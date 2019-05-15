
//
// Copyright 2016 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

/**
 *  @file GREYError+Internal.h
 *  @brief Exposes GREYError's interfaces and methods that are otherwise private for
 *  testing purposes.
 */

#import "Common/GREYError.h"

@class XCTestCase;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Key used to retrieve the error test case class name from an error object dictionary.
 */
GREY_EXTERN NSString *const kErrorTestCaseClassNameKey;

/**
 *  Key used to retrieve the test case method name from an error object dictionary.
 */
GREY_EXTERN NSString *const kErrorTestCaseMethodNameKey;

/**
 *  Key used to retrieve the file path from an error object dictionary.
 */
GREY_EXTERN NSString *const kErrorFilePathKey;

/**
 *  Key used to retrieve the file name from an error object dictionary.
 */
GREY_EXTERN NSString *const kErrorFileNameKey;

/**
 *  Key used to retrieve the line from an error object dictionary.
 */
GREY_EXTERN NSString *const kErrorLineKey;

/**
 *  Key used to retrieve the function name from an error object dictionary.
 */
GREY_EXTERN NSString *const kErrorFunctionNameKey;

/**
 *  Key used to retrieve the user info from an error object dictionary.
 */
GREY_EXTERN NSString *const kErrorUserInfoKey;

/**
 *  Key used to retrieve the error info from an error object dictionary.
 */
GREY_EXTERN NSString *const kErrorErrorInfoKey;

/**
 *  Key used to retrieve the bundle ID from an error object dictionary.
 */
GREY_EXTERN NSString *const kErrorBundleIDKey;

/**
 *  Key used to retrieve the stack trace from an error object dictionary.
 */
GREY_EXTERN NSString *const kErrorStackTraceKey;

/**
 *  Key used to retrieve the app UI hierarchy from an error object dictionary.
 */
GREY_EXTERN NSString *const kErrorAppUIHierarchyKey;

/**
 *  Key used to retrieve the app screenshots from an error object dictionary.
 */
GREY_EXTERN NSString *const kErrorAppScreenShotsKey;

/**
 *  Key used to retrieve the description glossary from an error object dictionary.
 */
GREY_EXTERN NSString *const kErrorDescriptionGlossaryKey;

@interface GREYError (Internal)

@property(nonatomic) NSString *testCaseClassName;
@property(nonatomic) NSString *testCaseMethodName;
@property(nonatomic) NSString *filePath;
@property(nonatomic) NSUInteger line;
@property(nonatomic) NSString *functionName;
@property(nonatomic) NSDictionary *errorInfo;
@property(nonatomic) NSString *bundleID;
@property(nonatomic) NSArray *stackTrace;
@property(nonatomic) NSString *appUIHierarchy;
@property(nonatomic) NSDictionary *appScreenshots;

- (instancetype)initWithDomain:(NSString *)domain
                          code:(NSInteger)code
                      userInfo:(NSDictionary *)dict
                      testCase:(XCTestCase *)testCase;

+ (instancetype)errorWithDomain:(NSString *)domain
                           code:(NSInteger)code
                       userInfo:(NSDictionary *)dict
                       testCase:(XCTestCase *)testCase;

@end

NS_ASSUME_NONNULL_END
