#import "SqflitePlugin.h"
#import "SqfliteDatabase.h"
#import "SqfliteOperation.h"
#import "SqfliteFmdbImport.m"

#import <sqlite3.h>

static NSString *const _channelName = @"com.tekartik.sqflite";
static NSString *const _inMemoryPath = @":memory:";

static NSString *const _methodGetPlatformVersion = @"getPlatformVersion";
static NSString *const _methodGetDatabasesPath = @"getDatabasesPath";
static NSString *const _methodDebugMode = @"debugMode";
static NSString *const _methodDebug = @"debug";
static NSString *const _methodOptions = @"options";
static NSString *const _methodOpenDatabase = @"openDatabase";
static NSString *const _methodCloseDatabase = @"closeDatabase";
static NSString *const _methodDeleteDatabase = @"deleteDatabase";
static NSString *const _methodDatabaseExists = @"databaseExists";

static NSString *const _methodQueryCursorNext = @"queryCursorNext";
static NSString *const _methodBatch = @"batch";

// For open
static NSString *const _paramReadOnly = @"readOnly";
static NSString *const _paramSingleInstance = @"singleInstance";
// Open result
static NSString *const _paramRecovered = @"recovered";
static NSString *const _paramRecoveredInTransaction = @"recoveredInTransaction";

// For batch
static NSString *const _paramOperations = @"operations";
// For each batch operation
static NSString *const _paramPath = @"path";
static NSString *const _paramId = @"id";
static NSString *const _paramTable = @"table";
static NSString *const _paramValues = @"values";



static NSString *const _errorOpenFailed = @"open_failed";
static NSString *const _errorDatabaseClosed = @"database_closed";

// debug
static NSString *const _paramDatabases = @"databases";
static NSString *const _paramLogLevel = @"logLevel";
static NSString *const _paramCmd = @"cmd";
static NSString *const _paramCmdGet = @"get";

// query
static NSString *const _paramCancel = @"cancel";
static NSString *const _paramCursorId = @"cursorId";
static NSString *const _paramCursorPageSize = @"cursorPageSize";

// Shared
NSString *const SqfliteMethodExecute = @"execute";
NSString *const SqfliteMethodInsert = @"insert";
NSString *const SqfliteMethodUpdate = @"update";
NSString *const SqfliteMethodQuery = @"query";

NSString *const SqliteErrorCode = @"sqlite_error";
NSString *const SqfliteErrorBadParam = @"bad_param"; // internal only

NSString *const SqfliteParamSql = @"sql";
NSString *const SqfliteParamSqlArguments = @"arguments";
NSString *const SqfliteParamInTransactionChange = @"inTransaction";
NSString *const SqfliteParamTransactionId = @"transactionId"; // int or null
NSString *const SqfliteParamNoResult = @"noResult";
NSString *const SqfliteParamContinueOnError = @"continueOnError";
NSString *const SqfliteParamMethod = @"method";
// For each operation in a batch, we have either a result or an error
NSString *const SqfliteParamResult = @"result";
NSString *const SqfliteParamError = @"error";
NSString *const SqfliteParamErrorCode = @"code";
NSString *const SqfliteParamErrorMessage = @"message";
NSString *const SqfliteParamErrorData = @"data";

// iOS workaround bug #214
NSString *const SqfliteSqlPragmaSqliteDefensiveOff = @"PRAGMA sqflite -- db_config_defensive_off";

// Import hidden method
@interface FMDatabase ()
- (void)resultSetDidClose:(FMResultSet *)resultSet;
@end

@interface SqflitePlugin ()

@property (atomic, retain) NSMutableDictionary<NSNumber*, SqfliteDatabase*>* databaseMap;
@property (atomic, retain) NSMutableDictionary<NSString*, SqfliteDatabase*>* singleInstanceDatabaseMap;
@property (atomic, retain) NSObject* mapLock;

@end



// True for basic debugging (open/close and sql)
bool sqfliteHasSqlLogLevel(int logLevel) {
    return logLevel >= sqfliteLogLevelSql;
}

// True for verbose debugging
bool sqfliteHasVerboseLogLevel(int logLevel) {
    return logLevel >= sqfliteLogLevelVerbose;
}

//
// Implementation
//


@implementation SqflitePlugin

@synthesize databaseMap;
@synthesize mapLock;

static int logLevel = sqfliteLogLevelNone;

