//
//  MHSAnalyticsDatabase.m
//  MHSRecommendAnalyticsSDK
//
//  Created by 东东 on 2022/7/6.
//

#import "MHSAnalyticsDatabase.h"

static NSString * const SensorsAnalyticsDefaultDatabaseName = @"MHS.analyticsDatabase.sqlite";

@interface MHSAnalyticsDatabase()
@property (nonatomic, copy) NSString *filePath;

@property (nonatomic, strong) dispatch_queue_t queue;
@end

@implementation MHSAnalyticsDatabase
{
    sqlite3 *_database;
}

- (instancetype)init {
    return [self initWithFilePath:nil];
}

- (instancetype)initWithFilePath:(NSString *)filePath {
    self = [super init];
    if (self) {
        _filePath = filePath ?: [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:SensorsAnalyticsDefaultDatabaseName];

        // 初始化队列的唯一标识
        NSString *label = [NSString stringWithFormat:@"cn.analyticsdata.serialQueue.%p", self];
        // 创建一个 serial 类型的 queue，即 FIFO
        _queue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);

        [self open];
        [self queryLocalDatabaseEventCount];
    }
    return self;
}

- (void)open {
    dispatch_async(self.queue, ^{
        // 初始化 SQLite 库
        if (sqlite3_initialize() != SQLITE_OK) {
            return ;
        }
        // 打开数据库，获取数据库指针
        if (sqlite3_open_v2([self.filePath UTF8String], &(self->_database), SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL) != SQLITE_OK) {
            NSLog(@"SQLite stmt prepare error: %s", sqlite3_errmsg(self.database));
            return;
        }
        char *error;
        // 创建数据库表的 sql 语句
        NSString *sql = @"CREATE TABLE IF NOT EXISTS events (id INTEGER PRIMARY KEY AUTOINCREMENT, event BLOB);";
        // 运行创建表格的 sql 语句
        if (sqlite3_exec(self.database, [sql UTF8String], NULL, NULL, &error) != SQLITE_OK) {
            NSLog(@"Create events Failure %s", error);
            return;
        }
    });
}

static sqlite3_stmt *insertStmt = NULL;
- (void)insertEvent:(NSDictionary *)event {
    if (!event) return;
    dispatch_async(self.queue, ^{
        if (insertStmt) {
            // 重置插入语句，重制之后可重新绑定数据
            sqlite3_reset(insertStmt);
        } else {
            // 插入语句
            NSString *sql = @"INSERT INTO events (event) values (?)";
            // 准备执行 SQL 语句，获取 sqlite3_stmt
            if (sqlite3_prepare_v2(self.database, sql.UTF8String, -1, &insertStmt, NULL) != SQLITE_OK) {
                // 准备执行 SQL 语句失败，打印 log 返回失败（NO）
                NSLog(@"SQLite stmt prepare error: %s", sqlite3_errmsg(self.database));
                return;
            }
        }

        NSError *error = nil;
        // 将 event 转换成 json 数据
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:event];
        NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
        if (error) {
            // event 转换失败，打印 log 返回失败（NO）
            NSLog(@"JSON Serialization error: %@", error);
            return;
        }
        // 将 json 数据与 stmt 绑定
        sqlite3_bind_blob(insertStmt, 1, data.bytes, (int)data.length, SQLITE_TRANSIENT);
        // 执行 stmt
        if (sqlite3_step(insertStmt) != SQLITE_DONE) {
            // 执行失败，打印 log 返回失败（NO）
            NSLog(@"Insert event into events error");
            return;
        }
        // 数据插入成功，事件数量加一
        self.eventCount++;
    });
}

// 最后一次查询的事件数量
static NSUInteger lastSelectEventCount = 50;
static sqlite3_stmt *selectStmt = NULL;
- (NSArray<NSDictionary *> *)selectEventsForCount:(NSUInteger)count {
    // 初始化数组，用于存储查询到的事件数据
    NSMutableArray<NSDictionary *> *events = [NSMutableArray arrayWithCapacity:count];

    dispatch_sync(self.queue, ^{
        // 当本地事件数据为 0 时，直接返回
        if (self.eventCount == 0) {
            return ;
        }

        if (count != lastSelectEventCount) {
            lastSelectEventCount = count;
            selectStmt = NULL;
        }
        if (selectStmt) {
            // 重置查询语句，重制之后可重新查询数据
            sqlite3_reset(selectStmt);
        } else {
            // 查询语句
            NSString *sql = [NSString stringWithFormat:@"SELECT id, event FROM events ORDER BY id ASC LIMIT %lu", (unsigned long)count];
            // 准备执行 SQL 语句，获取 sqlite3_stmt
            if (sqlite3_prepare_v2(self.database, sql.UTF8String, -1, &selectStmt, NULL) != SQLITE_OK) {
                // 准备执行 SQL 语句失败，打印 log 返回失败（NO）
                //NSLog(@"SQLite stmt prepare error: %s", sqlite3_errmsg(self.database));
                return;
            }
        }

        // 执行 SQL 语句
        while (sqlite3_step(selectStmt) == SQLITE_ROW) {
            // 将当前查询的这条数据转换成 NSData 对象
            NSData *jsonData = [[NSData alloc] initWithBytes:sqlite3_column_blob(selectStmt, 1) length:sqlite3_column_bytes(selectStmt, 1)];
            NSError *error;
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                options:NSJSONReadingMutableContainers
                                                                  error:&error];
            if (!error) {
                [events addObject:dic];
            }
        }
    });
    return events;
}

- (BOOL)deleteEventsForCount:(NSUInteger)count {
    __block BOOL success = YES;
    dispatch_sync(self.queue, ^{
        // 当本地事件数据为 0 时，直接返回
        if (self.eventCount == 0) {
            return ;
        }
        // 删除语句
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM events WHERE id IN (SELECT id FROM events ORDER BY id ASC LIMIT %lu);", (unsigned long)count];
        char *errmsg;
        // 执行删除语句
        if (sqlite3_exec(self.database, sql.UTF8String, NULL, NULL, &errmsg) != SQLITE_OK) {
            success = NO;
            //NSLog(@"Failed to delete record msg=%s", errmsg);
            return;
        }
        self.eventCount = self.eventCount < count ? 0 : self.eventCount - count;
    });
    return success;
}

- (void)queryLocalDatabaseEventCount {
    dispatch_async(self.queue, ^{
        // 查询语句
        NSString *sql = @"SELECT count(*) FROM events;";
        sqlite3_stmt *stmt = NULL;
        // 准备执行 SQL 语句，获取 sqlite3_stmt
        if (sqlite3_prepare_v2(self.database, sql.UTF8String, -1, &stmt, NULL) != SQLITE_OK) {
            // 准备执行 SQL 语句失败，打印 log 返回失败（NO）
            //NSLog(@"SQLite stmt prepare error: %s", sqlite3_errmsg(self.database));
            return;
        }
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            self.eventCount = sqlite3_column_int(stmt, 0);
        }
    });
}
@end
