//
//  MHSAnalyticsConfig.m
//  MHSAnalytics
//
//  Created by 东东 on 2022/7/14.
//

#import "MHSAnalyticsConfig.h"

@implementation MHSAnalyticsConfig

- (instancetype)initWithURL:(NSString *)serverURL
{
    self = [super init];
    if (self) {
        self.serverURL = serverURL;
        self.flushBulkSize = 20;
        self.flushInterval = 120;
    }
    return self;
}

@end
