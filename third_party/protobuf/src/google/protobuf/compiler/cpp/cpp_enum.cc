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

#include <set>
#include <map>

#include <google/protobuf/compiler/cpp/cpp_enum.h>
#include <google/protobuf/compiler/cpp/cpp_helpers.h>
#include <google/protobuf/io/printer.h>
#include <google/protobuf/stubs/strutil.h>

namespace google {
namespace protobuf {
namespace compiler {
namespace cpp {

EnumGenerator::EnumGenerator(const EnumDescriptor* descriptor,
                             const Options& options)
  : descriptor_(descriptor),
    classname_(ClassName(descriptor, false)),
    options_(options) {
}

EnumGenerator::~EnumGenerator() {}

void EnumGenerator::GenerateDefinition(io::Printer* printer) {
  map<string, string> vars;
  vars["classname"] = classname_;
  vars["short_name"] = descriptor_->name();

  printer->Print(vars, "enum $classname$ {\n");
  printer->Indent();

  const EnumValueDescriptor* min_value = descriptor_->value(0);
  const EnumValueDescriptor* max_value = descriptor_->value(0);

  for (int i = 0; i < descriptor_->value_count(); i++) {
    vars["name"] = descriptor_->value(i)->name();
    vars["number"] = SimpleItoa(descriptor_->value(i)->number());
    vars["prefix"] = (descriptor_->containing_type() == NULL) ?
      "" : classname_ + "_";

    if (i > 0) printer->Print(",\n");
    printer->Print(vars, "$prefix$$name$ = $number$");

    if (descriptor_->value(i)->number() < min_value->number()) {
      min_value = descriptor_->value(i);
    }
    if (descriptor_->value(i)->number() > max_value->number()) {
      max_value = descriptor_->value(i);
    }
  }

  printer->Outdent();
  printer->Print("\n};\n");

  vars["min_name"] = min_value->name();
  vars["max_name"] = max_value->name();

  if (options_.dllexport_decl.empty()) {
    vars["dllexport"] = "";
  } else {
    vars["dllexport"] = options_.dllexport_decl + " ";
  }

  printer->Print(vars,
    "$dllexport$bool $classname$_IsValid(int value);\n"
    "const $classname$ $prefix$$short_name$_MIN = $prefix$$min_name$;\n"
    "const $classname$ $prefix$$short_name$_MAX = $prefix$$max_name$;\n"
    "const int $prefix$$short_name$_ARRAYSIZE = $prefix$$short_name$_MAX + 1;\n"
    "\n");

  if (HasDescriptorMethods(descriptor_->file())) {
    printer->Print(vars,
      "$dllexport$const ::google::protobuf::EnumDescriptor* $classname$_descriptor();\n");
    // The _Name and _Parse methods
    printer->Print(vars,
      "inline const ::std::string& $classname$_Name($classname$ value) {\n"
      "  return ::google::protobuf::internal::NameOfEnum(\n"
      "    $classname$_descriptor(), value);\n"
      "}\n");
    printer->Print(vars,
      "inline bool $classname$_Parse(\n"
      "    const ::std::string& name, $classname$* value) {\n"
      "  return ::google::protobuf::internal::ParseNamedEnum<$classname$>(\n"
      "    $classname$_descriptor(), name, value);\n"
      "}\n");
  }
}

void EnumGenerator::
GenerateGetEnumDescriptorSpecializations(io::Printer* printer) {
  if (HasDescriptorMethods(descriptor_->file())) {
    printer->Print(
      "template <>\n"
      "inline const EnumDescriptor* GetEnumDescriptor< $classname$>() {\n"
      "  return $classname$_descriptor();\n"
      "}\n",
      "classname", ClassName(descriptor_, true));
  }
}

void EnumGenerator::GenerateSymbolImports(io::Printer* printer) {
  map<string, string> vars;
  vars["nested_name"] = descriptor_->name();
  vars["classname"] = classname_;
  printer->Print(vars, "typedef $classname$ $nested_name$;\n");

  for (int j = 0; j < descriptor_->value_count(); j++) {
    vars["tag"] = descriptor_->value(j)->name();
    printer->Print(vars,
      "static const $nested_name$ $tag$ = $classname$_$tag$;\n");
  }

  printer->Print(vars,
    "static inline bool $nested_name$_IsValid(int value) {\n"
    "  return $classname$_IsValid(value);\n"
    "}\n"
    "static const $nested_name$ $nested_name$_MIN =\n"
    "  $classname$_$nested_name$_MIN;\n"
    "static const $nested_name$ $nested_name$_MAX =\n"
    "  $classname$_$nested_name$_MAX;\n"
    "static const int $nested_name$_ARRAYSIZE =\n"
    "  $classname$_$nested_name$_ARRAYSIZE;\n");

  if (HasDescriptorMethods(descriptor_->file())) {
    printer->Print(vars,
      "static inline const ::google::protobuf::EnumDescriptor*\n"
      "$nested_name$_descriptor() {\n"
      "  return $classname$_descriptor();\n"
      "}\n");
    printer->Print(vars,
      "static inline const ::std::string& $nested_name$_Name($nested_name$ value) {\n"
      "  return $classname$_Name(value);\n"
      "}\n");
    printer->Print(vars,
      "static inline bool $nested_name$_Parse(const ::std::string& name,\n"
      "    $nested_name$* value) {\n"
      "  return $classname$_Parse(name, value);\n"
      "}\n");
  }
}

void EnumGenerator::GenerateDescriptorInitializer(
    io::Printer* printer, int index) {
  map<string, string> vars;
  vars["classname"] = classname_;
  vars["index"] = SimpleItoa(index);

  if (descriptor_->containing_type() == NULL) {
    printer->Print(vars,
      "$classname$_descriptor_ = file->enum_type($index$);\n");
  } else {
    vars["parent"] = ClassName(descriptor_->containing_type(), false);
    printer->Print(vars,
      "$classname$_descriptor_ = $parent$_descriptor_->enum_type($index$);\n");
  }
}

void EnumGenerator::GenerateMethods(io::Printer* printer) {
  map<string, string> vars;
  vars["classname"] = classname_;

  if (HasDescriptorMethods(descriptor_->file())) {
    printer->Print(vars,
      "const ::google::protobuf::EnumDescriptor* $classname$_descriptor() {\n"
      "  protobuf_AssignDescriptorsOnce();\n"
      "  return $classname$_descriptor_;\n"
      "}\n");
  }

  printer->Print(vars,
    "bool $classname$_IsValid(int value) {\n"
    "  switch(value) {\n");

  // Multiple values may have the same number.  Make sure we only cover
  // each number once by first constructing a set containing all valid
  // numbers, then printing a case statement for each element.

  set<int> numbers;
  for (int j = 0; j < descriptor_->value_count(); j++) {
    const EnumValueDescriptor* value = descriptor_->value(j);
    numbers.insert(value->number());
  }

  for (set<int>::iterator iter = numbers.begin();
       iter != numbers.end(); ++iter) {
    printer->Print(
      "    case $number$:\n",
      "number", SimpleItoa(*iter));
  }

  printer->Print(vars,
    "      return true;\n"
    "    default:\n"
    "      return false;\n"
    "  }\n"
    "}\n"
    "\n");

  if (descriptor_->containing_type() != NULL) {
    // We need to "define" the static constants which were declared in the
    // header, to give the linker a place to put them.  Or at least the C++
    // standard says we have to.  MSVC actually insists tha we do _not_ define
    // them again in the .cc file.
    printer->Print("#ifndef _MSC_VER\n");

    vars["parent"] = ClassName(descriptor_->containing_type(), false);
    vars["nested_name"] = descriptor_->name();
    for (int i = 0; i < descriptor_->value_count(); i++) {
      vars["value"] = descriptor_->value(i)->name();
      printer->Print(vars,
        "const $classname$ $parent$::$value$;\n");
    }
    printer->Print(vars,
      "const $classname$ $parent$::$nested_name$_MIN;\n"
      "const $classname$ $parent$::$nested_name$_MAX;\n"
      "const int $parent$::$nested_name$_ARRAYSIZE;\n");

    printer->Print("#endif  // _MSC_VER\n");
  }
}

}  // namespace cpp
}  // namespace compiler
}  // namespace protobuf
}  // namespace google
