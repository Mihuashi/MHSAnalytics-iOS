//
//  MHSAnalytics.h
//  MHSRecommendAnalytics
//
//  Created by 东东 on 2022/7/6.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MHSAnalyticsDataContainer.h"
NS_ASSUME_NONNULL_BEGIN

@interface MHSAnalytics : NSObject

- (instancetype)init NS_UNAVAILABLE;

/**
 获取SDK实例
 */
+ (instancetype)sharedInstance;

/**
 初始化SDK
 */
+ (void)startWithServerURL:(NSString *)urlString;
/**
 初始化SDK
 @param bulkSize 多少条上报一次 默认100条
 @param flushInterval 多少秒上报一次 默认30S
 */
+ (void)startWithServerURL:(NSString *)urlString flushBulkSize:(NSUInteger)bulkSize flushInterval:(NSUInteger)flushInterval;
/**
 向服务器发送本地数据
 */
- (void)flush;

/**
 打开控制台输出
 */
- (void)privntLogs:(BOOL)isOpen;

/**
 开始埋点
 */
- (void)openAnalytics:(BOOL)isOpen;

/**
 更新userId
 */
- (void)updateUserId:(NSString *)userId;
/**
 更新userType
 */
- (void)updateUserType:(NSString *)userType;
- (void)updateUserTypeWithType:(MHSAnalyticsUserType)userType;
@end



@interface MHSAnalytics (Track)
//业务埋点
- (void)trackWithEvent:(NSString *)eventType;
- (void)trackWithEvent:(NSString *)eventType content:(nullable NSDictionary<NSString *,id> *)content;
- (void)trackWithEvent:(NSString *)eventType content:(nullable NSDictionary<NSString *,id> *)content context:(nullable NSDictionary<NSString *,id> *)context;
//主动上报
- (void)report;
@end

NS_ASSUME_NONNULL_END
