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
// This file makes extensive use of RFC 3092.  :)

#include <vector>

#include <google/protobuf/compiler/importer.h>
#include <google/protobuf/unittest.pb.h>
#include <google/protobuf/unittest_custom_options.pb.h>
#include <google/protobuf/io/zero_copy_stream_impl.h>
#include <google/protobuf/descriptor.pb.h>
#include <google/protobuf/descriptor.h>
#include <google/protobuf/descriptor_database.h>
#include <google/protobuf/dynamic_message.h>
#include <google/protobuf/text_format.h>
#include <google/protobuf/stubs/strutil.h>
#include <google/protobuf/stubs/substitute.h>

#include <google/protobuf/stubs/common.h>
#include <google/protobuf/testing/googletest.h>
#include <gtest/gtest.h>

namespace google {
namespace protobuf {

// Can't use an anonymous namespace here due to brokenness of Tru64 compiler.
namespace descriptor_unittest {

// Some helpers to make assembling descriptors faster.
DescriptorProto* AddMessage(FileDescriptorProto* file, const string& name) {
  DescriptorProto* result = file->add_message_type();
  result->set_name(name);
  return result;
}

DescriptorProto* AddNestedMessage(DescriptorProto* parent, const string& name) {
  DescriptorProto* result = parent->add_nested_type();
  result->set_name(name);
  return result;
}

EnumDescriptorProto* AddEnum(FileDescriptorProto* file, const string& name) {
  EnumDescriptorProto* result = file->add_enum_type();
  result->set_name(name);
  return result;
}

EnumDescriptorProto* AddNestedEnum(DescriptorProto* parent,
                                   const string& name) {
  EnumDescriptorProto* result = parent->add_enum_type();
  result->set_name(name);
  return result;
}

ServiceDescriptorProto* AddService(FileDescriptorProto* file,
                                   const string& name) {
  ServiceDescriptorProto* result = file->add_service();
  result->set_name(name);
  return result;
}

FieldDescriptorProto* AddField(DescriptorProto* parent,
                               const string& name, int number,
                               FieldDescriptorProto::Label label,
                               FieldDescriptorProto::Type type) {
  FieldDescriptorProto* result = parent->add_field();
  result->set_name(name);
  result->set_number(number);
  result->set_label(label);
  result->set_type(type);
  return result;
}

FieldDescriptorProto* AddExtension(FileDescriptorProto* file,
                                   const string& extendee,
                                   const string& name, int number,
                                   FieldDescriptorProto::Label label,
                                   FieldDescriptorProto::Type type) {
  FieldDescriptorProto* result = file->add_extension();
  result->set_name(name);
  result->set_number(number);
  result->set_label(label);
  result->set_type(type);
  result->set_extendee(extendee);
  return result;
}

FieldDescriptorProto* AddNestedExtension(DescriptorProto* parent,
                                         const string& extendee,
                                         const string& name, int number,
                                         FieldDescriptorProto::Label label,
                                         FieldDescriptorProto::Type type) {
  FieldDescriptorProto* result = parent->add_extension();
  result->set_name(name);
  result->set_number(number);
  result->set_label(label);
  result->set_type(type);
  result->set_extendee(extendee);
  return result;
}

DescriptorProto::ExtensionRange* AddExtensionRange(DescriptorProto* parent,
                                                   int start, int end) {
  DescriptorProto::ExtensionRange* result = parent->add_extension_range();
  result->set_start(start);
  result->set_end(end);
  return result;
}

EnumValueDescriptorProto* AddEnumValue(EnumDescriptorProto* enum_proto,
                                       const string& name, int number) {
  EnumValueDescriptorProto* result = enum_proto->add_value();
  result->set_name(name);
  result->set_number(number);
  return result;
}

MethodDescriptorProto* AddMethod(ServiceDescriptorProto* service,
                                 const string& name,
                                 const string& input_type,
                                 const string& output_type) {
  MethodDescriptorProto* result = service->add_method();
  result->set_name(name);
  result->set_input_type(input_type);
  result->set_output_type(output_type);
  return result;
}

// Empty enums technically aren't allowed.  We need to insert a dummy value
// into them.
void AddEmptyEnum(FileDescriptorProto* file, const string& name) {
  AddEnumValue(AddEnum(file, name), name + "_DUMMY", 1);
}

// ===================================================================

// Test simple files.
class FileDescriptorTest : public testing::Test {
 protected:
  virtual void SetUp() {
    // Build descriptors for the following definitions:
    //
    //   // in "foo.proto"
    //   message FooMessage { extensions 1; }
    //   enum FooEnum {FOO_ENUM_VALUE = 1;}
    //   service FooService {}
    //   extend FooMessage { optional int32 foo_extension = 1; }
    //
    //   // in "bar.proto"
    //   package bar_package;
    //   message BarMessage { extensions 1; }
    //   enum BarEnum {BAR_ENUM_VALUE = 1;}
    //   service BarService {}
    //   extend BarMessage { optional int32 bar_extension = 1; }
    //
    // Also, we have an empty file "baz.proto".  This file's purpose is to
    // make sure that even though it has the same package as foo.proto,
    // searching it for members of foo.proto won't work.

    FileDescriptorProto foo_file;
    foo_file.set_name("foo.proto");
    AddExtensionRange(AddMessage(&foo_file, "FooMessage"), 1, 2);
    AddEnumValue(AddEnum(&foo_file, "FooEnum"), "FOO_ENUM_VALUE", 1);
    AddService(&foo_file, "FooService");
    AddExtension(&foo_file, "FooMessage", "foo_extension", 1,
                 FieldDescriptorProto::LABEL_OPTIONAL,
                 FieldDescriptorProto::TYPE_INT32);

    FileDescriptorProto bar_file;
    bar_file.set_name("bar.proto");
    bar_file.set_package("bar_package");
    bar_file.add_dependency("foo.proto");
    AddExtensionRange(AddMessage(&bar_file, "BarMessage"), 1, 2);
    AddEnumValue(AddEnum(&bar_file, "BarEnum"), "BAR_ENUM_VALUE", 1);
    AddService(&bar_file, "BarService");
    AddExtension(&bar_file, "bar_package.BarMessage", "bar_extension", 1,
                 FieldDescriptorProto::LABEL_OPTIONAL,
                 FieldDescriptorProto::TYPE_INT32);

    FileDescriptorProto baz_file;
    baz_file.set_name("baz.proto");

    // Build the descriptors and get the pointers.
    foo_file_ = pool_.BuildFile(foo_file);
    ASSERT_TRUE(foo_file_ != NULL);

    bar_file_ = pool_.BuildFile(bar_file);
    ASSERT_TRUE(bar_file_ != NULL);

    baz_file_ = pool_.BuildFile(baz_file);
    ASSERT_TRUE(baz_file_ != NULL);

    ASSERT_EQ(1, foo_file_->message_type_count());
    foo_message_ = foo_file_->message_type(0);
    ASSERT_EQ(1, foo_file_->enum_type_count());
    foo_enum_ = foo_file_->enum_type(0);
    ASSERT_EQ(1, foo_enum_->value_count());
    foo_enum_value_ = foo_enum_->value(0);
    ASSERT_EQ(1, foo_file_->service_count());
    foo_service_ = foo_file_->service(0);
    ASSERT_EQ(1, foo_file_->extension_count());
    foo_extension_ = foo_file_->extension(0);

    ASSERT_EQ(1, bar_file_->message_type_count());
    bar_message_ = bar_file_->message_type(0);
    ASSERT_EQ(1, bar_file_->enum_type_count());
    bar_enum_ = bar_file_->enum_type(0);
    ASSERT_EQ(1, bar_enum_->value_count());
    bar_enum_value_ = bar_enum_->value(0);
    ASSERT_EQ(1, bar_file_->service_count());
    bar_service_ = bar_file_->service(0);
    ASSERT_EQ(1, bar_file_->extension_count());
    bar_extension_ = bar_file_->extension(0);
  }

  DescriptorPool pool_;

  const FileDescriptor* foo_file_;
  const FileDescriptor* bar_file_;
  const FileDescriptor* baz_file_;

  const Descriptor*          foo_message_;
  const EnumDescriptor*      foo_enum_;
  const EnumValueDescriptor* foo_enum_value_;
  const ServiceDescriptor*   foo_service_;
  const FieldDescriptor*     foo_extension_;

  const Descriptor*          bar_message_;
  const EnumDescriptor*      bar_enum_;
  const EnumValueDescriptor* bar_enum_value_;
  const ServiceDescriptor*   bar_service_;
  const FieldDescriptor*     bar_extension_;
};

TEST_F(FileDescriptorTest, Name) {
  EXPECT_EQ("foo.proto", foo_file_->name());
  EXPECT_EQ("bar.proto", bar_file_->name());
  EXPECT_EQ("baz.proto", baz_file_->name());
}

TEST_F(FileDescriptorTest, Package) {
  EXPECT_EQ("", foo_file_->package());
  EXPECT_EQ("bar_package", bar_file_->package());
}

TEST_F(FileDescriptorTest, Dependencies) {
  EXPECT_EQ(0, foo_file_->dependency_count());
  EXPECT_EQ(1, bar_file_->dependency_count());
  EXPECT_EQ(foo_file_, bar_file_->dependency(0));
}

TEST_F(FileDescriptorTest, FindMessageTypeByName) {
  EXPECT_EQ(foo_message_, foo_file_->FindMessageTypeByName("FooMessage"));
  EXPECT_EQ(bar_message_, bar_file_->FindMessageTypeByName("BarMessage"));

  EXPECT_TRUE(foo_file_->FindMessageTypeByName("BarMessage") == NULL);
  EXPECT_TRUE(bar_file_->FindMessageTypeByName("FooMessage") == NULL);
  EXPECT_TRUE(baz_file_->FindMessageTypeByName("FooMessage") == NULL);

  EXPECT_TRUE(foo_file_->FindMessageTypeByName("NoSuchMessage") == NULL);
  EXPECT_TRUE(foo_file_->FindMessageTypeByName("FooEnum") == NULL);
}

TEST_F(FileDescriptorTest, FindEnumTypeByName) {
  EXPECT_EQ(foo_enum_, foo_file_->FindEnumTypeByName("FooEnum"));
  EXPECT_EQ(bar_enum_, bar_file_->FindEnumTypeByName("BarEnum"));

  EXPECT_TRUE(foo_file_->FindEnumTypeByName("BarEnum") == NULL);
  EXPECT_TRUE(bar_file_->FindEnumTypeByName("FooEnum") == NULL);
  EXPECT_TRUE(baz_file_->FindEnumTypeByName("FooEnum") == NULL);

  EXPECT_TRUE(foo_file_->FindEnumTypeByName("NoSuchEnum") == NULL);
  EXPECT_TRUE(foo_file_->FindEnumTypeByName("FooMessage") == NULL);
}

TEST_F(FileDescriptorTest, FindEnumValueByName) {
  EXPECT_EQ(foo_enum_value_, foo_file_->FindEnumValueByName("FOO_ENUM_VALUE"));
  EXPECT_EQ(bar_enum_value_, bar_file_->FindEnumValueByName("BAR_ENUM_VALUE"));

  EXPECT_TRUE(foo_file_->FindEnumValueByName("BAR_ENUM_VALUE") == NULL);
  EXPECT_TRUE(bar_file_->FindEnumValueByName("FOO_ENUM_VALUE") == NULL);
  EXPECT_TRUE(baz_file_->FindEnumValueByName("FOO_ENUM_VALUE") == NULL);

  EXPECT_TRUE(foo_file_->FindEnumValueByName("NO_SUCH_VALUE") == NULL);
  EXPECT_TRUE(foo_file_->FindEnumValueByName("FooMessage") == NULL);
}

TEST_F(FileDescriptorTest, FindServiceByName) {
  EXPECT_EQ(foo_service_, foo_file_->FindServiceByName("FooService"));
  EXPECT_EQ(bar_service_, bar_file_->FindServiceByName("BarService"));

  EXPECT_TRUE(foo_file_->FindServiceByName("BarService") == NULL);
  EXPECT_TRUE(bar_file_->FindServiceByName("FooService") == NULL);
  EXPECT_TRUE(baz_file_->FindServiceByName("FooService") == NULL);

  EXPECT_TRUE(foo_file_->FindServiceByName("NoSuchService") == NULL);
  EXPECT_TRUE(foo_file_->FindServiceByName("FooMessage") == NULL);
}

TEST_F(FileDescriptorTest, FindExtensionByName) {
  EXPECT_EQ(foo_extension_, foo_file_->FindExtensionByName("foo_extension"));
  EXPECT_EQ(bar_extension_, bar_file_->FindExtensionByName("bar_extension"));

  EXPECT_TRUE(foo_file_->FindExtensionByName("bar_extension") == NULL);
  EXPECT_TRUE(bar_file_->FindExtensionByName("foo_extension") == NULL);
  EXPECT_TRUE(baz_file_->FindExtensionByName("foo_extension") == NULL);

  EXPECT_TRUE(foo_file_->FindExtensionByName("no_such_extension") == NULL);
  EXPECT_TRUE(foo_file_->FindExtensionByName("FooMessage") == NULL);
}

TEST_F(FileDescriptorTest, FindExtensionByNumber) {
  EXPECT_EQ(foo_extension_, pool_.FindExtensionByNumber(foo_message_, 1));
  EXPECT_EQ(bar_extension_, pool_.FindExtensionByNumber(bar_message_, 1));

  EXPECT_TRUE(pool_.FindExtensionByNumber(foo_message_, 2) == NULL);
}

TEST_F(FileDescriptorTest, BuildAgain) {
  // Test that if te call BuildFile again on the same input we get the same
  // FileDescriptor back.
  FileDescriptorProto file;
  foo_file_->CopyTo(&file);
  EXPECT_EQ(foo_file_, pool_.BuildFile(file));

  // But if we change the file then it won't work.
  file.set_package("some.other.package");
  EXPECT_TRUE(pool_.BuildFile(file) == NULL);
}

// ===================================================================

// Test simple flat messages and fields.
class DescriptorTest : public testing::Test {
 protected:
  virtual void SetUp() {
    // Build descriptors for the following definitions:
    //
    //   // in "foo.proto"
    //   message TestForeign {}
    //   enum TestEnum {}
    //
    //   message TestMessage {
    //     required string      foo = 1;
    //     optional TestEnum    bar = 6;
    //     repeated TestForeign baz = 500000000;
    //     optional group       qux = 15 {}
    //   }
    //
    //   // in "bar.proto"
    //   package corge.grault;
    //   message TestMessage2 {
    //     required string foo = 1;
    //     required string bar = 2;
    //     required string quux = 6;
    //   }
    //
    // We cheat and use TestForeign as the type for qux rather than create
    // an actual nested type.
    //
    // Since all primitive types (including string) use the same building
    // code, there's no need to test each one individually.
    //
    // TestMessage2 is primarily here to test FindFieldByName and friends.
    // All messages created from the same DescriptorPool share the same lookup
    // table, so we need to insure that they don't interfere.

    FileDescriptorProto foo_file;
    foo_file.set_name("foo.proto");
    AddMessage(&foo_file, "TestForeign");
    AddEmptyEnum(&foo_file, "TestEnum");

    DescriptorProto* message = AddMessage(&foo_file, "TestMessage");
    AddField(message, "foo", 1,
             FieldDescriptorProto::LABEL_REQUIRED,
             FieldDescriptorProto::TYPE_STRING);
    AddField(message, "bar", 6,
             FieldDescriptorProto::LABEL_OPTIONAL,
             FieldDescriptorProto::TYPE_ENUM)
      ->set_type_name("TestEnum");
    AddField(message, "baz", 500000000,
             FieldDescriptorProto::LABEL_REPEATED,
             FieldDescriptorProto::TYPE_MESSAGE)
      ->set_type_name("TestForeign");
    AddField(message, "qux", 15,
             FieldDescriptorProto::LABEL_OPTIONAL,
             FieldDescriptorProto::TYPE_GROUP)
      ->set_type_name("TestForeign");

    FileDescriptorProto bar_file;
    bar_file.set_name("bar.proto");
    bar_file.set_package("corge.grault");

    DescriptorProto* message2 = AddMessage(&bar_file, "TestMessage2");
    AddField(message2, "foo", 1,
             FieldDescriptorProto::LABEL_REQUIRED,
             FieldDescriptorProto::TYPE_STRING);
    AddField(message2, "bar", 2,
             FieldDescriptorProto::LABEL_REQUIRED,
             FieldDescriptorProto::TYPE_STRING);
    AddField(message2, "quux", 6,
             FieldDescriptorProto::LABEL_REQUIRED,
             FieldDescriptorProto::TYPE_STRING);

    // Build the descriptors and get the pointers.
    foo_file_ = pool_.BuildFile(foo_file);
    ASSERT_TRUE(foo_file_ != NULL);

    bar_file_ = pool_.BuildFile(bar_file);
    ASSERT_TRUE(bar_file_ != NULL);

    ASSERT_EQ(1, foo_file_->enum_type_count());
    enum_ = foo_file_->enum_type(0);

    ASSERT_EQ(2, foo_file_->message_type_count());
    foreign_ = foo_file_->message_type(0);
    message_ = foo_file_->message_type(1);

    ASSERT_EQ(4, message_->field_count());
    foo_ = message_->field(0);
    bar_ = message_->field(1);
    baz_ = message_->field(2);
    qux_ = message_->field(3);

    ASSERT_EQ(1, bar_file_->message_type_count());
    message2_ = bar_file_->message_type(0);

    ASSERT_EQ(3, message2_->field_count());
    foo2_  = message2_->field(0);
    bar2_  = message2_->field(1);
    quux2_ = message2_->field(2);
  }

  DescriptorPool pool_;

  const FileDescriptor* foo_file_;
  const FileDescriptor* bar_file_;

  const Descriptor* message_;
  const Descriptor* message2_;
  const Descriptor* foreign_;
  const EnumDescriptor* enum_;

  const FieldDescriptor* foo_;
  const FieldDescriptor* bar_;
  const FieldDescriptor* baz_;
  const FieldDescriptor* qux_;

  const FieldDescriptor* foo2_;
  const FieldDescriptor* bar2_;
  const FieldDescriptor* quux2_;
};

TEST_F(DescriptorTest, Name) {
  EXPECT_EQ("TestMessage", message_->name());
  EXPECT_EQ("TestMessage", message_->full_name());
  EXPECT_EQ(foo_file_, message_->file());

  EXPECT_EQ("TestMessage2", message2_->name());
  EXPECT_EQ("corge.grault.TestMessage2", message2_->full_name());
  EXPECT_EQ(bar_file_, message2_->file());
}

TEST_F(DescriptorTest, ContainingType) {
  EXPECT_TRUE(message_->containing_type() == NULL);
  EXPECT_TRUE(message2_->containing_type() == NULL);
}

TEST_F(DescriptorTest, FieldsByIndex) {
  ASSERT_EQ(4, message_->field_count());
  EXPECT_EQ(foo_, message_->field(0));
  EXPECT_EQ(bar_, message_->field(1));
  EXPECT_EQ(baz_, message_->field(2));
  EXPECT_EQ(qux_, message_->field(3));
}

TEST_F(DescriptorTest, FindFieldByName) {
  // All messages in the same DescriptorPool share a single lookup table for
  // fields.  So, in addition to testing that FindFieldByName finds the fields
  // of the message, we need to test that it does *not* find the fields of
  // *other* messages.

  EXPECT_EQ(foo_, message_->FindFieldByName("foo"));
  EXPECT_EQ(bar_, message_->FindFieldByName("bar"));
  EXPECT_EQ(baz_, message_->FindFieldByName("baz"));
  EXPECT_EQ(qux_, message_->FindFieldByName("qux"));
  EXPECT_TRUE(message_->FindFieldByName("no_such_field") == NULL);
  EXPECT_TRUE(message_->FindFieldByName("quux") == NULL);

  EXPECT_EQ(foo2_ , message2_->FindFieldByName("foo" ));
  EXPECT_EQ(bar2_ , message2_->FindFieldByName("bar" ));
  EXPECT_EQ(quux2_, message2_->FindFieldByName("quux"));
  EXPECT_TRUE(message2_->FindFieldByName("baz") == NULL);
  EXPECT_TRUE(message2_->FindFieldByName("qux") == NULL);
}

TEST_F(DescriptorTest, FindFieldByNumber) {
  EXPECT_EQ(foo_, message_->FindFieldByNumber(1));
  EXPECT_EQ(bar_, message_->FindFieldByNumber(6));
  EXPECT_EQ(baz_, message_->FindFieldByNumber(500000000));
  EXPECT_EQ(qux_, message_->FindFieldByNumber(15));
  EXPECT_TRUE(message_->FindFieldByNumber(837592) == NULL);
  EXPECT_TRUE(message_->FindFieldByNumber(2) == NULL);

  EXPECT_EQ(foo2_ , message2_->FindFieldByNumber(1));
  EXPECT_EQ(bar2_ , message2_->FindFieldByNumber(2));
  EXPECT_EQ(quux2_, message2_->FindFieldByNumber(6));
  EXPECT_TRUE(message2_->FindFieldByNumber(15) == NULL);
  EXPECT_TRUE(message2_->FindFieldByNumber(500000000) == NULL);
}

TEST_F(DescriptorTest, FieldName) {
  EXPECT_EQ("foo", foo_->name());
  EXPECT_EQ("bar", bar_->name());
  EXPECT_EQ("baz", baz_->name());
  EXPECT_EQ("qux", qux_->name());
}

TEST_F(DescriptorTest, FieldFullName) {
  EXPECT_EQ("TestMessage.foo", foo_->full_name());
  EXPECT_EQ("TestMessage.bar", bar_->full_name());
  EXPECT_EQ("TestMessage.baz", baz_->full_name());
  EXPECT_EQ("TestMessage.qux", qux_->full_name());

  EXPECT_EQ("corge.grault.TestMessage2.foo", foo2_->full_name());
  EXPECT_EQ("corge.grault.TestMessage2.bar", bar2_->full_name());
  EXPECT_EQ("corge.grault.TestMessage2.quux", quux2_->full_name());
}

TEST_F(DescriptorTest, FieldFile) {
  EXPECT_EQ(foo_file_, foo_->file());
  EXPECT_EQ(foo_file_, bar_->file());
  EXPECT_EQ(foo_file_, baz_->file());
  EXPECT_EQ(foo_file_, qux_->file());

  EXPECT_EQ(bar_file_, foo2_->file());
  EXPECT_EQ(bar_file_, bar2_->file());
  EXPECT_EQ(bar_file_, quux2_->file());
}

TEST_F(DescriptorTest, FieldIndex) {
  EXPECT_EQ(0, foo_->index());
  EXPECT_EQ(1, bar_->index());
  EXPECT_EQ(2, baz_->index());
  EXPECT_EQ(3, qux_->index());
}

TEST_F(DescriptorTest, FieldNumber) {
  EXPECT_EQ(        1, foo_->number());
  EXPECT_EQ(        6, bar_->number());
  EXPECT_EQ(500000000, baz_->number());
  EXPECT_EQ(       15, qux_->number());
}

TEST_F(DescriptorTest, FieldType) {
  EXPECT_EQ(FieldDescriptor::TYPE_STRING , foo_->type());
  EXPECT_EQ(FieldDescriptor::TYPE_ENUM   , bar_->type());
  EXPECT_EQ(FieldDescriptor::TYPE_MESSAGE, baz_->type());
  EXPECT_EQ(FieldDescriptor::TYPE_GROUP  , qux_->type());
}

TEST_F(DescriptorTest, FieldLabel) {
  EXPECT_EQ(FieldDescriptor::LABEL_REQUIRED, foo_->label());
  EXPECT_EQ(FieldDescriptor::LABEL_OPTIONAL, bar_->label());
  EXPECT_EQ(FieldDescriptor::LABEL_REPEATED, baz_->label());
  EXPECT_EQ(FieldDescriptor::LABEL_OPTIONAL, qux_->label());

  EXPECT_TRUE (foo_->is_required());
  EXPECT_FALSE(foo_->is_optional());
  EXPECT_FALSE(foo_->is_repeated());

  EXPECT_FALSE(bar_->is_required());
  EXPECT_TRUE (bar_->is_optional());
  EXPECT_FALSE(bar_->is_repeated());

  EXPECT_FALSE(baz_->is_required());
  EXPECT_FALSE(baz_->is_optional());
  EXPECT_TRUE (baz_->is_repeated());
}

TEST_F(DescriptorTest, FieldHasDefault) {
  EXPECT_FALSE(foo_->has_default_value());
  EXPECT_FALSE(bar_->has_default_value());
  EXPECT_FALSE(baz_->has_default_value());
  EXPECT_FALSE(qux_->has_default_value());
}

TEST_F(DescriptorTest, FieldContainingType) {
  EXPECT_EQ(message_, foo_->containing_type());
  EXPECT_EQ(message_, bar_->containing_type());
  EXPECT_EQ(message_, baz_->containing_type());
  EXPECT_EQ(message_, qux_->containing_type());

  EXPECT_EQ(message2_, foo2_ ->containing_type());
  EXPECT_EQ(message2_, bar2_ ->containing_type());
  EXPECT_EQ(message2_, quux2_->containing_type());
}

TEST_F(DescriptorTest, FieldMessageType) {
  EXPECT_TRUE(foo_->message_type() == NULL);
  EXPECT_TRUE(bar_->message_type() == NULL);

  EXPECT_EQ(foreign_, baz_->message_type());
  EXPECT_EQ(foreign_, qux_->message_type());
}

TEST_F(DescriptorTest, FieldEnumType) {
  EXPECT_TRUE(foo_->enum_type() == NULL);
  EXPECT_TRUE(baz_->enum_type() == NULL);
  EXPECT_TRUE(qux_->enum_type() == NULL);

  EXPECT_EQ(enum_, bar_->enum_type());
}

// ===================================================================

class StylizedFieldNamesTest : public testing::Test {
 protected:
  void SetUp() {
    FileDescriptorProto file;
    file.set_name("foo.proto");

    AddExtensionRange(AddMessage(&file, "ExtendableMessage"), 1, 1000);

    DescriptorProto* message = AddMessage(&file, "TestMessage");
    AddField(message, "foo_foo", 1,
             FieldDescriptorProto::LABEL_OPTIONAL,
             FieldDescriptorProto::TYPE_INT32);
    AddField(message, "FooBar", 2,
             FieldDescriptorProto::LABEL_OPTIONAL,
             FieldDescriptorProto::TYPE_INT32);
    AddField(message, "fooBaz", 3,
             FieldDescriptorProto::LABEL_OPTIONAL,
             FieldDescriptorProto::TYPE_INT32);
    AddField(message, "fooFoo", 4,  // Camel-case conflict with foo_foo.
             FieldDescriptorProto::LABEL_OPTIONAL,
             FieldDescriptorProto::TYPE_INT32);
    AddField(message, "foobar", 5,  // Lower-case conflict with FooBar.
             FieldDescriptorProto::LABEL_OPTIONAL,
             FieldDescriptorProto::TYPE_INT32);

    AddNestedExtension(message, "ExtendableMessage", "bar_foo", 1,
                       FieldDescriptorProto::LABEL_OPTIONAL,
                       FieldDescriptorProto::TYPE_INT32);
    AddNestedExtension(message, "ExtendableMessage", "BarBar", 2,
                       FieldDescriptorProto::LABEL_OPTIONAL,
                       FieldDescriptorProto::TYPE_INT32);
    AddNestedExtension(message, "ExtendableMessage", "BarBaz", 3,
                       FieldDescriptorProto::LABEL_OPTIONAL,
                       FieldDescriptorProto::TYPE_INT32);
    AddNestedExtension(message, "ExtendableMessage", "barFoo", 4,  // Conflict
                       FieldDescriptorProto::LABEL_OPTIONAL,
                       FieldDescriptorProto::TYPE_INT32);
    AddNestedExtension(message, "ExtendableMessage", "barbar", 5,  // Conflict
                       FieldDescriptorProto::LABEL_OPTIONAL,
                       FieldDescriptorProto::TYPE_INT32);

    AddExtension(&file, "ExtendableMessage", "baz_foo", 11,
                 FieldDescriptorProto::LABEL_OPTIONAL,
                 FieldDescriptorProto::TYPE_INT32);
    AddExtension(&file, "ExtendableMessage", "BazBar", 12,
                 FieldDescriptorProto::LABEL_OPTIONAL,
                 FieldDescriptorProto::TYPE_INT32);
    AddExtension(&file, "ExtendableMessage", "BazBaz", 13,
                 FieldDescriptorProto::LABEL_OPTIONAL,
                 FieldDescriptorProto::TYPE_INT32);
    AddExtension(&file, "ExtendableMessage", "bazFoo", 14,  // Conflict
                 FieldDescriptorProto::LABEL_OPTIONAL,
                 FieldDescriptorProto::TYPE_INT32);
    AddExtension(&file, "ExtendableMessage", "bazbar", 15,  // Conflict
                 FieldDescriptorProto::LABEL_OPTIONAL,
                 FieldDescriptorProto::TYPE_INT32);

    file_ = pool_.BuildFile(file);
    ASSERT_TRUE(file_ != NULL);
    ASSERT_EQ(2, file_->message_type_count());
    message_ = file_->message_type(1);
    ASSERT_EQ("TestMessage", message_->name());
    ASSERT_EQ(5, message_->field_count());
    ASSERT_EQ(5, message_->extension_count());
    ASSERT_EQ(5, file_->extension_count());
  }

