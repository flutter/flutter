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

// Author: jschorr@google.com (Joseph Schorr)
//  Based on original Protocol Buffers design by
//  Sanjay Ghemawat, Jeff Dean, and others.
//
// Utilities for printing and parsing protocol messages in a human-readable,
// text-based format.

#ifndef GOOGLE_PROTOBUF_TEXT_FORMAT_H__
#define GOOGLE_PROTOBUF_TEXT_FORMAT_H__

#include <map>
#include <string>
#include <vector>
#include <google/protobuf/stubs/common.h>
#include <google/protobuf/message.h>
#include <google/protobuf/descriptor.h>

namespace google {
namespace protobuf {

namespace io {
  class ErrorCollector;      // tokenizer.h
}

// This class implements protocol buffer text format.  Printing and parsing
// protocol messages in text format is useful for debugging and human editing
// of messages.
//
// This class is really a namespace that contains only static methods.
class LIBPROTOBUF_EXPORT TextFormat {
 public:
  // Outputs a textual representation of the given message to the given
  // output stream.
  static bool Print(const Message& message, io::ZeroCopyOutputStream* output);

  // Print the fields in an UnknownFieldSet.  They are printed by tag number
  // only.  Embedded messages are heuristically identified by attempting to
  // parse them.
  static bool PrintUnknownFields(const UnknownFieldSet& unknown_fields,
                                 io::ZeroCopyOutputStream* output);

  // Like Print(), but outputs directly to a string.
  static bool PrintToString(const Message& message, string* output);

  // Like PrintUnknownFields(), but outputs directly to a string.
  static bool PrintUnknownFieldsToString(const UnknownFieldSet& unknown_fields,
                                         string* output);

  // Outputs a textual representation of the value of the field supplied on
  // the message supplied. For non-repeated fields, an index of -1 must
  // be supplied. Note that this method will print the default value for a
  // field if it is not set.
  static void PrintFieldValueToString(const Message& message,
                                      const FieldDescriptor* field,
                                      int index,
                                      string* output);

  // Class for those users which require more fine-grained control over how
  // a protobuffer message is printed out.
  class LIBPROTOBUF_EXPORT Printer {
   public:
    Printer();
    ~Printer();

    // Like TextFormat::Print
    bool Print(const Message& message, io::ZeroCopyOutputStream* output) const;
    // Like TextFormat::PrintUnknownFields
    bool PrintUnknownFields(const UnknownFieldSet& unknown_fields,
                            io::ZeroCopyOutputStream* output) const;
    // Like TextFormat::PrintToString
    bool PrintToString(const Message& message, string* output) const;
    // Like TextFormat::PrintUnknownFieldsToString
    bool PrintUnknownFieldsToString(const UnknownFieldSet& unknown_fields,
                                    string* output) const;
    // Like TextFormat::PrintFieldValueToString
    void PrintFieldValueToString(const Message& message,
                                 const FieldDescriptor* field,
                                 int index,
                                 string* output) const;

    // Adjust the initial indent level of all output.  Each indent level is
    // equal to two spaces.
    void SetInitialIndentLevel(int indent_level) {
      initial_indent_level_ = indent_level;
    }

    // If printing in single line mode, then the entire message will be output
    // on a single line with no line breaks.
    void SetSingleLineMode(bool single_line_mode) {
      single_line_mode_ = single_line_mode;
    }

    // Set true to print repeated primitives in a format like:
    //   field_name: [1, 2, 3, 4]
    // instead of printing each value on its own line.  Short format applies
    // only to primitive values -- i.e. everything except strings and
    // sub-messages/groups.
    void SetUseShortRepeatedPrimitives(bool use_short_repeated_primitives) {
      use_short_repeated_primitives_ = use_short_repeated_primitives;
    }

    // Set true to output UTF-8 instead of ASCII.  The only difference
    // is that bytes >= 0x80 in string fields will not be escaped,
    // because they are assumed to be part of UTF-8 multi-byte
    // sequences.
    void SetUseUtf8StringEscaping(bool as_utf8) {
      utf8_string_escaping_ = as_utf8;
    }