// static BOOL _log = false;
static BOOL _extra_log = false;

static BOOL __extra_log = false; // to set to true for type debugging

static NSInteger _lastDatabaseId = 0;
static NSInteger _databaseOpenCount = 0;


+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
#if TARGET_OS_IPHONE
    FlutterMethodChannel* channel =
    [[FlutterMethodChannel alloc] initWithName:_channelName
                               binaryMessenger:[registrar messenger]
                                         codec:[FlutterStandardMethodCodec sharedInstance]
                                     taskQueue:[registrar.messenger makeBackgroundTaskQueue]];
#else
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:_channelName
                                     binaryMessenger:[registrar messenger]];
#endif
    SqflitePlugin* instance = [[SqflitePlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.databaseMap = [NSMutableDictionary new];
        self.singleInstanceDatabaseMap = [NSMutableDictionary new];
        self.mapLock = [NSObject new];
    }
    return self;
}

- (SqfliteDatabase *)getDatabaseOrError:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSNumber* databaseId = call.arguments[_paramId];
    SqfliteDatabase* database = self.databaseMap[databaseId];
    if (database == nil) {
        NSLog(@"db not found.");
        result([FlutterError errorWithCode:SqliteErrorCode
                                   message: _errorDatabaseClosed
                                   details:nil]);
        
    }
    return database;
}

- (void)handleError:(FMDatabase*)db result:(FlutterResult)result {
    // handle error
    result([FlutterError errorWithCode:SqliteErrorCode
                               message:[NSString stringWithFormat:@"%@", [db lastError]]
                               details:nil]);
}

- (void)handleError:(FMDatabase*)db operation:(SqfliteOperation*)operation {
    NSMutableDictionary* details = nil;
    NSString* sql = [operation getSql];
    if (sql != nil) {
        details = [NSMutableDictionary new];
        [details setObject:sql forKey:SqfliteParamSql];
        NSArray* sqlArguments = [operation getSqlArguments];
        if (sqlArguments != nil) {
            [details setObject:sqlArguments forKey:SqfliteParamSqlArguments];
        }
    }
    
    [operation error:([FlutterError errorWithCode:SqliteErrorCode
                                          message:[NSString stringWithFormat:@"%@", [db lastError]]
                                          details:details])];
    
}

+ (NSObject*)toSqlValue:(NSObject*)value {
    if (_extra_log) {
        NSLog(@"value type %@ %@", [value class], value);
    }
    if (value == nil) {
        return nil;
    } else if ([value isKindOfClass:[FlutterStandardTypedData class]]) {
        FlutterStandardTypedData* typedData = (FlutterStandardTypedData*)value;
        return typedData.data;
    } else if ([value isKindOfClass:[NSArray class]]) {
        // Assume array of number
        // slow...to optimize
        NSArray* array = (NSArray*)value;
        NSMutableData* data = [NSMutableData new];
        for (int i = 0; i < [array count]; i++) {
            uint8_t byte = [((NSNumber *)[array objectAtIndex:i]) intValue];
            [data appendBytes:&byte length:1];
        }
        return data;
    } else {
        return value;
    }
}

+ (NSObject*)fromSqlValue:(NSObject*)sqlValue {
    if (_extra_log) {
        NSLog(@"sql value type %@ %@", [sqlValue class], sqlValue);
    }
    if (sqlValue == nil) {
        return [NSNull null];
    } else if ([sqlValue isKindOfClass:[NSData class]]) {
        return [FlutterStandardTypedData typedDataWithBytes:(NSData*)sqlValue];
    } else {
        return sqlValue;
    }
}

+ (bool)arrayIsEmpy:(NSArray*)array {
    return (array == nil || array == (id)[NSNull null] || [array count] == 0);
}

+ (NSArray*)toSqlArguments:(NSArray*)rawArguments {
    NSMutableArray* array = [NSMutableArray new];
    if (![SqflitePlugin arrayIsEmpy:rawArguments]) {
        for (int i = 0; i < [rawArguments count]; i++) {
            [array addObject:[SqflitePlugin toSqlValue:[rawArguments objectAtIndex:i]]];
        }
    }
    return array;
}

+ (NSDictionary*)fromSqlDictionary:(NSDictionary*)sqlDictionary {
    NSMutableDictionary* dictionary = [NSMutableDictionary new];
    [sqlDictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
        [dictionary setObject:[SqflitePlugin fromSqlValue:value] forKey:key];
    }];
    return dictionary;
}