  DescriptorPool pool_;
  const FileDescriptor* file_;
  const Descriptor* message_;
};

TEST_F(StylizedFieldNamesTest, LowercaseName) {
  EXPECT_EQ("foo_foo", message_->field(0)->lowercase_name());
  EXPECT_EQ("foobar" , message_->field(1)->lowercase_name());
  EXPECT_EQ("foobaz" , message_->field(2)->lowercase_name());
  EXPECT_EQ("foofoo" , message_->field(3)->lowercase_name());
  EXPECT_EQ("foobar" , message_->field(4)->lowercase_name());

  EXPECT_EQ("bar_foo", message_->extension(0)->lowercase_name());
  EXPECT_EQ("barbar" , message_->extension(1)->lowercase_name());
  EXPECT_EQ("barbaz" , message_->extension(2)->lowercase_name());
  EXPECT_EQ("barfoo" , message_->extension(3)->lowercase_name());
  EXPECT_EQ("barbar" , message_->extension(4)->lowercase_name());

  EXPECT_EQ("baz_foo", file_->extension(0)->lowercase_name());
  EXPECT_EQ("bazbar" , file_->extension(1)->lowercase_name());
  EXPECT_EQ("bazbaz" , file_->extension(2)->lowercase_name());
  EXPECT_EQ("bazfoo" , file_->extension(3)->lowercase_name());
  EXPECT_EQ("bazbar" , file_->extension(4)->lowercase_name());
}

TEST_F(StylizedFieldNamesTest, CamelcaseName) {
  EXPECT_EQ("fooFoo", message_->field(0)->camelcase_name());
  EXPECT_EQ("fooBar", message_->field(1)->camelcase_name());
  EXPECT_EQ("fooBaz", message_->field(2)->camelcase_name());
  EXPECT_EQ("fooFoo", message_->field(3)->camelcase_name());
  EXPECT_EQ("foobar", message_->field(4)->camelcase_name());

  EXPECT_EQ("barFoo", message_->extension(0)->camelcase_name());
  EXPECT_EQ("barBar", message_->extension(1)->camelcase_name());
  EXPECT_EQ("barBaz", message_->extension(2)->camelcase_name());
  EXPECT_EQ("barFoo", message_->extension(3)->camelcase_name());
  EXPECT_EQ("barbar", message_->extension(4)->camelcase_name());

  EXPECT_EQ("bazFoo", file_->extension(0)->camelcase_name());
  EXPECT_EQ("bazBar", file_->extension(1)->camelcase_name());
  EXPECT_EQ("bazBaz", file_->extension(2)->camelcase_name());
  EXPECT_EQ("bazFoo", file_->extension(3)->camelcase_name());
  EXPECT_EQ("bazbar", file_->extension(4)->camelcase_name());
}

TEST_F(StylizedFieldNamesTest, FindByLowercaseName) {
  EXPECT_EQ(message_->field(0),
            message_->FindFieldByLowercaseName("foo_foo"));
  EXPECT_EQ(message_->field(1),
            message_->FindFieldByLowercaseName("foobar"));
  EXPECT_EQ(message_->field(2),
            message_->FindFieldByLowercaseName("foobaz"));
  EXPECT_TRUE(message_->FindFieldByLowercaseName("FooBar") == NULL);
  EXPECT_TRUE(message_->FindFieldByLowercaseName("fooBaz") == NULL);
  EXPECT_TRUE(message_->FindFieldByLowercaseName("bar_foo") == NULL);
  EXPECT_TRUE(message_->FindFieldByLowercaseName("nosuchfield") == NULL);

  EXPECT_EQ(message_->extension(0),
            message_->FindExtensionByLowercaseName("bar_foo"));
  EXPECT_EQ(message_->extension(1),
            message_->FindExtensionByLowercaseName("barbar"));
  EXPECT_EQ(message_->extension(2),
            message_->FindExtensionByLowercaseName("barbaz"));
  EXPECT_TRUE(message_->FindExtensionByLowercaseName("BarBar") == NULL);
  EXPECT_TRUE(message_->FindExtensionByLowercaseName("barBaz") == NULL);
  EXPECT_TRUE(message_->FindExtensionByLowercaseName("foo_foo") == NULL);
  EXPECT_TRUE(message_->FindExtensionByLowercaseName("nosuchfield") == NULL);

  EXPECT_EQ(file_->extension(0),
            file_->FindExtensionByLowercaseName("baz_foo"));
  EXPECT_EQ(file_->extension(1),
            file_->FindExtensionByLowercaseName("bazbar"));
  EXPECT_EQ(file_->extension(2),
            file_->FindExtensionByLowercaseName("bazbaz"));
  EXPECT_TRUE(file_->FindExtensionByLowercaseName("BazBar") == NULL);
  EXPECT_TRUE(file_->FindExtensionByLowercaseName("bazBaz") == NULL);
  EXPECT_TRUE(file_->FindExtensionByLowercaseName("nosuchfield") == NULL);
}

TEST_F(StylizedFieldNamesTest, FindByCamelcaseName) {
  EXPECT_EQ(message_->field(0),
            message_->FindFieldByCamelcaseName("fooFoo"));
  EXPECT_EQ(message_->field(1),
            message_->FindFieldByCamelcaseName("fooBar"));
  EXPECT_EQ(message_->field(2),
            message_->FindFieldByCamelcaseName("fooBaz"));
  EXPECT_TRUE(message_->FindFieldByCamelcaseName("foo_foo") == NULL);
  EXPECT_TRUE(message_->FindFieldByCamelcaseName("FooBar") == NULL);
  EXPECT_TRUE(message_->FindFieldByCamelcaseName("barFoo") == NULL);
  EXPECT_TRUE(message_->FindFieldByCamelcaseName("nosuchfield") == NULL);

  EXPECT_EQ(message_->extension(0),
            message_->FindExtensionByCamelcaseName("barFoo"));
  EXPECT_EQ(message_->extension(1),
            message_->FindExtensionByCamelcaseName("barBar"));
  EXPECT_EQ(message_->extension(2),
            message_->FindExtensionByCamelcaseName("barBaz"));
  EXPECT_TRUE(message_->FindExtensionByCamelcaseName("bar_foo") == NULL);
  EXPECT_TRUE(message_->FindExtensionByCamelcaseName("BarBar") == NULL);
  EXPECT_TRUE(message_->FindExtensionByCamelcaseName("fooFoo") == NULL);
  EXPECT_TRUE(message_->FindExtensionByCamelcaseName("nosuchfield") == NULL);

  EXPECT_EQ(file_->extension(0),
            file_->FindExtensionByCamelcaseName("bazFoo"));
  EXPECT_EQ(file_->extension(1),
            file_->FindExtensionByCamelcaseName("bazBar"));
  EXPECT_EQ(file_->extension(2),
            file_->FindExtensionByCamelcaseName("bazBaz"));
  EXPECT_TRUE(file_->FindExtensionByCamelcaseName("baz_foo") == NULL);
  EXPECT_TRUE(file_->FindExtensionByCamelcaseName("BazBar") == NULL);
  EXPECT_TRUE(file_->FindExtensionByCamelcaseName("nosuchfield") == NULL);
}

// ===================================================================

// Test enum descriptors.
class EnumDescriptorTest : public testing::Test {
 protected:
  virtual void SetUp() {
    // Build descriptors for the following definitions:
    //
    //   // in "foo.proto"
    //   enum TestEnum {
    //     FOO = 1;
    //     BAR = 2;
    //   }
    //
    //   // in "bar.proto"
    //   package corge.grault;
    //   enum TestEnum2 {
    //     FOO = 1;
    //     BAZ = 3;
    //   }
    //
    // TestEnum2 is primarily here to test FindValueByName and friends.
    // All enums created from the same DescriptorPool share the same lookup
    // table, so we need to insure that they don't interfere.

    // TestEnum
    FileDescriptorProto foo_file;
    foo_file.set_name("foo.proto");

    EnumDescriptorProto* enum_proto = AddEnum(&foo_file, "TestEnum");
    AddEnumValue(enum_proto, "FOO", 1);
    AddEnumValue(enum_proto, "BAR", 2);

    // TestEnum2
    FileDescriptorProto bar_file;
    bar_file.set_name("bar.proto");
    bar_file.set_package("corge.grault");

    EnumDescriptorProto* enum2_proto = AddEnum(&bar_file, "TestEnum2");
    AddEnumValue(enum2_proto, "FOO", 1);
    AddEnumValue(enum2_proto, "BAZ", 3);

    // Build the descriptors and get the pointers.
    foo_file_ = pool_.BuildFile(foo_file);
    ASSERT_TRUE(foo_file_ != NULL);

    bar_file_ = pool_.BuildFile(bar_file);
    ASSERT_TRUE(bar_file_ != NULL);

    ASSERT_EQ(1, foo_file_->enum_type_count());
    enum_ = foo_file_->enum_type(0);

    ASSERT_EQ(2, enum_->value_count());
    foo_ = enum_->value(0);
    bar_ = enum_->value(1);

    ASSERT_EQ(1, bar_file_->enum_type_count());
    enum2_ = bar_file_->enum_type(0);

    ASSERT_EQ(2, enum2_->value_count());
    foo2_ = enum2_->value(0);
    baz2_ = enum2_->value(1);
  }

  DescriptorPool pool_;

  const FileDescriptor* foo_file_;
  const FileDescriptor* bar_file_;

  const EnumDescriptor* enum_;
  const EnumDescriptor* enum2_;

  const EnumValueDescriptor* foo_;
  const EnumValueDescriptor* bar_;

  const EnumValueDescriptor* foo2_;
  const EnumValueDescriptor* baz2_;
};

TEST_F(EnumDescriptorTest, Name) {
  EXPECT_EQ("TestEnum", enum_->name());
  EXPECT_EQ("TestEnum", enum_->full_name());
  EXPECT_EQ(foo_file_, enum_->file());

  EXPECT_EQ("TestEnum2", enum2_->name());
  EXPECT_EQ("corge.grault.TestEnum2", enum2_->full_name());
  EXPECT_EQ(bar_file_, enum2_->file());
}

TEST_F(EnumDescriptorTest, ContainingType) {
  EXPECT_TRUE(enum_->containing_type() == NULL);
  EXPECT_TRUE(enum2_->containing_type() == NULL);
}

TEST_F(EnumDescriptorTest, ValuesByIndex) {
  ASSERT_EQ(2, enum_->value_count());
  EXPECT_EQ(foo_, enum_->value(0));
  EXPECT_EQ(bar_, enum_->value(1));
}

TEST_F(EnumDescriptorTest, FindValueByName) {
  EXPECT_EQ(foo_ , enum_ ->FindValueByName("FOO"));
  EXPECT_EQ(bar_ , enum_ ->FindValueByName("BAR"));
  EXPECT_EQ(foo2_, enum2_->FindValueByName("FOO"));
  EXPECT_EQ(baz2_, enum2_->FindValueByName("BAZ"));

  EXPECT_TRUE(enum_ ->FindValueByName("NO_SUCH_VALUE") == NULL);
  EXPECT_TRUE(enum_ ->FindValueByName("BAZ"          ) == NULL);
  EXPECT_TRUE(enum2_->FindValueByName("BAR"          ) == NULL);
}

TEST_F(EnumDescriptorTest, FindValueByNumber) {
  EXPECT_EQ(foo_ , enum_ ->FindValueByNumber(1));
  EXPECT_EQ(bar_ , enum_ ->FindValueByNumber(2));
  EXPECT_EQ(foo2_, enum2_->FindValueByNumber(1));
  EXPECT_EQ(baz2_, enum2_->FindValueByNumber(3));

  EXPECT_TRUE(enum_ ->FindValueByNumber(416) == NULL);
  EXPECT_TRUE(enum_ ->FindValueByNumber(3) == NULL);
  EXPECT_TRUE(enum2_->FindValueByNumber(2) == NULL);
}

TEST_F(EnumDescriptorTest, ValueName) {
  EXPECT_EQ("FOO", foo_->name());
  EXPECT_EQ("BAR", bar_->name());
}

TEST_F(EnumDescriptorTest, ValueFullName) {
  EXPECT_EQ("FOO", foo_->full_name());
  EXPECT_EQ("BAR", bar_->full_name());
  EXPECT_EQ("corge.grault.FOO", foo2_->full_name());
  EXPECT_EQ("corge.grault.BAZ", baz2_->full_name());
}

TEST_F(EnumDescriptorTest, ValueIndex) {
  EXPECT_EQ(0, foo_->index());
  EXPECT_EQ(1, bar_->index());
}

TEST_F(EnumDescriptorTest, ValueNumber) {
  EXPECT_EQ(1, foo_->number());
  EXPECT_EQ(2, bar_->number());
}

TEST_F(EnumDescriptorTest, ValueType) {
  EXPECT_EQ(enum_ , foo_ ->type());
  EXPECT_EQ(enum_ , bar_ ->type());
  EXPECT_EQ(enum2_, foo2_->type());
  EXPECT_EQ(enum2_, baz2_->type());
}

// ===================================================================

// Test service descriptors.
class ServiceDescriptorTest : public testing::Test {
 protected:
  virtual void SetUp() {
    // Build descriptors for the following messages and service:
    //    // in "foo.proto"
    //    message FooRequest  {}
    //    message FooResponse {}
    //    message BarRequest  {}
    //    message BarResponse {}
    //    message BazRequest  {}
    //    message BazResponse {}
    //
    //    service TestService {
    //      rpc Foo(FooRequest) returns (FooResponse);
    //      rpc Bar(BarRequest) returns (BarResponse);
    //    }
    //
    //    // in "bar.proto"
    //    package corge.grault
    //    service TestService2 {
    //      rpc Foo(FooRequest) returns (FooResponse);
    //      rpc Baz(BazRequest) returns (BazResponse);
    //    }

    FileDescriptorProto foo_file;
    foo_file.set_name("foo.proto");

    AddMessage(&foo_file, "FooRequest");
    AddMessage(&foo_file, "FooResponse");
    AddMessage(&foo_file, "BarRequest");
    AddMessage(&foo_file, "BarResponse");
    AddMessage(&foo_file, "BazRequest");
    AddMessage(&foo_file, "BazResponse");

    ServiceDescriptorProto* service = AddService(&foo_file, "TestService");
    AddMethod(service, "Foo", "FooRequest", "FooResponse");
    AddMethod(service, "Bar", "BarRequest", "BarResponse");

    FileDescriptorProto bar_file;
    bar_file.set_name("bar.proto");
    bar_file.set_package("corge.grault");
    bar_file.add_dependency("foo.proto");

    ServiceDescriptorProto* service2 = AddService(&bar_file, "TestService2");
    AddMethod(service2, "Foo", "FooRequest", "FooResponse");
    AddMethod(service2, "Baz", "BazRequest", "BazResponse");

    // Build the descriptors and get the pointers.
    foo_file_ = pool_.BuildFile(foo_file);
    ASSERT_TRUE(foo_file_ != NULL);

    bar_file_ = pool_.BuildFile(bar_file);
    ASSERT_TRUE(bar_file_ != NULL);

    ASSERT_EQ(6, foo_file_->message_type_count());
    foo_request_  = foo_file_->message_type(0);
    foo_response_ = foo_file_->message_type(1);
    bar_request_  = foo_file_->message_type(2);
    bar_response_ = foo_file_->message_type(3);
    baz_request_  = foo_file_->message_type(4);
    baz_response_ = foo_file_->message_type(5);

    ASSERT_EQ(1, foo_file_->service_count());
    service_ = foo_file_->service(0);

    ASSERT_EQ(2, service_->method_count());
    foo_ = service_->method(0);
    bar_ = service_->method(1);

    ASSERT_EQ(1, bar_file_->service_count());
    service2_ = bar_file_->service(0);

    ASSERT_EQ(2, service2_->method_count());
    foo2_ = service2_->method(0);
    baz2_ = service2_->method(1);
  }

  DescriptorPool pool_;

  const FileDescriptor* foo_file_;
  const FileDescriptor* bar_file_;

  const Descriptor* foo_request_;
  const Descriptor* foo_response_;
  const Descriptor* bar_request_;
  const Descriptor* bar_response_;
  const Descriptor* baz_request_;
  const Descriptor* baz_response_;

  const ServiceDescriptor* service_;
  const ServiceDescriptor* service2_;

  const MethodDescriptor* foo_;
  const MethodDescriptor* bar_;

