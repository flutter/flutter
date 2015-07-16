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

#include <google/protobuf/compiler/java/java_extension.h>
#include <google/protobuf/compiler/java/java_doc_comment.h>
#include <google/protobuf/compiler/java/java_helpers.h>
#include <google/protobuf/stubs/strutil.h>
#include <google/protobuf/io/printer.h>

namespace google {
namespace protobuf {
namespace compiler {
namespace java {

namespace {

const char* TypeName(FieldDescriptor::Type field_type) {
  switch (field_type) {
    case FieldDescriptor::TYPE_INT32   : return "INT32";
    case FieldDescriptor::TYPE_UINT32  : return "UINT32";
    case FieldDescriptor::TYPE_SINT32  : return "SINT32";
    case FieldDescriptor::TYPE_FIXED32 : return "FIXED32";
    case FieldDescriptor::TYPE_SFIXED32: return "SFIXED32";
    case FieldDescriptor::TYPE_INT64   : return "INT64";
    case FieldDescriptor::TYPE_UINT64  : return "UINT64";
    case FieldDescriptor::TYPE_SINT64  : return "SINT64";
    case FieldDescriptor::TYPE_FIXED64 : return "FIXED64";
    case FieldDescriptor::TYPE_SFIXED64: return "SFIXED64";
    case FieldDescriptor::TYPE_FLOAT   : return "FLOAT";
    case FieldDescriptor::TYPE_DOUBLE  : return "DOUBLE";
    case FieldDescriptor::TYPE_BOOL    : return "BOOL";
    case FieldDescriptor::TYPE_STRING  : return "STRING";
    case FieldDescriptor::TYPE_BYTES   : return "BYTES";
    case FieldDescriptor::TYPE_ENUM    : return "ENUM";
    case FieldDescriptor::TYPE_GROUP   : return "GROUP";
    case FieldDescriptor::TYPE_MESSAGE : return "MESSAGE";

    // No default because we want the compiler to complain if any new
    // types are added.
  }

  GOOGLE_LOG(FATAL) << "Can't get here.";
  return NULL;
}

}

ExtensionGenerator::ExtensionGenerator(const FieldDescriptor* descriptor)
  : descriptor_(descriptor) {
  if (descriptor_->extension_scope() != NULL) {
    scope_ = ClassName(descriptor_->extension_scope());
  } else {
    scope_ = ClassName(descriptor_->file());
  }
}

ExtensionGenerator::~ExtensionGenerator() {}

// Initializes the vars referenced in the generated code templates.
void InitTemplateVars(const FieldDescriptor* descriptor,
                      const string& scope,
                      map<string, string>* vars_pointer) {
  map<string, string> &vars = *vars_pointer;
  vars["scope"] = scope;
  vars["name"] = UnderscoresToCamelCase(descriptor);
  vars["containing_type"] = ClassName(descriptor->containing_type());
  vars["number"] = SimpleItoa(descriptor->number());
  vars["constant_name"] = FieldConstantName(descriptor);
  vars["index"] = SimpleItoa(descriptor->index());
  vars["default"] =
      descriptor->is_repeated() ? "" : DefaultValue(descriptor);
  vars["type_constant"] = TypeName(GetType(descriptor));
  vars["packed"] = descriptor->options().packed() ? "true" : "false";
  vars["enum_map"] = "null";
  vars["prototype"] = "null";

  JavaType java_type = GetJavaType(descriptor);
  string singular_type;
  switch (java_type) {
    case JAVATYPE_MESSAGE:
      singular_type = ClassName(descriptor->message_type());
      vars["prototype"] = singular_type + ".getDefaultInstance()";
      break;
    case JAVATYPE_ENUM:
      singular_type = ClassName(descriptor->enum_type());
      vars["enum_map"] = singular_type + ".internalGetValueMap()";
      break;
    default:
      singular_type = BoxedPrimitiveTypeName(java_type);
      break;
  }
  vars["type"] = descriptor->is_repeated() ?
      "java.util.List<" + singular_type + ">" : singular_type;
  vars["singular_type"] = singular_type;
}

void ExtensionGenerator::Generate(io::Printer* printer) {
  map<string, string> vars;
  InitTemplateVars(descriptor_, scope_, &vars);
  printer->Print(vars,
      "public static final int $constant_name$ = $number$;\n");

  WriteFieldDocComment(printer, descriptor_);
  if (HasDescriptorMethods(descriptor_->file())) {
    // Non-lite extensions
    if (descriptor_->extension_scope() == NULL) {
      // Non-nested
      printer->Print(
          vars,
          "public static final\n"
          "  com.google.protobuf.GeneratedMessage.GeneratedExtension<\n"
          "    $containing_type$,\n"
          "    $type$> $name$ = com.google.protobuf.GeneratedMessage\n"
          "        .newFileScopedGeneratedExtension(\n"
          "      $singular_type$.class,\n"
          "      $prototype$);\n");
    } else {
      // Nested
      printer->Print(
          vars,
          "public static final\n"
          "  com.google.protobuf.GeneratedMessage.GeneratedExtension<\n"
          "    $containing_type$,\n"
          "    $type$> $name$ = com.google.protobuf.GeneratedMessage\n"
          "        .newMessageScopedGeneratedExtension(\n"
          "      $scope$.getDefaultInstance(),\n"
          "      $index$,\n"
          "      $singular_type$.class,\n"
          "      $prototype$);\n");
    }
  } else {
    // Lite extensions
    if (descriptor_->is_repeated()) {
      printer->Print(
          vars,
          "public static final\n"
          "  com.google.protobuf.GeneratedMessageLite.GeneratedExtension<\n"
          "    $containing_type$,\n"
          "    $type$> $name$ = com.google.protobuf.GeneratedMessageLite\n"
          "        .newRepeatedGeneratedExtension(\n"
          "      $containing_type$.getDefaultInstance(),\n"
          "      $prototype$,\n"
          "      $enum_map$,\n"
          "      $number$,\n"
          "      com.google.protobuf.WireFormat.FieldType.$type_constant$,\n"
          "      $packed$);\n");
    } else {
      printer->Print(
          vars,
          "public static final\n"
          "  com.google.protobuf.GeneratedMessageLite.GeneratedExtension<\n"
          "    $containing_type$,\n"
          "    $type$> $name$ = com.google.protobuf.GeneratedMessageLite\n"
          "        .newSingularGeneratedExtension(\n"
          "      $containing_type$.getDefaultInstance(),\n"
          "      $default$,\n"
          "      $prototype$,\n"
          "      $enum_map$,\n"
          "      $number$,\n"
          "      com.google.protobuf.WireFormat.FieldType.$type_constant$);\n");
    }
  }
}

void ExtensionGenerator::GenerateNonNestedInitializationCode(
    io::Printer* printer) {
  if (descriptor_->extension_scope() == NULL &&
      HasDescriptorMethods(descriptor_->file())) {
    // Only applies to non-nested, non-lite extensions.
    printer->Print(
        "$name$.internalInit(descriptor.getExtensions().get($index$));\n",
        "name", UnderscoresToCamelCase(descriptor_),
        "index", SimpleItoa(descriptor_->index()));
  }
}

void ExtensionGenerator::GenerateRegistrationCode(io::Printer* printer) {
  printer->Print(
    "registry.add($scope$.$name$);\n",
    "scope", scope_,
    "name", UnderscoresToCamelCase(descriptor_));
}

}  // namespace java
}  // namespace compiler
}  // namespace protobuf
}  // namespace google
