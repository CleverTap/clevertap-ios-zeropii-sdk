//
//  ResultItem.m
//  ZeroPIIObjCSample
//

#import "ResultItem.h"

@implementation ResultItem

+ (instancetype)loadingItem:(NSString *)message {
    ResultItem *item  = [ResultItem new];
    item.type         = ResultItemTypeLoading;
    item.title        = @"⏳ Loading";
    item.content      = message;
    item.detailedContent = message;
    item.timestamp    = [NSDate date];
    item.isExpandable = NO;
    item.cardColor    = [[UIColor systemYellowColor] colorWithAlphaComponent:0.2];
    return item;
}

+ (instancetype)singleTokenizeItemWithOriginalValue:(NSString *)originalValue
                                              token:(NSString *)token
                                             exists:(BOOL)exists
                                       newlyCreated:(BOOL)newlyCreated
                                           dataType:(NSString *)dataType
                                      inputDataType:(NSString *)inputDataType {
    ResultItem *item = [ResultItem new];
    item.type        = ResultItemTypeSingleTokenize;
    item.title       = [NSString stringWithFormat:@"Single Tokenize (%@)", inputDataType];
    item.content     = [NSString stringWithFormat:
                        @"Input:      %@\nToken:      %@\nStatus:     %@\nData Type:  %@\nInput Type: %@",
                        originalValue, token, exists ? @"Existing" : @"New",
                        dataType, inputDataType];
    item.detailedContent = item.content;
    item.timestamp   = [NSDate date];
    item.isExpandable = NO;
    item.cardColor   = [[UIColor systemGreenColor] colorWithAlphaComponent:0.2];
    return item;
}

+ (instancetype)batchTokenizeItemWithResults:(NSArray<BatchTokenItem *> *)results
                                     summary:(BatchTokenizeSummary *)summary
                               inputDataType:(NSString *)inputDataType {
    ResultItem *item = [ResultItem new];
    item.type        = ResultItemTypeBatchTokenize;
    item.title       = [NSString stringWithFormat:@"Batch Tokenize (%@)", inputDataType];
    item.timestamp   = [NSDate date];
    item.isExpandable = YES;
    item.cardColor   = [[UIColor systemPurpleColor] colorWithAlphaComponent:0.2];

    NSMutableString *content = [NSMutableString string];
    [content appendFormat:@"Summary:\n• Processed: %ld\n• Existing: %ld\n• New: %ld\n• Input Type: %@\n\nResults:\n",
     (long)summary.processedCount, (long)summary.existingCount,
     (long)summary.newlyCreatedCount, inputDataType];
    for (BatchTokenItem *r in results) {
        [content appendFormat:@"• %@ → %@\n", r.originalValue, r.token];
    }
    item.content = content;

    NSMutableString *detail = [NSMutableString string];
    [detail appendString:@"Batch Tokenize Results\n\n"];
    [detail appendFormat:@"Data Type: %@\n\nStatistics:\n", inputDataType];
    [detail appendFormat:@"• Total Items:      %ld\n", (long)results.count];
    [detail appendFormat:@"• Processed:        %ld\n", (long)summary.processedCount];
    [detail appendFormat:@"• Existing Tokens:  %ld\n", (long)summary.existingCount];
    [detail appendFormat:@"• New Tokens:       %ld\n\nResults:\n", (long)summary.newlyCreatedCount];
    NSArray *preview = results.count > 5 ? [results subarrayWithRange:NSMakeRange(0, 5)] : results;
    for (BatchTokenItem *r in preview) {
        [detail appendFormat:@"• %@ → %@\n", r.originalValue, r.token];
    }
    if (results.count > 5) {
        [detail appendFormat:@"\n… and %ld more", (long)(results.count - 5)];
    }
    item.detailedContent = detail;
    return item;
}

+ (instancetype)fileImportedItemWithFileName:(NSString *)fileName
                                 totalValues:(NSInteger)total
                                 validValues:(NSInteger)valid
                               invalidValues:(NSInteger)invalid
                                    dataType:(NSString *)dataType
                                sampleValues:(NSArray<NSString *> *)samples {
    ResultItem *item = [ResultItem new];
    item.type        = ResultItemTypeFileImported;
    item.title       = @"File Imported";
    item.timestamp   = [NSDate date];
    item.isExpandable = YES;
    item.cardColor   = [[UIColor systemBlueColor] colorWithAlphaComponent:0.2];

    NSInteger successPct = total > 0 ? (NSInteger)(((float)valid / total) * 100) : 0;
    NSMutableString *content = [NSMutableString string];
    [content appendFormat:@"File: %@\nData Type: %@\nTotal Values: %ld\n✅ Valid: %ld\n",
     fileName, dataType, (long)total, (long)valid];
    if (invalid > 0) [content appendFormat:@"❌ Invalid: %ld\n", (long)invalid];
    [content appendFormat:@"Success Rate: %ld%%\n\nSample Values:\n", (long)successPct];
    for (NSString *s in samples) [content appendFormat:@"• %@\n", s];
    if (valid > (NSInteger)samples.count) {
        [content appendFormat:@"… and %ld more", (long)(valid - samples.count)];
    }
    item.content = content;

    NSMutableString *detail = [NSMutableString stringWithString:content];
    [detail appendString:@"\n\n💡 Ready for batch tokenization!"];
    item.detailedContent = detail;
    return item;
}

+ (instancetype)errorItemWithTitle:(NSString *)title message:(NSString *)message {
    ResultItem *item = [ResultItem new];
    item.type        = ResultItemTypeError;
    item.title       = [NSString stringWithFormat:@"❌ %@", title];
    item.content     = message;
    item.detailedContent = [NSString stringWithFormat:
                            @"Error Details\n\nType: %@\n\nMessage:\n%@\n\n"
                            @"Troubleshooting:\n• Check network connection\n"
                            @"• Verify API credentials\n• Ensure data format is correct",
                            title, message];
    item.timestamp   = [NSDate date];
    item.isExpandable = YES;
    item.cardColor   = [[UIColor systemRedColor] colorWithAlphaComponent:0.2];
    return item;
}

@end
