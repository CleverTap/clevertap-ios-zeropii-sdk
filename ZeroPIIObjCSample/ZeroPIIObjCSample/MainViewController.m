//
//  MainViewController.m
//  ZeroPIIObjCSample
//

#import "MainViewController.h"
#import "ResultItem.h"
#import "ResultDetailViewController.h"
#import "SampleDataProvider.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <clevertap_ios_zeropii_sdk/clevertap_ios_zeropii_sdk-Swift.h>
#import <objc/runtime.h>

// MARK: - Constants

static NSString * const kDataTypeNames[] = {
    @"String", @"Int", @"Long", @"Float", @"Double", @"Bool"
};
static const NSInteger kDataTypeCount = 6;

// MARK: - MainViewController

@interface MainViewController () <UIDocumentPickerDelegate>

// Layout
@property (nonatomic, strong) UIScrollView   *scrollView;
@property (nonatomic, strong) UIView         *contentView;
@property (nonatomic, strong) UIStackView    *mainStack;

// Data type buttons
@property (nonatomic, strong) NSMutableArray<UIButton *> *dataTypeButtons;
@property (nonatomic, assign) CTDataType      selectedDataType;

// Operation
@property (nonatomic, strong) UISegmentedControl *operationSegment;
@property (nonatomic, assign) BOOL isBatchMode;

// Input
@property (nonatomic, strong) UIView         *singleInputContainer;
@property (nonatomic, strong) UITextField    *singleTextField;

@property (nonatomic, strong) UIView         *batchInputContainer;
@property (nonatomic, strong) UIStackView    *batchFieldsStack;
@property (nonatomic, strong) NSMutableArray<UITextField *> *batchTextFields;

// File import
@property (nonatomic, strong) UIView         *fileImportContainer;
@property (nonatomic, strong) UILabel        *fileStatusLabel;
@property (nonatomic, strong) NSMutableArray *importedData;
@property (nonatomic, copy)   NSString       *importedFileName;

// Action buttons
@property (nonatomic, strong) UIButton       *actionButton;

// Results
@property (nonatomic, strong) UIStackView    *resultsStack;
@property (nonatomic, strong) NSMutableArray<ResultItem *> *resultItems;
@property (nonatomic, strong) NSMutableArray<UIView *>     *resultCardViews;

@end

@implementation MainViewController

// MARK: - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"ZeroPII SDK Demo (ObjC)";
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    _selectedDataType = CTDataTypeString;
    _isBatchMode      = NO;
    _batchTextFields  = [NSMutableArray array];
    _dataTypeButtons  = [NSMutableArray array];
    _importedData     = [NSMutableArray array];
    _resultItems      = [NSMutableArray array];
    _resultCardViews  = [NSMutableArray array];

    [self setupScrollView];
    [self setupContent];
}

// MARK: - Layout Setup

- (void)setupScrollView {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.view addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.contentView];

    UILayoutGuide *cg = self.scrollView.contentLayoutGuide;
    UILayoutGuide *fg = self.scrollView.frameLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.contentView.topAnchor constraintEqualToAnchor:cg.topAnchor],
        [self.contentView.leadingAnchor constraintEqualToAnchor:cg.leadingAnchor],
        [self.contentView.trailingAnchor constraintEqualToAnchor:cg.trailingAnchor],
        [self.contentView.bottomAnchor constraintEqualToAnchor:cg.bottomAnchor],
        [self.contentView.widthAnchor constraintEqualToAnchor:fg.widthAnchor],
    ]];
}