  const MethodDescriptor* foo2_;
  const MethodDescriptor* baz2_;
};

TEST_F(ServiceDescriptorTest, Name) {
  EXPECT_EQ("TestService", service_->name());
  EXPECT_EQ("TestService", service_->full_name());
  EXPECT_EQ(foo_file_, service_->file());

  EXPECT_EQ("TestService2", service2_->name());
  EXPECT_EQ("corge.grault.TestService2", service2_->full_name());
  EXPECT_EQ(bar_file_, service2_->file());
}

TEST_F(ServiceDescriptorTest, MethodsByIndex) {
  ASSERT_EQ(2, service_->method_count());
  EXPECT_EQ(foo_, service_->method(0));
  EXPECT_EQ(bar_, service_->method(1));
}

TEST_F(ServiceDescriptorTest, FindMethodByName) {
  EXPECT_EQ(foo_ , service_ ->FindMethodByName("Foo"));
  EXPECT_EQ(bar_ , service_ ->FindMethodByName("Bar"));
  EXPECT_EQ(foo2_, service2_->FindMethodByName("Foo"));
  EXPECT_EQ(baz2_, service2_->FindMethodByName("Baz"));

  EXPECT_TRUE(service_ ->FindMethodByName("NoSuchMethod") == NULL);
  EXPECT_TRUE(service_ ->FindMethodByName("Baz"         ) == NULL);
  EXPECT_TRUE(service2_->FindMethodByName("Bar"         ) == NULL);
}

TEST_F(ServiceDescriptorTest, MethodName) {
  EXPECT_EQ("Foo", foo_->name());
  EXPECT_EQ("Bar", bar_->name());
}

TEST_F(ServiceDescriptorTest, MethodFullName) {
  EXPECT_EQ("TestService.Foo", foo_->full_name());
  EXPECT_EQ("TestService.Bar", bar_->full_name());
  EXPECT_EQ("corge.grault.TestService2.Foo", foo2_->full_name());
  EXPECT_EQ("corge.grault.TestService2.Baz", baz2_->full_name());
}

TEST_F(ServiceDescriptorTest, MethodIndex) {
  EXPECT_EQ(0, foo_->index());
  EXPECT_EQ(1, bar_->index());
}

TEST_F(ServiceDescriptorTest, MethodParent) {
  EXPECT_EQ(service_, foo_->service());
  EXPECT_EQ(service_, bar_->service());
}

TEST_F(ServiceDescriptorTest, MethodInputType) {
  EXPECT_EQ(foo_request_, foo_->input_type());
  EXPECT_EQ(bar_request_, bar_->input_type());
}

TEST_F(ServiceDescriptorTest, MethodOutputType) {
  EXPECT_EQ(foo_response_, foo_->output_type());
  EXPECT_EQ(bar_response_, bar_->output_type());
}

// ===================================================================

// Test nested types.
class NestedDescriptorTest : public testing::Test {
 protected:
  virtual void SetUp() {
    // Build descriptors for the following definitions:
    //
    //   // in "foo.proto"
    //   message TestMessage {
    //     message Foo {}
    //     message Bar {}
    //     enum Baz { A = 1; }
    //     enum Qux { B = 1; }
    //   }
    //
    //   // in "bar.proto"
    //   package corge.grault;
    //   message TestMessage2 {
    //     message Foo {}
    //     message Baz {}
    //     enum Qux  { A = 1; }
    //     enum Quux { C = 1; }
    //   }
    //
    // TestMessage2 is primarily here to test FindNestedTypeByName and friends.
    // All messages created from the same DescriptorPool share the same lookup
    // table, so we need to insure that they don't interfere.
    //
    // We add enum values to the enums in order to test searching for enum
    // values across a message's scope.

    FileDescriptorProto foo_file;
    foo_file.set_name("foo.proto");

    DescriptorProto* message = AddMessage(&foo_file, "TestMessage");
    AddNestedMessage(message, "Foo");
    AddNestedMessage(message, "Bar");
    EnumDescriptorProto* baz = AddNestedEnum(message, "Baz");
    AddEnumValue(baz, "A", 1);
    EnumDescriptorProto* qux = AddNestedEnum(message, "Qux");
    AddEnumValue(qux, "B", 1);

    FileDescriptorProto bar_file;
    bar_file.set_name("bar.proto");
    bar_file.set_package("corge.grault");

    DescriptorProto* message2 = AddMessage(&bar_file, "TestMessage2");
    AddNestedMessage(message2, "Foo");
    AddNestedMessage(message2, "Baz");
    EnumDescriptorProto* qux2 = AddNestedEnum(message2, "Qux");
    AddEnumValue(qux2, "A", 1);
    EnumDescriptorProto* quux2 = AddNestedEnum(message2, "Quux");
    AddEnumValue(quux2, "C", 1);

    // Build the descriptors and get the pointers.
    foo_file_ = pool_.BuildFile(foo_file);
    ASSERT_TRUE(foo_file_ != NULL);

    bar_file_ = pool_.BuildFile(bar_file);
    ASSERT_TRUE(bar_file_ != NULL);

    ASSERT_EQ(1, foo_file_->message_type_count());
    message_ = foo_file_->message_type(0);

    ASSERT_EQ(2, message_->nested_type_count());
    foo_ = message_->nested_type(0);
    bar_ = message_->nested_type(1);

    ASSERT_EQ(2, message_->enum_type_count());
    baz_ = message_->enum_type(0);
    qux_ = message_->enum_type(1);

    ASSERT_EQ(1, baz_->value_count());
    a_ = baz_->value(0);
    ASSERT_EQ(1, qux_->value_count());
    b_ = qux_->value(0);

    ASSERT_EQ(1, bar_file_->message_type_count());
    message2_ = bar_file_->message_type(0);

    ASSERT_EQ(2, message2_->nested_type_count());
    foo2_ = message2_->nested_type(0);
    baz2_ = message2_->nested_type(1);

    ASSERT_EQ(2, message2_->enum_type_count());
    qux2_ = message2_->enum_type(0);
    quux2_ = message2_->enum_type(1);

    ASSERT_EQ(1, qux2_->value_count());
    a2_ = qux2_->value(0);
    ASSERT_EQ(1, quux2_->value_count());
    c2_ = quux2_->value(0);
  }

  DescriptorPool pool_;

  const FileDescriptor* foo_file_;
  const FileDescriptor* bar_file_;

  const Descriptor* message_;
  const Descriptor* message2_;

  const Descriptor* foo_;
  const Descriptor* bar_;
  const EnumDescriptor* baz_;
  const EnumDescriptor* qux_;
  const EnumValueDescriptor* a_;
  const EnumValueDescriptor* b_;

  const Descriptor* foo2_;
  const Descriptor* baz2_;
  const EnumDescriptor* qux2_;
  const EnumDescriptor* quux2_;
  const EnumValueDescriptor* a2_;
  const EnumValueDescriptor* c2_;
};

TEST_F(NestedDescriptorTest, MessageName) {
  EXPECT_EQ("Foo", foo_ ->name());
  EXPECT_EQ("Bar", bar_ ->name());
  EXPECT_EQ("Foo", foo2_->name());
  EXPECT_EQ("Baz", baz2_->name());

  EXPECT_EQ("TestMessage.Foo", foo_->full_name());
  EXPECT_EQ("TestMessage.Bar", bar_->full_name());
  EXPECT_EQ("corge.grault.TestMessage2.Foo", foo2_->full_name());
  EXPECT_EQ("corge.grault.TestMessage2.Baz", baz2_->full_name());
}

TEST_F(NestedDescriptorTest, MessageContainingType) {
  EXPECT_EQ(message_ , foo_ ->containing_type());
  EXPECT_EQ(message_ , bar_ ->containing_type());
  EXPECT_EQ(message2_, foo2_->containing_type());
  EXPECT_EQ(message2_, baz2_->containing_type());
}

TEST_F(NestedDescriptorTest, NestedMessagesByIndex) {
  ASSERT_EQ(2, message_->nested_type_count());
  EXPECT_EQ(foo_, message_->nested_type(0));
  EXPECT_EQ(bar_, message_->nested_type(1));
}

TEST_F(NestedDescriptorTest, FindFieldByNameDoesntFindNestedTypes) {
  EXPECT_TRUE(message_->FindFieldByName("Foo") == NULL);
  EXPECT_TRUE(message_->FindFieldByName("Qux") == NULL);
  EXPECT_TRUE(message_->FindExtensionByName("Foo") == NULL);
  EXPECT_TRUE(message_->FindExtensionByName("Qux") == NULL);
}

TEST_F(NestedDescriptorTest, FindNestedTypeByName) {
  EXPECT_EQ(foo_ , message_ ->FindNestedTypeByName("Foo"));
  EXPECT_EQ(bar_ , message_ ->FindNestedTypeByName("Bar"));
  EXPECT_EQ(foo2_, message2_->FindNestedTypeByName("Foo"));
  EXPECT_EQ(baz2_, message2_->FindNestedTypeByName("Baz"));

  EXPECT_TRUE(message_ ->FindNestedTypeByName("NoSuchType") == NULL);
  EXPECT_TRUE(message_ ->FindNestedTypeByName("Baz"       ) == NULL);
  EXPECT_TRUE(message2_->FindNestedTypeByName("Bar"       ) == NULL);

  EXPECT_TRUE(message_->FindNestedTypeByName("Qux") == NULL);
}

TEST_F(NestedDescriptorTest, EnumName) {
  EXPECT_EQ("Baz" , baz_ ->name());
  EXPECT_EQ("Qux" , qux_ ->name());
  EXPECT_EQ("Qux" , qux2_->name());
  EXPECT_EQ("Quux", quux2_->name());

  EXPECT_EQ("TestMessage.Baz", baz_->full_name());
  EXPECT_EQ("TestMessage.Qux", qux_->full_name());
  EXPECT_EQ("corge.grault.TestMessage2.Qux" , qux2_ ->full_name());
  EXPECT_EQ("corge.grault.TestMessage2.Quux", quux2_->full_name());
}

TEST_F(NestedDescriptorTest, EnumContainingType) {
  EXPECT_EQ(message_ , baz_  ->containing_type());
  EXPECT_EQ(message_ , qux_  ->containing_type());
  EXPECT_EQ(message2_, qux2_ ->containing_type());
  EXPECT_EQ(message2_, quux2_->containing_type());
}

TEST_F(NestedDescriptorTest, NestedEnumsByIndex) {
  ASSERT_EQ(2, message_->nested_type_count());
  EXPECT_EQ(foo_, message_->nested_type(0));
  EXPECT_EQ(bar_, message_->nested_type(1));
}

TEST_F(NestedDescriptorTest, FindEnumTypeByName) {
  EXPECT_EQ(baz_  , message_ ->FindEnumTypeByName("Baz" ));
  EXPECT_EQ(qux_  , message_ ->FindEnumTypeByName("Qux" ));
  EXPECT_EQ(qux2_ , message2_->FindEnumTypeByName("Qux" ));
  EXPECT_EQ(quux2_, message2_->FindEnumTypeByName("Quux"));

  EXPECT_TRUE(message_ ->FindEnumTypeByName("NoSuchType") == NULL);
  EXPECT_TRUE(message_ ->FindEnumTypeByName("Quux"      ) == NULL);
  EXPECT_TRUE(message2_->FindEnumTypeByName("Baz"       ) == NULL);

  EXPECT_TRUE(message_->FindEnumTypeByName("Foo") == NULL);
}

TEST_F(NestedDescriptorTest, FindEnumValueByName) {
  EXPECT_EQ(a_ , message_ ->FindEnumValueByName("A"));
  EXPECT_EQ(b_ , message_ ->FindEnumValueByName("B"));
  EXPECT_EQ(a2_, message2_->FindEnumValueByName("A"));
  EXPECT_EQ(c2_, message2_->FindEnumValueByName("C"));

  EXPECT_TRUE(message_ ->FindEnumValueByName("NO_SUCH_VALUE") == NULL);
  EXPECT_TRUE(message_ ->FindEnumValueByName("C"            ) == NULL);
  EXPECT_TRUE(message2_->FindEnumValueByName("B"            ) == NULL);

  EXPECT_TRUE(message_->FindEnumValueByName("Foo") == NULL);
}

// ===================================================================

// Test extensions.
class ExtensionDescriptorTest : public testing::Test {
 protected:
  virtual void SetUp() {
    // Build descriptors for the following definitions:
    //
    //   enum Baz {}
    //   message Qux {}
    //
    //   message Foo {
    //     extensions 10 to 19;
    //     extensions 30 to 39;
    //   }
    //   extends Foo with optional int32 foo_int32 = 10;
    //   extends Foo with repeated TestEnum foo_enum = 19;
    //   message Bar {
    //     extends Foo with optional Qux foo_message = 30;
    //     // (using Qux as the group type)
    //     extends Foo with repeated group foo_group = 39;
    //   }

    FileDescriptorProto foo_file;
    foo_file.set_name("foo.proto");

    AddEmptyEnum(&foo_file, "Baz");
    AddMessage(&foo_file, "Qux");

    DescriptorProto* foo = AddMessage(&foo_file, "Foo");
    AddExtensionRange(foo, 10, 20);
    AddExtensionRange(foo, 30, 40);

    AddExtension(&foo_file, "Foo", "foo_int32", 10,
                 FieldDescriptorProto::LABEL_OPTIONAL,
                 FieldDescriptorProto::TYPE_INT32);
    AddExtension(&foo_file, "Foo", "foo_enum", 19,
                 FieldDescriptorProto::LABEL_REPEATED,
                 FieldDescriptorProto::TYPE_ENUM)
      ->set_type_name("Baz");

    DescriptorProto* bar = AddMessage(&foo_file, "Bar");
    AddNestedExtension(bar, "Foo", "foo_message", 30,
                       FieldDescriptorProto::LABEL_OPTIONAL,
                       FieldDescriptorProto::TYPE_MESSAGE)
      ->set_type_name("Qux");
    AddNestedExtension(bar, "Foo", "foo_group", 39,
                       FieldDescriptorProto::LABEL_REPEATED,
                       FieldDescriptorProto::TYPE_GROUP)
      ->set_type_name("Qux");

    // Build the descriptors and get the pointers.
    foo_file_ = pool_.BuildFile(foo_file);
    ASSERT_TRUE(foo_file_ != NULL);

    ASSERT_EQ(1, foo_file_->enum_type_count());
    baz_ = foo_file_->enum_type(0);

    ASSERT_EQ(3, foo_file_->message_type_count());
    qux_ = foo_file_->message_type(0);
    foo_ = foo_file_->message_type(1);
    bar_ = foo_file_->message_type(2);
  }

  DescriptorPool pool_;

  const FileDescriptor* foo_file_;

  const Descriptor* foo_;
  const Descriptor* bar_;
  const EnumDescriptor* baz_;
  const Descriptor* qux_;
};

TEST_F(ExtensionDescriptorTest, ExtensionRanges) {
  EXPECT_EQ(0, bar_->extension_range_count());
  ASSERT_EQ(2, foo_->extension_range_count());

  EXPECT_EQ(10, foo_->extension_range(0)->start);
  EXPECT_EQ(30, foo_->extension_range(1)->start);

  EXPECT_EQ(20, foo_->extension_range(0)->end);
  EXPECT_EQ(40, foo_->extension_range(1)->end);
};

TEST_F(ExtensionDescriptorTest, Extensions) {
  EXPECT_EQ(0, foo_->extension_count());
  ASSERT_EQ(2, foo_file_->extension_count());
  ASSERT_EQ(2, bar_->extension_count());

  EXPECT_TRUE(foo_file_->extension(0)->is_extension());
  EXPECT_TRUE(foo_file_->extension(1)->is_extension());
  EXPECT_TRUE(bar_->extension(0)->is_extension());
  EXPECT_TRUE(bar_->extension(1)->is_extension());

  EXPECT_EQ("foo_int32"  , foo_file_->extension(0)->name());
  EXPECT_EQ("foo_enum"   , foo_file_->extension(1)->name());
  EXPECT_EQ("foo_message", bar_->extension(0)->name());
  EXPECT_EQ("foo_group"  , bar_->extension(1)->name());

  EXPECT_EQ(10, foo_file_->extension(0)->number());
  EXPECT_EQ(19, foo_file_->extension(1)->number());
  EXPECT_EQ(30, bar_->extension(0)->number());
  EXPECT_EQ(39, bar_->extension(1)->number());

  EXPECT_EQ(FieldDescriptor::TYPE_INT32  , foo_file_->extension(0)->type());
  EXPECT_EQ(FieldDescriptor::TYPE_ENUM   , foo_file_->extension(1)->type());
  EXPECT_EQ(FieldDescriptor::TYPE_MESSAGE, bar_->extension(0)->type());
  EXPECT_EQ(FieldDescriptor::TYPE_GROUP  , bar_->extension(1)->type());

  EXPECT_EQ(baz_, foo_file_->extension(1)->enum_type());
  EXPECT_EQ(qux_, bar_->extension(0)->message_type());
  EXPECT_EQ(qux_, bar_->extension(1)->message_type());

  EXPECT_EQ(FieldDescriptor::LABEL_OPTIONAL, foo_file_->extension(0)->label());
  EXPECT_EQ(FieldDescriptor::LABEL_REPEATED, foo_file_->extension(1)->label());
  EXPECT_EQ(FieldDescriptor::LABEL_OPTIONAL, bar_->extension(0)->label());
  EXPECT_EQ(FieldDescriptor::LABEL_REPEATED, bar_->extension(1)->label());

  EXPECT_EQ(foo_, foo_file_->extension(0)->containing_type());
  EXPECT_EQ(foo_, foo_file_->extension(1)->containing_type());
  EXPECT_EQ(foo_, bar_->extension(0)->containing_type());
  EXPECT_EQ(foo_, bar_->extension(1)->containing_type());

  EXPECT_TRUE(foo_file_->extension(0)->extension_scope() == NULL);
  EXPECT_TRUE(foo_file_->extension(1)->extension_scope() == NULL);
  EXPECT_EQ(bar_, bar_->extension(0)->extension_scope());
  EXPECT_EQ(bar_, bar_->extension(1)->extension_scope());
};

TEST_F(ExtensionDescriptorTest, IsExtensionNumber) {
  EXPECT_FALSE(foo_->IsExtensionNumber( 9));
  EXPECT_TRUE (foo_->IsExtensionNumber(10));
  EXPECT_TRUE (foo_->IsExtensionNumber(19));
  EXPECT_FALSE(foo_->IsExtensionNumber(20));
  EXPECT_FALSE(foo_->IsExtensionNumber(29));
  EXPECT_TRUE (foo_->IsExtensionNumber(30));
  EXPECT_TRUE (foo_->IsExtensionNumber(39));
  EXPECT_FALSE(foo_->IsExtensionNumber(40));
}

TEST_F(ExtensionDescriptorTest, FindExtensionByName) {
  // Note that FileDescriptor::FindExtensionByName() is tested by
  // FileDescriptorTest.
  ASSERT_EQ(2, bar_->extension_count());

  EXPECT_EQ(bar_->extension(0), bar_->FindExtensionByName("foo_message"));
  EXPECT_EQ(bar_->extension(1), bar_->FindExtensionByName("foo_group"  ));

  EXPECT_TRUE(bar_->FindExtensionByName("no_such_extension") == NULL);
  EXPECT_TRUE(foo_->FindExtensionByName("foo_int32") == NULL);
  EXPECT_TRUE(foo_->FindExtensionByName("foo_message") == NULL);
}

TEST_F(ExtensionDescriptorTest, FindAllExtensions) {
  vector<const FieldDescriptor*> extensions;
  pool_.FindAllExtensions(foo_, &extensions);
  ASSERT_EQ(4, extensions.size());
  EXPECT_EQ(10, extensions[0]->number());
  EXPECT_EQ(19, extensions[1]->number());
  EXPECT_EQ(30, extensions[2]->number());
  EXPECT_EQ(39, extensions[3]->number());
}

// ===================================================================

class MiscTest : public testing::Test {
 protected:
  // Function which makes a field descriptor of the given type.
  const FieldDescriptor* GetFieldDescriptorOfType(FieldDescriptor::Type type) {
    FileDescriptorProto file_proto;
    file_proto.set_name("foo.proto");
    AddEmptyEnum(&file_proto, "DummyEnum");

    DescriptorProto* message = AddMessage(&file_proto, "TestMessage");
    FieldDescriptorProto* field =
      AddField(message, "foo", 1, FieldDescriptorProto::LABEL_OPTIONAL,
               static_cast<FieldDescriptorProto::Type>(static_cast<int>(type)));

    if (type == FieldDescriptor::TYPE_MESSAGE ||
        type == FieldDescriptor::TYPE_GROUP) {
      field->set_type_name("TestMessage");
    } else if (type == FieldDescriptor::TYPE_ENUM) {
      field->set_type_name("DummyEnum");
    }

    // Build the descriptors and get the pointers.
    pool_.reset(new DescriptorPool());
    const FileDescriptor* file = pool_->BuildFile(file_proto);

    if (file != NULL &&
        file->message_type_count() == 1 &&
        file->message_type(0)->field_count() == 1) {
      return file->message_type(0)->field(0);
    } else {
      return NULL;
    }
  }

  const char* GetTypeNameForFieldType(FieldDescriptor::Type type) {
    const FieldDescriptor* field = GetFieldDescriptorOfType(type);
    return field != NULL ? field->type_name() : "";
  }

  FieldDescriptor::CppType GetCppTypeForFieldType(FieldDescriptor::Type type) {
    const FieldDescriptor* field = GetFieldDescriptorOfType(type);
    return field != NULL ? field->cpp_type() :
        static_cast<FieldDescriptor::CppType>(0);
  }

  const char* GetCppTypeNameForFieldType(FieldDescriptor::Type type) {
    const FieldDescriptor* field = GetFieldDescriptorOfType(type);
    return field != NULL ? field->cpp_type_name() : "";
  }

