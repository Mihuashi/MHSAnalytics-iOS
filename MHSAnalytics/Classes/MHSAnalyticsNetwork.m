//
//  MHSAnalyticsNetwork.m
//  MHSRecommendAnalyticsSDK
//
//  Created by 东东 on 2022/7/6.
//

#import "MHSAnalyticsNetwork.h"
#import "NSObject+MHSJson.h"
#import "MHSURLRequestSerialization.h"
/// 网络请求结束处理回调类型
typedef void(^SAURLSessionTaskCompletionHandler)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error);

@interface MHSAnalyticsNetwork()<NSURLSessionDelegate>
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, copy) NSString *topic;
@end

@implementation MHSAnalyticsNetwork
- (instancetype)initWithServerURL:(NSURL *)serverURL topic:(nonnull NSString *)topic{
    self = [super init];
    if (self) {
        _serverURL = serverURL;
        _topic = topic;
       // 创建默认的 session 配置对象
       NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
       // 设置单个主机连接数为 5
       configuration.HTTPMaximumConnectionsPerHost = 5;
       // 设置请求的超时时间
       configuration.timeoutIntervalForRequest = 30;
       // 允许使用蜂窝网络连接
       configuration.allowsCellularAccess = YES;

       // 创建一个网络请求回调和完成操作的线程池
       NSOperationQueue *queue = [[NSOperationQueue alloc] init];
       // 设置同步运行的最大操作数为 1，即各操作 FIFO
       queue.maxConcurrentOperationCount = 1;

       // 通过配置对象创建一个 session 对象
       _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:queue];
    }
    return self;
}

- (NSString *)buildJSONStringWithEvents:(NSArray *)events {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"payload"] = [@{@"events": events ?: @""} mhs_JSONString];
//    params[@"payload"] = @{@"events": events};
    params[@"topic"] = _topic;
    return MHSQueryStringFromParameters(params);
}

- (NSURLRequest *)buildRequestWithJSONString:(NSString *)json {
    // 通过服务器 URL 地址创建请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.serverURL];
    // 设置请求的 body
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[self userAgent] forHTTPHeaderField:@"User-Agent"];
    [request setHTTPBody:[json dataUsingEncoding:NSUTF8StringEncoding]];
    // 请求方法
    request.HTTPMethod = @"POST";
    return request;
}

- (NSString *)userAgent
{
    NSString *userAgent = nil;
#if TARGET_OS_IOS
    // User-Agent Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.43
    userAgent = [NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)", [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleExecutableKey] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleIdentifierKey], [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], [[UIScreen mainScreen] scale]];
#elif TARGET_OS_WATCH
    // User-Agent Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.43
    userAgent = [NSString stringWithFormat:@"%@/%@ (%@; watchOS %@; Scale/%0.2f)", [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleExecutableKey] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleIdentifierKey], [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey], [[WKInterfaceDevice currentDevice] model], [[WKInterfaceDevice currentDevice] systemVersion], [[WKInterfaceDevice currentDevice] screenScale]];
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
    userAgent = [NSString stringWithFormat:@"%@/%@ (Mac OS X %@)", [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleExecutableKey] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleIdentifierKey], [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey], [[NSProcessInfo processInfo] operatingSystemVersionString]];
#endif
    if (userAgent) {
        if (![userAgent canBeConvertedToEncoding:NSASCIIStringEncoding]) {
            NSMutableString *mutableUserAgent = [userAgent mutableCopy];
            if (CFStringTransform((__bridge CFMutableStringRef)(mutableUserAgent), NULL, (__bridge CFStringRef)@"Any-Latin; Latin-ASCII; [:^ASCII:] Remove", false)) {
                userAgent = mutableUserAgent;
            }
        }
    }
    return userAgent;
}


- (BOOL)flushEvents:(NSArray *)events {
    // 将事件数组组装成 json 字符串
    NSString *jsonString = [self buildJSONStringWithEvents:events];
    // 创建请求对象
    NSURLRequest *request = [self buildRequestWithJSONString:jsonString];

    // 数据上传结果
    __block BOOL flushSuccess = NO;
    // 使用 GCD 中的信号量，实现线程锁
    dispatch_semaphore_t flushSemaphore = dispatch_semaphore_create(0);
    SAURLSessionTaskCompletionHandler handler = ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            // 当请求发生错误时，打印错误信息
            NSLog(@"Flush events error: %@", error);
            // 信号量，执行结束，不再等待
            dispatch_semaphore_signal(flushSemaphore);
            return;
        }
        // 获取请结束返回的状态码
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        // 当状态码为 2XX 时，表示事件发送成功
        if (statusCode >= 200 && statusCode < 300) {
            // 打印上传成功的数据
//            NSLog(@"Flush events success: %@", jsonString);
            // 数据上传成功
            flushSuccess = YES;
        } else {
            // 事件发送失败信息
            NSString *desc = [NSString stringWithFormat:@"Flush events error, statusCode: %d, events: %@", (int)statusCode, jsonString];
            NSLog(@"%@", desc);
        }
        dispatch_semaphore_signal(flushSemaphore);
    };

    // 通过 request 创建请求任务
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:handler];
    // 执行任务
    [task resume];

    // 等待请求完成
    dispatch_semaphore_wait(flushSemaphore, DISPATCH_TIME_FOREVER);

    // 返回数据上传结果
    return flushSuccess;
}

- (void)getServerTimeWithCompletion:(void (^)(NSTimeInterval))completion
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://www.mihuashi.com/api/v1/utils/infos"]];
    // 请求方法
    request.HTTPMethod = @"GET";
    SAURLSessionTaskCompletionHandler handler = ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            return;
        }
        // 获取请结束返回的状态码
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        // 当状态码为 2XX 时，表示事件发送成功
        if (statusCode >= 200 && statusCode < 300) {
            NSError *error;
            NSDictionary *resultDic = [NSJSONSerialization JSONObjectWithData:data
                                                                      options:NSJSONReadingMutableContainers
                                                                        error:&error];
            if (!error && resultDic.count) {
                NSTimeInterval timestamp = [resultDic[@"timestamp"] doubleValue];
                !completion ?: completion(timestamp);
            }
        } else {
            
        }
    };

    // 通过 request 创建请求任务
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:handler];
    // 执行任务
    [task resume];
}
@end