   private:
    // Forward declaration of an internal class used to print the text
    // output to the OutputStream (see text_format.cc for implementation).
    class TextGenerator;

    // Internal Print method, used for writing to the OutputStream via
    // the TextGenerator class.
    void Print(const Message& message,
               TextGenerator& generator) const;

    // Print a single field.
    void PrintField(const Message& message,
                    const Reflection* reflection,
                    const FieldDescriptor* field,
                    TextGenerator& generator) const;

    // Print a repeated primitive field in short form.
    void PrintShortRepeatedField(const Message& message,
                                 const Reflection* reflection,
                                 const FieldDescriptor* field,
                                 TextGenerator& generator) const;

    // Print the name of a field -- i.e. everything that comes before the
    // ':' for a single name/value pair.
    void PrintFieldName(const Message& message,
                        const Reflection* reflection,
                        const FieldDescriptor* field,
                        TextGenerator& generator) const;

    // Outputs a textual representation of the value of the field supplied on
    // the message supplied or the default value if not set.
    void PrintFieldValue(const Message& message,
                         const Reflection* reflection,
                         const FieldDescriptor* field,
                         int index,
                         TextGenerator& generator) const;

    // Print the fields in an UnknownFieldSet.  They are printed by tag number
    // only.  Embedded messages are heuristically identified by attempting to
    // parse them.
    void PrintUnknownFields(const UnknownFieldSet& unknown_fields,
                            TextGenerator& generator) const;

    int initial_indent_level_;

    bool single_line_mode_;

    bool use_short_repeated_primitives_;

    bool utf8_string_escaping_;
  };

  // Parses a text-format protocol message from the given input stream to
  // the given message object.  This function parses the format written
  // by Print().
  static bool Parse(io::ZeroCopyInputStream* input, Message* output);
  // Like Parse(), but reads directly from a string.
  static bool ParseFromString(const string& input, Message* output);

  // Like Parse(), but the data is merged into the given message, as if
  // using Message::MergeFrom().
  static bool Merge(io::ZeroCopyInputStream* input, Message* output);
  // Like Merge(), but reads directly from a string.
  static bool MergeFromString(const string& input, Message* output);

  // Parse the given text as a single field value and store it into the
  // given field of the given message. If the field is a repeated field,
  // the new value will be added to the end
  static bool ParseFieldValueFromString(const string& input,
                                        const FieldDescriptor* field,
                                        Message* message);

  // Interface that TextFormat::Parser can use to find extensions.
  // This class may be extended in the future to find more information
  // like fields, etc.
  class LIBPROTOBUF_EXPORT Finder {
   public:
    virtual ~Finder();

    // Try to find an extension of *message by fully-qualified field
    // name.  Returns NULL if no extension is known for this name or number.
    virtual const FieldDescriptor* FindExtension(
        Message* message,
        const string& name) const = 0;
  };

  // A location in the parsed text.
  struct ParseLocation {
    int line;
    int column;

    ParseLocation() : line(-1), column(-1) {}
    ParseLocation(int line_param, int column_param)
        : line(line_param), column(column_param) {}
  };

  // Data structure which is populated with the locations of each field
  // value parsed from the text.
  class LIBPROTOBUF_EXPORT ParseInfoTree {
   public:
    ParseInfoTree();
    ~ParseInfoTree();

    // Returns the parse location for index-th value of the field in the parsed
    // text. If none exists, returns a location with line = -1. Index should be
    // -1 for not-repeated fields.
    ParseLocation GetLocation(const FieldDescriptor* field, int index) const;

    // Returns the parse info tree for the given field, which must be a message
    // type. The nested information tree is owned by the root tree and will be
    // deleted when it is deleted.
    ParseInfoTree* GetTreeForNested(const FieldDescriptor* field,
                                    int index) const;

