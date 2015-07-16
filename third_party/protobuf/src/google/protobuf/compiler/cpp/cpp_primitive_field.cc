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

#include <google/protobuf/compiler/cpp/cpp_primitive_field.h>
#include <google/protobuf/compiler/cpp/cpp_helpers.h>
#include <google/protobuf/io/printer.h>
#include <google/protobuf/wire_format.h>
#include <google/protobuf/stubs/strutil.h>

namespace google {
namespace protobuf {
namespace compiler {
namespace cpp {

using internal::WireFormatLite;

namespace {

// For encodings with fixed sizes, returns that size in bytes.  Otherwise
// returns -1.
int FixedSize(FieldDescriptor::Type type) {
  switch (type) {
    case FieldDescriptor::TYPE_INT32   : return -1;
    case FieldDescriptor::TYPE_INT64   : return -1;
    case FieldDescriptor::TYPE_UINT32  : return -1;
    case FieldDescriptor::TYPE_UINT64  : return -1;
    case FieldDescriptor::TYPE_SINT32  : return -1;
    case FieldDescriptor::TYPE_SINT64  : return -1;
    case FieldDescriptor::TYPE_FIXED32 : return WireFormatLite::kFixed32Size;
    case FieldDescriptor::TYPE_FIXED64 : return WireFormatLite::kFixed64Size;
    case FieldDescriptor::TYPE_SFIXED32: return WireFormatLite::kSFixed32Size;
    case FieldDescriptor::TYPE_SFIXED64: return WireFormatLite::kSFixed64Size;
    case FieldDescriptor::TYPE_FLOAT   : return WireFormatLite::kFloatSize;
    case FieldDescriptor::TYPE_DOUBLE  : return WireFormatLite::kDoubleSize;

    case FieldDescriptor::TYPE_BOOL    : return WireFormatLite::kBoolSize;
    case FieldDescriptor::TYPE_ENUM    : return -1;

    case FieldDescriptor::TYPE_STRING  : return -1;
    case FieldDescriptor::TYPE_BYTES   : return -1;
    case FieldDescriptor::TYPE_GROUP   : return -1;
    case FieldDescriptor::TYPE_MESSAGE : return -1;

    // No default because we want the compiler to complain if any new
    // types are added.
  }
  GOOGLE_LOG(FATAL) << "Can't get here.";
  return -1;
}

void SetPrimitiveVariables(const FieldDescriptor* descriptor,
                           map<string, string>* variables,
                           const Options& options) {
  SetCommonFieldVariables(descriptor, variables, options);
  (*variables)["type"] = PrimitiveTypeName(descriptor->cpp_type());
  (*variables)["default"] = DefaultValue(descriptor);
  (*variables)["tag"] = SimpleItoa(internal::WireFormat::MakeTag(descriptor));
  int fixed_size = FixedSize(descriptor->type());
  if (fixed_size != -1) {
    (*variables)["fixed_size"] = SimpleItoa(fixed_size);
  }
  (*variables)["wire_format_field_type"] =
      "::google::protobuf::internal::WireFormatLite::" + FieldDescriptorProto_Type_Name(
          static_cast<FieldDescriptorProto_Type>(descriptor->type()));
}

}  // namespace

// ===================================================================

PrimitiveFieldGenerator::
PrimitiveFieldGenerator(const FieldDescriptor* descriptor,
                        const Options& options)
  : descriptor_(descriptor) {
  SetPrimitiveVariables(descriptor, &variables_, options);
}

PrimitiveFieldGenerator::~PrimitiveFieldGenerator() {}

void PrimitiveFieldGenerator::
GeneratePrivateMembers(io::Printer* printer) const {
  printer->Print(variables_, "$type$ $name$_;\n");
}

void PrimitiveFieldGenerator::
GenerateAccessorDeclarations(io::Printer* printer) const {
  printer->Print(variables_,
    "inline $type$ $name$() const$deprecation$;\n"
    "inline void set_$name$($type$ value)$deprecation$;\n");
}

void PrimitiveFieldGenerator::
GenerateInlineAccessorDefinitions(io::Printer* printer) const {
  printer->Print(variables_,
    "inline $type$ $classname$::$name$() const {\n"
    "  return $name$_;\n"
    "}\n"
    "inline void $classname$::set_$name$($type$ value) {\n"
    "  set_has_$name$();\n"
    "  $name$_ = value;\n"
    "}\n");
}

void PrimitiveFieldGenerator::
GenerateClearingCode(io::Printer* printer) const {
  printer->Print(variables_, "$name$_ = $default$;\n");
}

void PrimitiveFieldGenerator::
GenerateMergingCode(io::Printer* printer) const {
  printer->Print(variables_, "set_$name$(from.$name$());\n");
}

void PrimitiveFieldGenerator::
GenerateSwappingCode(io::Printer* printer) const {
  printer->Print(variables_, "std::swap($name$_, other->$name$_);\n");
}

void PrimitiveFieldGenerator::
GenerateConstructorCode(io::Printer* printer) const {
  printer->Print(variables_, "$name$_ = $default$;\n");
}

void PrimitiveFieldGenerator::
GenerateMergeFromCodedStream(io::Printer* printer) const {
  printer->Print(variables_,
    "DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<\n"
    "         $type$, $wire_format_field_type$>(\n"
    "       input, &$name$_)));\n"
    "set_has_$name$();\n");
}

void PrimitiveFieldGenerator::
GenerateSerializeWithCachedSizes(io::Printer* printer) const {
  printer->Print(variables_,
    "::google::protobuf::internal::WireFormatLite::Write$declared_type$("
      "$number$, this->$name$(), output);\n");
}

void PrimitiveFieldGenerator::
GenerateSerializeWithCachedSizesToArray(io::Printer* printer) const {
  printer->Print(variables_,
    "target = ::google::protobuf::internal::WireFormatLite::Write$declared_type$ToArray("
      "$number$, this->$name$(), target);\n");
}

void PrimitiveFieldGenerator::
GenerateByteSize(io::Printer* printer) const {
  int fixed_size = FixedSize(descriptor_->type());
  if (fixed_size == -1) {
    printer->Print(variables_,
      "total_size += $tag_size$ +\n"
      "  ::google::protobuf::internal::WireFormatLite::$declared_type$Size(\n"
      "    this->$name$());\n");
  } else {
    printer->Print(variables_,
      "total_size += $tag_size$ + $fixed_size$;\n");
  }
}

// ===================================================================

RepeatedPrimitiveFieldGenerator::
RepeatedPrimitiveFieldGenerator(const FieldDescriptor* descriptor,
                                const Options& options)
  : descriptor_(descriptor) {
  SetPrimitiveVariables(descriptor, &variables_, options);

  if (descriptor->options().packed()) {
    variables_["packed_reader"] = "ReadPackedPrimitive";
    variables_["repeated_reader"] = "ReadRepeatedPrimitiveNoInline";
  } else {
    variables_["packed_reader"] = "ReadPackedPrimitiveNoInline";
    variables_["repeated_reader"] = "ReadRepeatedPrimitive";
  }
}

RepeatedPrimitiveFieldGenerator::~RepeatedPrimitiveFieldGenerator() {}

void RepeatedPrimitiveFieldGenerator::
GeneratePrivateMembers(io::Printer* printer) const {
  printer->Print(variables_,
    "::google::protobuf::RepeatedField< $type$ > $name$_;\n");
  if (descriptor_->options().packed() && HasGeneratedMethods(descriptor_->file())) {
    printer->Print(variables_,
      "mutable int _$name$_cached_byte_size_;\n");
  }
}

void RepeatedPrimitiveFieldGenerator::
GenerateAccessorDeclarations(io::Printer* printer) const {
  printer->Print(variables_,
    "inline $type$ $name$(int index) const$deprecation$;\n"
    "inline void set_$name$(int index, $type$ value)$deprecation$;\n"
    "inline void add_$name$($type$ value)$deprecation$;\n");
  printer->Print(variables_,
    "inline const ::google::protobuf::RepeatedField< $type$ >&\n"
    "    $name$() const$deprecation$;\n"
    "inline ::google::protobuf::RepeatedField< $type$ >*\n"
    "    mutable_$name$()$deprecation$;\n");
}

void RepeatedPrimitiveFieldGenerator::
GenerateInlineAccessorDefinitions(io::Printer* printer) const {
  printer->Print(variables_,
    "inline $type$ $classname$::$name$(int index) const {\n"
    "  return $name$_.Get(index);\n"
    "}\n"
    "inline void $classname$::set_$name$(int index, $type$ value) {\n"
    "  $name$_.Set(index, value);\n"
    "}\n"
    "inline void $classname$::add_$name$($type$ value) {\n"
    "  $name$_.Add(value);\n"
    "}\n");
  printer->Print(variables_,
    "inline const ::google::protobuf::RepeatedField< $type$ >&\n"
    "$classname$::$name$() const {\n"
    "  return $name$_;\n"
    "}\n"
    "inline ::google::protobuf::RepeatedField< $type$ >*\n"
    "$classname$::mutable_$name$() {\n"
    "  return &$name$_;\n"
    "}\n");
}

void RepeatedPrimitiveFieldGenerator::
GenerateClearingCode(io::Printer* printer) const {
  printer->Print(variables_, "$name$_.Clear();\n");
}

void RepeatedPrimitiveFieldGenerator::
GenerateMergingCode(io::Printer* printer) const {
  printer->Print(variables_, "$name$_.MergeFrom(from.$name$_);\n");
}

void RepeatedPrimitiveFieldGenerator::
GenerateSwappingCode(io::Printer* printer) const {
  printer->Print(variables_, "$name$_.Swap(&other->$name$_);\n");
}

void RepeatedPrimitiveFieldGenerator::
GenerateConstructorCode(io::Printer* printer) const {
  // Not needed for repeated fields.
}

void RepeatedPrimitiveFieldGenerator::
GenerateMergeFromCodedStream(io::Printer* printer) const {
  printer->Print(variables_,
    "DO_((::google::protobuf::internal::WireFormatLite::$repeated_reader$<\n"
    "         $type$, $wire_format_field_type$>(\n"
    "       $tag_size$, $tag$, input, this->mutable_$name$())));\n");
}

void RepeatedPrimitiveFieldGenerator::
GenerateMergeFromCodedStreamWithPacking(io::Printer* printer) const {
  printer->Print(variables_,
    "DO_((::google::protobuf::internal::WireFormatLite::$packed_reader$<\n"
    "         $type$, $wire_format_field_type$>(\n"
    "       input, this->mutable_$name$())));\n");
}

void RepeatedPrimitiveFieldGenerator::
GenerateSerializeWithCachedSizes(io::Printer* printer) const {
  if (descriptor_->options().packed()) {
    // Write the tag and the size.
    printer->Print(variables_,
      "if (this->$name$_size() > 0) {\n"
      "  ::google::protobuf::internal::WireFormatLite::WriteTag("
          "$number$, "
          "::google::protobuf::internal::WireFormatLite::WIRETYPE_LENGTH_DELIMITED, "
          "output);\n"
      "  output->WriteVarint32(_$name$_cached_byte_size_);\n"
      "}\n");
  }
  printer->Print(variables_,
      "for (int i = 0; i < this->$name$_size(); i++) {\n");
  if (descriptor_->options().packed()) {
    printer->Print(variables_,
      "  ::google::protobuf::internal::WireFormatLite::Write$declared_type$NoTag(\n"
      "    this->$name$(i), output);\n");
  } else {
    printer->Print(variables_,
      "  ::google::protobuf::internal::WireFormatLite::Write$declared_type$(\n"
      "    $number$, this->$name$(i), output);\n");
  }
  printer->Print("}\n");
}

void RepeatedPrimitiveFieldGenerator::
GenerateSerializeWithCachedSizesToArray(io::Printer* printer) const {
  if (descriptor_->options().packed()) {
    // Write the tag and the size.
    printer->Print(variables_,
      "if (this->$name$_size() > 0) {\n"
      "  target = ::google::protobuf::internal::WireFormatLite::WriteTagToArray(\n"
      "    $number$,\n"
      "    ::google::protobuf::internal::WireFormatLite::WIRETYPE_LENGTH_DELIMITED,\n"
      "    target);\n"
      "  target = ::google::protobuf::io::CodedOutputStream::WriteVarint32ToArray(\n"
      "    _$name$_cached_byte_size_, target);\n"
      "}\n");
  }
  printer->Print(variables_,
      "for (int i = 0; i < this->$name$_size(); i++) {\n");
  if (descriptor_->options().packed()) {
    printer->Print(variables_,
      "  target = ::google::protobuf::internal::WireFormatLite::\n"
      "    Write$declared_type$NoTagToArray(this->$name$(i), target);\n");
  } else {
    printer->Print(variables_,
      "  target = ::google::protobuf::internal::WireFormatLite::\n"
      "    Write$declared_type$ToArray($number$, this->$name$(i), target);\n");
  }
  printer->Print("}\n");
}

void RepeatedPrimitiveFieldGenerator::
GenerateByteSize(io::Printer* printer) const {
  printer->Print(variables_,
    "{\n"
    "  int data_size = 0;\n");
  printer->Indent();
  int fixed_size = FixedSize(descriptor_->type());
  if (fixed_size == -1) {
    printer->Print(variables_,
      "for (int i = 0; i < this->$name$_size(); i++) {\n"
      "  data_size += ::google::protobuf::internal::WireFormatLite::\n"
      "    $declared_type$Size(this->$name$(i));\n"
      "}\n");
  } else {
    printer->Print(variables_,
      "data_size = $fixed_size$ * this->$name$_size();\n");
  }

  if (descriptor_->options().packed()) {
    printer->Print(variables_,
      "if (data_size > 0) {\n"
      "  total_size += $tag_size$ +\n"
      "    ::google::protobuf::internal::WireFormatLite::Int32Size(data_size);\n"
      "}\n"
      "GOOGLE_SAFE_CONCURRENT_WRITES_BEGIN();\n"
      "_$name$_cached_byte_size_ = data_size;\n"
      "GOOGLE_SAFE_CONCURRENT_WRITES_END();\n"
      "total_size += data_size;\n");
  } else {
    printer->Print(variables_,
      "total_size += $tag_size$ * this->$name$_size() + data_size;\n");
  }
  printer->Outdent();
  printer->Print("}\n");
}

}  // namespace cpp
}  // namespace compiler
}  // namespace protobuf
}  // namespace google