- (void)setupContent {
    self.mainStack = [[UIStackView alloc] init];
    self.mainStack.translatesAutoresizingMaskIntoConstraints = NO;
    self.mainStack.axis = UILayoutConstraintAxisVertical;
    self.mainStack.spacing = 0;
    [self.contentView addSubview:self.mainStack];

    [NSLayoutConstraint activateConstraints:@[
        [self.mainStack.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [self.mainStack.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.mainStack.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [self.mainStack.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    ]];

    [self.mainStack addArrangedSubview:[self makeStatusHeader]];
    [self.mainStack addArrangedSubview:[self makeSectionCard:[self makeDataTypeSection]]];
    [self.mainStack addArrangedSubview:[self makeSectionCard:[self makeOperationSection]]];
    [self.mainStack addArrangedSubview:[self makeSectionCard:[self makeInputSection]]];
    [self.mainStack addArrangedSubview:[self makeSectionCard:[self makeActionButtons]]];
    [self.mainStack addArrangedSubview:[self makeSectionCard:[self makeResultsSection]]];
}

// MARK: - Status Header

- (UIView *)makeStatusHeader {
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor systemGray6Color];

    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = @"🔒 Encryption: ON    |    SDK Status: Ready";
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    label.textColor = [UIColor systemGreenColor];
    [view addSubview:label];

    [NSLayoutConstraint activateConstraints:@[
        [label.topAnchor constraintEqualToAnchor:view.topAnchor constant:10],
        [label.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:16],
        [label.trailingAnchor constraintEqualToAnchor:view.trailingAnchor constant:-16],
        [label.bottomAnchor constraintEqualToAnchor:view.bottomAnchor constant:-10],
    ]];
    return view;
}

// MARK: - Data Type Section

- (UIView *)makeDataTypeSection {
    UIStackView *stack = [self makeLabeledSectionStack:@"Data Type"];

    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.showsHorizontalScrollIndicator = NO;
    [stack addArrangedSubview:scroll];

    UIStackView *btnStack = [[UIStackView alloc] init];
    btnStack.translatesAutoresizingMaskIntoConstraints = NO;
    btnStack.axis = UILayoutConstraintAxisHorizontal;
    btnStack.spacing = 8;
    [scroll addSubview:btnStack];

    [NSLayoutConstraint activateConstraints:@[
        [btnStack.topAnchor constraintEqualToAnchor:scroll.topAnchor],
        [btnStack.leadingAnchor constraintEqualToAnchor:scroll.leadingAnchor],
        [btnStack.trailingAnchor constraintEqualToAnchor:scroll.trailingAnchor],
        [btnStack.bottomAnchor constraintEqualToAnchor:scroll.bottomAnchor],
        [btnStack.heightAnchor constraintEqualToAnchor:scroll.heightAnchor],
        [scroll.heightAnchor constraintEqualToConstant:44],
    ]];

    for (NSInteger i = 0; i < kDataTypeCount; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.tag = i;
        [btn setTitle:kDataTypeNames[i] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        btn.layer.cornerRadius = 16;
        btn.contentEdgeInsets = UIEdgeInsetsMake(8, 14, 8, 14);
        [btn addTarget:self action:@selector(dataTypeTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self applyDataTypeStyle:btn selected:(i == 0)];
        [btnStack addArrangedSubview:btn];
        [self.dataTypeButtons addObject:btn];
    }
    return stack;
}

- (void)applyDataTypeStyle:(UIButton *)btn selected:(BOOL)selected {
    btn.backgroundColor = selected ? [UIColor systemBlueColor] : [UIColor systemGray5Color];
    [btn setTitleColor:selected ? [UIColor whiteColor] : [UIColor labelColor]
              forState:UIControlStateNormal];
}

- (void)dataTypeTapped:(UIButton *)sender {
    self.selectedDataType = (CTDataType)sender.tag;
    for (UIButton *btn in self.dataTypeButtons) {
        [self applyDataTypeStyle:btn selected:(btn.tag == sender.tag)];
    }
    self.singleTextField.placeholder = [self inputPlaceholder];
    for (UITextField *tf in self.batchTextFields) {
        tf.placeholder = [self inputPlaceholder];
    }
}

// MARK: - Operation Section

- (UIView *)makeOperationSection {
    UIStackView *stack = [self makeLabeledSectionStack:@"Operation Type"];

    self.operationSegment = [[UISegmentedControl alloc] initWithItems:@[@"Single", @"Batch"]];
    self.operationSegment.selectedSegmentIndex = 0;
    [self.operationSegment addTarget:self action:@selector(operationChanged:)
                    forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:self.operationSegment];
    return stack;
}

- (void)operationChanged:(UISegmentedControl *)sender {
    self.isBatchMode = (sender.selectedSegmentIndex == 1);
    self.singleInputContainer.hidden = self.isBatchMode;
    self.batchInputContainer.hidden  = !self.isBatchMode;
    self.fileImportContainer.hidden  = !self.isBatchMode;
    NSString *title = self.isBatchMode ? @"Batch Tokenize" : @"Tokenize";
    [self.actionButton setTitle:title forState:UIControlStateNormal];
    [UIView animateWithDuration:0.2 animations:^{ [self.mainStack layoutIfNeeded]; }];
}

// MARK: - Input Section

- (UIView *)makeInputSection {
    UIStackView *outerStack = [self makeLabeledSectionStack:@"Input"];

    // Single input
    self.singleInputContainer = [[UIView alloc] init];
    UITextField *tf = [self makeTextField];
    tf.placeholder = [self inputPlaceholder];
    self.singleTextField = tf;

    UIButton *randomBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [randomBtn setTitle:@"Random" forState:UIControlStateNormal];
    randomBtn.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    [randomBtn addTarget:self action:@selector(randomSampleTapped) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *singleRow = [[UIStackView alloc] initWithArrangedSubviews:@[tf, randomBtn]];
    singleRow.translatesAutoresizingMaskIntoConstraints = NO;
    singleRow.spacing = 8;
    singleRow.alignment = UIStackViewAlignmentCenter;

    self.singleInputContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.singleInputContainer addSubview:singleRow];
    [NSLayoutConstraint activateConstraints:@[
        [singleRow.topAnchor constraintEqualToAnchor:self.singleInputContainer.topAnchor],
        [singleRow.leadingAnchor constraintEqualToAnchor:self.singleInputContainer.leadingAnchor],
        [singleRow.trailingAnchor constraintEqualToAnchor:self.singleInputContainer.trailingAnchor],
        [singleRow.bottomAnchor constraintEqualToAnchor:self.singleInputContainer.bottomAnchor],
    ]];
    [outerStack addArrangedSubview:self.singleInputContainer];

    // Batch input container
    self.batchInputContainer = [[UIView alloc] init];
    self.batchInputContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.batchInputContainer.hidden = YES;

    self.batchFieldsStack = [[UIStackView alloc] init];
    self.batchFieldsStack.translatesAutoresizingMaskIntoConstraints = NO;
    self.batchFieldsStack.axis = UILayoutConstraintAxisVertical;
    self.batchFieldsStack.spacing = 8;
    [self.batchInputContainer addSubview:self.batchFieldsStack];

    UIButton *addBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    addBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [addBtn setTitle:@"+ Add Value" forState:UIControlStateNormal];
    addBtn.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    addBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [addBtn addTarget:self action:@selector(addBatchFieldTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.batchInputContainer addSubview:addBtn];

    [NSLayoutConstraint activateConstraints:@[
        [self.batchFieldsStack.topAnchor constraintEqualToAnchor:self.batchInputContainer.topAnchor],
        [self.batchFieldsStack.leadingAnchor constraintEqualToAnchor:self.batchInputContainer.leadingAnchor],
        [self.batchFieldsStack.trailingAnchor constraintEqualToAnchor:self.batchInputContainer.trailingAnchor],
        [addBtn.topAnchor constraintEqualToAnchor:self.batchFieldsStack.bottomAnchor constant:8],
        [addBtn.leadingAnchor constraintEqualToAnchor:self.batchInputContainer.leadingAnchor],
        [addBtn.trailingAnchor constraintEqualToAnchor:self.batchInputContainer.trailingAnchor],
        [addBtn.bottomAnchor constraintEqualToAnchor:self.batchInputContainer.bottomAnchor],
    ]];

    [outerStack addArrangedSubview:self.batchInputContainer];

    // Seed the first batch field
    [self addBatchFieldRow];

    // File import container (shown in batch mode only)
    self.fileImportContainer = [self makeFileImportView];
    self.fileImportContainer.hidden = YES;
    [outerStack addArrangedSubview:self.fileImportContainer];

    return outerStack;
}

- (UIView *)makeFileImportView {
    UIStackView *stack = [self makeLabeledSectionStack:@"Or Import from File"];

    self.fileStatusLabel = [[UILabel alloc] init];
    self.fileStatusLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    self.fileStatusLabel.textColor = [UIColor secondaryLabelColor];
    self.fileStatusLabel.numberOfLines = 0;
    self.fileStatusLabel.hidden = YES;
    [stack addArrangedSubview:self.fileStatusLabel];

    UIButton *importBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [importBtn setTitle:@"Import File" forState:UIControlStateNormal];
    importBtn.backgroundColor = [UIColor systemBlueColor];
    [importBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    importBtn.layer.cornerRadius = 8;
    importBtn.contentEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 0);
    [importBtn addTarget:self action:@selector(importFileTapped) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:importBtn];

    return stack;
}

// MARK: - Action Buttons

- (UIView *)makeActionButtons {
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 8;
    stack.layoutMargins = UIEdgeInsetsMake(0, 0, 0, 0);

    self.actionButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.actionButton setTitle:@"Tokenize" forState:UIControlStateNormal];
    self.actionButton.backgroundColor = [UIColor systemGreenColor];
    [self.actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.actionButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    self.actionButton.layer.cornerRadius = 10;
    self.actionButton.contentEdgeInsets = UIEdgeInsetsMake(14, 0, 14, 0);
    [self.actionButton addTarget:self action:@selector(actionButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:self.actionButton];

    UIButton *clearBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [clearBtn setTitle:@"Clear Results" forState:UIControlStateNormal];
    clearBtn.backgroundColor = [UIColor systemGray5Color];
    [clearBtn setTitleColor:[UIColor labelColor] forState:UIControlStateNormal];
    clearBtn.layer.cornerRadius = 8;
    clearBtn.contentEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 0);
    [clearBtn addTarget:self action:@selector(clearResultsTapped) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:clearBtn];

    return stack;
}

// MARK: - Results Section

- (UIView *)makeResultsSection {
    UIStackView *stack = [self makeLabeledSectionStack:@"Results"];

    self.resultsStack = [[UIStackView alloc] init];
    self.resultsStack.axis = UILayoutConstraintAxisVertical;
    self.resultsStack.spacing = 10;
    [stack addArrangedSubview:self.resultsStack];

    return stack;
}

// MARK: - Batch Field Management

- (void)addBatchFieldRow {
    UITextField *tf = [self makeTextField];
    tf.placeholder = [self inputPlaceholder];
    [self.batchTextFields addObject:tf];

    UIButton *removeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [removeBtn setImage:[UIImage systemImageNamed:@"minus.circle.fill"] forState:UIControlStateNormal];
    removeBtn.tintColor = [UIColor systemRedColor];
    [removeBtn addTarget:self action:@selector(removeBatchFieldTapped:) forControlEvents:UIControlEventTouchUpInside];
    removeBtn.tag = self.batchTextFields.count - 1;
    [removeBtn setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[tf, removeBtn]];
    row.spacing = 8;
    row.alignment = UIStackViewAlignmentCenter;
    [self.batchFieldsStack addArrangedSubview:row];

    [self updateRemoveButtonVisibility];
}

- (void)addBatchFieldTapped {
    if (self.batchTextFields.count >= 20) return;
    [self addBatchFieldRow];
}

- (void)removeBatchFieldTapped:(UIButton *)sender {
    NSInteger idx = sender.tag;
    if (self.batchTextFields.count <= 1 || idx >= (NSInteger)self.batchTextFields.count) return;

    [self.batchTextFields removeObjectAtIndex:idx];
    UIView *row = self.batchFieldsStack.arrangedSubviews[idx];
    [self.batchFieldsStack removeArrangedSubview:row];
    [row removeFromSuperview];

    // Re-tag remaining remove buttons
    for (NSInteger i = idx; i < (NSInteger)self.batchFieldsStack.arrangedSubviews.count; i++) {
        UIStackView *r = (UIStackView *)self.batchFieldsStack.arrangedSubviews[i];
        UIButton *btn = (UIButton *)r.arrangedSubviews.lastObject;
        btn.tag = i;
    }
    [self updateRemoveButtonVisibility];
}

- (void)updateRemoveButtonVisibility {
    BOOL showRemove = self.batchTextFields.count > 1;
    for (UIView *row in self.batchFieldsStack.arrangedSubviews) {
        if ([row isKindOfClass:[UIStackView class]]) {
            UIView *removeBtn = ((UIStackView *)row).arrangedSubviews.lastObject;
            removeBtn.hidden = !showRemove;
        }
    }
}

// MARK: - Random Sample

- (void)randomSampleTapped {
    self.singleTextField.text = [SampleDataProvider randomSampleStringForDataType:self.selectedDataType];
}

// MARK: - Tokenize Actions

- (void)actionButtonTapped {
    [self.view endEditing:YES];
    if (self.isBatchMode) {
        [self batchTokenizeTapped];
    } else {
        [self singleTokenizeTapped];
    }
}

- (void)singleTokenizeTapped {
    NSString *input = [self.singleTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (input.length == 0) {
        [self showAlert:@"Please enter a value to tokenize"];
        return;
    }
    id parsed = [self parseInput:input];
    if (!parsed) {
        [self showAlert:[NSString stringWithFormat:@"Invalid %@ format",
                         [SampleDataProvider displayNameForDataType:self.selectedDataType]]];
        return;
    }

    NSString *typeName = [SampleDataProvider displayNameForDataType:self.selectedDataType];
    [self addResultCard:[ResultItem loadingItem:[NSString stringWithFormat:@"Tokenizing %@ as %@…", input, typeName]]];

    ZeroPiiSDK *sdk = [ZeroPiiSDK getInstance];
    __weak typeof(self) weakSelf = self;

    switch (self.selectedDataType) {
        case CTDataTypeString: {
            [sdk tokenizeString:(NSString *)parsed callback:^(TokenizeResult *r) {
                [weakSelf handleTokenizeResult:r originalValue:input];
            }];
            break;
        }
        case CTDataTypeInt: {
            [sdk tokenizeInt:[(NSNumber *)parsed integerValue] callback:^(TokenizeResult *r) {
                [weakSelf handleTokenizeResult:r originalValue:input];
            }];
            break;
        }
        case CTDataTypeLong: {
            [sdk tokenizeLong:[(NSNumber *)parsed longLongValue] callback:^(TokenizeResult *r) {
                [weakSelf handleTokenizeResult:r originalValue:input];
            }];
            break;
        }
        case CTDataTypeFloat: {
            [sdk tokenizeFloat:[(NSNumber *)parsed floatValue] callback:^(TokenizeResult *r) {
                [weakSelf handleTokenizeResult:r originalValue:input];
            }];
            break;
        }
        case CTDataTypeDouble: {
            [sdk tokenizeDouble:[(NSNumber *)parsed doubleValue] callback:^(TokenizeResult *r) {
                [weakSelf handleTokenizeResult:r originalValue:input];
            }];
            break;
        }
        case CTDataTypeBoolean: {
            [sdk tokenizeBool:[(NSNumber *)parsed boolValue] callback:^(TokenizeResult *r) {
                [weakSelf handleTokenizeResult:r originalValue:input];
            }];
            break;
        }
    }
}

- (void)batchTokenizeTapped {
    ZeroPiiSDK *sdk = [ZeroPiiSDK getInstance];
    __weak typeof(self) weakSelf = self;
    NSString *typeName = [SampleDataProvider displayNameForDataType:self.selectedDataType];

    if (self.importedData.count > 0) {
        NSString *msg = [NSString stringWithFormat:@"Batch tokenizing %lu imported %@ values from %@…",
                         (unsigned long)self.importedData.count, typeName,
                         self.importedFileName ?: @"file"];
        [self addResultCard:[ResultItem loadingItem:msg]];
        [self performBatchTokenize:self.importedData sdk:sdk typeName:typeName];
        return;
    }

    NSMutableArray *nonEmpty = [NSMutableArray array];
    for (UITextField *tf in self.batchTextFields) {
        NSString *s = [tf.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (s.length > 0) [nonEmpty addObject:s];
    }
    if (nonEmpty.count == 0) {
        [self showAlert:@"Please add at least one value to batch tokenize"];
        return;
    }

    NSMutableArray *parsed = [NSMutableArray array];
    for (NSString *s in nonEmpty) {
        id v = [self parseInput:s];
        if (!v) {
            [self showAlert:[NSString stringWithFormat:@"Invalid %@ format: %@", typeName, s]];
            return;
        }
        [parsed addObject:v];
    }

    [self addResultCard:[ResultItem loadingItem:[NSString stringWithFormat:@"Batch tokenizing %lu %@ values…",
                                                  (unsigned long)parsed.count, typeName]]];
    [self performBatchTokenize:parsed sdk:sdk typeName:typeName];
    (void)weakSelf;
}

- (void)performBatchTokenize:(NSArray *)data sdk:(ZeroPiiSDK *)sdk typeName:(NSString *)typeName {
    __weak typeof(self) weakSelf = self;
    void (^handler)(BatchTokenizeResult *) = ^(BatchTokenizeResult *r) {
        [weakSelf handleBatchTokenizeResult:r typeName:typeName];
    };

    switch (self.selectedDataType) {
        case CTDataTypeString:  [sdk batchTokenizeStringValues:(NSArray<NSString *> *)data callback:handler];  break;
        case CTDataTypeInt:     [sdk batchTokenizeIntValues:(NSArray<NSNumber *> *)data callback:handler];     break;
        case CTDataTypeLong:    [sdk batchTokenizeLongValues:(NSArray<NSNumber *> *)data callback:handler];    break;
        case CTDataTypeFloat:   [sdk batchTokenizeFloatValues:(NSArray<NSNumber *> *)data callback:handler];   break;
        case CTDataTypeDouble:  [sdk batchTokenizeDoubleValues:(NSArray<NSNumber *> *)data callback:handler];  break;
        case CTDataTypeBoolean: [sdk batchTokenizeBoolValues:(NSArray<NSNumber *> *)data callback:handler];    break;
    }
}

// MARK: - Result Handlers

- (void)handleTokenizeResult:(TokenizeResult *)result originalValue:(NSString *)original {
    [self removeLoadingCards];
    NSString *typeName = [SampleDataProvider displayNameForDataType:self.selectedDataType];
    if (!result.isSuccess || !result.token) {
        NSString *msg = result.errorMessage ?: @"Unknown error";
        if (result.httpStatusCode) {
            msg = [NSString stringWithFormat:@"%@ (HTTP %@)", msg, result.httpStatusCode];
        }
        [self addResultCard:[ResultItem errorItemWithTitle:[NSString stringWithFormat:@"%@ Tokenize Error", typeName]
                                                  message:msg]];
        return;
    }
    [self addResultCard:[ResultItem singleTokenizeItemWithOriginalValue:original
                                                                  token:result.token
                                                                 exists:result.exists
                                                           newlyCreated:result.newlyCreated
                                                               dataType:result.dataType ?: @"unknown"
                                                          inputDataType:typeName]];
}

- (void)handleBatchTokenizeResult:(BatchTokenizeResult *)result typeName:(NSString *)typeName {
    [self removeLoadingCards];
    if (!result.isSuccess) {
        NSString *msg = result.errorMessage ?: @"Batch tokenization failed";
        if (result.httpStatusCode) {
            msg = [NSString stringWithFormat:@"%@ (HTTP %@)", msg, result.httpStatusCode];
        }
        [self addResultCard:[ResultItem errorItemWithTitle:[NSString stringWithFormat:@"%@ Batch Error", typeName]
                                                  message:msg]];
        return;
    }
    BatchTokenizeSummary *summary = result.summary
        ?: [[BatchTokenizeSummary alloc] initWithProcessedCount:0 existingCount:0 newlyCreatedCount:0];
    [self addResultCard:[ResultItem batchTokenizeItemWithResults:result.results
                                                        summary:summary
                                                  inputDataType:typeName]];
}

// MARK: - File Import

- (void)importFileTapped {
    NSArray *types = @[UTTypeText, UTTypeCommaSeparatedText, UTTypePlainText];
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc]
        initForOpeningContentTypes:types];
    picker.delegate = self;
    picker.allowsMultipleSelection = NO;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller
didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *url = urls.firstObject;
    if (!url) return;
    BOOL access = [url startAccessingSecurityScopedResource];
    NSError *error;
    NSString *content = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    if (access) [url stopAccessingSecurityScopedResource];
    if (error || !content) {
        [self showAlert:[NSString stringWithFormat:@"Error reading file: %@", error.localizedDescription]];
        return;
    }
    [self parseFileContent:content fileName:url.lastPathComponent];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {}

- (void)parseFileContent:(NSString *)content fileName:(NSString *)fileName {
    NSArray<NSString *> *raw = [[content componentsSeparatedByCharactersInSet:
                                  [NSCharacterSet characterSetWithCharactersInString:@",\n"]]
                                 filteredArrayUsingPredicate:
                                 [NSPredicate predicateWithBlock:^BOOL(NSString *s, id _) {
        return [[s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0;
    }]];

    if (raw.count == 0) {
        [self showAlert:@"No valid data found in file"];
        return;
    }

    NSMutableArray *validData = [NSMutableArray array];
    NSInteger invalidCount = 0;
    for (NSString *s in raw) {
        id v = [self parseInput:[s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
        if (v) [validData addObject:v];
        else invalidCount++;
    }

    if (validData.count == 0) {
        NSString *typeName = [SampleDataProvider displayNameForDataType:self.selectedDataType];
        [self showAlert:[NSString stringWithFormat:@"No valid %@ values found in file", typeName]];
        return;
    }

    self.importedData     = validData;
    self.importedFileName = fileName;

    NSString *typeName = [SampleDataProvider displayNameForDataType:self.selectedDataType];
    NSString *status;
    if (invalidCount > 0) {
        status = [NSString stringWithFormat:@"📄 %@: %ld valid, %ld invalid %@ values",
                  fileName, (long)validData.count, (long)invalidCount, typeName];
    } else {
        status = [NSString stringWithFormat:@"📄 %@: %ld valid %@ values",
                  fileName, (long)validData.count, typeName];
    }
    self.fileStatusLabel.text   = status;
    self.fileStatusLabel.hidden = NO;

    // Show file import result card
    NSArray<NSString *> *samples = [validData subarrayWithRange:NSMakeRange(0, MIN(3, validData.count))];
    NSMutableArray<NSString *> *sampleStrings = [NSMutableArray array];
    for (id v in samples) [sampleStrings addObject:[v description]];

    [self addResultCard:[ResultItem fileImportedItemWithFileName:fileName
                                                    totalValues:raw.count
                                                    validValues:validData.count
                                                  invalidValues:invalidCount
                                                       dataType:typeName
                                                   sampleValues:sampleStrings]];
}

// MARK: - Input Parsing

- (id)parseInput:(NSString *)input {
    switch (self.selectedDataType) {
        case CTDataTypeString:  return input;
        case CTDataTypeInt: {
            NSInteger v; NSScanner *sc = [NSScanner scannerWithString:input];
            return [sc scanInteger:&v] && sc.atEnd ? @(v) : nil;
        }
        case CTDataTypeLong: {
            long long v; NSScanner *sc = [NSScanner scannerWithString:input];
            return [sc scanLongLong:&v] && sc.atEnd ? @(v) : nil;
        }
        case CTDataTypeFloat: {
            float v; NSScanner *sc = [NSScanner scannerWithString:input];
            return [sc scanFloat:&v] && sc.atEnd ? @(v) : nil;
        }
        case CTDataTypeDouble: {
            double v; NSScanner *sc = [NSScanner scannerWithString:input];
            return [sc scanDouble:&v] && sc.atEnd ? @(v) : nil;
        }
        case CTDataTypeBoolean: {
            NSString *lower = input.lowercaseString;
            if ([@[@"true",@"1",@"yes",@"y"] containsObject:lower]) return @YES;
            if ([@[@"false",@"0",@"no",@"n"] containsObject:lower]) return @NO;
            return nil;
        }
    }
}

- (NSString *)inputPlaceholder {
    switch (self.selectedDataType) {
        case CTDataTypeString:  return @"Enter string value (e.g., john@example.com)";
        case CTDataTypeInt:     return @"Enter integer (e.g., 123456)";
        case CTDataTypeLong:    return @"Enter long (e.g., 9876543210)";
        case CTDataTypeFloat:   return @"Enter float (e.g., 123.45)";
        case CTDataTypeDouble:  return @"Enter double (e.g., 123.456789)";
        case CTDataTypeBoolean: return @"Enter boolean (true or false)";
    }
}

// MARK: - Results Management

- (void)addResultCard:(ResultItem *)item {
    [self.resultItems insertObject:item atIndex:0];

    UIView *card = [self makeResultCardView:item];
    [self.resultCardViews insertObject:card atIndex:0];

    if (self.resultsStack.arrangedSubviews.count == 0) {
        [self.resultsStack addArrangedSubview:card];
    } else {
        [self.resultsStack insertArrangedSubview:card atIndex:0];
    }
}

- (void)removeLoadingCards {
    for (NSInteger i = (NSInteger)self.resultItems.count - 1; i >= 0; i--) {
        if (self.resultItems[i].type == ResultItemTypeLoading) {
            UIView *card = self.resultCardViews[i];
            [self.resultsStack removeArrangedSubview:card];
            [card removeFromSuperview];
            [self.resultCardViews removeObjectAtIndex:i];
            [self.resultItems removeObjectAtIndex:i];
        }
    }
}

- (void)clearResultsTapped {
    for (UIView *card in self.resultCardViews) {
        [self.resultsStack removeArrangedSubview:card];
        [card removeFromSuperview];
    }
    [self.resultCardViews removeAllObjects];
    [self.resultItems removeAllObjects];
    self.importedData     = [NSMutableArray array];
    self.importedFileName = nil;
    self.fileStatusLabel.hidden = YES;
    self.fileStatusLabel.text   = nil;
}

// MARK: - Result Card UI

- (UIView *)makeResultCardView:(ResultItem *)item {
    UIView *card = [[UIView alloc] init];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor = item.cardColor;
    card.layer.cornerRadius = 10;
    card.clipsToBounds = YES;

    // Title row
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.font = [UIFont boldSystemFontOfSize:14];
    titleLabel.text = item.title;
    titleLabel.numberOfLines = 1;

    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"HH:mm:ss";
    UILabel *timeLabel = [[UILabel alloc] init];
    timeLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    timeLabel.textColor = [UIColor secondaryLabelColor];
    timeLabel.text = [fmt stringFromDate:item.timestamp];
    [timeLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    UIStackView *titleRow = [[UIStackView alloc] initWithArrangedSubviews:@[titleLabel, timeLabel]];
    titleRow.distribution = UIStackViewDistributionFill;

    // Content label
    UILabel *contentLabel = [[UILabel alloc] init];
    contentLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    contentLabel.textColor = [UIColor secondaryLabelColor];
    contentLabel.numberOfLines = 5;
    contentLabel.text = item.content;

    UIStackView *cardStack = [[UIStackView alloc] initWithArrangedSubviews:@[titleRow, contentLabel]];
    cardStack.translatesAutoresizingMaskIntoConstraints = NO;
    cardStack.axis = UILayoutConstraintAxisVertical;
    cardStack.spacing = 6;

    if (item.isExpandable) {
        UIButton *detailBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [detailBtn setTitle:@"View Details ›" forState:UIControlStateNormal];
        detailBtn.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
        detailBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [detailBtn addTarget:self action:@selector(viewDetailsTapped:) forControlEvents:UIControlEventTouchUpInside];
        detailBtn.tag = [self.resultCardViews count]; // will be set after insertion
        [cardStack addArrangedSubview:detailBtn];
        // Store tag post-insertion via associated object
        objc_setAssociatedObject(detailBtn, "resultItem", item, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    [card addSubview:cardStack];
    [NSLayoutConstraint activateConstraints:@[
        [cardStack.topAnchor constraintEqualToAnchor:card.topAnchor constant:12],
        [cardStack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:12],
        [cardStack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-12],
        [cardStack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-12],
    ]];
    return card;
}

- (void)viewDetailsTapped:(UIButton *)sender {
    ResultItem *item = objc_getAssociatedObject(sender, "resultItem");
    if (!item) return;
    ResultDetailViewController *detailVC = [[ResultDetailViewController alloc] initWithResultItem:item];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:detailVC];
    [self presentViewController:nav animated:YES completion:nil];
}

// MARK: - Helpers

- (UIStackView *)makeLabeledSectionStack:(NSString *)title {
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 8;

    UILabel *label = [[UILabel alloc] init];
    label.text = title;
    label.font = [UIFont boldSystemFontOfSize:15];
    [stack addArrangedSubview:label];
    return stack;
}

- (UIView *)makeSectionCard:(UIView *)content {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];

    content.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:content];
    [NSLayoutConstraint activateConstraints:@[
        [content.topAnchor constraintEqualToAnchor:card.topAnchor constant:16],
        [content.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [content.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
        [content.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-16],
    ]];

    UIView *separator = [[UIView alloc] init];
    separator.translatesAutoresizingMaskIntoConstraints = NO;
    separator.backgroundColor = [UIColor separatorColor];
    [card addSubview:separator];
    [NSLayoutConstraint activateConstraints:@[
        [separator.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
        [separator.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],
        [separator.bottomAnchor constraintEqualToAnchor:card.bottomAnchor],
        [separator.heightAnchor constraintEqualToConstant:0.5],
    ]];
    return card;
}

- (UITextField *)makeTextField {
    UITextField *tf = [[UITextField alloc] init];
    tf.borderStyle = UITextBorderStyleRoundedRect;
    tf.autocapitalizationType = UITextAutocapitalizationTypeNone;
    tf.autocorrectionType = UITextAutocorrectionTypeNo;
    tf.clearButtonMode = UITextFieldViewModeWhileEditing;
    tf.returnKeyType = UIReturnKeyDone;
    [tf addTarget:self action:@selector(textFieldReturnTapped:) forControlEvents:UIControlEventEditingDidEndOnExit];
    return tf;
}

- (void)textFieldReturnTapped:(UITextField *)sender {
    [sender resignFirstResponder];
}

- (void)showAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
