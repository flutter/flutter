// Protocol Buffers - Google's data interchange format
// Copyright 2008 Google Inc.  All rights reserved.
// http://code.google.com/p/protobuf/
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// Author: kenton@google.com (Kenton Varda)
//  Based on original Protocol Buffers design by
//  Sanjay Ghemawat, Jeff Dean, and others.

#include <vector>
#include <algorithm>
#include <map>

#include <google/protobuf/compiler/parser.h>

#include <google/protobuf/io/tokenizer.h>
#include <google/protobuf/io/zero_copy_stream_impl.h>
#include <google/protobuf/descriptor.pb.h>
#include <google/protobuf/wire_format.h>
#include <google/protobuf/text_format.h>
#include <google/protobuf/unittest.pb.h>
#include <google/protobuf/unittest_custom_options.pb.h>
#include <google/protobuf/stubs/strutil.h>
#include <google/protobuf/stubs/substitute.h>
#include <google/protobuf/stubs/map-util.h>

#include <google/protobuf/testing/googletest.h>
#include <gtest/gtest.h>

namespace google {
namespace protobuf {
namespace compiler {

namespace {

class MockErrorCollector : public io::ErrorCollector {
 public:
  MockErrorCollector() {}
  ~MockErrorCollector() {}

  string text_;

  // implements ErrorCollector ---------------------------------------
  void AddError(int line, int column, const string& message) {
    strings::SubstituteAndAppend(&text_, "$0:$1: $2\n",
                                 line, column, message);
  }
};

class MockValidationErrorCollector : public DescriptorPool::ErrorCollector {
 public:
  MockValidationErrorCollector(const SourceLocationTable& source_locations,
                               io::ErrorCollector* wrapped_collector)
    : source_locations_(source_locations),
      wrapped_collector_(wrapped_collector) {}
  ~MockValidationErrorCollector() {}

  // implements ErrorCollector ---------------------------------------
  void AddError(const string& filename,
                const string& element_name,
                const Message* descriptor,
                ErrorLocation location,
                const string& message) {
    int line, column;
    source_locations_.Find(descriptor, location, &line, &column);
    wrapped_collector_->AddError(line, column, message);
  }

 private:
  const SourceLocationTable& source_locations_;
  io::ErrorCollector* wrapped_collector_;
};

class ParserTest : public testing::Test {
 protected:
  ParserTest()
    : require_syntax_identifier_(false) {}

  // Set up the parser to parse the given text.
  void SetupParser(const char* text) {
    raw_input_.reset(new io::ArrayInputStream(text, strlen(text)));
    input_.reset(new io::Tokenizer(raw_input_.get(), &error_collector_));
    parser_.reset(new Parser());
    parser_->RecordErrorsTo(&error_collector_);
    parser_->SetRequireSyntaxIdentifier(require_syntax_identifier_);
  }

  // Parse the input and expect that the resulting FileDescriptorProto matches
  // the given output.  The output is a FileDescriptorProto in protocol buffer
  // text format.
  void ExpectParsesTo(const char* input, const char* output) {
    SetupParser(input);
    FileDescriptorProto actual, expected;

    parser_->Parse(input_.get(), &actual);
    EXPECT_EQ(io::Tokenizer::TYPE_END, input_->current().type);
    ASSERT_EQ("", error_collector_.text_);

    // We don't cover SourceCodeInfo in these tests.
    actual.clear_source_code_info();

    // Parse the ASCII representation in order to canonicalize it.  We could
    // just compare directly to actual.DebugString(), but that would require
    // that the caller precisely match the formatting that DebugString()
    // produces.
    ASSERT_TRUE(TextFormat::ParseFromString(output, &expected));

    // Compare by comparing debug strings.
    // TODO(kenton):  Use differencer, once it is available.
    EXPECT_EQ(expected.DebugString(), actual.DebugString());
  }

  // Parse the text and expect that the given errors are reported.
  void ExpectHasErrors(const char* text, const char* expected_errors) {
    ExpectHasEarlyExitErrors(text, expected_errors);
    EXPECT_EQ(io::Tokenizer::TYPE_END, input_->current().type);
  }

  // Same as above but does not expect that the parser parses the complete
  // input.
  void ExpectHasEarlyExitErrors(const char* text, const char* expected_errors) {
    SetupParser(text);
    FileDescriptorProto file;
    parser_->Parse(input_.get(), &file);
    EXPECT_EQ(expected_errors, error_collector_.text_);
  }

  // Parse the text as a file and validate it (with a DescriptorPool), and
  // expect that the validation step reports the given errors.
  void ExpectHasValidationErrors(const char* text,
                                 const char* expected_errors) {
    SetupParser(text);
    SourceLocationTable source_locations;
    parser_->RecordSourceLocationsTo(&source_locations);

    FileDescriptorProto file;
    file.set_name("foo.proto");
    parser_->Parse(input_.get(), &file);
    EXPECT_EQ(io::Tokenizer::TYPE_END, input_->current().type);
    ASSERT_EQ("", error_collector_.text_);

    MockValidationErrorCollector validation_error_collector(
      source_locations, &error_collector_);
    EXPECT_TRUE(pool_.BuildFileCollectingErrors(
      file, &validation_error_collector) == NULL);
    EXPECT_EQ(expected_errors, error_collector_.text_);
  }

  MockErrorCollector error_collector_;
  DescriptorPool pool_;

