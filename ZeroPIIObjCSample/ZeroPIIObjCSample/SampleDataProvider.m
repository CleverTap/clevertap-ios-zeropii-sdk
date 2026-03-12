//
//  SampleDataProvider.m
//  ZeroPIIObjCSample
//

#import "SampleDataProvider.h"

@implementation SampleDataProvider

+ (NSArray<NSString *> *)sampleStrings {
    return @[@"john.doe@example.com", @"555-12-3456", @"4111-2222-3333-4444",
             @"jane.smith@test.com", @"+1-555-123-4567", @"alice.johnson@demo.org",
             @"987-65-4321", @"5555-4444-3333-2222", @"bob.wilson@sample.net",
             @"+44-20-7946-0958", @"michael.brown@example.co.uk", @"6011-1111-1111-1117"];
}

+ (NSArray<NSNumber *> *)sampleInts {
    return @[@123456, @987654, @555123, @789456, @111222, @333444, @567890, @246813];
}

+ (NSArray<NSNumber *> *)sampleLongs {
    return @[@9876543210LL, @1234567890LL, @5555666677LL, @9999888877LL,
             @7777666655LL, @4444333322LL, @8888999900LL, @2222111100LL];
}

+ (NSArray<NSNumber *> *)sampleFloats {
    return @[@123.45f, @987.65f, @555.12f, @789.33f,
             @111.22f, @333.44f, @567.89f, @246.81f];
}

+ (NSArray<NSNumber *> *)sampleDoubles {
    return @[@123.456789, @987.654321, @555.123456, @789.987654,
             @111.222333, @333.444555, @567.890123, @246.813579];
}

+ (NSArray<NSNumber *> *)sampleBooleans {
    return @[@YES, @NO, @YES, @YES, @NO, @NO, @YES, @NO];
}

+ (NSString *)displayNameForDataType:(CTDataType)type {
    switch (type) {
        case CTDataTypeString:  return @"String";
        case CTDataTypeInt:     return @"Int";
        case CTDataTypeLong:    return @"Long";
        case CTDataTypeFloat:   return @"Float";
        case CTDataTypeDouble:  return @"Double";
        case CTDataTypeBoolean: return @"Boolean";
    }
}

+ (NSString *)randomSampleStringForDataType:(CTDataType)type {
    switch (type) {
        case CTDataTypeString: {
            NSArray *a = [self sampleStrings];
            return a[arc4random_uniform((uint32_t)a.count)];
        }
        case CTDataTypeInt: {
            NSArray *a = [self sampleInts];
            return [a[arc4random_uniform((uint32_t)a.count)] stringValue];
        }
        case CTDataTypeLong: {
            NSArray *a = [self sampleLongs];
            return [a[arc4random_uniform((uint32_t)a.count)] stringValue];
        }
        case CTDataTypeFloat: {
            NSArray *a = [self sampleFloats];
            return [a[arc4random_uniform((uint32_t)a.count)] stringValue];
        }
        case CTDataTypeDouble: {
            NSArray *a = [self sampleDoubles];
            return [a[arc4random_uniform((uint32_t)a.count)] stringValue];
        }
        case CTDataTypeBoolean: {
            NSArray *a = [self sampleBooleans];
            return [a[arc4random_uniform((uint32_t)a.count)] boolValue] ? @"true" : @"false";
        }
    }
}

+ (NSArray *)batchSampleForDataType:(CTDataType)type {
    uint32_t batchSize = 3 + arc4random_uniform(5);  // 3–7 items
    switch (type) {
        case CTDataTypeString:  return [self shuffledPrefix:batchSize from:[self sampleStrings]];
        case CTDataTypeInt:     return [self shuffledPrefix:batchSize from:[self sampleInts]];
        case CTDataTypeLong:    return [self shuffledPrefix:batchSize from:[self sampleLongs]];
        case CTDataTypeFloat:   return [self shuffledPrefix:batchSize from:[self sampleFloats]];
        case CTDataTypeDouble:  return [self shuffledPrefix:batchSize from:[self sampleDoubles]];
        case CTDataTypeBoolean: return [self shuffledPrefix:batchSize from:[self sampleBooleans]];
    }
}

+ (NSArray *)shuffledPrefix:(NSUInteger)count from:(NSArray *)array {
    NSMutableArray *copy = [array mutableCopy];
    for (NSUInteger i = copy.count - 1; i > 0; i--) {
        NSUInteger j = arc4random_uniform((uint32_t)(i + 1));
        [copy exchangeObjectAtIndex:i withObjectAtIndex:j];
    }
    NSUInteger take = MIN(count, copy.count);
    return [copy subarrayWithRange:NSMakeRange(0, take)];
}

@end
