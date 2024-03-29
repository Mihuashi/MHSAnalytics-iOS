//
//  MHSAnalytics.m
//  MHSRecommendAnalytics
//
//  Created by 东东 on 2022/7/6.
//

#import "MHSAnalytics.h"
#import "MHSAnalyticsDatabase.h"
#import "MHSAnalyticsNetwork.h"
#import "NSDate+MHSExtension.h"

// 默认一次向服务器发送的条数
static NSUInteger const MHSAnalyticsDefalutFlushEventCount = 20;


@interface MHSAnalytics()

//队列
@property (nonatomic, strong) dispatch_queue_t serialQueue;

/// 数据库存储对象
@property (nonatomic, strong) MHSAnalyticsDatabase *database;


@property (nonatomic, strong) NSURL *serverURL;
/// 数据上传等网络请求对象
@property (nonatomic, strong) MHSAnalyticsNetwork *network;

/// 定时上传事件的 Timer
@property (nonatomic, strong) NSTimer *flushTimer;

///当本地存储的事件达到这个数量时，上传数据(默认为100)
@property (nonatomic, assign) NSUInteger flushBulkSize;
///两次数据发送的时间间隔，单位秒(默认为30S)
@property (nonatomic, assign) NSUInteger flushInterval;

// 是否打开控制台输出
@property (nonatomic, assign) BOOL isOpenPrivnt;
// 是否打开埋点
@property (nonatomic, assign) BOOL isOpenAnalytics;

/// 标记应用程序是否将进入非活跃状态
@property (nonatomic) BOOL applicationWillResignActive;
/// 标记应用程序是否进入了后台  用来区分是不是从后台唤醒
@property (nonatomic) BOOL applicationDidEnterBackground;

//记录曝光的开始时间，如果少于1秒则不上报
@property (nonatomic, strong) NSMutableDictionary *exposureTimer;
//记录已经曝光的埋点，在APP运行期间，1个曝光事件只传一次
@property (nonatomic, strong) NSMutableDictionary *exposureEvents;

//时间偏差值，防止手动调时间
@property (nonatomic, assign) NSTimeInterval timeDiffValue;
@end

@implementation MHSAnalytics

#pragma mark - 初始化
static MHSAnalytics *sharedInstance = nil;

+ (void)startWithConfigOptions:(MHSAnalyticsConfig *)config
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MHSAnalytics alloc] initWithConfig:config];
    });
}


+ (MHSAnalytics *)sharedInstance {
    return sharedInstance;
}

- (instancetype)initWithConfig:(MHSAnalyticsConfig *)config {
    self = [super init];
    if (self) {
        
        self.exposureTimer = [NSMutableDictionary dictionary];
        self.exposureEvents = [NSMutableDictionary dictionary];
        
        _flushBulkSize = config.flushBulkSize;
        _flushInterval = config.flushInterval;

        NSString *queueLabel = [NSString stringWithFormat:@"mhs.analyticsdata.%@.%p", self.class, self];
        _serialQueue = dispatch_queue_create([queueLabel UTF8String], DISPATCH_QUEUE_SERIAL);


        // 初始化 SensorsAnalyticsDatabase 类的对象，使用默认路径
        _database = [[MHSAnalyticsDatabase alloc] init];
        
        //page页面路径，存储page映射关系及黑名单
        [MHSAnalyticsDataContainer dataContainer].pageLocalURL = config.pageLocalURL;
        
        _network = [[MHSAnalyticsNetwork alloc] initWithServerURL:[NSURL URLWithString:config.serverURL] topic:config.topic];

        _isOpenAnalytics = YES;//默认打开上传
        _isOpenPrivnt = YES;//默认打开控制台打印
        
        // 添加应用程序状态监听
        [self setupListeners];
        // 开启定时器
        [self startFlushTimer];
        
        
    }
    return self;
}



#pragma mark - 定时器
/// 开启上传数据的定时器
- (void)startFlushTimer {
    if (self.flushTimer) {
        return;
    }
    NSTimeInterval interval = self.flushInterval < 5 ? 5 : self.flushInterval;
    self.flushTimer = [NSTimer timerWithTimeInterval:interval target:self selector:@selector(flush) userInfo:nil repeats:YES];
    [NSRunLoop.currentRunLoop addTimer:self.flushTimer forMode:NSRunLoopCommonModes];
}

// 停止上传数据的定时器
- (void)stopFlushTimer {
    [self.flushTimer invalidate];
    self.flushTimer = nil;
}

