//
//  SampleDataProvider.h
//  ZeroPIIObjCSample
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, CTDataType) {
    CTDataTypeString  = 0,
    CTDataTypeInt     = 1,
    CTDataTypeLong    = 2,
    CTDataTypeFloat   = 3,
    CTDataTypeDouble  = 4,
    CTDataTypeBoolean = 5
};

@interface SampleDataProvider : NSObject

+ (NSString *)displayNameForDataType:(CTDataType)type;
+ (NSString *)randomSampleStringForDataType:(CTDataType)type;
+ (NSArray *)batchSampleForDataType:(CTDataType)type;

@end