// TODO remove
- (bool)executeOrError:(SqfliteDatabase*)database fmdb:(FMDatabase*)db call:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString* sql = call.arguments[SqfliteParamSql];
    NSArray* arguments = call.arguments[SqfliteParamSqlArguments];
    NSArray* sqlArguments = [SqflitePlugin toSqlArguments:arguments];
    BOOL argumentsEmpty = [SqflitePlugin arrayIsEmpy:arguments];
    if (sqfliteHasSqlLogLevel(database.logLevel)) {
        NSLog(@"%@ %@", sql, argumentsEmpty ? @"" : sqlArguments);
    }
    
    BOOL success;
    if (!argumentsEmpty) {
        success = [db executeUpdate: sql withArgumentsInArray: sqlArguments];
    } else {
        success = [db executeUpdate: sql];
    }
    
    // handle error
    if (!success) {
        [self handleError:db result:result];
        return false;
    }
    
    return true;
}

- (bool)executeOrError:(SqfliteDatabase*)database fmdb:(FMDatabase*)db operation:(SqfliteOperation*)operation {
    NSString* sql = [operation getSql];
    NSArray* sqlArguments = [operation getSqlArguments];
    NSNumber* inTransaction = [operation getInTransactionChange];
    
    // Handle Hardcoded workarounds
    // Handle issue #525
    if ([SqfliteSqlPragmaSqliteDefensiveOff isEqualToString:sql]) {
        sqlite3_db_config(db.sqliteHandle, SQLITE_DBCONFIG_DEFENSIVE, 0, 0);
    }
    
    BOOL argumentsEmpty = [SqflitePlugin arrayIsEmpy:sqlArguments];
    if (sqfliteHasSqlLogLevel(database.logLevel)) {
        NSLog(@"%@ %@", sql, argumentsEmpty ? @"" : sqlArguments);
    }
    
    BOOL success;
    if (!argumentsEmpty) {
        success = [db executeUpdate: sql withArgumentsInArray: sqlArguments];
    } else {
        success = [db executeUpdate: sql];
    }
    
    // If wanted, we leave the transaction even if it fails
    if (inTransaction != nil) {
        if (![inTransaction boolValue]) {
            database.inTransaction = false;
        }
    }
    
    // handle error
    if (!success) {
        [self handleError:db operation:operation];
        return false;
    }
    
    // We enter the transaction on success
    if (inTransaction != nil) {
        if ([inTransaction boolValue]) {
            database.inTransaction = true;
        }
    }
    
    return true;
}

// Rewrite to handle empty bloc reported as null
// refer to original FMResultSet.objectForColumnIndex, removed
// when fixed in FMDB
// See https://github.com/ccgus/fmdb/issues/350 for information
+ (id)rsObjectForColumn:(FMResultSet*)rs index:(int)columnIdx {
    FMStatement* _statement = [rs statement];
    if (columnIdx < 0 || columnIdx >= sqlite3_column_count([_statement statement])) {
        return nil;
    }
    
    int columnType = sqlite3_column_type([_statement statement], columnIdx);
    
    id returnValue = nil;
    
    if (columnType == SQLITE_INTEGER) {
        returnValue = [NSNumber numberWithLongLong:[rs longLongIntForColumnIndex:columnIdx]];
    }
    else if (columnType == SQLITE_FLOAT) {
        returnValue = [NSNumber numberWithDouble:[rs doubleForColumnIndex:columnIdx]];
    }
    else if (columnType == SQLITE_BLOB) {
        returnValue = [rs dataForColumnIndex:columnIdx];
        // Workaround, empty blob are reported as nil
        if (returnValue == nil) {
            return [NSData new];
        }
    }
    else {
        //default to a string for everything else
        returnValue = [rs stringForColumnIndex:columnIdx];
    }
    
    if (returnValue == nil) {
        returnValue = [NSNull null];
    }
    
    return returnValue;
}

