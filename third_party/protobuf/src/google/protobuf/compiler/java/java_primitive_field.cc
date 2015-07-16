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

#include <map>
#include <string>

#include <google/protobuf/compiler/java/java_primitive_field.h>
#include <google/protobuf/compiler/java/java_doc_comment.h>
#include <google/protobuf/stubs/common.h>
#include <google/protobuf/compiler/java/java_helpers.h>
#include <google/protobuf/io/printer.h>
#include <google/protobuf/wire_format.h>
#include <google/protobuf/stubs/strutil.h>

namespace google {
namespace protobuf {
namespace compiler {
namespace java {

using internal::WireFormat;
using internal::WireFormatLite;

namespace {

const char* PrimitiveTypeName(JavaType type) {
  switch (type) {
    case JAVATYPE_INT    : return "int";
    case JAVATYPE_LONG   : return "long";
    case JAVATYPE_FLOAT  : return "float";
    case JAVATYPE_DOUBLE : return "double";
    case JAVATYPE_BOOLEAN: return "boolean";
    case JAVATYPE_STRING : return "java.lang.String";
    case JAVATYPE_BYTES  : return "com.google.protobuf.ByteString";
    case JAVATYPE_ENUM   : return NULL;
    case JAVATYPE_MESSAGE: return NULL;

    // No default because we want the compiler to complain if any new
    // JavaTypes are added.
  }

  GOOGLE_LOG(FATAL) << "Can't get here.";
  return NULL;
}

bool IsReferenceType(JavaType type) {
  switch (type) {
    case JAVATYPE_INT    : return false;
    case JAVATYPE_LONG   : return false;
    case JAVATYPE_FLOAT  : return false;
    case JAVATYPE_DOUBLE : return false;
    case JAVATYPE_BOOLEAN: return false;
    case JAVATYPE_STRING : return true;
    case JAVATYPE_BYTES  : return true;
    case JAVATYPE_ENUM   : return true;
    case JAVATYPE_MESSAGE: return true;

    // No default because we want the compiler to complain if any new
    // JavaTypes are added.
  }

  GOOGLE_LOG(FATAL) << "Can't get here.";
  return false;
}

const char* GetCapitalizedType(const FieldDescriptor* field) {
  switch (GetType(field)) {
    case FieldDescriptor::TYPE_INT32   : return "Int32"   ;
    case FieldDescriptor::TYPE_UINT32  : return "UInt32"  ;
    case FieldDescriptor::TYPE_SINT32  : return "SInt32"  ;
    case FieldDescriptor::TYPE_FIXED32 : return "Fixed32" ;
    case FieldDescriptor::TYPE_SFIXED32: return "SFixed32";
    case FieldDescriptor::TYPE_INT64   : return "Int64"   ;
    case FieldDescriptor::TYPE_UINT64  : return "UInt64"  ;
    case FieldDescriptor::TYPE_SINT64  : return "SInt64"  ;
    case FieldDescriptor::TYPE_FIXED64 : return "Fixed64" ;
    case FieldDescriptor::TYPE_SFIXED64: return "SFixed64";
    case FieldDescriptor::TYPE_FLOAT   : return "Float"   ;
    case FieldDescriptor::TYPE_DOUBLE  : return "Double"  ;
    case FieldDescriptor::TYPE_BOOL    : return "Bool"    ;
    case FieldDescriptor::TYPE_STRING  : return "String"  ;
    case FieldDescriptor::TYPE_BYTES   : return "Bytes"   ;
    case FieldDescriptor::TYPE_ENUM    : return "Enum"    ;
    case FieldDescriptor::TYPE_GROUP   : return "Group"   ;
    case FieldDescriptor::TYPE_MESSAGE : return "Message" ;

    // No default because we want the compiler to complain if any new
    // types are added.
  }

  GOOGLE_LOG(FATAL) << "Can't get here.";
  return NULL;
}

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
                           int messageBitIndex,
                           int builderBitIndex,
                           map<string, string>* variables) {
  (*variables)["name"] =
    UnderscoresToCamelCase(descriptor);
  (*variables)["capitalized_name"] =
    UnderscoresToCapitalizedCamelCase(descriptor);
  (*variables)["constant_name"] = FieldConstantName(descriptor);
  (*variables)["number"] = SimpleItoa(descriptor->number());
  (*variables)["type"] = PrimitiveTypeName(GetJavaType(descriptor));
  (*variables)["boxed_type"] = BoxedPrimitiveTypeName(GetJavaType(descriptor));
  (*variables)["field_type"] = (*variables)["type"];
  (*variables)["field_list_type"] = "java.util.List<" +
      (*variables)["boxed_type"] + ">";
  (*variables)["empty_list"] = "java.util.Collections.emptyList()";
  (*variables)["default"] = DefaultValue(descriptor);
  (*variables)["default_init"] = IsDefaultValueJavaDefault(descriptor) ?
      "" : ("= " + DefaultValue(descriptor));
  (*variables)["capitalized_type"] = GetCapitalizedType(descriptor);
  (*variables)["tag"] = SimpleItoa(WireFormat::MakeTag(descriptor));
  (*variables)["tag_size"] = SimpleItoa(
      WireFormat::TagSize(descriptor->number(), GetType(descriptor)));
  if (IsReferenceType(GetJavaType(descriptor))) {
    (*variables)["null_check"] =
        "  if (value == null) {\n"
        "    throw new NullPointerException();\n"
        "  }\n";
  } else {
    (*variables)["null_check"] = "";
  }
  // TODO(birdo): Add @deprecated javadoc when generating javadoc is supported
  // by the proto compiler
  (*variables)["deprecation"] = descriptor->options().deprecated()
      ? "@java.lang.Deprecated " : "";
  int fixed_size = FixedSize(GetType(descriptor));
  if (fixed_size != -1) {
    (*variables)["fixed_size"] = SimpleItoa(fixed_size);
  }
  (*variables)["on_changed"] =
      HasDescriptorMethods(descriptor->containing_type()) ? "onChanged();" : "";

  // For singular messages and builders, one bit is used for the hasField bit.
  (*variables)["get_has_field_bit_message"] = GenerateGetBit(messageBitIndex);
  (*variables)["set_has_field_bit_message"] = GenerateSetBit(messageBitIndex);

  (*variables)["get_has_field_bit_builder"] = GenerateGetBit(builderBitIndex);
  (*variables)["set_has_field_bit_builder"] = GenerateSetBit(builderBitIndex);
  (*variables)["clear_has_field_bit_builder"] =
      GenerateClearBit(builderBitIndex);

  // For repated builders, one bit is used for whether the array is immutable.
  (*variables)["get_mutable_bit_builder"] = GenerateGetBit(builderBitIndex);
  (*variables)["set_mutable_bit_builder"] = GenerateSetBit(builderBitIndex);
  (*variables)["clear_mutable_bit_builder"] = GenerateClearBit(builderBitIndex);

  // For repeated fields, one bit is used for whether the array is immutable
  // in the parsing constructor.
  (*variables)["get_mutable_bit_parser"] =
      GenerateGetBitMutableLocal(builderBitIndex);
  (*variables)["set_mutable_bit_parser"] =
      GenerateSetBitMutableLocal(builderBitIndex);

  (*variables)["get_has_field_bit_from_local"] =
      GenerateGetBitFromLocal(builderBitIndex);
  (*variables)["set_has_field_bit_to_local"] =
      GenerateSetBitToLocal(messageBitIndex);
}

}  // namespace

// ===================================================================

PrimitiveFieldGenerator::
PrimitiveFieldGenerator(const FieldDescriptor* descriptor,
                        int messageBitIndex,
                        int builderBitIndex)
  : descriptor_(descriptor), messageBitIndex_(messageBitIndex),
    builderBitIndex_(builderBitIndex) {
  SetPrimitiveVariables(descriptor, messageBitIndex, builderBitIndex,
                        &variables_);
}

PrimitiveFieldGenerator::~PrimitiveFieldGenerator() {}

int PrimitiveFieldGenerator::GetNumBitsForMessage() const {
  return 1;
}

int PrimitiveFieldGenerator::GetNumBitsForBuilder() const {
  return 1;
}

void PrimitiveFieldGenerator::
GenerateInterfaceMembers(io::Printer* printer) const {
  WriteFieldDocComment(printer, descriptor_);
  printer->Print(variables_,
    "$deprecation$boolean has$capitalized_name$();\n");
  WriteFieldDocComment(printer, descriptor_);
  printer->Print(variables_,
    "$deprecation$$type$ get$capitalized_name$();\n");
}

void PrimitiveFieldGenerator::
GenerateMembers(io::Printer* printer) const {
  printer->Print(variables_,
    "private $field_type$ $name$_;\n");

  WriteFieldDocComment(printer, descriptor_);
  printer->Print(variables_,
    "$deprecation$public boolean has$capitalized_name$() {\n"
    "  return $get_has_field_bit_message$;\n"
    "}\n");

  WriteFieldDocComment(printer, descriptor_);
  printer->Print(variables_,
    "$deprecation$public $type$ get$capitalized_name$() {\n"
    "  return $name$_;\n"
    "}\n");
}

void PrimitiveFieldGenerator::
GenerateBuilderMembers(io::Printer* printer) const {
  printer->Print(variables_,
    "private $field_type$ $name$_ $default_init$;\n");

  WriteFieldDocComment(printer, descriptor_);
  printer->Print(variables_,
    "$deprecation$public boolean has$capitalized_name$() {\n"
    "  return $get_has_field_bit_builder$;\n"
    "}\n");

  WriteFieldDocComment(printer, descriptor_);
  printer->Print(variables_,
    "$deprecation$public $type$ get$capitalized_name$() {\n"
    "  return $name$_;\n"
    "}\n");

  WriteFieldDocComment(printer, descriptor_);
  printer->Print(variables_,
    "$deprecation$public Builder set$capitalized_name$($type$ value) {\n"
    "$null_check$"
    "  $set_has_field_bit_builder$;\n"
    "  $name$_ = value;\n"
    "  $on_changed$\n"
    "  return this;\n"
    "}\n");

  WriteFieldDocComment(printer, descriptor_);
  printer->Print(variables_,
    "$deprecation$public Builder clear$capitalized_name$() {\n"
    "  $clear_has_field_bit_builder$;\n");
  JavaType type = GetJavaType(descriptor_);
  if (type == JAVATYPE_STRING || type == JAVATYPE_BYTES) {
    // The default value is not a simple literal so we want to avoid executing
    // it multiple times.  Instead, get the default out of the default instance.
    printer->Print(variables_,
      "  $name$_ = getDefaultInstance().get$capitalized_name$();\n");
  } else {
    printer->Print(variables_,
      "  $name$_ = $default$;\n");
  }
  printer->Print(variables_,
    "  $on_changed$\n"
    "  return this;\n"
    "}\n");
}

void PrimitiveFieldGenerator::
GenerateFieldBuilderInitializationCode(io::Printer* printer)  const {
  // noop for primitives
}

void PrimitiveFieldGenerator::
GenerateInitializationCode(io::Printer* printer) const {
  printer->Print(variables_, "$name$_ = $default$;\n");
}

void PrimitiveFieldGenerator::
GenerateBuilderClearCode(io::Printer* printer) const {
  printer->Print(variables_,
    "$name$_ = $default$;\n"
    "$clear_has_field_bit_builder$;\n");
}

void PrimitiveFieldGenerator::
GenerateMergingCode(io::Printer* printer) const {
  printer->Print(variables_,
    "if (other.has$capitalized_name$()) {\n"
    "  set$capitalized_name$(other.get$capitalized_name$());\n"
    "}\n");
}

void PrimitiveFieldGenerator::
GenerateBuildingCode(io::Printer* printer) const {
  printer->Print(variables_,
    "if ($get_has_field_bit_from_local$) {\n"
    "  $set_has_field_bit_to_local$;\n"
    "}\n"
    "result.$name$_ = $name$_;\n");
}

void PrimitiveFieldGenerator::
GenerateParsingCode(io::Printer* printer) const {
  printer->Print(variables_,
    "$set_has_field_bit_message$;\n"
    "$name$_ = input.read$capitalized_type$();\n");
}

void PrimitiveFieldGenerator::
GenerateParsingDoneCode(io::Printer* printer) const {
  // noop for primitives.
}

void PrimitiveFieldGenerator::
GenerateSerializationCode(io::Printer* printer) const {
  printer->Print(variables_,
    "if ($get_has_field_bit_message$) {\n"
    "  output.write$capitalized_type$($number$, $name$_);\n"
    "}\n");
}

void PrimitiveFieldGenerator::
GenerateSerializedSizeCode(io::Printer* printer) const {
  printer->Print(variables_,
    "if ($get_has_field_bit_message$) {\n"
    "  size += com.google.protobuf.CodedOutputStream\n"
    "    .compute$capitalized_type$Size($number$, $name$_);\n"
    "}\n");
}

void PrimitiveFieldGenerator::
GenerateEqualsCode(io::Printer* printer) const {
  switch (GetJavaType(descriptor_)) {
    case JAVATYPE_INT:
    case JAVATYPE_LONG:
    case JAVATYPE_BOOLEAN:
      printer->Print(variables_,
        "result = result && (get$capitalized_name$()\n"
        "    == other.get$capitalized_name$());\n");
      break;

    case JAVATYPE_FLOAT:
      printer->Print(variables_,
        "result = result && (Float.floatToIntBits(get$capitalized_name$())"
        "    == Float.floatToIntBits(other.get$capitalized_name$()));\n");
      break;

    case JAVATYPE_DOUBLE:
      printer->Print(variables_,
        "result = result && (Double.doubleToLongBits(get$capitalized_name$())"
        "    == Double.doubleToLongBits(other.get$capitalized_name$()));\n");
      break;

    case JAVATYPE_STRING:
    case JAVATYPE_BYTES:
      printer->Print(variables_,
        "result = result && get$capitalized_name$()\n"
        "    .equals(other.get$capitalized_name$());\n");
      break;

    case JAVATYPE_ENUM:
    case JAVATYPE_MESSAGE:
    default:
      GOOGLE_LOG(FATAL) << "Can't get here.";
      break;
  }
}

void PrimitiveFieldGenerator::
GenerateHashCode(io::Printer* printer) const {
  printer->Print(variables_,
    "hash = (37 * hash) + $constant_name$;\n");
  switch (GetJavaType(descriptor_)) {
    case JAVATYPE_INT:
      printer->Print(variables_,
        "hash = (53 * hash) + get$capitalized_name$();\n");
      break;

    case JAVATYPE_LONG:
      printer->Print(variables_,
        "hash = (53 * hash) + hashLong(get$capitalized_name$());\n");
      break;

    case JAVATYPE_BOOLEAN:
      printer->Print(variables_,
        "hash = (53 * hash) + hashBoolean(get$capitalized_name$());\n");
      break;

    case JAVATYPE_FLOAT:
      printer->Print(variables_,
        "hash = (53 * hash) + Float.floatToIntBits(\n"
        "    get$capitalized_name$());\n");
      break;

    case JAVATYPE_DOUBLE:
      printer->Print(variables_,
        "hash = (53 * hash) + hashLong(\n"
        "    Double.doubleToLongBits(get$capitalized_name$()));\n");
      break;

    case JAVATYPE_STRING:
    case JAVATYPE_BYTES:
      printer->Print(variables_,
        "hash = (53 * hash) + get$capitalized_name$().hashCode();\n");
      break;

    case JAVATYPE_ENUM:
    case JAVATYPE_MESSAGE:
    default:
      GOOGLE_LOG(FATAL) << "Can't get here.";
      break;
  }
}

string PrimitiveFieldGenerator::GetBoxedType() const {
  return BoxedPrimitiveTypeName(GetJavaType(descriptor_));
}

// ===================================================================

RepeatedPrimitiveFieldGenerator::
RepeatedPrimitiveFieldGenerator(const FieldDescriptor* descriptor,
                                int messageBitIndex,
                                int builderBitIndex)
  : descriptor_(descriptor), messageBitIndex_(messageBitIndex),
    builderBitIndex_(builderBitIndex) {
  SetPrimitiveVariables(descriptor, messageBitIndex, builderBitIndex,
                        &variables_);
}

RepeatedPrimitiveFieldGenerator::~RepeatedPrimitiveFieldGenerator() {}

int RepeatedPrimitiveFieldGenerator::GetNumBitsForMessage() const {
  return 0;
}

int RepeatedPrimitiveFieldGenerator::GetNumBitsForBuilder() const {
  return 1;
}

void RepeatedPrimitiveFieldGenerator::
GenerateInterfaceMembers(io::Printer* printer) const {
  WriteFieldDocComment(printer, descriptor_);
  printer->Print(variables_,
    "$deprecation$java.util.List<$boxed_type$> get$capitalized_name$List();\n");
  WriteFieldDocComment(printer, descriptor_);
  printer->Print(variables_,
    "$deprecation$int get$capitalized_name$Count();\n");
  WriteFieldDocComment(printer, descriptor_);
  printer->Print(variables_,
    "$deprecation$$type$ get$capitalized_name$(int index);\n");
}


void RepeatedPrimitiveFieldGenerator::
GenerateMembers(io::Printer* printer) const {
  printer->Print(variables_,
    "private $field_list_type$ $name$_;\n");
  WriteFieldDocComment(printer, descriptor_);
  printer->Print(variables_,
    "$deprecation$public java.util.List<$boxed_type$>\n"
    "    get$capitalized_name$List() {\n"
    "  return $name$_;\n"   // note:  unmodifiable list
    "}\n");
  WriteFieldDocComment(printer, descriptor_);
  printer->Print(variables_,
    "$deprecation$public int get$capitalized_name$Count() {\n"
    "  return $name$_.size();\n"
    "}\n");
  WriteFieldDocComment(printer, descriptor_);
  printer->Print(variables_,
    "$deprecation$public $type$ get$capitalized_name$(int index) {\n"
    "  return $name$_.get(index);\n"
    "}\n");

  if (descriptor_->options().packed() &&
      HasGeneratedMethods(descriptor_->containing_type())) {
    printer->Print(variables_,
      "private int $name$MemoizedSerializedSize = -1;\n");
  }
}

void RepeatedPrimitiveFieldGenerator::
GenerateBuilderMembers(io::Printer* printer) const {
  // One field is the list and the bit field keeps track of whether the
  // list is immutable. If it's immutable, the invariant is that it must
  // either an instance of Collections.emptyList() or it's an ArrayList
  // wrapped in a Collections.unmodifiableList() wrapper and nobody else has
  // a refererence to the underlying ArrayList. This invariant allows us to
  // share instances of lists between protocol buffers avoiding expensive
  // memory allocations. Note, immutable is a strong guarantee here -- not
  // just that the list cannot be modified via the reference but that the
  // list can never be modified.
  printer->Print(variables_,
    "private $field_list_type$ $name$_ = $empty_list$;\n");

  printer->Print(variables_,
    "private void ensure$capitalized_name$IsMutable() {\n"
    "  if (!$get_mutable_bit_builder$) {\n"
    "    $name$_ = new java.util.ArrayList<$boxed_type$>($name$_);\n"
    "    $set_mutable_bit_builder$;\n"
    "   }\n"
    "}\n");

    // Note:  We return an unmodifiable list because otherwise the caller
    //   could hold on to the returned list and modify it after the message
    //   has been built, thus mutating the message which is supposed to be
    //   immutable.
  WriteFieldDocComment(printer, descriptor_);
  printer->Print(variables_,
    "$deprecation$public java.util.List<$boxed_type$>\n"
    "    get$capitalized_name$List() {\n"
    "  return java.util.Collections.unmodifiableList($name$_);\n"
    "}\n");
  WriteFieldDocComment(printer, descriptor_);
  printer->Print(variables_,
    "$deprecation$public int get$capitalized_name$Count() {\n"
    "  return $name$_.size();\n"
    "}\n");
  WriteFieldDocComment(printer, descriptor_);
  printer->Print(variables_,
    "$deprecation$public $type$ get$capitalized_name$(int index) {\n"
    "  return $name$_.get(index);\n"
    "}\n");
  WriteFieldDocComment(printer, descriptor_);
  printer->Print(variables_,
    "$deprecation$public Builder set$capitalized_name$(\n"
    "    int index, $type$ value) {\n"
    "$null_check$"
    "  ensure$capitalized_name$IsMutable();\n"
    "  $name$_.set(index, value);\n"
    "  $on_changed$\n"
    "  return this;\n"
    "}\n");
  WriteFieldDocComment(printer, descriptor_);
  printer->Print(variables_,
    "$deprecation$public Builder add$capitalized_name$($type$ value) {\n"
    "$null_check$"
    "  ensure$capitalized_name$IsMutable();\n"
    "  $name$_.add(value);\n"
    "  $on_changed$\n"
    "  return this;\n"
    "}\n");
  WriteFieldDocComment(printer, descriptor_);
  printer->Print(variables_,
    "$deprecation$public Builder addAll$capitalized_name$(\n"
    "    java.lang.Iterable<? extends $boxed_type$> values) {\n"
    "  ensure$capitalized_name$IsMutable();\n"
    "  super.addAll(values, $name$_);\n"
    "  $on_changed$\n"
    "  return this;\n"
    "}\n");
  WriteFieldDocComment(printer, descriptor_);
  printer->Print(variables_,
    "$deprecation$public Builder clear$capitalized_name$() {\n"
    "  $name$_ = $empty_list$;\n"
    "  $clear_mutable_bit_builder$;\n"
    "  $on_changed$\n"
    "  return this;\n"
    "}\n");
}

void RepeatedPrimitiveFieldGenerator::
GenerateFieldBuilderInitializationCode(io::Printer* printer)  const {
  // noop for primitives
}

void RepeatedPrimitiveFieldGenerator::
GenerateInitializationCode(io::Printer* printer) const {
  printer->Print(variables_, "$name$_ = $empty_list$;\n");
}

void RepeatedPrimitiveFieldGenerator::
GenerateBuilderClearCode(io::Printer* printer) const {
  printer->Print(variables_,
    "$name$_ = $empty_list$;\n"
    "$clear_mutable_bit_builder$;\n");
}

void RepeatedPrimitiveFieldGenerator::
GenerateMergingCode(io::Printer* printer) const {
  // The code below does two optimizations:
  //   1. If the other list is empty, there's nothing to do. This ensures we
  //      don't allocate a new array if we already have an immutable one.
  //   2. If the other list is non-empty and our current list is empty, we can
  //      reuse the other list which is guaranteed to be immutable.
  printer->Print(variables_,
    "if (!other.$name$_.isEmpty()) {\n"
    "  if ($name$_.isEmpty()) {\n"
    "    $name$_ = other.$name$_;\n"
    "    $clear_mutable_bit_builder$;\n"
    "  } else {\n"
    "    ensure$capitalized_name$IsMutable();\n"
    "    $name$_.addAll(other.$name$_);\n"
    "  }\n"
    "  $on_changed$\n"
    "}\n");
}

void RepeatedPrimitiveFieldGenerator::
GenerateBuildingCode(io::Printer* printer) const {
  // The code below ensures that the result has an immutable list. If our
  // list is immutable, we can just reuse it. If not, we make it immutable.
  printer->Print(variables_,
    "if ($get_mutable_bit_builder$) {\n"
    "  $name$_ = java.util.Collections.unmodifiableList($name$_);\n"
    "  $clear_mutable_bit_builder$;\n"
    "}\n"
    "result.$name$_ = $name$_;\n");
}

void RepeatedPrimitiveFieldGenerator::
GenerateParsingCode(io::Printer* printer) const {
  printer->Print(variables_,
    "if (!$get_mutable_bit_parser$) {\n"
    "  $name$_ = new java.util.ArrayList<$boxed_type$>();\n"
    "  $set_mutable_bit_parser$;\n"
    "}\n"
    "$name$_.add(input.read$capitalized_type$());\n");
}

void RepeatedPrimitiveFieldGenerator::
GenerateParsingCodeFromPacked(io::Printer* printer) const {
  printer->Print(variables_,
    "int length = input.readRawVarint32();\n"
    "int limit = input.pushLimit(length);\n"
    "if (!$get_mutable_bit_parser$ && input.getBytesUntilLimit() > 0) {\n"
    "  $name$_ = new java.util.ArrayList<$boxed_type$>();\n"
    "  $set_mutable_bit_parser$;\n"
    "}\n"
    "while (input.getBytesUntilLimit() > 0) {\n"
    "  $name$_.add(input.read$capitalized_type$());\n"
    "}\n"
    "input.popLimit(limit);\n");
}

void RepeatedPrimitiveFieldGenerator::
GenerateParsingDoneCode(io::Printer* printer) const {
  printer->Print(variables_,
    "if ($get_mutable_bit_parser$) {\n"
    "  $name$_ = java.util.Collections.unmodifiableList($name$_);\n"
    "}\n");
}

void RepeatedPrimitiveFieldGenerator::
GenerateSerializationCode(io::Printer* printer) const {
  if (descriptor_->options().packed()) {
    printer->Print(variables_,
      "if (get$capitalized_name$List().size() > 0) {\n"
      "  output.writeRawVarint32($tag$);\n"
      "  output.writeRawVarint32($name$MemoizedSerializedSize);\n"
      "}\n"
      "for (int i = 0; i < $name$_.size(); i++) {\n"
      "  output.write$capitalized_type$NoTag($name$_.get(i));\n"
      "}\n");
  } else {
    printer->Print(variables_,
      "for (int i = 0; i < $name$_.size(); i++) {\n"
      "  output.write$capitalized_type$($number$, $name$_.get(i));\n"
      "}\n");
  }
}

void RepeatedPrimitiveFieldGenerator::
GenerateSerializedSizeCode(io::Printer* printer) const {
  printer->Print(variables_,
    "{\n"
    "  int dataSize = 0;\n");
  printer->Indent();

  if (FixedSize(GetType(descriptor_)) == -1) {
    printer->Print(variables_,
      "for (int i = 0; i < $name$_.size(); i++) {\n"
      "  dataSize += com.google.protobuf.CodedOutputStream\n"
      "    .compute$capitalized_type$SizeNoTag($name$_.get(i));\n"
      "}\n");
  } else {
    printer->Print(variables_,
      "dataSize = $fixed_size$ * get$capitalized_name$List().size();\n");
  }

  printer->Print(
      "size += dataSize;\n");

  if (descriptor_->options().packed()) {
    printer->Print(variables_,
      "if (!get$capitalized_name$List().isEmpty()) {\n"
      "  size += $tag_size$;\n"
      "  size += com.google.protobuf.CodedOutputStream\n"
      "      .computeInt32SizeNoTag(dataSize);\n"
      "}\n");
  } else {
    printer->Print(variables_,
      "size += $tag_size$ * get$capitalized_name$List().size();\n");
  }

  // cache the data size for packed fields.
  if (descriptor_->options().packed()) {
    printer->Print(variables_,
      "$name$MemoizedSerializedSize = dataSize;\n");
  }

  printer->Outdent();
  printer->Print("}\n");
}

void RepeatedPrimitiveFieldGenerator::
GenerateEqualsCode(io::Printer* printer) const {
  printer->Print(variables_,
    "result = result && get$capitalized_name$List()\n"
    "    .equals(other.get$capitalized_name$List());\n");
}

void RepeatedPrimitiveFieldGenerator::
GenerateHashCode(io::Printer* printer) const {
  printer->Print(variables_,
    "if (get$capitalized_name$Count() > 0) {\n"
    "  hash = (37 * hash) + $constant_name$;\n"
    "  hash = (53 * hash) + get$capitalized_name$List().hashCode();\n"
    "}\n");
}

string RepeatedPrimitiveFieldGenerator::GetBoxedType() const {
  return BoxedPrimitiveTypeName(GetJavaType(descriptor_));
}

}  // namespace java
}  // namespace compiler
}  // namespace protobuf
}  // namespace google
