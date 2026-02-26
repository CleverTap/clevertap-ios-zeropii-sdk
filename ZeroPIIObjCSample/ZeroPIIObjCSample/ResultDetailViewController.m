//
//  ResultDetailViewController.m
//  ZeroPIIObjCSample
//

#import "ResultDetailViewController.h"

@interface ResultDetailViewController ()
@property (nonatomic, strong) ResultItem *item;
@property (nonatomic, strong) UITextView *textView;
@end

@implementation ResultDetailViewController

- (instancetype)initWithResultItem:(ResultItem *)item {
    self = [super init];
    if (self) {
        _item = item;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.item.title;
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    // Done button
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                      target:self
                                                      action:@selector(doneTapped)];

    // Copy button
    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"doc.on.doc"]
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(copyTapped)];

    // Text view
    self.textView = [[UITextView alloc] init];
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    self.textView.editable = NO;
    self.textView.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightRegular];
    self.textView.text = self.item.detailedContent;
    self.textView.textContainerInset = UIEdgeInsetsMake(16, 16, 16, 16);
    [self.view addSubview:self.textView];

    [NSLayoutConstraint activateConstraints:@[
        [self.textView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.textView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.textView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.textView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)doneTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)copyTapped {
    [UIPasteboard generalPasteboard].string = self.item.detailedContent;
    UIBarButtonItem *btn = self.navigationItem.leftBarButtonItem;
    btn.image = [UIImage systemImageNamed:@"checkmark"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        btn.image = [UIImage systemImageNamed:@"doc.on.doc"];
    });
}

@end
