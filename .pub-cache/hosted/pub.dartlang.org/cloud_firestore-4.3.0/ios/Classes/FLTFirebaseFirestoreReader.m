// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Firebase/Firebase.h>
#import <firebase_core/FLTFirebasePlugin.h>

#import "Private/FLTFirebaseFirestoreReader.h"
#import "Private/FLTFirebaseFirestoreUtils.h"

@implementation FLTFirebaseFirestoreReader

- (id)readValueOfType:(UInt8)type {
  switch (type) {
    case FirestoreDataTypeDateTime: {
      SInt64 value;
      [self readBytes:&value length:8];
      return [NSDate dateWithTimeIntervalSince1970:(value / 1000.0)];
    }
    case FirestoreDataTypeTimestamp: {
      SInt64 seconds;
      int nanoseconds;
      [self readBytes:&seconds length:8];
      [self readBytes:&nanoseconds length:4];
      return [[FIRTimestamp alloc] initWithSeconds:seconds nanoseconds:nanoseconds];
    }
    case FirestoreDataTypeGeoPoint: {
      Float64 latitude;
      Float64 longitude;
      [self readAlignment:8];
      [self readBytes:&latitude length:8];
      [self readBytes:&longitude length:8];
      return [[FIRGeoPoint alloc] initWithLatitude:latitude longitude:longitude];
    }
    case FirestoreDataTypeDocumentReference: {
      FIRFirestore *firestore = [self readValue];
      NSString *documentPath = [self readValue];
      return [firestore documentWithPath:documentPath];
    }
    case FirestoreDataTypeFieldPath: {
      UInt32 length = [self readSize];
      NSMutableArray *array = [NSMutableArray arrayWithCapacity:length];
      for (UInt32 i = 0; i < length; i++) {
        id value = [self readValue];
        [array addObject:(value == nil ? [NSNull null] : value)];
      }
      return [[FIRFieldPath alloc] initWithFields:array];
    }
    case FirestoreDataTypeBlob:
      return [self readData:[self readSize]];
    case FirestoreDataTypeArrayUnion:
      return [FIRFieldValue fieldValueForArrayUnion:[self readValue]];
    case FirestoreDataTypeArrayRemove:
      return [FIRFieldValue fieldValueForArrayRemove:[self readValue]];
    case FirestoreDataTypeDelete:
      return [FIRFieldValue fieldValueForDelete];
    case FirestoreDataTypeServerTimestamp:
      return [FIRFieldValue fieldValueForServerTimestamp];
    case FirestoreDataTypeIncrementDouble:
      return
          [FIRFieldValue fieldValueForDoubleIncrement:((NSNumber *)[self readValue]).doubleValue];
    case FirestoreDataTypeIncrementInteger:
      return [FIRFieldValue fieldValueForIntegerIncrement:((NSNumber *)[self readValue]).intValue];
    case FirestoreDataTypeDocumentId:
      return [FIRFieldPath documentID];
    case FirestoreDataTypeFirestoreInstance:
      return [self FIRFirestore];
    case FirestoreDataTypeFirestoreQuery:
      return [self FIRQuery];
    case FirestoreDataTypeFirestoreSettings:
      return [self FIRFirestoreSettings];
    case FirestoreDataTypeNaN:
      return @(NAN);
    case FirestoreDataTypeInfinity:
      return @(INFINITY);
    case FirestoreDataTypeNegativeInfinity:
      return @(-INFINITY);
    default:
      return [super readValueOfType:type];
  }
}

+ (dispatch_queue_t)getFirestoreQueue {
  static dispatch_queue_t firestoreQueue;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    firestoreQueue = dispatch_queue_create("dev.flutter.firebase.firestore", DISPATCH_QUEUE_SERIAL);
  });
  return firestoreQueue;
}

- (FIRFirestoreSettings *)FIRFirestoreSettings {
  NSDictionary *values = [self readValue];
  FIRFirestoreSettings *settings = [[FIRFirestoreSettings alloc] init];

  if (![values[@"persistenceEnabled"] isEqual:[NSNull null]]) {
    settings.persistenceEnabled = [((NSNumber *)values[@"persistenceEnabled"]) boolValue];
  }

  if (![values[@"host"] isEqual:[NSNull null]]) {
    settings.host = (NSString *)values[@"host"];
    // Only allow changing ssl if host is also specified.
    if (![values[@"sslEnabled"] isEqual:[NSNull null]]) {
      settings.sslEnabled = [((NSNumber *)values[@"sslEnabled"]) boolValue];
    }
  }

  if (![values[@"cacheSizeBytes"] isEqual:[NSNull null]]) {
    int size = [((NSNumber *)values[@"cacheSizeBytes"]) intValue];
    if (size == -1) {
      settings.cacheSizeBytes = kFIRFirestoreCacheSizeUnlimited;
    } else {
      settings.cacheSizeBytes = (int64_t)size;
    }
  }

  settings.dispatchQueue = [FLTFirebaseFirestoreReader getFirestoreQueue];

  return settings;
}