  scoped_ptr<DescriptorPool> pool_;
};

TEST_F(MiscTest, TypeNames) {
  // Test that correct type names are returned.

  typedef FieldDescriptor FD;  // avoid ugly line wrapping

  EXPECT_STREQ("double"  , GetTypeNameForFieldType(FD::TYPE_DOUBLE  ));
  EXPECT_STREQ("float"   , GetTypeNameForFieldType(FD::TYPE_FLOAT   ));
  EXPECT_STREQ("int64"   , GetTypeNameForFieldType(FD::TYPE_INT64   ));
  EXPECT_STREQ("uint64"  , GetTypeNameForFieldType(FD::TYPE_UINT64  ));
  EXPECT_STREQ("int32"   , GetTypeNameForFieldType(FD::TYPE_INT32   ));
  EXPECT_STREQ("fixed64" , GetTypeNameForFieldType(FD::TYPE_FIXED64 ));
  EXPECT_STREQ("fixed32" , GetTypeNameForFieldType(FD::TYPE_FIXED32 ));
  EXPECT_STREQ("bool"    , GetTypeNameForFieldType(FD::TYPE_BOOL    ));
  EXPECT_STREQ("string"  , GetTypeNameForFieldType(FD::TYPE_STRING  ));
  EXPECT_STREQ("group"   , GetTypeNameForFieldType(FD::TYPE_GROUP   ));
  EXPECT_STREQ("message" , GetTypeNameForFieldType(FD::TYPE_MESSAGE ));
  EXPECT_STREQ("bytes"   , GetTypeNameForFieldType(FD::TYPE_BYTES   ));
  EXPECT_STREQ("uint32"  , GetTypeNameForFieldType(FD::TYPE_UINT32  ));
  EXPECT_STREQ("enum"    , GetTypeNameForFieldType(FD::TYPE_ENUM    ));
  EXPECT_STREQ("sfixed32", GetTypeNameForFieldType(FD::TYPE_SFIXED32));
  EXPECT_STREQ("sfixed64", GetTypeNameForFieldType(FD::TYPE_SFIXED64));
  EXPECT_STREQ("sint32"  , GetTypeNameForFieldType(FD::TYPE_SINT32  ));
  EXPECT_STREQ("sint64"  , GetTypeNameForFieldType(FD::TYPE_SINT64  ));
}

TEST_F(MiscTest, CppTypes) {
  // Test that CPP types are assigned correctly.

  typedef FieldDescriptor FD;  // avoid ugly line wrapping

  EXPECT_EQ(FD::CPPTYPE_DOUBLE , GetCppTypeForFieldType(FD::TYPE_DOUBLE  ));
  EXPECT_EQ(FD::CPPTYPE_FLOAT  , GetCppTypeForFieldType(FD::TYPE_FLOAT   ));
  EXPECT_EQ(FD::CPPTYPE_INT64  , GetCppTypeForFieldType(FD::TYPE_INT64   ));
  EXPECT_EQ(FD::CPPTYPE_UINT64 , GetCppTypeForFieldType(FD::TYPE_UINT64  ));
  EXPECT_EQ(FD::CPPTYPE_INT32  , GetCppTypeForFieldType(FD::TYPE_INT32   ));
  EXPECT_EQ(FD::CPPTYPE_UINT64 , GetCppTypeForFieldType(FD::TYPE_FIXED64 ));
  EXPECT_EQ(FD::CPPTYPE_UINT32 , GetCppTypeForFieldType(FD::TYPE_FIXED32 ));
  EXPECT_EQ(FD::CPPTYPE_BOOL   , GetCppTypeForFieldType(FD::TYPE_BOOL    ));
  EXPECT_EQ(FD::CPPTYPE_STRING , GetCppTypeForFieldType(FD::TYPE_STRING  ));
  EXPECT_EQ(FD::CPPTYPE_MESSAGE, GetCppTypeForFieldType(FD::TYPE_GROUP   ));
  EXPECT_EQ(FD::CPPTYPE_MESSAGE, GetCppTypeForFieldType(FD::TYPE_MESSAGE ));
  EXPECT_EQ(FD::CPPTYPE_STRING , GetCppTypeForFieldType(FD::TYPE_BYTES   ));
  EXPECT_EQ(FD::CPPTYPE_UINT32 , GetCppTypeForFieldType(FD::TYPE_UINT32  ));
  EXPECT_EQ(FD::CPPTYPE_ENUM   , GetCppTypeForFieldType(FD::TYPE_ENUM    ));
  EXPECT_EQ(FD::CPPTYPE_INT32  , GetCppTypeForFieldType(FD::TYPE_SFIXED32));
  EXPECT_EQ(FD::CPPTYPE_INT64  , GetCppTypeForFieldType(FD::TYPE_SFIXED64));
  EXPECT_EQ(FD::CPPTYPE_INT32  , GetCppTypeForFieldType(FD::TYPE_SINT32  ));
  EXPECT_EQ(FD::CPPTYPE_INT64  , GetCppTypeForFieldType(FD::TYPE_SINT64  ));
}

TEST_F(MiscTest, CppTypeNames) {
  // Test that correct CPP type names are returned.

  typedef FieldDescriptor FD;  // avoid ugly line wrapping

  EXPECT_STREQ("double" , GetCppTypeNameForFieldType(FD::TYPE_DOUBLE  ));
  EXPECT_STREQ("float"  , GetCppTypeNameForFieldType(FD::TYPE_FLOAT   ));
  EXPECT_STREQ("int64"  , GetCppTypeNameForFieldType(FD::TYPE_INT64   ));
  EXPECT_STREQ("uint64" , GetCppTypeNameForFieldType(FD::TYPE_UINT64  ));
  EXPECT_STREQ("int32"  , GetCppTypeNameForFieldType(FD::TYPE_INT32   ));
  EXPECT_STREQ("uint64" , GetCppTypeNameForFieldType(FD::TYPE_FIXED64 ));
  EXPECT_STREQ("uint32" , GetCppTypeNameForFieldType(FD::TYPE_FIXED32 ));
  EXPECT_STREQ("bool"   , GetCppTypeNameForFieldType(FD::TYPE_BOOL    ));
  EXPECT_STREQ("string" , GetCppTypeNameForFieldType(FD::TYPE_STRING  ));
  EXPECT_STREQ("message", GetCppTypeNameForFieldType(FD::TYPE_GROUP   ));
  EXPECT_STREQ("message", GetCppTypeNameForFieldType(FD::TYPE_MESSAGE ));
  EXPECT_STREQ("string" , GetCppTypeNameForFieldType(FD::TYPE_BYTES   ));
  EXPECT_STREQ("uint32" , GetCppTypeNameForFieldType(FD::TYPE_UINT32  ));
  EXPECT_STREQ("enum"   , GetCppTypeNameForFieldType(FD::TYPE_ENUM    ));
  EXPECT_STREQ("int32"  , GetCppTypeNameForFieldType(FD::TYPE_SFIXED32));
  EXPECT_STREQ("int64"  , GetCppTypeNameForFieldType(FD::TYPE_SFIXED64));
  EXPECT_STREQ("int32"  , GetCppTypeNameForFieldType(FD::TYPE_SINT32  ));
  EXPECT_STREQ("int64"  , GetCppTypeNameForFieldType(FD::TYPE_SINT64  ));
}

TEST_F(MiscTest, DefaultValues) {
  // Test that setting default values works.
  FileDescriptorProto file_proto;
  file_proto.set_name("foo.proto");

  EnumDescriptorProto* enum_type_proto = AddEnum(&file_proto, "DummyEnum");
  AddEnumValue(enum_type_proto, "A", 1);
  AddEnumValue(enum_type_proto, "B", 2);

  DescriptorProto* message_proto = AddMessage(&file_proto, "TestMessage");

  typedef FieldDescriptorProto FD;  // avoid ugly line wrapping
  const FD::Label label = FD::LABEL_OPTIONAL;

  // Create fields of every CPP type with default values.
  AddField(message_proto, "int32" , 1, label, FD::TYPE_INT32 )
    ->set_default_value("-1");
  AddField(message_proto, "int64" , 2, label, FD::TYPE_INT64 )
    ->set_default_value("-1000000000000");
  AddField(message_proto, "uint32", 3, label, FD::TYPE_UINT32)
    ->set_default_value("42");
  AddField(message_proto, "uint64", 4, label, FD::TYPE_UINT64)
    ->set_default_value("2000000000000");
  AddField(message_proto, "float" , 5, label, FD::TYPE_FLOAT )
    ->set_default_value("4.5");
  AddField(message_proto, "double", 6, label, FD::TYPE_DOUBLE)
    ->set_default_value("10e100");
  AddField(message_proto, "bool"  , 7, label, FD::TYPE_BOOL  )
    ->set_default_value("true");
  AddField(message_proto, "string", 8, label, FD::TYPE_STRING)
    ->set_default_value("hello");
  AddField(message_proto, "data"  , 9, label, FD::TYPE_BYTES )
    ->set_default_value("\\001\\002\\003");

  FieldDescriptorProto* enum_field =
    AddField(message_proto, "enum", 10, label, FD::TYPE_ENUM);
  enum_field->set_type_name("DummyEnum");
  enum_field->set_default_value("B");

  // Strings are allowed to have empty defaults.  (At one point, due to
  // a bug, empty defaults for strings were rejected.  Oops.)
  AddField(message_proto, "empty_string", 11, label, FD::TYPE_STRING)
    ->set_default_value("");

  // Add a second set of fields with implicit defalut values.
  AddField(message_proto, "implicit_int32" , 21, label, FD::TYPE_INT32 );
  AddField(message_proto, "implicit_int64" , 22, label, FD::TYPE_INT64 );
  AddField(message_proto, "implicit_uint32", 23, label, FD::TYPE_UINT32);
  AddField(message_proto, "implicit_uint64", 24, label, FD::TYPE_UINT64);
  AddField(message_proto, "implicit_float" , 25, label, FD::TYPE_FLOAT );
  AddField(message_proto, "implicit_double", 26, label, FD::TYPE_DOUBLE);
  AddField(message_proto, "implicit_bool"  , 27, label, FD::TYPE_BOOL  );
  AddField(message_proto, "implicit_string", 28, label, FD::TYPE_STRING);
  AddField(message_proto, "implicit_data"  , 29, label, FD::TYPE_BYTES );
  AddField(message_proto, "implicit_enum"  , 30, label, FD::TYPE_ENUM)
    ->set_type_name("DummyEnum");

  // Build it.
  DescriptorPool pool;
  const FileDescriptor* file = pool.BuildFile(file_proto);
  ASSERT_TRUE(file != NULL);

  ASSERT_EQ(1, file->enum_type_count());
  const EnumDescriptor* enum_type = file->enum_type(0);
  ASSERT_EQ(2, enum_type->value_count());
  const EnumValueDescriptor* enum_value_a = enum_type->value(0);
  const EnumValueDescriptor* enum_value_b = enum_type->value(1);

  ASSERT_EQ(1, file->message_type_count());
  const Descriptor* message = file->message_type(0);

  ASSERT_EQ(21, message->field_count());

  // Check the default values.
  ASSERT_TRUE(message->field(0)->has_default_value());
  ASSERT_TRUE(message->field(1)->has_default_value());
  ASSERT_TRUE(message->field(2)->has_default_value());
  ASSERT_TRUE(message->field(3)->has_default_value());
  ASSERT_TRUE(message->field(4)->has_default_value());
  ASSERT_TRUE(message->field(5)->has_default_value());
  ASSERT_TRUE(message->field(6)->has_default_value());
  ASSERT_TRUE(message->field(7)->has_default_value());
  ASSERT_TRUE(message->field(8)->has_default_value());
  ASSERT_TRUE(message->field(9)->has_default_value());
  ASSERT_TRUE(message->field(10)->has_default_value());

  EXPECT_EQ(-1              , message->field(0)->default_value_int32 ());
  EXPECT_EQ(-GOOGLE_ULONGLONG(1000000000000),
            message->field(1)->default_value_int64 ());
  EXPECT_EQ(42              , message->field(2)->default_value_uint32());
  EXPECT_EQ(GOOGLE_ULONGLONG(2000000000000),
            message->field(3)->default_value_uint64());
  EXPECT_EQ(4.5             , message->field(4)->default_value_float ());
  EXPECT_EQ(10e100          , message->field(5)->default_value_double());
  EXPECT_TRUE(                message->field(6)->default_value_bool  ());
  EXPECT_EQ("hello"         , message->field(7)->default_value_string());
  EXPECT_EQ("\001\002\003"  , message->field(8)->default_value_string());
  EXPECT_EQ(enum_value_b    , message->field(9)->default_value_enum  ());
  EXPECT_EQ(""              , message->field(10)->default_value_string());

  ASSERT_FALSE(message->field(11)->has_default_value());
  ASSERT_FALSE(message->field(12)->has_default_value());
  ASSERT_FALSE(message->field(13)->has_default_value());
  ASSERT_FALSE(message->field(14)->has_default_value());
  ASSERT_FALSE(message->field(15)->has_default_value());
  ASSERT_FALSE(message->field(16)->has_default_value());
  ASSERT_FALSE(message->field(17)->has_default_value());
  ASSERT_FALSE(message->field(18)->has_default_value());
  ASSERT_FALSE(message->field(19)->has_default_value());
  ASSERT_FALSE(message->field(20)->has_default_value());

  EXPECT_EQ(0    , message->field(11)->default_value_int32 ());
  EXPECT_EQ(0    , message->field(12)->default_value_int64 ());
  EXPECT_EQ(0    , message->field(13)->default_value_uint32());
  EXPECT_EQ(0    , message->field(14)->default_value_uint64());
  EXPECT_EQ(0.0f , message->field(15)->default_value_float ());
  EXPECT_EQ(0.0  , message->field(16)->default_value_double());
  EXPECT_FALSE(    message->field(17)->default_value_bool  ());
  EXPECT_EQ(""   , message->field(18)->default_value_string());
  EXPECT_EQ(""   , message->field(19)->default_value_string());
  EXPECT_EQ(enum_value_a, message->field(20)->default_value_enum());
}

TEST_F(MiscTest, FieldOptions) {
  // Try setting field options.

  FileDescriptorProto file_proto;
  file_proto.set_name("foo.proto");

  DescriptorProto* message_proto = AddMessage(&file_proto, "TestMessage");
  AddField(message_proto, "foo", 1,
           FieldDescriptorProto::LABEL_OPTIONAL,
           FieldDescriptorProto::TYPE_INT32);
  FieldDescriptorProto* bar_proto =
    AddField(message_proto, "bar", 2,
             FieldDescriptorProto::LABEL_OPTIONAL,
             FieldDescriptorProto::TYPE_INT32);

  FieldOptions* options = bar_proto->mutable_options();
  options->set_ctype(FieldOptions::CORD);

  // Build the descriptors and get the pointers.
  DescriptorPool pool;
  const FileDescriptor* file = pool.BuildFile(file_proto);
  ASSERT_TRUE(file != NULL);

  ASSERT_EQ(1, file->message_type_count());
  const Descriptor* message = file->message_type(0);

  ASSERT_EQ(2, message->field_count());
  const FieldDescriptor* foo = message->field(0);
  const FieldDescriptor* bar = message->field(1);

  // "foo" had no options set, so it should return the default options.
  EXPECT_EQ(&FieldOptions::default_instance(), &foo->options());

  // "bar" had options set.
  EXPECT_NE(&FieldOptions::default_instance(), options);
  EXPECT_TRUE(bar->options().has_ctype());
  EXPECT_EQ(FieldOptions::CORD, bar->options().ctype());
}

// ===================================================================
enum DescriptorPoolMode {
  NO_DATABASE,
  FALLBACK_DATABASE
};

class AllowUnknownDependenciesTest
    : public testing::TestWithParam<DescriptorPoolMode> {
 protected:
  DescriptorPoolMode mode() {
    return GetParam();
   }

  virtual void SetUp() {
    FileDescriptorProto foo_proto, bar_proto;

    switch (mode()) {
      case NO_DATABASE:
        pool_.reset(new DescriptorPool);
        break;
      case FALLBACK_DATABASE:
        pool_.reset(new DescriptorPool(&db_));
        break;
    }

    pool_->AllowUnknownDependencies();

    ASSERT_TRUE(TextFormat::ParseFromString(
      "name: 'foo.proto'"
      "dependency: 'bar.proto'"
      "dependency: 'baz.proto'"
      "message_type {"
      "  name: 'Foo'"
      "  field { name:'bar' number:1 label:LABEL_OPTIONAL type_name:'Bar' }"
      "  field { name:'baz' number:2 label:LABEL_OPTIONAL type_name:'Baz' }"
      "  field { name:'qux' number:3 label:LABEL_OPTIONAL"
      "    type_name: '.corge.Qux'"
      "    type: TYPE_ENUM"
      "    options {"
      "      uninterpreted_option {"
      "        name {"
      "          name_part: 'grault'"
      "          is_extension: true"
      "        }"
      "        positive_int_value: 1234"
      "      }"
      "    }"
      "  }"
      "}",
      &foo_proto));
    ASSERT_TRUE(TextFormat::ParseFromString(
      "name: 'bar.proto'"
      "message_type { name: 'Bar' }",
      &bar_proto));

    // Collect pointers to stuff.
    bar_file_ = BuildFile(bar_proto);
    ASSERT_TRUE(bar_file_ != NULL);

    ASSERT_EQ(1, bar_file_->message_type_count());
    bar_type_ = bar_file_->message_type(0);

    foo_file_ = BuildFile(foo_proto);
    ASSERT_TRUE(foo_file_ != NULL);

    ASSERT_EQ(1, foo_file_->message_type_count());
    foo_type_ = foo_file_->message_type(0);

    ASSERT_EQ(3, foo_type_->field_count());
    bar_field_ = foo_type_->field(0);
    baz_field_ = foo_type_->field(1);
    qux_field_ = foo_type_->field(2);
  }

  const FileDescriptor* BuildFile(const FileDescriptorProto& proto) {
    switch (mode()) {
      case NO_DATABASE:
        return pool_->BuildFile(proto);
        break;
      case FALLBACK_DATABASE: {
        EXPECT_TRUE(db_.Add(proto));
        return pool_->FindFileByName(proto.name());
      }
    }
    GOOGLE_LOG(FATAL) << "Can't get here.";
    return NULL;
  }

  const FileDescriptor* bar_file_;
  const Descriptor* bar_type_;
  const FileDescriptor* foo_file_;
  const Descriptor* foo_type_;
  const FieldDescriptor* bar_field_;
  const FieldDescriptor* baz_field_;
  const FieldDescriptor* qux_field_;

  SimpleDescriptorDatabase db_;        // used if in FALLBACK_DATABASE mode.
  scoped_ptr<DescriptorPool> pool_;
};

TEST_P(AllowUnknownDependenciesTest, PlaceholderFile) {
  ASSERT_EQ(2, foo_file_->dependency_count());
  EXPECT_EQ(bar_file_, foo_file_->dependency(0));

  const FileDescriptor* baz_file = foo_file_->dependency(1);
  EXPECT_EQ("baz.proto", baz_file->name());
  EXPECT_EQ(0, baz_file->message_type_count());

  // Placeholder files should not be findable.
  EXPECT_EQ(bar_file_, pool_->FindFileByName(bar_file_->name()));
  EXPECT_TRUE(pool_->FindFileByName(baz_file->name()) == NULL);
}

TEST_P(AllowUnknownDependenciesTest, PlaceholderTypes) {
  ASSERT_EQ(FieldDescriptor::TYPE_MESSAGE, bar_field_->type());
  EXPECT_EQ(bar_type_, bar_field_->message_type());

  ASSERT_EQ(FieldDescriptor::TYPE_MESSAGE, baz_field_->type());
  const Descriptor* baz_type = baz_field_->message_type();
  EXPECT_EQ("Baz", baz_type->name());
  EXPECT_EQ("Baz", baz_type->full_name());
  EXPECT_EQ("Baz.placeholder.proto", baz_type->file()->name());
  EXPECT_EQ(0, baz_type->extension_range_count());

  ASSERT_EQ(FieldDescriptor::TYPE_ENUM, qux_field_->type());
  const EnumDescriptor* qux_type = qux_field_->enum_type();
  EXPECT_EQ("Qux", qux_type->name());
  EXPECT_EQ("corge.Qux", qux_type->full_name());
  EXPECT_EQ("corge.Qux.placeholder.proto", qux_type->file()->name());

  // Placeholder types should not be findable.
  EXPECT_EQ(bar_type_, pool_->FindMessageTypeByName(bar_type_->full_name()));
  EXPECT_TRUE(pool_->FindMessageTypeByName(baz_type->full_name()) == NULL);
  EXPECT_TRUE(pool_->FindEnumTypeByName(qux_type->full_name()) == NULL);
}

TEST_P(AllowUnknownDependenciesTest, CopyTo) {
  // FieldDescriptor::CopyTo() should write non-fully-qualified type names
  // for placeholder types which were not originally fully-qualified.
  FieldDescriptorProto proto;

  // Bar is not a placeholder, so it is fully-qualified.
  bar_field_->CopyTo(&proto);
  EXPECT_EQ(".Bar", proto.type_name());
  EXPECT_EQ(FieldDescriptorProto::TYPE_MESSAGE, proto.type());

  // Baz is an unqualified placeholder.
  proto.Clear();
  baz_field_->CopyTo(&proto);
  EXPECT_EQ("Baz", proto.type_name());
  EXPECT_FALSE(proto.has_type());

  // Qux is a fully-qualified placeholder.
  proto.Clear();
  qux_field_->CopyTo(&proto);
  EXPECT_EQ(".corge.Qux", proto.type_name());
  EXPECT_EQ(FieldDescriptorProto::TYPE_ENUM, proto.type());
}

TEST_P(AllowUnknownDependenciesTest, CustomOptions) {
  // Qux should still have the uninterpreted option attached.
  ASSERT_EQ(1, qux_field_->options().uninterpreted_option_size());
  const UninterpretedOption& option =
    qux_field_->options().uninterpreted_option(0);
  ASSERT_EQ(1, option.name_size());
  EXPECT_EQ("grault", option.name(0).name_part());
}

TEST_P(AllowUnknownDependenciesTest, UnknownExtendee) {
  // Test that we can extend an unknown type.  This is slightly tricky because
  // it means that the placeholder type must have an extension range.

  FileDescriptorProto extension_proto;

  ASSERT_TRUE(TextFormat::ParseFromString(
    "name: 'extension.proto'"
    "extension { extendee: 'UnknownType' name:'some_extension' number:123"
    "            label:LABEL_OPTIONAL type:TYPE_INT32 }",
    &extension_proto));
  const FileDescriptor* file = BuildFile(extension_proto);

  ASSERT_TRUE(file != NULL);

  ASSERT_EQ(1, file->extension_count());
  const Descriptor* extendee = file->extension(0)->containing_type();
  EXPECT_EQ("UnknownType", extendee->name());
  ASSERT_EQ(1, extendee->extension_range_count());
  EXPECT_EQ(1, extendee->extension_range(0)->start);
  EXPECT_EQ(FieldDescriptor::kMaxNumber + 1, extendee->extension_range(0)->end);
}

TEST_P(AllowUnknownDependenciesTest, CustomOption) {
  // Test that we can use a custom option without having parsed
  // descriptor.proto.

  FileDescriptorProto option_proto;

  ASSERT_TRUE(TextFormat::ParseFromString(
    "name: \"unknown_custom_options.proto\" "
    "dependency: \"google/protobuf/descriptor.proto\" "
    "extension { "
    "  extendee: \"google.protobuf.FileOptions\" "
    "  name: \"some_option\" "
    "  number: 123456 "
    "  label: LABEL_OPTIONAL "
    "  type: TYPE_INT32 "
    "} "
    "options { "
    "  uninterpreted_option { "
    "    name { "
    "      name_part: \"some_option\" "
    "      is_extension: true "
    "    } "
    "    positive_int_value: 1234 "
    "  } "
    "  uninterpreted_option { "
    "    name { "
    "      name_part: \"unknown_option\" "
    "      is_extension: true "
    "    } "
    "    positive_int_value: 1234 "
    "  } "
    "  uninterpreted_option { "
    "    name { "
    "      name_part: \"optimize_for\" "
    "      is_extension: false "
    "    } "
    "    identifier_value: \"SPEED\" "
    "  } "
    "}",
    &option_proto));

  const FileDescriptor* file = BuildFile(option_proto);
  ASSERT_TRUE(file != NULL);

  // Verify that no extension options were set, but they were left as
  // uninterpreted_options.
  vector<const FieldDescriptor*> fields;
  file->options().GetReflection()->ListFields(file->options(), &fields);
  ASSERT_EQ(2, fields.size());
  EXPECT_TRUE(file->options().has_optimize_for());
  EXPECT_EQ(2, file->options().uninterpreted_option_size());
}

TEST_P(AllowUnknownDependenciesTest,
       UndeclaredDependencyTriggersBuildOfDependency) {
  // Crazy case: suppose foo.proto refers to a symbol without declaring the
  // dependency that finds it. In the event that the pool is backed by a
  // DescriptorDatabase, the pool will attempt to find the symbol in the
  // database. If successful, it will build the undeclared dependency to verify
  // that the file does indeed contain the symbol. If that file fails to build,
  // then its descriptors must be rolled back. However, we still want foo.proto
  // to build successfully, since we are allowing unknown dependencies.

  FileDescriptorProto undeclared_dep_proto;
  // We make this file fail to build by giving it two fields with tag 1.
  ASSERT_TRUE(TextFormat::ParseFromString(
    "name: \"invalid_file_as_undeclared_dep.proto\" "
    "package: \"undeclared\" "
    "message_type: {  "
    "  name: \"Quux\"  "
    "  field { "
    "    name:'qux' number:1 label:LABEL_OPTIONAL type: TYPE_INT32 "
    "  }"
    "  field { "
    "    name:'quux' number:1 label:LABEL_OPTIONAL type: TYPE_INT64 "
    "  }"
    "}",
    &undeclared_dep_proto));
  // We can't use the BuildFile() helper because we don't actually want to build
  // it into the descriptor pool in the fallback database case: it just needs to
  // be sitting in the database so that it gets built during the building of
  // test.proto below.
  switch (mode()) {
    case NO_DATABASE: {
      ASSERT_TRUE(pool_->BuildFile(undeclared_dep_proto) == NULL);
      break;
    }
    case FALLBACK_DATABASE: {
      ASSERT_TRUE(db_.Add(undeclared_dep_proto));
    }
  }

  FileDescriptorProto test_proto;
  ASSERT_TRUE(TextFormat::ParseFromString(
    "name: \"test.proto\" "
    "message_type: { "
    "  name: \"Corge\" "
    "  field { "
    "    name:'quux' number:1 label: LABEL_OPTIONAL "
    "    type_name:'undeclared.Quux' type: TYPE_MESSAGE "
    "  }"
    "}",
    &test_proto));

  const FileDescriptor* file = BuildFile(test_proto);
  ASSERT_TRUE(file != NULL);
  GOOGLE_LOG(INFO) << file->DebugString();

  EXPECT_EQ(0, file->dependency_count());
  ASSERT_EQ(1, file->message_type_count());
  const Descriptor* corge_desc = file->message_type(0);
  ASSERT_EQ("Corge", corge_desc->name());
  ASSERT_EQ(1, corge_desc->field_count());

  const FieldDescriptor* quux_field = corge_desc->field(0);
  ASSERT_EQ(FieldDescriptor::TYPE_MESSAGE, quux_field->type());
  ASSERT_EQ("Quux", quux_field->message_type()->name());
  ASSERT_EQ("undeclared.Quux", quux_field->message_type()->full_name());
  EXPECT_EQ("undeclared.Quux.placeholder.proto",
            quux_field->message_type()->file()->name());
  // The place holder type should not be findable.
  ASSERT_TRUE(pool_->FindMessageTypeByName("undeclared.Quux") == NULL);
}

INSTANTIATE_TEST_CASE_P(DatabaseSource,
                        AllowUnknownDependenciesTest,
                        testing::Values(NO_DATABASE, FALLBACK_DATABASE));

// ===================================================================

TEST(CustomOptions, OptionLocations) {
  const Descriptor* message =
      protobuf_unittest::TestMessageWithCustomOptions::descriptor();
  const FileDescriptor* file = message->file();
  const FieldDescriptor* field = message->FindFieldByName("field1");
  const EnumDescriptor* enm = message->FindEnumTypeByName("AnEnum");
  // TODO(benjy): Support EnumValue options, once the compiler does.
  const ServiceDescriptor* service =
      file->FindServiceByName("TestServiceWithCustomOptions");
  const MethodDescriptor* method = service->FindMethodByName("Foo");

  EXPECT_EQ(GOOGLE_LONGLONG(9876543210),
            file->options().GetExtension(protobuf_unittest::file_opt1));
  EXPECT_EQ(-56,
            message->options().GetExtension(protobuf_unittest::message_opt1));
  EXPECT_EQ(GOOGLE_LONGLONG(8765432109),
            field->options().GetExtension(protobuf_unittest::field_opt1));
  EXPECT_EQ(42,  // Check that we get the default for an option we don't set.
            field->options().GetExtension(protobuf_unittest::field_opt2));
  EXPECT_EQ(-789,
            enm->options().GetExtension(protobuf_unittest::enum_opt1));
  EXPECT_EQ(123,
            enm->value(1)->options().GetExtension(
              protobuf_unittest::enum_value_opt1));
  EXPECT_EQ(GOOGLE_LONGLONG(-9876543210),
            service->options().GetExtension(protobuf_unittest::service_opt1));
  EXPECT_EQ(protobuf_unittest::METHODOPT1_VAL2,
            method->options().GetExtension(protobuf_unittest::method_opt1));

  // See that the regular options went through unscathed.
  EXPECT_TRUE(message->options().has_message_set_wire_format());
  EXPECT_EQ(FieldOptions::CORD, field->options().ctype());
}

TEST(CustomOptions, OptionTypes) {
  const MessageOptions* options = NULL;

  options =
      &protobuf_unittest::CustomOptionMinIntegerValues::descriptor()->options();
  EXPECT_FALSE(        options->GetExtension(protobuf_unittest::bool_opt));
  EXPECT_EQ(kint32min, options->GetExtension(protobuf_unittest::int32_opt));
  EXPECT_EQ(kint64min, options->GetExtension(protobuf_unittest::int64_opt));
  EXPECT_EQ(0        , options->GetExtension(protobuf_unittest::uint32_opt));
  EXPECT_EQ(0        , options->GetExtension(protobuf_unittest::uint64_opt));
  EXPECT_EQ(kint32min, options->GetExtension(protobuf_unittest::sint32_opt));
  EXPECT_EQ(kint64min, options->GetExtension(protobuf_unittest::sint64_opt));
  EXPECT_EQ(0        , options->GetExtension(protobuf_unittest::fixed32_opt));
  EXPECT_EQ(0        , options->GetExtension(protobuf_unittest::fixed64_opt));
  EXPECT_EQ(kint32min, options->GetExtension(protobuf_unittest::sfixed32_opt));
  EXPECT_EQ(kint64min, options->GetExtension(protobuf_unittest::sfixed64_opt));

  options =
      &protobuf_unittest::CustomOptionMaxIntegerValues::descriptor()->options();
  EXPECT_TRUE(          options->GetExtension(protobuf_unittest::bool_opt));
  EXPECT_EQ(kint32max , options->GetExtension(protobuf_unittest::int32_opt));
  EXPECT_EQ(kint64max , options->GetExtension(protobuf_unittest::int64_opt));
  EXPECT_EQ(kuint32max, options->GetExtension(protobuf_unittest::uint32_opt));
  EXPECT_EQ(kuint64max, options->GetExtension(protobuf_unittest::uint64_opt));
  EXPECT_EQ(kint32max , options->GetExtension(protobuf_unittest::sint32_opt));
  EXPECT_EQ(kint64max , options->GetExtension(protobuf_unittest::sint64_opt));
  EXPECT_EQ(kuint32max, options->GetExtension(protobuf_unittest::fixed32_opt));
  EXPECT_EQ(kuint64max, options->GetExtension(protobuf_unittest::fixed64_opt));
  EXPECT_EQ(kint32max , options->GetExtension(protobuf_unittest::sfixed32_opt));
  EXPECT_EQ(kint64max , options->GetExtension(protobuf_unittest::sfixed64_opt));

  options =
      &protobuf_unittest::CustomOptionOtherValues::descriptor()->options();
  EXPECT_EQ(-100, options->GetExtension(protobuf_unittest::int32_opt));
  EXPECT_FLOAT_EQ(12.3456789,
                  options->GetExtension(protobuf_unittest::float_opt));
  EXPECT_DOUBLE_EQ(1.234567890123456789,
                   options->GetExtension(protobuf_unittest::double_opt));
  EXPECT_EQ("Hello, \"World\"",
            options->GetExtension(protobuf_unittest::string_opt));

  EXPECT_EQ(string("Hello\0World", 11),
            options->GetExtension(protobuf_unittest::bytes_opt));

  EXPECT_EQ(protobuf_unittest::DummyMessageContainingEnum::TEST_OPTION_ENUM_TYPE2,
            options->GetExtension(protobuf_unittest::enum_opt));

  options =
      &protobuf_unittest::SettingRealsFromPositiveInts::descriptor()->options();
  EXPECT_FLOAT_EQ(12, options->GetExtension(protobuf_unittest::float_opt));
  EXPECT_DOUBLE_EQ(154, options->GetExtension(protobuf_unittest::double_opt));

  options =
      &protobuf_unittest::SettingRealsFromNegativeInts::descriptor()->options();
  EXPECT_FLOAT_EQ(-12, options->GetExtension(protobuf_unittest::float_opt));
  EXPECT_DOUBLE_EQ(-154, options->GetExtension(protobuf_unittest::double_opt));
}

TEST(CustomOptions, ComplexExtensionOptions) {
  const MessageOptions* options =
      &protobuf_unittest::VariousComplexOptions::descriptor()->options();
  EXPECT_EQ(options->GetExtension(protobuf_unittest::complex_opt1).foo(), 42);
  EXPECT_EQ(options->GetExtension(protobuf_unittest::complex_opt1).
            GetExtension(protobuf_unittest::quux), 324);
  EXPECT_EQ(options->GetExtension(protobuf_unittest::complex_opt1).
            GetExtension(protobuf_unittest::corge).qux(), 876);
  EXPECT_EQ(options->GetExtension(protobuf_unittest::complex_opt2).baz(), 987);
  EXPECT_EQ(options->GetExtension(protobuf_unittest::complex_opt2).
            GetExtension(protobuf_unittest::grault), 654);
  EXPECT_EQ(options->GetExtension(protobuf_unittest::complex_opt2).bar().foo(),
            743);
  EXPECT_EQ(options->GetExtension(protobuf_unittest::complex_opt2).bar().
            GetExtension(protobuf_unittest::quux), 1999);
  EXPECT_EQ(options->GetExtension(protobuf_unittest::complex_opt2).bar().
            GetExtension(protobuf_unittest::corge).qux(), 2008);
  EXPECT_EQ(options->GetExtension(protobuf_unittest::complex_opt2).
            GetExtension(protobuf_unittest::garply).foo(), 741);
  EXPECT_EQ(options->GetExtension(protobuf_unittest::complex_opt2).
            GetExtension(protobuf_unittest::garply).
            GetExtension(protobuf_unittest::quux), 1998);
  EXPECT_EQ(options->GetExtension(protobuf_unittest::complex_opt2).
            GetExtension(protobuf_unittest::garply).
            GetExtension(protobuf_unittest::corge).qux(), 2121);
  EXPECT_EQ(options->GetExtension(
      protobuf_unittest::ComplexOptionType2::ComplexOptionType4::complex_opt4).
            waldo(), 1971);
  EXPECT_EQ(options->GetExtension(protobuf_unittest::complex_opt2).
            fred().waldo(), 321);
  EXPECT_EQ(9, options->GetExtension(protobuf_unittest::complex_opt3).qux());
  EXPECT_EQ(22, options->GetExtension(protobuf_unittest::complex_opt3).
                complexoptiontype5().plugh());
  EXPECT_EQ(24, options->GetExtension(protobuf_unittest::complexopt6).xyzzy());
}

TEST(CustomOptions, OptionsFromOtherFile) {
  // Test that to use a custom option, we only need to import the file
  // defining the option; we do not also have to import descriptor.proto.
  DescriptorPool pool;

  FileDescriptorProto file_proto;
  FileDescriptorProto::descriptor()->file()->CopyTo(&file_proto);
  ASSERT_TRUE(pool.BuildFile(file_proto) != NULL);

  protobuf_unittest::TestMessageWithCustomOptions::descriptor()
    ->file()->CopyTo(&file_proto);
  ASSERT_TRUE(pool.BuildFile(file_proto) != NULL);

  ASSERT_TRUE(TextFormat::ParseFromString(
    "name: \"custom_options_import.proto\" "
    "package: \"protobuf_unittest\" "
    "dependency: \"google/protobuf/unittest_custom_options.proto\" "
    "options { "
    "  uninterpreted_option { "
    "    name { "
    "      name_part: \"file_opt1\" "
    "      is_extension: true "
    "    } "
    "    positive_int_value: 1234 "
    "  } "
    // Test a non-extension option too.  (At one point this failed due to a
    // bug.)
    "  uninterpreted_option { "
    "    name { "
    "      name_part: \"java_package\" "
    "      is_extension: false "
    "    } "
    "    string_value: \"foo\" "
    "  } "
    // Test that enum-typed options still work too.  (At one point this also
    // failed due to a bug.)
    "  uninterpreted_option { "
    "    name { "
    "      name_part: \"optimize_for\" "
    "      is_extension: false "
    "    } "
    "    identifier_value: \"SPEED\" "
    "  } "
    "}"
    ,
    &file_proto));

  const FileDescriptor* file = pool.BuildFile(file_proto);
  ASSERT_TRUE(file != NULL);
  EXPECT_EQ(1234, file->options().GetExtension(protobuf_unittest::file_opt1));
  EXPECT_TRUE(file->options().has_java_package());
  EXPECT_EQ("foo", file->options().java_package());
  EXPECT_TRUE(file->options().has_optimize_for());
  EXPECT_EQ(FileOptions::SPEED, file->options().optimize_for());
}

TEST(CustomOptions, MessageOptionThreeFieldsSet) {
  // This tests a bug which previously existed in custom options parsing.  The
  // bug occurred when you defined a custom option with message type and then
  // set three fields of that option on a single definition (see the example
  // below).  The bug is a bit hard to explain, so check the change history if
  // you want to know more.
  DescriptorPool pool;

  FileDescriptorProto file_proto;
  FileDescriptorProto::descriptor()->file()->CopyTo(&file_proto);
  ASSERT_TRUE(pool.BuildFile(file_proto) != NULL);

  protobuf_unittest::TestMessageWithCustomOptions::descriptor()
    ->file()->CopyTo(&file_proto);
  ASSERT_TRUE(pool.BuildFile(file_proto) != NULL);

  // The following represents the definition:
  //
  //   import "google/protobuf/unittest_custom_options.proto"
  //   package protobuf_unittest;
  //   message Foo {
  //     option (complex_opt1).foo  = 1234;
  //     option (complex_opt1).foo2 = 1234;
  //     option (complex_opt1).foo3 = 1234;
  //   }
  ASSERT_TRUE(TextFormat::ParseFromString(
    "name: \"custom_options_import.proto\" "
    "package: \"protobuf_unittest\" "
    "dependency: \"google/protobuf/unittest_custom_options.proto\" "
    "message_type { "
    "  name: \"Foo\" "
    "  options { "
    "    uninterpreted_option { "
    "      name { "
    "        name_part: \"complex_opt1\" "
    "        is_extension: true "
    "      } "
    "      name { "
    "        name_part: \"foo\" "
    "        is_extension: false "
    "      } "
    "      positive_int_value: 1234 "
    "    } "
    "    uninterpreted_option { "
    "      name { "
    "        name_part: \"complex_opt1\" "
    "        is_extension: true "
    "      } "
    "      name { "
    "        name_part: \"foo2\" "
    "        is_extension: false "
    "      } "
    "      positive_int_value: 1234 "
    "    } "
    "    uninterpreted_option { "
    "      name { "
    "        name_part: \"complex_opt1\" "
    "        is_extension: true "
    "      } "
    "      name { "
    "        name_part: \"foo3\" "
    "        is_extension: false "
    "      } "
    "      positive_int_value: 1234 "
    "    } "
    "  } "
    "}",
    &file_proto));

  const FileDescriptor* file = pool.BuildFile(file_proto);
  ASSERT_TRUE(file != NULL);
  ASSERT_EQ(1, file->message_type_count());

  const MessageOptions& options = file->message_type(0)->options();
  EXPECT_EQ(1234, options.GetExtension(protobuf_unittest::complex_opt1).foo());
}

// Check that aggregate options were parsed and saved correctly in
// the appropriate descriptors.
TEST(CustomOptions, AggregateOptions) {
  const Descriptor* msg = protobuf_unittest::AggregateMessage::descriptor();
  const FileDescriptor* file = msg->file();
  const FieldDescriptor* field = msg->FindFieldByName("fieldname");
  const EnumDescriptor* enumd = file->FindEnumTypeByName("AggregateEnum");
  const EnumValueDescriptor* enumv = enumd->FindValueByName("VALUE");
  const ServiceDescriptor* service = file->FindServiceByName(
      "AggregateService");
  const MethodDescriptor* method = service->FindMethodByName("Method");

  // Tests for the different types of data embedded in fileopt
  const protobuf_unittest::Aggregate& file_options =
      file->options().GetExtension(protobuf_unittest::fileopt);
  EXPECT_EQ(100, file_options.i());
  EXPECT_EQ("FileAnnotation", file_options.s());
  EXPECT_EQ("NestedFileAnnotation", file_options.sub().s());
  EXPECT_EQ("FileExtensionAnnotation",
            file_options.file().GetExtension(protobuf_unittest::fileopt).s());
  EXPECT_EQ("EmbeddedMessageSetElement",
            file_options.mset().GetExtension(
                protobuf_unittest::AggregateMessageSetElement
                ::message_set_extension).s());

  // Simple tests for all the other types of annotations
  EXPECT_EQ("MessageAnnotation",
            msg->options().GetExtension(protobuf_unittest::msgopt).s());
  EXPECT_EQ("FieldAnnotation",
            field->options().GetExtension(protobuf_unittest::fieldopt).s());
  EXPECT_EQ("EnumAnnotation",
            enumd->options().GetExtension(protobuf_unittest::enumopt).s());
  EXPECT_EQ("EnumValueAnnotation",
            enumv->options().GetExtension(protobuf_unittest::enumvalopt).s());
  EXPECT_EQ("ServiceAnnotation",
            service->options().GetExtension(protobuf_unittest::serviceopt).s());
  EXPECT_EQ("MethodAnnotation",
            method->options().GetExtension(protobuf_unittest::methodopt).s());
}

// ===================================================================

// The tests below trigger every unique call to AddError() in descriptor.cc,
// in the order in which they appear in that file.  I'm using TextFormat here
// to specify the input descriptors because building them using code would
// be too bulky.

class MockErrorCollector : public DescriptorPool::ErrorCollector {
 public:
  MockErrorCollector() {}
  ~MockErrorCollector() {}

