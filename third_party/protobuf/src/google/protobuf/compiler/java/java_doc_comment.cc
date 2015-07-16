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

#include <google/protobuf/compiler/java/java_doc_comment.h>

#include <vector>

#include <google/protobuf/io/printer.h>
#include <google/protobuf/stubs/strutil.h>

namespace google {
namespace protobuf {
namespace compiler {
namespace java {

string EscapeJavadoc(const string& input) {
  string result;
  result.reserve(input.size() * 2);

  char prev = '*';

  for (string::size_type i = 0; i < input.size(); i++) {
    char c = input[i];
    switch (c) {
      case '*':
        // Avoid "/*".
        if (prev == '/') {
          result.append("&#42;");
        } else {
          result.push_back(c);
        }
        break;
      case '/':
        // Avoid "*/".
        if (prev == '*') {
          result.append("&#47;");
        } else {
          result.push_back(c);
        }
        break;
      case '@':
        // "{@" starts Javadoc markup.
        if (prev == '{') {
          result.append("&#64;");
        } else {
          result.push_back(c);
        }
        break;
      case '<':
        // Avoid interpretation as HTML.
        result.append("&lt;");
        break;
      case '>':
        // Avoid interpretation as HTML.
        result.append("&gt;");
        break;
      case '&':
        // Avoid interpretation as HTML.
        result.append("&amp;");
        break;
      case '\\':
        // Java interprets Unicode escape sequences anywhere!
        result.append("&#92;");
        break;
      default:
        result.push_back(c);
        break;
    }

    prev = c;
  }

  return result;
}

static void WriteDocCommentBodyForLocation(
    io::Printer* printer, const SourceLocation& location) {
  string comments = location.leading_comments.empty() ?
      location.trailing_comments : location.leading_comments;
  if (!comments.empty()) {
    // TODO(kenton):  Ideally we should parse the comment text as Markdown and
    //   write it back as HTML, but this requires a Markdown parser.  For now
    //   we just use <pre> to get fixed-width text formatting.

    // If the comment itself contains block comment start or end markers,
    // HTML-escape them so that they don't accidentally close the doc comment.
    comments = EscapeJavadoc(comments);

    vector<string> lines;
    SplitStringAllowEmpty(comments, "\n", &lines);
    while (!lines.empty() && lines.back().empty()) {
      lines.pop_back();
    }

    printer->Print(
        " *\n"
        " * <pre>\n");
    for (int i = 0; i < lines.size(); i++) {
      // Most lines should start with a space.  Watch out for lines that start
      // with a /, since putting that right after the leading asterisk will
      // close the comment.
      if (!lines[i].empty() && lines[i][0] == '/') {
        printer->Print(" * $line$\n", "line", lines[i]);
      } else {
        printer->Print(" *$line$\n", "line", lines[i]);
      }
    }
    printer->Print(" * </pre>\n");
  }
}

template <typename DescriptorType>
static void WriteDocCommentBody(
    io::Printer* printer, const DescriptorType* descriptor) {
  SourceLocation location;
  if (descriptor->GetSourceLocation(&location)) {
    WriteDocCommentBodyForLocation(printer, location);
  }
}

static string FirstLineOf(const string& value) {
  string result = value;

  string::size_type pos = result.find_first_of('\n');
  if (pos != string::npos) {
    result.erase(pos);
  }

  // If line ends in an opening brace, make it "{ ... }" so it looks nice.
  if (!result.empty() && result[result.size() - 1] == '{') {
    result.append(" ... }");
  }

  return result;
}

void WriteMessageDocComment(io::Printer* printer, const Descriptor* message) {
  printer->Print(
    "/**\n"
    " * Protobuf type {@code $fullname$}\n",
    "fullname", EscapeJavadoc(message->full_name()));
  WriteDocCommentBody(printer, message);
  printer->Print(" */\n");
}

void WriteFieldDocComment(io::Printer* printer, const FieldDescriptor* field) {
  // In theory we should have slightly different comments for setters, getters,
  // etc., but in practice everyone already knows the difference between these
  // so it's redundant information.

  // We use the field declaration as the first line of the comment, e.g.:
  //   optional string foo = 5;
  // This communicates a lot of information about the field in a small space.
  // If the field is a group, the debug string might end with {.
  printer->Print(
    "/**\n"
    " * <code>$def$</code>\n",
    "def", EscapeJavadoc(FirstLineOf(field->DebugString())));
  WriteDocCommentBody(printer, field);
  printer->Print(" */\n");
}

void WriteEnumDocComment(io::Printer* printer, const EnumDescriptor* enum_) {
  printer->Print(
    "/**\n"
    " * Protobuf enum {@code $fullname$}\n",
    "fullname", EscapeJavadoc(enum_->full_name()));
  WriteDocCommentBody(printer, enum_);
  printer->Print(" */\n");
}

void WriteEnumValueDocComment(io::Printer* printer,
                              const EnumValueDescriptor* value) {
  printer->Print(
    "/**\n"
    " * <code>$def$</code>\n",
    "def", EscapeJavadoc(FirstLineOf(value->DebugString())));
  WriteDocCommentBody(printer, value);
  printer->Print(" */\n");
}

void WriteServiceDocComment(io::Printer* printer,
                            const ServiceDescriptor* service) {
  printer->Print(
    "/**\n"
    " * Protobuf service {@code $fullname$}\n",
    "fullname", EscapeJavadoc(service->full_name()));
  WriteDocCommentBody(printer, service);
  printer->Print(" */\n");
}

void WriteMethodDocComment(io::Printer* printer,
                           const MethodDescriptor* method) {
  printer->Print(
    "/**\n"
    " * <code>$def$</code>\n",
    "def", EscapeJavadoc(FirstLineOf(method->DebugString())));
  WriteDocCommentBody(printer, method);
  printer->Print(" */\n");
}

}  // namespace java
}  // namespace compiler
}  // namespace protobuf
}  // namespace google
