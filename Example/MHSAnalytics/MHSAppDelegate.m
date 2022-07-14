//
//  MHSAppDelegate.m
//  MHSAnalytics
//
//  Created by Visual on 07/08/2022.
//  Copyright (c) 2022 Visual. All rights reserved.
//

#import "MHSAppDelegate.h"
#import <MHSAnalytics.h>
@implementation MHSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    MHSAnalyticsConfig *config = [[MHSAnalyticsConfig alloc] initWithURL:@""];
    config.flushBulkSize = 20;
    config.flushInterval = 120;
    config.pageLocalURL = [[NSBundle mainBundle] pathForResource:@"MHSAnalyticsPage" ofType:@"json"];
    [MHSAnalytics startWithConfigOptions:config];
    //如果想控制上报触发的条数和时间间隔，请使用下面的API
//    [MHSAnalytics startWithServerURL:@"" flushBulkSize:100 flushInterval:30];
//    [[MHSAnalytics sharedInstance] openAnalytics:YES];//控制是否开启埋点，默认开启
//    [[MHSAnalytics sharedInstance] privntLogs:YES];//控制台是否开启打印，默认开启
//    [[MHSAnalytics sharedInstance] updateUserId:@""];//更新用户ID，根据业务需要
//    [[MHSAnalytics sharedInstance] updateUserTypeWithType:MHSAnalyticsUserTypeUser];//更新用户角色，根据业务需要
//    [[MHSAnalytics sharedInstance] trackWithEvent:@""];//日志上报
//    [[MHSAnalytics sharedInstance]  trackWithEvent:@"" content:@{} context:@{}];//带附加属性的上报
//    [[MHSAnalytics sharedInstance] report];//主动上报
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
