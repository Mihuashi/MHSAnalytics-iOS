//
//  MHSAnalytics.h
//  MHSRecommendAnalytics
//
//  Created by 东东 on 2022/7/6.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MHSAnalyticsDataContainer.h"
#import "MHSAnalyticsConfig.h"
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
+ (void)startWithConfigOptions:(MHSAnalyticsConfig *)config;

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


#pragma mark - Track
@interface MHSAnalytics (Track)
/**
 业务埋点
 eventType：事件ID
 page：下标，如果没有则为0
 content：附加字段
 cls：所属页面
 */
- (void)trackWithEvent:(NSString *)eventType;
- (void)trackWithEvent:(NSString *)eventType content:(nullable NSDictionary<NSString *,id> *)content;
- (void)trackWithEvent:(NSString *)eventType content:(nullable NSDictionary<NSString *,id> *)content context:(nullable NSDictionary<NSString *,id> *)context;
//主动上报
- (void)report;
@end

#pragma mark - 曝光
@interface MHSAnalytics (Exposure)
//展示
- (void)exposureShowWithEvent:(NSString *)eventType eventId:(NSString *)eventId;

- (void)exposureHideWithEvent:(NSString *)eventType eventId:(NSString *)eventId content:(nullable NSDictionary<NSString *,id> *)content context:(nullable NSDictionary<NSString *,id> *)context;
//是否忽视1s的限制，只判断是否曝光过
- (void)exposureHideWithEvent:(NSString *)eventType eventId:(NSString *)eventId content:(nullable NSDictionary<NSString *,id> *)content context:(nullable NSDictionary<NSString *,id> *)context ignoreDuration:(BOOL)ignoreDuration;

//检查是否已经曝光 如果没有则立即曝光,返回是否已经曝光
- (BOOL)isExposureWithEvent:(NSString *)eventType eventId:(NSString *)eventId;
@end

NS_ASSUME_NONNULL_END