// if cursorPageSize is not null, we limit the result count
+ (NSMutableDictionary*)resultSetToResults:(FMResultSet*)resultSet cursorPageSize:(NSNumber*)cursorPageSize {
    NSMutableDictionary* results = [NSMutableDictionary new];
    NSMutableArray* columns = nil;
    NSMutableArray* rows;
    int columnCount = 0;
    
    while ([resultSet next]) {
        if (columns == nil) {
            columnCount = [resultSet columnCount];
            columns = [NSMutableArray new];
            rows = [NSMutableArray new];
            for (int i = 0; i < columnCount; i++) {
                [columns addObject:[resultSet columnNameForIndex:i]];
            }
            [results setValue:columns forKey:@"columns"];
            [results setValue:rows forKey:@"rows"];
            
        }
        NSMutableArray* row = [NSMutableArray new];
        for (int i = 0; i < columnCount; i++) {
            [row addObject:[SqflitePlugin fromSqlValue:[self rsObjectForColumn:resultSet index:i]]];
        }
        [rows addObject:row];
        
        if (cursorPageSize != nil) {
            if ([rows count] >= [cursorPageSize intValue]) {
                break;
            }
        }
    }
    return results;
}
//
// query
//
- (bool)query:(SqfliteDatabase*)database fmdb:(FMDatabase*)db operation:(SqfliteOperation*)operation {
    NSString* sql = [operation getSql];
    NSArray* sqlArguments = [operation getSqlArguments];
    bool argumentsEmpty = [SqflitePlugin arrayIsEmpy:sqlArguments];
    // Non null means use a cursor
    NSNumber* cursorPageSize = [operation getArgument:_paramCursorPageSize];
    
    if (sqfliteHasSqlLogLevel(database.logLevel)) {
        NSLog(@"%@ %@", sql, argumentsEmpty ? @"" : sqlArguments);
    }
    
    FMResultSet *resultSet;
    if (!argumentsEmpty) {
        resultSet = [db executeQuery:sql withArgumentsInArray:sqlArguments];
    } else {
        // rs = [db executeQuery:sql];
        // This crashes on MacOS if there is any ? in the query
        // Workaround using an empty array
        resultSet = [db executeQuery:sql withArgumentsInArray:@[]];
    }
    
    // handle error
    if ([db hadError]) {
        [self handleError:db operation:operation];
        return false;
    }
    
    NSMutableDictionary* results = [SqflitePlugin resultSetToResults:resultSet cursorPageSize:cursorPageSize];
    
    if (cursorPageSize != nil) {
        bool cursorHasMoreData = [resultSet hasAnotherRow];
        if (cursorHasMoreData) {
            NSNumber* cursorId = [NSNumber numberWithInt:++database.lastCursorId];
            SqfliteCursor* cursor = [SqfliteCursor new];
            cursor.cursorId = cursorId;
            cursor.pageSize = cursorPageSize;
            cursor.resultSet = resultSet;
            database.cursorMap[cursorId] = cursor;
            // Notify cursor support in the result
            results[_paramCursorId] = cursorId;
            // Prevent FMDB warning, we keep a result set open on purpose
            [db resultSetDidClose:resultSet];
        }
    }
    [operation success:results];
    
    return true;
}

- (void)handleQueryCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    SqfliteDatabase* database = [self getDatabaseOrError:call result:result];
    if (database == nil) {
        return;
    }
    [database inDatabase:^(FMDatabase *db) {
        SqfliteMethodCallOperation* operation = [SqfliteMethodCallOperation newWithCall:call result:result];
        [database dbQuery:db operation:operation];
    }];
    
}


- (void)handleQueryCursorNextCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    SqfliteDatabase* database = [self getDatabaseOrError:call result:result];
    if (database == nil) {
        return;
    }
    [database inDatabase:^(FMDatabase *db) {
        SqfliteMethodCallOperation* operation = [SqfliteMethodCallOperation newWithCall:call result:result];
        [database dbQueryCursorNext:db operation:operation];
    }];
    
}

- (void)handleInsertCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    
    SqfliteDatabase* database = [self getDatabaseOrError:call result:result];
    if (database == nil) {
        return;
    }
    [database inDatabase:^(FMDatabase *db) {
        SqfliteMethodCallOperation* operation = [SqfliteMethodCallOperation newWithCall:call result:result];
        [database dbInsert:db operation:operation];
    }];
    
    
}

- (void)handleUpdateCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    SqfliteDatabase* database = [self getDatabaseOrError:call result:result];
    if (database == nil) {
        return;
    }
    
    [database inDatabase:^(FMDatabase *db) {
        SqfliteMethodCallOperation* operation = [SqfliteMethodCallOperation newWithCall:call result:result];
        [database dbUpdate:db operation:operation];
    }];
    
    
}

