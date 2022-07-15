//
//  MHSAnalyticsDataContainer.m
//  MHSRecommendAnalyticsSDK
//
//  Created by 东东 on 2022/7/6.
//

#import "MHSAnalyticsDataContainer.h"
#import "NSDate+MHSExtension.h"
#import "NSString+MHSDeviceInfo.h"
@interface MHSAnalyticsDataContainer()
@property (nonatomic, strong, readwrite) NSMutableDictionary<NSString *,id> *baseProperties;

@property (nonatomic, strong) NSMutableDictionary *contextProperties;
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
        self.pageMap = [NSMutableDictionary dictionary];
        self.ignorePageList = [NSArray array];
        [self cacheContextData];
        [self cacheContainerData];
    }
    return self;
}

- (void)cacheContextData
{
    self.contextProperties = [NSMutableDictionary dictionary];
    self.contextProperties[@"ip"] = [NSString ftsp_getDeviceIPAdress];
    self.contextProperties[@"os"] = @"iOS";
    self.contextProperties[@"osVersion"] = UIDevice.currentDevice.systemVersion;
    self.contextProperties[@"manufacturer"] = @"iPhone";
    self.contextProperties[@"dimensionDictModel"] = @"iPhone";
    self.contextProperties[@"appVersion"] = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
    self.contextProperties[@"platformType"] = @"app";
}

- (void)cacheContainerData
{
    self.baseProperties = [NSMutableDictionary dictionary];
    self.baseProperties[@"eventTime"] = [NSDate mhs_currentDateNormalFormat];
    self.baseProperties[@"userType"] = @"user";
    self.baseProperties[@"context"] = self.contextProperties;
}

- (void)updateBaseProperties:(NSMutableDictionary<NSString *,id> *)baseProperties
{
    self.baseProperties = baseProperties;
    self.baseProperties[@"context"] = self.contextProperties;
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


#pragma mark - setter
- (void)setPageLocalURL:(NSString *)pageLocalURL
{
    if (pageLocalURL == nil || pageLocalURL.length == 0) return;
    NSData *jsonData = [NSData dataWithContentsOfFile:pageLocalURL];
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:nil];
    if (data[@"PAGEPV"]) {
        self.pageMap = data[@"PAGEPV"];
    }
    if (data[@"ignorePageList"]) {
        self.ignorePageList = data[@"ignorePageList"];
    }
}
    
@end
