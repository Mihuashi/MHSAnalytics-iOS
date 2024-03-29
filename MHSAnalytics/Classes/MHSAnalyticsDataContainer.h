//
//  MHSAnalyticsDataContainer.h
//  MHSRecommendAnalyticsSDK
//
//  Created by 东东 on 2022/7/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MHSAnalyticsUserType) {
    MHSAnalyticsUserTypeUser,//企划方
    MHSAnalyticsUserTypeArtist//画师
};

@interface MHSAnalyticsDataContainer : NSObject

+ (instancetype)dataContainer;

@property (nonatomic, copy) NSString *pageLocalURL;

@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *,id> *baseProperties;
@property (nonatomic, strong) NSMutableDictionary *contextProperties;
/**
 page映射表
 */
@property (nonatomic, strong) NSMutableDictionary *pageMap;
/**
 page黑名单
 */
@property (nonatomic, strong) NSArray *ignorePageList;

- (void)updateUserId:(NSString *)userId;
- (void)updateUserType:(NSString *)userType;
- (void)updateUserTypeWithType:(MHSAnalyticsUserType)userType;
- (void)updateBaseProperties:(NSMutableDictionary<NSString *,id> *)baseProperties;
@end

NS_ASSUME_NONNULL_END