  string text_;

  // implements ErrorCollector ---------------------------------------
  void AddError(const string& filename,
                const string& element_name, const Message* descriptor,
                ErrorLocation location, const string& message) {
    const char* location_name = NULL;
    switch (location) {
      case NAME         : location_name = "NAME"         ; break;
      case NUMBER       : location_name = "NUMBER"       ; break;
      case TYPE         : location_name = "TYPE"         ; break;
      case EXTENDEE     : location_name = "EXTENDEE"     ; break;
      case DEFAULT_VALUE: location_name = "DEFAULT_VALUE"; break;
      case OPTION_NAME  : location_name = "OPTION_NAME"  ; break;
      case OPTION_VALUE : location_name = "OPTION_VALUE" ; break;
      case INPUT_TYPE   : location_name = "INPUT_TYPE"   ; break;
      case OUTPUT_TYPE  : location_name = "OUTPUT_TYPE"  ; break;
      case OTHER        : location_name = "OTHER"        ; break;
    }

    strings::SubstituteAndAppend(
      &text_, "$0: $1: $2: $3\n",
      filename, element_name, location_name, message);
  }
};

class ValidationErrorTest : public testing::Test {
 protected:
  // Parse file_text as a FileDescriptorProto in text format and add it
  // to the DescriptorPool.  Expect no errors.
  void BuildFile(const string& file_text) {
    FileDescriptorProto file_proto;
    ASSERT_TRUE(TextFormat::ParseFromString(file_text, &file_proto));
    ASSERT_TRUE(pool_.BuildFile(file_proto) != NULL);
  }

  // Parse file_text as a FileDescriptorProto in text format and add it
  // to the DescriptorPool.  Expect errors to be produced which match the
  // given error text.
  void BuildFileWithErrors(const string& file_text,
                           const string& expected_errors) {
    FileDescriptorProto file_proto;
    ASSERT_TRUE(TextFormat::ParseFromString(file_text, &file_proto));

    MockErrorCollector error_collector;
    EXPECT_TRUE(
      pool_.BuildFileCollectingErrors(file_proto, &error_collector) == NULL);
    EXPECT_EQ(expected_errors, error_collector.text_);
  }

  // Builds some already-parsed file in our test pool.
  void BuildFileInTestPool(const FileDescriptor* file) {
    FileDescriptorProto file_proto;
    file->CopyTo(&file_proto);
    ASSERT_TRUE(pool_.BuildFile(file_proto) != NULL);
  }

  // Build descriptor.proto in our test pool. This allows us to extend it in
  // the test pool, so we can test custom options.
  void BuildDescriptorMessagesInTestPool() {
    BuildFileInTestPool(DescriptorProto::descriptor()->file());
  }

  DescriptorPool pool_;
};

TEST_F(ValidationErrorTest, AlreadyDefined) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type { name: \"Foo\" }"
    "message_type { name: \"Foo\" }",

    "foo.proto: Foo: NAME: \"Foo\" is already defined.\n");
}

TEST_F(ValidationErrorTest, AlreadyDefinedInPackage) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "package: \"foo.bar\" "
    "message_type { name: \"Foo\" }"
    "message_type { name: \"Foo\" }",

    "foo.proto: foo.bar.Foo: NAME: \"Foo\" is already defined in "
      "\"foo.bar\".\n");
}

TEST_F(ValidationErrorTest, AlreadyDefinedInOtherFile) {
  BuildFile(
    "name: \"foo.proto\" "
    "message_type { name: \"Foo\" }");

  BuildFileWithErrors(
    "name: \"bar.proto\" "
    "message_type { name: \"Foo\" }",

    "bar.proto: Foo: NAME: \"Foo\" is already defined in file "
      "\"foo.proto\".\n");
}

TEST_F(ValidationErrorTest, PackageAlreadyDefined) {
  BuildFile(
    "name: \"foo.proto\" "
    "message_type { name: \"foo\" }");
  BuildFileWithErrors(
    "name: \"bar.proto\" "
    "package: \"foo.bar\"",

    "bar.proto: foo: NAME: \"foo\" is already defined (as something other "
      "than a package) in file \"foo.proto\".\n");
}

TEST_F(ValidationErrorTest, EnumValueAlreadyDefinedInParent) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "enum_type { name: \"Foo\" value { name: \"FOO\" number: 1 } } "
    "enum_type { name: \"Bar\" value { name: \"FOO\" number: 1 } } ",

    "foo.proto: FOO: NAME: \"FOO\" is already defined.\n"
    "foo.proto: FOO: NAME: Note that enum values use C++ scoping rules, "
      "meaning that enum values are siblings of their type, not children of "
      "it.  Therefore, \"FOO\" must be unique within the global scope, not "
      "just within \"Bar\".\n");
}

TEST_F(ValidationErrorTest, EnumValueAlreadyDefinedInParentNonGlobal) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "package: \"pkg\" "
    "enum_type { name: \"Foo\" value { name: \"FOO\" number: 1 } } "
    "enum_type { name: \"Bar\" value { name: \"FOO\" number: 1 } } ",

    "foo.proto: pkg.FOO: NAME: \"FOO\" is already defined in \"pkg\".\n"
    "foo.proto: pkg.FOO: NAME: Note that enum values use C++ scoping rules, "
      "meaning that enum values are siblings of their type, not children of "
      "it.  Therefore, \"FOO\" must be unique within \"pkg\", not just within "
      "\"Bar\".\n");
}

TEST_F(ValidationErrorTest, MissingName) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type { }",

    "foo.proto: : NAME: Missing name.\n");
}

TEST_F(ValidationErrorTest, InvalidName) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type { name: \"$\" }",

    "foo.proto: $: NAME: \"$\" is not a valid identifier.\n");
}

TEST_F(ValidationErrorTest, InvalidPackageName) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "package: \"foo.$\"",

    "foo.proto: foo.$: NAME: \"$\" is not a valid identifier.\n");
}

TEST_F(ValidationErrorTest, MissingFileName) {
  BuildFileWithErrors(
    "",

    ": : OTHER: Missing field: FileDescriptorProto.name.\n");
}

TEST_F(ValidationErrorTest, DupeDependency) {
  BuildFile("name: \"foo.proto\"");
  BuildFileWithErrors(
    "name: \"bar.proto\" "
    "dependency: \"foo.proto\" "
    "dependency: \"foo.proto\" ",

    "bar.proto: bar.proto: OTHER: Import \"foo.proto\" was listed twice.\n");
}

TEST_F(ValidationErrorTest, UnknownDependency) {
  BuildFileWithErrors(
    "name: \"bar.proto\" "
    "dependency: \"foo.proto\" ",

    "bar.proto: bar.proto: OTHER: Import \"foo.proto\" has not been loaded.\n");
}

TEST_F(ValidationErrorTest, InvalidPublicDependencyIndex) {
  BuildFile("name: \"foo.proto\"");
  BuildFileWithErrors(
    "name: \"bar.proto\" "
    "dependency: \"foo.proto\" "
    "public_dependency: 1",
    "bar.proto: bar.proto: OTHER: Invalid public dependency index.\n");
}

TEST_F(ValidationErrorTest, ForeignUnimportedPackageNoCrash) {
  // Used to crash:  If we depend on a non-existent file and then refer to a
  // package defined in a file that we didn't import, and that package is
  // nested within a parent package which this file is also in, and we don't
  // include that parent package in the name (i.e. we do a relative lookup)...
  // Yes, really.
  BuildFile(
    "name: 'foo.proto' "
    "package: 'outer.foo' ");
  BuildFileWithErrors(
    "name: 'bar.proto' "
    "dependency: 'baz.proto' "
    "package: 'outer.bar' "
    "message_type { "
    "  name: 'Bar' "
    "  field { name:'bar' number:1 label:LABEL_OPTIONAL type_name:'foo.Foo' }"
    "}",

    "bar.proto: bar.proto: OTHER: Import \"baz.proto\" has not been loaded.\n"
    "bar.proto: outer.bar.Bar.bar: TYPE: \"outer.foo\" seems to be defined in "
      "\"foo.proto\", which is not imported by \"bar.proto\".  To use it here, "
      "please add the necessary import.\n");
}

TEST_F(ValidationErrorTest, DupeFile) {
  BuildFile(
    "name: \"foo.proto\" "
    "message_type { name: \"Foo\" }");
  // Note:  We should *not* get redundant errors about "Foo" already being
  //   defined.
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type { name: \"Foo\" } "
    // Add another type so that the files aren't identical (in which case there
    // would be no error).
    "enum_type { name: \"Bar\" }",

    "foo.proto: foo.proto: OTHER: A file with this name is already in the "
      "pool.\n");
}

TEST_F(ValidationErrorTest, FieldInExtensionRange) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type {"
    "  name: \"Foo\""
    "  field { name: \"foo\" number:  9 label:LABEL_OPTIONAL type:TYPE_INT32 }"
    "  field { name: \"bar\" number: 10 label:LABEL_OPTIONAL type:TYPE_INT32 }"
    "  field { name: \"baz\" number: 19 label:LABEL_OPTIONAL type:TYPE_INT32 }"
    "  field { name: \"qux\" number: 20 label:LABEL_OPTIONAL type:TYPE_INT32 }"
    "  extension_range { start: 10 end: 20 }"
    "}",

    "foo.proto: Foo.bar: NUMBER: Extension range 10 to 19 includes field "
      "\"bar\" (10).\n"
    "foo.proto: Foo.baz: NUMBER: Extension range 10 to 19 includes field "
      "\"baz\" (19).\n");
}

TEST_F(ValidationErrorTest, OverlappingExtensionRanges) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type {"
    "  name: \"Foo\""
    "  extension_range { start: 10 end: 20 }"
    "  extension_range { start: 20 end: 30 }"
    "  extension_range { start: 19 end: 21 }"
    "}",

    "foo.proto: Foo: NUMBER: Extension range 19 to 20 overlaps with "
      "already-defined range 10 to 19.\n"
    "foo.proto: Foo: NUMBER: Extension range 19 to 20 overlaps with "
      "already-defined range 20 to 29.\n");
}