- (FIRQuery *)FIRQuery {
  @try {
    FIRQuery *query;
    NSDictionary *values = [self readValue];
    FIRFirestore *firestore = values[@"firestore"];

    NSDictionary *parameters = values[@"parameters"];
    NSArray *whereConditions = parameters[@"where"];
    BOOL isCollectionGroup = ((NSNumber *)values[@"isCollectionGroup"]).boolValue;

    if (isCollectionGroup) {
      query = [firestore collectionGroupWithID:values[@"path"]];
    } else {
      query = (FIRQuery *)[firestore collectionWithPath:values[@"path"]];
    }

    // Filters
    for (id item in whereConditions) {
      NSArray *condition = item;
      FIRFieldPath *fieldPath = (FIRFieldPath *)condition[0];
      NSString *operator= condition[1];
      id value = condition[2];
      if ([operator isEqualToString:@"=="]) {
        query = [query queryWhereFieldPath:fieldPath isEqualTo:value];
      } else if ([operator isEqualToString:@"!="]) {
        query = [query queryWhereFieldPath:fieldPath isNotEqualTo:value];
      } else if ([operator isEqualToString:@"<"]) {
        query = [query queryWhereFieldPath:fieldPath isLessThan:value];
      } else if ([operator isEqualToString:@"<="]) {
        query = [query queryWhereFieldPath:fieldPath isLessThanOrEqualTo:value];
      } else if ([operator isEqualToString:@">"]) {
        query = [query queryWhereFieldPath:fieldPath isGreaterThan:value];
      } else if ([operator isEqualToString:@">="]) {
        query = [query queryWhereFieldPath:fieldPath isGreaterThanOrEqualTo:value];
      } else if ([operator isEqualToString:@"array-contains"]) {
        query = [query queryWhereFieldPath:fieldPath arrayContains:value];
      } else if ([operator isEqualToString:@"array-contains-any"]) {
        query = [query queryWhereFieldPath:fieldPath arrayContainsAny:value];
      } else if ([operator isEqualToString:@"in"]) {
        query = [query queryWhereFieldPath:fieldPath in:value];
      } else if ([operator isEqualToString:@"not-in"]) {
        query = [query queryWhereFieldPath:fieldPath notIn:value];
      } else {
        NSLog(@"FLTFirebaseFirestore: An invalid query operator %@ was received but not handled.",
              operator);
      }
    }

    // Limit
    id limit = parameters[@"limit"];
    if (![limit isEqual:[NSNull null]]) {
      query = [query queryLimitedTo:((NSNumber *)limit).intValue];
    }

    // Limit To Last
    id limitToLast = parameters[@"limitToLast"];
    if (![limitToLast isEqual:[NSNull null]]) {
      query = [query queryLimitedToLast:((NSNumber *)limitToLast).intValue];
    }

    // Ordering
    NSArray *orderBy = parameters[@"orderBy"];
    if ([orderBy isEqual:[NSNull null]]) {
      // We return early if no ordering set as cursor queries below require at least one orderBy set
      return query;
    }

    for (NSArray *orderByParameters in orderBy) {
      FIRFieldPath *fieldPath = (FIRFieldPath *)orderByParameters[0];
      NSNumber *descending = orderByParameters[1];
      query = [query queryOrderedByFieldPath:fieldPath descending:[descending boolValue]];
    }

    // Start At
    id startAt = parameters[@"startAt"];
    if (![startAt isEqual:[NSNull null]]) query = [query queryStartingAtValues:(NSArray *)startAt];
    // Start After
    id startAfter = parameters[@"startAfter"];
    if (![startAfter isEqual:[NSNull null]])
      query = [query queryStartingAfterValues:(NSArray *)startAfter];
    // End At
    id endAt = parameters[@"endAt"];
    if (![endAt isEqual:[NSNull null]]) query = [query queryEndingAtValues:(NSArray *)endAt];
    // End Before
    id endBefore = parameters[@"endBefore"];
    if (![endBefore isEqual:[NSNull null]])
      query = [query queryEndingBeforeValues:(NSArray *)endBefore];

    return query;
  } @catch (NSException *exception) {
    NSLog(@"An error occurred while parsing query arguments, this is most likely an error with "
          @"this SDK. %@",
          [exception callStackSymbols]);
    return nil;
  }
}

- (FIRFirestore *)FIRFirestore {
  @synchronized(self) {
    NSString *appNameDart = [self readValue];
    FIRFirestoreSettings *settings = [self readValue];
    FIRApp *app = [FLTFirebasePlugin firebaseAppNamed:appNameDart];

    if ([FLTFirebaseFirestoreUtils getCachedFIRFirestoreInstanceForKey:app.name] != nil) {
      return [FLTFirebaseFirestoreUtils getCachedFIRFirestoreInstanceForKey:app.name];
    }

    FIRFirestore *firestore = [FIRFirestore firestoreForApp:app];
    firestore.settings = settings;

    [FLTFirebaseFirestoreUtils setCachedFIRFirestoreInstance:firestore forKey:app.name];
    return firestore;
  }
}

@end
