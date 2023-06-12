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

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "../Classes/FLTAdUtil.h"
#import "../Classes/FLTConstants.h"

@interface FLTAdUtilTest : XCTestCase
@end

@implementation FLTAdUtilTest {
  NSBundle *_mockMainBundle;
}

- (void)setUp {
  id mockBundle = OCMClassMock([NSBundle class]);
  OCMStub(ClassMethod([mockBundle mainBundle])).andReturn(mockBundle);
  _mockMainBundle = mockBundle;
}

- (void)testRequestAgent_noTemplateMetadata {
  OCMStub(
      [_mockMainBundle
          objectForInfoDictionaryKey:[OCMArg
                                         isEqual:@"FLTNewsTemplateVersion"]])
      .andReturn(nil);
  OCMStub(
      [_mockMainBundle
          objectForInfoDictionaryKey:[OCMArg
                                         isEqual:@"FLTGameTemplateVersion"]])
      .andReturn(nil);
  XCTAssertEqualObjects([FLTAdUtil requestAgent], FLT_REQUEST_AGENT_VERSIONED);
}

- (void)testRequestAgent_newsTemplateMetadata {
  OCMStub(
      [_mockMainBundle
          objectForInfoDictionaryKey:[OCMArg
                                         isEqual:@"FLTNewsTemplateVersion"]])
      .andReturn(@"v1.2.3");
  OCMStub(
      [_mockMainBundle
          objectForInfoDictionaryKey:[OCMArg
                                         isEqual:@"FLTGameTemplateVersion"]])
      .andReturn(nil);
  NSString *expected = [NSString
      stringWithFormat:@"%@%@", FLT_REQUEST_AGENT_VERSIONED, @"_News-v1.2.3"];
  XCTAssertEqualObjects([FLTAdUtil requestAgent], expected);
}

- (void)testRequestAgent_gameTemplateMetadata {
  OCMStub(
      [_mockMainBundle
          objectForInfoDictionaryKey:[OCMArg
                                         isEqual:@"FLTNewsTemplateVersion"]])
      .andReturn(nil);
  OCMStub(
      [_mockMainBundle
          objectForInfoDictionaryKey:[OCMArg
                                         isEqual:@"FLTGameTemplateVersion"]])
      .andReturn(@"123456");
  NSString *expected = [NSString
      stringWithFormat:@"%@%@", FLT_REQUEST_AGENT_VERSIONED, @"_Game-123456"];
  XCTAssertEqualObjects([FLTAdUtil requestAgent], expected);
}

- (void)testRequestAgent_gameAndNewsTemplateMetadata {
  OCMStub(
      [_mockMainBundle
          objectForInfoDictionaryKey:[OCMArg
                                         isEqual:@"FLTNewsTemplateVersion"]])
      .andReturn(@"123456");
  OCMStub(
      [_mockMainBundle
          objectForInfoDictionaryKey:[OCMArg
                                         isEqual:@"FLTGameTemplateVersion"]])
      .andReturn(@"789z");
  NSString *expected =
      [NSString stringWithFormat:@"%@%@%@", FLT_REQUEST_AGENT_VERSIONED,
                                 @"_News-123456", @"_Game-789z"];
  XCTAssertEqualObjects([FLTAdUtil requestAgent], expected);
}

@end
