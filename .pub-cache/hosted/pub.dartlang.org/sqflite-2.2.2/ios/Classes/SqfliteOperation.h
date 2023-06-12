//
//  Operation.h
//  sqflite
//
//  Created by Alexandre Roux on 09/01/2018.
//
#ifndef SqfliteOperation_h
#define SqfliteOperation_h

#import "SqfliteImport.h"

@class FMDatabase;
@interface SqfliteOperation : NSObject

- (NSString*)getMethod;
- (NSString*)getSql;
- (NSArray*)getSqlArguments;
- (NSNumber*)getInTransactionChange;
- (void)success:(NSObject*)results;
- (void)error:(FlutterError*)error;
- (bool)getNoResult;
- (bool)getContinueOnError;
- (bool)hasNullTransactionId;
- (NSNumber*)getTransactionId;
// Generic way to get any argument
- (id)getArgument:(NSString*)key;
- (bool)hasArgument:(NSString*)key;

@end

@interface SqfliteBatchOperation : SqfliteOperation

@property (atomic, retain) NSDictionary* dictionary;
@property (atomic, retain) NSObject* results;
@property (atomic, retain) FlutterError* error;
@property (atomic, assign) bool noResult;
@property (atomic, assign) bool continueOnError;

- (void)handleSuccess:(NSMutableArray*)results;
- (void)handleErrorContinue:(NSMutableArray*)results;
- (void)handleError:(FlutterResult)result;

@end

@interface SqfliteMethodCallOperation : SqfliteOperation

@property (atomic, retain) FlutterMethodCall* flutterMethodCall;
@property (atomic, copy) FlutterResult flutterResult;

+ (SqfliteMethodCallOperation*)newWithCall:(FlutterMethodCall*)flutterMethodCall result:(FlutterResult)flutterResult;

@end

typedef void(^SqfliteOperationHandler)(FMDatabase* db, SqfliteOperation* operation);
@interface SqfliteQueuedOperation : NSObject

@property (atomic, retain) SqfliteOperation* operation;
@property (atomic, copy) SqfliteOperationHandler handler;

@end

#endif // SqfliteOperation_h
