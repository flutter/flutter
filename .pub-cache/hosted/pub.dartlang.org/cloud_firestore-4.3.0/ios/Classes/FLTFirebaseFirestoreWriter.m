// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Firebase/Firebase.h>
#import <firebase_core/FLTFirebasePlugin.h>

#import "Private/FLTFirebaseFirestoreUtils.h"
#import "Private/FLTFirebaseFirestoreWriter.h"
#import "Public/FLTFirebaseFirestorePlugin.h"

@implementation FLTFirebaseFirestoreWriter : FlutterStandardWriter
- (void)writeValue:(id)value {
  if ([value isKindOfClass:[NSDate class]]) {
    [self writeByte:FirestoreDataTypeDateTime];
    NSDate *date = value;
    NSTimeInterval time = date.timeIntervalSince1970;
    SInt64 ms = (SInt64)(time * 1000.0);
    [self writeBytes:&ms length:8];
  } else if ([value isKindOfClass:[FIRTimestamp class]]) {
    FIRTimestamp *timestamp = value;
    SInt64 seconds = timestamp.seconds;
    int nanoseconds = timestamp.nanoseconds;
    [self writeByte:FirestoreDataTypeTimestamp];
    [self writeBytes:(UInt8 *)&seconds length:8];
    [self writeBytes:(UInt8 *)&nanoseconds length:4];
  } else if ([value isKindOfClass:[FIRGeoPoint class]]) {
    FIRGeoPoint *geoPoint = value;
    Float64 latitude = geoPoint.latitude;
    Float64 longitude = geoPoint.longitude;
    [self writeByte:FirestoreDataTypeGeoPoint];
    [self writeAlignment:8];
    [self writeBytes:(UInt8 *)&latitude length:8];
    [self writeBytes:(UInt8 *)&longitude length:8];
  } else if ([value isKindOfClass:[FIRDocumentReference class]]) {
    FIRDocumentReference *document = value;
    NSString *documentPath = [document path];
    NSString *appName = [FLTFirebasePlugin firebaseAppNameFromIosName:document.firestore.app.name];
    [self writeByte:FirestoreDataTypeDocumentReference];
    [self writeValue:appName];
    [self writeValue:documentPath];
  } else if ([value isKindOfClass:[FIRDocumentSnapshot class]]) {
    [super writeValue:[self FIRDocumentSnapshot:value]];
  } else if ([value isKindOfClass:[FIRLoadBundleTaskProgress class]]) {
    [super writeValue:[self FIRLoadBundleTaskProgress:value]];
  } else if ([value isKindOfClass:[FIRQuerySnapshot class]]) {
    [super writeValue:[self FIRQuerySnapshot:value]];
  } else if ([value isKindOfClass:[FIRDocumentChange class]]) {
    [super writeValue:[self FIRDocumentChange:value]];
  } else if ([value isKindOfClass:[FIRSnapshotMetadata class]]) {
    [super writeValue:[self FIRSnapshotMetadata:value]];
  } else if ([value isKindOfClass:[NSNumber class]]) {
    NSNumber *number = (NSNumber *)value;

    // Infinity
    if ([number isEqual:@(INFINITY)]) {
      [self writeByte:FirestoreDataTypeInfinity];
      return;
    }

    // -Infinity
    if ([number isEqual:@(-INFINITY)]) {
      [self writeByte:FirestoreDataTypeNegativeInfinity];
      return;
    }

    // NaN
    if ([[value description].lowercaseString isEqual:@"nan"]) {
      [self writeByte:FirestoreDataTypeNaN];
      return;
    }

    [super writeValue:value];
  } else if ([value isKindOfClass:[NSData class]]) {
    NSData *blob = value;
    [self writeByte:FirestoreDataTypeBlob];
    [self writeSize:(UInt32)blob.length];
    [self writeData:blob];
  } else {
    [super writeValue:value];
  }
}

- (NSDictionary *)FIRSnapshotMetadata:(FIRSnapshotMetadata *)snapshotMetadata {
  return @{
    @"hasPendingWrites" : @(snapshotMetadata.hasPendingWrites),
    @"isFromCache" : @(snapshotMetadata.isFromCache),
  };
}