TEST_F(ValidationErrorTest, InvalidDefaults) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type {"
    "  name: \"Foo\""

    // Invalid number.
    "  field { name: \"foo\" number: 1 label: LABEL_OPTIONAL type: TYPE_INT32"
    "          default_value: \"abc\" }"

    // Empty default value.
    "  field { name: \"bar\" number: 2 label: LABEL_OPTIONAL type: TYPE_INT32"
    "          default_value: \"\" }"

    // Invalid boolean.
    "  field { name: \"baz\" number: 3 label: LABEL_OPTIONAL type: TYPE_BOOL"
    "          default_value: \"abc\" }"

    // Messages can't have defaults.
    "  field { name: \"qux\" number: 4 label: LABEL_OPTIONAL type: TYPE_MESSAGE"
    "          default_value: \"abc\" type_name: \"Foo\" }"

    // Same thing, but we don't know that this field has message type until
    // we look up the type name.
    "  field { name: \"quux\" number: 5 label: LABEL_OPTIONAL"
    "          default_value: \"abc\" type_name: \"Foo\" }"

    // Repeateds can't have defaults.
    "  field { name: \"corge\" number: 6 label: LABEL_REPEATED type: TYPE_INT32"
    "          default_value: \"1\" }"
    "}",

    "foo.proto: Foo.foo: DEFAULT_VALUE: Couldn't parse default value.\n"
    "foo.proto: Foo.bar: DEFAULT_VALUE: Couldn't parse default value.\n"
    "foo.proto: Foo.baz: DEFAULT_VALUE: Boolean default must be true or "
      "false.\n"
    "foo.proto: Foo.qux: DEFAULT_VALUE: Messages can't have default values.\n"
    "foo.proto: Foo.corge: DEFAULT_VALUE: Repeated fields can't have default "
      "values.\n"
    // This ends up being reported later because the error is detected at
    // cross-linking time.
    "foo.proto: Foo.quux: DEFAULT_VALUE: Messages can't have default "
      "values.\n");
}

TEST_F(ValidationErrorTest, NegativeFieldNumber) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type {"
    "  name: \"Foo\""
    "  field { name: \"foo\" number: -1 label:LABEL_OPTIONAL type:TYPE_INT32 }"
    "}",

    "foo.proto: Foo.foo: NUMBER: Field numbers must be positive integers.\n");
}

TEST_F(ValidationErrorTest, HugeFieldNumber) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type {"
    "  name: \"Foo\""
    "  field { name: \"foo\" number: 0x70000000 "
    "          label:LABEL_OPTIONAL type:TYPE_INT32 }"
    "}",

    "foo.proto: Foo.foo: NUMBER: Field numbers cannot be greater than "
      "536870911.\n");
}

TEST_F(ValidationErrorTest, ReservedFieldNumber) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type {"
    "  name: \"Foo\""
    "  field {name:\"foo\" number: 18999 label:LABEL_OPTIONAL type:TYPE_INT32 }"
    "  field {name:\"bar\" number: 19000 label:LABEL_OPTIONAL type:TYPE_INT32 }"
    "  field {name:\"baz\" number: 19999 label:LABEL_OPTIONAL type:TYPE_INT32 }"
    "  field {name:\"qux\" number: 20000 label:LABEL_OPTIONAL type:TYPE_INT32 }"
    "}",

    "foo.proto: Foo.bar: NUMBER: Field numbers 19000 through 19999 are "
      "reserved for the protocol buffer library implementation.\n"
    "foo.proto: Foo.baz: NUMBER: Field numbers 19000 through 19999 are "
      "reserved for the protocol buffer library implementation.\n");
}

TEST_F(ValidationErrorTest, ExtensionMissingExtendee) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type {"
    "  name: \"Foo\""
    "  extension { name: \"foo\" number: 1 label: LABEL_OPTIONAL"
    "              type_name: \"Foo\" }"
    "}",

    "foo.proto: Foo.foo: EXTENDEE: FieldDescriptorProto.extendee not set for "
      "extension field.\n");
}

TEST_F(ValidationErrorTest, NonExtensionWithExtendee) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type {"
    "  name: \"Bar\""
    "  extension_range { start: 1 end: 2 }"
    "}"
    "message_type {"
    "  name: \"Foo\""
    "  field { name: \"foo\" number: 1 label: LABEL_OPTIONAL"
    "          type_name: \"Foo\" extendee: \"Bar\" }"
    "}",

    "foo.proto: Foo.foo: EXTENDEE: FieldDescriptorProto.extendee set for "
      "non-extension field.\n");
}

TEST_F(ValidationErrorTest, FieldNumberConflict) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type {"
    "  name: \"Foo\""
    "  field { name: \"foo\" number: 1 label:LABEL_OPTIONAL type:TYPE_INT32 }"
    "  field { name: \"bar\" number: 1 label:LABEL_OPTIONAL type:TYPE_INT32 }"
    "}",

    "foo.proto: Foo.bar: NUMBER: Field number 1 has already been used in "
      "\"Foo\" by field \"foo\".\n");
}

TEST_F(ValidationErrorTest, BadMessageSetExtensionType) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type {"
    "  name: \"MessageSet\""
    "  options { message_set_wire_format: true }"
    "  extension_range { start: 4 end: 5 }"
    "}"
    "message_type {"
    "  name: \"Foo\""
    "  extension { name:\"foo\" number:4 label:LABEL_OPTIONAL type:TYPE_INT32"
    "              extendee: \"MessageSet\" }"
    "}",

    "foo.proto: Foo.foo: TYPE: Extensions of MessageSets must be optional "
      "messages.\n");
}

TEST_F(ValidationErrorTest, BadMessageSetExtensionLabel) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type {"
    "  name: \"MessageSet\""
    "  options { message_set_wire_format: true }"
    "  extension_range { start: 4 end: 5 }"
    "}"
    "message_type {"
    "  name: \"Foo\""
    "  extension { name:\"foo\" number:4 label:LABEL_REPEATED type:TYPE_MESSAGE"
    "              type_name: \"Foo\" extendee: \"MessageSet\" }"
    "}",

    "foo.proto: Foo.foo: TYPE: Extensions of MessageSets must be optional "
      "messages.\n");
}

TEST_F(ValidationErrorTest, FieldInMessageSet) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type {"
    "  name: \"Foo\""
    "  options { message_set_wire_format: true }"
    "  field { name: \"foo\" number: 1 label:LABEL_OPTIONAL type:TYPE_INT32 }"
    "}",

    "foo.proto: Foo.foo: NAME: MessageSets cannot have fields, only "
      "extensions.\n");
}

TEST_F(ValidationErrorTest, NegativeExtensionRangeNumber) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type {"
    "  name: \"Foo\""
    "  extension_range { start: -10 end: -1 }"
    "}",

    "foo.proto: Foo: NUMBER: Extension numbers must be positive integers.\n");
}

TEST_F(ValidationErrorTest, HugeExtensionRangeNumber) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type {"
    "  name: \"Foo\""
    "  extension_range { start: 1 end: 0x70000000 }"
    "}",

    "foo.proto: Foo: NUMBER: Extension numbers cannot be greater than "
      "536870911.\n");
}

TEST_F(ValidationErrorTest, ExtensionRangeEndBeforeStart) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type {"
    "  name: \"Foo\""
    "  extension_range { start: 10 end: 10 }"
    "  extension_range { start: 10 end: 5 }"
    "}",

    "foo.proto: Foo: NUMBER: Extension range end number must be greater than "
      "start number.\n"
    "foo.proto: Foo: NUMBER: Extension range end number must be greater than "
      "start number.\n");
}

TEST_F(ValidationErrorTest, EmptyEnum) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "enum_type { name: \"Foo\" }"
    // Also use the empty enum in a message to make sure there are no crashes
    // during validation (possible if the code attempts to derive a default
    // value for the field).
    "message_type {"
    "  name: \"Bar\""
    "  field { name: \"foo\" number: 1 label:LABEL_OPTIONAL type_name:\"Foo\" }"
    "  field { name: \"bar\" number: 2 label:LABEL_OPTIONAL type_name:\"Foo\" "
    "          default_value: \"NO_SUCH_VALUE\" }"
    "}",

    "foo.proto: Foo: NAME: Enums must contain at least one value.\n"
    "foo.proto: Bar.bar: DEFAULT_VALUE: Enum type \"Foo\" has no value named "
      "\"NO_SUCH_VALUE\".\n");
}

TEST_F(ValidationErrorTest, UndefinedExtendee) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type {"
    "  name: \"Foo\""
    "  extension { name:\"foo\" number:1 label:LABEL_OPTIONAL type:TYPE_INT32"
    "              extendee: \"Bar\" }"
    "}",

    "foo.proto: Foo.foo: EXTENDEE: \"Bar\" is not defined.\n");
}

TEST_F(ValidationErrorTest, NonMessageExtendee) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "enum_type { name: \"Bar\" value { name:\"DUMMY\" number:0 } }"
    "message_type {"
    "  name: \"Foo\""
    "  extension { name:\"foo\" number:1 label:LABEL_OPTIONAL type:TYPE_INT32"
    "              extendee: \"Bar\" }"
    "}",

    "foo.proto: Foo.foo: EXTENDEE: \"Bar\" is not a message type.\n");
}

TEST_F(ValidationErrorTest, NotAnExtensionNumber) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type {"
    "  name: \"Bar\""
    "}"
    "message_type {"
    "  name: \"Foo\""
    "  extension { name:\"foo\" number:1 label:LABEL_OPTIONAL type:TYPE_INT32"
    "              extendee: \"Bar\" }"
    "}",

    "foo.proto: Foo.foo: NUMBER: \"Bar\" does not declare 1 as an extension "
      "number.\n");
}

TEST_F(ValidationErrorTest, UndefinedFieldType) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type {"
    "  name: \"Foo\""
    "  field { name:\"foo\" number:1 label:LABEL_OPTIONAL type_name:\"Bar\" }"
    "}",

    "foo.proto: Foo.foo: TYPE: \"Bar\" is not defined.\n");
}

TEST_F(ValidationErrorTest, FieldTypeDefinedInUndeclaredDependency) {
  BuildFile(
    "name: \"bar.proto\" "
    "message_type { name: \"Bar\" } ");

  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type {"
    "  name: \"Foo\""
    "  field { name:\"foo\" number:1 label:LABEL_OPTIONAL type_name:\"Bar\" }"
    "}",
    "foo.proto: Foo.foo: TYPE: \"Bar\" seems to be defined in \"bar.proto\", "
      "which is not imported by \"foo.proto\".  To use it here, please add the "
      "necessary import.\n");
}

TEST_F(ValidationErrorTest, FieldTypeDefinedInIndirectDependency) {
  // Test for hidden dependencies.
  //
  // // bar.proto
  // message Bar{}
  //
  // // forward.proto
  // import "bar.proto"
  //
  // // foo.proto
  // import "forward.proto"
  // message Foo {
  //   optional Bar foo = 1;  // Error, needs to import bar.proto explicitly.
  // }
  //
  BuildFile(
    "name: \"bar.proto\" "
    "message_type { name: \"Bar\" }");

  BuildFile(
    "name: \"forward.proto\""
    "dependency: \"bar.proto\"");

  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "dependency: \"forward.proto\" "
    "message_type {"
    "  name: \"Foo\""
    "  field { name:\"foo\" number:1 label:LABEL_OPTIONAL type_name:\"Bar\" }"
    "}",
    "foo.proto: Foo.foo: TYPE: \"Bar\" seems to be defined in \"bar.proto\", "
      "which is not imported by \"foo.proto\".  To use it here, please add the "
      "necessary import.\n");
}

TEST_F(ValidationErrorTest, FieldTypeDefinedInPublicDependency) {
  // Test for public dependencies.
  //
  // // bar.proto
  // message Bar{}
  //
  // // forward.proto
  // import public "bar.proto"
  //
  // // foo.proto
  // import "forward.proto"
  // message Foo {
  //   optional Bar foo = 1;  // Correct. "bar.proto" is public imported into
  //                          // forward.proto, so when "foo.proto" imports
  //                          // "forward.proto", it imports "bar.proto" too.
  // }
  //
  BuildFile(
    "name: \"bar.proto\" "
    "message_type { name: \"Bar\" }");

  BuildFile(
    "name: \"forward.proto\""
    "dependency: \"bar.proto\" "
    "public_dependency: 0");

  BuildFile(
    "name: \"foo.proto\" "
    "dependency: \"forward.proto\" "
    "message_type {"
    "  name: \"Foo\""
    "  field { name:\"foo\" number:1 label:LABEL_OPTIONAL type_name:\"Bar\" }"
    "}");
}

TEST_F(ValidationErrorTest, FieldTypeDefinedInTransitivePublicDependency) {
  // Test for public dependencies.
  //
  // // bar.proto
  // message Bar{}
  //
  // // forward.proto
  // import public "bar.proto"
  //
  // // forward2.proto
  // import public "forward.proto"
  //
  // // foo.proto
  // import "forward2.proto"
  // message Foo {
  //   optional Bar foo = 1;  // Correct, public imports are transitive.
  // }
  //
  BuildFile(
    "name: \"bar.proto\" "
    "message_type { name: \"Bar\" }");

  BuildFile(
    "name: \"forward.proto\""
    "dependency: \"bar.proto\" "
    "public_dependency: 0");

  BuildFile(
    "name: \"forward2.proto\""
    "dependency: \"forward.proto\" "
    "public_dependency: 0");

  BuildFile(
    "name: \"foo.proto\" "
    "dependency: \"forward2.proto\" "
    "message_type {"
    "  name: \"Foo\""
    "  field { name:\"foo\" number:1 label:LABEL_OPTIONAL type_name:\"Bar\" }"
    "}");
}

TEST_F(ValidationErrorTest,
       FieldTypeDefinedInPrivateDependencyOfPublicDependency) {
  // Test for public dependencies.
  //
  // // bar.proto
  // message Bar{}
  //
  // // forward.proto
  // import "bar.proto"
  //
  // // forward2.proto
  // import public "forward.proto"
  //
  // // foo.proto
  // import "forward2.proto"
  // message Foo {
  //   optional Bar foo = 1;  // Error, the "bar.proto" is not public imported
  //                          // into "forward.proto", so will not be imported
  //                          // into either "forward2.proto" or "foo.proto".
  // }
  //
  BuildFile(
    "name: \"bar.proto\" "
    "message_type { name: \"Bar\" }");

  BuildFile(
    "name: \"forward.proto\""
    "dependency: \"bar.proto\"");

  BuildFile(
    "name: \"forward2.proto\""
    "dependency: \"forward.proto\" "
    "public_dependency: 0");

  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "dependency: \"forward2.proto\" "
    "message_type {"
    "  name: \"Foo\""
    "  field { name:\"foo\" number:1 label:LABEL_OPTIONAL type_name:\"Bar\" }"
    "}",
    "foo.proto: Foo.foo: TYPE: \"Bar\" seems to be defined in \"bar.proto\", "
      "which is not imported by \"foo.proto\".  To use it here, please add the "
      "necessary import.\n");
}


TEST_F(ValidationErrorTest, SearchMostLocalFirst) {
  // The following should produce an error that Bar.Baz is not defined:
  //   message Bar { message Baz {} }
  //   message Foo {
  //     message Bar {
  //       // Placing "message Baz{}" here, or removing Foo.Bar altogether,
  //       // would fix the error.
  //     }
  //     optional Bar.Baz baz = 1;
  //   }
  // An one point the lookup code incorrectly did not produce an error in this
  // case, because when looking for Bar.Baz, it would try "Foo.Bar.Baz" first,
  // fail, and ten try "Bar.Baz" and succeed, even though "Bar" should actually
  // refer to the inner Bar, not the outer one.
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type {"
    "  name: \"Bar\""
    "  nested_type { name: \"Baz\" }"
    "}"
    "message_type {"
    "  name: \"Foo\""
    "  nested_type { name: \"Bar\" }"
    "  field { name:\"baz\" number:1 label:LABEL_OPTIONAL"
    "          type_name:\"Bar.Baz\" }"
    "}",

    "foo.proto: Foo.baz: TYPE: \"Bar.Baz\" is not defined.\n");
}

TEST_F(ValidationErrorTest, SearchMostLocalFirst2) {
  // This test would find the most local "Bar" first, and does, but
  // proceeds to find the outer one because the inner one's not an
  // aggregate.
  BuildFile(
    "name: \"foo.proto\" "
    "message_type {"
    "  name: \"Bar\""
    "  nested_type { name: \"Baz\" }"
    "}"
    "message_type {"
    "  name: \"Foo\""
    "  field { name: \"Bar\" number:1 type:TYPE_BYTES } "
    "  field { name:\"baz\" number:2 label:LABEL_OPTIONAL"
    "          type_name:\"Bar.Baz\" }"
    "}");
}

TEST_F(ValidationErrorTest, PackageOriginallyDeclaredInTransitiveDependent) {
  // Imagine we have the following:
  //
  // foo.proto:
  //   package foo.bar;
  // bar.proto:
  //   package foo.bar;
  //   import "foo.proto";
  //   message Bar {}
  // baz.proto:
  //   package foo;
  //   import "bar.proto"
  //   message Baz { optional bar.Bar qux = 1; }
  //
  // When validating baz.proto, we will look up "bar.Bar".  As part of this
  // lookup, we first lookup "bar" then try to find "Bar" within it.  "bar"
  // should resolve to "foo.bar".  Note, though, that "foo.bar" was originally
  // defined in foo.proto, which is not a direct dependency of baz.proto.  The
  // implementation of FindSymbol() normally only returns symbols in direct
  // dependencies, not indirect ones.  This test insures that this does not
  // prevent it from finding "foo.bar".

  BuildFile(
    "name: \"foo.proto\" "
    "package: \"foo.bar\" ");
  BuildFile(
    "name: \"bar.proto\" "
    "package: \"foo.bar\" "
    "dependency: \"foo.proto\" "
    "message_type { name: \"Bar\" }");
  BuildFile(
    "name: \"baz.proto\" "
    "package: \"foo\" "
    "dependency: \"bar.proto\" "
    "message_type { "
    "  name: \"Baz\" "
    "  field { name:\"qux\" number:1 label:LABEL_OPTIONAL "
    "          type_name:\"bar.Bar\" }"
    "}");
}

TEST_F(ValidationErrorTest, FieldTypeNotAType) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type {"
    "  name: \"Foo\""
    "  field { name:\"foo\" number:1 label:LABEL_OPTIONAL "
    "          type_name:\".Foo.bar\" }"
    "  field { name:\"bar\" number:2 label:LABEL_OPTIONAL type:TYPE_INT32 }"
    "}",

    "foo.proto: Foo.foo: TYPE: \".Foo.bar\" is not a type.\n");
}

TEST_F(ValidationErrorTest, RelativeFieldTypeNotAType) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type {"
    "  nested_type {"
    "    name: \"Bar\""
    "    field { name:\"Baz\" number:2 label:LABEL_OPTIONAL type:TYPE_INT32 }"
    "  }"
    "  name: \"Foo\""
    "  field { name:\"foo\" number:1 label:LABEL_OPTIONAL "
    "          type_name:\"Bar.Baz\" }"
    "}",
    "foo.proto: Foo.foo: TYPE: \"Bar.Baz\" is not a type.\n");
}

TEST_F(ValidationErrorTest, FieldTypeMayBeItsName) {
  BuildFile(
    "name: \"foo.proto\" "
    "message_type {"
    "  name: \"Bar\""
    "}"
    "message_type {"
    "  name: \"Foo\""
    "  field { name:\"Bar\" number:1 label:LABEL_OPTIONAL type_name:\"Bar\" }"
    "}");
}

TEST_F(ValidationErrorTest, EnumFieldTypeIsMessage) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type { name: \"Bar\" } "
    "message_type {"
    "  name: \"Foo\""
    "  field { name:\"foo\" number:1 label:LABEL_OPTIONAL type:TYPE_ENUM"
    "          type_name:\"Bar\" }"
    "}",

    "foo.proto: Foo.foo: TYPE: \"Bar\" is not an enum type.\n");
}

TEST_F(ValidationErrorTest, MessageFieldTypeIsEnum) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "enum_type { name: \"Bar\" value { name:\"DUMMY\" number:0 } } "
    "message_type {"
    "  name: \"Foo\""
    "  field { name:\"foo\" number:1 label:LABEL_OPTIONAL type:TYPE_MESSAGE"
    "          type_name:\"Bar\" }"
    "}",

    "foo.proto: Foo.foo: TYPE: \"Bar\" is not a message type.\n");
}

TEST_F(ValidationErrorTest, BadEnumDefaultValue) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "enum_type { name: \"Bar\" value { name:\"DUMMY\" number:0 } } "
    "message_type {"
    "  name: \"Foo\""
    "  field { name:\"foo\" number:1 label:LABEL_OPTIONAL type_name:\"Bar\""
    "          default_value:\"NO_SUCH_VALUE\" }"
    "}",

    "foo.proto: Foo.foo: DEFAULT_VALUE: Enum type \"Bar\" has no value named "
      "\"NO_SUCH_VALUE\".\n");
}

TEST_F(ValidationErrorTest, PrimitiveWithTypeName) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type {"
    "  name: \"Foo\""
    "  field { name:\"foo\" number:1 label:LABEL_OPTIONAL type:TYPE_INT32"
    "          type_name:\"Foo\" }"
    "}",

    "foo.proto: Foo.foo: TYPE: Field with primitive type has type_name.\n");
}

TEST_F(ValidationErrorTest, NonPrimitiveWithoutTypeName) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type {"
    "  name: \"Foo\""
    "  field { name:\"foo\" number:1 label:LABEL_OPTIONAL type:TYPE_MESSAGE }"
    "}",

    "foo.proto: Foo.foo: TYPE: Field with message or enum type missing "
      "type_name.\n");
}

TEST_F(ValidationErrorTest, InputTypeNotDefined) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type { name: \"Foo\" } "
    "service {"
    "  name: \"TestService\""
    "  method { name: \"A\" input_type: \"Bar\" output_type: \"Foo\" }"
    "}",

    "foo.proto: TestService.A: INPUT_TYPE: \"Bar\" is not defined.\n"
    );
}

TEST_F(ValidationErrorTest, InputTypeNotAMessage) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type { name: \"Foo\" } "
    "enum_type { name: \"Bar\" value { name:\"DUMMY\" number:0 } } "
    "service {"
    "  name: \"TestService\""
    "  method { name: \"A\" input_type: \"Bar\" output_type: \"Foo\" }"
    "}",

    "foo.proto: TestService.A: INPUT_TYPE: \"Bar\" is not a message type.\n"
    );
}

TEST_F(ValidationErrorTest, OutputTypeNotDefined) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type { name: \"Foo\" } "
    "service {"
    "  name: \"TestService\""
    "  method { name: \"A\" input_type: \"Foo\" output_type: \"Bar\" }"
    "}",

    "foo.proto: TestService.A: OUTPUT_TYPE: \"Bar\" is not defined.\n"
    );
}

TEST_F(ValidationErrorTest, OutputTypeNotAMessage) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type { name: \"Foo\" } "
    "enum_type { name: \"Bar\" value { name:\"DUMMY\" number:0 } } "
    "service {"
    "  name: \"TestService\""
    "  method { name: \"A\" input_type: \"Foo\" output_type: \"Bar\" }"
    "}",

    "foo.proto: TestService.A: OUTPUT_TYPE: \"Bar\" is not a message type.\n"
    );
}


TEST_F(ValidationErrorTest, IllegalPackedField) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type {\n"
    "  name: \"Foo\""
    "  field { name:\"packed_string\" number:1 label:LABEL_REPEATED "
    "          type:TYPE_STRING "
    "          options { uninterpreted_option {"
    "            name { name_part: \"packed\" is_extension: false }"
    "            identifier_value: \"true\" }}}\n"
    "  field { name:\"packed_message\" number:3 label:LABEL_REPEATED "
    "          type_name: \"Foo\""
    "          options { uninterpreted_option {"
    "            name { name_part: \"packed\" is_extension: false }"
    "            identifier_value: \"true\" }}}\n"
    "  field { name:\"optional_int32\" number: 4 label: LABEL_OPTIONAL "
    "          type:TYPE_INT32 "
    "          options { uninterpreted_option {"
    "            name { name_part: \"packed\" is_extension: false }"
    "            identifier_value: \"true\" }}}\n"
    "}",

    "foo.proto: Foo.packed_string: TYPE: [packed = true] can only be "
        "specified for repeated primitive fields.\n"
    "foo.proto: Foo.packed_message: TYPE: [packed = true] can only be "
        "specified for repeated primitive fields.\n"
    "foo.proto: Foo.optional_int32: TYPE: [packed = true] can only be "
        "specified for repeated primitive fields.\n"
        );
}

