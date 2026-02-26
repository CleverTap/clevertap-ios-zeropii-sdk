//
//  AppDelegate.m
//  ZeroPIIObjCSample
//

#import "AppDelegate.h"
@import CleverTapZeroPiiSDK;

// MARK: - Sample Retry Policy

@interface SampleRetryPolicy : NSObject <RetryPolicy>
@end

@implementation SampleRetryPolicy

- (BOOL)shouldRetryWithAttempt:(NSInteger)attempt httpStatusCode:(NSNumber *)httpStatusCode {
    if (attempt >= 2) return NO;
    if (!httpStatusCode) return YES;  // network error → always retry
    NSArray<NSNumber *> *retryable = @[@429, @500, @502, @503, @504];
    return [retryable containsObject:httpStatusCode];
}

- (NSInteger)retryDelayMsWithAttempt:(NSInteger)attempt {
    return 1000 * (1 << (attempt + 1));  // 2000 ms, 4000 ms, 8000 ms …
}

@end

// MARK: - Sample Token Provider

@interface SampleTokenProvider : NSObject <AccessTokenProvider>
@end

@implementation SampleTokenProvider

- (void)fetchTokenWithCompletion:(void (^)(AccessTokenInfo * _Nullable, NSError * _Nullable))completion {
    NSURL *url = [NSURL URLWithString:@"https://auth-test.clevertap.net/auth/realms/master/protocol/openid-connect/token"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];

    NSString *body = @"grant_type=client_credentials"
                      "&client_id=navin-client"
                      "&client_secret=83EpGODDbeyepKaGRy1Srg4c4YVEFQG8";
    request.HTTPBody = [body dataUsingEncoding:NSUTF8StringEncoding];

    [[[NSURLSession sharedSession] dataTaskWithRequest:request
                                    completionHandler:^(NSData *data, NSURLResponse *resp, NSError *error) {
        if (error) { completion(nil, error); return; }
        NSError *parseError;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        NSString *token   = json[@"access_token"];
        NSNumber *expires = json[@"expires_in"];
        if (token && expires) {
            AccessTokenInfo *info = [[AccessTokenInfo alloc] initWithToken:token
                                                          expiresInSeconds:expires.integerValue];
            completion(info, nil);
        } else {
            completion(nil, [NSError errorWithDomain:@"SampleTokenProvider"
                                                code:-1
                                            userInfo:@{NSLocalizedDescriptionKey: @"Invalid auth response"}]);
        }
    }] resume];
}

@end

// MARK: - AppDelegate

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [ZeroPiiSDK initializeWithTokenProvider:[SampleTokenProvider new]
                                     apiUrl:@"https://vault.mangaforyou.com/ct-vault/"
                                   logLevel:ZeroPiiLogLevelDebug
                                retryPolicy:[SampleRetryPolicy new]];
    return YES;
}

@end
