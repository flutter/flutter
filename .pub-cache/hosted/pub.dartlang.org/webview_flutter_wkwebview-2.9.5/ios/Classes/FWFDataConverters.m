// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FWFDataConverters.h"

#import <Flutter/Flutter.h>

NSURLRequest *_Nullable FWFNSURLRequestFromRequestData(FWFNSUrlRequestData *data) {
  NSURL *url = [NSURL URLWithString:data.url];
  if (!url) {
    return nil;
  }

  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  if (!request) {
    return nil;
  }

  if (data.httpMethod) {
    [request setHTTPMethod:data.httpMethod];
  }
  if (data.httpBody) {
    [request setHTTPBody:data.httpBody.data];
  }
  [request setAllHTTPHeaderFields:data.allHttpHeaderFields];

  return request;
}

extern NSHTTPCookie *_Nullable FWFNSHTTPCookieFromCookieData(FWFNSHttpCookieData *data) {
  NSMutableDictionary<NSHTTPCookiePropertyKey, id> *properties = [NSMutableDictionary dictionary];
  for (int i = 0; i < data.propertyKeys.count; i++) {
    NSHTTPCookiePropertyKey cookieKey =
        FWFNSHTTPCookiePropertyKeyFromEnumData(data.propertyKeys[i]);
    if (!cookieKey) {
      // Some keys aren't supported on all versions, so this ignores keys
      // that require a higher version or are unsupported.
      continue;
    }
    [properties setObject:data.propertyValues[i] forKey:cookieKey];
  }
  return [NSHTTPCookie cookieWithProperties:properties];
}

NSKeyValueObservingOptions FWFNSKeyValueObservingOptionsFromEnumData(
    FWFNSKeyValueObservingOptionsEnumData *data) {
  switch (data.value) {
    case FWFNSKeyValueObservingOptionsEnumNewValue:
      return NSKeyValueObservingOptionNew;
    case FWFNSKeyValueObservingOptionsEnumOldValue:
      return NSKeyValueObservingOptionOld;
    case FWFNSKeyValueObservingOptionsEnumInitialValue:
      return NSKeyValueObservingOptionInitial;
    case FWFNSKeyValueObservingOptionsEnumPriorNotification:
      return NSKeyValueObservingOptionPrior;
  }

  return -1;
}

NSHTTPCookiePropertyKey _Nullable FWFNSHTTPCookiePropertyKeyFromEnumData(
    FWFNSHttpCookiePropertyKeyEnumData *data) {
  switch (data.value) {
    case FWFNSHttpCookiePropertyKeyEnumComment:
      return NSHTTPCookieComment;
    case FWFNSHttpCookiePropertyKeyEnumCommentUrl:
      return NSHTTPCookieCommentURL;
    case FWFNSHttpCookiePropertyKeyEnumDiscard:
      return NSHTTPCookieDiscard;
    case FWFNSHttpCookiePropertyKeyEnumDomain:
      return NSHTTPCookieDomain;
    case FWFNSHttpCookiePropertyKeyEnumExpires:
      return NSHTTPCookieExpires;
    case FWFNSHttpCookiePropertyKeyEnumMaximumAge:
      return NSHTTPCookieMaximumAge;
    case FWFNSHttpCookiePropertyKeyEnumName:
      return NSHTTPCookieName;
    case FWFNSHttpCookiePropertyKeyEnumOriginUrl:
      return NSHTTPCookieOriginURL;
    case FWFNSHttpCookiePropertyKeyEnumPath:
      return NSHTTPCookiePath;
    case FWFNSHttpCookiePropertyKeyEnumPort:
      return NSHTTPCookiePort;
    case FWFNSHttpCookiePropertyKeyEnumSameSitePolicy:
      if (@available(iOS 13.0, *)) {
        return NSHTTPCookieSameSitePolicy;
      } else {
        return nil;
      }
    case FWFNSHttpCookiePropertyKeyEnumSecure:
      return NSHTTPCookieSecure;
    case FWFNSHttpCookiePropertyKeyEnumValue:
      return NSHTTPCookieValue;
    case FWFNSHttpCookiePropertyKeyEnumVersion:
      return NSHTTPCookieVersion;
  }

  return nil;
}

extern WKUserScript *FWFWKUserScriptFromScriptData(FWFWKUserScriptData *data) {
  return [[WKUserScript alloc]
        initWithSource:data.source
         injectionTime:FWFWKUserScriptInjectionTimeFromEnumData(data.injectionTime)
      forMainFrameOnly:data.isMainFrameOnly.boolValue];
}

WKUserScriptInjectionTime FWFWKUserScriptInjectionTimeFromEnumData(
    FWFWKUserScriptInjectionTimeEnumData *data) {
  switch (data.value) {
    case FWFWKUserScriptInjectionTimeEnumAtDocumentStart:
      return WKUserScriptInjectionTimeAtDocumentStart;
    case FWFWKUserScriptInjectionTimeEnumAtDocumentEnd:
      return WKUserScriptInjectionTimeAtDocumentEnd;
  }

  return -1;
}

