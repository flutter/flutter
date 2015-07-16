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
// Since the reflection interface for DynamicMessage is implemented by
// GenericMessageReflection, the only thing we really have to test is
// that DynamicMessage correctly sets up the information that
// GenericMessageReflection needs to use.  So, we focus on that in this
// test.  Other tests, such as generic_message_reflection_unittest and
// reflection_ops_unittest, cover the rest of the functionality used by
// DynamicMessage.

#include <google/protobuf/stubs/common.h>
#include <google/protobuf/dynamic_message.h>
#include <google/protobuf/descriptor.h>
#include <google/protobuf/descriptor.pb.h>
#include <google/protobuf/test_util.h>
#include <google/protobuf/unittest.pb.h>

#include <google/protobuf/testing/googletest.h>
#include <gtest/gtest.h>

namespace google {
namespace protobuf {

class DynamicMessageTest : public testing::Test {
 protected:
  DescriptorPool pool_;
  DynamicMessageFactory factory_;
  const Descriptor* descriptor_;
  const Message* prototype_;
  const Descriptor* extensions_descriptor_;
  const Message* extensions_prototype_;
  const Descriptor* packed_descriptor_;
  const Message* packed_prototype_;

  DynamicMessageTest(): factory_(&pool_) {}

  virtual void SetUp() {
    // We want to make sure that DynamicMessage works (particularly with
    // extensions) even if we use descriptors that are *not* from compiled-in
    // types, so we make copies of the descriptors for unittest.proto and
    // unittest_import.proto.
    FileDescriptorProto unittest_file;
    FileDescriptorProto unittest_import_file;
    FileDescriptorProto unittest_import_public_file;

    unittest::TestAllTypes::descriptor()->file()->CopyTo(&unittest_file);
    unittest_import::ImportMessage::descriptor()->file()->CopyTo(
      &unittest_import_file);
    unittest_import::PublicImportMessage::descriptor()->file()->CopyTo(
      &unittest_import_public_file);

    ASSERT_TRUE(pool_.BuildFile(unittest_import_public_file) != NULL);
    ASSERT_TRUE(pool_.BuildFile(unittest_import_file) != NULL);
    ASSERT_TRUE(pool_.BuildFile(unittest_file) != NULL);

    descriptor_ = pool_.FindMessageTypeByName("protobuf_unittest.TestAllTypes");
    ASSERT_TRUE(descriptor_ != NULL);
    prototype_ = factory_.GetPrototype(descriptor_);

    extensions_descriptor_ =
      pool_.FindMessageTypeByName("protobuf_unittest.TestAllExtensions");
    ASSERT_TRUE(extensions_descriptor_ != NULL);
    extensions_prototype_ = factory_.GetPrototype(extensions_descriptor_);

    packed_descriptor_ =
      pool_.FindMessageTypeByName("protobuf_unittest.TestPackedTypes");
    ASSERT_TRUE(packed_descriptor_ != NULL);
    packed_prototype_ = factory_.GetPrototype(packed_descriptor_);
  }
};

TEST_F(DynamicMessageTest, Descriptor) {
  // Check that the descriptor on the DynamicMessage matches the descriptor
  // passed to GetPrototype().
  EXPECT_EQ(prototype_->GetDescriptor(), descriptor_);
}

TEST_F(DynamicMessageTest, OnePrototype) {
  // Check that requesting the same prototype twice produces the same object.
  EXPECT_EQ(prototype_, factory_.GetPrototype(descriptor_));
}

TEST_F(DynamicMessageTest, Defaults) {
  // Check that all default values are set correctly in the initial message.
  TestUtil::ReflectionTester reflection_tester(descriptor_);
  reflection_tester.ExpectClearViaReflection(*prototype_);
}

TEST_F(DynamicMessageTest, IndependentOffsets) {
  // Check that all fields have independent offsets by setting each
  // one to a unique value then checking that they all still have those
  // unique values (i.e. they don't stomp each other).
  scoped_ptr<Message> message(prototype_->New());
  TestUtil::ReflectionTester reflection_tester(descriptor_);

  reflection_tester.SetAllFieldsViaReflection(message.get());
  reflection_tester.ExpectAllFieldsSetViaReflection(*message);
}

TEST_F(DynamicMessageTest, Extensions) {
  // Check that extensions work.
  scoped_ptr<Message> message(extensions_prototype_->New());
  TestUtil::ReflectionTester reflection_tester(extensions_descriptor_);

  reflection_tester.SetAllFieldsViaReflection(message.get());
  reflection_tester.ExpectAllFieldsSetViaReflection(*message);
}

TEST_F(DynamicMessageTest, PackedFields) {
  // Check that packed fields work properly.
  scoped_ptr<Message> message(packed_prototype_->New());
  TestUtil::ReflectionTester reflection_tester(packed_descriptor_);

  reflection_tester.SetPackedFieldsViaReflection(message.get());
  reflection_tester.ExpectPackedFieldsSetViaReflection(*message);
}

TEST_F(DynamicMessageTest, SpaceUsed) {
  // Test that SpaceUsed() works properly

  // Since we share the implementation with generated messages, we don't need
  // to test very much here.  Just make sure it appears to be working.

  scoped_ptr<Message> message(prototype_->New());
  TestUtil::ReflectionTester reflection_tester(descriptor_);

  int initial_space_used = message->SpaceUsed();

  reflection_tester.SetAllFieldsViaReflection(message.get());
  EXPECT_LT(initial_space_used, message->SpaceUsed());
}

}  // namespace protobuf
}  // namespace google
