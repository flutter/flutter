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
// Implements parsing of .proto files to FileDescriptorProtos.

#ifndef GOOGLE_PROTOBUF_COMPILER_PARSER_H__
#define GOOGLE_PROTOBUF_COMPILER_PARSER_H__

#include <map>
#include <string>
#include <utility>
#include <google/protobuf/stubs/common.h>
#include <google/protobuf/descriptor.h>
#include <google/protobuf/descriptor.pb.h>
#include <google/protobuf/repeated_field.h>
#include <google/protobuf/io/tokenizer.h>

namespace google {
namespace protobuf { class Message; }

namespace protobuf {
namespace compiler {

// Defined in this file.
class Parser;
class SourceLocationTable;

// Implements parsing of protocol definitions (such as .proto files).
//
// Note that most users will be more interested in the Importer class.
// Parser is a lower-level class which simply converts a single .proto file
// to a FileDescriptorProto.  It does not resolve import directives or perform
// many other kinds of validation needed to construct a complete
// FileDescriptor.
class LIBPROTOBUF_EXPORT Parser {
 public:
  Parser();
  ~Parser();

  // Parse the entire input and construct a FileDescriptorProto representing
  // it.  Returns true if no errors occurred, false otherwise.
  bool Parse(io::Tokenizer* input, FileDescriptorProto* file);

  // Optional fetaures:

  // DEPRECATED:  New code should use the SourceCodeInfo embedded in the
  //   FileDescriptorProto.
  //
  // Requests that locations of certain definitions be recorded to the given
  // SourceLocationTable while parsing.  This can be used to look up exact line
  // and column numbers for errors reported by DescriptorPool during validation.
  // Set to NULL (the default) to discard source location information.
  void RecordSourceLocationsTo(SourceLocationTable* location_table) {
    source_location_table_ = location_table;
  }

  // Requests that errors be recorded to the given ErrorCollector while
  // parsing.  Set to NULL (the default) to discard error messages.
  void RecordErrorsTo(io::ErrorCollector* error_collector) {
    error_collector_ = error_collector;
  }

  // Returns the identifier used in the "syntax = " declaration, if one was
  // seen during the last call to Parse(), or the empty string otherwise.
  const string& GetSyntaxIdentifier() { return syntax_identifier_; }

  // If set true, input files will be required to begin with a syntax
  // identifier.  Otherwise, files may omit this.  If a syntax identifier
  // is provided, it must be 'syntax = "proto2";' and must appear at the
  // top of this file regardless of whether or not it was required.
  void SetRequireSyntaxIdentifier(bool value) {
    require_syntax_identifier_ = value;
  }

  // Call SetStopAfterSyntaxIdentifier(true) to tell the parser to stop
  // parsing as soon as it has seen the syntax identifier, or lack thereof.
  // This is useful for quickly identifying the syntax of the file without
  // parsing the whole thing.  If this is enabled, no error will be recorded
  // if the syntax identifier is something other than "proto2" (since
  // presumably the caller intends to deal with that), but other kinds of
  // errors (e.g. parse errors) will still be reported.  When this is enabled,
  // you may pass a NULL FileDescriptorProto to Parse().
  void SetStopAfterSyntaxIdentifier(bool value) {
    stop_after_syntax_identifier_ = value;
  }

 private:
  class LocationRecorder;

  // =================================================================
  // Error recovery helpers

  // Consume the rest of the current statement.  This consumes tokens
  // until it sees one of:
  //   ';'  Consumes the token and returns.
  //   '{'  Consumes the brace then calls SkipRestOfBlock().
  //   '}'  Returns without consuming.
  //   EOF  Returns (can't consume).
  // The Parser often calls SkipStatement() after encountering a syntax
  // error.  This allows it to go on parsing the following lines, allowing
  // it to report more than just one error in the file.
  void SkipStatement();

  // Consume the rest of the current block, including nested blocks,
  // ending after the closing '}' is encountered and consumed, or at EOF.
  void SkipRestOfBlock();

  // -----------------------------------------------------------------
  // Single-token consuming helpers
  //
  // These make parsing code more readable.

  // True if the current token is TYPE_END.
  inline bool AtEnd();

  // True if the next token matches the given text.
  inline bool LookingAt(const char* text);
  // True if the next token is of the given type.
  inline bool LookingAtType(io::Tokenizer::TokenType token_type);

