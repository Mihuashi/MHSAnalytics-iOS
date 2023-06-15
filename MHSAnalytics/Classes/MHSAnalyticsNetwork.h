//
//  MHSAnalyticsNetwork.h
//  MHSRecommendAnalyticsSDK
//
//  Created by 东东 on 2022/7/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MHSAnalyticsNetwork : NSObject
- (instancetype)init NS_UNAVAILABLE;

/// 数据上报的服务器地址
@property (nonatomic, strong) NSURL *serverURL;

/**
 指定初始化方法

 @param serverURL 服务器 URL 地址
 @return 初始化对象
 */
- (instancetype)initWithServerURL:(NSURL *)serverURL topic:(NSString *)topic NS_DESIGNATED_INITIALIZER;

/**
同步发送事件数据

@param events JSON 格式的
@return 初始化对象
*/
- (BOOL)flushEvents:(NSArray *)events;

/**
 获取服务器时间
 */
- (void)getServerTimeWithCompletion:(void(^)(NSTimeInterval timestamp))completion;
@end

NS_ASSUME_NONNULL_END
