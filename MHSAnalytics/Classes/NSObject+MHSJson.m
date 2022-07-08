//
//  NSObject+MHSKeyValue.m
//  MHSRecommendAnalyticsSDK
//
//  Created by 东东 on 2022/7/6.
//

#import "NSObject+MHSJson.h"

@implementation NSObject (MHSJson)
- (NSString *)mhs_JSONString
{
    if ([self isKindOfClass:[NSString class]]) {
        return (NSString *)self;
    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:0 error:nil];

    NSString *strJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    return strJson;
}



@end
