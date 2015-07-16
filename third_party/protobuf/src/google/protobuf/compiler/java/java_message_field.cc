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

#include <google/protobuf/compiler/java/java_message_field.h>
#include <google/protobuf/compiler/java/java_doc_comment.h>
#include <google/protobuf/compiler/java/java_helpers.h>
#include <google/protobuf/io/printer.h>
#include <google/protobuf/wire_format.h>
#include <google/protobuf/stubs/strutil.h>

namespace google {
namespace protobuf {
namespace compiler {
namespace java {

namespace {

// TODO(kenton):  Factor out a "SetCommonFieldVariables()" to get rid of
//   repeat code between this and the other field types.
void SetMessageVariables(const FieldDescriptor* descriptor,
                         int messageBitIndex,
                         int builderBitIndex,
                         map<string, string>* variables) {
  (*variables)["name"] =
    UnderscoresToCamelCase(descriptor);
  (*variables)["capitalized_name"] =
    UnderscoresToCapitalizedCamelCase(descriptor);
  (*variables)["constant_name"] = FieldConstantName(descriptor);
  (*variables)["number"] = SimpleItoa(descriptor->number());
  (*variables)["type"] = ClassName(descriptor->message_type());
  (*variables)["group_or_message"] =
    (GetType(descriptor) == FieldDescriptor::TYPE_GROUP) ?
    "Group" : "Message";
  // TODO(birdo): Add @deprecated javadoc when generating javadoc is supported
  // by the proto compiler
  (*variables)["deprecation"] = descriptor->options().deprecated()
      ? "@java.lang.Deprecated " : "";
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

MessageFieldGenerator::
MessageFieldGenerator(const FieldDescriptor* descriptor,
                      int messageBitIndex,
                      int builderBitIndex)
  : descriptor_(descriptor), messageBitIndex_(messageBitIndex),
    builderBitIndex_(builderBitIndex) {
  SetMessageVariables(descriptor, messageBitIndex, builderBitIndex,
                      &variables_);
}

MessageFieldGenerator::~MessageFieldGenerator() {}

int MessageFieldGenerator::GetNumBitsForMessage() const {
  return 1;
}

int MessageFieldGenerator::GetNumBitsForBuilder() const {
  return 1;
}

void MessageFieldGenerator::
GenerateInterfaceMembers(io::Printer* printer) const {
  // TODO(jonp): In the future, consider having a method specific to the
  // interface so that builders can choose dynamically to either return a
  // message or a nested builder, so that asking for the interface doesn't
  // cause a message to ever be built.
  WriteFieldDocComment(printer, descriptor_);
  printer->Print(variables_,
    "$deprecation$boolean has$capitalized_name$();\n");
  WriteFieldDocComment(printer, descriptor_);
  printer->Print(variables_,
    "$deprecation$$type$ get$capitalized_name$();\n");

  if (HasNestedBuilders(descriptor_->containing_type())) {
    WriteFieldDocComment(printer, descriptor_);
    printer->Print(variables_,
      "$deprecation$$type$OrBuilder get$capitalized_name$OrBuilder();\n");
  }
}

void MessageFieldGenerator::
GenerateMembers(io::Printer* printer) const {
  printer->Print(variables_,
    "private $type$ $name$_;\n");
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

  if (HasNestedBuilders(descriptor_->containing_type())) {
    WriteFieldDocComment(printer, descriptor_);
    printer->Print(variables_,
      "$deprecation$public $type$OrBuilder get$capitalized_name$OrBuilder() {\n"
      "  return $name$_;\n"
      "}\n");
  }
}

void MessageFieldGenerator::PrintNestedBuilderCondition(
    io::Printer* printer,
    const char* regular_case,
    const char* nested_builder_case) const {
  if (HasNestedBuilders(descriptor_->containing_type())) {
     printer->Print(variables_, "if ($name$Builder_ == null) {\n");
     printer->Indent();
     printer->Print(variables_, regular_case);
     printer->Outdent();
     printer->Print("} else {\n");
     printer->Indent();
     printer->Print(variables_, nested_builder_case);
     printer->Outdent();
     printer->Print("}\n");
   } else {
     printer->Print(variables_, regular_case);
   }
}

void MessageFieldGenerator::PrintNestedBuilderFunction(
    io::Printer* printer,
    const char* method_prototype,
    const char* regular_case,
    const char* nested_builder_case,
    const char* trailing_code) const {
  printer->Print(variables_, method_prototype);
  printer->Print(" {\n");
  printer->Indent();
  PrintNestedBuilderCondition(printer, regular_case, nested_builder_case);
  if (trailing_code != NULL) {
    printer->Print(variables_, trailing_code);
  }
  printer->Outdent();
  printer->Print("}\n");
}

void MessageFieldGenerator::
GenerateBuilderMembers(io::Printer* printer) const {
  // When using nested-builders, the code initially works just like the
  // non-nested builder case. It only creates a nested builder lazily on
  // demand and then forever delegates to it after creation.

  printer->Print(variables_,
    // Used when the builder is null.
    "private $type$ $name$_ = $type$.getDefaultInstance();\n");

  if (HasNestedBuilders(descriptor_->containing_type())) {
    printer->Print(variables_,
      // If this builder is non-null, it is used and the other fields are
      // ignored.
      "private com.google.protobuf.SingleFieldBuilder<\n"
      "    $type$, $type$.Builder, $type$OrBuilder> $name$Builder_;"
      "\n");
  }

  // The comments above the methods below are based on a hypothetical
  // field of type "Field" called "Field".

  // boolean hasField()
  WriteFieldDocComment(printer, descriptor_);
  printer->Print(variables_,
    "$deprecation$public boolean has$capitalized_name$() {\n"
    "  return $get_has_field_bit_builder$;\n"
    "}\n");

  // Field getField()
  WriteFieldDocComment(printer, descriptor_);
  PrintNestedBuilderFunction(printer,
    "$deprecation$public $type$ get$capitalized_name$()",

    "return $name$_;\n",

    "return $name$Builder_.getMessage();\n",

    NULL);

  // Field.Builder setField(Field value)
  WriteFieldDocComment(printer, descriptor_);
  PrintNestedBuilderFunction(printer,
    "$deprecation$public Builder set$capitalized_name$($type$ value)",

    "if (value == null) {\n"
    "  throw new NullPointerException();\n"
    "}\n"
    "$name$_ = value;\n"
    "$on_changed$\n",

    "$name$Builder_.setMessage(value);\n",

    "$set_has_field_bit_builder$;\n"
    "return this;\n");

  // Field.Builder setField(Field.Builder builderForValue)
  WriteFieldDocComment(printer, descriptor_);
  PrintNestedBuilderFunction(printer,
    "$deprecation$public Builder set$capitalized_name$(\n"
    "    $type$.Builder builderForValue)",

    "$name$_ = builderForValue.build();\n"
    "$on_changed$\n",

    "$name$Builder_.setMessage(builderForValue.build());\n",

    "$set_has_field_bit_builder$;\n"
    "return this;\n");

  // Field.Builder mergeField(Field value)
  WriteFieldDocComment(printer, descriptor_);
  PrintNestedBuilderFunction(printer,
    "$deprecation$public Builder merge$capitalized_name$($type$ value)",

    "if ($get_has_field_bit_builder$ &&\n"
    "    $name$_ != $type$.getDefaultInstance()) {\n"
    "  $name$_ =\n"
    "    $type$.newBuilder($name$_).mergeFrom(value).buildPartial();\n"
    "} else {\n"
    "  $name$_ = value;\n"
    "}\n"
    "$on_changed$\n",

    "$name$Builder_.mergeFrom(value);\n",

    "$set_has_field_bit_builder$;\n"
    "return this;\n");

  // Field.Builder clearField()
  WriteFieldDocComment(printer, descriptor_);
  PrintNestedBuilderFunction(printer,
    "$deprecation$public Builder clear$capitalized_name$()",

    "$name$_ = $type$.getDefaultInstance();\n"
    "$on_changed$\n",

    "$name$Builder_.clear();\n",

    "$clear_has_field_bit_builder$;\n"
    "return this;\n");

  if (HasNestedBuilders(descriptor_->containing_type())) {
    WriteFieldDocComment(printer, descriptor_);
    printer->Print(variables_,
      "$deprecation$public $type$.Builder get$capitalized_name$Builder() {\n"
      "  $set_has_field_bit_builder$;\n"
      "  $on_changed$\n"
      "  return get$capitalized_name$FieldBuilder().getBuilder();\n"
      "}\n");
    WriteFieldDocComment(printer, descriptor_);
    printer->Print(variables_,
      "$deprecation$public $type$OrBuilder get$capitalized_name$OrBuilder() {\n"
      "  if ($name$Builder_ != null) {\n"
      "    return $name$Builder_.getMessageOrBuilder();\n"
      "  } else {\n"
      "    return $name$_;\n"
      "  }\n"
      "}\n");
    WriteFieldDocComment(printer, descriptor_);
    printer->Print(variables_,
      "private com.google.protobuf.SingleFieldBuilder<\n"
      "    $type$, $type$.Builder, $type$OrBuilder> \n"
      "    get$capitalized_name$FieldBuilder() {\n"
      "  if ($name$Builder_ == null) {\n"
      "    $name$Builder_ = new com.google.protobuf.SingleFieldBuilder<\n"
      "        $type$, $type$.Builder, $type$OrBuilder>(\n"
      "            $name$_,\n"
      "            getParentForChildren(),\n"
      "            isClean());\n"
      "    $name$_ = null;\n"
      "  }\n"
      "  return $name$Builder_;\n"
      "}\n");
  }
}

void MessageFieldGenerator::
GenerateFieldBuilderInitializationCode(io::Printer* printer)  const {
  printer->Print(variables_,
    "get$capitalized_name$FieldBuilder();\n");
}


void MessageFieldGenerator::
GenerateInitializationCode(io::Printer* printer) const {
  printer->Print(variables_, "$name$_ = $type$.getDefaultInstance();\n");
}

void MessageFieldGenerator::
GenerateBuilderClearCode(io::Printer* printer) const {
  PrintNestedBuilderCondition(printer,
    "$name$_ = $type$.getDefaultInstance();\n",

    "$name$Builder_.clear();\n");
  printer->Print(variables_, "$clear_has_field_bit_builder$;\n");
}

void MessageFieldGenerator::
GenerateMergingCode(io::Printer* printer) const {
  printer->Print(variables_,
    "if (other.has$capitalized_name$()) {\n"
    "  merge$capitalized_name$(other.get$capitalized_name$());\n"
    "}\n");
}

void MessageFieldGenerator::
GenerateBuildingCode(io::Printer* printer) const {

  printer->Print(variables_,
      "if ($get_has_field_bit_from_local$) {\n"
      "  $set_has_field_bit_to_local$;\n"
      "}\n");

  PrintNestedBuilderCondition(printer,
    "result.$name$_ = $name$_;\n",

    "result.$name$_ = $name$Builder_.build();\n");
}

void MessageFieldGenerator::
GenerateParsingCode(io::Printer* printer) const {
  printer->Print(variables_,
    "$type$.Builder subBuilder = null;\n"
    "if ($get_has_field_bit_message$) {\n"
    "  subBuilder = $name$_.toBuilder();\n"
    "}\n");

  if (GetType(descriptor_) == FieldDescriptor::TYPE_GROUP) {
    printer->Print(variables_,
      "$name$_ = input.readGroup($number$, $type$.PARSER,\n"
      "    extensionRegistry);\n");
  } else {
    printer->Print(variables_,
      "$name$_ = input.readMessage($type$.PARSER, extensionRegistry);\n");
  }

  printer->Print(variables_,
    "if (subBuilder != null) {\n"
    "  subBuilder.mergeFrom($name$_);\n"
    "  $name$_ = subBuilder.buildPartial();\n"
    "}\n");
  printer->Print(variables_,
    "$set_has_field_bit_message$;\n");
}

void MessageFieldGenerator::
GenerateParsingDoneCode(io::Printer* printer) const {
  // noop for messages.
}

void MessageFieldGenerator::
GenerateSerializationCode(io::Printer* printer) const {
  printer->Print(variables_,
    "if ($get_has_field_bit_message$) {\n"
    "  output.write$group_or_message$($number$, $name$_);\n"
    "}\n");
}

void MessageFieldGenerator::
GenerateSerializedSizeCode(io::Printer* printer) const {
  printer->Print(variables_,
    "if ($get_has_field_bit_message$) {\n"
    "  size += com.google.protobuf.CodedOutputStream\n"
    "    .compute$group_or_message$Size($number$, $name$_);\n"
    "}\n");
}

void MessageFieldGenerator::
GenerateEqualsCode(io::Printer* printer) const {
  printer->Print(variables_,
    "result = result && get$capitalized_name$()\n"
    "    .equals(other.get$capitalized_name$());\n");
}

void MessageFieldGenerator::
GenerateHashCode(io::Printer* printer) const {
  printer->Print(variables_,
    "hash = (37 * hash) + $constant_name$;\n"
    "hash = (53 * hash) + get$capitalized_name$().hashCode();\n");
}

string MessageFieldGenerator::GetBoxedType() const {
  return ClassName(descriptor_->message_type());
}

// ===================================================================

RepeatedMessageFieldGenerator::
RepeatedMessageFieldGenerator(const FieldDescriptor* descriptor,
                              int messageBitIndex,
                              int builderBitIndex)
  : descriptor_(descriptor), messageBitIndex_(messageBitIndex),
    builderBitIndex_(builderBitIndex) {
  SetMessageVariables(descriptor, messageBitIndex, builderBitIndex,
                      &variables_);
}

RepeatedMessageFieldGenerator::~RepeatedMessageFieldGenerator() {}

int RepeatedMessageFieldGenerator::GetNumBitsForMessage() const {
  return 0;
}

int RepeatedMessageFieldGenerator::GetNumBitsForBuilder() const {
  return 1;
}

void RepeatedMessageFieldGenerator::
GenerateInterfaceMembers(io::Printer* printer) const {
  // TODO(jonp): In the future, consider having methods specific to the
  // interface so that builders can choose dynamically to either return a
  // message or a nested builder, so that asking for the interface doesn't
  // cause a message to ever be built.
  WriteFieldDocComment(printer, descriptor_);
  printer->Print(variables_,
    "$deprecation$java.util.List<$type$> \n"
    "    get$capitalized_name$List();\n");
  WriteFieldDocComment(printer, descriptor_);
  printer->Print(variables_,
    "$deprecation$$type$ get$capitalized_name$(int index);\n");
  WriteFieldDocComment(printer, descriptor_);
  printer->Print(variables_,
    "$deprecation$int get$capitalized_name$Count();\n");
  if (HasNestedBuilders(descriptor_->containing_type())) {
    WriteFieldDocComment(printer, descriptor_);
    printer->Print(variables_,
      "$deprecation$java.util.List<? extends $type$OrBuilder> \n"
      "    get$capitalized_name$OrBuilderList();\n");
    WriteFieldDocComment(printer, descriptor_);
    printer->Print(variables_,
      "$deprecation$$type$OrBuilder get$capitalized_name$OrBuilder(\n"
      "    int index);\n");
  }
}

void RepeatedMessageFieldGenerator::
GenerateMembers(io::Printer* printer) const {
  printer->Print(variables_,
    "private java.util.List<$type$> $name$_;\n");
  WriteFieldDocComment(printer, descriptor_);
  printer->Print(variables_,
    "$deprecation$public java.util.List<$type$> get$capitalized_name$List() {\n"
    "  return $name$_;\n"   // note:  unmodifiable list
    "}\n");
  WriteFieldDocComment(printer, descriptor_);
  printer->Print(variables_,
    "$deprecation$public java.util.List<? extends $type$OrBuilder> \n"
    "    get$capitalized_name$OrBuilderList() {\n"
    "  return $name$_;\n"
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
    "$deprecation$public $type$OrBuilder get$capitalized_name$OrBuilder(\n"
    "    int index) {\n"
    "  return $name$_.get(index);\n"
    "}\n");

}

void RepeatedMessageFieldGenerator::PrintNestedBuilderCondition(
    io::Printer* printer,
    const char* regular_case,
    const char* nested_builder_case) const {
  if (HasNestedBuilders(descriptor_->containing_type())) {
     printer->Print(variables_, "if ($name$Builder_ == null) {\n");
     printer->Indent();
     printer->Print(variables_, regular_case);
     printer->Outdent();
     printer->Print("} else {\n");
     printer->Indent();
     printer->Print(variables_, nested_builder_case);
     printer->Outdent();
     printer->Print("}\n");
   } else {
     printer->Print(variables_, regular_case);
   }
}

void RepeatedMessageFieldGenerator::PrintNestedBuilderFunction(
    io::Printer* printer,
    const char* method_prototype,
    const char* regular_case,
    const char* nested_builder_case,
    const char* trailing_code) const {
  printer->Print(variables_, method_prototype);
  printer->Print(" {\n");
  printer->Indent();
  PrintNestedBuilderCondition(printer, regular_case, nested_builder_case);
  if (trailing_code != NULL) {
    printer->Print(variables_, trailing_code);
  }
  printer->Outdent();
  printer->Print("}\n");
}

void RepeatedMessageFieldGenerator::
GenerateBuilderMembers(io::Printer* printer) const {
  // When using nested-builders, the code initially works just like the
  // non-nested builder case. It only creates a nested builder lazily on
  // demand and then forever delegates to it after creation.

  printer->Print(variables_,
    // Used when the builder is null.
    // One field is the list and the other field keeps track of whether the
    // list is immutable. If it's immutable, the invariant is that it must
    // either an instance of Collections.emptyList() or it's an ArrayList
    // wrapped in a Collections.unmodifiableList() wrapper and nobody else has
    // a refererence to the underlying ArrayList. This invariant allows us to
    // share instances of lists between protocol buffers avoiding expensive
    // memory allocations. Note, immutable is a strong guarantee here -- not
    // just that the list cannot be modified via the reference but that the
    // list can never be modified.
    "private java.util.List<$type$> $name$_ =\n"
    "  java.util.Collections.emptyList();\n"

    "private void ensure$capitalized_name$IsMutable() {\n"
    "  if (!$get_mutable_bit_builder$) {\n"
    "    $name$_ = new java.util.ArrayList<$type$>($name$_);\n"
    "    $set_mutable_bit_builder$;\n"
    "   }\n"
    "}\n"
    "\n");

  if (HasNestedBuilders(descriptor_->containing_type())) {
    printer->Print(variables_,
      // If this builder is non-null, it is used and the other fields are
      // ignored.
      "private com.google.protobuf.RepeatedFieldBuilder<\n"
      "    $type$, $type$.Builder, $type$OrBuilder> $name$Builder_;\n"
      "\n");
  }

  // The comments above the methods below are based on a hypothetical
  // repeated field of type "Field" called "RepeatedField".

  // List<Field> getRepeatedFieldList()
  WriteFieldDocComment(printer, descriptor_);
  PrintNestedBuilderFunction(printer,
    "$deprecation$public java.util.List<$type$> get$capitalized_name$List()",

    "return java.util.Collections.unmodifiableList($name$_);\n",
    "return $name$Builder_.getMessageList();\n",

    NULL);

  // int getRepeatedFieldCount()
  WriteFieldDocComment(printer, descriptor_);
  PrintNestedBuilderFunction(printer,
    "$deprecation$public int get$capitalized_name$Count()",

    "return $name$_.size();\n",
    "return $name$Builder_.getCount();\n",

    NULL);

  // Field getRepeatedField(int index)
  WriteFieldDocComment(printer, descriptor_);
  PrintNestedBuilderFunction(printer,
    "$deprecation$public $type$ get$capitalized_name$(int index)",

    "return $name$_.get(index);\n",

    "return $name$Builder_.getMessage(index);\n",

    NULL);

  // Builder setRepeatedField(int index, Field value)
  WriteFieldDocComment(printer, descriptor_);
  PrintNestedBuilderFunction(printer,
    "$deprecation$public Builder set$capitalized_name$(\n"
    "    int index, $type$ value)",
    "if (value == null) {\n"
    "  throw new NullPointerException();\n"
    "}\n"
    "ensure$capitalized_name$IsMutable();\n"
    "$name$_.set(index, value);\n"
    "$on_changed$\n",
    "$name$Builder_.setMessage(index, value);\n",
    "return this;\n");

  // Builder setRepeatedField(int index, Field.Builder builderForValue)
  WriteFieldDocComment(printer, descriptor_);
  PrintNestedBuilderFunction(printer,
    "$deprecation$public Builder set$capitalized_name$(\n"
    "    int index, $type$.Builder builderForValue)",

    "ensure$capitalized_name$IsMutable();\n"
    "$name$_.set(index, builderForValue.build());\n"
    "$on_changed$\n",

    "$name$Builder_.setMessage(index, builderForValue.build());\n",

    "return this;\n");

  // Builder addRepeatedField(Field value)
  WriteFieldDocComment(printer, descriptor_);
  PrintNestedBuilderFunction(printer,
    "$deprecation$public Builder add$capitalized_name$($type$ value)",

    "if (value == null) {\n"
    "  throw new NullPointerException();\n"
    "}\n"
    "ensure$capitalized_name$IsMutable();\n"
    "$name$_.add(value);\n"

    "$on_changed$\n",

    "$name$Builder_.addMessage(value);\n",

    "return this;\n");

  // Builder addRepeatedField(int index, Field value)
  WriteFieldDocComment(printer, descriptor_);
  PrintNestedBuilderFunction(printer,
    "$deprecation$public Builder add$capitalized_name$(\n"
    "    int index, $type$ value)",

    "if (value == null) {\n"
    "  throw new NullPointerException();\n"
    "}\n"
    "ensure$capitalized_name$IsMutable();\n"
    "$name$_.add(index, value);\n"
    "$on_changed$\n",

    "$name$Builder_.addMessage(index, value);\n",

    "return this;\n");

  // Builder addRepeatedField(Field.Builder builderForValue)
  WriteFieldDocComment(printer, descriptor_);
  PrintNestedBuilderFunction(printer,
    "$deprecation$public Builder add$capitalized_name$(\n"
    "    $type$.Builder builderForValue)",

    "ensure$capitalized_name$IsMutable();\n"
    "$name$_.add(builderForValue.build());\n"
    "$on_changed$\n",

    "$name$Builder_.addMessage(builderForValue.build());\n",

    "return this;\n");

  // Builder addRepeatedField(int index, Field.Builder builderForValue)
  WriteFieldDocComment(printer, descriptor_);
  PrintNestedBuilderFunction(printer,
    "$deprecation$public Builder add$capitalized_name$(\n"
    "    int index, $type$.Builder builderForValue)",

    "ensure$capitalized_name$IsMutable();\n"
    "$name$_.add(index, builderForValue.build());\n"
    "$on_changed$\n",

    "$name$Builder_.addMessage(index, builderForValue.build());\n",

    "return this;\n");

  // Builder addAllRepeatedField(Iterable<Field> values)
  WriteFieldDocComment(printer, descriptor_);
  PrintNestedBuilderFunction(printer,
    "$deprecation$public Builder addAll$capitalized_name$(\n"
    "    java.lang.Iterable<? extends $type$> values)",

    "ensure$capitalized_name$IsMutable();\n"
    "super.addAll(values, $name$_);\n"
    "$on_changed$\n",

    "$name$Builder_.addAllMessages(values);\n",

    "return this;\n");

  // Builder clearAllRepeatedField()
  WriteFieldDocComment(printer, descriptor_);
  PrintNestedBuilderFunction(printer,
    "$deprecation$public Builder clear$capitalized_name$()",

    "$name$_ = java.util.Collections.emptyList();\n"
    "$clear_mutable_bit_builder$;\n"
    "$on_changed$\n",

    "$name$Builder_.clear();\n",

    "return this;\n");

  // Builder removeRepeatedField(int index)
  WriteFieldDocComment(printer, descriptor_);
  PrintNestedBuilderFunction(printer,
    "$deprecation$public Builder remove$capitalized_name$(int index)",

    "ensure$capitalized_name$IsMutable();\n"
    "$name$_.remove(index);\n"
    "$on_changed$\n",

    "$name$Builder_.remove(index);\n",

    "return this;\n");

  if (HasNestedBuilders(descriptor_->containing_type())) {
    WriteFieldDocComment(printer, descriptor_);
    printer->Print(variables_,
      "$deprecation$public $type$.Builder get$capitalized_name$Builder(\n"
      "    int index) {\n"
      "  return get$capitalized_name$FieldBuilder().getBuilder(index);\n"
      "}\n");

    WriteFieldDocComment(printer, descriptor_);
        printer->Print(variables_,
      "$deprecation$public $type$OrBuilder get$capitalized_name$OrBuilder(\n"
      "    int index) {\n"
      "  if ($name$Builder_ == null) {\n"
      "    return $name$_.get(index);"
      "  } else {\n"
      "    return $name$Builder_.getMessageOrBuilder(index);\n"
      "  }\n"
      "}\n");

    WriteFieldDocComment(printer, descriptor_);
        printer->Print(variables_,
      "$deprecation$public java.util.List<? extends $type$OrBuilder> \n"
      "     get$capitalized_name$OrBuilderList() {\n"
      "  if ($name$Builder_ != null) {\n"
      "    return $name$Builder_.getMessageOrBuilderList();\n"
      "  } else {\n"
      "    return java.util.Collections.unmodifiableList($name$_);\n"
      "  }\n"
      "}\n");

    WriteFieldDocComment(printer, descriptor_);
        printer->Print(variables_,
      "$deprecation$public $type$.Builder add$capitalized_name$Builder() {\n"
      "  return get$capitalized_name$FieldBuilder().addBuilder(\n"
      "      $type$.getDefaultInstance());\n"
      "}\n");
    WriteFieldDocComment(printer, descriptor_);
        printer->Print(variables_,
      "$deprecation$public $type$.Builder add$capitalized_name$Builder(\n"
      "    int index) {\n"
      "  return get$capitalized_name$FieldBuilder().addBuilder(\n"
      "      index, $type$.getDefaultInstance());\n"
      "}\n");
    WriteFieldDocComment(printer, descriptor_);
        printer->Print(variables_,
      "$deprecation$public java.util.List<$type$.Builder> \n"
      "     get$capitalized_name$BuilderList() {\n"
      "  return get$capitalized_name$FieldBuilder().getBuilderList();\n"
      "}\n"
      "private com.google.protobuf.RepeatedFieldBuilder<\n"
      "    $type$, $type$.Builder, $type$OrBuilder> \n"
      "    get$capitalized_name$FieldBuilder() {\n"
      "  if ($name$Builder_ == null) {\n"
      "    $name$Builder_ = new com.google.protobuf.RepeatedFieldBuilder<\n"
      "        $type$, $type$.Builder, $type$OrBuilder>(\n"
      "            $name$_,\n"
      "            $get_mutable_bit_builder$,\n"
      "            getParentForChildren(),\n"
      "            isClean());\n"
      "    $name$_ = null;\n"
      "  }\n"
      "  return $name$Builder_;\n"
      "}\n");
  }
}

void RepeatedMessageFieldGenerator::
GenerateFieldBuilderInitializationCode(io::Printer* printer)  const {
  printer->Print(variables_,
    "get$capitalized_name$FieldBuilder();\n");
}

void RepeatedMessageFieldGenerator::
GenerateInitializationCode(io::Printer* printer) const {
  printer->Print(variables_, "$name$_ = java.util.Collections.emptyList();\n");
}

void RepeatedMessageFieldGenerator::
GenerateBuilderClearCode(io::Printer* printer) const {
  PrintNestedBuilderCondition(printer,
    "$name$_ = java.util.Collections.emptyList();\n"
    "$clear_mutable_bit_builder$;\n",

    "$name$Builder_.clear();\n");
}

void RepeatedMessageFieldGenerator::
GenerateMergingCode(io::Printer* printer) const {
  // The code below does two optimizations (non-nested builder case):
  //   1. If the other list is empty, there's nothing to do. This ensures we
  //      don't allocate a new array if we already have an immutable one.
  //   2. If the other list is non-empty and our current list is empty, we can
  //      reuse the other list which is guaranteed to be immutable.
  PrintNestedBuilderCondition(printer,
    "if (!other.$name$_.isEmpty()) {\n"
    "  if ($name$_.isEmpty()) {\n"
    "    $name$_ = other.$name$_;\n"
    "    $clear_mutable_bit_builder$;\n"
    "  } else {\n"
    "    ensure$capitalized_name$IsMutable();\n"
    "    $name$_.addAll(other.$name$_);\n"
    "  }\n"
    "  $on_changed$\n"
    "}\n",

    "if (!other.$name$_.isEmpty()) {\n"
    "  if ($name$Builder_.isEmpty()) {\n"
    "    $name$Builder_.dispose();\n"
    "    $name$Builder_ = null;\n"
    "    $name$_ = other.$name$_;\n"
    "    $clear_mutable_bit_builder$;\n"
    "    $name$Builder_ = \n"
    "      com.google.protobuf.GeneratedMessage.alwaysUseFieldBuilders ?\n"
    "         get$capitalized_name$FieldBuilder() : null;\n"
    "  } else {\n"
    "    $name$Builder_.addAllMessages(other.$name$_);\n"
    "  }\n"
    "}\n");
}

void RepeatedMessageFieldGenerator::
GenerateBuildingCode(io::Printer* printer) const {
  // The code below (non-nested builder case) ensures that the result has an
  // immutable list. If our list is immutable, we can just reuse it. If not,
  // we make it immutable.
  PrintNestedBuilderCondition(printer,
    "if ($get_mutable_bit_builder$) {\n"
    "  $name$_ = java.util.Collections.unmodifiableList($name$_);\n"
    "  $clear_mutable_bit_builder$;\n"
    "}\n"
    "result.$name$_ = $name$_;\n",

    "result.$name$_ = $name$Builder_.build();\n");
}

void RepeatedMessageFieldGenerator::
GenerateParsingCode(io::Printer* printer) const {
  printer->Print(variables_,
    "if (!$get_mutable_bit_parser$) {\n"
    "  $name$_ = new java.util.ArrayList<$type$>();\n"
    "  $set_mutable_bit_parser$;\n"
    "}\n");

  if (GetType(descriptor_) == FieldDescriptor::TYPE_GROUP) {
    printer->Print(variables_,
      "$name$_.add(input.readGroup($number$, $type$.PARSER,\n"
      "    extensionRegistry));\n");
  } else {
    printer->Print(variables_,
      "$name$_.add(input.readMessage($type$.PARSER, extensionRegistry));\n");
  }
}

void RepeatedMessageFieldGenerator::
GenerateParsingDoneCode(io::Printer* printer) const {
  printer->Print(variables_,
    "if ($get_mutable_bit_parser$) {\n"
    "  $name$_ = java.util.Collections.unmodifiableList($name$_);\n"
    "}\n");
}

void RepeatedMessageFieldGenerator::
GenerateSerializationCode(io::Printer* printer) const {
  printer->Print(variables_,
    "for (int i = 0; i < $name$_.size(); i++) {\n"
    "  output.write$group_or_message$($number$, $name$_.get(i));\n"
    "}\n");
}

void RepeatedMessageFieldGenerator::
GenerateSerializedSizeCode(io::Printer* printer) const {
  printer->Print(variables_,
    "for (int i = 0; i < $name$_.size(); i++) {\n"
    "  size += com.google.protobuf.CodedOutputStream\n"
    "    .compute$group_or_message$Size($number$, $name$_.get(i));\n"
    "}\n");
}

void RepeatedMessageFieldGenerator::
GenerateEqualsCode(io::Printer* printer) const {
  printer->Print(variables_,
    "result = result && get$capitalized_name$List()\n"
    "    .equals(other.get$capitalized_name$List());\n");
}

void RepeatedMessageFieldGenerator::
GenerateHashCode(io::Printer* printer) const {
  printer->Print(variables_,
    "if (get$capitalized_name$Count() > 0) {\n"
    "  hash = (37 * hash) + $constant_name$;\n"
    "  hash = (53 * hash) + get$capitalized_name$List().hashCode();\n"
    "}\n");
}

string RepeatedMessageFieldGenerator::GetBoxedType() const {
  return ClassName(descriptor_->message_type());
}

}  // namespace java
}  // namespace compiler
}  // namespace protobuf
}  // namespace google