  scoped_ptr<io::ZeroCopyInputStream> raw_input_;
  scoped_ptr<io::Tokenizer> input_;
  scoped_ptr<Parser> parser_;
  bool require_syntax_identifier_;
};

// ===================================================================

TEST_F(ParserTest, StopAfterSyntaxIdentifier) {
  SetupParser(
    "// blah\n"
    "syntax = \"foobar\";\n"
    "this line will not be parsed\n");
  parser_->SetStopAfterSyntaxIdentifier(true);
  EXPECT_TRUE(parser_->Parse(input_.get(), NULL));
  EXPECT_EQ("", error_collector_.text_);
  EXPECT_EQ("foobar", parser_->GetSyntaxIdentifier());
}

TEST_F(ParserTest, StopAfterOmittedSyntaxIdentifier) {
  SetupParser(
    "// blah\n"
    "this line will not be parsed\n");
  parser_->SetStopAfterSyntaxIdentifier(true);
  EXPECT_TRUE(parser_->Parse(input_.get(), NULL));
  EXPECT_EQ("", error_collector_.text_);
  EXPECT_EQ("", parser_->GetSyntaxIdentifier());
}

TEST_F(ParserTest, StopAfterSyntaxIdentifierWithErrors) {
  SetupParser(
    "// blah\n"
    "syntax = error;\n");
  parser_->SetStopAfterSyntaxIdentifier(true);
  EXPECT_FALSE(parser_->Parse(input_.get(), NULL));
  EXPECT_EQ("1:9: Expected syntax identifier.\n", error_collector_.text_);
}

// ===================================================================

typedef ParserTest ParseMessageTest;

TEST_F(ParseMessageTest, SimpleMessage) {
  ExpectParsesTo(
    "message TestMessage {\n"
    "  required int32 foo = 1;\n"
    "}\n",

    "message_type {"
    "  name: \"TestMessage\""
    "  field { name:\"foo\" label:LABEL_REQUIRED type:TYPE_INT32 number:1 }"
    "}");
}

TEST_F(ParseMessageTest, ImplicitSyntaxIdentifier) {
  require_syntax_identifier_ = false;
  ExpectParsesTo(
    "message TestMessage {\n"
    "  required int32 foo = 1;\n"
    "}\n",

    "message_type {"
    "  name: \"TestMessage\""
    "  field { name:\"foo\" label:LABEL_REQUIRED type:TYPE_INT32 number:1 }"
    "}");
  EXPECT_EQ("proto2", parser_->GetSyntaxIdentifier());
}

TEST_F(ParseMessageTest, ExplicitSyntaxIdentifier) {
  ExpectParsesTo(
    "syntax = \"proto2\";\n"
    "message TestMessage {\n"
    "  required int32 foo = 1;\n"
    "}\n",

    "message_type {"
    "  name: \"TestMessage\""
    "  field { name:\"foo\" label:LABEL_REQUIRED type:TYPE_INT32 number:1 }"
    "}");
  EXPECT_EQ("proto2", parser_->GetSyntaxIdentifier());
}

TEST_F(ParseMessageTest, ExplicitRequiredSyntaxIdentifier) {
  require_syntax_identifier_ = true;
  ExpectParsesTo(
    "syntax = \"proto2\";\n"
    "message TestMessage {\n"
    "  required int32 foo = 1;\n"
    "}\n",

    "message_type {"
    "  name: \"TestMessage\""
    "  field { name:\"foo\" label:LABEL_REQUIRED type:TYPE_INT32 number:1 }"
    "}");
  EXPECT_EQ("proto2", parser_->GetSyntaxIdentifier());
}

TEST_F(ParseMessageTest, SimpleFields) {
  ExpectParsesTo(
    "message TestMessage {\n"
    "  required int32 foo = 15;\n"
    "  optional int32 bar = 34;\n"
    "  repeated int32 baz = 3;\n"
    "}\n",

    "message_type {"
    "  name: \"TestMessage\""
    "  field { name:\"foo\" label:LABEL_REQUIRED type:TYPE_INT32 number:15 }"
    "  field { name:\"bar\" label:LABEL_OPTIONAL type:TYPE_INT32 number:34 }"
    "  field { name:\"baz\" label:LABEL_REPEATED type:TYPE_INT32 number:3  }"
    "}");
}

TEST_F(ParseMessageTest, PrimitiveFieldTypes) {
  ExpectParsesTo(
    "message TestMessage {\n"
    "  required int32    foo = 1;\n"
    "  required int64    foo = 1;\n"
    "  required uint32   foo = 1;\n"
    "  required uint64   foo = 1;\n"
    "  required sint32   foo = 1;\n"
    "  required sint64   foo = 1;\n"
    "  required fixed32  foo = 1;\n"
    "  required fixed64  foo = 1;\n"
    "  required sfixed32 foo = 1;\n"
    "  required sfixed64 foo = 1;\n"
    "  required float    foo = 1;\n"
    "  required double   foo = 1;\n"
    "  required string   foo = 1;\n"
    "  required bytes    foo = 1;\n"
    "  required bool     foo = 1;\n"
    "}\n",

    "message_type {"
    "  name: \"TestMessage\""
    "  field { name:\"foo\" label:LABEL_REQUIRED type:TYPE_INT32    number:1 }"
    "  field { name:\"foo\" label:LABEL_REQUIRED type:TYPE_INT64    number:1 }"
    "  field { name:\"foo\" label:LABEL_REQUIRED type:TYPE_UINT32   number:1 }"
    "  field { name:\"foo\" label:LABEL_REQUIRED type:TYPE_UINT64   number:1 }"
    "  field { name:\"foo\" label:LABEL_REQUIRED type:TYPE_SINT32   number:1 }"
    "  field { name:\"foo\" label:LABEL_REQUIRED type:TYPE_SINT64   number:1 }"
    "  field { name:\"foo\" label:LABEL_REQUIRED type:TYPE_FIXED32  number:1 }"
    "  field { name:\"foo\" label:LABEL_REQUIRED type:TYPE_FIXED64  number:1 }"
    "  field { name:\"foo\" label:LABEL_REQUIRED type:TYPE_SFIXED32 number:1 }"
    "  field { name:\"foo\" label:LABEL_REQUIRED type:TYPE_SFIXED64 number:1 }"
    "  field { name:\"foo\" label:LABEL_REQUIRED type:TYPE_FLOAT    number:1 }"
    "  field { name:\"foo\" label:LABEL_REQUIRED type:TYPE_DOUBLE   number:1 }"
    "  field { name:\"foo\" label:LABEL_REQUIRED type:TYPE_STRING   number:1 }"
    "  field { name:\"foo\" label:LABEL_REQUIRED type:TYPE_BYTES    number:1 }"
    "  field { name:\"foo\" label:LABEL_REQUIRED type:TYPE_BOOL     number:1 }"
    "}");
}

TEST_F(ParseMessageTest, FieldDefaults) {
  ExpectParsesTo(
    "message TestMessage {\n"
    "  required int32  foo = 1 [default=  1  ];\n"
    "  required int32  foo = 1 [default= -2  ];\n"
    "  required int64  foo = 1 [default=  3  ];\n"
    "  required int64  foo = 1 [default= -4  ];\n"
    "  required uint32 foo = 1 [default=  5  ];\n"
    "  required uint64 foo = 1 [default=  6  ];\n"
    "  required float  foo = 1 [default=  7.5];\n"
    "  required float  foo = 1 [default= -8.5];\n"
    "  required float  foo = 1 [default=  9  ];\n"
    "  required double foo = 1 [default= 10.5];\n"
    "  required double foo = 1 [default=-11.5];\n"
    "  required double foo = 1 [default= 12  ];\n"
    "  required double foo = 1 [default= inf ];\n"
    "  required double foo = 1 [default=-inf ];\n"
    "  required double foo = 1 [default= nan ];\n"
    "  required string foo = 1 [default='13\\001'];\n"
    "  required string foo = 1 [default='a' \"b\" \n \"c\"];\n"
    "  required bytes  foo = 1 [default='14\\002'];\n"
    "  required bytes  foo = 1 [default='a' \"b\" \n 'c'];\n"
    "  required bool   foo = 1 [default=true ];\n"
    "  required Foo    foo = 1 [default=FOO  ];\n"

    "  required int32  foo = 1 [default= 0x7FFFFFFF];\n"
    "  required int32  foo = 1 [default=-0x80000000];\n"
    "  required uint32 foo = 1 [default= 0xFFFFFFFF];\n"
    "  required int64  foo = 1 [default= 0x7FFFFFFFFFFFFFFF];\n"
    "  required int64  foo = 1 [default=-0x8000000000000000];\n"
    "  required uint64 foo = 1 [default= 0xFFFFFFFFFFFFFFFF];\n"
    "  required double foo = 1 [default= 0xabcd];\n"
    "}\n",

#define ETC "name:\"foo\" label:LABEL_REQUIRED number:1"
    "message_type {"
    "  name: \"TestMessage\""
    "  field { type:TYPE_INT32   default_value:\"1\"         "ETC" }"
    "  field { type:TYPE_INT32   default_value:\"-2\"        "ETC" }"
    "  field { type:TYPE_INT64   default_value:\"3\"         "ETC" }"
    "  field { type:TYPE_INT64   default_value:\"-4\"        "ETC" }"
    "  field { type:TYPE_UINT32  default_value:\"5\"         "ETC" }"
    "  field { type:TYPE_UINT64  default_value:\"6\"         "ETC" }"
    "  field { type:TYPE_FLOAT   default_value:\"7.5\"       "ETC" }"
    "  field { type:TYPE_FLOAT   default_value:\"-8.5\"      "ETC" }"
    "  field { type:TYPE_FLOAT   default_value:\"9\"         "ETC" }"
    "  field { type:TYPE_DOUBLE  default_value:\"10.5\"      "ETC" }"
    "  field { type:TYPE_DOUBLE  default_value:\"-11.5\"     "ETC" }"
    "  field { type:TYPE_DOUBLE  default_value:\"12\"        "ETC" }"
    "  field { type:TYPE_DOUBLE  default_value:\"inf\"       "ETC" }"
    "  field { type:TYPE_DOUBLE  default_value:\"-inf\"      "ETC" }"
    "  field { type:TYPE_DOUBLE  default_value:\"nan\"       "ETC" }"
    "  field { type:TYPE_STRING  default_value:\"13\\001\"   "ETC" }"
    "  field { type:TYPE_STRING  default_value:\"abc\"       "ETC" }"
    "  field { type:TYPE_BYTES   default_value:\"14\\\\002\" "ETC" }"
    "  field { type:TYPE_BYTES   default_value:\"abc\"       "ETC" }"
    "  field { type:TYPE_BOOL    default_value:\"true\"      "ETC" }"
    "  field { type_name:\"Foo\" default_value:\"FOO\"       "ETC" }"

    "  field { type:TYPE_INT32   default_value:\"2147483647\"           "ETC" }"
    "  field { type:TYPE_INT32   default_value:\"-2147483648\"          "ETC" }"
    "  field { type:TYPE_UINT32  default_value:\"4294967295\"           "ETC" }"
    "  field { type:TYPE_INT64   default_value:\"9223372036854775807\"  "ETC" }"
    "  field { type:TYPE_INT64   default_value:\"-9223372036854775808\" "ETC" }"
    "  field { type:TYPE_UINT64  default_value:\"18446744073709551615\" "ETC" }"
    "  field { type:TYPE_DOUBLE  default_value:\"43981\"                "ETC" }"
    "}");
#undef ETC
}

TEST_F(ParseMessageTest, FieldOptions) {
  ExpectParsesTo(
    "message TestMessage {\n"
    "  optional string foo = 1\n"
    "      [ctype=CORD, (foo)=7, foo.(.bar.baz).qux.quux.(corge)=-33, \n"
    "       (quux)=\"x\040y\", (baz.qux)=hey];\n"
    "}\n",

    "message_type {"
    "  name: \"TestMessage\""
    "  field { name: \"foo\" label: LABEL_OPTIONAL type: TYPE_STRING number: 1"
    "          options { uninterpreted_option: { name { name_part: \"ctype\" "
    "                                                   is_extension: false } "
    "                                            identifier_value: \"CORD\"  }"
    "                    uninterpreted_option: { name { name_part: \"foo\" "
    "                                                   is_extension: true } "
    "                                            positive_int_value: 7  }"
    "                    uninterpreted_option: { name { name_part: \"foo\" "
    "                                                   is_extension: false } "
    "                                            name { name_part: \".bar.baz\""
    "                                                   is_extension: true } "
    "                                            name { name_part: \"qux\" "
    "                                                   is_extension: false } "
    "                                            name { name_part: \"quux\" "
    "                                                   is_extension: false } "
    "                                            name { name_part: \"corge\" "
    "                                                   is_extension: true } "
    "                                            negative_int_value: -33 }"
    "                    uninterpreted_option: { name { name_part: \"quux\" "
    "                                                   is_extension: true } "
    "                                            string_value: \"x y\" }"
    "                    uninterpreted_option: { name { name_part: \"baz.qux\" "
    "                                                   is_extension: true } "
    "                                            identifier_value: \"hey\" }"
    "          }"
    "  }"
    "}");
}

TEST_F(ParseMessageTest, Group) {
  ExpectParsesTo(
    "message TestMessage {\n"
    "  optional group TestGroup = 1 {};\n"
    "}\n",

    "message_type {"
    "  name: \"TestMessage\""
    "  nested_type { name: \"TestGroup\" }"
    "  field { name:\"testgroup\" label:LABEL_OPTIONAL number:1"
    "          type:TYPE_GROUP type_name: \"TestGroup\" }"
    "}");
}

TEST_F(ParseMessageTest, NestedMessage) {
  ExpectParsesTo(
    "message TestMessage {\n"
    "  message Nested {}\n"
    "  optional Nested test_nested = 1;\n"
    "}\n",

    "message_type {"
    "  name: \"TestMessage\""
    "  nested_type { name: \"Nested\" }"
    "  field { name:\"test_nested\" label:LABEL_OPTIONAL number:1"
    "          type_name: \"Nested\" }"
    "}");
}

TEST_F(ParseMessageTest, NestedEnum) {
  ExpectParsesTo(
    "message TestMessage {\n"
    "  enum NestedEnum {}\n"
    "  optional NestedEnum test_enum = 1;\n"
    "}\n",

    "message_type {"
    "  name: \"TestMessage\""
    "  enum_type { name: \"NestedEnum\" }"
    "  field { name:\"test_enum\" label:LABEL_OPTIONAL number:1"
    "          type_name: \"NestedEnum\" }"
    "}");
}

TEST_F(ParseMessageTest, ExtensionRange) {
  ExpectParsesTo(
    "message TestMessage {\n"
    "  extensions 10 to 19;\n"
    "  extensions 30 to max;\n"
    "}\n",

    "message_type {"
    "  name: \"TestMessage\""
    "  extension_range { start:10 end:20        }"
    "  extension_range { start:30 end:536870912 }"
    "}");
}

TEST_F(ParseMessageTest, CompoundExtensionRange) {
  ExpectParsesTo(
    "message TestMessage {\n"
    "  extensions 2, 15, 9 to 11, 100 to max, 3;\n"
    "}\n",

    "message_type {"
    "  name: \"TestMessage\""
    "  extension_range { start:2   end:3         }"
    "  extension_range { start:15  end:16        }"
    "  extension_range { start:9   end:12        }"
    "  extension_range { start:100 end:536870912 }"
    "  extension_range { start:3   end:4         }"
    "}");
}

TEST_F(ParseMessageTest, LargerMaxForMessageSetWireFormatMessages) {
  // Messages using the message_set_wire_format option can accept larger
  // extension numbers, as the numbers are not encoded as int32 field values
  // rather than tags.
  ExpectParsesTo(
    "message TestMessage {\n"
    "  extensions 4 to max;\n"
    "  option message_set_wire_format = true;\n"
    "}\n",

    "message_type {"
    "  name: \"TestMessage\""
    "    extension_range { start:4 end: 0x7fffffff }"
    "  options {\n"
    "    uninterpreted_option { \n"
    "      name {\n"
    "        name_part: \"message_set_wire_format\"\n"
    "        is_extension: false\n"
    "      }\n"
    "      identifier_value: \"true\"\n"
    "    }\n"
    "  }\n"
    "}");
}

TEST_F(ParseMessageTest, Extensions) {
  ExpectParsesTo(
    "extend Extendee1 { optional int32 foo = 12; }\n"
    "extend Extendee2 { repeated TestMessage bar = 22; }\n",

    "extension { name:\"foo\" label:LABEL_OPTIONAL type:TYPE_INT32 number:12"
    "            extendee: \"Extendee1\" } "
    "extension { name:\"bar\" label:LABEL_REPEATED number:22"
    "            type_name:\"TestMessage\" extendee: \"Extendee2\" }");
}

TEST_F(ParseMessageTest, ExtensionsInMessageScope) {
  ExpectParsesTo(
    "message TestMessage {\n"
    "  extend Extendee1 { optional int32 foo = 12; }\n"
    "  extend Extendee2 { repeated TestMessage bar = 22; }\n"
    "}\n",

    "message_type {"
    "  name: \"TestMessage\""
    "  extension { name:\"foo\" label:LABEL_OPTIONAL type:TYPE_INT32 number:12"
    "              extendee: \"Extendee1\" }"
    "  extension { name:\"bar\" label:LABEL_REPEATED number:22"
    "              type_name:\"TestMessage\" extendee: \"Extendee2\" }"
    "}");
}

TEST_F(ParseMessageTest, MultipleExtensionsOneExtendee) {
  ExpectParsesTo(
    "extend Extendee1 {\n"
    "  optional int32 foo = 12;\n"
    "  repeated TestMessage bar = 22;\n"
    "}\n",

    "extension { name:\"foo\" label:LABEL_OPTIONAL type:TYPE_INT32 number:12"
    "            extendee: \"Extendee1\" } "
    "extension { name:\"bar\" label:LABEL_REPEATED number:22"
    "            type_name:\"TestMessage\" extendee: \"Extendee1\" }");
}

// ===================================================================

typedef ParserTest ParseEnumTest;

TEST_F(ParseEnumTest, SimpleEnum) {
  ExpectParsesTo(
    "enum TestEnum {\n"
    "  FOO = 0;\n"
    "}\n",

    "enum_type {"
    "  name: \"TestEnum\""
    "  value { name:\"FOO\" number:0 }"
    "}");
}

TEST_F(ParseEnumTest, Values) {
  ExpectParsesTo(
    "enum TestEnum {\n"
    "  FOO = 13;\n"
    "  BAR = -10;\n"
    "  BAZ = 500;\n"
    "  HEX_MAX = 0x7FFFFFFF;\n"
    "  HEX_MIN = -0x80000000;\n"
    "  INT_MAX = 2147483647;\n"
    "  INT_MIN = -2147483648;\n"
    "}\n",

    "enum_type {"
    "  name: \"TestEnum\""
    "  value { name:\"FOO\" number:13 }"
    "  value { name:\"BAR\" number:-10 }"
    "  value { name:\"BAZ\" number:500 }"
    "  value { name:\"HEX_MAX\" number:2147483647 }"
    "  value { name:\"HEX_MIN\" number:-2147483648 }"
    "  value { name:\"INT_MAX\" number:2147483647 }"
    "  value { name:\"INT_MIN\" number:-2147483648 }"
    "}");
}

TEST_F(ParseEnumTest, ValueOptions) {
  ExpectParsesTo(
    "enum TestEnum {\n"
    "  FOO = 13;\n"
    "  BAR = -10 [ (something.text) = 'abc' ];\n"
    "  BAZ = 500 [ (something.text) = 'def', other = 1 ];\n"
    "}\n",

    "enum_type {"
    "  name: \"TestEnum\""
    "  value { name: \"FOO\" number: 13 }"
    "  value { name: \"BAR\" number: -10 "
    "    options { "
    "      uninterpreted_option { "
    "        name { name_part: \"something.text\" is_extension: true } "
    "        string_value: \"abc\" "
    "      } "
    "    } "
    "  } "
    "  value { name: \"BAZ\" number: 500 "
    "    options { "
    "      uninterpreted_option { "
    "        name { name_part: \"something.text\" is_extension: true } "
    "        string_value: \"def\" "
    "      } "
    "      uninterpreted_option { "
    "        name { name_part: \"other\" is_extension: false } "
    "        positive_int_value: 1 "
    "      } "
    "    } "
    "  } "
    "}");
}

// ===================================================================

typedef ParserTest ParseServiceTest;

TEST_F(ParseServiceTest, SimpleService) {
  ExpectParsesTo(
    "service TestService {\n"
    "  rpc Foo(In) returns (Out);\n"
    "}\n",

    "service {"
    "  name: \"TestService\""
    "  method { name:\"Foo\" input_type:\"In\" output_type:\"Out\" }"
    "}");
}

TEST_F(ParseServiceTest, MethodsAndStreams) {
  ExpectParsesTo(
    "service TestService {\n"
    "  rpc Foo(In1) returns (Out1);\n"
    "  rpc Bar(In2) returns (Out2);\n"
    "  rpc Baz(In3) returns (Out3);\n"
    "}\n",

    "service {"
    "  name: \"TestService\""
    "  method { name:\"Foo\" input_type:\"In1\" output_type:\"Out1\" }"
    "  method { name:\"Bar\" input_type:\"In2\" output_type:\"Out2\" }"
    "  method { name:\"Baz\" input_type:\"In3\" output_type:\"Out3\" }"
    "}");
}

// ===================================================================
// imports and packages

typedef ParserTest ParseMiscTest;

TEST_F(ParseMiscTest, ParseImport) {
  ExpectParsesTo(
    "import \"foo/bar/baz.proto\";\n",
    "dependency: \"foo/bar/baz.proto\"");
}

TEST_F(ParseMiscTest, ParseMultipleImports) {
  ExpectParsesTo(
    "import \"foo.proto\";\n"
    "import \"bar.proto\";\n"
    "import \"baz.proto\";\n",
    "dependency: \"foo.proto\""
    "dependency: \"bar.proto\""
    "dependency: \"baz.proto\"");
}

TEST_F(ParseMiscTest, ParsePublicImports) {
  ExpectParsesTo(
    "import \"foo.proto\";\n"
    "import public \"bar.proto\";\n"
    "import \"baz.proto\";\n"
    "import public \"qux.proto\";\n",
    "dependency: \"foo.proto\""
    "dependency: \"bar.proto\""
    "dependency: \"baz.proto\""
    "dependency: \"qux.proto\""
    "public_dependency: 1 "
    "public_dependency: 3 ");
}

TEST_F(ParseMiscTest, ParsePackage) {
  ExpectParsesTo(
    "package foo.bar.baz;\n",
    "package: \"foo.bar.baz\"");
}

TEST_F(ParseMiscTest, ParsePackageWithSpaces) {
  ExpectParsesTo(
    "package foo   .   bar.  \n"
    "  baz;\n",
    "package: \"foo.bar.baz\"");
}

// ===================================================================
// options

TEST_F(ParseMiscTest, ParseFileOptions) {
  ExpectParsesTo(
    "option java_package = \"com.google.foo\";\n"
    "option optimize_for = CODE_SIZE;",

    "options {"
    "uninterpreted_option { name { name_part: \"java_package\" "
    "                              is_extension: false }"
    "                       string_value: \"com.google.foo\"} "
    "uninterpreted_option { name { name_part: \"optimize_for\" "
    "                              is_extension: false }"
    "                       identifier_value: \"CODE_SIZE\" } "
    "}");
}

// ===================================================================
// Error tests
//
// There are a very large number of possible errors that the parser could
// report, so it's infeasible to test every single one of them.  Instead,
// we test each unique call to AddError() in parser.h.  This does not mean
// we are testing every possible error that Parser can generate because
// each variant of the Consume() helper only counts as one unique call to
// AddError().

typedef ParserTest ParseErrorTest;

TEST_F(ParseErrorTest, MissingSyntaxIdentifier) {
  require_syntax_identifier_ = true;
  ExpectHasEarlyExitErrors(
    "message TestMessage {}",
    "0:0: File must begin with 'syntax = \"proto2\";'.\n");
  EXPECT_EQ("", parser_->GetSyntaxIdentifier());
}

TEST_F(ParseErrorTest, UnknownSyntaxIdentifier) {
  ExpectHasEarlyExitErrors(
    "syntax = \"no_such_syntax\";",
    "0:9: Unrecognized syntax identifier \"no_such_syntax\".  This parser "
      "only recognizes \"proto2\".\n");
  EXPECT_EQ("no_such_syntax", parser_->GetSyntaxIdentifier());
}

TEST_F(ParseErrorTest, SimpleSyntaxError) {
  ExpectHasErrors(
    "message TestMessage @#$ { blah }",
    "0:20: Expected \"{\".\n");
  EXPECT_EQ("proto2", parser_->GetSyntaxIdentifier());
}

TEST_F(ParseErrorTest, ExpectedTopLevel) {
  ExpectHasErrors(
    "blah;",
    "0:0: Expected top-level statement (e.g. \"message\").\n");
}

TEST_F(ParseErrorTest, UnmatchedCloseBrace) {
  // This used to cause an infinite loop.  Doh.
  ExpectHasErrors(
    "}",
    "0:0: Expected top-level statement (e.g. \"message\").\n"
    "0:0: Unmatched \"}\".\n");
}

// -------------------------------------------------------------------
// Message errors

TEST_F(ParseErrorTest, MessageMissingName) {
  ExpectHasErrors(
    "message {}",
    "0:8: Expected message name.\n");
}

TEST_F(ParseErrorTest, MessageMissingBody) {
  ExpectHasErrors(
    "message TestMessage;",
    "0:19: Expected \"{\".\n");
}

TEST_F(ParseErrorTest, EofInMessage) {
  ExpectHasErrors(
    "message TestMessage {",
    "0:21: Reached end of input in message definition (missing '}').\n");
}

TEST_F(ParseErrorTest, MissingFieldNumber) {
  ExpectHasErrors(
    "message TestMessage {\n"
    "  optional int32 foo;\n"
    "}\n",
    "1:20: Missing field number.\n");
}

TEST_F(ParseErrorTest, ExpectedFieldNumber) {
  ExpectHasErrors(
    "message TestMessage {\n"
    "  optional int32 foo = ;\n"
    "}\n",
    "1:23: Expected field number.\n");
}

TEST_F(ParseErrorTest, FieldNumberOutOfRange) {
  ExpectHasErrors(
    "message TestMessage {\n"
    "  optional int32 foo = 0x100000000;\n"
    "}\n",
    "1:23: Integer out of range.\n");
}

TEST_F(ParseErrorTest, MissingLabel) {
  ExpectHasErrors(
    "message TestMessage {\n"
    "  int32 foo = 1;\n"
    "}\n",
    "1:2: Expected \"required\", \"optional\", or \"repeated\".\n");
}

TEST_F(ParseErrorTest, ExpectedOptionName) {
  ExpectHasErrors(
    "message TestMessage {\n"
    "  optional uint32 foo = 1 [];\n"
    "}\n",
    "1:27: Expected identifier.\n");
}

TEST_F(ParseErrorTest, NonExtensionOptionNameBeginningWithDot) {
  ExpectHasErrors(
    "message TestMessage {\n"
    "  optional uint32 foo = 1 [.foo=1];\n"
    "}\n",
    "1:27: Expected identifier.\n");
}

TEST_F(ParseErrorTest, DefaultValueTypeMismatch) {
  ExpectHasErrors(
    "message TestMessage {\n"
    "  optional uint32 foo = 1 [default=true];\n"
    "}\n",
    "1:35: Expected integer.\n");
}

TEST_F(ParseErrorTest, DefaultValueNotBoolean) {
  ExpectHasErrors(
    "message TestMessage {\n"
    "  optional bool foo = 1 [default=blah];\n"
    "}\n",
    "1:33: Expected \"true\" or \"false\".\n");
}

TEST_F(ParseErrorTest, DefaultValueNotString) {
  ExpectHasErrors(
    "message TestMessage {\n"
    "  optional string foo = 1 [default=1];\n"
    "}\n",
    "1:35: Expected string.\n");
}

TEST_F(ParseErrorTest, DefaultValueUnsignedNegative) {
  ExpectHasErrors(
    "message TestMessage {\n"
    "  optional uint32 foo = 1 [default=-1];\n"
    "}\n",
    "1:36: Unsigned field can't have negative default value.\n");
}

TEST_F(ParseErrorTest, DefaultValueTooLarge) {
  ExpectHasErrors(
    "message TestMessage {\n"
    "  optional int32  foo = 1 [default= 0x80000000];\n"
    "  optional int32  foo = 1 [default=-0x80000001];\n"
    "  optional uint32 foo = 1 [default= 0x100000000];\n"
    "  optional int64  foo = 1 [default= 0x80000000000000000];\n"
    "  optional int64  foo = 1 [default=-0x80000000000000001];\n"
    "  optional uint64 foo = 1 [default= 0x100000000000000000];\n"
    "}\n",
    "1:36: Integer out of range.\n"
    "2:36: Integer out of range.\n"
    "3:36: Integer out of range.\n"
    "4:36: Integer out of range.\n"
    "5:36: Integer out of range.\n"
    "6:36: Integer out of range.\n");
}

TEST_F(ParseErrorTest, EnumValueOutOfRange) {
  ExpectHasErrors(
    "enum TestEnum {\n"
    "  HEX_TOO_BIG   =  0x80000000;\n"
    "  HEX_TOO_SMALL = -0x80000001;\n"
    "  INT_TOO_BIG   =  2147483648;\n"
    "  INT_TOO_SMALL = -2147483649;\n"
    "}\n",
    "1:19: Integer out of range.\n"
    "2:19: Integer out of range.\n"
    "3:19: Integer out of range.\n"
    "4:19: Integer out of range.\n");
}

TEST_F(ParseErrorTest, DefaultValueMissing) {
  ExpectHasErrors(
    "message TestMessage {\n"
    "  optional uint32 foo = 1 [default=];\n"
    "}\n",
    "1:35: Expected integer.\n");
}

TEST_F(ParseErrorTest, DefaultValueForGroup) {
  ExpectHasErrors(
    "message TestMessage {\n"
    "  optional group Foo = 1 [default=blah] {}\n"
    "}\n",
    "1:34: Messages can't have default values.\n");
}

TEST_F(ParseErrorTest, DuplicateDefaultValue) {
  ExpectHasErrors(
    "message TestMessage {\n"
    "  optional uint32 foo = 1 [default=1,default=2];\n"
    "}\n",
    "1:37: Already set option \"default\".\n");
}

TEST_F(ParseErrorTest, GroupNotCapitalized) {
  ExpectHasErrors(
    "message TestMessage {\n"
    "  optional group foo = 1 {}\n"
    "}\n",
    "1:17: Group names must start with a capital letter.\n");
}

TEST_F(ParseErrorTest, GroupMissingBody) {
  ExpectHasErrors(
    "message TestMessage {\n"
    "  optional group Foo = 1;\n"
    "}\n",
    "1:24: Missing group body.\n");
}

TEST_F(ParseErrorTest, ExtendingPrimitive) {
  ExpectHasErrors(
    "extend int32 { optional string foo = 4; }\n",
    "0:7: Expected message type.\n");
}

TEST_F(ParseErrorTest, ErrorInExtension) {
  ExpectHasErrors(
    "message Foo { extensions 100 to 199; }\n"
    "extend Foo { optional string foo; }\n",
    "1:32: Missing field number.\n");
}

TEST_F(ParseErrorTest, MultipleParseErrors) {
  // When a statement has a parse error, the parser should be able to continue
  // parsing at the next statement.
  ExpectHasErrors(
    "message TestMessage {\n"
    "  optional int32 foo;\n"
    "  !invalid statement ending in a block { blah blah { blah } blah }\n"
    "  optional int32 bar = 3 {}\n"
    "}\n",
    "1:20: Missing field number.\n"
    "2:2: Expected \"required\", \"optional\", or \"repeated\".\n"
    "2:2: Expected type name.\n"
    "3:25: Expected \";\".\n");
}

TEST_F(ParseErrorTest, EofInAggregateValue) {
  ExpectHasErrors(
      "option (fileopt) = { i:100\n",
      "1:0: Unexpected end of stream while parsing aggregate value.\n");
}

// -------------------------------------------------------------------
// Enum errors

TEST_F(ParseErrorTest, EofInEnum) {
  ExpectHasErrors(
    "enum TestEnum {",
    "0:15: Reached end of input in enum definition (missing '}').\n");
}

TEST_F(ParseErrorTest, EnumValueMissingNumber) {
  ExpectHasErrors(
    "enum TestEnum {\n"
    "  FOO;\n"
    "}\n",
    "1:5: Missing numeric value for enum constant.\n");
}

// -------------------------------------------------------------------
// Service errors

TEST_F(ParseErrorTest, EofInService) {
  ExpectHasErrors(
    "service TestService {",
    "0:21: Reached end of input in service definition (missing '}').\n");
}

TEST_F(ParseErrorTest, ServiceMethodPrimitiveParams) {
  ExpectHasErrors(
    "service TestService {\n"
    "  rpc Foo(int32) returns (string);\n"
    "}\n",
    "1:10: Expected message type.\n"
    "1:26: Expected message type.\n");
}


TEST_F(ParseErrorTest, EofInMethodOptions) {
  ExpectHasErrors(
    "service TestService {\n"
    "  rpc Foo(Bar) returns(Bar) {",
    "1:29: Reached end of input in method options (missing '}').\n"
    "1:29: Reached end of input in service definition (missing '}').\n");
}


TEST_F(ParseErrorTest, PrimitiveMethodInput) {
  ExpectHasErrors(
    "service TestService {\n"
    "  rpc Foo(int32) returns(Bar);\n"
    "}\n",
    "1:10: Expected message type.\n");
}


TEST_F(ParseErrorTest, MethodOptionTypeError) {
  // This used to cause an infinite loop.
  ExpectHasErrors(
    "message Baz {}\n"
    "service Foo {\n"
    "  rpc Bar(Baz) returns(Baz) { option invalid syntax; }\n"
    "}\n",
    "2:45: Expected \"=\".\n");
}


// -------------------------------------------------------------------
// Import and package errors

TEST_F(ParseErrorTest, ImportNotQuoted) {
  ExpectHasErrors(
    "import foo;\n",
    "0:7: Expected a string naming the file to import.\n");
}

TEST_F(ParseErrorTest, MultiplePackagesInFile) {
  ExpectHasErrors(
    "package foo;\n"
    "package bar;\n",
    "1:0: Multiple package definitions.\n");
}

// ===================================================================
// Test that errors detected by DescriptorPool correctly report line and
// column numbers.  We have one test for every call to RecordLocation() in
// parser.cc.

typedef ParserTest ParserValidationErrorTest;

TEST_F(ParserValidationErrorTest, PackageNameError) {
  // Create another file which defines symbol "foo".
  FileDescriptorProto other_file;
  other_file.set_name("bar.proto");
  other_file.add_message_type()->set_name("foo");
  EXPECT_TRUE(pool_.BuildFile(other_file) != NULL);

  // Now try to define it as a package.
  ExpectHasValidationErrors(
    "package foo.bar;",
    "0:8: \"foo\" is already defined (as something other than a package) "
      "in file \"bar.proto\".\n");
}

TEST_F(ParserValidationErrorTest, MessageNameError) {
  ExpectHasValidationErrors(
    "message Foo {}\n"
    "message Foo {}\n",
    "1:8: \"Foo\" is already defined.\n");
}

TEST_F(ParserValidationErrorTest, FieldNameError) {
  ExpectHasValidationErrors(
    "message Foo {\n"
    "  optional int32 bar = 1;\n"
    "  optional int32 bar = 2;\n"
    "}\n",
    "2:17: \"bar\" is already defined in \"Foo\".\n");
}

TEST_F(ParserValidationErrorTest, FieldTypeError) {
  ExpectHasValidationErrors(
    "message Foo {\n"
    "  optional Baz bar = 1;\n"
    "}\n",
    "1:11: \"Baz\" is not defined.\n");
}

TEST_F(ParserValidationErrorTest, FieldNumberError) {
  ExpectHasValidationErrors(
    "message Foo {\n"
    "  optional int32 bar = 0;\n"
    "}\n",
    "1:23: Field numbers must be positive integers.\n");
}

TEST_F(ParserValidationErrorTest, FieldExtendeeError) {
  ExpectHasValidationErrors(
    "extend Baz { optional int32 bar = 1; }\n",
    "0:7: \"Baz\" is not defined.\n");
}

TEST_F(ParserValidationErrorTest, FieldDefaultValueError) {
  ExpectHasValidationErrors(
    "enum Baz { QUX = 1; }\n"
    "message Foo {\n"
    "  optional Baz bar = 1 [default=NO_SUCH_VALUE];\n"
    "}\n",
    "2:32: Enum type \"Baz\" has no value named \"NO_SUCH_VALUE\".\n");
}

TEST_F(ParserValidationErrorTest, FileOptionNameError) {
  ExpectHasValidationErrors(
    "option foo = 5;",
    "0:7: Option \"foo\" unknown.\n");
}

TEST_F(ParserValidationErrorTest, FileOptionValueError) {
  ExpectHasValidationErrors(
    "option java_outer_classname = 5;",
    "0:30: Value must be quoted string for string option "
    "\"google.protobuf.FileOptions.java_outer_classname\".\n");
}

TEST_F(ParserValidationErrorTest, FieldOptionNameError) {
  ExpectHasValidationErrors(
    "message Foo {\n"
    "  optional bool bar = 1 [foo=1];\n"
    "}\n",
    "1:25: Option \"foo\" unknown.\n");
}

TEST_F(ParserValidationErrorTest, FieldOptionValueError) {
  ExpectHasValidationErrors(
    "message Foo {\n"
    "  optional int32 bar = 1 [ctype=1];\n"
    "}\n",
    "1:32: Value must be identifier for enum-valued option "
    "\"google.protobuf.FieldOptions.ctype\".\n");
}

TEST_F(ParserValidationErrorTest, ExtensionRangeNumberError) {
  ExpectHasValidationErrors(
    "message Foo {\n"
    "  extensions 0;\n"
    "}\n",
    "1:13: Extension numbers must be positive integers.\n");
}

TEST_F(ParserValidationErrorTest, EnumNameError) {
  ExpectHasValidationErrors(
    "enum Foo {A = 1;}\n"
    "enum Foo {B = 1;}\n",
    "1:5: \"Foo\" is already defined.\n");
}

TEST_F(ParserValidationErrorTest, EnumValueNameError) {
  ExpectHasValidationErrors(
    "enum Foo {\n"
    "  BAR = 1;\n"
    "  BAR = 1;\n"
    "}\n",
    "2:2: \"BAR\" is already defined.\n");
}

TEST_F(ParserValidationErrorTest, ServiceNameError) {
  ExpectHasValidationErrors(
    "service Foo {}\n"
    "service Foo {}\n",
    "1:8: \"Foo\" is already defined.\n");
}

TEST_F(ParserValidationErrorTest, MethodNameError) {
  ExpectHasValidationErrors(
    "message Baz {}\n"
    "service Foo {\n"
    "  rpc Bar(Baz) returns(Baz);\n"
    "  rpc Bar(Baz) returns(Baz);\n"
    "}\n",
    "3:6: \"Bar\" is already defined in \"Foo\".\n");
}


TEST_F(ParserValidationErrorTest, MethodInputTypeError) {
  ExpectHasValidationErrors(
    "message Baz {}\n"
    "service Foo {\n"
    "  rpc Bar(Qux) returns(Baz);\n"
    "}\n",
    "2:10: \"Qux\" is not defined.\n");
}


TEST_F(ParserValidationErrorTest, MethodOutputTypeError) {
  ExpectHasValidationErrors(
    "message Baz {}\n"
    "service Foo {\n"
    "  rpc Bar(Baz) returns(Qux);\n"
    "}\n",
    "2:23: \"Qux\" is not defined.\n");
}


// ===================================================================
// Test that the output from FileDescriptor::DebugString() (and all other
// descriptor types) is parseable, and results in the same Descriptor
// definitions again afoter parsing (not, however, that the order of messages
// cannot be guaranteed to be the same)

typedef ParserTest ParseDecriptorDebugTest;

class CompareDescriptorNames {
 public:
  bool operator()(const DescriptorProto* left, const DescriptorProto* right) {
    return left->name() < right->name();
  }
};

// Sorts nested DescriptorProtos of a DescriptoProto, by name.
void SortMessages(DescriptorProto *descriptor_proto) {
  int size = descriptor_proto->nested_type_size();
  // recursively sort; we can't guarantee the order of nested messages either
  for (int i = 0; i < size; ++i) {
    SortMessages(descriptor_proto->mutable_nested_type(i));
  }
  DescriptorProto **data =
    descriptor_proto->mutable_nested_type()->mutable_data();
  sort(data, data + size, CompareDescriptorNames());
}

// Sorts DescriptorProtos belonging to a FileDescriptorProto, by name.
void SortMessages(FileDescriptorProto *file_descriptor_proto) {
  int size = file_descriptor_proto->message_type_size();
  // recursively sort; we can't guarantee the order of nested messages either
  for (int i = 0; i < size; ++i) {
    SortMessages(file_descriptor_proto->mutable_message_type(i));
  }
  DescriptorProto **data =
    file_descriptor_proto->mutable_message_type()->mutable_data();
  sort(data, data + size, CompareDescriptorNames());
}

TEST_F(ParseDecriptorDebugTest, TestAllDescriptorTypes) {
  const FileDescriptor* original_file =
     protobuf_unittest::TestAllTypes::descriptor()->file();
  FileDescriptorProto expected;
  original_file->CopyTo(&expected);

  // Get the DebugString of the unittest.proto FileDecriptor, which includes
  // all other descriptor types
  string debug_string = original_file->DebugString();

  // Parse the debug string
  SetupParser(debug_string.c_str());
  FileDescriptorProto parsed;
  parser_->Parse(input_.get(), &parsed);
  EXPECT_EQ(io::Tokenizer::TYPE_END, input_->current().type);
  ASSERT_EQ("", error_collector_.text_);

  // We now have a FileDescriptorProto, but to compare with the expected we
  // need to link to a FileDecriptor, then output back to a proto. We'll
  // also need to give it the same name as the original.
  parsed.set_name("google/protobuf/unittest.proto");
  // We need the imported dependency before we can build our parsed proto
  const FileDescriptor* public_import =
      protobuf_unittest_import::PublicImportMessage::descriptor()->file();
  FileDescriptorProto public_import_proto;
  public_import->CopyTo(&public_import_proto);
  ASSERT_TRUE(pool_.BuildFile(public_import_proto) != NULL);
  const FileDescriptor* import =
       protobuf_unittest_import::ImportMessage::descriptor()->file();
  FileDescriptorProto import_proto;
  import->CopyTo(&import_proto);
  ASSERT_TRUE(pool_.BuildFile(import_proto) != NULL);
  const FileDescriptor* actual = pool_.BuildFile(parsed);
  parsed.Clear();
  actual->CopyTo(&parsed);
  ASSERT_TRUE(actual != NULL);

  // The messages might be in different orders, making them hard to compare.
  // So, sort the messages in the descriptor protos (including nested messages,
  // recursively).
  SortMessages(&expected);
  SortMessages(&parsed);

  // I really wanted to use StringDiff here for the debug output on fail,
  // but the strings are too long for it, and if I increase its max size,
  // we get a memory allocation failure :(
  EXPECT_EQ(expected.DebugString(), parsed.DebugString());
}

TEST_F(ParseDecriptorDebugTest, TestCustomOptions) {
  const FileDescriptor* original_file =
     protobuf_unittest::AggregateMessage::descriptor()->file();
  FileDescriptorProto expected;
  original_file->CopyTo(&expected);

  string debug_string = original_file->DebugString();

  // Parse the debug string
  SetupParser(debug_string.c_str());
  FileDescriptorProto parsed;
  parser_->Parse(input_.get(), &parsed);
  EXPECT_EQ(io::Tokenizer::TYPE_END, input_->current().type);
  ASSERT_EQ("", error_collector_.text_);

  // We now have a FileDescriptorProto, but to compare with the expected we
  // need to link to a FileDecriptor, then output back to a proto. We'll
  // also need to give it the same name as the original.
  parsed.set_name(original_file->name());

  // unittest_custom_options.proto depends on descriptor.proto.
  const FileDescriptor* import = FileDescriptorProto::descriptor()->file();
  FileDescriptorProto import_proto;
  import->CopyTo(&import_proto);
  ASSERT_TRUE(pool_.BuildFile(import_proto) != NULL);
  const FileDescriptor* actual = pool_.BuildFile(parsed);
  ASSERT_TRUE(actual != NULL);
  parsed.Clear();
  actual->CopyTo(&parsed);

  // The messages might be in different orders, making them hard to compare.
  // So, sort the messages in the descriptor protos (including nested messages,
  // recursively).
  SortMessages(&expected);
  SortMessages(&parsed);

  EXPECT_EQ(expected.DebugString(), parsed.DebugString());
}

// ===================================================================
// SourceCodeInfo tests.

// Follows a path -- as defined by SourceCodeInfo.Location.path -- from a
// message to a particular sub-field.
// * If the target is itself a message, sets *output_message to point at it,
//   *output_field to NULL, and *output_index to -1.
// * Otherwise, if the target is an element of a repeated field, sets
//   *output_message to the containing message, *output_field to the descriptor
//   of the field, and *output_index to the index of the element.
// * Otherwise, the target is a field (possibly a repeated field, but not any
//   one element).  Sets *output_message to the containing message,
//   *output_field to the descriptor of the field, and *output_index to -1.
// Returns true if the path was valid, false otherwise.  A gTest failure is
// recorded before returning false.
bool FollowPath(const Message& root,
                const int* path_begin, const int* path_end,
                const Message** output_message,
                const FieldDescriptor** output_field,
                int* output_index) {
  if (path_begin == path_end) {
    // Path refers to this whole message.
    *output_message = &root;
    *output_field = NULL;
    *output_index = -1;
    return true;
  }

  const Descriptor* descriptor = root.GetDescriptor();
  const Reflection* reflection = root.GetReflection();

  const FieldDescriptor* field = descriptor->FindFieldByNumber(*path_begin);

  if (field == NULL) {
    ADD_FAILURE() << descriptor->name() << " has no field number: "
                  << *path_begin;
    return false;
  }

  ++path_begin;

  if (field->is_repeated()) {
    if (path_begin == path_end) {
      // Path refers to the whole repeated field.
      *output_message = &root;
      *output_field = field;
      *output_index = -1;
      return true;
    }

    int index = *path_begin++;
    int size = reflection->FieldSize(root, field);

    if (index >= size) {
      ADD_FAILURE() << descriptor->name() << "." << field->name()
                    << " has size " << size << ", but path contained index: "
                    << index;
      return false;
    }

    if (field->cpp_type() == FieldDescriptor::CPPTYPE_MESSAGE) {
      // Descend into child message.
      const Message& child = reflection->GetRepeatedMessage(root, field, index);
      return FollowPath(child, path_begin, path_end,
                        output_message, output_field, output_index);
    } else if (path_begin == path_end) {
      // Path refers to this element.
      *output_message = &root;
      *output_field = field;
      *output_index = index;
      return true;
    } else {
      ADD_FAILURE() << descriptor->name() << "." << field->name()
                    << " is not a message; cannot descend into it.";
      return false;
    }
  } else {
    if (field->cpp_type() == FieldDescriptor::CPPTYPE_MESSAGE) {
      const Message& child = reflection->GetMessage(root, field);
      return FollowPath(child, path_begin, path_end,
                        output_message, output_field, output_index);
    } else if (path_begin == path_end) {
      // Path refers to this field.
      *output_message = &root;
      *output_field = field;
      *output_index = -1;
      return true;
    } else {
      ADD_FAILURE() << descriptor->name() << "." << field->name()
                    << " is not a message; cannot descend into it.";
      return false;
    }
  }
}

// Check if two spans are equal.
bool CompareSpans(const RepeatedField<int>& span1,
                  const RepeatedField<int>& span2) {
  if (span1.size() != span2.size()) return false;
  for (int i = 0; i < span1.size(); i++) {
    if (span1.Get(i) != span2.Get(i)) return false;
  }
  return true;
}

// Test fixture for source info tests, which check that source locations are
// recorded correctly in FileDescriptorProto.source_code_info.location.
class SourceInfoTest : public ParserTest {
 protected:
  // The parsed file (initialized by Parse()).
  FileDescriptorProto file_;

