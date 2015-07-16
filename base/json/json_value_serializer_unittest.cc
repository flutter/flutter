// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <string>

#include "base/files/file_util.h"
#include "base/files/scoped_temp_dir.h"
#include "base/json/json_file_value_serializer.h"
#include "base/json/json_reader.h"
#include "base/json/json_string_value_serializer.h"
#include "base/json/json_writer.h"
#include "base/memory/scoped_ptr.h"
#include "base/path_service.h"
#include "base/strings/string_piece.h"
#include "base/strings/string_util.h"
#include "base/strings/utf_string_conversions.h"
#include "base/values.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

namespace {

// Some proper JSON to test with:
const char kProperJSON[] =
    "{\n"
    "   \"compound\": {\n"
    "      \"a\": 1,\n"
    "      \"b\": 2\n"
    "   },\n"
    "   \"some_String\": \"1337\",\n"
    "   \"some_int\": 42,\n"
    "   \"the_list\": [ \"val1\", \"val2\" ]\n"
    "}\n";

// Some proper JSON with trailing commas:
const char kProperJSONWithCommas[] =
    "{\n"
    "\t\"some_int\": 42,\n"
    "\t\"some_String\": \"1337\",\n"
    "\t\"the_list\": [\"val1\", \"val2\", ],\n"
    "\t\"compound\": { \"a\": 1, \"b\": 2, },\n"
    "}\n";

// kProperJSON with a few misc characters at the begin and end.
const char kProperJSONPadded[] =
    ")]}'\n"
    "{\n"
    "   \"compound\": {\n"
    "      \"a\": 1,\n"
    "      \"b\": 2\n"
    "   },\n"
    "   \"some_String\": \"1337\",\n"
    "   \"some_int\": 42,\n"
    "   \"the_list\": [ \"val1\", \"val2\" ]\n"
    "}\n"
    "?!ab\n";

const char kWinLineEnds[] = "\r\n";
const char kLinuxLineEnds[] = "\n";

// Verifies the generated JSON against the expected output.
void CheckJSONIsStillTheSame(const Value& value) {
  // Serialize back the output.
  std::string serialized_json;
  JSONStringValueSerializer str_serializer(&serialized_json);
  str_serializer.set_pretty_print(true);
  ASSERT_TRUE(str_serializer.Serialize(value));
  // Unify line endings between platforms.
  ReplaceSubstringsAfterOffset(&serialized_json, 0,
                               kWinLineEnds, kLinuxLineEnds);
  // Now compare the input with the output.
  ASSERT_EQ(kProperJSON, serialized_json);
}

void ValidateJsonList(const std::string& json) {
  scoped_ptr<Value> root = JSONReader::Read(json);
  ASSERT_TRUE(root.get() && root->IsType(Value::TYPE_LIST));
  ListValue* list = static_cast<ListValue*>(root.get());
  ASSERT_EQ(1U, list->GetSize());
  Value* elt = NULL;
  ASSERT_TRUE(list->Get(0, &elt));
  int value = 0;
  ASSERT_TRUE(elt && elt->GetAsInteger(&value));
  ASSERT_EQ(1, value);
}

// Test proper JSON deserialization from string is working.
TEST(JSONValueDeserializerTest, ReadProperJSONFromString) {
  // Try to deserialize it through the serializer.
  JSONStringValueDeserializer str_deserializer(kProperJSON);

  int error_code = 0;
  std::string error_message;
  scoped_ptr<Value> value(
      str_deserializer.Deserialize(&error_code, &error_message));
  ASSERT_TRUE(value.get());
  ASSERT_EQ(0, error_code);
  ASSERT_TRUE(error_message.empty());
  // Verify if the same JSON is still there.
  CheckJSONIsStillTheSame(*value);
}

// Test proper JSON deserialization from a StringPiece substring.
TEST(JSONValueDeserializerTest, ReadProperJSONFromStringPiece) {
  // Create a StringPiece for the substring of kProperJSONPadded that matches
  // kProperJSON.
  base::StringPiece proper_json(kProperJSONPadded);
  proper_json = proper_json.substr(5, proper_json.length() - 10);
  JSONStringValueDeserializer str_deserializer(proper_json);

  int error_code = 0;
  std::string error_message;
  scoped_ptr<Value> value(
      str_deserializer.Deserialize(&error_code, &error_message));
  ASSERT_TRUE(value.get());
  ASSERT_EQ(0, error_code);
  ASSERT_TRUE(error_message.empty());
  // Verify if the same JSON is still there.
  CheckJSONIsStillTheSame(*value);
}

// Test that trialing commas are only properly deserialized from string when
// the proper flag for that is set.
TEST(JSONValueDeserializerTest, ReadJSONWithTrailingCommasFromString) {
  // Try to deserialize it through the serializer.
  JSONStringValueDeserializer str_deserializer(kProperJSONWithCommas);

  int error_code = 0;
  std::string error_message;
  scoped_ptr<Value> value(
      str_deserializer.Deserialize(&error_code, &error_message));
  ASSERT_FALSE(value.get());
  ASSERT_NE(0, error_code);
  ASSERT_FALSE(error_message.empty());
  // Now the flag is set and it must pass.
  str_deserializer.set_allow_trailing_comma(true);
  value.reset(str_deserializer.Deserialize(&error_code, &error_message));
  ASSERT_TRUE(value.get());
  ASSERT_EQ(JSONReader::JSON_TRAILING_COMMA, error_code);
  // Verify if the same JSON is still there.
  CheckJSONIsStillTheSame(*value);
}

// Test proper JSON deserialization from file is working.
TEST(JSONValueDeserializerTest, ReadProperJSONFromFile) {
  ScopedTempDir tempdir;
  ASSERT_TRUE(tempdir.CreateUniqueTempDir());
  // Write it down in the file.
  FilePath temp_file(tempdir.path().AppendASCII("test.json"));
  ASSERT_EQ(static_cast<int>(strlen(kProperJSON)),
            WriteFile(temp_file, kProperJSON, strlen(kProperJSON)));

  // Try to deserialize it through the serializer.
  JSONFileValueDeserializer file_deserializer(temp_file);

  int error_code = 0;
  std::string error_message;
  scoped_ptr<Value> value(
      file_deserializer.Deserialize(&error_code, &error_message));
  ASSERT_TRUE(value.get());
  ASSERT_EQ(0, error_code);
  ASSERT_TRUE(error_message.empty());
  // Verify if the same JSON is still there.
  CheckJSONIsStillTheSame(*value);
}

// Test that trialing commas are only properly deserialized from file when
// the proper flag for that is set.
TEST(JSONValueDeserializerTest, ReadJSONWithCommasFromFile) {
  ScopedTempDir tempdir;
  ASSERT_TRUE(tempdir.CreateUniqueTempDir());
  // Write it down in the file.
  FilePath temp_file(tempdir.path().AppendASCII("test.json"));
  ASSERT_EQ(static_cast<int>(strlen(kProperJSONWithCommas)),
            WriteFile(temp_file, kProperJSONWithCommas,
                      strlen(kProperJSONWithCommas)));

  // Try to deserialize it through the serializer.
  JSONFileValueDeserializer file_deserializer(temp_file);
  // This must fail without the proper flag.
  int error_code = 0;
  std::string error_message;
  scoped_ptr<Value> value(
      file_deserializer.Deserialize(&error_code, &error_message));
  ASSERT_FALSE(value.get());
  ASSERT_NE(0, error_code);
  ASSERT_FALSE(error_message.empty());
  // Now the flag is set and it must pass.
  file_deserializer.set_allow_trailing_comma(true);
  value.reset(file_deserializer.Deserialize(&error_code, &error_message));
  ASSERT_TRUE(value.get());
  ASSERT_EQ(JSONReader::JSON_TRAILING_COMMA, error_code);
  // Verify if the same JSON is still there.
  CheckJSONIsStillTheSame(*value);
}

TEST(JSONValueDeserializerTest, AllowTrailingComma) {
  scoped_ptr<Value> root;
  scoped_ptr<Value> root_expected;
  static const char kTestWithCommas[] = "{\"key\": [true,],}";
  static const char kTestNoCommas[] = "{\"key\": [true]}";

  JSONStringValueDeserializer deserializer(kTestWithCommas);
  deserializer.set_allow_trailing_comma(true);
  JSONStringValueDeserializer deserializer_expected(kTestNoCommas);
  root.reset(deserializer.Deserialize(NULL, NULL));
  ASSERT_TRUE(root.get());
  root_expected.reset(deserializer_expected.Deserialize(NULL, NULL));
  ASSERT_TRUE(root_expected.get());
  ASSERT_TRUE(root->Equals(root_expected.get()));
}

TEST(JSONValueSerializerTest, Roundtrip) {
  static const char kOriginalSerialization[] =
    "{\"bool\":true,\"double\":3.14,\"int\":42,\"list\":[1,2],\"null\":null}";
  JSONStringValueDeserializer deserializer(kOriginalSerialization);
  scoped_ptr<Value> root(deserializer.Deserialize(NULL, NULL));
  ASSERT_TRUE(root.get());
  ASSERT_TRUE(root->IsType(Value::TYPE_DICTIONARY));

  DictionaryValue* root_dict = static_cast<DictionaryValue*>(root.get());

  Value* null_value = NULL;
  ASSERT_TRUE(root_dict->Get("null", &null_value));
  ASSERT_TRUE(null_value);
  ASSERT_TRUE(null_value->IsType(Value::TYPE_NULL));

  bool bool_value = false;
  ASSERT_TRUE(root_dict->GetBoolean("bool", &bool_value));
  ASSERT_TRUE(bool_value);

  int int_value = 0;
  ASSERT_TRUE(root_dict->GetInteger("int", &int_value));
  ASSERT_EQ(42, int_value);

  double double_value = 0.0;
  ASSERT_TRUE(root_dict->GetDouble("double", &double_value));
  ASSERT_DOUBLE_EQ(3.14, double_value);

  std::string test_serialization;
  JSONStringValueSerializer mutable_serializer(&test_serialization);
  ASSERT_TRUE(mutable_serializer.Serialize(*root_dict));
  ASSERT_EQ(kOriginalSerialization, test_serialization);

  mutable_serializer.set_pretty_print(true);
  ASSERT_TRUE(mutable_serializer.Serialize(*root_dict));
  // JSON output uses a different newline style on Windows than on other
  // platforms.
#if defined(OS_WIN)
#define JSON_NEWLINE "\r\n"
#else
#define JSON_NEWLINE "\n"
#endif
  const std::string pretty_serialization =
    "{" JSON_NEWLINE
    "   \"bool\": true," JSON_NEWLINE
    "   \"double\": 3.14," JSON_NEWLINE
    "   \"int\": 42," JSON_NEWLINE
    "   \"list\": [ 1, 2 ]," JSON_NEWLINE
    "   \"null\": null" JSON_NEWLINE
    "}" JSON_NEWLINE;
#undef JSON_NEWLINE
  ASSERT_EQ(pretty_serialization, test_serialization);
}

TEST(JSONValueSerializerTest, StringEscape) {
  string16 all_chars;
  for (int i = 1; i < 256; ++i) {
    all_chars += static_cast<char16>(i);
  }
  // Generated in in Firefox using the following js (with an extra backslash for
  // double quote):
  // var s = '';
  // for (var i = 1; i < 256; ++i) { s += String.fromCharCode(i); }
  // uneval(s).replace(/\\/g, "\\\\");
  std::string all_chars_expected =
      "\\u0001\\u0002\\u0003\\u0004\\u0005\\u0006\\u0007\\b\\t\\n\\u000B\\f\\r"
      "\\u000E\\u000F\\u0010\\u0011\\u0012\\u0013\\u0014\\u0015\\u0016\\u0017"
      "\\u0018\\u0019\\u001A\\u001B\\u001C\\u001D\\u001E\\u001F !\\\"#$%&'()*+,"
      "-./0123456789:;\\u003C=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\\\]^_`abcde"
      "fghijklmnopqrstuvwxyz{|}~\x7F\xC2\x80\xC2\x81\xC2\x82\xC2\x83\xC2\x84"
      "\xC2\x85\xC2\x86\xC2\x87\xC2\x88\xC2\x89\xC2\x8A\xC2\x8B\xC2\x8C\xC2\x8D"
      "\xC2\x8E\xC2\x8F\xC2\x90\xC2\x91\xC2\x92\xC2\x93\xC2\x94\xC2\x95\xC2\x96"
      "\xC2\x97\xC2\x98\xC2\x99\xC2\x9A\xC2\x9B\xC2\x9C\xC2\x9D\xC2\x9E\xC2\x9F"
      "\xC2\xA0\xC2\xA1\xC2\xA2\xC2\xA3\xC2\xA4\xC2\xA5\xC2\xA6\xC2\xA7\xC2\xA8"
      "\xC2\xA9\xC2\xAA\xC2\xAB\xC2\xAC\xC2\xAD\xC2\xAE\xC2\xAF\xC2\xB0\xC2\xB1"
      "\xC2\xB2\xC2\xB3\xC2\xB4\xC2\xB5\xC2\xB6\xC2\xB7\xC2\xB8\xC2\xB9\xC2\xBA"
      "\xC2\xBB\xC2\xBC\xC2\xBD\xC2\xBE\xC2\xBF\xC3\x80\xC3\x81\xC3\x82\xC3\x83"
      "\xC3\x84\xC3\x85\xC3\x86\xC3\x87\xC3\x88\xC3\x89\xC3\x8A\xC3\x8B\xC3\x8C"
      "\xC3\x8D\xC3\x8E\xC3\x8F\xC3\x90\xC3\x91\xC3\x92\xC3\x93\xC3\x94\xC3\x95"
      "\xC3\x96\xC3\x97\xC3\x98\xC3\x99\xC3\x9A\xC3\x9B\xC3\x9C\xC3\x9D\xC3\x9E"
      "\xC3\x9F\xC3\xA0\xC3\xA1\xC3\xA2\xC3\xA3\xC3\xA4\xC3\xA5\xC3\xA6\xC3\xA7"
      "\xC3\xA8\xC3\xA9\xC3\xAA\xC3\xAB\xC3\xAC\xC3\xAD\xC3\xAE\xC3\xAF\xC3\xB0"
      "\xC3\xB1\xC3\xB2\xC3\xB3\xC3\xB4\xC3\xB5\xC3\xB6\xC3\xB7\xC3\xB8\xC3\xB9"
      "\xC3\xBA\xC3\xBB\xC3\xBC\xC3\xBD\xC3\xBE\xC3\xBF";

  std::string expected_output = "{\"all_chars\":\"" + all_chars_expected +
                                 "\"}";
  // Test JSONWriter interface
  std::string output_js;
  DictionaryValue valueRoot;
  valueRoot.SetString("all_chars", all_chars);
  JSONWriter::Write(valueRoot, &output_js);
  ASSERT_EQ(expected_output, output_js);

  // Test JSONValueSerializer interface (uses JSONWriter).
  JSONStringValueSerializer serializer(&output_js);
  ASSERT_TRUE(serializer.Serialize(valueRoot));
  ASSERT_EQ(expected_output, output_js);
}

TEST(JSONValueSerializerTest, UnicodeStrings) {
  // unicode string json -> escaped ascii text
  DictionaryValue root;
  string16 test(WideToUTF16(L"\x7F51\x9875"));
  root.SetString("web", test);

  static const char kExpected[] = "{\"web\":\"\xE7\xBD\x91\xE9\xA1\xB5\"}";

  std::string actual;
  JSONStringValueSerializer serializer(&actual);
  ASSERT_TRUE(serializer.Serialize(root));
  ASSERT_EQ(kExpected, actual);

  // escaped ascii text -> json
  JSONStringValueDeserializer deserializer(kExpected);
  scoped_ptr<Value> deserial_root(deserializer.Deserialize(NULL, NULL));
  ASSERT_TRUE(deserial_root.get());
  DictionaryValue* dict_root =
      static_cast<DictionaryValue*>(deserial_root.get());
  string16 web_value;
  ASSERT_TRUE(dict_root->GetString("web", &web_value));
  ASSERT_EQ(test, web_value);
}

TEST(JSONValueSerializerTest, HexStrings) {
  // hex string json -> escaped ascii text
  DictionaryValue root;
  string16 test(WideToUTF16(L"\x01\x02"));
  root.SetString("test", test);

  static const char kExpected[] = "{\"test\":\"\\u0001\\u0002\"}";

  std::string actual;
  JSONStringValueSerializer serializer(&actual);
  ASSERT_TRUE(serializer.Serialize(root));
  ASSERT_EQ(kExpected, actual);

  // escaped ascii text -> json
  JSONStringValueDeserializer deserializer(kExpected);
  scoped_ptr<Value> deserial_root(deserializer.Deserialize(NULL, NULL));
  ASSERT_TRUE(deserial_root.get());
  DictionaryValue* dict_root =
      static_cast<DictionaryValue*>(deserial_root.get());
  string16 test_value;
  ASSERT_TRUE(dict_root->GetString("test", &test_value));
  ASSERT_EQ(test, test_value);

  // Test converting escaped regular chars
  static const char kEscapedChars[] = "{\"test\":\"\\u0067\\u006f\"}";
  JSONStringValueDeserializer deserializer2(kEscapedChars);
  deserial_root.reset(deserializer2.Deserialize(NULL, NULL));
  ASSERT_TRUE(deserial_root.get());
  dict_root = static_cast<DictionaryValue*>(deserial_root.get());
  ASSERT_TRUE(dict_root->GetString("test", &test_value));
  ASSERT_EQ(ASCIIToUTF16("go"), test_value);
}

TEST(JSONValueSerializerTest, JSONReaderComments) {
  ValidateJsonList("[ // 2, 3, ignore me ] \n1 ]");
  ValidateJsonList("[ /* 2, \n3, ignore me ]*/ \n1 ]");
  ValidateJsonList("//header\n[ // 2, \n// 3, \n1 ]// footer");
  ValidateJsonList("/*\n[ // 2, \n// 3, \n1 ]*/[1]");
  ValidateJsonList("[ 1 /* one */ ] /* end */");
  ValidateJsonList("[ 1 //// ,2\r\n ]");

  scoped_ptr<Value> root;

  // It's ok to have a comment in a string.
  root.reset(JSONReader::DeprecatedRead("[\"// ok\\n /* foo */ \"]"));
  ASSERT_TRUE(root.get() && root->IsType(Value::TYPE_LIST));
  ListValue* list = static_cast<ListValue*>(root.get());
  ASSERT_EQ(1U, list->GetSize());
  Value* elt = NULL;
  ASSERT_TRUE(list->Get(0, &elt));
  std::string value;
  ASSERT_TRUE(elt && elt->GetAsString(&value));
  ASSERT_EQ("// ok\n /* foo */ ", value);

  // You can't nest comments.
  root.reset(JSONReader::DeprecatedRead("/* /* inner */ outer */ [ 1 ]"));
  ASSERT_FALSE(root.get());

  // Not a open comment token.
  root.reset(JSONReader::DeprecatedRead("/ * * / [1]"));
  ASSERT_FALSE(root.get());
}

class JSONFileValueSerializerTest : public testing::Test {
 protected:
  void SetUp() override { ASSERT_TRUE(temp_dir_.CreateUniqueTempDir()); }

