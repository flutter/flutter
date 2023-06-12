//
//  SqfliteDatabase.h
//  sqflite
//
//  Created by Alexandre Roux on 24/10/2022.
//
#ifndef SqfliteDatabase_h
#define SqfliteDatabase_h

#import "SqfliteCursor.h"
#import "SqfliteOperation.h"

@class FMDatabaseQueue,FMDatabase;
@interface SqfliteDatabase : NSObject

@property (atomic, retain) FMDatabaseQueue *fmDatabaseQueue;
@property (atomic, retain) NSNumber *databaseId;
@property (atomic, retain) NSString* path;
@property (nonatomic) bool singleInstance;
@property (nonatomic) bool inTransaction;
@property (nonatomic) int logLevel;
// Curosr support
@property (nonatomic) int lastCursorId;
@property (atomic, retain) NSMutableDictionary<NSNumber*, SqfliteCursor*>* cursorMap;
// Transaction v2
@property (nonatomic) int lastTransactionId;
@property (atomic, retain) NSNumber *currentTransactionId;
@property (atomic, retain) NSMutableArray<SqfliteQueuedOperation*>* noTransactionOperationQueue;

- (void)closeCursorById:(NSNumber*)cursorId;
- (void)closeCursor:(SqfliteCursor*)cursor;
- (void)inDatabase:(void (^)(FMDatabase *db))block;
- (void)dbBatch:(FMDatabase*)db operation:(SqfliteMethodCallOperation*)mainOperation;
- (void)dbExecute:(FMDatabase*)db operation:(SqfliteOperation*)operation;
- (void)dbInsert:(FMDatabase*)db operation:(SqfliteOperation*)operation;
- (void)dbUpdate:(FMDatabase*)db operation:(SqfliteOperation*)operation;
- (void)dbQuery:(FMDatabase*)db operation:(SqfliteOperation*)operation;
- (void)dbQueryCursorNext:(FMDatabase*)db operation:(SqfliteOperation*)operation;
@end

#endif // SqfliteDatabase_h
