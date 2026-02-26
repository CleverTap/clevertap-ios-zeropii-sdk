//
//  ResultItem.h
//  ZeroPIIObjCSample
//

#import <UIKit/UIKit.h>
#import <clevertap_ios_zeropii_sdk/clevertap_ios_zeropii_sdk-Swift.h>

typedef NS_ENUM(NSInteger, ResultItemType) {
    ResultItemTypeLoading,
    ResultItemTypeSingleTokenize,
    ResultItemTypeBatchTokenize,
    ResultItemTypeFileImported,
    ResultItemTypeError
};

@interface ResultItem : NSObject

@property (nonatomic, assign) ResultItemType type;
@property (nonatomic, copy)   NSString *title;
@property (nonatomic, copy)   NSString *content;
@property (nonatomic, copy)   NSString *detailedContent;
@property (nonatomic, strong) NSDate   *timestamp;
@property (nonatomic, assign) BOOL      isExpandable;
@property (nonatomic, strong) UIColor  *cardColor;

+ (instancetype)loadingItem:(NSString *)message;

+ (instancetype)singleTokenizeItemWithOriginalValue:(NSString *)originalValue
                                              token:(NSString *)token
                                             exists:(BOOL)exists
                                       newlyCreated:(BOOL)newlyCreated
                                           dataType:(NSString *)dataType
                                      inputDataType:(NSString *)inputDataType;

+ (instancetype)batchTokenizeItemWithResults:(NSArray<BatchTokenItem *> *)results
                                     summary:(BatchTokenizeSummary *)summary
                               inputDataType:(NSString *)inputDataType;

+ (instancetype)fileImportedItemWithFileName:(NSString *)fileName
                                 totalValues:(NSInteger)total
                                 validValues:(NSInteger)valid
                               invalidValues:(NSInteger)invalid
                                    dataType:(NSString *)dataType
                                sampleValues:(NSArray<NSString *> *)samples;

+ (instancetype)errorItemWithTitle:(NSString *)title message:(NSString *)message;

@end