- (void)handleExecuteCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    SqfliteDatabase* database = [self getDatabaseOrError:call result:result];
    if (database == nil) {
        return;
    }
    
    [database inDatabase:^(FMDatabase *db) {
        SqfliteMethodCallOperation* operation = [SqfliteMethodCallOperation newWithCall:call result:result];
        [database dbExecute:db operation:operation];
    }];
}

//
// batch
//
- (void)handleBatchCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    SqfliteDatabase* database = [self getDatabaseOrError:call result:result];
    if (database == nil) {
        return;
    }
    
    [database inDatabase:^(FMDatabase *db) {
        
        SqfliteMethodCallOperation* mainOperation = [SqfliteMethodCallOperation newWithCall:call result:result];
        [database dbBatch:db operation:mainOperation];
        
    }];
    
    
}

+ (bool)isInMemoryPath:(NSString*)path {
    if ([path isEqualToString:_inMemoryPath]) {
        return true;
    }
    return false;
}

+ (NSDictionary*)makeOpenResult:(NSNumber*)databaseId recovered:(bool)recovered recoveredInTransaction:(bool)recoveredInTransaction {
    NSMutableDictionary* result = [NSMutableDictionary new];
    [result setObject:databaseId forKey:_paramId];
    if (recovered) {
        [result setObject:[NSNumber numberWithBool:recovered] forKey:_paramRecovered];
    }
    if (recoveredInTransaction) {
        [result setObject:[NSNumber numberWithBool:recoveredInTransaction] forKey:_paramRecoveredInTransaction];
    }
    return result;
}

//
// open
//
- (void)handleOpenDatabaseCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString* path = call.arguments[_paramPath];
    NSNumber* readOnlyValue = call.arguments[_paramReadOnly];
    bool readOnly = [readOnlyValue boolValue] == true;
    NSNumber* singleInstanceValue = call.arguments[_paramSingleInstance];
    bool inMemoryPath = [SqflitePlugin isInMemoryPath:path];
    // A single instance must be a regular database
    bool singleInstance = [singleInstanceValue boolValue] != false && !inMemoryPath;
    
    bool _log = sqfliteHasSqlLogLevel(logLevel);
    if (_log) {
        NSLog(@"opening %@ %@ %@", path, readOnly ? @" read-only" : @"", singleInstance ? @"" : @" new instance");
    }
    
    // Handle hot-restart for single instance
    // The dart code is killed but the native code remains
    if (singleInstance) {
        @synchronized (self.mapLock) {
            SqfliteDatabase* database = self.singleInstanceDatabaseMap[path];
            if (database != nil) {
                // Check if openedŸ
                if (_log) {
                    NSLog(@"re-opened %@singleInstance %@ id %@", database.inTransaction ? @"(in transaction) ": @"", path, database.databaseId);
                }
                result([SqflitePlugin makeOpenResult:database.databaseId recovered:true recoveredInTransaction:database.inTransaction]);
                return;
            }
        }
    }
    
    // Make sure the directory exists
    if (!inMemoryPath && !readOnly) {
        NSError* error;
        NSString* parentDir = [path stringByDeletingLastPathComponent];
        if (![[NSFileManager defaultManager] fileExistsAtPath:parentDir]) {
            if (_log) {
                NSLog(@"Creating parent dir %@", parentDir);
            }
            [[NSFileManager defaultManager] createDirectoryAtPath:parentDir withIntermediateDirectories:YES attributes:nil error:&error];
            // Ingore the error, it will break later during open
        }
    }
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:path flags:(readOnly ? SQLITE_OPEN_READONLY : (SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE))];
    bool success = queue != nil;
    
    if (!success) {
        NSLog(@"Could not open db.");
        result([FlutterError errorWithCode:SqliteErrorCode
                                   message:[NSString stringWithFormat:@"%@ %@", _errorOpenFailed, path]
                                   details:nil]);
        return;
    }
    
    // First call will be to prepare the database.
    // We turn on extended result code, allowing failure
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [queue inDatabase:^(FMDatabase *db) {
            sqlite3_extended_result_codes(db.sqliteHandle, 1);
        }];
    });
    
    NSNumber* databaseId;
    @synchronized (self.mapLock) {
        SqfliteDatabase* database = [SqfliteDatabase new];
        databaseId = [NSNumber numberWithInteger:++_lastDatabaseId];
        database.inTransaction = false;
        database.fmDatabaseQueue = queue;
        database.singleInstance = singleInstance;
        database.databaseId = databaseId;
        database.path = path;
        database.logLevel = logLevel;
        self.databaseMap[databaseId] = database;
        // To handle hot-restart recovery
        if (singleInstance) {
            self.singleInstanceDatabaseMap[path] = database;
        }
        if (_databaseOpenCount++ == 0) {
            if (sqfliteHasVerboseLogLevel(logLevel)) {
                NSLog(@"Creating operation queue");
            }
        }
    }
    
    result([SqflitePlugin makeOpenResult: databaseId recovered:false recoveredInTransaction:false]);
}

