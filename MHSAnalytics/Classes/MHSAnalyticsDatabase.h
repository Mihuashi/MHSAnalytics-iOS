//
//  MHSAnalyticsDatabase.h
//  MHSRecommendAnalyticsSDK
//
//  Created by 东东 on 2022/7/6.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
NS_ASSUME_NONNULL_BEGIN

@interface MHSAnalyticsDatabase : NSObject
///数据库文件路径
@property (nonatomic, copy, readonly) NSString *filePath;

@property (nonatomic) sqlite3 *database;

///本地事件存储总量
@property (nonatomic) NSUInteger eventCount;

/**
 初始化方法
 */
- (instancetype)initWithFilePath:(nullable NSString *)filePath NS_DESIGNATED_INITIALIZER;

/**
 同步向数据库中插入事件
 */
- (void)insertEvent:(NSDictionary *)event;

/**
 从数据库中获取事件数据
 */
- (NSArray<NSDictionary *> *)selectEventsForCount:(NSUInteger)count;

/**
 从数据库中删除一定数量的事件数据
 */
- (BOOL)deleteEventsForCount:(NSUInteger)count;
@end

NS_ASSUME_NONNULL_END
