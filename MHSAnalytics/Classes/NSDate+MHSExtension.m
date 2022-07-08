//
//  NSDate+MHSExtension.m
//  MHSRecommendAnalyticsSDK
//
//  Created by 东东 on 2022/7/6.
//

#import "NSDate+MHSExtension.h"

@implementation NSDate (MHSExtension)
/**
 *  提供格式转换为符合的时间字符串
 */
- (NSString *)mhs_coverDateWithForMatter:(NSString *)formatter {
    NSDateFormatter *dateformatter = [[NSDateFormatter alloc]init];
    dateformatter.dateFormat = formatter;
    return [dateformatter stringFromDate:self];
}
+ (NSString *)mhs_coverCurrentDateWithForMatter:(NSString *)formatter
{
    return [[NSDate date] mhs_coverDateWithForMatter:formatter];
}
+ (NSString *)mhs_currentDateNormalFormat
{
    return [NSDate mhs_coverCurrentDateWithForMatter:@"yyyy-MM-dd HH:mm:ss"];
}
@end