API_AVAILABLE(ios(10.0))
WKAudiovisualMediaTypes FWFWKAudiovisualMediaTypeFromEnumData(
    FWFWKAudiovisualMediaTypeEnumData *data) {
  switch (data.value) {
    case FWFWKAudiovisualMediaTypeEnumNone:
      return WKAudiovisualMediaTypeNone;
    case FWFWKAudiovisualMediaTypeEnumAudio:
      return WKAudiovisualMediaTypeAudio;
    case FWFWKAudiovisualMediaTypeEnumVideo:
      return WKAudiovisualMediaTypeVideo;
    case FWFWKAudiovisualMediaTypeEnumAll:
      return WKAudiovisualMediaTypeAll;
  }

  return -1;
}

NSString *_Nullable FWFWKWebsiteDataTypeFromEnumData(FWFWKWebsiteDataTypeEnumData *data) {
  switch (data.value) {
    case FWFWKWebsiteDataTypeEnumCookies:
      return WKWebsiteDataTypeCookies;
    case FWFWKWebsiteDataTypeEnumMemoryCache:
      return WKWebsiteDataTypeMemoryCache;
    case FWFWKWebsiteDataTypeEnumDiskCache:
      return WKWebsiteDataTypeDiskCache;
    case FWFWKWebsiteDataTypeEnumOfflineWebApplicationCache:
      return WKWebsiteDataTypeOfflineWebApplicationCache;
    case FWFWKWebsiteDataTypeEnumLocalStorage:
      return WKWebsiteDataTypeLocalStorage;
    case FWFWKWebsiteDataTypeEnumSessionStorage:
      return WKWebsiteDataTypeSessionStorage;
    case FWFWKWebsiteDataTypeEnumWebSQLDatabases:
      return WKWebsiteDataTypeWebSQLDatabases;
    case FWFWKWebsiteDataTypeEnumIndexedDBDatabases:
      return WKWebsiteDataTypeIndexedDBDatabases;
  }

  return nil;
}

FWFWKNavigationActionData *FWFWKNavigationActionDataFromNavigationAction(
    WKNavigationAction *action) {
  return [FWFWKNavigationActionData
      makeWithRequest:FWFNSUrlRequestDataFromNSURLRequest(action.request)
          targetFrame:FWFWKFrameInfoDataFromWKFrameInfo(action.targetFrame)];
}

FWFNSUrlRequestData *FWFNSUrlRequestDataFromNSURLRequest(NSURLRequest *request) {
  return [FWFNSUrlRequestData
              makeWithUrl:request.URL.absoluteString
               httpMethod:request.HTTPMethod
                 httpBody:request.HTTPBody
                              ? [FlutterStandardTypedData typedDataWithBytes:request.HTTPBody]
                              : nil
      allHttpHeaderFields:request.allHTTPHeaderFields ? request.allHTTPHeaderFields : @{}];
}

FWFWKFrameInfoData *FWFWKFrameInfoDataFromWKFrameInfo(WKFrameInfo *info) {
  return [FWFWKFrameInfoData makeWithIsMainFrame:@(info.isMainFrame)];
}

WKNavigationActionPolicy FWFWKNavigationActionPolicyFromEnumData(
    FWFWKNavigationActionPolicyEnumData *data) {
  switch (data.value) {
    case FWFWKNavigationActionPolicyEnumAllow:
      return WKNavigationActionPolicyAllow;
    case FWFWKNavigationActionPolicyEnumCancel:
      return WKNavigationActionPolicyCancel;
  }

  return -1;
}

FWFNSErrorData *FWFNSErrorDataFromNSError(NSError *error) {
  return [FWFNSErrorData makeWithCode:@(error.code)
                               domain:error.domain
                 localizedDescription:error.localizedDescription];
}

FWFNSKeyValueChangeKeyEnumData *FWFNSKeyValueChangeKeyEnumDataFromNSKeyValueChangeKey(
    NSKeyValueChangeKey key) {
  if ([key isEqualToString:NSKeyValueChangeIndexesKey]) {
    return [FWFNSKeyValueChangeKeyEnumData makeWithValue:FWFNSKeyValueChangeKeyEnumIndexes];
  } else if ([key isEqualToString:NSKeyValueChangeKindKey]) {
    return [FWFNSKeyValueChangeKeyEnumData makeWithValue:FWFNSKeyValueChangeKeyEnumKind];
  } else if ([key isEqualToString:NSKeyValueChangeNewKey]) {
    return [FWFNSKeyValueChangeKeyEnumData makeWithValue:FWFNSKeyValueChangeKeyEnumNewValue];
  } else if ([key isEqualToString:NSKeyValueChangeNotificationIsPriorKey]) {
    return [FWFNSKeyValueChangeKeyEnumData
        makeWithValue:FWFNSKeyValueChangeKeyEnumNotificationIsPrior];
  } else if ([key isEqualToString:NSKeyValueChangeOldKey]) {
    return [FWFNSKeyValueChangeKeyEnumData makeWithValue:FWFNSKeyValueChangeKeyEnumOldValue];
  }

  return nil;
}

FWFWKScriptMessageData *FWFWKScriptMessageDataFromWKScriptMessage(WKScriptMessage *message) {
  return [FWFWKScriptMessageData makeWithName:message.name body:message.body];
}
