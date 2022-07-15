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
//业务埋点
- (void)trackWithEvent:(NSString *)eventType;
- (void)trackWithEvent:(NSString *)eventType content:(nullable NSDictionary<NSString *,id> *)content;
- (void)trackWithEvent:(NSString *)eventType content:(nullable NSDictionary<NSString *,id> *)content page:(nullable Class)cls;
//主动上报
- (void)report;
@end

#pragma mark - 曝光
@interface MHSAnalytics (Exposure)
//展示
- (void)exposureShowWithEvent:(NSString *)eventType;
//隐藏
- (void)exposureHideWithEvent:(NSString *)eventType;
- (void)exposureHideWithEvent:(NSString *)eventType content:(nullable NSDictionary<NSString *,id> *)content;
- (void)exposureHideWithEvent:(NSString *)eventType content:(nullable NSDictionary<NSString *,id> *)content page:(nullable Class)cls;


@end

NS_ASSUME_NONNULL_END