TEST_F(ValidationErrorTest, OptionWrongType) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type { "
    "  name: \"TestMessage\" "
    "  field { name:\"foo\" number:1 label:LABEL_OPTIONAL type:TYPE_STRING "
    "          options { uninterpreted_option { name { name_part: \"ctype\" "
    "                                                  is_extension: false }"
    "                                           positive_int_value: 1 }"
    "          }"
    "  }"
    "}\n",

    "foo.proto: TestMessage.foo: OPTION_VALUE: Value must be identifier for "
    "enum-valued option \"google.protobuf.FieldOptions.ctype\".\n");
}

TEST_F(ValidationErrorTest, OptionExtendsAtomicType) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type { "
    "  name: \"TestMessage\" "
    "  field { name:\"foo\" number:1 label:LABEL_OPTIONAL type:TYPE_STRING "
    "          options { uninterpreted_option { name { name_part: \"ctype\" "
    "                                                  is_extension: false }"
    "                                           name { name_part: \"foo\" "
    "                                                  is_extension: true }"
    "                                           positive_int_value: 1 }"
    "          }"
    "  }"
    "}\n",

    "foo.proto: TestMessage.foo: OPTION_NAME: Option \"ctype\" is an "
    "atomic type, not a message.\n");
}

TEST_F(ValidationErrorTest, DupOption) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type { "
    "  name: \"TestMessage\" "
    "  field { name:\"foo\" number:1 label:LABEL_OPTIONAL type:TYPE_UINT32 "
    "          options { uninterpreted_option { name { name_part: \"ctype\" "
    "                                                  is_extension: false }"
    "                                           identifier_value: \"CORD\" }"
    "                    uninterpreted_option { name { name_part: \"ctype\" "
    "                                                  is_extension: false }"
    "                                           identifier_value: \"CORD\" }"
    "          }"
    "  }"
    "}\n",

    "foo.proto: TestMessage.foo: OPTION_NAME: Option \"ctype\" was "
    "already set.\n");
}

TEST_F(ValidationErrorTest, InvalidOptionName) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type { "
    "  name: \"TestMessage\" "
    "  field { name:\"foo\" number:1 label:LABEL_OPTIONAL type:TYPE_BOOL "
    "          options { uninterpreted_option { "
    "                      name { name_part: \"uninterpreted_option\" "
    "                             is_extension: false }"
    "                      positive_int_value: 1 "
    "                    }"
    "          }"
    "  }"
    "}\n",

    "foo.proto: TestMessage.foo: OPTION_NAME: Option must not use "
    "reserved name \"uninterpreted_option\".\n");
}

TEST_F(ValidationErrorTest, RepeatedOption) {
  BuildDescriptorMessagesInTestPool();

  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "dependency: \"google/protobuf/descriptor.proto\" "
    "extension { name: \"foo\" number: 7672757 label: LABEL_REPEATED "
    "            type: TYPE_FLOAT extendee: \"google.protobuf.FileOptions\" }"
    "options { uninterpreted_option { name { name_part: \"foo\" "
    "                                        is_extension: true } "
    "                                 double_value: 1.2 } }",

    "foo.proto: foo.proto: OPTION_NAME: Option field \"(foo)\" is repeated. "
    "Repeated options are not supported.\n");
}

TEST_F(ValidationErrorTest, CustomOptionConflictingFieldNumber) {
  BuildDescriptorMessagesInTestPool();

  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "dependency: \"google/protobuf/descriptor.proto\" "
    "extension { name: \"foo1\" number: 7672757 label: LABEL_OPTIONAL "
    "            type: TYPE_INT32 extendee: \"google.protobuf.FieldOptions\" }"
    "extension { name: \"foo2\" number: 7672757 label: LABEL_OPTIONAL "
    "            type: TYPE_INT32 extendee: \"google.protobuf.FieldOptions\" }",

    "foo.proto: foo2: NUMBER: Extension number 7672757 has already been used "
    "in \"google.protobuf.FieldOptions\" by extension \"foo1\".\n");
}

TEST_F(ValidationErrorTest, Int32OptionValueOutOfPositiveRange) {
  BuildDescriptorMessagesInTestPool();

  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "dependency: \"google/protobuf/descriptor.proto\" "
    "extension { name: \"foo\" number: 7672757 label: LABEL_OPTIONAL "
    "            type: TYPE_INT32 extendee: \"google.protobuf.FileOptions\" }"
    "options { uninterpreted_option { name { name_part: \"foo\" "
    "                                        is_extension: true } "
    "                                 positive_int_value: 0x80000000 } "
    "}",

    "foo.proto: foo.proto: OPTION_VALUE: Value out of range "
    "for int32 option \"foo\".\n");
}

TEST_F(ValidationErrorTest, Int32OptionValueOutOfNegativeRange) {
  BuildDescriptorMessagesInTestPool();

  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "dependency: \"google/protobuf/descriptor.proto\" "
    "extension { name: \"foo\" number: 7672757 label: LABEL_OPTIONAL "
    "            type: TYPE_INT32 extendee: \"google.protobuf.FileOptions\" }"
    "options { uninterpreted_option { name { name_part: \"foo\" "
    "                                        is_extension: true } "
    "                                 negative_int_value: -0x80000001 } "
    "}",

    "foo.proto: foo.proto: OPTION_VALUE: Value out of range "
    "for int32 option \"foo\".\n");
}

TEST_F(ValidationErrorTest, Int32OptionValueIsNotPositiveInt) {
  BuildDescriptorMessagesInTestPool();

  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "dependency: \"google/protobuf/descriptor.proto\" "
    "extension { name: \"foo\" number: 7672757 label: LABEL_OPTIONAL "
    "            type: TYPE_INT32 extendee: \"google.protobuf.FileOptions\" }"
    "options { uninterpreted_option { name { name_part: \"foo\" "
    "                                        is_extension: true } "
    "                                 string_value: \"5\" } }",

    "foo.proto: foo.proto: OPTION_VALUE: Value must be integer "
    "for int32 option \"foo\".\n");
}

TEST_F(ValidationErrorTest, Int64OptionValueOutOfRange) {
  BuildDescriptorMessagesInTestPool();

  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "dependency: \"google/protobuf/descriptor.proto\" "
    "extension { name: \"foo\" number: 7672757 label: LABEL_OPTIONAL "
    "            type: TYPE_INT64 extendee: \"google.protobuf.FileOptions\" }"
    "options { uninterpreted_option { name { name_part: \"foo\" "
    "                                        is_extension: true } "
    "                                 positive_int_value: 0x8000000000000000 } "
    "}",

    "foo.proto: foo.proto: OPTION_VALUE: Value out of range "
    "for int64 option \"foo\".\n");
}

TEST_F(ValidationErrorTest, Int64OptionValueIsNotPositiveInt) {
  BuildDescriptorMessagesInTestPool();

  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "dependency: \"google/protobuf/descriptor.proto\" "
    "extension { name: \"foo\" number: 7672757 label: LABEL_OPTIONAL "
    "            type: TYPE_INT64 extendee: \"google.protobuf.FileOptions\" }"
    "options { uninterpreted_option { name { name_part: \"foo\" "
    "                                        is_extension: true } "
    "                                 identifier_value: \"5\" } }",

    "foo.proto: foo.proto: OPTION_VALUE: Value must be integer "
    "for int64 option \"foo\".\n");
}

TEST_F(ValidationErrorTest, UInt32OptionValueOutOfRange) {
  BuildDescriptorMessagesInTestPool();

  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "dependency: \"google/protobuf/descriptor.proto\" "
    "extension { name: \"foo\" number: 7672757 label: LABEL_OPTIONAL "
    "            type: TYPE_UINT32 extendee: \"google.protobuf.FileOptions\" }"
    "options { uninterpreted_option { name { name_part: \"foo\" "
    "                                        is_extension: true } "
    "                                 positive_int_value: 0x100000000 } }",

    "foo.proto: foo.proto: OPTION_VALUE: Value out of range "
    "for uint32 option \"foo\".\n");
}

TEST_F(ValidationErrorTest, UInt32OptionValueIsNotPositiveInt) {
  BuildDescriptorMessagesInTestPool();

  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "dependency: \"google/protobuf/descriptor.proto\" "
    "extension { name: \"foo\" number: 7672757 label: LABEL_OPTIONAL "
    "            type: TYPE_UINT32 extendee: \"google.protobuf.FileOptions\" }"
    "options { uninterpreted_option { name { name_part: \"foo\" "
    "                                        is_extension: true } "
    "                                 double_value: -5.6 } }",

    "foo.proto: foo.proto: OPTION_VALUE: Value must be non-negative integer "
    "for uint32 option \"foo\".\n");
}

TEST_F(ValidationErrorTest, UInt64OptionValueIsNotPositiveInt) {
  BuildDescriptorMessagesInTestPool();

  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "dependency: \"google/protobuf/descriptor.proto\" "
    "extension { name: \"foo\" number: 7672757 label: LABEL_OPTIONAL "
    "            type: TYPE_UINT64 extendee: \"google.protobuf.FileOptions\" }"
    "options { uninterpreted_option { name { name_part: \"foo\" "
    "                                        is_extension: true } "
    "                                 negative_int_value: -5 } }",

    "foo.proto: foo.proto: OPTION_VALUE: Value must be non-negative integer "
    "for uint64 option \"foo\".\n");
}

TEST_F(ValidationErrorTest, FloatOptionValueIsNotNumber) {
  BuildDescriptorMessagesInTestPool();

  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "dependency: \"google/protobuf/descriptor.proto\" "
    "extension { name: \"foo\" number: 7672757 label: LABEL_OPTIONAL "
    "            type: TYPE_FLOAT extendee: \"google.protobuf.FileOptions\" }"
    "options { uninterpreted_option { name { name_part: \"foo\" "
    "                                        is_extension: true } "
    "                                 string_value: \"bar\" } }",

    "foo.proto: foo.proto: OPTION_VALUE: Value must be number "
    "for float option \"foo\".\n");
}

TEST_F(ValidationErrorTest, DoubleOptionValueIsNotNumber) {
  BuildDescriptorMessagesInTestPool();

  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "dependency: \"google/protobuf/descriptor.proto\" "
    "extension { name: \"foo\" number: 7672757 label: LABEL_OPTIONAL "
    "            type: TYPE_DOUBLE extendee: \"google.protobuf.FileOptions\" }"
    "options { uninterpreted_option { name { name_part: \"foo\" "
    "                                        is_extension: true } "
    "                                 string_value: \"bar\" } }",

    "foo.proto: foo.proto: OPTION_VALUE: Value must be number "
    "for double option \"foo\".\n");
}

TEST_F(ValidationErrorTest, BoolOptionValueIsNotTrueOrFalse) {
  BuildDescriptorMessagesInTestPool();

  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "dependency: \"google/protobuf/descriptor.proto\" "
    "extension { name: \"foo\" number: 7672757 label: LABEL_OPTIONAL "
    "            type: TYPE_BOOL extendee: \"google.protobuf.FileOptions\" }"
    "options { uninterpreted_option { name { name_part: \"foo\" "
    "                                        is_extension: true } "
    "                                 identifier_value: \"bar\" } }",

    "foo.proto: foo.proto: OPTION_VALUE: Value must be \"true\" or \"false\" "
    "for boolean option \"foo\".\n");
}

TEST_F(ValidationErrorTest, EnumOptionValueIsNotIdentifier) {
  BuildDescriptorMessagesInTestPool();

  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "dependency: \"google/protobuf/descriptor.proto\" "
    "enum_type { name: \"FooEnum\" value { name: \"BAR\" number: 1 } "
    "                              value { name: \"BAZ\" number: 2 } }"
    "extension { name: \"foo\" number: 7672757 label: LABEL_OPTIONAL "
    "            type: TYPE_ENUM type_name: \"FooEnum\" "
    "            extendee: \"google.protobuf.FileOptions\" }"
    "options { uninterpreted_option { name { name_part: \"foo\" "
    "                                        is_extension: true } "
    "                                 string_value: \"QUUX\" } }",

    "foo.proto: foo.proto: OPTION_VALUE: Value must be identifier for "
    "enum-valued option \"foo\".\n");
}

TEST_F(ValidationErrorTest, EnumOptionValueIsNotEnumValueName) {
  BuildDescriptorMessagesInTestPool();

  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "dependency: \"google/protobuf/descriptor.proto\" "
    "enum_type { name: \"FooEnum\" value { name: \"BAR\" number: 1 } "
    "                              value { name: \"BAZ\" number: 2 } }"
    "extension { name: \"foo\" number: 7672757 label: LABEL_OPTIONAL "
    "            type: TYPE_ENUM type_name: \"FooEnum\" "
    "            extendee: \"google.protobuf.FileOptions\" }"
    "options { uninterpreted_option { name { name_part: \"foo\" "
    "                                        is_extension: true } "
    "                                 identifier_value: \"QUUX\" } }",

    "foo.proto: foo.proto: OPTION_VALUE: Enum type \"FooEnum\" has no value "
    "named \"QUUX\" for option \"foo\".\n");
}

TEST_F(ValidationErrorTest, EnumOptionValueIsSiblingEnumValueName) {
  BuildDescriptorMessagesInTestPool();

  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "dependency: \"google/protobuf/descriptor.proto\" "
    "enum_type { name: \"FooEnum1\" value { name: \"BAR\" number: 1 } "
    "                               value { name: \"BAZ\" number: 2 } }"
    "enum_type { name: \"FooEnum2\" value { name: \"QUX\" number: 1 } "
    "                               value { name: \"QUUX\" number: 2 } }"
    "extension { name: \"foo\" number: 7672757 label: LABEL_OPTIONAL "
    "            type: TYPE_ENUM type_name: \"FooEnum1\" "
    "            extendee: \"google.protobuf.FileOptions\" }"
    "options { uninterpreted_option { name { name_part: \"foo\" "
    "                                        is_extension: true } "
    "                                 identifier_value: \"QUUX\" } }",

    "foo.proto: foo.proto: OPTION_VALUE: Enum type \"FooEnum1\" has no value "
    "named \"QUUX\" for option \"foo\". This appears to be a value from a "
    "sibling type.\n");
}

TEST_F(ValidationErrorTest, StringOptionValueIsNotString) {
  BuildDescriptorMessagesInTestPool();

  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "dependency: \"google/protobuf/descriptor.proto\" "
    "extension { name: \"foo\" number: 7672757 label: LABEL_OPTIONAL "
    "            type: TYPE_STRING extendee: \"google.protobuf.FileOptions\" }"
    "options { uninterpreted_option { name { name_part: \"foo\" "
    "                                        is_extension: true } "
    "                                 identifier_value: \"QUUX\" } }",

    "foo.proto: foo.proto: OPTION_VALUE: Value must be quoted string for "
    "string option \"foo\".\n");
}

// Helper function for tests that check for aggregate value parsing
// errors.  The "value" argument is embedded inside the
// "uninterpreted_option" portion of the result.
static string EmbedAggregateValue(const char* value) {
  return strings::Substitute(
      "name: \"foo.proto\" "
      "dependency: \"google/protobuf/descriptor.proto\" "
      "message_type { name: \"Foo\" } "
      "extension { name: \"foo\" number: 7672757 label: LABEL_OPTIONAL "
      "            type: TYPE_MESSAGE type_name: \"Foo\" "
      "            extendee: \"google.protobuf.FileOptions\" }"
      "options { uninterpreted_option { name { name_part: \"foo\" "
      "                                        is_extension: true } "
      "                                 $0 } }",
      value);
}

TEST_F(ValidationErrorTest, AggregateValueNotFound) {
  BuildDescriptorMessagesInTestPool();

  BuildFileWithErrors(
      EmbedAggregateValue("string_value: \"\""),
      "foo.proto: foo.proto: OPTION_VALUE: Option \"foo\" is a message. "
      "To set the entire message, use syntax like "
      "\"foo = { <proto text format> }\". To set fields within it, use "
      "syntax like \"foo.foo = value\".\n");
}

TEST_F(ValidationErrorTest, AggregateValueParseError) {
  BuildDescriptorMessagesInTestPool();

  BuildFileWithErrors(
      EmbedAggregateValue("aggregate_value: \"1+2\""),
      "foo.proto: foo.proto: OPTION_VALUE: Error while parsing option "
      "value for \"foo\": Expected identifier.\n");
}

TEST_F(ValidationErrorTest, AggregateValueUnknownFields) {
  BuildDescriptorMessagesInTestPool();

  BuildFileWithErrors(
      EmbedAggregateValue("aggregate_value: \"x:100\""),
      "foo.proto: foo.proto: OPTION_VALUE: Error while parsing option "
      "value for \"foo\": Message type \"Foo\" has no field named \"x\".\n");
}

TEST_F(ValidationErrorTest, NotLiteImportsLite) {
  BuildFile(
    "name: \"bar.proto\" "
    "options { optimize_for: LITE_RUNTIME } ");

  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "dependency: \"bar.proto\" ",

    "foo.proto: foo.proto: OTHER: Files that do not use optimize_for = "
      "LITE_RUNTIME cannot import files which do use this option.  This file "
      "is not lite, but it imports \"bar.proto\" which is.\n");
}

TEST_F(ValidationErrorTest, LiteExtendsNotLite) {
  BuildFile(
    "name: \"bar.proto\" "
    "message_type: {"
    "  name: \"Bar\""
    "  extension_range { start: 1 end: 1000 }"
    "}");

  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "dependency: \"bar.proto\" "
    "options { optimize_for: LITE_RUNTIME } "
    "extension { name: \"ext\" number: 123 label: LABEL_OPTIONAL "
    "            type: TYPE_INT32 extendee: \"Bar\" }",

    "foo.proto: ext: EXTENDEE: Extensions to non-lite types can only be "
      "declared in non-lite files.  Note that you cannot extend a non-lite "
      "type to contain a lite type, but the reverse is allowed.\n");
}

TEST_F(ValidationErrorTest, NoLiteServices) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "options {"
    "  optimize_for: LITE_RUNTIME"
    "  cc_generic_services: true"
    "  java_generic_services: true"
    "} "
    "service { name: \"Foo\" }",

    "foo.proto: Foo: NAME: Files with optimize_for = LITE_RUNTIME cannot "
    "define services unless you set both options cc_generic_services and "
    "java_generic_sevices to false.\n");

  BuildFile(
    "name: \"bar.proto\" "
    "options {"
    "  optimize_for: LITE_RUNTIME"
    "  cc_generic_services: false"
    "  java_generic_services: false"
    "} "
    "service { name: \"Bar\" }");
}

TEST_F(ValidationErrorTest, RollbackAfterError) {
  // Build a file which contains every kind of construct but references an
  // undefined type.  All these constructs will be added to the symbol table
  // before the undefined type error is noticed.  The DescriptorPool will then
  // have to roll everything back.
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "message_type {"
    "  name: \"TestMessage\""
    "  field { name:\"foo\" label:LABEL_OPTIONAL type:TYPE_INT32 number:1 }"
    "} "
    "enum_type {"
    "  name: \"TestEnum\""
    "  value { name:\"BAR\" number:1 }"
    "} "
    "service {"
    "  name: \"TestService\""
    "  method {"
    "    name: \"Baz\""
    "    input_type: \"NoSuchType\""    // error
    "    output_type: \"TestMessage\""
    "  }"
    "}",

    "foo.proto: TestService.Baz: INPUT_TYPE: \"NoSuchType\" is not defined.\n"
    );

  // Make sure that if we build the same file again with the error fixed,
  // it works.  If the above rollback was incomplete, then some symbols will
  // be left defined, and this second attempt will fail since it tries to
  // re-define the same symbols.
  BuildFile(
    "name: \"foo.proto\" "
    "message_type {"
    "  name: \"TestMessage\""
    "  field { name:\"foo\" label:LABEL_OPTIONAL type:TYPE_INT32 number:1 }"
    "} "
    "enum_type {"
    "  name: \"TestEnum\""
    "  value { name:\"BAR\" number:1 }"
    "} "
    "service {"
    "  name: \"TestService\""
    "  method { name:\"Baz\""
    "           input_type:\"TestMessage\""
    "           output_type:\"TestMessage\" }"
    "}");
}

TEST_F(ValidationErrorTest, ErrorsReportedToLogError) {
  // Test that errors are reported to GOOGLE_LOG(ERROR) if no error collector is
  // provided.

  FileDescriptorProto file_proto;
  ASSERT_TRUE(TextFormat::ParseFromString(
    "name: \"foo.proto\" "
    "message_type { name: \"Foo\" } "
    "message_type { name: \"Foo\" } ",
    &file_proto));

  vector<string> errors;

  {
    ScopedMemoryLog log;
    EXPECT_TRUE(pool_.BuildFile(file_proto) == NULL);
    errors = log.GetMessages(ERROR);
  }

  ASSERT_EQ(2, errors.size());

  EXPECT_EQ("Invalid proto descriptor for file \"foo.proto\":", errors[0]);
  EXPECT_EQ("  Foo: \"Foo\" is already defined.", errors[1]);
}

TEST_F(ValidationErrorTest, DisallowEnumAlias) {
  BuildFileWithErrors(
    "name: \"foo.proto\" "
    "enum_type {"
    "  name: \"Bar\""
    "  value { name:\"ENUM_A\" number:0 }"
    "  value { name:\"ENUM_B\" number:0 }"
    "  options { allow_alias: false }"
    "}",
    "foo.proto: Bar: NUMBER: "
    "\"ENUM_B\" uses the same enum value as \"ENUM_A\". "
    "If this is intended, set 'option allow_alias = true;' to the enum "
    "definition.\n");
}

// ===================================================================
// DescriptorDatabase

static void AddToDatabase(SimpleDescriptorDatabase* database,
                          const char* file_text) {
  FileDescriptorProto file_proto;
  EXPECT_TRUE(TextFormat::ParseFromString(file_text, &file_proto));
  database->Add(file_proto);
}

class DatabaseBackedPoolTest : public testing::Test {
 protected:
  DatabaseBackedPoolTest() {}

  SimpleDescriptorDatabase database_;

  virtual void SetUp() {
    AddToDatabase(&database_,
      "name: 'foo.proto' "
      "message_type { name:'Foo' extension_range { start: 1 end: 100 } } "
      "enum_type { name:'TestEnum' value { name:'DUMMY' number:0 } } "
      "service { name:'TestService' } ");
    AddToDatabase(&database_,
      "name: 'bar.proto' "
      "dependency: 'foo.proto' "
      "message_type { name:'Bar' } "
      "extension { name:'foo_ext' extendee: '.Foo' number:5 "
      "            label:LABEL_OPTIONAL type:TYPE_INT32 } ");
    // Baz has an undeclared dependency on Foo.
    AddToDatabase(&database_,
      "name: 'baz.proto' "
      "message_type { "
      "  name:'Baz' "
      "  field { name:'foo' number:1 label:LABEL_OPTIONAL type_name:'Foo' } "
      "}");
  }

  // We can't inject a file containing errors into a DescriptorPool, so we
  // need an actual mock DescriptorDatabase to test errors.
  class ErrorDescriptorDatabase : public DescriptorDatabase {
   public:
    ErrorDescriptorDatabase() {}
    ~ErrorDescriptorDatabase() {}

    // implements DescriptorDatabase ---------------------------------
    bool FindFileByName(const string& filename,
                        FileDescriptorProto* output) {
      // error.proto and error2.proto cyclically import each other.
      if (filename == "error.proto") {
        output->Clear();
        output->set_name("error.proto");
        output->add_dependency("error2.proto");
        return true;
      } else if (filename == "error2.proto") {
        output->Clear();
        output->set_name("error2.proto");
        output->add_dependency("error.proto");
        return true;
      } else {
        return false;
      }
    }
    bool FindFileContainingSymbol(const string& symbol_name,
                                  FileDescriptorProto* output) {
      return false;
    }
    bool FindFileContainingExtension(const string& containing_type,
                                     int field_number,
                                     FileDescriptorProto* output) {
      return false;
    }
  };