- (NSDictionary *)FIRDocumentChange:(FIRDocumentChange *)documentChange {
  NSString *type;

  switch (documentChange.type) {
    case FIRDocumentChangeTypeAdded:
      type = @"DocumentChangeType.added";
      break;
    case FIRDocumentChangeTypeModified:
      type = @"DocumentChangeType.modified";
      break;
    case FIRDocumentChangeTypeRemoved:
      type = @"DocumentChangeType.removed";
      break;
  }

  NSNumber *oldIndex;
  NSNumber *newIndex;

  // Note the Firestore C++ SDK here returns a maxed UInt that is != NSUIntegerMax, so we make one
  // ourselves so we can convert to -1 for Dart.
  NSUInteger MAX_VAL = (NSUInteger)[@(-1) integerValue];

  if (documentChange.newIndex == NSNotFound || documentChange.newIndex == 4294967295 ||
      documentChange.newIndex == MAX_VAL) {
    newIndex = @([@(-1) intValue]);
  } else {
    newIndex = @([@(documentChange.newIndex) intValue]);
  }

  if (documentChange.oldIndex == NSNotFound || documentChange.oldIndex == 4294967295 ||
      documentChange.oldIndex == MAX_VAL) {
    oldIndex = @([@(-1) intValue]);
  } else {
    oldIndex = @([@(documentChange.oldIndex) intValue]);
  }

  return @{
    @"type" : type,
    @"data" : documentChange.document.data,
    @"path" : documentChange.document.reference.path,
    @"oldIndex" : oldIndex,
    @"newIndex" : newIndex,
    @"metadata" : documentChange.document.metadata,
  };
}

- (FIRServerTimestampBehavior)toServerTimestampBehavior:(NSString *)serverTimestampBehavior {
  if (serverTimestampBehavior == nil) {
    return FIRServerTimestampBehaviorNone;
  }

  if ([serverTimestampBehavior isEqualToString:@"estimate"]) {
    return FIRServerTimestampBehaviorEstimate;
  } else if ([serverTimestampBehavior isEqualToString:@"previous"]) {
    return FIRServerTimestampBehaviorPrevious;
  } else {
    return FIRServerTimestampBehaviorNone;
  }
}

- (NSDictionary *)FIRDocumentSnapshot:(FIRDocumentSnapshot *)documentSnapshot {
  FIRServerTimestampBehavior serverTimestampBehavior =
      [self toServerTimestampBehavior:FLTFirebaseFirestorePlugin
                                          .serverTimestampMap[@([documentSnapshot hash])]];

  [FLTFirebaseFirestorePlugin.serverTimestampMap removeObjectForKey:@([documentSnapshot hash])];

  return @{
    @"path" : documentSnapshot.reference.path,
    @"data" : documentSnapshot.exists
        ? (id)[documentSnapshot dataWithServerTimestampBehavior:serverTimestampBehavior]
        : [NSNull null],
    @"metadata" : documentSnapshot.metadata,
  };
}

- (NSDictionary *)FIRLoadBundleTaskProgress:(FIRLoadBundleTaskProgress *)progress {
  NSString *state;

  switch (progress.state) {
    case FIRLoadBundleTaskStateError:
      state = @"error";
      break;
    case FIRLoadBundleTaskStateSuccess:
      state = @"success";
      break;
    case FIRLoadBundleTaskStateInProgress:
      state = @"running";
      break;
  }
  return @{
    @"bytesLoaded" : @(progress.bytesLoaded),
    @"documentsLoaded" : @(progress.documentsLoaded),
    @"totalBytes" : @(progress.totalBytes),
    @"totalDocuments" : @(progress.totalDocuments),
    @"taskState" : state,
  };
}

- (NSDictionary *)FIRQuerySnapshot:(FIRQuerySnapshot *)querySnapshot {
  NSMutableArray *paths = [NSMutableArray array];
  NSMutableArray *documents = [NSMutableArray array];
  NSMutableArray *metadatas = [NSMutableArray array];
  FIRServerTimestampBehavior serverTimestampBehavior =
      [self toServerTimestampBehavior:FLTFirebaseFirestorePlugin
                                          .serverTimestampMap[@([querySnapshot hash])]];

  [FLTFirebaseFirestorePlugin.serverTimestampMap removeObjectForKey:@([querySnapshot hash])];

  for (FIRDocumentSnapshot *document in querySnapshot.documents) {
    [paths addObject:document.reference.path];
    [documents addObject:[document dataWithServerTimestampBehavior:serverTimestampBehavior]];
    [metadatas addObject:document.metadata];
  }

  return @{
    @"paths" : paths,
    @"documentChanges" : querySnapshot.documentChanges,
    @"documents" : documents,
    @"metadatas" : metadatas,
    @"metadata" : querySnapshot.metadata,
  };
}
@end