  // If the next token exactly matches the text given, consume it and return
  // true.  Otherwise, return false without logging an error.
  bool TryConsume(const char* text);

  // These attempt to read some kind of token from the input.  If successful,
  // they return true.  Otherwise they return false and add the given error
  // to the error list.

  // Consume a token with the exact text given.
  bool Consume(const char* text, const char* error);
  // Same as above, but automatically generates the error "Expected \"text\".",
  // where "text" is the expected token text.
  bool Consume(const char* text);
  // Consume a token of type IDENTIFIER and store its text in "output".
  bool ConsumeIdentifier(string* output, const char* error);
  // Consume an integer and store its value in "output".
  bool ConsumeInteger(int* output, const char* error);
  // Consume a signed integer and store its value in "output".
  bool ConsumeSignedInteger(int* output, const char* error);
  // Consume a 64-bit integer and store its value in "output".  If the value
  // is greater than max_value, an error will be reported.
  bool ConsumeInteger64(uint64 max_value, uint64* output, const char* error);
  // Consume a number and store its value in "output".  This will accept
  // tokens of either INTEGER or FLOAT type.
  bool ConsumeNumber(double* output, const char* error);
  // Consume a string literal and store its (unescaped) value in "output".
  bool ConsumeString(string* output, const char* error);

  // Consume a token representing the end of the statement.  Comments between
  // this token and the next will be harvested for documentation.  The given
  // LocationRecorder should refer to the declaration that was just parsed;
  // it will be populated with these comments.
  //
  // TODO(kenton):  The LocationRecorder is const because historically locations
  //   have been passed around by const reference, for no particularly good
  //   reason.  We should probably go through and change them all to mutable
  //   pointer to make this more intuitive.
  bool TryConsumeEndOfDeclaration(const char* text,
                                  const LocationRecorder* location);
  bool ConsumeEndOfDeclaration(const char* text,
                               const LocationRecorder* location);

  // -----------------------------------------------------------------
  // Error logging helpers

  // Invokes error_collector_->AddError(), if error_collector_ is not NULL.
  void AddError(int line, int column, const string& error);

  // Invokes error_collector_->AddError() with the line and column number
  // of the current token.
  void AddError(const string& error);

  // Records a location in the SourceCodeInfo.location table (see
  // descriptor.proto).  We use RAII to ensure that the start and end locations
  // are recorded -- the constructor records the start location and the
  // destructor records the end location.  Since the parser is
  // recursive-descent, this works out beautifully.
  class LIBPROTOBUF_EXPORT LocationRecorder {
   public:
    // Construct the file's "root" location.
    LocationRecorder(Parser* parser);

    // Construct a location that represents a declaration nested within the
    // given parent.  E.g. a field's location is nested within the location
    // for a message type.  The parent's path will be copied, so you should
    // call AddPath() only to add the path components leading from the parent
    // to the child (as opposed to leading from the root to the child).
    LocationRecorder(const LocationRecorder& parent);

    // Convenience constructors that call AddPath() one or two times.
    LocationRecorder(const LocationRecorder& parent, int path1);
    LocationRecorder(const LocationRecorder& parent, int path1, int path2);

    ~LocationRecorder();

    // Add a path component.  See SourceCodeInfo.Location.path in
    // descriptor.proto.
    void AddPath(int path_component);

    // By default the location is considered to start at the current token at
    // the time the LocationRecorder is created.  StartAt() sets the start
    // location to the given token instead.
    void StartAt(const io::Tokenizer::Token& token);

    // By default the location is considered to end at the previous token at
    // the time the LocationRecorder is destroyed.  EndAt() sets the end
    // location to the given token instead.
    void EndAt(const io::Tokenizer::Token& token);

    // Records the start point of this location to the SourceLocationTable that
    // was passed to RecordSourceLocationsTo(), if any.  SourceLocationTable
    // is an older way of keeping track of source locations which is still
    // used in some places.
    void RecordLegacyLocation(const Message* descriptor,
        DescriptorPool::ErrorCollector::ErrorLocation location);

    // Attaches leading and trailing comments to the location.  The two strings
    // will be swapped into place, so after this is called *leading and
    // *trailing will be empty.
    //
    // TODO(kenton):  See comment on TryConsumeEndOfDeclaration(), above, for
    //   why this is const.
    void AttachComments(string* leading, string* trailing) const;