  // A DescriptorDatabase that counts how many times each method has been
  // called and forwards to some other DescriptorDatabase.
  class CallCountingDatabase : public DescriptorDatabase {
   public:
    CallCountingDatabase(DescriptorDatabase* wrapped_db)
      : wrapped_db_(wrapped_db) {
      Clear();
    }
    ~CallCountingDatabase() {}

    DescriptorDatabase* wrapped_db_;

    int call_count_;

    void Clear() {
      call_count_ = 0;
    }

    // implements DescriptorDatabase ---------------------------------
    bool FindFileByName(const string& filename,
                        FileDescriptorProto* output) {
      ++call_count_;
      return wrapped_db_->FindFileByName(filename, output);
    }
    bool FindFileContainingSymbol(const string& symbol_name,
                                  FileDescriptorProto* output) {
      ++call_count_;
      return wrapped_db_->FindFileContainingSymbol(symbol_name, output);
    }
    bool FindFileContainingExtension(const string& containing_type,
                                     int field_number,
                                     FileDescriptorProto* output) {
      ++call_count_;
      return wrapped_db_->FindFileContainingExtension(
        containing_type, field_number, output);
    }
  };

  // A DescriptorDatabase which falsely always returns foo.proto when searching
  // for any symbol or extension number.  This shouldn't cause the
  // DescriptorPool to reload foo.proto if it is already loaded.
  class FalsePositiveDatabase : public DescriptorDatabase {
   public:
    FalsePositiveDatabase(DescriptorDatabase* wrapped_db)
      : wrapped_db_(wrapped_db) {}
    ~FalsePositiveDatabase() {}

    DescriptorDatabase* wrapped_db_;

    // implements DescriptorDatabase ---------------------------------
    bool FindFileByName(const string& filename,
                        FileDescriptorProto* output) {
      return wrapped_db_->FindFileByName(filename, output);
    }
    bool FindFileContainingSymbol(const string& symbol_name,
                                  FileDescriptorProto* output) {
      return FindFileByName("foo.proto", output);
    }
    bool FindFileContainingExtension(const string& containing_type,
                                     int field_number,
                                     FileDescriptorProto* output) {
      return FindFileByName("foo.proto", output);
    }
  };
};

TEST_F(DatabaseBackedPoolTest, FindFileByName) {
  DescriptorPool pool(&database_);

  const FileDescriptor* foo = pool.FindFileByName("foo.proto");
  ASSERT_TRUE(foo != NULL);
  EXPECT_EQ("foo.proto", foo->name());
  ASSERT_EQ(1, foo->message_type_count());
  EXPECT_EQ("Foo", foo->message_type(0)->name());

  EXPECT_EQ(foo, pool.FindFileByName("foo.proto"));

  EXPECT_TRUE(pool.FindFileByName("no_such_file.proto") == NULL);
}

TEST_F(DatabaseBackedPoolTest, FindDependencyBeforeDependent) {
  DescriptorPool pool(&database_);

  const FileDescriptor* foo = pool.FindFileByName("foo.proto");
  ASSERT_TRUE(foo != NULL);
  EXPECT_EQ("foo.proto", foo->name());
  ASSERT_EQ(1, foo->message_type_count());
  EXPECT_EQ("Foo", foo->message_type(0)->name());

  const FileDescriptor* bar = pool.FindFileByName("bar.proto");
  ASSERT_TRUE(bar != NULL);
  EXPECT_EQ("bar.proto", bar->name());
  ASSERT_EQ(1, bar->message_type_count());
  EXPECT_EQ("Bar", bar->message_type(0)->name());

  ASSERT_EQ(1, bar->dependency_count());
  EXPECT_EQ(foo, bar->dependency(0));
}

TEST_F(DatabaseBackedPoolTest, FindDependentBeforeDependency) {
  DescriptorPool pool(&database_);

  const FileDescriptor* bar = pool.FindFileByName("bar.proto");
  ASSERT_TRUE(bar != NULL);
  EXPECT_EQ("bar.proto", bar->name());
  ASSERT_EQ(1, bar->message_type_count());
  ASSERT_EQ("Bar", bar->message_type(0)->name());

  const FileDescriptor* foo = pool.FindFileByName("foo.proto");
  ASSERT_TRUE(foo != NULL);
  EXPECT_EQ("foo.proto", foo->name());
  ASSERT_EQ(1, foo->message_type_count());
  ASSERT_EQ("Foo", foo->message_type(0)->name());

  ASSERT_EQ(1, bar->dependency_count());
  EXPECT_EQ(foo, bar->dependency(0));
}

TEST_F(DatabaseBackedPoolTest, FindFileContainingSymbol) {
  DescriptorPool pool(&database_);

  const FileDescriptor* file = pool.FindFileContainingSymbol("Foo");
  ASSERT_TRUE(file != NULL);
  EXPECT_EQ("foo.proto", file->name());
  EXPECT_EQ(file, pool.FindFileByName("foo.proto"));

  EXPECT_TRUE(pool.FindFileContainingSymbol("NoSuchSymbol") == NULL);
}

TEST_F(DatabaseBackedPoolTest, FindMessageTypeByName) {
  DescriptorPool pool(&database_);

  const Descriptor* type = pool.FindMessageTypeByName("Foo");
  ASSERT_TRUE(type != NULL);
  EXPECT_EQ("Foo", type->name());
  EXPECT_EQ(type->file(), pool.FindFileByName("foo.proto"));

  EXPECT_TRUE(pool.FindMessageTypeByName("NoSuchType") == NULL);
}

TEST_F(DatabaseBackedPoolTest, FindExtensionByNumber) {
  DescriptorPool pool(&database_);

  const Descriptor* foo = pool.FindMessageTypeByName("Foo");
  ASSERT_TRUE(foo != NULL);

  const FieldDescriptor* extension = pool.FindExtensionByNumber(foo, 5);
  ASSERT_TRUE(extension != NULL);
  EXPECT_EQ("foo_ext", extension->name());
  EXPECT_EQ(extension->file(), pool.FindFileByName("bar.proto"));

  EXPECT_TRUE(pool.FindExtensionByNumber(foo, 12) == NULL);
}

TEST_F(DatabaseBackedPoolTest, FindAllExtensions) {
  DescriptorPool pool(&database_);

  const Descriptor* foo = pool.FindMessageTypeByName("Foo");

  for (int i = 0; i < 2; ++i) {
    // Repeat the lookup twice, to check that we get consistent
    // results despite the fallback database lookup mutating the pool.
    vector<const FieldDescriptor*> extensions;
    pool.FindAllExtensions(foo, &extensions);
    ASSERT_EQ(1, extensions.size());
    EXPECT_EQ(5, extensions[0]->number());
  }
}

TEST_F(DatabaseBackedPoolTest, ErrorWithoutErrorCollector) {
  ErrorDescriptorDatabase error_database;
  DescriptorPool pool(&error_database);

  vector<string> errors;

  {
    ScopedMemoryLog log;
    EXPECT_TRUE(pool.FindFileByName("error.proto") == NULL);
    errors = log.GetMessages(ERROR);
  }

  EXPECT_FALSE(errors.empty());
}

TEST_F(DatabaseBackedPoolTest, ErrorWithErrorCollector) {
  ErrorDescriptorDatabase error_database;
  MockErrorCollector error_collector;
  DescriptorPool pool(&error_database, &error_collector);

  EXPECT_TRUE(pool.FindFileByName("error.proto") == NULL);
  EXPECT_EQ(
    "error.proto: error.proto: OTHER: File recursively imports itself: "
      "error.proto -> error2.proto -> error.proto\n"
    "error2.proto: error2.proto: OTHER: Import \"error.proto\" was not "
      "found or had errors.\n"
    "error.proto: error.proto: OTHER: Import \"error2.proto\" was not "
      "found or had errors.\n",
    error_collector.text_);
}

TEST_F(DatabaseBackedPoolTest, UndeclaredDependencyOnUnbuiltType) {
  // Check that we find and report undeclared dependencies on types that exist
  // in the descriptor database but that have not not been built yet.
  MockErrorCollector error_collector;
  DescriptorPool pool(&database_, &error_collector);
  EXPECT_TRUE(pool.FindMessageTypeByName("Baz") == NULL);
  EXPECT_EQ(
    "baz.proto: Baz.foo: TYPE: \"Foo\" seems to be defined in \"foo.proto\", "
    "which is not imported by \"baz.proto\".  To use it here, please add "
    "the necessary import.\n",
    error_collector.text_);
}

TEST_F(DatabaseBackedPoolTest, RollbackAfterError) {
  // Make sure that all traces of bad types are removed from the pool. This used
  // to be b/4529436, due to the fact that a symbol resolution failure could
  // potentially cause another file to be recursively built, which would trigger
  // a checkpoint _past_ possibly invalid symbols.
  // Baz is defined in the database, but the file is invalid because it is
  // missing a necessary import.
  DescriptorPool pool(&database_);
  EXPECT_TRUE(pool.FindMessageTypeByName("Baz") == NULL);
  // Make sure that searching again for the file or the type fails.
  EXPECT_TRUE(pool.FindFileByName("baz.proto") == NULL);
  EXPECT_TRUE(pool.FindMessageTypeByName("Baz") == NULL);
}

TEST_F(DatabaseBackedPoolTest, UnittestProto) {
  // Try to load all of unittest.proto from a DescriptorDatabase.  This should
  // thoroughly test all paths through DescriptorBuilder to insure that there
  // are no deadlocking problems when pool_->mutex_ is non-NULL.
  const FileDescriptor* original_file =
    protobuf_unittest::TestAllTypes::descriptor()->file();

  DescriptorPoolDatabase database(*DescriptorPool::generated_pool());
  DescriptorPool pool(&database);
  const FileDescriptor* file_from_database =
    pool.FindFileByName(original_file->name());

  ASSERT_TRUE(file_from_database != NULL);

  FileDescriptorProto original_file_proto;
  original_file->CopyTo(&original_file_proto);

  FileDescriptorProto file_from_database_proto;
  file_from_database->CopyTo(&file_from_database_proto);

  EXPECT_EQ(original_file_proto.DebugString(),
            file_from_database_proto.DebugString());
}

TEST_F(DatabaseBackedPoolTest, DoesntRetryDbUnnecessarily) {
  // Searching for a child of an existing descriptor should never fall back
  // to the DescriptorDatabase even if it isn't found, because we know all
  // children are already loaded.
  CallCountingDatabase call_counter(&database_);
  DescriptorPool pool(&call_counter);

  const FileDescriptor* file = pool.FindFileByName("foo.proto");
  ASSERT_TRUE(file != NULL);
  const Descriptor* foo = pool.FindMessageTypeByName("Foo");
  ASSERT_TRUE(foo != NULL);
  const EnumDescriptor* test_enum = pool.FindEnumTypeByName("TestEnum");
  ASSERT_TRUE(test_enum != NULL);
  const ServiceDescriptor* test_service = pool.FindServiceByName("TestService");
  ASSERT_TRUE(test_service != NULL);

  EXPECT_NE(0, call_counter.call_count_);
  call_counter.Clear();

  EXPECT_TRUE(foo->FindFieldByName("no_such_field") == NULL);
  EXPECT_TRUE(foo->FindExtensionByName("no_such_extension") == NULL);
  EXPECT_TRUE(foo->FindNestedTypeByName("NoSuchMessageType") == NULL);
  EXPECT_TRUE(foo->FindEnumTypeByName("NoSuchEnumType") == NULL);
  EXPECT_TRUE(foo->FindEnumValueByName("NO_SUCH_VALUE") == NULL);
  EXPECT_TRUE(test_enum->FindValueByName("NO_SUCH_VALUE") == NULL);
  EXPECT_TRUE(test_service->FindMethodByName("NoSuchMethod") == NULL);

  EXPECT_TRUE(file->FindMessageTypeByName("NoSuchMessageType") == NULL);
  EXPECT_TRUE(file->FindEnumTypeByName("NoSuchEnumType") == NULL);
  EXPECT_TRUE(file->FindEnumValueByName("NO_SUCH_VALUE") == NULL);
  EXPECT_TRUE(file->FindServiceByName("NO_SUCH_VALUE") == NULL);
  EXPECT_TRUE(file->FindExtensionByName("no_such_extension") == NULL);

  EXPECT_TRUE(pool.FindFileContainingSymbol("Foo.no.such.field") == NULL);
  EXPECT_TRUE(pool.FindFileContainingSymbol("Foo.no_such_field") == NULL);
  EXPECT_TRUE(pool.FindMessageTypeByName("Foo.NoSuchMessageType") == NULL);
  EXPECT_TRUE(pool.FindFieldByName("Foo.no_such_field") == NULL);
  EXPECT_TRUE(pool.FindExtensionByName("Foo.no_such_extension") == NULL);
  EXPECT_TRUE(pool.FindEnumTypeByName("Foo.NoSuchEnumType") == NULL);
  EXPECT_TRUE(pool.FindEnumValueByName("Foo.NO_SUCH_VALUE") == NULL);
  EXPECT_TRUE(pool.FindMethodByName("TestService.NoSuchMethod") == NULL);

  EXPECT_EQ(0, call_counter.call_count_);
}

TEST_F(DatabaseBackedPoolTest, DoesntReloadFilesUncesessarily) {
  // If FindFileContainingSymbol() or FindFileContainingExtension() return a
  // file that is already in the DescriptorPool, it should not attempt to
  // reload the file.
  FalsePositiveDatabase false_positive_database(&database_);
  MockErrorCollector error_collector;
  DescriptorPool pool(&false_positive_database, &error_collector);

  // First make sure foo.proto is loaded.
  const Descriptor* foo = pool.FindMessageTypeByName("Foo");
  ASSERT_TRUE(foo != NULL);

  // Try inducing false positives.
  EXPECT_TRUE(pool.FindMessageTypeByName("NoSuchSymbol") == NULL);
  EXPECT_TRUE(pool.FindExtensionByNumber(foo, 22) == NULL);

  // No errors should have been reported.  (If foo.proto was incorrectly
  // loaded multiple times, errors would have been reported.)
  EXPECT_EQ("", error_collector.text_);
}

TEST_F(DatabaseBackedPoolTest, DoesntReloadKnownBadFiles) {
  ErrorDescriptorDatabase error_database;
  MockErrorCollector error_collector;
  DescriptorPool pool(&error_database, &error_collector);

  EXPECT_TRUE(pool.FindFileByName("error.proto") == NULL);
  error_collector.text_.clear();
  EXPECT_TRUE(pool.FindFileByName("error.proto") == NULL);
  EXPECT_EQ("", error_collector.text_);
}

TEST_F(DatabaseBackedPoolTest, DoesntFallbackOnWrongType) {
  // If a lookup finds a symbol of the wrong type (e.g. we pass a type name
  // to FindFieldByName()), we should fail fast, without checking the fallback
  // database.
  CallCountingDatabase call_counter(&database_);
  DescriptorPool pool(&call_counter);

  const FileDescriptor* file = pool.FindFileByName("foo.proto");
  ASSERT_TRUE(file != NULL);
  const Descriptor* foo = pool.FindMessageTypeByName("Foo");
  ASSERT_TRUE(foo != NULL);
  const EnumDescriptor* test_enum = pool.FindEnumTypeByName("TestEnum");
  ASSERT_TRUE(test_enum != NULL);

  EXPECT_NE(0, call_counter.call_count_);
  call_counter.Clear();

  EXPECT_TRUE(pool.FindMessageTypeByName("TestEnum") == NULL);
  EXPECT_TRUE(pool.FindFieldByName("Foo") == NULL);
  EXPECT_TRUE(pool.FindExtensionByName("Foo") == NULL);
  EXPECT_TRUE(pool.FindEnumTypeByName("Foo") == NULL);
  EXPECT_TRUE(pool.FindEnumValueByName("Foo") == NULL);
  EXPECT_TRUE(pool.FindServiceByName("Foo") == NULL);
  EXPECT_TRUE(pool.FindMethodByName("Foo") == NULL);

  EXPECT_EQ(0, call_counter.call_count_);
}

// ===================================================================

class AbortingErrorCollector : public DescriptorPool::ErrorCollector {
 public:
  AbortingErrorCollector() {}

  virtual void AddError(
      const string &filename,
      const string &element_name,
      const Message *message,
      ErrorLocation location,
      const string &error_message) {
    GOOGLE_LOG(FATAL) << "AddError() called unexpectedly: " << filename << ": "
               << error_message;
  }
 private:
  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(AbortingErrorCollector);
};

// A source tree containing only one file.
class SingletonSourceTree : public compiler::SourceTree {
 public:
  SingletonSourceTree(const string& filename, const string& contents)
      : filename_(filename), contents_(contents) {}

  virtual io::ZeroCopyInputStream* Open(const string& filename) {
    return filename == filename_ ?
        new io::ArrayInputStream(contents_.data(), contents_.size()) : NULL;
  }

 private:
  const string filename_;
  const string contents_;

  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(SingletonSourceTree);
};

const char *const kSourceLocationTestInput =
  "syntax = \"proto2\";\n"
  "message A {\n"
  "  optional int32 a = 1;\n"
  "  message B {\n"
  "    required double b = 1;\n"
  "  }\n"
  "}\n"
  "enum Indecision {\n"
  "  YES   = 1;\n"
  "  NO    = 2;\n"
  "  MAYBE = 3;\n"
  "}\n"
  "service S {\n"
  "  rpc Method(A) returns (A.B);\n"
  // Put an empty line here to make the source location range match.
  "\n"
  "}\n";

class SourceLocationTest : public testing::Test {
 public:
  SourceLocationTest()
      : source_tree_("/test/test.proto", kSourceLocationTestInput),
        db_(&source_tree_),
        pool_(&db_, &collector_) {}

  static string PrintSourceLocation(const SourceLocation &loc) {
    return strings::Substitute("$0:$1-$2:$3",
                               1 + loc.start_line,
                               1 + loc.start_column,
                               1 + loc.end_line,
                               1 + loc.end_column);
  }

 private:
  AbortingErrorCollector collector_;
  SingletonSourceTree source_tree_;
  compiler::SourceTreeDescriptorDatabase db_;

 protected:
  DescriptorPool pool_;
};

// TODO(adonovan): implement support for option fields and for
// subparts of declarations.

TEST_F(SourceLocationTest, GetSourceLocation) {
  SourceLocation loc;

  const FileDescriptor *file_desc =
      GOOGLE_CHECK_NOTNULL(pool_.FindFileByName("/test/test.proto"));

  const Descriptor *a_desc = file_desc->FindMessageTypeByName("A");
  EXPECT_TRUE(a_desc->GetSourceLocation(&loc));
  EXPECT_EQ("2:1-7:2", PrintSourceLocation(loc));

  const Descriptor *a_b_desc = a_desc->FindNestedTypeByName("B");
  EXPECT_TRUE(a_b_desc->GetSourceLocation(&loc));
  EXPECT_EQ("4:3-6:4", PrintSourceLocation(loc));

  const EnumDescriptor *e_desc = file_desc->FindEnumTypeByName("Indecision");
  EXPECT_TRUE(e_desc->GetSourceLocation(&loc));
  EXPECT_EQ("8:1-12:2", PrintSourceLocation(loc));

  const EnumValueDescriptor *yes_desc = e_desc->FindValueByName("YES");
  EXPECT_TRUE(yes_desc->GetSourceLocation(&loc));
  EXPECT_EQ("9:3-9:13", PrintSourceLocation(loc));

  const ServiceDescriptor *s_desc = file_desc->FindServiceByName("S");
  EXPECT_TRUE(s_desc->GetSourceLocation(&loc));
  EXPECT_EQ("13:1-16:2", PrintSourceLocation(loc));

  const MethodDescriptor *m_desc = s_desc->FindMethodByName("Method");
  EXPECT_TRUE(m_desc->GetSourceLocation(&loc));
  EXPECT_EQ("14:3-14:31", PrintSourceLocation(loc));

}

// Missing SourceCodeInfo doesn't cause crash:
TEST_F(SourceLocationTest, GetSourceLocation_MissingSourceCodeInfo) {
  SourceLocation loc;

  const FileDescriptor *file_desc =
      GOOGLE_CHECK_NOTNULL(pool_.FindFileByName("/test/test.proto"));

  FileDescriptorProto proto;
  file_desc->CopyTo(&proto);  // Note, this discards the SourceCodeInfo.
  EXPECT_FALSE(proto.has_source_code_info());

  DescriptorPool bad1_pool(&pool_);
  const FileDescriptor* bad1_file_desc =
      GOOGLE_CHECK_NOTNULL(bad1_pool.BuildFile(proto));
  const Descriptor *bad1_a_desc = bad1_file_desc->FindMessageTypeByName("A");
  EXPECT_FALSE(bad1_a_desc->GetSourceLocation(&loc));
}

// Corrupt SourceCodeInfo doesn't cause crash:
TEST_F(SourceLocationTest, GetSourceLocation_BogusSourceCodeInfo) {
  SourceLocation loc;

  const FileDescriptor *file_desc =
      GOOGLE_CHECK_NOTNULL(pool_.FindFileByName("/test/test.proto"));

  FileDescriptorProto proto;
  file_desc->CopyTo(&proto);  // Note, this discards the SourceCodeInfo.
  EXPECT_FALSE(proto.has_source_code_info());
  SourceCodeInfo_Location *loc_msg =
      proto.mutable_source_code_info()->add_location();
  loc_msg->add_path(1);
  loc_msg->add_path(2);
  loc_msg->add_path(3);
  loc_msg->add_span(4);
  loc_msg->add_span(5);
  loc_msg->add_span(6);

  DescriptorPool bad2_pool(&pool_);
  const FileDescriptor* bad2_file_desc =
      GOOGLE_CHECK_NOTNULL(bad2_pool.BuildFile(proto));
  const Descriptor *bad2_a_desc = bad2_file_desc->FindMessageTypeByName("A");
  EXPECT_FALSE(bad2_a_desc->GetSourceLocation(&loc));
}

// ===================================================================

const char* const kCopySourceCodeInfoToTestInput =
  "syntax = \"proto2\";\n"
  "message Foo {}\n";

// Required since source code information is not preserved by
// FileDescriptorTest.
class CopySourceCodeInfoToTest : public testing::Test {
 public:
  CopySourceCodeInfoToTest()
      : source_tree_("/test/test.proto", kCopySourceCodeInfoToTestInput),
        db_(&source_tree_),
        pool_(&db_, &collector_) {}

 private:
  AbortingErrorCollector collector_;
  SingletonSourceTree source_tree_;
  compiler::SourceTreeDescriptorDatabase db_;

 protected:
  DescriptorPool pool_;
};

TEST_F(CopySourceCodeInfoToTest, CopyTo_DoesNotCopySourceCodeInfo) {
  const FileDescriptor* file_desc =
      GOOGLE_CHECK_NOTNULL(pool_.FindFileByName("/test/test.proto"));
  FileDescriptorProto file_desc_proto;
  ASSERT_FALSE(file_desc_proto.has_source_code_info());

  file_desc->CopyTo(&file_desc_proto);
  EXPECT_FALSE(file_desc_proto.has_source_code_info());
}

TEST_F(CopySourceCodeInfoToTest, CopySourceCodeInfoTo) {
  const FileDescriptor* file_desc =
      GOOGLE_CHECK_NOTNULL(pool_.FindFileByName("/test/test.proto"));
  FileDescriptorProto file_desc_proto;
  ASSERT_FALSE(file_desc_proto.has_source_code_info());

  file_desc->CopySourceCodeInfoTo(&file_desc_proto);
  const SourceCodeInfo& info = file_desc_proto.source_code_info();
  ASSERT_EQ(3, info.location_size());
  // Get the Foo message location
  const SourceCodeInfo_Location& foo_location = info.location(1);
  ASSERT_EQ(2, foo_location.path_size());
  EXPECT_EQ(FileDescriptorProto::kMessageTypeFieldNumber, foo_location.path(0));
  EXPECT_EQ(0, foo_location.path(1));      // Foo is the first message defined
  ASSERT_EQ(3, foo_location.span_size());  // Foo spans one line
  EXPECT_EQ(1, foo_location.span(0));      // Foo is declared on line 1
  EXPECT_EQ(0, foo_location.span(1));      // Foo starts at column 0
  EXPECT_EQ(14, foo_location.span(2));     // Foo ends on column 14
}

// ===================================================================


}  // namespace descriptor_unittest
}  // namespace protobuf
}  // namespace google