//
// close
//
- (void)handleCloseDatabaseCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    SqfliteDatabase* database = [self getDatabaseOrError:call result:result];
    if (database == nil) {
        return;
    }
    
    if (sqfliteHasSqlLogLevel(database.logLevel)) {
        NSLog(@"closing %@", database.path);
    }
    [self closeDatabase:database callback:^(){
        // We are in a background thread here.
        // resut itself is a wrapper posting on the main thread
        result(nil);
    }];
}

//
// close action
//
// The callback will be called from a background thread
//
- (void)closeDatabase:(SqfliteDatabase*)database callback:(void(^)(void))callback {
    if (sqfliteHasSqlLogLevel(database.logLevel)) {
        NSLog(@"closing %@", database.path);
    }
    @synchronized (self.mapLock) {
        [self.databaseMap removeObjectForKey:database.databaseId];
        if (database.singleInstance) {
            [self.singleInstanceDatabaseMap removeObjectForKey:database.path];
        }
        if (--_databaseOpenCount == 0) {
            if (sqfliteHasVerboseLogLevel(logLevel)) {
                NSLog(@"No more databases open");
            }
        }
    }
    FMDatabaseQueue* queue = database.fmDatabaseQueue;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // It is safe to call this from a background queue because the function
        // dispatches immediately to its queue synchronously.
        [queue close];
        // TODO(gaaclarke): Remove this dispatch once the minimum Flutter value is set to 3.0.
        // See also: https://github.com/flutter/flutter/issues/91635
        callback();
    });
}

- (void)deleteDatabaseFile:(NSString*)path {
    bool _log = sqfliteHasSqlLogLevel(logLevel);
    if (_log) {
        NSLog(@"Deleting %@", path);
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
}

//
// delete
//
- (void)handleDeleteDatabaseCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString* path = call.arguments[_paramPath];
    
    bool _log = sqfliteHasSqlLogLevel(logLevel);
    
    // Handle hot-restart for single instance
    // The dart code is killed but the native code remains
    SqfliteDatabase* database = nil;
    @synchronized (self.mapLock) {
        database = self.singleInstanceDatabaseMap[path];
        if (database != nil) {
            // Check if openedŸ
            if (_log) {
                NSLog(@"Deleting opened %@ id %@", path, database.databaseId);
            }
        }
    }
    
    if (database != nil) {
        [self closeDatabase:database callback:^() {
            // We are in a background thread here.
            // resut itself is a wrapper posting on the main thread
            [self deleteDatabaseFile:path];
            result(nil);
        }];
    } else {
        [self deleteDatabaseFile:path];
        result(nil);
    }
}

- (bool)databaseExists:(NSString*)path {
    bool _log = sqfliteHasSqlLogLevel(logLevel);
    if (_log) {
        NSLog(@"databaseExists %@", path);
    }
    return ([[NSFileManager defaultManager] fileExistsAtPath:path]);
}

//
// exists
//
- (void)handleDatabaseExistsCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString* path = call.arguments[_paramPath];
    NSNumber* existsResult =[NSNumber numberWithBool:[self databaseExists: path]];
    result(existsResult);
}