   private:
    Parser* parser_;
    SourceCodeInfo::Location* location_;

    void Init(const LocationRecorder& parent);
  };

  // =================================================================
  // Parsers for various language constructs

  // Parses the "syntax = \"proto2\";" line at the top of the file.  Returns
  // false if it failed to parse or if the syntax identifier was not
  // recognized.
  bool ParseSyntaxIdentifier();

  // These methods parse various individual bits of code.  They return
  // false if they completely fail to parse the construct.  In this case,
  // it is probably necessary to skip the rest of the statement to recover.
  // However, if these methods return true, it does NOT mean that there
  // were no errors; only that there were no *syntax* errors.  For instance,
  // if a service method is defined using proper syntax but uses a primitive
  // type as its input or output, ParseMethodField() still returns true
  // and only reports the error by calling AddError().  In practice, this
  // makes logic much simpler for the caller.

  // Parse a top-level message, enum, service, etc.
  bool ParseTopLevelStatement(FileDescriptorProto* file,
                              const LocationRecorder& root_location);

  // Parse various language high-level language construrcts.
  bool ParseMessageDefinition(DescriptorProto* message,
                              const LocationRecorder& message_location);
  bool ParseEnumDefinition(EnumDescriptorProto* enum_type,
                           const LocationRecorder& enum_location);
  bool ParseServiceDefinition(ServiceDescriptorProto* service,
                              const LocationRecorder& service_location);
  bool ParsePackage(FileDescriptorProto* file,
                    const LocationRecorder& root_location);
  bool ParseImport(RepeatedPtrField<string>* dependency,
                   RepeatedField<int32>* public_dependency,
                   RepeatedField<int32>* weak_dependency,
                   const LocationRecorder& root_location);
  bool ParseOption(Message* options,
                   const LocationRecorder& options_location);

  // These methods parse the contents of a message, enum, or service type and
  // add them to the given object.  They consume the entire block including
  // the beginning and ending brace.
  bool ParseMessageBlock(DescriptorProto* message,
                         const LocationRecorder& message_location);
  bool ParseEnumBlock(EnumDescriptorProto* enum_type,
                      const LocationRecorder& enum_location);
  bool ParseServiceBlock(ServiceDescriptorProto* service,
                         const LocationRecorder& service_location);

  // Parse one statement within a message, enum, or service block, inclunding
  // final semicolon.
  bool ParseMessageStatement(DescriptorProto* message,
                             const LocationRecorder& message_location);
  bool ParseEnumStatement(EnumDescriptorProto* message,
                          const LocationRecorder& enum_location);
  bool ParseServiceStatement(ServiceDescriptorProto* message,
                             const LocationRecorder& service_location);

  // Parse a field of a message.  If the field is a group, its type will be
  // added to "messages".
  //
  // parent_location and location_field_number_for_nested_type are needed when
  // parsing groups -- we need to generate a nested message type within the
  // parent and record its location accordingly.  Since the parent could be
  // either a FileDescriptorProto or a DescriptorProto, we must pass in the
  // correct field number to use.
  bool ParseMessageField(FieldDescriptorProto* field,
                         RepeatedPtrField<DescriptorProto>* messages,
                         const LocationRecorder& parent_location,
                         int location_field_number_for_nested_type,
                         const LocationRecorder& field_location);

  // Parse an "extensions" declaration.
  bool ParseExtensions(DescriptorProto* message,
                       const LocationRecorder& extensions_location);

  // Parse an "extend" declaration.  (See also comments for
  // ParseMessageField().)
  bool ParseExtend(RepeatedPtrField<FieldDescriptorProto>* extensions,
                   RepeatedPtrField<DescriptorProto>* messages,
                   const LocationRecorder& parent_location,
                   int location_field_number_for_nested_type,
                   const LocationRecorder& extend_location);

  // Parse a single enum value within an enum block.
  bool ParseEnumConstant(EnumValueDescriptorProto* enum_value,
                         const LocationRecorder& enum_value_location);

  // Parse enum constant options, i.e. the list in square brackets at the end
  // of the enum constant value definition.
  bool ParseEnumConstantOptions(EnumValueDescriptorProto* value,
                                const LocationRecorder& enum_value_location);

  // Parse a single method within a service definition.
  bool ParseServiceMethod(MethodDescriptorProto* method,
                          const LocationRecorder& method_location);