#pragma mark - 上报
- (void)flush {
    dispatch_async(self.serialQueue, ^{
        // 默认一次向服务端发送 100 条数据
        [self flushByEventCount:MHSAnalyticsDefalutFlushEventCount background:NO isLaunching:NO];
    });
}

- (void)flushByEventCount:(NSUInteger)count background:(BOOL)background isLaunching:(BOOL)isLaunching {

    // 获取本地数据
    NSArray<NSDictionary *> *events = [self.database selectEventsForCount:count];
    if (!events.count) return;
    //启动时检查是否有上次遗留的events,如果有的话加delayed_at上报
    if (isLaunching) {
        NSMutableArray *array = [NSMutableArray array];
        NSTimeInterval timestamp = [MHSAnalytics currentTime] + self.timeDiffValue;
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
        NSString *delayedAt = [date mhs_coverDateWithForMatter:@"yyyy-MM-dd HH:mm:ss Z"];
        for (NSDictionary *dict in events) {
            NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithDictionary:dict];
            if (mutableDict[@"context"]) {
                NSMutableDictionary *context = [NSMutableDictionary dictionaryWithDictionary:mutableDict[@"context"]];
                context[@"delayed_at"] = delayedAt;
                mutableDict[@"context"] = context;
            }
            [array addObject:mutableDict];
        }
        events = [array copy];
    }
    if (!_isOpenAnalytics) return;//没有打开则不上传
    // 当本地存储的数据为 0 或者上传失败时，直接返回，退出递归调用
    if (events.count == 0 || ![self.network flushEvents:events]) {
        return;
    }
    // 当删除数据失败时，直接返回退出递归调用，防止死循环
    if (![self.database deleteEventsForCount:count]) {
        return;
    }

    // 继续上传本地的其他数据
    [self flushByEventCount:count background:background isLaunching:isLaunching];
    
}

#pragma mark - private methods
- (void)privntLogs:(BOOL)isOpen
{
    _isOpenPrivnt = isOpen;
}

- (void)openAnalytics:(BOOL)isOpen
{
    _isOpenAnalytics = isOpen;
}

- (void)printEvent:(NSDictionary *)event {
    if (!_isOpenPrivnt) return;
#if DEBUG
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:event options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        NSLog(@"JSON Serialized Error: %@", error);
        return;
    }
    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"[MHSAnalytics-Event]: %@", json);
#endif
}

