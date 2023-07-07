// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FWFGeneratedWebKitApis.h"

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Converts an FWFNSUrlRequestData to an NSURLRequest.
 *
 * @param data The data object containing information to create an NSURLRequest.
 *
 * @return An NSURLRequest or nil if data could not be converted.
 */
extern NSURLRequest *_Nullable FWFNSURLRequestFromRequestData(FWFNSUrlRequestData *data);

/**
 * Converts an FWFNSHttpCookieData to an NSHTTPCookie.
 *
 * @param data The data object containing information to create an NSHTTPCookie.
 *
 * @return An NSHTTPCookie or nil if data could not be converted.
 */
extern NSHTTPCookie *_Nullable FWFNSHTTPCookieFromCookieData(FWFNSHttpCookieData *data);

/**
 * Converts an FWFNSKeyValueObservingOptionsEnumData to an NSKeyValueObservingOptions.
 *
 * @param data The data object containing information to create an NSKeyValueObservingOptions.
 *
 * @return An NSKeyValueObservingOptions or -1 if data could not be converted.
 */
extern NSKeyValueObservingOptions FWFNSKeyValueObservingOptionsFromEnumData(
    FWFNSKeyValueObservingOptionsEnumData *data);

/**
 * Converts an FWFNSHTTPCookiePropertyKeyEnumData to an NSHTTPCookiePropertyKey.
 *
 * @param data The data object containing information to create an NSHTTPCookiePropertyKey.
 *
 * @return An NSHttpCookiePropertyKey or nil if data could not be converted.
 */
extern NSHTTPCookiePropertyKey _Nullable FWFNSHTTPCookiePropertyKeyFromEnumData(
    FWFNSHttpCookiePropertyKeyEnumData *data);

/**
 * Converts a WKUserScriptData to a WKUserScript.
 *
 * @param data The data object containing information to create a WKUserScript.
 *
 * @return A WKUserScript or nil if data could not be converted.
 */
extern WKUserScript *FWFWKUserScriptFromScriptData(FWFWKUserScriptData *data);

/**
 * Converts an FWFWKUserScriptInjectionTimeEnumData to a WKUserScriptInjectionTime.
 *
 * @param data The data object containing information to create a WKUserScriptInjectionTime.
 *
 * @return A WKUserScriptInjectionTime or -1 if data could not be converted.
 */
extern WKUserScriptInjectionTime FWFWKUserScriptInjectionTimeFromEnumData(
    FWFWKUserScriptInjectionTimeEnumData *data);

/**
 * Converts an FWFWKAudiovisualMediaTypeEnumData to a WKAudiovisualMediaTypes.
 *
 * @param data The data object containing information to create a WKAudiovisualMediaTypes.
 *
 * @return A WKAudiovisualMediaType or -1 if data could not be converted.
 */
API_AVAILABLE(ios(10.0))
extern WKAudiovisualMediaTypes FWFWKAudiovisualMediaTypeFromEnumData(
    FWFWKAudiovisualMediaTypeEnumData *data);

/**
 * Converts an FWFWKWebsiteDataTypeEnumData to a WKWebsiteDataType.
 *
 * @param data The data object containing information to create a WKWebsiteDataType.
 *
 * @return A WKWebsiteDataType or nil if data could not be converted.
 */
extern NSString *_Nullable FWFWKWebsiteDataTypeFromEnumData(FWFWKWebsiteDataTypeEnumData *data);

/**
 * Converts a WKNavigationAction to an FWFWKNavigationActionData.
 *
 * @param action The object containing information to create a WKNavigationActionData.
 *
 * @return A FWFWKNavigationActionData.
 */
extern FWFWKNavigationActionData *FWFWKNavigationActionDataFromNavigationAction(
    WKNavigationAction *action);

/**
 * Converts a NSURLRequest to an FWFNSUrlRequestData.
 *
 * @param request The object containing information to create a WKNavigationActionData.
 *
 * @return A FWFNSUrlRequestData.
 */
extern FWFNSUrlRequestData *FWFNSUrlRequestDataFromNSURLRequest(NSURLRequest *request);

/**
 * Converts a WKFrameInfo to an FWFWKFrameInfoData.
 *
 * @param info The object containing information to create a FWFWKFrameInfoData.
 *
 * @return A FWFWKFrameInfoData.
 */
extern FWFWKFrameInfoData *FWFWKFrameInfoDataFromWKFrameInfo(WKFrameInfo *info);

/**
 * Converts an FWFWKNavigationActionPolicyEnumData to a WKNavigationActionPolicy.
 *
 * @param data The data object containing information to create a WKNavigationActionPolicy.
 *
 * @return A WKNavigationActionPolicy or -1 if data could not be converted.
 */
extern WKNavigationActionPolicy FWFWKNavigationActionPolicyFromEnumData(
    FWFWKNavigationActionPolicyEnumData *data);

/**
 * Converts a NSError to an FWFNSErrorData.
 *
 * @param error The object containing information to create a FWFNSErrorData.
 *
 * @return A FWFNSErrorData.
 */
extern FWFNSErrorData *FWFNSErrorDataFromNSError(NSError *error);

/**
 * Converts an NSKeyValueChangeKey to a FWFNSKeyValueChangeKeyEnumData.
 *
 * @param key The data object containing information to create a FWFNSKeyValueChangeKeyEnumData.
 *
 * @return A FWFNSKeyValueChangeKeyEnumData or nil if data could not be converted.
 */
extern FWFNSKeyValueChangeKeyEnumData *FWFNSKeyValueChangeKeyEnumDataFromNSKeyValueChangeKey(
    NSKeyValueChangeKey key);

/**
 * Converts a WKScriptMessage to an FWFWKScriptMessageData.
 *
 * @param message The object containing information to create a FWFWKScriptMessageData.
 *
 * @return A FWFWKScriptMessageData.
 */
extern FWFWKScriptMessageData *FWFWKScriptMessageDataFromWKScriptMessage(WKScriptMessage *message);

NS_ASSUME_NONNULL_END