  base::ScopedTempDir temp_dir_;
};

TEST_F(JSONFileValueSerializerTest, Roundtrip) {
  base::FilePath original_file_path;
  ASSERT_TRUE(PathService::Get(DIR_TEST_DATA, &original_file_path));
  original_file_path =
      original_file_path.Append(FILE_PATH_LITERAL("serializer_test.json"));

  ASSERT_TRUE(PathExists(original_file_path));

  JSONFileValueDeserializer deserializer(original_file_path);
  scoped_ptr<Value> root;
  root.reset(deserializer.Deserialize(NULL, NULL));

  ASSERT_TRUE(root.get());
  ASSERT_TRUE(root->IsType(Value::TYPE_DICTIONARY));

  DictionaryValue* root_dict = static_cast<DictionaryValue*>(root.get());

  Value* null_value = NULL;
  ASSERT_TRUE(root_dict->Get("null", &null_value));
  ASSERT_TRUE(null_value);
  ASSERT_TRUE(null_value->IsType(Value::TYPE_NULL));

  bool bool_value = false;
  ASSERT_TRUE(root_dict->GetBoolean("bool", &bool_value));
  ASSERT_TRUE(bool_value);

  int int_value = 0;
  ASSERT_TRUE(root_dict->GetInteger("int", &int_value));
  ASSERT_EQ(42, int_value);

  std::string string_value;
  ASSERT_TRUE(root_dict->GetString("string", &string_value));
  ASSERT_EQ("hello", string_value);

  // Now try writing.
  const base::FilePath written_file_path =
      temp_dir_.path().Append(FILE_PATH_LITERAL("test_output.js"));

  ASSERT_FALSE(PathExists(written_file_path));
  JSONFileValueSerializer serializer(written_file_path);
  ASSERT_TRUE(serializer.Serialize(*root));
  ASSERT_TRUE(PathExists(written_file_path));

  // Now compare file contents.
  EXPECT_TRUE(TextContentsEqual(original_file_path, written_file_path));
  EXPECT_TRUE(base::DeleteFile(written_file_path, false));
}

TEST_F(JSONFileValueSerializerTest, RoundtripNested) {
  base::FilePath original_file_path;
  ASSERT_TRUE(PathService::Get(DIR_TEST_DATA, &original_file_path));
  original_file_path = original_file_path.Append(
      FILE_PATH_LITERAL("serializer_nested_test.json"));

  ASSERT_TRUE(PathExists(original_file_path));

  JSONFileValueDeserializer deserializer(original_file_path);
  scoped_ptr<Value> root;
  root.reset(deserializer.Deserialize(NULL, NULL));
  ASSERT_TRUE(root.get());

  // Now try writing.
  base::FilePath written_file_path = temp_dir_.path().Append(
      FILE_PATH_LITERAL("test_output.json"));

  ASSERT_FALSE(PathExists(written_file_path));
  JSONFileValueSerializer serializer(written_file_path);
  ASSERT_TRUE(serializer.Serialize(*root));
  ASSERT_TRUE(PathExists(written_file_path));

  // Now compare file contents.
  EXPECT_TRUE(TextContentsEqual(original_file_path, written_file_path));
  EXPECT_TRUE(base::DeleteFile(written_file_path, false));
}

TEST_F(JSONFileValueSerializerTest, NoWhitespace) {
  base::FilePath source_file_path;
  ASSERT_TRUE(PathService::Get(DIR_TEST_DATA, &source_file_path));
  source_file_path = source_file_path.Append(
      FILE_PATH_LITERAL("serializer_test_nowhitespace.json"));
  ASSERT_TRUE(PathExists(source_file_path));
  JSONFileValueDeserializer deserializer(source_file_path);
  scoped_ptr<Value> root;
  root.reset(deserializer.Deserialize(NULL, NULL));
  ASSERT_TRUE(root.get());
}

}  // namespace

}  // namespace base
