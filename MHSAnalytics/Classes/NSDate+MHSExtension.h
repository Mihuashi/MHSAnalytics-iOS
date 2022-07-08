//
//  NSDate+MHSExtension.h
//  MHSRecommendAnalyticsSDK
//
//  Created by 东东 on 2022/7/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDate (MHSExtension)
+ (NSString *)mhs_currentDateNormalFormat;
- (NSString *)mhs_coverDateWithForMatter:(NSString *)formatter;
+ (NSString *)mhs_coverCurrentDateWithForMatter:(NSString *)formatter;
@end

NS_ASSUME_NONNULL_END