  // Parse the given text as a .proto file and populate the spans_ map with
  // all the source location spans in its SourceCodeInfo table.
  bool Parse(const char* text) {
    ExtractMarkers(text);
    SetupParser(text_without_markers_.c_str());
    if (!parser_->Parse(input_.get(), &file_)) {
      return false;
    }

    const SourceCodeInfo& source_info = file_.source_code_info();
    for (int i = 0; i < source_info.location_size(); i++) {
      const SourceCodeInfo::Location& location = source_info.location(i);
      const Message* descriptor_proto = NULL;
      const FieldDescriptor* field = NULL;
      int index = 0;
      if (!FollowPath(file_, location.path().begin(), location.path().end(),
                      &descriptor_proto, &field, &index)) {
        return false;
      }

      spans_.insert(make_pair(SpanKey(*descriptor_proto, field, index),
                              &location));
    }

    return true;
  }

  virtual void TearDown() {
    EXPECT_TRUE(spans_.empty())
        << "Forgot to call HasSpan() for:\n"
        << spans_.begin()->second->DebugString();
  }

  // -----------------------------------------------------------------
  // HasSpan() checks that the span of source code delimited by the given
  // tags (comments) correspond via the SourceCodeInfo table to the given
  // part of the FileDescriptorProto.  (If unclear, look at the actual tests;
  // it should quickly become obvious.)

