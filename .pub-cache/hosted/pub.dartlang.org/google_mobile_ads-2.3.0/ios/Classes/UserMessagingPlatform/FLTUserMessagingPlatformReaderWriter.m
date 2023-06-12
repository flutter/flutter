// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "FLTUserMessagingPlatformReaderWriter.h"
#import "../FLTAdUtil.h"
#include <UserMessagingPlatform/UserMessagingPlatform.h>

// The type values below must be consistent for each platform.
typedef NS_ENUM(NSInteger, FLTUserMessagingPlatformField) {
  FLTValueConsentRequestParameters = 129,
  FLTValueConsentDebugSettings = 130,
  FLTValueConsentForm = 131,
};

@interface FLTUserMessagingPlatformReader : FlutterStandardReader
@property NSMutableDictionary<NSNumber *, UMPConsentForm *> *consentFormDict;
@end

@interface FLTUserMessagingPlatformWriter : FlutterStandardWriter
@property NSMutableDictionary<NSNumber *, UMPConsentForm *> *consentFormDict;
@end

@interface FLTUserMessagingPlatformReaderWriter ()
@property NSMutableDictionary<NSNumber *, UMPConsentForm *> *consentFormDict;
@end

@implementation FLTUserMessagingPlatformReaderWriter

- (instancetype _Nonnull)init {
  self = [super init];
  if (self) {
    self.consentFormDict = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (void)trackConsentForm:(UMPConsentForm *)consentForm {
  NSNumber *hash = [[NSNumber alloc] initWithInteger:consentForm.hash];
  _consentFormDict[hash] = consentForm;
}

- (void)disposeConsentForm:(UMPConsentForm *)consentForm {
  NSNumber *hash = [[NSNumber alloc] initWithInteger:consentForm.hash];
  [_consentFormDict removeObjectForKey:hash];
}

- (FlutterStandardReader *_Nonnull)readerWithData:(NSData *_Nonnull)data {
  FLTUserMessagingPlatformReader *reader =
      [[FLTUserMessagingPlatformReader alloc] initWithData:data];
  reader.consentFormDict = self.consentFormDict;
  return reader;
}

- (FlutterStandardWriter *_Nonnull)writerWithData:
    (NSMutableData *_Nonnull)data {
  FLTUserMessagingPlatformWriter *writer =
      [[FLTUserMessagingPlatformWriter alloc] initWithData:data];
  writer.consentFormDict = self.consentFormDict;
  return writer;
}
@end

@implementation FLTUserMessagingPlatformWriter

- (void)writeValue:(id)value {
  if ([value isKindOfClass:[UMPConsentForm class]]) {
    UMPConsentForm *form = (UMPConsentForm *)value;
    NSNumber *hash = [[NSNumber alloc] initWithInteger:form.hash];
    [self writeByte:FLTValueConsentForm];
    [self writeValue:hash];
  } else if ([value isKindOfClass:[UMPRequestParameters class]]) {
    UMPRequestParameters *params = (UMPRequestParameters *)value;

    [self writeByte:FLTValueConsentRequestParameters];
    [self writeValue:[[NSNumber alloc]
                         initWithBool:params.tagForUnderAgeOfConsent]];
    [self writeValue:params.debugSettings];
  } else if ([value isKindOfClass:[UMPDebugSettings class]]) {
    UMPDebugSettings *debugSettings = (UMPDebugSettings *)value;
    [self writeByte:FLTValueConsentDebugSettings];
    [self
        writeValue:[[NSNumber alloc] initWithInteger:debugSettings.geography]];
    [self writeValue:debugSettings.testDeviceIdentifiers];
  } else {
    [super writeValue:value];
  }
}

@end

@implementation FLTUserMessagingPlatformReader

- (id _Nullable)readValueOfType:(UInt8)type {
  FLTUserMessagingPlatformField field = (FLTUserMessagingPlatformField)type;
  switch (field) {
  case FLTValueConsentRequestParameters: {
    UMPRequestParameters *parameters = [[UMPRequestParameters alloc] init];
    NSNumber *tfuac = [self readValueOfType:[self readByte]];

    parameters.tagForUnderAgeOfConsent = tfuac.boolValue;
    UMPDebugSettings *debugSettings = [self readValueOfType:[self readByte]];
    parameters.debugSettings = debugSettings;
    return parameters;
  }
  case FLTValueConsentDebugSettings: {
    UMPDebugSettings *debugSettings = [[UMPDebugSettings alloc] init];
    NSNumber *geography = [self readValueOfType:[self readByte]];
    NSArray<NSString *> *testIdentifiers =
        [self readValueOfType:[self readByte]];
    if ([FLTAdUtil isNotNull:geography]) {
      debugSettings.geography = geography.intValue;
    }
    if ([FLTAdUtil isNotNull:testIdentifiers]) {
      debugSettings.testDeviceIdentifiers = testIdentifiers;
    }
    return debugSettings;
  }
  case FLTValueConsentForm: {
    NSNumber *hash = [self readValueOfType:[self readByte]];
    return _consentFormDict[hash];
  }
  default:
    return [super readValueOfType:type];
  }
}

@end
