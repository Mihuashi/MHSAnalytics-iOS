//
//  MHSAnalyticsDataContainer.m
//  MHSRecommendAnalyticsSDK
//
//  Created by 东东 on 2022/7/6.
//

#import "MHSAnalyticsDataContainer.h"
#import "NSDate+MHSExtension.h"
@interface MHSAnalyticsDataContainer()
@property (nonatomic, strong, readwrite) NSMutableDictionary<NSString *,id> *baseProperties;
@end

@implementation MHSAnalyticsDataContainer

+ (instancetype)dataContainer
{
    static MHSAnalyticsDataContainer *_container;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _container = [[MHSAnalyticsDataContainer alloc] init];
    });
    return _container;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self cacheContainerData];
    }
    return self;
}

- (void)cacheContainerData
{
    self.baseProperties = [NSMutableDictionary dictionary];
    self.baseProperties[@"eventTime"] = [NSDate mhs_currentDateNormalFormat];
    self.baseProperties[@"userType"] = @"user";
}

- (void)updateBaseProperties:(NSMutableDictionary<NSString *,id> *)baseProperties
{
    self.baseProperties = baseProperties;
}

- (void)updateUserId:(NSString *)userId
{
    self.baseProperties[@"userId"] = userId;
}
- (void)updateUserType:(NSString *)userType
{
    self.baseProperties[@"userType"] = userType;
}
- (void)updateUserTypeWithType:(MHSAnalyticsUserType)userType
{
    self.baseProperties[@"userType"] = (userType == MHSAnalyticsUserTypeArtist) ? @"artist" : @"user";
}
@end