  bool HasSpan(char start_marker, char end_marker,
               const Message& descriptor_proto) {
    return HasSpanWithComment(
        start_marker, end_marker, descriptor_proto, NULL, -1, NULL, NULL);
  }

  bool HasSpanWithComment(char start_marker, char end_marker,
                          const Message& descriptor_proto,
                          const char* expected_leading_comments,
                          const char* expected_trailing_comments) {
    return HasSpanWithComment(
        start_marker, end_marker, descriptor_proto, NULL, -1,
        expected_leading_comments, expected_trailing_comments);
  }

  bool HasSpan(char start_marker, char end_marker,
               const Message& descriptor_proto, const string& field_name) {
    return HasSpan(start_marker, end_marker, descriptor_proto, field_name, -1);
  }

  bool HasSpan(char start_marker, char end_marker,
               const Message& descriptor_proto, const string& field_name,
               int index) {
    return HasSpan(start_marker, end_marker, descriptor_proto,
                   field_name, index, NULL, NULL);
  }

  bool HasSpan(char start_marker, char end_marker,
               const Message& descriptor_proto,
               const string& field_name, int index,
               const char* expected_leading_comments,
               const char* expected_trailing_comments) {
    const FieldDescriptor* field =
        descriptor_proto.GetDescriptor()->FindFieldByName(field_name);
    if (field == NULL) {
      ADD_FAILURE() << descriptor_proto.GetDescriptor()->name()
                    << " has no such field: " << field_name;
      return false;
    }

    return HasSpanWithComment(
        start_marker, end_marker, descriptor_proto, field, index,
        expected_leading_comments, expected_trailing_comments);
  }