//
// debug
//
- (void)handleDebugCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSMutableDictionary* info = [NSMutableDictionary new];
    
    NSString* cmd = call.arguments[_paramCmd];
    // NSLog(@"cmd %@", cmd);
    if ([_paramCmdGet isEqualToString:cmd]) {
        @synchronized (self.mapLock) {
            if ([self.databaseMap  count] > 0) {
                NSMutableDictionary* dbsInfo     = [NSMutableDictionary new];
                [self.databaseMap enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, SqfliteDatabase * _Nonnull db, BOOL * _Nonnull stop) {
                    NSMutableDictionary* dbInfo	 = [NSMutableDictionary new];
                    [dbInfo setObject:db.path forKey:_paramPath];
                    [dbInfo setObject:[NSNumber numberWithBool:db.singleInstance] forKey:_paramSingleInstance];
                    if (db.logLevel > sqfliteLogLevelNone) {
                        [dbInfo setObject:[NSNumber numberWithInteger:db.logLevel ] forKey:_paramLogLevel];
                    }
                    [dbsInfo setObject:dbInfo forKey:[key stringValue]];
                    [info setObject:dbsInfo forKey:_paramDatabases];
                }];
            }
        }
        if (logLevel > sqfliteLogLevelNone) {
            [info setObject:[NSNumber numberWithInteger:logLevel] forKey:_paramLogLevel];
        }
        
    }
    result(info);
}

//
// debug mode - trying deprecation since 1.1.6
//
- (void)handleDebugModeCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSNumber* on = (NSNumber*)call.arguments;
    bool _log = [on boolValue];
    NSLog(@"Debug mode %d", _log);
    _extra_log = __extra_log && _log;
    
    if (_log) {
        if (_extra_log) {
            logLevel = sqfliteLogLevelVerbose;
        } else {
            logLevel = sqfliteLogLevelSql;
        }
    } else {
        logLevel = sqfliteLogLevelNone;
    }
    result(nil);
}

//
// Options
//
- (void)handleOptionsCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSNumber* logLevelNumber = call.arguments[_paramLogLevel];
    
    if (logLevelNumber) {
        logLevel = [logLevelNumber intValue];
        NSLog(@"Sqflite: logLevel %d", logLevel);
    }
    result(nil);
}

//
// getDatabasesPath
// returns the Documents directory on iOS
//
- (void)handleGetDatabasesPath:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    result(paths.firstObject);
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
#if !TARGET_OS_IPHONE
    // result wrapper to post the result on the main thread
    // until background threads are supported for plugin services
    result = ^(id res) {
        dispatch_async(dispatch_get_main_queue(), ^{
            result(res);
        });
    };
#endif
    
    if ([_methodGetPlatformVersion isEqualToString:call.method]) {
#if TARGET_OS_IPHONE
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
        
#else
        result([@"macOS " stringByAppendingString:[[NSProcessInfo processInfo] operatingSystemVersionString]]);
#endif
    } else if ([_methodOpenDatabase isEqualToString:call.method]) {
        [self handleOpenDatabaseCall:call result:result];
    } else if ([SqfliteMethodInsert isEqualToString:call.method]) {
        [self handleInsertCall:call result:result];
    } else if ([SqfliteMethodQuery isEqualToString:call.method]) {
        [self handleQueryCall:call result:result];
    } else if ([SqfliteMethodUpdate isEqualToString:call.method]) {
        [self handleUpdateCall:call result:result];
    } else if ([SqfliteMethodExecute isEqualToString:call.method]) {
        [self handleExecuteCall:call result:result];
    } else if ([_methodBatch isEqualToString:call.method]) {
        [self handleBatchCall:call result:result];
    } else if ([_methodQueryCursorNext isEqualToString:call.method]) {
        [self handleQueryCursorNextCall:call result:result];
    } else if ([_methodGetDatabasesPath isEqualToString:call.method]) {
        [self handleGetDatabasesPath:call result:result];
    } else if ([_methodCloseDatabase isEqualToString:call.method]) {
        [self handleCloseDatabaseCall:call result:result];
    } else if ([_methodDeleteDatabase isEqualToString:call.method]) {
        [self handleDeleteDatabaseCall:call result:result];
    } else if ([_methodDatabaseExists isEqualToString:call.method]) {
        [self handleDatabaseExistsCall:call result:result];
    } else if ([_methodOptions isEqualToString:call.method]) {
        [self handleOptionsCall:call result:result];
    } else if ([_methodDebug isEqualToString:call.method]) {
        [self handleDebugCall:call
                       result:result];
    } else if ([_methodDebugMode isEqualToString:call.method]) {
        [self handleDebugModeCall:call
                           result:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end