   private:
    // Allow the text format parser to record information into the tree.
    friend class TextFormat;

    // Records the starting location of a single value for a field.
    void RecordLocation(const FieldDescriptor* field, ParseLocation location);

    // Create and records a nested tree for a nested message field.
    ParseInfoTree* CreateNested(const FieldDescriptor* field);

    // Defines the map from the index-th field descriptor to its parse location.
    typedef map<const FieldDescriptor*, vector<ParseLocation> > LocationMap;

    // Defines the map from the index-th field descriptor to the nested parse
    // info tree.
    typedef map<const FieldDescriptor*, vector<ParseInfoTree*> > NestedMap;

    LocationMap locations_;
    NestedMap nested_;

    GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(ParseInfoTree);
  };

  // For more control over parsing, use this class.
  class LIBPROTOBUF_EXPORT Parser {
   public:
    Parser();
    ~Parser();

    // Like TextFormat::Parse().
    bool Parse(io::ZeroCopyInputStream* input, Message* output);
    // Like TextFormat::ParseFromString().
    bool ParseFromString(const string& input, Message* output);
    // Like TextFormat::Merge().
    bool Merge(io::ZeroCopyInputStream* input, Message* output);
    // Like TextFormat::MergeFromString().
    bool MergeFromString(const string& input, Message* output);

    // Set where to report parse errors.  If NULL (the default), errors will
    // be printed to stderr.
    void RecordErrorsTo(io::ErrorCollector* error_collector) {
      error_collector_ = error_collector;
    }

    // Set how parser finds extensions.  If NULL (the default), the
    // parser will use the standard Reflection object associated with
    // the message being parsed.
    void SetFinder(Finder* finder) {
      finder_ = finder;
    }

    // Sets where location information about the parse will be written. If NULL
    // (the default), then no location will be written.
    void WriteLocationsTo(ParseInfoTree* tree) {
      parse_info_tree_ = tree;
    }

    // Normally parsing fails if, after parsing, output->IsInitialized()
    // returns false.  Call AllowPartialMessage(true) to skip this check.
    void AllowPartialMessage(bool allow) {
      allow_partial_ = allow;
    }

    // Like TextFormat::ParseFieldValueFromString
    bool ParseFieldValueFromString(const string& input,
                                   const FieldDescriptor* field,
                                   Message* output);


   private:
    // Forward declaration of an internal class used to parse text
    // representations (see text_format.cc for implementation).
    class ParserImpl;

    // Like TextFormat::Merge().  The provided implementation is used
    // to do the parsing.
    bool MergeUsingImpl(io::ZeroCopyInputStream* input,
                        Message* output,
                        ParserImpl* parser_impl);

    io::ErrorCollector* error_collector_;
    Finder* finder_;
    ParseInfoTree* parse_info_tree_;
    bool allow_partial_;
    bool allow_unknown_field_;
  };

 private:
  // Hack: ParseInfoTree declares TextFormat as a friend which should extend
  // the friendship to TextFormat::Parser::ParserImpl, but unfortunately some
  // old compilers (e.g. GCC 3.4.6) don't implement this correctly. We provide
  // helpers for ParserImpl to call methods of ParseInfoTree.
  static inline void RecordLocation(ParseInfoTree* info_tree,
                                    const FieldDescriptor* field,
                                    ParseLocation location);
  static inline ParseInfoTree* CreateNested(ParseInfoTree* info_tree,
                                            const FieldDescriptor* field);

  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(TextFormat);
};

inline void TextFormat::RecordLocation(ParseInfoTree* info_tree,
                                       const FieldDescriptor* field,
                                       ParseLocation location) {
  info_tree->RecordLocation(field, location);
}

inline TextFormat::ParseInfoTree* TextFormat::CreateNested(
    ParseInfoTree* info_tree, const FieldDescriptor* field) {
  return info_tree->CreateNested(field);
}

}  // namespace protobuf

}  // namespace google
#endif  // GOOGLE_PROTOBUF_TEXT_FORMAT_H__