  bool HasSpan(const Message& descriptor_proto) {
    return HasSpanWithComment(
        '\0', '\0', descriptor_proto, NULL, -1, NULL, NULL);
  }

  bool HasSpan(const Message& descriptor_proto, const string& field_name) {
    return HasSpan('\0', '\0', descriptor_proto, field_name, -1);
  }

  bool HasSpan(const Message& descriptor_proto, const string& field_name,
               int index) {
    return HasSpan('\0', '\0', descriptor_proto, field_name, index);
  }

  bool HasSpanWithComment(char start_marker, char end_marker,
                          const Message& descriptor_proto,
                          const FieldDescriptor* field, int index,
                          const char* expected_leading_comments,
                          const char* expected_trailing_comments) {
    pair<SpanMap::iterator, SpanMap::iterator> range =
        spans_.equal_range(SpanKey(descriptor_proto, field, index));

    if (start_marker == '\0') {
      if (range.first == range.second) {
        return false;
      } else {
        spans_.erase(range.first);
        return true;
      }
    } else {
      pair<int, int> start_pos = FindOrDie(markers_, start_marker);
      pair<int, int> end_pos = FindOrDie(markers_, end_marker);

      RepeatedField<int> expected_span;
      expected_span.Add(start_pos.first);
      expected_span.Add(start_pos.second);
      if (end_pos.first != start_pos.first) {
        expected_span.Add(end_pos.first);
      }
      expected_span.Add(end_pos.second);

      for (SpanMap::iterator iter = range.first; iter != range.second; ++iter) {
        if (CompareSpans(expected_span, iter->second->span())) {
          if (expected_leading_comments == NULL) {
            EXPECT_FALSE(iter->second->has_leading_comments());
          } else {
            EXPECT_TRUE(iter->second->has_leading_comments());
            EXPECT_EQ(expected_leading_comments,
                      iter->second->leading_comments());
          }
          if (expected_trailing_comments == NULL) {
            EXPECT_FALSE(iter->second->has_trailing_comments());
          } else {
            EXPECT_TRUE(iter->second->has_trailing_comments());
            EXPECT_EQ(expected_trailing_comments,
                      iter->second->trailing_comments());
          }

          spans_.erase(iter);
          return true;
        }
      }

      return false;
    }
  }