#pragma mark - public methods
- (void)updateUserId:(NSString *)userId
{
    [[MHSAnalyticsDataContainer dataContainer] updateUserId:userId];
}
- (void)updateUserType:(NSString *)userType
{
    [[MHSAnalyticsDataContainer dataContainer] updateUserType:userType];
}
- (void)updateUserTypeWithType:(MHSAnalyticsUserType)userType
{
    [[MHSAnalyticsDataContainer dataContainer] updateUserTypeWithType:userType];
}
#pragma mark - 通知
- (void)setupListeners {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    // 监听 UIApplicationDidEnterBackgroundNotification，即当应用程序进入后台之后会调用通知方法
    [center addObserver:self
               selector:@selector(applicationDidEnterBackground:)
                   name:UIApplicationDidEnterBackgroundNotification
                 object:nil];

    // 监听 UIApplicationDidBecomeActiveNotification，即当应用程序进入进入前台并处于活动状态时，会调用通知方法
    [center addObserver:self
               selector:@selector(applicationDidBecomeActive:)
                   name:UIApplicationDidBecomeActiveNotification
                 object:nil];
    
    [center addObserver:self selector:@selector(applicationDidFinishLaunching:) name:UIApplicationDidFinishLaunchingNotification object:nil];
    
    [center addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {

    self.applicationWillResignActive = NO;
    self.applicationDidEnterBackground = YES;

    dispatch_async(self.serialQueue, ^{
        // 发送数据
        [self flushByEventCount:MHSAnalyticsDefalutFlushEventCount background:YES isLaunching:NO];
    });

    // 停止计时器
    [self stopFlushTimer];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    self.applicationDidEnterBackground = NO;
    // 开始计时器
    [self startFlushTimer];
    // 时间校对
    [self requestSeverTime];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    dispatch_async(self.serialQueue, ^{
        // 发送数据
        [self flushByEventCount:MHSAnalyticsDefalutFlushEventCount background:YES isLaunching:YES];
    });
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [self report];//结束APP前全部上报
}

- (void)requestSeverTime
{
    __weak typeof(self) weakSelf = self;
    [self.network getServerTimeWithCompletion:^(NSTimeInterval timestamp) {
        [weakSelf repeatLocalTime:timestamp];
    }];
}

//本地时间校对
- (void)repeatLocalTime:(NSTimeInterval)serverTime
{
    //获取当前时间戳
    NSTimeInterval curTime = [MHSAnalytics currentTime];
    if (fabs(serverTime - curTime) > 10) {
        self.timeDiffValue = serverTime - curTime;
    }
}

#pragma mark - Property
+ (double)currentTime {
    return [[NSDate date] timeIntervalSince1970];
}

+ (double)systemUpTime {
    return NSProcessInfo.processInfo.systemUptime;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end


#pragma mark - Track
@implementation MHSAnalytics (Track)

- (void)trackWithEvent:(NSString *)eventType {
    [self trackWithEvent:eventType content:nil context:nil];
}
- (void)trackWithEvent:(NSString *)eventType content:(NSDictionary<NSString *,id> *)content
{
    [self trackWithEvent:eventType content:content context:nil];
}
- (void)trackWithEvent:(NSString *)eventType content:(nullable NSDictionary<NSString *,id> *)content context:(nullable NSDictionary<NSString *,id> *)context
{
    if (!_isOpenAnalytics) return;
    
    NSMutableDictionary *event = [NSMutableDictionary dictionaryWithDictionary:[MHSAnalyticsDataContainer dataContainer].baseProperties];
    //获取校验后时间戳
    NSTimeInterval timestamp = [MHSAnalytics currentTime] + self.timeDiffValue;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    event[@"eventTime"] = [date mhs_coverDateWithForMatter:@"yyyy-MM-dd HH:mm:ss Z"];
    event[@"eventType"] = eventType;
    NSMutableDictionary *contentProperties = [NSMutableDictionary dictionaryWithDictionary:content];
    event[@"content"] = contentProperties;
    if (context.count) {
        NSMutableDictionary *baseContext = [[MHSAnalyticsDataContainer dataContainer].contextProperties mutableCopy];
        [baseContext addEntriesFromDictionary:context];
        event[@"context"] = baseContext;
    }
//    event[@"page"] = [MHSAnalyticsDataContainer dataContainer].pageMap[NSStringFromClass(cls)];
//    dispatch_async(self.serialQueue, ^{
        [self printEvent:event];
        [self.database insertEvent:event];
//    });

    if (self.database.eventCount >= self.flushBulkSize) {
        [self flush];
    }
}

- (void)report
{
    [self flush];
}
@end


#pragma mark - 曝光
@implementation MHSAnalytics (Exposure)

//展示
- (void)exposureShowWithEvent:(NSString *)eventType eventId:(NSString *)eventId
{
    NSString *exposeKey = [self exposureKeyWithEvent:eventType eventId:eventId];
    self.exposureTimer[exposeKey] = @([MHSAnalytics systemUpTime]);
}

- (void)exposureHideWithEvent:(NSString *)eventType eventId:(NSString *)eventId content:(nullable NSDictionary<NSString *,id> *)content context:(nullable NSDictionary<NSString *,id> *)context
{
    [self exposureHideWithEvent:eventType eventId:eventId content:content context:context ignoreDuration:NO];
}

- (void)exposureHideWithEvent:(NSString *)eventType eventId:(NSString *)eventId content:(nullable NSDictionary<NSString *,id> *)content context:(nullable NSDictionary<NSString *,id> *)context ignoreDuration:(BOOL)ignoreDuration
{
    NSString *exposeKey = [self exposureKeyWithEvent:eventType eventId:eventId];
    
    BOOL isExpose = [self isExposureWithEvent:eventType eventId:eventId];
    
    if (isExpose) return;//如果APP运行期间已经曝光过了则不再曝光
    double beginTime = [self.exposureTimer[exposeKey] doubleValue];
    double currentTime = [MHSAnalytics systemUpTime];
    double duration = currentTime - beginTime;
    if (!ignoreDuration && duration < 1) return;//小于1秒并且非立即上报
    self.exposureEvents[exposeKey] = @(YES);//记录已经曝光
    [self trackWithEvent:eventType content:content context:context];//上报曝光
}


- (BOOL)isExposureWithEvent:(NSString *)eventType eventId:(nonnull NSString *)eventId
{
    NSString *exposeKey = [self exposureKeyWithEvent:eventType eventId:eventId];
    if (!self.exposureEvents[exposeKey]) return NO;
    return [self.exposureEvents[exposeKey] boolValue];
}

- (NSString *)exposureKeyWithEvent:(NSString *)eventType eventId:(NSString *)eventId
{
    return [NSString stringWithFormat:@"%@_%@",eventType,eventId];
}
@end