  // Parse options of a single method or stream.
  bool ParseOptions(const LocationRecorder& parent_location,
                    const int optionsFieldNumber,
                    Message* mutable_options);

  // Parse "required", "optional", or "repeated" and fill in "label"
  // with the value.
  bool ParseLabel(FieldDescriptorProto::Label* label);

  // Parse a type name and fill in "type" (if it is a primitive) or
  // "type_name" (if it is not) with the type parsed.
  bool ParseType(FieldDescriptorProto::Type* type,
                 string* type_name);
  // Parse a user-defined type and fill in "type_name" with the name.
  // If a primitive type is named, it is treated as an error.
  bool ParseUserDefinedType(string* type_name);

  // Parses field options, i.e. the stuff in square brackets at the end
  // of a field definition.  Also parses default value.
  bool ParseFieldOptions(FieldDescriptorProto* field,
                         const LocationRecorder& field_location);

  // Parse the "default" option.  This needs special handling because its
  // type is the field's type.
  bool ParseDefaultAssignment(FieldDescriptorProto* field,
                              const LocationRecorder& field_location);

  enum OptionStyle {
    OPTION_ASSIGNMENT,  // just "name = value"
    OPTION_STATEMENT    // "option name = value;"
  };

  // Parse a single option name/value pair, e.g. "ctype = CORD".  The name
  // identifies a field of the given Message, and the value of that field
  // is set to the parsed value.
  bool ParseOption(Message* options,
                   const LocationRecorder& options_location,
                   OptionStyle style);

  // Parses a single part of a multipart option name. A multipart name consists
  // of names separated by dots. Each name is either an identifier or a series
  // of identifiers separated by dots and enclosed in parentheses. E.g.,
  // "foo.(bar.baz).qux".
  bool ParseOptionNamePart(UninterpretedOption* uninterpreted_option,
                           const LocationRecorder& part_location);

  // Parses a string surrounded by balanced braces.  Strips off the outer
  // braces and stores the enclosed string in *value.
  // E.g.,
  //     { foo }                     *value gets 'foo'
  //     { foo { bar: box } }        *value gets 'foo { bar: box }'
  //     {}                          *value gets ''
  //
  // REQUIRES: LookingAt("{")
  // When finished successfully, we are looking at the first token past
  // the ending brace.
  bool ParseUninterpretedBlock(string* value);

  // =================================================================

  io::Tokenizer* input_;
  io::ErrorCollector* error_collector_;
  SourceCodeInfo* source_code_info_;
  SourceLocationTable* source_location_table_;  // legacy
  bool had_errors_;
  bool require_syntax_identifier_;
  bool stop_after_syntax_identifier_;
  string syntax_identifier_;

  // Leading doc comments for the next declaration.  These are not complete
  // yet; use ConsumeEndOfDeclaration() to get the complete comments.
  string upcoming_doc_comments_;

  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(Parser);
};

// A table mapping (descriptor, ErrorLocation) pairs -- as reported by
// DescriptorPool when validating descriptors -- to line and column numbers
// within the original source code.
//
// This is semi-obsolete:  FileDescriptorProto.source_code_info now contains
// far more complete information about source locations.  However, as of this
// writing you still need to use SourceLocationTable when integrating with
// DescriptorPool.
class LIBPROTOBUF_EXPORT SourceLocationTable {
 public:
  SourceLocationTable();
  ~SourceLocationTable();

  // Finds the precise location of the given error and fills in *line and
  // *column with the line and column numbers.  If not found, sets *line to
  // -1 and *column to 0 (since line = -1 is used to mean "error has no exact
  // location" in the ErrorCollector interface).  Returns true if found, false
  // otherwise.
  bool Find(const Message* descriptor,
            DescriptorPool::ErrorCollector::ErrorLocation location,
            int* line, int* column) const;

  // Adds a location to the table.
  void Add(const Message* descriptor,
           DescriptorPool::ErrorCollector::ErrorLocation location,
           int line, int column);

  // Clears the contents of the table.
  void Clear();

 private:
  typedef map<
    pair<const Message*, DescriptorPool::ErrorCollector::ErrorLocation>,
    pair<int, int> > LocationMap;
  LocationMap location_map_;
};

}  // namespace compiler
}  // namespace protobuf

}  // namespace google
#endif  // GOOGLE_PROTOBUF_COMPILER_PARSER_H__
