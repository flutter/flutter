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

#include <limits>
#include <map>
#include <vector>
#include <google/protobuf/stubs/hash.h>

#include <google/protobuf/compiler/cpp/cpp_helpers.h>
#include <google/protobuf/io/printer.h>
#include <google/protobuf/stubs/common.h>
#include <google/protobuf/stubs/strutil.h>
#include <google/protobuf/stubs/substitute.h>


namespace google {
namespace protobuf {
namespace compiler {
namespace cpp {

namespace {

string DotsToUnderscores(const string& name) {
  return StringReplace(name, ".", "_", true);
}

string DotsToColons(const string& name) {
  return StringReplace(name, ".", "::", true);
}

const char* const kKeywordList[] = {
  "and", "and_eq", "asm", "auto", "bitand", "bitor", "bool", "break", "case",
  "catch", "char", "class", "compl", "const", "const_cast", "continue",
  "default", "delete", "do", "double", "dynamic_cast", "else", "enum",
  "explicit", "extern", "false", "float", "for", "friend", "goto", "if",
  "inline", "int", "long", "mutable", "namespace", "new", "not", "not_eq",
  "operator", "or", "or_eq", "private", "protected", "public", "register",
  "reinterpret_cast", "return", "short", "signed", "sizeof", "static",
  "static_cast", "struct", "switch", "template", "this", "throw", "true", "try",
  "typedef", "typeid", "typename", "union", "unsigned", "using", "virtual",
  "void", "volatile", "wchar_t", "while", "xor", "xor_eq"
};

hash_set<string> MakeKeywordsMap() {
  hash_set<string> result;
  for (int i = 0; i < GOOGLE_ARRAYSIZE(kKeywordList); i++) {
    result.insert(kKeywordList[i]);
  }
  return result;
}

hash_set<string> kKeywords = MakeKeywordsMap();

string UnderscoresToCamelCase(const string& input, bool cap_next_letter) {
  string result;
  // Note:  I distrust ctype.h due to locales.
  for (int i = 0; i < input.size(); i++) {
    if ('a' <= input[i] && input[i] <= 'z') {
      if (cap_next_letter) {
        result += input[i] + ('A' - 'a');
      } else {
        result += input[i];
      }
      cap_next_letter = false;
    } else if ('A' <= input[i] && input[i] <= 'Z') {
      // Capital letters are left as-is.
      result += input[i];
      cap_next_letter = false;
    } else if ('0' <= input[i] && input[i] <= '9') {
      result += input[i];
      cap_next_letter = true;
    } else {
      cap_next_letter = true;
    }
  }
  return result;
}

// Returns whether the provided descriptor has an extension. This includes its
// nested types.
bool HasExtension(const Descriptor* descriptor) {
  if (descriptor->extension_count() > 0) {
    return true;
  }
  for (int i = 0; i < descriptor->nested_type_count(); ++i) {
    if (HasExtension(descriptor->nested_type(i))) {
      return true;
    }
  }
  return false;
}

}  // namespace

const char kThickSeparator[] =
  "// ===================================================================\n";
const char kThinSeparator[] =
  "// -------------------------------------------------------------------\n";

string ClassName(const Descriptor* descriptor, bool qualified) {

  // Find "outer", the descriptor of the top-level message in which
  // "descriptor" is embedded.
  const Descriptor* outer = descriptor;
  while (outer->containing_type() != NULL) outer = outer->containing_type();

  const string& outer_name = outer->full_name();
  string inner_name = descriptor->full_name().substr(outer_name.size());

  if (qualified) {
    return "::" + DotsToColons(outer_name) + DotsToUnderscores(inner_name);
  } else {
    return outer->name() + DotsToUnderscores(inner_name);
  }
}

string ClassName(const EnumDescriptor* enum_descriptor, bool qualified) {
  if (enum_descriptor->containing_type() == NULL) {
    if (qualified) {
      return "::" + DotsToColons(enum_descriptor->full_name());
    } else {
      return enum_descriptor->name();
    }
  } else {
    string result = ClassName(enum_descriptor->containing_type(), qualified);
    result += '_';
    result += enum_descriptor->name();
    return result;
  }
}


string SuperClassName(const Descriptor* descriptor) {
  return HasDescriptorMethods(descriptor->file()) ?
      "::google::protobuf::Message" : "::google::protobuf::MessageLite";
}

string FieldName(const FieldDescriptor* field) {
  string result = field->name();
  LowerString(&result);
  if (kKeywords.count(result) > 0) {
    result.append("_");
  }
  return result;
}

string FieldConstantName(const FieldDescriptor *field) {
  string field_name = UnderscoresToCamelCase(field->name(), true);
  string result = "k" + field_name + "FieldNumber";

  if (!field->is_extension() &&
      field->containing_type()->FindFieldByCamelcaseName(
        field->camelcase_name()) != field) {
    // This field's camelcase name is not unique.  As a hack, add the field
    // number to the constant name.  This makes the constant rather useless,
    // but what can we do?
    result += "_" + SimpleItoa(field->number());
  }

  return result;
}

string FieldMessageTypeName(const FieldDescriptor* field) {
  // Note:  The Google-internal version of Protocol Buffers uses this function
  //   as a hook point for hacks to support legacy code.
  return ClassName(field->message_type(), true);
}

string StripProto(const string& filename) {
  if (HasSuffixString(filename, ".protodevel")) {
    return StripSuffixString(filename, ".protodevel");
  } else {
    return StripSuffixString(filename, ".proto");
  }
}

const char* PrimitiveTypeName(FieldDescriptor::CppType type) {
  switch (type) {
    case FieldDescriptor::CPPTYPE_INT32  : return "::google::protobuf::int32";
    case FieldDescriptor::CPPTYPE_INT64  : return "::google::protobuf::int64";
    case FieldDescriptor::CPPTYPE_UINT32 : return "::google::protobuf::uint32";
    case FieldDescriptor::CPPTYPE_UINT64 : return "::google::protobuf::uint64";
    case FieldDescriptor::CPPTYPE_DOUBLE : return "double";
    case FieldDescriptor::CPPTYPE_FLOAT  : return "float";
    case FieldDescriptor::CPPTYPE_BOOL   : return "bool";
    case FieldDescriptor::CPPTYPE_ENUM   : return "int";
    case FieldDescriptor::CPPTYPE_STRING : return "::std::string";
    case FieldDescriptor::CPPTYPE_MESSAGE: return NULL;

    // No default because we want the compiler to complain if any new
    // CppTypes are added.
  }

  GOOGLE_LOG(FATAL) << "Can't get here.";
  return NULL;
}

const char* DeclaredTypeMethodName(FieldDescriptor::Type type) {
  switch (type) {
    case FieldDescriptor::TYPE_INT32   : return "Int32";
    case FieldDescriptor::TYPE_INT64   : return "Int64";
    case FieldDescriptor::TYPE_UINT32  : return "UInt32";
    case FieldDescriptor::TYPE_UINT64  : return "UInt64";
    case FieldDescriptor::TYPE_SINT32  : return "SInt32";
    case FieldDescriptor::TYPE_SINT64  : return "SInt64";
    case FieldDescriptor::TYPE_FIXED32 : return "Fixed32";
    case FieldDescriptor::TYPE_FIXED64 : return "Fixed64";
    case FieldDescriptor::TYPE_SFIXED32: return "SFixed32";
    case FieldDescriptor::TYPE_SFIXED64: return "SFixed64";
    case FieldDescriptor::TYPE_FLOAT   : return "Float";
    case FieldDescriptor::TYPE_DOUBLE  : return "Double";

    case FieldDescriptor::TYPE_BOOL    : return "Bool";
    case FieldDescriptor::TYPE_ENUM    : return "Enum";

    case FieldDescriptor::TYPE_STRING  : return "String";
    case FieldDescriptor::TYPE_BYTES   : return "Bytes";
    case FieldDescriptor::TYPE_GROUP   : return "Group";
    case FieldDescriptor::TYPE_MESSAGE : return "Message";

    // No default because we want the compiler to complain if any new
    // types are added.
  }
  GOOGLE_LOG(FATAL) << "Can't get here.";
  return "";
}

string DefaultValue(const FieldDescriptor* field) {
  switch (field->cpp_type()) {
    case FieldDescriptor::CPPTYPE_INT32:
      // gcc rejects the decimal form of kint32min and kint64min.
      if (field->default_value_int32() == kint32min) {
        // Make sure we are in a 2's complement system.
        GOOGLE_COMPILE_ASSERT(
            (uint32)kint32min == (uint32)0 - (uint32)0x80000000,
            kint32min_value_error);
        return "-0x80000000";
      }
      return SimpleItoa(field->default_value_int32());
    case FieldDescriptor::CPPTYPE_UINT32:
      return SimpleItoa(field->default_value_uint32()) + "u";
    case FieldDescriptor::CPPTYPE_INT64:
      // See the comments for CPPTYPE_INT32.
      if (field->default_value_int64() == kint64min) {
        // Make sure we are in a 2's complement system.
        GOOGLE_COMPILE_ASSERT(
            (uint64)kint64min ==
                (uint64)0 - (uint64)GOOGLE_LONGLONG(0x8000000000000000),
            kint64min_value_error);
        return "GOOGLE_LONGLONG(-0x8000000000000000)";
      }
      return "GOOGLE_LONGLONG(" + SimpleItoa(field->default_value_int64()) + ")";
    case FieldDescriptor::CPPTYPE_UINT64:
      return "GOOGLE_ULONGLONG(" + SimpleItoa(field->default_value_uint64())+ ")";
    case FieldDescriptor::CPPTYPE_DOUBLE: {
      double value = field->default_value_double();
      if (value == numeric_limits<double>::infinity()) {
        return "::google::protobuf::internal::Infinity()";
      } else if (value == -numeric_limits<double>::infinity()) {
        return "-::google::protobuf::internal::Infinity()";
      } else if (value != value) {
        return "::google::protobuf::internal::NaN()";
      } else {
        return SimpleDtoa(value);
      }
    }
    case FieldDescriptor::CPPTYPE_FLOAT:
      {
        float value = field->default_value_float();
        if (value == numeric_limits<float>::infinity()) {
          return "static_cast<float>(::google::protobuf::internal::Infinity())";
        } else if (value == -numeric_limits<float>::infinity()) {
          return "static_cast<float>(-::google::protobuf::internal::Infinity())";
        } else if (value != value) {
          return "static_cast<float>(::google::protobuf::internal::NaN())";
        } else {
          string float_value = SimpleFtoa(value);
          // If floating point value contains a period (.) or an exponent
          // (either E or e), then append suffix 'f' to make it a float
          // literal.
          if (float_value.find_first_of(".eE") != string::npos) {
            float_value.push_back('f');
          }
          return float_value;
        }
      }
    case FieldDescriptor::CPPTYPE_BOOL:
      return field->default_value_bool() ? "true" : "false";
    case FieldDescriptor::CPPTYPE_ENUM:
      // Lazy:  Generate a static_cast because we don't have a helper function
      //   that constructs the full name of an enum value.
      return strings::Substitute(
          "static_cast< $0 >($1)",
          ClassName(field->enum_type(), true),
          field->default_value_enum()->number());
    case FieldDescriptor::CPPTYPE_STRING:
      return "\"" + EscapeTrigraphs(
        CEscape(field->default_value_string())) +
        "\"";
    case FieldDescriptor::CPPTYPE_MESSAGE:
      return FieldMessageTypeName(field) + "::default_instance()";
  }
  // Can't actually get here; make compiler happy.  (We could add a default
  // case above but then we wouldn't get the nice compiler warning when a
  // new type is added.)
  GOOGLE_LOG(FATAL) << "Can't get here.";
  return "";
}

// Convert a file name into a valid identifier.
string FilenameIdentifier(const string& filename) {
  string result;
  for (int i = 0; i < filename.size(); i++) {
    if (ascii_isalnum(filename[i])) {
      result.push_back(filename[i]);
    } else {
      // Not alphanumeric.  To avoid any possibility of name conflicts we
      // use the hex code for the character.
      result.push_back('_');
      char buffer[kFastToBufferSize];
      result.append(FastHexToBuffer(static_cast<uint8>(filename[i]), buffer));
    }
  }
  return result;
}

// Return the name of the AddDescriptors() function for a given file.
string GlobalAddDescriptorsName(const string& filename) {
  return "protobuf_AddDesc_" + FilenameIdentifier(filename);
}

// Return the name of the AssignDescriptors() function for a given file.
string GlobalAssignDescriptorsName(const string& filename) {
  return "protobuf_AssignDesc_" + FilenameIdentifier(filename);
}

// Return the name of the ShutdownFile() function for a given file.
string GlobalShutdownFileName(const string& filename) {
  return "protobuf_ShutdownFile_" + FilenameIdentifier(filename);
}

// Escape C++ trigraphs by escaping question marks to \?
string EscapeTrigraphs(const string& to_escape) {
  return StringReplace(to_escape, "?", "\\?", true);
}

bool StaticInitializersForced(const FileDescriptor* file) {
  if (HasDescriptorMethods(file) || file->extension_count() > 0) {
    return true;
  }
  for (int i = 0; i < file->message_type_count(); ++i) {
    if (HasExtension(file->message_type(i))) {
      return true;
    }
  }
  return false;
}

void PrintHandlingOptionalStaticInitializers(
    const FileDescriptor* file, io::Printer* printer,
    const char* with_static_init, const char* without_static_init,
    const char* var1, const string& val1,
    const char* var2, const string& val2) {
  map<string, string> vars;
  if (var1) {
    vars[var1] = val1;
  }
  if (var2) {
    vars[var2] = val2;
  }
  PrintHandlingOptionalStaticInitializers(
      vars, file, printer, with_static_init, without_static_init);
}

void PrintHandlingOptionalStaticInitializers(
    const map<string, string>& vars, const FileDescriptor* file,
    io::Printer* printer, const char* with_static_init,
    const char* without_static_init) {
  if (StaticInitializersForced(file)) {
    printer->Print(vars, with_static_init);
  } else {
    printer->Print(vars, (string(
      "#ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER\n") +
      without_static_init +
      "#else\n" +
      with_static_init +
      "#endif\n").c_str());
  }
}


static bool HasEnumDefinitions(const Descriptor* message_type) {
  if (message_type->enum_type_count() > 0) return true;
  for (int i = 0; i < message_type->nested_type_count(); ++i) {
    if (HasEnumDefinitions(message_type->nested_type(i))) return true;
  }
  return false;
}

bool HasEnumDefinitions(const FileDescriptor* file) {
  if (file->enum_type_count() > 0) return true;
  for (int i = 0; i < file->message_type_count(); ++i) {
    if (HasEnumDefinitions(file->message_type(i))) return true;
  }
  return false;
}

}  // namespace cpp
}  // namespace compiler
}  // namespace protobuf
}  // namespace google
