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

/**
 *  Indent when perform object formation.
 */
GREY_EXTERN NSInteger const kGREYObjectFormatIndent;

NS_ASSUME_NONNULL_BEGIN

@interface GREYObjectFormatter : NSObject

/**
 *  Serializes an array of objects into JSON string.
 *  The supported objects are: NSString, NSNumber, NSArray, NSDictionary and GREYError.
 *
 *  @param array  The array to serialize.
 *  @param indent The spaces that will be applied to each element of the serialized array.
 *  @param keyOrder   Output the key-value pair in the order of the keys specified
 *                    in the keyOrder array.
 *
 *  @return JSON-ified string of the provided @c array.
 */
+ (NSString *)formatArray:(NSArray *)array indent:(NSInteger)indent keyOrder:(NSArray *)keyOrder;

/**
 *  Serializes a dictionary of objects into JSON string.
 *  The supported objects are: NSString, NSNumber, NSArray, NSDictionary and GREYError.
 *
 *  @param dictionary The dictionary to serialize.
 *  @param indent     Number of spaces that will be applied to each element
 *                    of the serialized dictionary.
 *  @param hideEmpty  Hide the key-value pair if the value in the dictionary
 *                    when the key is empty.
 *  @param keyOrder   Output the key-value pair in the order of the keys specified
 *                    in the keyOrder array.
 *
 *  @return JSON-ified string of the provided @c dictionary.
 */
+ (NSString *)formatDictionary:(NSDictionary *)dictionary
                        indent:(NSInteger)indent
                     hideEmpty:(BOOL)hideEmpty
                      keyOrder:(NSArray *_Nullable)keyOrder;

/**
 *  Serializes an array of objects into JSON-like string.
 *  The supported objects are: NSString, NSNumber, NSArray, NSDictionary.
 *
 *  @remark The serialized string is formatted as a JSON for presentation purposes but it doesn't
 *          have the right escaping applied for special character as it hinders readability.
 *
 *  @param array    The array to serialize.
 *  @param prefix   A string that will be applied to each newline of the serialized array.
 *  @param indent   The spaces that will be applied to each element of the serialized array.
 *  @param keyOrder Output the key-value pair in the order of the keys specified
 *                  in the keyOrder array.
 *  @return Serialized JSON-like string of the provided @c array.
 */
+ (NSString *)formatArray:(NSArray *)array
                   prefix:(NSString *_Nullable)prefix
                   indent:(NSInteger)indent
                 keyOrder:(NSArray *_Nullable)keyOrder;

/**
 *  Serializes a dictionary of objects into JSON-like string.
 *  The supported objects are: NSString, NSNumber, NSArray, NSDictionary.
 *
 *  @remark The serialized string is formatted as a JSON for presentation purposes but it doesn't
 *          have the right escaping applied for special character as it hinders readability.
 *
 *  @param dictionary The dictionary to serialize.
 *  @param prefix     A string that will be applied to each newline
 *                    of the serialized dictionary.
 *  @param indent     Number of spaces that will be applied to each element (key and value)
 *                    of the serialized dictionary
 *  @param hideEmpty  Hide the key-value pair if the value in the dictionary
 *                    when the key is empty.
 *  @param keyOrder   Output the key-value pair in the order of the keys specified
 *                    in the keyOrder array.
 *
 *  @return Serialized string of the provided @c dictionary.
 */
+ (NSString *)formatDictionary:(NSDictionary *)dictionary
                        prefix:(NSString *_Nullable)prefix
                        indent:(NSInteger)indent
                     hideEmpty:(BOOL)hideEmpty
                      keyOrder:(NSArray *_Nullable)keyOrder;

@end

NS_ASSUME_NONNULL_END
