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

#import <Foundation/Foundation.h>

#import <EarlGrey/GREYDefines.h>

@class GREYError;
@class XCTestCase;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Class to help formatting error objects for logging purposes.
 */
@interface GREYFailureFormatter : NSObject

/**
 *  Format a given error object to a string for logging.
 *  The formatted failure message will follow this order:
 *
 *  FailureLabel: FailureName
 *  Source File
 *  Source Line
 *  Bundle ID
 *  Stack Trace
 *  Screenshot
 *  Window Hierarchy
 *
 *  @param error        The error object to be formatted.
 *  @param excluding    An array to exclude parts of the error from the output.
 *                      The key
 *  @param failureLabel The label to be associated with the error.
 *  @param failureName  The name to be associated with the error.
 *  @param format       Extra message to be included in the message.
 *
 *  @return Formatted error message string.
 */
+ (NSString *)formatFailureForError:(GREYError *)error
                          excluding:(NSArray *_Nullable)excluding
                       failureLabel:(NSString *)failureLabel
                        failureName:(NSString *)failureName
                             format:(NSString *)format, ... NS_FORMAT_FUNCTION(5, 6);
/**
 *  Format a failure happened in a given test case for logging.
 *
 *  The formatted failure message will follow this order:
 *
 *  FailureLabel: FailureName
 *  Source File
 *  Source Line
 *  Bundle ID
 *  Stack Trace
 *  Screenshot
 *  Window Hierarchy
 *
 *  @param testCase       The test case where the failure happens.
 *  @param failureLabel   The label to be associated with the error.
 *  @param failureName    The name to be associated with the error.
 *  @param functionName   The name of the function where the error is generated.
 *  @param filePath       The path to the source code file where the error happens.
 *  @param lineNumber     The line number of the source code file when the error happens.
 *  @param stackTrace     The stack trace of the executable when the error happens.
 *  @param appScreenshots The dictionary of app screenshot names and image paths
 *                        when the error happens.
 *  @param format         Extra message to be included in the message.
 *
 *  @return Formatted error message string.
 */
+ (NSString *)formatFailureForTestCase:(XCTestCase *)testCase
                          failureLabel:(NSString *)failureLabel
                           failureName:(NSString *)failureName
                              filePath:(NSString *)filePath
                            lineNumber:(NSUInteger)lineNumber
                          functionName:(NSString *_Nullable)functionName
                            stackTrace:(NSArray *)stackTrace
                        appScreenshots:(NSDictionary *)appScreenshots
                                format:(NSString *)format, ... NS_FORMAT_FUNCTION(9, 10);

@end

NS_ASSUME_NONNULL_END
