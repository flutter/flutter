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
//
// Recursive descent FTW.

#include <float.h>
#include <google/protobuf/stubs/hash.h>
#include <limits>


#include <google/protobuf/compiler/parser.h>
#include <google/protobuf/descriptor.h>
#include <google/protobuf/descriptor.pb.h>
#include <google/protobuf/wire_format.h>
#include <google/protobuf/io/tokenizer.h>
#include <google/protobuf/stubs/common.h>
#include <google/protobuf/stubs/strutil.h>
#include <google/protobuf/stubs/map-util.h>

namespace google {
namespace protobuf {
namespace compiler {

using internal::WireFormat;

namespace {

typedef hash_map<string, FieldDescriptorProto::Type> TypeNameMap;

TypeNameMap MakeTypeNameTable() {
  TypeNameMap result;

  result["double"  ] = FieldDescriptorProto::TYPE_DOUBLE;
  result["float"   ] = FieldDescriptorProto::TYPE_FLOAT;
  result["uint64"  ] = FieldDescriptorProto::TYPE_UINT64;
  result["fixed64" ] = FieldDescriptorProto::TYPE_FIXED64;
  result["fixed32" ] = FieldDescriptorProto::TYPE_FIXED32;
  result["bool"    ] = FieldDescriptorProto::TYPE_BOOL;
  result["string"  ] = FieldDescriptorProto::TYPE_STRING;
  result["group"   ] = FieldDescriptorProto::TYPE_GROUP;

  result["bytes"   ] = FieldDescriptorProto::TYPE_BYTES;
  result["uint32"  ] = FieldDescriptorProto::TYPE_UINT32;
  result["sfixed32"] = FieldDescriptorProto::TYPE_SFIXED32;
  result["sfixed64"] = FieldDescriptorProto::TYPE_SFIXED64;
  result["int32"   ] = FieldDescriptorProto::TYPE_INT32;
  result["int64"   ] = FieldDescriptorProto::TYPE_INT64;
  result["sint32"  ] = FieldDescriptorProto::TYPE_SINT32;
  result["sint64"  ] = FieldDescriptorProto::TYPE_SINT64;

  return result;
}

const TypeNameMap kTypeNames = MakeTypeNameTable();

}  // anonymous namespace

// Makes code slightly more readable.  The meaning of "DO(foo)" is
// "Execute foo and fail if it fails.", where failure is indicated by
// returning false.
#define DO(STATEMENT) if (STATEMENT) {} else return false

// ===================================================================

Parser::Parser()
  : input_(NULL),
    error_collector_(NULL),
    source_location_table_(NULL),
    had_errors_(false),
    require_syntax_identifier_(false),
    stop_after_syntax_identifier_(false) {
}

Parser::~Parser() {
}

// ===================================================================

inline bool Parser::LookingAt(const char* text) {
  return input_->current().text == text;
}

inline bool Parser::LookingAtType(io::Tokenizer::TokenType token_type) {
  return input_->current().type == token_type;
}

inline bool Parser::AtEnd() {
  return LookingAtType(io::Tokenizer::TYPE_END);
}

bool Parser::TryConsume(const char* text) {
  if (LookingAt(text)) {
    input_->Next();
    return true;
  } else {
    return false;
  }
}

bool Parser::Consume(const char* text, const char* error) {
  if (TryConsume(text)) {
    return true;
  } else {
    AddError(error);
    return false;
  }
}

bool Parser::Consume(const char* text) {
  if (TryConsume(text)) {
    return true;
  } else {
    AddError("Expected \"" + string(text) + "\".");
    return false;
  }
}

bool Parser::ConsumeIdentifier(string* output, const char* error) {
  if (LookingAtType(io::Tokenizer::TYPE_IDENTIFIER)) {
    *output = input_->current().text;
    input_->Next();
    return true;
  } else {
    AddError(error);
    return false;
  }
}

bool Parser::ConsumeInteger(int* output, const char* error) {
  if (LookingAtType(io::Tokenizer::TYPE_INTEGER)) {
    uint64 value = 0;
    if (!io::Tokenizer::ParseInteger(input_->current().text,
                                     kint32max, &value)) {
      AddError("Integer out of range.");
      // We still return true because we did, in fact, parse an integer.
    }
    *output = value;
    input_->Next();
    return true;
  } else {
    AddError(error);
    return false;
  }
}

bool Parser::ConsumeSignedInteger(int* output, const char* error) {
  bool is_negative = false;
  uint64 max_value = kint32max;
  if (TryConsume("-")) {
    is_negative = true;
    max_value += 1;
  }
  uint64 value = 0;
  DO(ConsumeInteger64(max_value, &value, error));
  if (is_negative) value *= -1;
  *output = value;
  return true;
}

bool Parser::ConsumeInteger64(uint64 max_value, uint64* output,
                              const char* error) {
  if (LookingAtType(io::Tokenizer::TYPE_INTEGER)) {
    if (!io::Tokenizer::ParseInteger(input_->current().text, max_value,
                                     output)) {
      AddError("Integer out of range.");
      // We still return true because we did, in fact, parse an integer.
      *output = 0;
    }
    input_->Next();
    return true;
  } else {
    AddError(error);
    return false;
  }
}

bool Parser::ConsumeNumber(double* output, const char* error) {
  if (LookingAtType(io::Tokenizer::TYPE_FLOAT)) {
    *output = io::Tokenizer::ParseFloat(input_->current().text);
    input_->Next();
    return true;
  } else if (LookingAtType(io::Tokenizer::TYPE_INTEGER)) {
    // Also accept integers.
    uint64 value = 0;
    if (!io::Tokenizer::ParseInteger(input_->current().text,
                                     kuint64max, &value)) {
      AddError("Integer out of range.");
      // We still return true because we did, in fact, parse a number.
    }
    *output = value;
    input_->Next();
    return true;
  } else if (LookingAt("inf")) {
    *output = numeric_limits<double>::infinity();
    input_->Next();
    return true;
  } else if (LookingAt("nan")) {
    *output = numeric_limits<double>::quiet_NaN();
    input_->Next();
    return true;
  } else {
    AddError(error);
    return false;
  }
}

bool Parser::ConsumeString(string* output, const char* error) {
  if (LookingAtType(io::Tokenizer::TYPE_STRING)) {
    io::Tokenizer::ParseString(input_->current().text, output);
    input_->Next();
    // Allow C++ like concatenation of adjacent string tokens.
    while (LookingAtType(io::Tokenizer::TYPE_STRING)) {
      io::Tokenizer::ParseStringAppend(input_->current().text, output);
      input_->Next();
    }
    return true;
  } else {
    AddError(error);
    return false;
  }
}

bool Parser::TryConsumeEndOfDeclaration(const char* text,
                                        const LocationRecorder* location) {
  if (LookingAt(text)) {
    string leading, trailing;
    input_->NextWithComments(&trailing, NULL, &leading);

    // Save the leading comments for next time, and recall the leading comments
    // from last time.
    leading.swap(upcoming_doc_comments_);

    if (location != NULL) {
      location->AttachComments(&leading, &trailing);
    }
    return true;
  } else {
    return false;
  }
}

bool Parser::ConsumeEndOfDeclaration(const char* text,
                                     const LocationRecorder* location) {
  if (TryConsumeEndOfDeclaration(text, location)) {
    return true;
  } else {
    AddError("Expected \"" + string(text) + "\".");
    return false;
  }
}

// -------------------------------------------------------------------

void Parser::AddError(int line, int column, const string& error) {
  if (error_collector_ != NULL) {
    error_collector_->AddError(line, column, error);
  }
  had_errors_ = true;
}

void Parser::AddError(const string& error) {
  AddError(input_->current().line, input_->current().column, error);
}

// -------------------------------------------------------------------

Parser::LocationRecorder::LocationRecorder(Parser* parser)
  : parser_(parser),
    location_(parser_->source_code_info_->add_location()) {
  location_->add_span(parser_->input_->current().line);
  location_->add_span(parser_->input_->current().column);
}

Parser::LocationRecorder::LocationRecorder(const LocationRecorder& parent) {
  Init(parent);
}

Parser::LocationRecorder::LocationRecorder(const LocationRecorder& parent,
                                           int path1) {
  Init(parent);
  AddPath(path1);
}

Parser::LocationRecorder::LocationRecorder(const LocationRecorder& parent,
                                           int path1, int path2) {
  Init(parent);
  AddPath(path1);
  AddPath(path2);
}

void Parser::LocationRecorder::Init(const LocationRecorder& parent) {
  parser_ = parent.parser_;
  location_ = parser_->source_code_info_->add_location();
  location_->mutable_path()->CopyFrom(parent.location_->path());

  location_->add_span(parser_->input_->current().line);
  location_->add_span(parser_->input_->current().column);
}

Parser::LocationRecorder::~LocationRecorder() {
  if (location_->span_size() <= 2) {
    EndAt(parser_->input_->previous());
  }
}

void Parser::LocationRecorder::AddPath(int path_component) {
  location_->add_path(path_component);
}

void Parser::LocationRecorder::StartAt(const io::Tokenizer::Token& token) {
  location_->set_span(0, token.line);
  location_->set_span(1, token.column);
}

void Parser::LocationRecorder::EndAt(const io::Tokenizer::Token& token) {
  if (token.line != location_->span(0)) {
    location_->add_span(token.line);
  }
  location_->add_span(token.end_column);
}

void Parser::LocationRecorder::RecordLegacyLocation(const Message* descriptor,
    DescriptorPool::ErrorCollector::ErrorLocation location) {
  if (parser_->source_location_table_ != NULL) {
    parser_->source_location_table_->Add(
        descriptor, location, location_->span(0), location_->span(1));
  }
}

void Parser::LocationRecorder::AttachComments(
    string* leading, string* trailing) const {
  GOOGLE_CHECK(!location_->has_leading_comments());
  GOOGLE_CHECK(!location_->has_trailing_comments());

  if (!leading->empty()) {
    location_->mutable_leading_comments()->swap(*leading);
  }
  if (!trailing->empty()) {
    location_->mutable_trailing_comments()->swap(*trailing);
  }
}

// -------------------------------------------------------------------

void Parser::SkipStatement() {
  while (true) {
    if (AtEnd()) {
      return;
    } else if (LookingAtType(io::Tokenizer::TYPE_SYMBOL)) {
      if (TryConsumeEndOfDeclaration(";", NULL)) {
        return;
      } else if (TryConsume("{")) {
        SkipRestOfBlock();
        return;
      } else if (LookingAt("}")) {
        return;
      }
    }
    input_->Next();
  }
}

void Parser::SkipRestOfBlock() {
  while (true) {
    if (AtEnd()) {
      return;
    } else if (LookingAtType(io::Tokenizer::TYPE_SYMBOL)) {
      if (TryConsumeEndOfDeclaration("}", NULL)) {
        return;
      } else if (TryConsume("{")) {
        SkipRestOfBlock();
      }
    }
    input_->Next();
  }
}

// ===================================================================

bool Parser::Parse(io::Tokenizer* input, FileDescriptorProto* file) {
  input_ = input;
  had_errors_ = false;
  syntax_identifier_.clear();

  // Note that |file| could be NULL at this point if
  // stop_after_syntax_identifier_ is true.  So, we conservatively allocate
  // SourceCodeInfo on the stack, then swap it into the FileDescriptorProto
  // later on.
  SourceCodeInfo source_code_info;
  source_code_info_ = &source_code_info;

  if (LookingAtType(io::Tokenizer::TYPE_START)) {
    // Advance to first token.
    input_->NextWithComments(NULL, NULL, &upcoming_doc_comments_);
  }

  {
    LocationRecorder root_location(this);

    if (require_syntax_identifier_ || LookingAt("syntax")) {
      if (!ParseSyntaxIdentifier()) {
        // Don't attempt to parse the file if we didn't recognize the syntax
        // identifier.
        return false;
      }
    } else if (!stop_after_syntax_identifier_) {
      syntax_identifier_ = "proto2";
    }

    if (stop_after_syntax_identifier_) return !had_errors_;

    // Repeatedly parse statements until we reach the end of the file.
    while (!AtEnd()) {
      if (!ParseTopLevelStatement(file, root_location)) {
        // This statement failed to parse.  Skip it, but keep looping to parse
        // other statements.
        SkipStatement();

        if (LookingAt("}")) {
          AddError("Unmatched \"}\".");
          input_->NextWithComments(NULL, NULL, &upcoming_doc_comments_);
        }
      }
    }
  }

  input_ = NULL;
  source_code_info_ = NULL;
  source_code_info.Swap(file->mutable_source_code_info());
  return !had_errors_;
}

bool Parser::ParseSyntaxIdentifier() {
  DO(Consume("syntax", "File must begin with 'syntax = \"proto2\";'."));
  DO(Consume("="));
  io::Tokenizer::Token syntax_token = input_->current();
  string syntax;
  DO(ConsumeString(&syntax, "Expected syntax identifier."));
  DO(ConsumeEndOfDeclaration(";", NULL));

  syntax_identifier_ = syntax;

  if (syntax != "proto2" && !stop_after_syntax_identifier_) {
    AddError(syntax_token.line, syntax_token.column,
      "Unrecognized syntax identifier \"" + syntax + "\".  This parser "
      "only recognizes \"proto2\".");
    return false;
  }

  return true;
}

bool Parser::ParseTopLevelStatement(FileDescriptorProto* file,
                                    const LocationRecorder& root_location) {
  if (TryConsumeEndOfDeclaration(";", NULL)) {
    // empty statement; ignore
    return true;
  } else if (LookingAt("message")) {
    LocationRecorder location(root_location,
      FileDescriptorProto::kMessageTypeFieldNumber, file->message_type_size());
    return ParseMessageDefinition(file->add_message_type(), location);
  } else if (LookingAt("enum")) {
    LocationRecorder location(root_location,
      FileDescriptorProto::kEnumTypeFieldNumber, file->enum_type_size());
    return ParseEnumDefinition(file->add_enum_type(), location);
  } else if (LookingAt("service")) {
    LocationRecorder location(root_location,
      FileDescriptorProto::kServiceFieldNumber, file->service_size());
    return ParseServiceDefinition(file->add_service(), location);
  } else if (LookingAt("extend")) {
    LocationRecorder location(root_location,
        FileDescriptorProto::kExtensionFieldNumber);
    return ParseExtend(file->mutable_extension(),
                       file->mutable_message_type(),
                       root_location,
                       FileDescriptorProto::kMessageTypeFieldNumber,
                       location);
  } else if (LookingAt("import")) {
    return ParseImport(file->mutable_dependency(),
                       file->mutable_public_dependency(),
                       file->mutable_weak_dependency(),
                       root_location);
  } else if (LookingAt("package")) {
    return ParsePackage(file, root_location);
  } else if (LookingAt("option")) {
    LocationRecorder location(root_location,
        FileDescriptorProto::kOptionsFieldNumber);
    return ParseOption(file->mutable_options(), location, OPTION_STATEMENT);
  } else {
    AddError("Expected top-level statement (e.g. \"message\").");
    return false;
  }
}

// -------------------------------------------------------------------
// Messages

bool Parser::ParseMessageDefinition(DescriptorProto* message,
                                    const LocationRecorder& message_location) {
  DO(Consume("message"));
  {
    LocationRecorder location(message_location,
                              DescriptorProto::kNameFieldNumber);
    location.RecordLegacyLocation(
        message, DescriptorPool::ErrorCollector::NAME);
    DO(ConsumeIdentifier(message->mutable_name(), "Expected message name."));
  }
  DO(ParseMessageBlock(message, message_location));
  return true;
}

namespace {

const int kMaxExtensionRangeSentinel = -1;

bool IsMessageSetWireFormatMessage(const DescriptorProto& message) {
  const MessageOptions& options = message.options();
  for (int i = 0; i < options.uninterpreted_option_size(); ++i) {
    const UninterpretedOption& uninterpreted = options.uninterpreted_option(i);
    if (uninterpreted.name_size() == 1 &&
        uninterpreted.name(0).name_part() == "message_set_wire_format" &&
        uninterpreted.identifier_value() == "true") {
      return true;
    }
  }
  return false;
}

// Modifies any extension ranges that specified 'max' as the end of the
// extension range, and sets them to the type-specific maximum. The actual max
// tag number can only be determined after all options have been parsed.
void AdjustExtensionRangesWithMaxEndNumber(DescriptorProto* message) {
  const bool is_message_set = IsMessageSetWireFormatMessage(*message);
  const int max_extension_number = is_message_set ?
      kint32max :
      FieldDescriptor::kMaxNumber + 1;
  for (int i = 0; i < message->extension_range_size(); ++i) {
    if (message->extension_range(i).end() == kMaxExtensionRangeSentinel) {
      message->mutable_extension_range(i)->set_end(max_extension_number);
    }
  }
}

}  // namespace

bool Parser::ParseMessageBlock(DescriptorProto* message,
                               const LocationRecorder& message_location) {
  DO(ConsumeEndOfDeclaration("{", &message_location));

  while (!TryConsumeEndOfDeclaration("}", NULL)) {
    if (AtEnd()) {
      AddError("Reached end of input in message definition (missing '}').");
      return false;
    }

    if (!ParseMessageStatement(message, message_location)) {
      // This statement failed to parse.  Skip it, but keep looping to parse
      // other statements.
      SkipStatement();
    }
  }

  if (message->extension_range_size() > 0) {
    AdjustExtensionRangesWithMaxEndNumber(message);
  }
  return true;
}

bool Parser::ParseMessageStatement(DescriptorProto* message,
                                   const LocationRecorder& message_location) {
  if (TryConsumeEndOfDeclaration(";", NULL)) {
    // empty statement; ignore
    return true;
  } else if (LookingAt("message")) {
    LocationRecorder location(message_location,
                              DescriptorProto::kNestedTypeFieldNumber,
                              message->nested_type_size());
    return ParseMessageDefinition(message->add_nested_type(), location);
  } else if (LookingAt("enum")) {
    LocationRecorder location(message_location,
                              DescriptorProto::kEnumTypeFieldNumber,
                              message->enum_type_size());
    return ParseEnumDefinition(message->add_enum_type(), location);
  } else if (LookingAt("extensions")) {
    LocationRecorder location(message_location,
                              DescriptorProto::kExtensionRangeFieldNumber);
    return ParseExtensions(message, location);
  } else if (LookingAt("extend")) {
    LocationRecorder location(message_location,
                              DescriptorProto::kExtensionFieldNumber);
    return ParseExtend(message->mutable_extension(),
                       message->mutable_nested_type(),
                       message_location,
                       DescriptorProto::kNestedTypeFieldNumber,
                       location);
  } else if (LookingAt("option")) {
    LocationRecorder location(message_location,
                              DescriptorProto::kOptionsFieldNumber);
    return ParseOption(message->mutable_options(), location, OPTION_STATEMENT);
  } else {
    LocationRecorder location(message_location,
                              DescriptorProto::kFieldFieldNumber,
                              message->field_size());
    return ParseMessageField(message->add_field(),
                             message->mutable_nested_type(),
                             message_location,
                             DescriptorProto::kNestedTypeFieldNumber,
                             location);
  }
}

bool Parser::ParseMessageField(FieldDescriptorProto* field,
                               RepeatedPtrField<DescriptorProto>* messages,
                               const LocationRecorder& parent_location,
                               int location_field_number_for_nested_type,
                               const LocationRecorder& field_location) {
  // Parse label and type.
  io::Tokenizer::Token label_token = input_->current();
  {
    LocationRecorder location(field_location,
                              FieldDescriptorProto::kLabelFieldNumber);
    FieldDescriptorProto::Label label;
    DO(ParseLabel(&label));
    field->set_label(label);
  }

  {
    LocationRecorder location(field_location);  // add path later
    location.RecordLegacyLocation(field, DescriptorPool::ErrorCollector::TYPE);

    FieldDescriptorProto::Type type = FieldDescriptorProto::TYPE_INT32;
    string type_name;
    DO(ParseType(&type, &type_name));
    if (type_name.empty()) {
      location.AddPath(FieldDescriptorProto::kTypeFieldNumber);
      field->set_type(type);
    } else {
      location.AddPath(FieldDescriptorProto::kTypeNameFieldNumber);
      field->set_type_name(type_name);
    }
  }

  // Parse name and '='.
  io::Tokenizer::Token name_token = input_->current();
  {
    LocationRecorder location(field_location,
                              FieldDescriptorProto::kNameFieldNumber);
    location.RecordLegacyLocation(field, DescriptorPool::ErrorCollector::NAME);
    DO(ConsumeIdentifier(field->mutable_name(), "Expected field name."));
  }
  DO(Consume("=", "Missing field number."));

  // Parse field number.
  {
    LocationRecorder location(field_location,
                              FieldDescriptorProto::kNumberFieldNumber);
    location.RecordLegacyLocation(
        field, DescriptorPool::ErrorCollector::NUMBER);
    int number;
    DO(ConsumeInteger(&number, "Expected field number."));
    field->set_number(number);
  }

  // Parse options.
  DO(ParseFieldOptions(field, field_location));

  // Deal with groups.
  if (field->has_type() && field->type() == FieldDescriptorProto::TYPE_GROUP) {
    // Awkward:  Since a group declares both a message type and a field, we
    //   have to create overlapping locations.
    LocationRecorder group_location(parent_location);
    group_location.StartAt(label_token);
    group_location.AddPath(location_field_number_for_nested_type);
    group_location.AddPath(messages->size());

    DescriptorProto* group = messages->Add();
    group->set_name(field->name());

    // Record name location to match the field name's location.
    {
      LocationRecorder location(group_location,
                                DescriptorProto::kNameFieldNumber);
      location.StartAt(name_token);
      location.EndAt(name_token);
      location.RecordLegacyLocation(
          group, DescriptorPool::ErrorCollector::NAME);
    }

    // The field's type_name also comes from the name.  Confusing!
    {
      LocationRecorder location(field_location,
                                FieldDescriptorProto::kTypeNameFieldNumber);
      location.StartAt(name_token);
      location.EndAt(name_token);
    }

    // As a hack for backwards-compatibility, we force the group name to start
    // with a capital letter and lower-case the field name.  New code should
    // not use groups; it should use nested messages.
    if (group->name()[0] < 'A' || 'Z' < group->name()[0]) {
      AddError(name_token.line, name_token.column,
        "Group names must start with a capital letter.");
    }
    LowerString(field->mutable_name());

    field->set_type_name(group->name());
    if (LookingAt("{")) {
      DO(ParseMessageBlock(group, group_location));
    } else {
      AddError("Missing group body.");
      return false;
    }
  } else {
    DO(ConsumeEndOfDeclaration(";", &field_location));
  }

  return true;
}

bool Parser::ParseFieldOptions(FieldDescriptorProto* field,
                               const LocationRecorder& field_location) {
  if (!LookingAt("[")) return true;

  LocationRecorder location(field_location,
                            FieldDescriptorProto::kOptionsFieldNumber);

  DO(Consume("["));

  // Parse field options.
  do {
    if (LookingAt("default")) {
      // We intentionally pass field_location rather than location here, since
      // the default value is not actually an option.
      DO(ParseDefaultAssignment(field, field_location));
    } else {
      DO(ParseOption(field->mutable_options(), location, OPTION_ASSIGNMENT));
    }
  } while (TryConsume(","));

  DO(Consume("]"));
  return true;
}

bool Parser::ParseDefaultAssignment(FieldDescriptorProto* field,
                                    const LocationRecorder& field_location) {
  if (field->has_default_value()) {
    AddError("Already set option \"default\".");
    field->clear_default_value();
  }

  DO(Consume("default"));
  DO(Consume("="));

  LocationRecorder location(field_location,
                            FieldDescriptorProto::kDefaultValueFieldNumber);
  location.RecordLegacyLocation(
      field, DescriptorPool::ErrorCollector::DEFAULT_VALUE);
  string* default_value = field->mutable_default_value();

  if (!field->has_type()) {
    // The field has a type name, but we don't know if it is a message or an
    // enum yet.  Assume an enum for now.
    DO(ConsumeIdentifier(default_value, "Expected identifier."));
    return true;
  }

  switch (field->type()) {
    case FieldDescriptorProto::TYPE_INT32:
    case FieldDescriptorProto::TYPE_INT64:
    case FieldDescriptorProto::TYPE_SINT32:
    case FieldDescriptorProto::TYPE_SINT64:
    case FieldDescriptorProto::TYPE_SFIXED32:
    case FieldDescriptorProto::TYPE_SFIXED64: {
      uint64 max_value = kint64max;
      if (field->type() == FieldDescriptorProto::TYPE_INT32 ||
          field->type() == FieldDescriptorProto::TYPE_SINT32 ||
          field->type() == FieldDescriptorProto::TYPE_SFIXED32) {
        max_value = kint32max;
      }

      // These types can be negative.
      if (TryConsume("-")) {
        default_value->append("-");
        // Two's complement always has one more negative value than positive.
        ++max_value;
      }
      // Parse the integer to verify that it is not out-of-range.
      uint64 value;
      DO(ConsumeInteger64(max_value, &value, "Expected integer."));
      // And stringify it again.
      default_value->append(SimpleItoa(value));
      break;
    }

    case FieldDescriptorProto::TYPE_UINT32:
    case FieldDescriptorProto::TYPE_UINT64:
    case FieldDescriptorProto::TYPE_FIXED32:
    case FieldDescriptorProto::TYPE_FIXED64: {
      uint64 max_value = kuint64max;
      if (field->type() == FieldDescriptorProto::TYPE_UINT32 ||
          field->type() == FieldDescriptorProto::TYPE_FIXED32) {
        max_value = kuint32max;
      }

      // Numeric, not negative.
      if (TryConsume("-")) {
        AddError("Unsigned field can't have negative default value.");
      }
      // Parse the integer to verify that it is not out-of-range.
      uint64 value;
      DO(ConsumeInteger64(max_value, &value, "Expected integer."));
      // And stringify it again.
      default_value->append(SimpleItoa(value));
      break;
    }

    case FieldDescriptorProto::TYPE_FLOAT:
    case FieldDescriptorProto::TYPE_DOUBLE:
      // These types can be negative.
      if (TryConsume("-")) {
        default_value->append("-");
      }
      // Parse the integer because we have to convert hex integers to decimal
      // floats.
      double value;
      DO(ConsumeNumber(&value, "Expected number."));
      // And stringify it again.
      default_value->append(SimpleDtoa(value));
      break;

    case FieldDescriptorProto::TYPE_BOOL:
      if (TryConsume("true")) {
        default_value->assign("true");
      } else if (TryConsume("false")) {
        default_value->assign("false");
      } else {
        AddError("Expected \"true\" or \"false\".");
        return false;
      }
      break;

    case FieldDescriptorProto::TYPE_STRING:
      DO(ConsumeString(default_value, "Expected string."));
      break;

    case FieldDescriptorProto::TYPE_BYTES:
      DO(ConsumeString(default_value, "Expected string."));
      *default_value = CEscape(*default_value);
      break;

    case FieldDescriptorProto::TYPE_ENUM:
      DO(ConsumeIdentifier(default_value, "Expected identifier."));
      break;

    case FieldDescriptorProto::TYPE_MESSAGE:
    case FieldDescriptorProto::TYPE_GROUP:
      AddError("Messages can't have default values.");
      return false;
  }

  return true;
}

bool Parser::ParseOptionNamePart(UninterpretedOption* uninterpreted_option,
                                 const LocationRecorder& part_location) {
  UninterpretedOption::NamePart* name = uninterpreted_option->add_name();
  string identifier;  // We parse identifiers into this string.
  if (LookingAt("(")) {  // This is an extension.
    DO(Consume("("));

    {
      LocationRecorder location(
          part_location, UninterpretedOption::NamePart::kNamePartFieldNumber);
      // An extension name consists of dot-separated identifiers, and may begin
      // with a dot.
      if (LookingAtType(io::Tokenizer::TYPE_IDENTIFIER)) {
        DO(ConsumeIdentifier(&identifier, "Expected identifier."));
        name->mutable_name_part()->append(identifier);
      }
      while (LookingAt(".")) {
        DO(Consume("."));
        name->mutable_name_part()->append(".");
        DO(ConsumeIdentifier(&identifier, "Expected identifier."));
        name->mutable_name_part()->append(identifier);
      }
    }

    DO(Consume(")"));
    name->set_is_extension(true);
  } else {  // This is a regular field.
    LocationRecorder location(
        part_location, UninterpretedOption::NamePart::kNamePartFieldNumber);
    DO(ConsumeIdentifier(&identifier, "Expected identifier."));
    name->mutable_name_part()->append(identifier);
    name->set_is_extension(false);
  }
  return true;
}

bool Parser::ParseUninterpretedBlock(string* value) {
  // Note that enclosing braces are not added to *value.
  // We do NOT use ConsumeEndOfStatement for this brace because it's delimiting
  // an expression, not a block of statements.
  DO(Consume("{"));
  int brace_depth = 1;
  while (!AtEnd()) {
    if (LookingAt("{")) {
      brace_depth++;
    } else if (LookingAt("}")) {
      brace_depth--;
      if (brace_depth == 0) {
        input_->Next();
        return true;
      }
    }
    // TODO(sanjay): Interpret line/column numbers to preserve formatting
    if (!value->empty()) value->push_back(' ');
    value->append(input_->current().text);
    input_->Next();
  }
  AddError("Unexpected end of stream while parsing aggregate value.");
  return false;
}

// We don't interpret the option here. Instead we store it in an
// UninterpretedOption, to be interpreted later.
bool Parser::ParseOption(Message* options,
                         const LocationRecorder& options_location,
                         OptionStyle style) {
  // Create an entry in the uninterpreted_option field.
  const FieldDescriptor* uninterpreted_option_field = options->GetDescriptor()->
      FindFieldByName("uninterpreted_option");
  GOOGLE_CHECK(uninterpreted_option_field != NULL)
      << "No field named \"uninterpreted_option\" in the Options proto.";

  const Reflection* reflection = options->GetReflection();

  LocationRecorder location(
      options_location, uninterpreted_option_field->number(),
      reflection->FieldSize(*options, uninterpreted_option_field));

  if (style == OPTION_STATEMENT) {
    DO(Consume("option"));
  }

  UninterpretedOption* uninterpreted_option = down_cast<UninterpretedOption*>(
      options->GetReflection()->AddMessage(options,
                                           uninterpreted_option_field));

  // Parse dot-separated name.
  {
    LocationRecorder name_location(location,
                                   UninterpretedOption::kNameFieldNumber);
    name_location.RecordLegacyLocation(
        uninterpreted_option, DescriptorPool::ErrorCollector::OPTION_NAME);

    {
      LocationRecorder part_location(name_location,
                                     uninterpreted_option->name_size());
      DO(ParseOptionNamePart(uninterpreted_option, part_location));
    }

    while (LookingAt(".")) {
      DO(Consume("."));
      LocationRecorder part_location(name_location,
                                     uninterpreted_option->name_size());
      DO(ParseOptionNamePart(uninterpreted_option, part_location));
    }
  }

  DO(Consume("="));

  {
    LocationRecorder value_location(location);
    value_location.RecordLegacyLocation(
        uninterpreted_option, DescriptorPool::ErrorCollector::OPTION_VALUE);

    // All values are a single token, except for negative numbers, which consist
    // of a single '-' symbol, followed by a positive number.
    bool is_negative = TryConsume("-");

    switch (input_->current().type) {
      case io::Tokenizer::TYPE_START:
        GOOGLE_LOG(FATAL) << "Trying to read value before any tokens have been read.";
        return false;

      case io::Tokenizer::TYPE_END:
        AddError("Unexpected end of stream while parsing option value.");
        return false;

      case io::Tokenizer::TYPE_IDENTIFIER: {
        value_location.AddPath(
            UninterpretedOption::kIdentifierValueFieldNumber);
        if (is_negative) {
          AddError("Invalid '-' symbol before identifier.");
          return false;
        }
        string value;
        DO(ConsumeIdentifier(&value, "Expected identifier."));
        uninterpreted_option->set_identifier_value(value);
        break;
      }

      case io::Tokenizer::TYPE_INTEGER: {
        uint64 value;
        uint64 max_value =
            is_negative ? static_cast<uint64>(kint64max) + 1 : kuint64max;
        DO(ConsumeInteger64(max_value, &value, "Expected integer."));
        if (is_negative) {
          value_location.AddPath(
              UninterpretedOption::kNegativeIntValueFieldNumber);
          uninterpreted_option->set_negative_int_value(
              -static_cast<int64>(value));
        } else {
          value_location.AddPath(
              UninterpretedOption::kPositiveIntValueFieldNumber);
          uninterpreted_option->set_positive_int_value(value);
        }
        break;
      }

      case io::Tokenizer::TYPE_FLOAT: {
        value_location.AddPath(UninterpretedOption::kDoubleValueFieldNumber);
        double value;
        DO(ConsumeNumber(&value, "Expected number."));
        uninterpreted_option->set_double_value(is_negative ? -value : value);
        break;
      }

      case io::Tokenizer::TYPE_STRING: {
        value_location.AddPath(UninterpretedOption::kStringValueFieldNumber);
        if (is_negative) {
          AddError("Invalid '-' symbol before string.");
          return false;
        }
        string value;
        DO(ConsumeString(&value, "Expected string."));
        uninterpreted_option->set_string_value(value);
        break;
      }

      case io::Tokenizer::TYPE_SYMBOL:
        if (LookingAt("{")) {
          value_location.AddPath(
              UninterpretedOption::kAggregateValueFieldNumber);
          DO(ParseUninterpretedBlock(
              uninterpreted_option->mutable_aggregate_value()));
        } else {
          AddError("Expected option value.");
          return false;
        }
        break;
    }
  }

  if (style == OPTION_STATEMENT) {
    DO(ConsumeEndOfDeclaration(";", &location));
  }

  return true;
}

bool Parser::ParseExtensions(DescriptorProto* message,
                             const LocationRecorder& extensions_location) {
  // Parse the declaration.
  DO(Consume("extensions"));

  do {
    // Note that kExtensionRangeFieldNumber was already pushed by the parent.
    LocationRecorder location(extensions_location,
                              message->extension_range_size());

    DescriptorProto::ExtensionRange* range = message->add_extension_range();
    location.RecordLegacyLocation(
        range, DescriptorPool::ErrorCollector::NUMBER);

    int start, end;
    io::Tokenizer::Token start_token;

    {
      LocationRecorder start_location(
          location, DescriptorProto::ExtensionRange::kStartFieldNumber);
      start_token = input_->current();
      DO(ConsumeInteger(&start, "Expected field number range."));
    }

    if (TryConsume("to")) {
      LocationRecorder end_location(
          location, DescriptorProto::ExtensionRange::kEndFieldNumber);
      if (TryConsume("max")) {
        // Set to the sentinel value - 1 since we increment the value below.
        // The actual value of the end of the range should be set with
        // AdjustExtensionRangesWithMaxEndNumber.
        end = kMaxExtensionRangeSentinel - 1;
      } else {
        DO(ConsumeInteger(&end, "Expected integer."));
      }
    } else {
      LocationRecorder end_location(
          location, DescriptorProto::ExtensionRange::kEndFieldNumber);
      end_location.StartAt(start_token);
      end_location.EndAt(start_token);
      end = start;
    }

    // Users like to specify inclusive ranges, but in code we like the end
    // number to be exclusive.
    ++end;

    range->set_start(start);
    range->set_end(end);
  } while (TryConsume(","));

  DO(ConsumeEndOfDeclaration(";", &extensions_location));
  return true;
}

bool Parser::ParseExtend(RepeatedPtrField<FieldDescriptorProto>* extensions,
                         RepeatedPtrField<DescriptorProto>* messages,
                         const LocationRecorder& parent_location,
                         int location_field_number_for_nested_type,
                         const LocationRecorder& extend_location) {
  DO(Consume("extend"));

  // Parse the extendee type.
  io::Tokenizer::Token extendee_start = input_->current();
  string extendee;
  DO(ParseUserDefinedType(&extendee));
  io::Tokenizer::Token extendee_end = input_->previous();

  // Parse the block.
  DO(ConsumeEndOfDeclaration("{", &extend_location));

  bool is_first = true;

  do {
    if (AtEnd()) {
      AddError("Reached end of input in extend definition (missing '}').");
      return false;
    }

    // Note that kExtensionFieldNumber was already pushed by the parent.
    LocationRecorder location(extend_location, extensions->size());

    FieldDescriptorProto* field = extensions->Add();

    {
      LocationRecorder extendee_location(
          location, FieldDescriptorProto::kExtendeeFieldNumber);
      extendee_location.StartAt(extendee_start);
      extendee_location.EndAt(extendee_end);

      if (is_first) {
        extendee_location.RecordLegacyLocation(
            field, DescriptorPool::ErrorCollector::EXTENDEE);
        is_first = false;
      }
    }

    field->set_extendee(extendee);

    if (!ParseMessageField(field, messages, parent_location,
                           location_field_number_for_nested_type,
                           location)) {
      // This statement failed to parse.  Skip it, but keep looping to parse
      // other statements.
      SkipStatement();
    }
  } while (!TryConsumeEndOfDeclaration("}", NULL));

  return true;
}

// -------------------------------------------------------------------
// Enums

bool Parser::ParseEnumDefinition(EnumDescriptorProto* enum_type,
                                 const LocationRecorder& enum_location) {
  DO(Consume("enum"));

  {
    LocationRecorder location(enum_location,
                              EnumDescriptorProto::kNameFieldNumber);
    location.RecordLegacyLocation(
        enum_type, DescriptorPool::ErrorCollector::NAME);
    DO(ConsumeIdentifier(enum_type->mutable_name(), "Expected enum name."));
  }

  DO(ParseEnumBlock(enum_type, enum_location));
  return true;
}

bool Parser::ParseEnumBlock(EnumDescriptorProto* enum_type,
                            const LocationRecorder& enum_location) {
  DO(ConsumeEndOfDeclaration("{", &enum_location));

  while (!TryConsumeEndOfDeclaration("}", NULL)) {
    if (AtEnd()) {
      AddError("Reached end of input in enum definition (missing '}').");
      return false;
    }

    if (!ParseEnumStatement(enum_type, enum_location)) {
      // This statement failed to parse.  Skip it, but keep looping to parse
      // other statements.
      SkipStatement();
    }
  }

  return true;
}

bool Parser::ParseEnumStatement(EnumDescriptorProto* enum_type,
                                const LocationRecorder& enum_location) {
  if (TryConsumeEndOfDeclaration(";", NULL)) {
    // empty statement; ignore
    return true;
  } else if (LookingAt("option")) {
    LocationRecorder location(enum_location,
                              EnumDescriptorProto::kOptionsFieldNumber);
    return ParseOption(enum_type->mutable_options(), location,
                       OPTION_STATEMENT);
  } else {
    LocationRecorder location(enum_location,
        EnumDescriptorProto::kValueFieldNumber, enum_type->value_size());
    return ParseEnumConstant(enum_type->add_value(), location);
  }
}

bool Parser::ParseEnumConstant(EnumValueDescriptorProto* enum_value,
                               const LocationRecorder& enum_value_location) {
  // Parse name.
  {
    LocationRecorder location(enum_value_location,
                              EnumValueDescriptorProto::kNameFieldNumber);
    location.RecordLegacyLocation(
        enum_value, DescriptorPool::ErrorCollector::NAME);
    DO(ConsumeIdentifier(enum_value->mutable_name(),
                         "Expected enum constant name."));
  }

  DO(Consume("=", "Missing numeric value for enum constant."));

  // Parse value.
  {
    LocationRecorder location(
        enum_value_location, EnumValueDescriptorProto::kNumberFieldNumber);
    location.RecordLegacyLocation(
        enum_value, DescriptorPool::ErrorCollector::NUMBER);

    int number;
    DO(ConsumeSignedInteger(&number, "Expected integer."));
    enum_value->set_number(number);
  }

  DO(ParseEnumConstantOptions(enum_value, enum_value_location));

  DO(ConsumeEndOfDeclaration(";", &enum_value_location));

  return true;
}

bool Parser::ParseEnumConstantOptions(
    EnumValueDescriptorProto* value,
    const LocationRecorder& enum_value_location) {
  if (!LookingAt("[")) return true;

  LocationRecorder location(
      enum_value_location, EnumValueDescriptorProto::kOptionsFieldNumber);

  DO(Consume("["));

  do {
    DO(ParseOption(value->mutable_options(), location, OPTION_ASSIGNMENT));
  } while (TryConsume(","));

  DO(Consume("]"));
  return true;
}

// -------------------------------------------------------------------
// Services

bool Parser::ParseServiceDefinition(ServiceDescriptorProto* service,
                                    const LocationRecorder& service_location) {
  DO(Consume("service"));

  {
    LocationRecorder location(service_location,
                              ServiceDescriptorProto::kNameFieldNumber);
    location.RecordLegacyLocation(
        service, DescriptorPool::ErrorCollector::NAME);
    DO(ConsumeIdentifier(service->mutable_name(), "Expected service name."));
  }

  DO(ParseServiceBlock(service, service_location));
  return true;
}

bool Parser::ParseServiceBlock(ServiceDescriptorProto* service,
                               const LocationRecorder& service_location) {
  DO(ConsumeEndOfDeclaration("{", &service_location));

  while (!TryConsumeEndOfDeclaration("}", NULL)) {
    if (AtEnd()) {
      AddError("Reached end of input in service definition (missing '}').");
      return false;
    }

    if (!ParseServiceStatement(service, service_location)) {
      // This statement failed to parse.  Skip it, but keep looping to parse
      // other statements.
      SkipStatement();
    }
  }

  return true;
}

bool Parser::ParseServiceStatement(ServiceDescriptorProto* service,
                                   const LocationRecorder& service_location) {
  if (TryConsumeEndOfDeclaration(";", NULL)) {
    // empty statement; ignore
    return true;
  } else if (LookingAt("option")) {
    LocationRecorder location(
        service_location, ServiceDescriptorProto::kOptionsFieldNumber);
    return ParseOption(service->mutable_options(), location, OPTION_STATEMENT);
  } else {
    LocationRecorder location(service_location,
        ServiceDescriptorProto::kMethodFieldNumber, service->method_size());
    return ParseServiceMethod(service->add_method(), location);
  }
}

bool Parser::ParseServiceMethod(MethodDescriptorProto* method,
                                const LocationRecorder& method_location) {
  DO(Consume("rpc"));

  {
    LocationRecorder location(method_location,
                              MethodDescriptorProto::kNameFieldNumber);
    location.RecordLegacyLocation(
        method, DescriptorPool::ErrorCollector::NAME);
    DO(ConsumeIdentifier(method->mutable_name(), "Expected method name."));
  }

  // Parse input type.
  DO(Consume("("));
  {
    LocationRecorder location(method_location,
                              MethodDescriptorProto::kInputTypeFieldNumber);
    location.RecordLegacyLocation(
        method, DescriptorPool::ErrorCollector::INPUT_TYPE);
    DO(ParseUserDefinedType(method->mutable_input_type()));
  }
  DO(Consume(")"));

  // Parse output type.
  DO(Consume("returns"));
  DO(Consume("("));
  {
    LocationRecorder location(method_location,
                              MethodDescriptorProto::kOutputTypeFieldNumber);
    location.RecordLegacyLocation(
        method, DescriptorPool::ErrorCollector::OUTPUT_TYPE);
    DO(ParseUserDefinedType(method->mutable_output_type()));
  }
  DO(Consume(")"));

  if (LookingAt("{")) {
    // Options!
    DO(ParseOptions(method_location,
                    MethodDescriptorProto::kOptionsFieldNumber,
                    method->mutable_options()));
  } else {
    DO(ConsumeEndOfDeclaration(";", &method_location));
  }

  return true;
}


bool Parser::ParseOptions(const LocationRecorder& parent_location,
                          const int optionsFieldNumber,
                          Message* mutable_options) {
  // Options!
  ConsumeEndOfDeclaration("{", &parent_location);
  while (!TryConsumeEndOfDeclaration("}", NULL)) {
    if (AtEnd()) {
      AddError("Reached end of input in method options (missing '}').");
      return false;
    }

    if (TryConsumeEndOfDeclaration(";", NULL)) {
      // empty statement; ignore
    } else {
      LocationRecorder location(parent_location,
                                optionsFieldNumber);
      if (!ParseOption(mutable_options, location, OPTION_STATEMENT)) {
        // This statement failed to parse.  Skip it, but keep looping to
        // parse other statements.
        SkipStatement();
      }
    }
  }

  return true;
}

// -------------------------------------------------------------------

bool Parser::ParseLabel(FieldDescriptorProto::Label* label) {
  if (TryConsume("optional")) {
    *label = FieldDescriptorProto::LABEL_OPTIONAL;
    return true;
  } else if (TryConsume("repeated")) {
    *label = FieldDescriptorProto::LABEL_REPEATED;
    return true;
  } else if (TryConsume("required")) {
    *label = FieldDescriptorProto::LABEL_REQUIRED;
    return true;
  } else {
    AddError("Expected \"required\", \"optional\", or \"repeated\".");
    // We can actually reasonably recover here by just assuming the user
    // forgot the label altogether.
    *label = FieldDescriptorProto::LABEL_OPTIONAL;
    return true;
  }
}

bool Parser::ParseType(FieldDescriptorProto::Type* type,
                       string* type_name) {
  TypeNameMap::const_iterator iter = kTypeNames.find(input_->current().text);
  if (iter != kTypeNames.end()) {
    *type = iter->second;
    input_->Next();
  } else {
    DO(ParseUserDefinedType(type_name));
  }
  return true;
}

bool Parser::ParseUserDefinedType(string* type_name) {
  type_name->clear();

  TypeNameMap::const_iterator iter = kTypeNames.find(input_->current().text);
  if (iter != kTypeNames.end()) {
    // Note:  The only place enum types are allowed is for field types, but
    //   if we are parsing a field type then we would not get here because
    //   primitives are allowed there as well.  So this error message doesn't
    //   need to account for enums.
    AddError("Expected message type.");

    // Pretend to accept this type so that we can go on parsing.
    *type_name = input_->current().text;
    input_->Next();
    return true;
  }

  // A leading "." means the name is fully-qualified.
  if (TryConsume(".")) type_name->append(".");

  // Consume the first part of the name.
  string identifier;
  DO(ConsumeIdentifier(&identifier, "Expected type name."));
  type_name->append(identifier);

  // Consume more parts.
  while (TryConsume(".")) {
    type_name->append(".");
    DO(ConsumeIdentifier(&identifier, "Expected identifier."));
    type_name->append(identifier);
  }

  return true;
}

// ===================================================================

bool Parser::ParsePackage(FileDescriptorProto* file,
                          const LocationRecorder& root_location) {
  if (file->has_package()) {
    AddError("Multiple package definitions.");
    // Don't append the new package to the old one.  Just replace it.  Not
    // that it really matters since this is an error anyway.
    file->clear_package();
  }

  DO(Consume("package"));

  {
    LocationRecorder location(root_location,
                              FileDescriptorProto::kPackageFieldNumber);
    location.RecordLegacyLocation(file, DescriptorPool::ErrorCollector::NAME);

    while (true) {
      string identifier;
      DO(ConsumeIdentifier(&identifier, "Expected identifier."));
      file->mutable_package()->append(identifier);
      if (!TryConsume(".")) break;
      file->mutable_package()->append(".");
    }

    location.EndAt(input_->previous());

    DO(ConsumeEndOfDeclaration(";", &location));
  }

  return true;
}

bool Parser::ParseImport(RepeatedPtrField<string>* dependency,
                         RepeatedField<int32>* public_dependency,
                         RepeatedField<int32>* weak_dependency,
                         const LocationRecorder& root_location) {
  DO(Consume("import"));
  if (LookingAt("public")) {
    LocationRecorder location(
        root_location, FileDescriptorProto::kPublicDependencyFieldNumber,
        public_dependency->size());
    DO(Consume("public"));
    *public_dependency->Add() = dependency->size();
  } else if (LookingAt("weak")) {
    LocationRecorder location(
        root_location, FileDescriptorProto::kWeakDependencyFieldNumber,
        weak_dependency->size());
    DO(Consume("weak"));
    *weak_dependency->Add() = dependency->size();
  }
  {
    LocationRecorder location(root_location,
                              FileDescriptorProto::kDependencyFieldNumber,
                              dependency->size());
    DO(ConsumeString(dependency->Add(),
      "Expected a string naming the file to import."));

    location.EndAt(input_->previous());

    DO(ConsumeEndOfDeclaration(";", &location));
  }
  return true;
}

// ===================================================================

SourceLocationTable::SourceLocationTable() {}
SourceLocationTable::~SourceLocationTable() {}

bool SourceLocationTable::Find(
    const Message* descriptor,
    DescriptorPool::ErrorCollector::ErrorLocation location,
    int* line, int* column) const {
  const pair<int, int>* result =
    FindOrNull(location_map_, make_pair(descriptor, location));
  if (result == NULL) {
    *line   = -1;
    *column = 0;
    return false;
  } else {
    *line   = result->first;
    *column = result->second;
    return true;
  }
}

void SourceLocationTable::Add(
    const Message* descriptor,
    DescriptorPool::ErrorCollector::ErrorLocation location,
    int line, int column) {
  location_map_[make_pair(descriptor, location)] = make_pair(line, column);
}

void SourceLocationTable::Clear() {
  location_map_.clear();
}

}  // namespace compiler
}  // namespace protobuf
}  // namespace google
