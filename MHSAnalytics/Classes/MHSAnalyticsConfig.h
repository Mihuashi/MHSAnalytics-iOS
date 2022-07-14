//
//  MHSAnalyticsConfig.h
//  MHSAnalytics
//
//  Created by 东东 on 2022/7/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MHSAnalyticsConfig : NSObject
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithURL:(NSString *)serverURL;
/**
 上报的接口URL
 */
@property (nonatomic, copy) NSString *serverURL;

/**
 满多少条上报 默认20条
 */
@property (nonatomic, assign) NSUInteger flushBulkSize;
/**
 满多少秒上报 默认120s
 */
@property (nonatomic, assign) NSUInteger flushInterval;
/**
 页面配置路径，包含page映射关系和黑名单
 */
@property (nonatomic, copy) NSString *pageLocalURL;
@end

NS_ASSUME_NONNULL_END