 private:
  struct SpanKey {
    const Message* descriptor_proto;
    const FieldDescriptor* field;
    int index;

    inline SpanKey() {}
    inline SpanKey(const Message& descriptor_proto_param,
                   const FieldDescriptor* field_param,
                   int index_param)
        : descriptor_proto(&descriptor_proto_param), field(field_param),
          index(index_param) {}

    inline bool operator<(const SpanKey& other) const {
      if (descriptor_proto < other.descriptor_proto) return true;
      if (descriptor_proto > other.descriptor_proto) return false;
      if (field < other.field) return true;
      if (field > other.field) return false;
      return index < other.index;
    }
  };

  typedef multimap<SpanKey, const SourceCodeInfo::Location*> SpanMap;
  SpanMap spans_;
  map<char, pair<int, int> > markers_;
  string text_without_markers_;

  void ExtractMarkers(const char* text) {
    markers_.clear();
    text_without_markers_.clear();
    int line = 0;
    int column = 0;
    while (*text != '\0') {
      if (*text == '$') {
        ++text;
        GOOGLE_CHECK_NE('\0', *text);
        if (*text == '$') {
          text_without_markers_ += '$';
          ++column;
        } else {
          markers_[*text] = make_pair(line, column);
          ++text;
          GOOGLE_CHECK_EQ('$', *text);
        }
      } else if (*text == '\n') {
        ++line;
        column = 0;
        text_without_markers_ += *text;
      } else {
        text_without_markers_ += *text;
        ++column;
      }
      ++text;
    }
  }
};

TEST_F(SourceInfoTest, BasicFileDecls) {
  EXPECT_TRUE(Parse(
      "$a$syntax = \"proto2\";\n"
      "package $b$foo.bar$c$;\n"
      "import $d$\"baz.proto\"$e$;\n"
      "import $f$\"qux.proto\"$g$;$h$\n"
      "\n"
      "// comment ignored\n"));

  EXPECT_TRUE(HasSpan('a', 'h', file_));
  EXPECT_TRUE(HasSpan('b', 'c', file_, "package"));
  EXPECT_TRUE(HasSpan('d', 'e', file_, "dependency", 0));
  EXPECT_TRUE(HasSpan('f', 'g', file_, "dependency", 1));
}

TEST_F(SourceInfoTest, Messages) {
  EXPECT_TRUE(Parse(
      "$a$message $b$Foo$c$ {}$d$\n"
      "$e$message $f$Bar$g$ {}$h$\n"));

  EXPECT_TRUE(HasSpan('a', 'd', file_.message_type(0)));
  EXPECT_TRUE(HasSpan('b', 'c', file_.message_type(0), "name"));
  EXPECT_TRUE(HasSpan('e', 'h', file_.message_type(1)));
  EXPECT_TRUE(HasSpan('f', 'g', file_.message_type(1), "name"));

  // Ignore these.
  EXPECT_TRUE(HasSpan(file_));
}

TEST_F(SourceInfoTest, Fields) {
  EXPECT_TRUE(Parse(
      "message Foo {\n"
      "  $a$optional$b$ $c$int32$d$ $e$bar$f$ = $g$1$h$;$i$\n"
      "  $j$repeated$k$ $l$X.Y$m$ $n$baz$o$ = $p$2$q$;$r$\n"
      "}\n"));

  const FieldDescriptorProto& field1 = file_.message_type(0).field(0);
  const FieldDescriptorProto& field2 = file_.message_type(0).field(1);

  EXPECT_TRUE(HasSpan('a', 'i', field1));
  EXPECT_TRUE(HasSpan('a', 'b', field1, "label"));
  EXPECT_TRUE(HasSpan('c', 'd', field1, "type"));
  EXPECT_TRUE(HasSpan('e', 'f', field1, "name"));
  EXPECT_TRUE(HasSpan('g', 'h', field1, "number"));

  EXPECT_TRUE(HasSpan('j', 'r', field2));
  EXPECT_TRUE(HasSpan('j', 'k', field2, "label"));
  EXPECT_TRUE(HasSpan('l', 'm', field2, "type_name"));
  EXPECT_TRUE(HasSpan('n', 'o', field2, "name"));
  EXPECT_TRUE(HasSpan('p', 'q', field2, "number"));

  // Ignore these.
  EXPECT_TRUE(HasSpan(file_));
  EXPECT_TRUE(HasSpan(file_.message_type(0)));
  EXPECT_TRUE(HasSpan(file_.message_type(0), "name"));
}

TEST_F(SourceInfoTest, Extensions) {
  EXPECT_TRUE(Parse(
      "$a$extend $b$Foo$c$ {\n"
      "  $d$optional$e$ int32 bar = 1;$f$\n"
      "  $g$repeated$h$ X.Y baz = 2;$i$\n"
      "}$j$\n"
      "$k$extend $l$Bar$m$ {\n"
      "  $n$optional int32 qux = 1;$o$\n"
      "}$p$\n"));

  const FieldDescriptorProto& field1 = file_.extension(0);
  const FieldDescriptorProto& field2 = file_.extension(1);
  const FieldDescriptorProto& field3 = file_.extension(2);

  EXPECT_TRUE(HasSpan('a', 'j', file_, "extension"));
  EXPECT_TRUE(HasSpan('k', 'p', file_, "extension"));

  EXPECT_TRUE(HasSpan('d', 'f', field1));
  EXPECT_TRUE(HasSpan('d', 'e', field1, "label"));
  EXPECT_TRUE(HasSpan('b', 'c', field1, "extendee"));

  EXPECT_TRUE(HasSpan('g', 'i', field2));
  EXPECT_TRUE(HasSpan('g', 'h', field2, "label"));
  EXPECT_TRUE(HasSpan('b', 'c', field2, "extendee"));

  EXPECT_TRUE(HasSpan('n', 'o', field3));
  EXPECT_TRUE(HasSpan('l', 'm', field3, "extendee"));

  // Ignore these.
  EXPECT_TRUE(HasSpan(file_));
  EXPECT_TRUE(HasSpan(field1, "type"));
  EXPECT_TRUE(HasSpan(field1, "name"));
  EXPECT_TRUE(HasSpan(field1, "number"));
  EXPECT_TRUE(HasSpan(field2, "type_name"));
  EXPECT_TRUE(HasSpan(field2, "name"));
  EXPECT_TRUE(HasSpan(field2, "number"));
  EXPECT_TRUE(HasSpan(field3, "label"));
  EXPECT_TRUE(HasSpan(field3, "type"));
  EXPECT_TRUE(HasSpan(field3, "name"));
  EXPECT_TRUE(HasSpan(field3, "number"));
}

TEST_F(SourceInfoTest, NestedExtensions) {
  EXPECT_TRUE(Parse(
      "message Message {\n"
      "  $a$extend $b$Foo$c$ {\n"
      "    $d$optional$e$ int32 bar = 1;$f$\n"
      "    $g$repeated$h$ X.Y baz = 2;$i$\n"
      "  }$j$\n"
      "  $k$extend $l$Bar$m$ {\n"
      "    $n$optional int32 qux = 1;$o$\n"
      "  }$p$\n"
      "}\n"));

  const FieldDescriptorProto& field1 = file_.message_type(0).extension(0);
  const FieldDescriptorProto& field2 = file_.message_type(0).extension(1);
  const FieldDescriptorProto& field3 = file_.message_type(0).extension(2);

  EXPECT_TRUE(HasSpan('a', 'j', file_.message_type(0), "extension"));
  EXPECT_TRUE(HasSpan('k', 'p', file_.message_type(0), "extension"));

  EXPECT_TRUE(HasSpan('d', 'f', field1));
  EXPECT_TRUE(HasSpan('d', 'e', field1, "label"));
  EXPECT_TRUE(HasSpan('b', 'c', field1, "extendee"));

  EXPECT_TRUE(HasSpan('g', 'i', field2));
  EXPECT_TRUE(HasSpan('g', 'h', field2, "label"));
  EXPECT_TRUE(HasSpan('b', 'c', field2, "extendee"));

  EXPECT_TRUE(HasSpan('n', 'o', field3));
  EXPECT_TRUE(HasSpan('l', 'm', field3, "extendee"));

  // Ignore these.
  EXPECT_TRUE(HasSpan(file_));
  EXPECT_TRUE(HasSpan(file_.message_type(0)));
  EXPECT_TRUE(HasSpan(file_.message_type(0), "name"));
  EXPECT_TRUE(HasSpan(field1, "type"));
  EXPECT_TRUE(HasSpan(field1, "name"));
  EXPECT_TRUE(HasSpan(field1, "number"));
  EXPECT_TRUE(HasSpan(field2, "type_name"));
  EXPECT_TRUE(HasSpan(field2, "name"));
  EXPECT_TRUE(HasSpan(field2, "number"));
  EXPECT_TRUE(HasSpan(field3, "label"));
  EXPECT_TRUE(HasSpan(field3, "type"));
  EXPECT_TRUE(HasSpan(field3, "name"));
  EXPECT_TRUE(HasSpan(field3, "number"));
}

TEST_F(SourceInfoTest, ExtensionRanges) {
  EXPECT_TRUE(Parse(
      "message Message {\n"
      "  $a$extensions $b$1$c$ to $d$4$e$, $f$6$g$;$h$\n"
      "  $i$extensions $j$8$k$ to $l$max$m$;$n$\n"
      "}\n"));

  const DescriptorProto::ExtensionRange& range1 =
      file_.message_type(0).extension_range(0);
  const DescriptorProto::ExtensionRange& range2 =
      file_.message_type(0).extension_range(1);
  const DescriptorProto::ExtensionRange& range3 =
      file_.message_type(0).extension_range(2);

  EXPECT_TRUE(HasSpan('a', 'h', file_.message_type(0), "extension_range"));
  EXPECT_TRUE(HasSpan('i', 'n', file_.message_type(0), "extension_range"));

  EXPECT_TRUE(HasSpan('b', 'e', range1));
  EXPECT_TRUE(HasSpan('b', 'c', range1, "start"));
  EXPECT_TRUE(HasSpan('d', 'e', range1, "end"));

  EXPECT_TRUE(HasSpan('f', 'g', range2));
  EXPECT_TRUE(HasSpan('f', 'g', range2, "start"));
  EXPECT_TRUE(HasSpan('f', 'g', range2, "end"));

  EXPECT_TRUE(HasSpan('j', 'm', range3));
  EXPECT_TRUE(HasSpan('j', 'k', range3, "start"));
  EXPECT_TRUE(HasSpan('l', 'm', range3, "end"));

  // Ignore these.
  EXPECT_TRUE(HasSpan(file_));
  EXPECT_TRUE(HasSpan(file_.message_type(0)));
  EXPECT_TRUE(HasSpan(file_.message_type(0), "name"));
}

TEST_F(SourceInfoTest, NestedMessages) {
  EXPECT_TRUE(Parse(
      "message Foo {\n"
      "  $a$message $b$Bar$c$ {\n"
      "    $d$message $e$Baz$f$ {}$g$\n"
      "  }$h$\n"
      "  $i$message $j$Qux$k$ {}$l$\n"
      "}\n"));

  const DescriptorProto& bar = file_.message_type(0).nested_type(0);
  const DescriptorProto& baz = bar.nested_type(0);
  const DescriptorProto& qux = file_.message_type(0).nested_type(1);

  EXPECT_TRUE(HasSpan('a', 'h', bar));
  EXPECT_TRUE(HasSpan('b', 'c', bar, "name"));
  EXPECT_TRUE(HasSpan('d', 'g', baz));
  EXPECT_TRUE(HasSpan('e', 'f', baz, "name"));
  EXPECT_TRUE(HasSpan('i', 'l', qux));
  EXPECT_TRUE(HasSpan('j', 'k', qux, "name"));

  // Ignore these.
  EXPECT_TRUE(HasSpan(file_));
  EXPECT_TRUE(HasSpan(file_.message_type(0)));
  EXPECT_TRUE(HasSpan(file_.message_type(0), "name"));
}

TEST_F(SourceInfoTest, Groups) {
  EXPECT_TRUE(Parse(
      "message Foo {\n"
      "  message Bar {}\n"
      "  $a$optional$b$ $c$group$d$ $e$Baz$f$ = $g$1$h$ {\n"
      "    $i$message Qux {}$j$\n"
      "  }$k$\n"
      "}\n"));

  const DescriptorProto& bar = file_.message_type(0).nested_type(0);
  const DescriptorProto& baz = file_.message_type(0).nested_type(1);
  const DescriptorProto& qux = baz.nested_type(0);
  const FieldDescriptorProto& field = file_.message_type(0).field(0);

  EXPECT_TRUE(HasSpan('a', 'k', field));
  EXPECT_TRUE(HasSpan('a', 'b', field, "label"));
  EXPECT_TRUE(HasSpan('c', 'd', field, "type"));
  EXPECT_TRUE(HasSpan('e', 'f', field, "name"));
  EXPECT_TRUE(HasSpan('e', 'f', field, "type_name"));
  EXPECT_TRUE(HasSpan('g', 'h', field, "number"));

  EXPECT_TRUE(HasSpan('a', 'k', baz));
  EXPECT_TRUE(HasSpan('e', 'f', baz, "name"));
  EXPECT_TRUE(HasSpan('i', 'j', qux));

  // Ignore these.
  EXPECT_TRUE(HasSpan(file_));
  EXPECT_TRUE(HasSpan(file_.message_type(0)));
  EXPECT_TRUE(HasSpan(file_.message_type(0), "name"));
  EXPECT_TRUE(HasSpan(bar));
  EXPECT_TRUE(HasSpan(bar, "name"));
  EXPECT_TRUE(HasSpan(qux, "name"));
}

TEST_F(SourceInfoTest, Enums) {
  EXPECT_TRUE(Parse(
      "$a$enum $b$Foo$c$ {}$d$\n"
      "$e$enum $f$Bar$g$ {}$h$\n"));

  EXPECT_TRUE(HasSpan('a', 'd', file_.enum_type(0)));
  EXPECT_TRUE(HasSpan('b', 'c', file_.enum_type(0), "name"));
  EXPECT_TRUE(HasSpan('e', 'h', file_.enum_type(1)));
  EXPECT_TRUE(HasSpan('f', 'g', file_.enum_type(1), "name"));

  // Ignore these.
  EXPECT_TRUE(HasSpan(file_));
}

TEST_F(SourceInfoTest, EnumValues) {
  EXPECT_TRUE(Parse(
      "enum Foo {\n"
      "  $a$BAR$b$ = $c$1$d$;$e$\n"
      "  $f$BAZ$g$ = $h$2$i$;$j$\n"
      "}"));

  const EnumValueDescriptorProto& bar = file_.enum_type(0).value(0);
  const EnumValueDescriptorProto& baz = file_.enum_type(0).value(1);

  EXPECT_TRUE(HasSpan('a', 'e', bar));
  EXPECT_TRUE(HasSpan('a', 'b', bar, "name"));
  EXPECT_TRUE(HasSpan('c', 'd', bar, "number"));
  EXPECT_TRUE(HasSpan('f', 'j', baz));
  EXPECT_TRUE(HasSpan('f', 'g', baz, "name"));
  EXPECT_TRUE(HasSpan('h', 'i', baz, "number"));

  // Ignore these.
  EXPECT_TRUE(HasSpan(file_));
  EXPECT_TRUE(HasSpan(file_.enum_type(0)));
  EXPECT_TRUE(HasSpan(file_.enum_type(0), "name"));
}

TEST_F(SourceInfoTest, NestedEnums) {
  EXPECT_TRUE(Parse(
      "message Foo {\n"
      "  $a$enum $b$Bar$c$ {}$d$\n"
      "  $e$enum $f$Baz$g$ {}$h$\n"
      "}\n"));

  const EnumDescriptorProto& bar = file_.message_type(0).enum_type(0);
  const EnumDescriptorProto& baz = file_.message_type(0).enum_type(1);

  EXPECT_TRUE(HasSpan('a', 'd', bar));
  EXPECT_TRUE(HasSpan('b', 'c', bar, "name"));
  EXPECT_TRUE(HasSpan('e', 'h', baz));
  EXPECT_TRUE(HasSpan('f', 'g', baz, "name"));

  // Ignore these.
  EXPECT_TRUE(HasSpan(file_));
  EXPECT_TRUE(HasSpan(file_.message_type(0)));
  EXPECT_TRUE(HasSpan(file_.message_type(0), "name"));
}

TEST_F(SourceInfoTest, Services) {
  EXPECT_TRUE(Parse(
      "$a$service $b$Foo$c$ {}$d$\n"
      "$e$service $f$Bar$g$ {}$h$\n"));

  EXPECT_TRUE(HasSpan('a', 'd', file_.service(0)));
  EXPECT_TRUE(HasSpan('b', 'c', file_.service(0), "name"));
  EXPECT_TRUE(HasSpan('e', 'h', file_.service(1)));
  EXPECT_TRUE(HasSpan('f', 'g', file_.service(1), "name"));

  // Ignore these.
  EXPECT_TRUE(HasSpan(file_));
}

TEST_F(SourceInfoTest, MethodsAndStreams) {
  EXPECT_TRUE(Parse(
      "service Foo {\n"
      "  $a$rpc $b$Bar$c$($d$X$e$) returns($f$Y$g$);$h$"
      "  $i$rpc $j$Baz$k$($l$Z$m$) returns($n$W$o$);$p$"
      "}"));

  const MethodDescriptorProto& bar = file_.service(0).method(0);
  const MethodDescriptorProto& baz = file_.service(0).method(1);

  EXPECT_TRUE(HasSpan('a', 'h', bar));
  EXPECT_TRUE(HasSpan('b', 'c', bar, "name"));
  EXPECT_TRUE(HasSpan('d', 'e', bar, "input_type"));
  EXPECT_TRUE(HasSpan('f', 'g', bar, "output_type"));

  EXPECT_TRUE(HasSpan('i', 'p', baz));
  EXPECT_TRUE(HasSpan('j', 'k', baz, "name"));
  EXPECT_TRUE(HasSpan('l', 'm', baz, "input_type"));
  EXPECT_TRUE(HasSpan('n', 'o', baz, "output_type"));

  // Ignore these.
  EXPECT_TRUE(HasSpan(file_));
  EXPECT_TRUE(HasSpan(file_.service(0)));
  EXPECT_TRUE(HasSpan(file_.service(0), "name"));
}

TEST_F(SourceInfoTest, Options) {
  EXPECT_TRUE(Parse(
      "$a$option $b$foo$c$.$d$($e$bar.baz$f$)$g$ = "
          "$h$123$i$;$j$\n"
      "$k$option qux = $l$-123$m$;$n$\n"
      "$o$option corge = $p$abc$q$;$r$\n"
      "$s$option grault = $t$'blah'$u$;$v$\n"
      "$w$option garply = $x${ yadda yadda }$y$;$z$\n"
      "$0$option waldo = $1$123.0$2$;$3$\n"
  ));

  const UninterpretedOption& option1 = file_.options().uninterpreted_option(0);
  const UninterpretedOption& option2 = file_.options().uninterpreted_option(1);
  const UninterpretedOption& option3 = file_.options().uninterpreted_option(2);
  const UninterpretedOption& option4 = file_.options().uninterpreted_option(3);
  const UninterpretedOption& option5 = file_.options().uninterpreted_option(4);
  const UninterpretedOption& option6 = file_.options().uninterpreted_option(5);

  EXPECT_TRUE(HasSpan('a', 'j', file_.options()));
  EXPECT_TRUE(HasSpan('a', 'j', option1));
  EXPECT_TRUE(HasSpan('b', 'g', option1, "name"));
  EXPECT_TRUE(HasSpan('b', 'c', option1.name(0)));
  EXPECT_TRUE(HasSpan('b', 'c', option1.name(0), "name_part"));
  EXPECT_TRUE(HasSpan('d', 'g', option1.name(1)));
  EXPECT_TRUE(HasSpan('e', 'f', option1.name(1), "name_part"));
  EXPECT_TRUE(HasSpan('h', 'i', option1, "positive_int_value"));

  EXPECT_TRUE(HasSpan('k', 'n', file_.options()));
  EXPECT_TRUE(HasSpan('l', 'm', option2, "negative_int_value"));

  EXPECT_TRUE(HasSpan('o', 'r', file_.options()));
  EXPECT_TRUE(HasSpan('p', 'q', option3, "identifier_value"));

  EXPECT_TRUE(HasSpan('s', 'v', file_.options()));
  EXPECT_TRUE(HasSpan('t', 'u', option4, "string_value"));

  EXPECT_TRUE(HasSpan('w', 'z', file_.options()));
  EXPECT_TRUE(HasSpan('x', 'y', option5, "aggregate_value"));

  EXPECT_TRUE(HasSpan('0', '3', file_.options()));
  EXPECT_TRUE(HasSpan('1', '2', option6, "double_value"));

  // Ignore these.
  EXPECT_TRUE(HasSpan(file_));
  EXPECT_TRUE(HasSpan(option2));
  EXPECT_TRUE(HasSpan(option3));
  EXPECT_TRUE(HasSpan(option4));
  EXPECT_TRUE(HasSpan(option5));
  EXPECT_TRUE(HasSpan(option6));
  EXPECT_TRUE(HasSpan(option2, "name"));
  EXPECT_TRUE(HasSpan(option3, "name"));
  EXPECT_TRUE(HasSpan(option4, "name"));
  EXPECT_TRUE(HasSpan(option5, "name"));
  EXPECT_TRUE(HasSpan(option6, "name"));
  EXPECT_TRUE(HasSpan(option2.name(0)));
  EXPECT_TRUE(HasSpan(option3.name(0)));
  EXPECT_TRUE(HasSpan(option4.name(0)));
  EXPECT_TRUE(HasSpan(option5.name(0)));
  EXPECT_TRUE(HasSpan(option6.name(0)));
  EXPECT_TRUE(HasSpan(option2.name(0), "name_part"));
  EXPECT_TRUE(HasSpan(option3.name(0), "name_part"));
  EXPECT_TRUE(HasSpan(option4.name(0), "name_part"));
  EXPECT_TRUE(HasSpan(option5.name(0), "name_part"));
  EXPECT_TRUE(HasSpan(option6.name(0), "name_part"));
}

TEST_F(SourceInfoTest, ScopedOptions) {
  EXPECT_TRUE(Parse(
    "message Foo {\n"
    "  $a$option mopt = 1;$b$\n"
    "}\n"
    "enum Bar {\n"
    "  $c$option eopt = 1;$d$\n"
    "}\n"
    "service Baz {\n"
    "  $e$option sopt = 1;$f$\n"
    "  rpc M(X) returns(Y) {\n"
    "    $g$option mopt = 1;$h$\n"
    "  }\n"
    "}\n"));

  EXPECT_TRUE(HasSpan('a', 'b', file_.message_type(0).options()));
  EXPECT_TRUE(HasSpan('c', 'd', file_.enum_type(0).options()));
  EXPECT_TRUE(HasSpan('e', 'f', file_.service(0).options()));
  EXPECT_TRUE(HasSpan('g', 'h', file_.service(0).method(0).options()));

  // Ignore these.
  EXPECT_TRUE(HasSpan(file_));
  EXPECT_TRUE(HasSpan(file_.message_type(0)));
  EXPECT_TRUE(HasSpan(file_.message_type(0), "name"));
  EXPECT_TRUE(HasSpan(file_.message_type(0).options()
                      .uninterpreted_option(0)));
  EXPECT_TRUE(HasSpan(file_.message_type(0).options()
                      .uninterpreted_option(0), "name"));
  EXPECT_TRUE(HasSpan(file_.message_type(0).options()
                      .uninterpreted_option(0).name(0)));
  EXPECT_TRUE(HasSpan(file_.message_type(0).options()
                      .uninterpreted_option(0).name(0), "name_part"));
  EXPECT_TRUE(HasSpan(file_.message_type(0).options()
                      .uninterpreted_option(0), "positive_int_value"));
  EXPECT_TRUE(HasSpan(file_.enum_type(0)));
  EXPECT_TRUE(HasSpan(file_.enum_type(0), "name"));
  EXPECT_TRUE(HasSpan(file_.enum_type(0).options()
                      .uninterpreted_option(0)));
  EXPECT_TRUE(HasSpan(file_.enum_type(0).options()
                      .uninterpreted_option(0), "name"));
  EXPECT_TRUE(HasSpan(file_.enum_type(0).options()
                      .uninterpreted_option(0).name(0)));
  EXPECT_TRUE(HasSpan(file_.enum_type(0).options()
                      .uninterpreted_option(0).name(0), "name_part"));
  EXPECT_TRUE(HasSpan(file_.enum_type(0).options()
                      .uninterpreted_option(0), "positive_int_value"));
  EXPECT_TRUE(HasSpan(file_.service(0)));
  EXPECT_TRUE(HasSpan(file_.service(0), "name"));
  EXPECT_TRUE(HasSpan(file_.service(0).method(0)));
  EXPECT_TRUE(HasSpan(file_.service(0).options()
                      .uninterpreted_option(0)));
  EXPECT_TRUE(HasSpan(file_.service(0).options()
                      .uninterpreted_option(0), "name"));
  EXPECT_TRUE(HasSpan(file_.service(0).options()
                      .uninterpreted_option(0).name(0)));
  EXPECT_TRUE(HasSpan(file_.service(0).options()
                      .uninterpreted_option(0).name(0), "name_part"));
  EXPECT_TRUE(HasSpan(file_.service(0).options()
                      .uninterpreted_option(0), "positive_int_value"));
  EXPECT_TRUE(HasSpan(file_.service(0).method(0), "name"));
  EXPECT_TRUE(HasSpan(file_.service(0).method(0), "input_type"));
  EXPECT_TRUE(HasSpan(file_.service(0).method(0), "output_type"));
  EXPECT_TRUE(HasSpan(file_.service(0).method(0).options()
                      .uninterpreted_option(0)));
  EXPECT_TRUE(HasSpan(file_.service(0).method(0).options()
                      .uninterpreted_option(0), "name"));
  EXPECT_TRUE(HasSpan(file_.service(0).method(0).options()
                      .uninterpreted_option(0).name(0)));
  EXPECT_TRUE(HasSpan(file_.service(0).method(0).options()
                      .uninterpreted_option(0).name(0), "name_part"));
  EXPECT_TRUE(HasSpan(file_.service(0).method(0).options()
                      .uninterpreted_option(0), "positive_int_value"));
}

TEST_F(SourceInfoTest, FieldOptions) {
  // The actual "name = value" pairs are parsed by the same code as for
  // top-level options so we won't re-test that -- just make sure that the
  // syntax used for field options is understood.
  EXPECT_TRUE(Parse(
      "message Foo {"
      "  optional int32 bar = 1 "
          "$a$[default=$b$123$c$,$d$opt1=123$e$,"
          "$f$opt2='hi'$g$]$h$;"
      "}\n"
  ));

  const FieldDescriptorProto& field = file_.message_type(0).field(0);
  const UninterpretedOption& option1 = field.options().uninterpreted_option(0);
  const UninterpretedOption& option2 = field.options().uninterpreted_option(1);

  EXPECT_TRUE(HasSpan('a', 'h', field.options()));
  EXPECT_TRUE(HasSpan('b', 'c', field, "default_value"));
  EXPECT_TRUE(HasSpan('d', 'e', option1));
  EXPECT_TRUE(HasSpan('f', 'g', option2));

  // Ignore these.
  EXPECT_TRUE(HasSpan(file_));
  EXPECT_TRUE(HasSpan(file_.message_type(0)));
  EXPECT_TRUE(HasSpan(file_.message_type(0), "name"));
  EXPECT_TRUE(HasSpan(field));
  EXPECT_TRUE(HasSpan(field, "label"));
  EXPECT_TRUE(HasSpan(field, "type"));
  EXPECT_TRUE(HasSpan(field, "name"));
  EXPECT_TRUE(HasSpan(field, "number"));
  EXPECT_TRUE(HasSpan(option1, "name"));
  EXPECT_TRUE(HasSpan(option2, "name"));
  EXPECT_TRUE(HasSpan(option1.name(0)));
  EXPECT_TRUE(HasSpan(option2.name(0)));
  EXPECT_TRUE(HasSpan(option1.name(0), "name_part"));
  EXPECT_TRUE(HasSpan(option2.name(0), "name_part"));
  EXPECT_TRUE(HasSpan(option1, "positive_int_value"));
  EXPECT_TRUE(HasSpan(option2, "string_value"));
}

TEST_F(SourceInfoTest, EnumValueOptions) {
  // The actual "name = value" pairs are parsed by the same code as for
  // top-level options so we won't re-test that -- just make sure that the
  // syntax used for enum options is understood.
  EXPECT_TRUE(Parse(
      "enum Foo {"
      "  BAR = 1 $a$[$b$opt1=123$c$,$d$opt2='hi'$e$]$f$;"
      "}\n"
  ));

  const EnumValueDescriptorProto& value = file_.enum_type(0).value(0);
  const UninterpretedOption& option1 = value.options().uninterpreted_option(0);
  const UninterpretedOption& option2 = value.options().uninterpreted_option(1);

  EXPECT_TRUE(HasSpan('a', 'f', value.options()));
  EXPECT_TRUE(HasSpan('b', 'c', option1));
  EXPECT_TRUE(HasSpan('d', 'e', option2));

  // Ignore these.
  EXPECT_TRUE(HasSpan(file_));
  EXPECT_TRUE(HasSpan(file_.enum_type(0)));
  EXPECT_TRUE(HasSpan(file_.enum_type(0), "name"));
  EXPECT_TRUE(HasSpan(value));
  EXPECT_TRUE(HasSpan(value, "name"));
  EXPECT_TRUE(HasSpan(value, "number"));
  EXPECT_TRUE(HasSpan(option1, "name"));
  EXPECT_TRUE(HasSpan(option2, "name"));
  EXPECT_TRUE(HasSpan(option1.name(0)));
  EXPECT_TRUE(HasSpan(option2.name(0)));
  EXPECT_TRUE(HasSpan(option1.name(0), "name_part"));
  EXPECT_TRUE(HasSpan(option2.name(0), "name_part"));
  EXPECT_TRUE(HasSpan(option1, "positive_int_value"));
  EXPECT_TRUE(HasSpan(option2, "string_value"));
}

TEST_F(SourceInfoTest, DocComments) {
  EXPECT_TRUE(Parse(
      "// Foo leading\n"
      "// line 2\n"
      "$a$message Foo {\n"
      "  // Foo trailing\n"
      "  // line 2\n"
      "\n"
      "  // ignored\n"
      "\n"
      "  // bar leading\n"
      "  $b$optional int32 bar = 1;$c$\n"
      "  // bar trailing\n"
      "}$d$\n"
      "// ignored\n"
  ));

  const DescriptorProto& foo = file_.message_type(0);
  const FieldDescriptorProto& bar = foo.field(0);

  EXPECT_TRUE(HasSpanWithComment('a', 'd', foo,
      " Foo leading\n line 2\n",
      " Foo trailing\n line 2\n"));
  EXPECT_TRUE(HasSpanWithComment('b', 'c', bar,
      " bar leading\n",
      " bar trailing\n"));

  // Ignore these.
  EXPECT_TRUE(HasSpan(file_));
  EXPECT_TRUE(HasSpan(foo, "name"));
  EXPECT_TRUE(HasSpan(bar, "label"));
  EXPECT_TRUE(HasSpan(bar, "type"));
  EXPECT_TRUE(HasSpan(bar, "name"));
  EXPECT_TRUE(HasSpan(bar, "number"));
}

TEST_F(SourceInfoTest, DocComments2) {
  EXPECT_TRUE(Parse(
      "// ignored\n"
      "syntax = \"proto2\";\n"
      "// Foo leading\n"
      "// line 2\n"
      "$a$message Foo {\n"
      "  /* Foo trailing\n"
      "   * line 2 */\n"
      "  // ignored\n"
      "  /* bar leading\n"
      "   */"
      "  $b$optional int32 bar = 1;$c$  // bar trailing\n"
      "  // ignored\n"
      "}$d$\n"
      "// ignored\n"
      "\n"
      "// option leading\n"
      "$e$option baz = 123;$f$\n"
      "// option trailing\n"
  ));

  const DescriptorProto& foo = file_.message_type(0);
  const FieldDescriptorProto& bar = foo.field(0);
  const UninterpretedOption& baz = file_.options().uninterpreted_option(0);

  EXPECT_TRUE(HasSpanWithComment('a', 'd', foo,
      " Foo leading\n line 2\n",
      " Foo trailing\n line 2 "));
  EXPECT_TRUE(HasSpanWithComment('b', 'c', bar,
      " bar leading\n",
      " bar trailing\n"));
  EXPECT_TRUE(HasSpanWithComment('e', 'f', baz,
      " option leading\n",
      " option trailing\n"));

  // Ignore these.
  EXPECT_TRUE(HasSpan(file_));
  EXPECT_TRUE(HasSpan(foo, "name"));
  EXPECT_TRUE(HasSpan(bar, "label"));
  EXPECT_TRUE(HasSpan(bar, "type"));
  EXPECT_TRUE(HasSpan(bar, "name"));
  EXPECT_TRUE(HasSpan(bar, "number"));
  EXPECT_TRUE(HasSpan(file_.options()));
  EXPECT_TRUE(HasSpan(baz, "name"));
  EXPECT_TRUE(HasSpan(baz.name(0)));
  EXPECT_TRUE(HasSpan(baz.name(0), "name_part"));
  EXPECT_TRUE(HasSpan(baz, "positive_int_value"));
}

TEST_F(SourceInfoTest, DocComments3) {
  EXPECT_TRUE(Parse(
      "$a$message Foo {\n"
      "  // bar leading\n"
      "  $b$optional int32 bar = 1 [(baz.qux) = {}];$c$\n"
      "  // bar trailing\n"
      "}$d$\n"
      "// ignored\n"
  ));

  const DescriptorProto& foo = file_.message_type(0);
  const FieldDescriptorProto& bar = foo.field(0);

  EXPECT_TRUE(HasSpanWithComment('b', 'c', bar,
      " bar leading\n",
      " bar trailing\n"));

  // Ignore these.
  EXPECT_TRUE(HasSpan(file_));
  EXPECT_TRUE(HasSpan(foo));
  EXPECT_TRUE(HasSpan(foo, "name"));
  EXPECT_TRUE(HasSpan(bar, "label"));
  EXPECT_TRUE(HasSpan(bar, "type"));
  EXPECT_TRUE(HasSpan(bar, "name"));
  EXPECT_TRUE(HasSpan(bar, "number"));
  EXPECT_TRUE(HasSpan(bar.options()));
  EXPECT_TRUE(HasSpan(bar.options().uninterpreted_option(0)));
  EXPECT_TRUE(HasSpan(bar.options().uninterpreted_option(0), "name"));
  EXPECT_TRUE(HasSpan(bar.options().uninterpreted_option(0).name(0)));
  EXPECT_TRUE(HasSpan(
      bar.options().uninterpreted_option(0).name(0), "name_part"));
  EXPECT_TRUE(HasSpan(
      bar.options().uninterpreted_option(0), "aggregate_value"));
}

// ===================================================================

}  // anonymous namespace

}  // namespace compiler
}  // namespace protobuf
}  // namespace google
