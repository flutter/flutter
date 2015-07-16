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

#include <istream>
#include <stack>
#include <google/protobuf/stubs/hash.h>

#include <google/protobuf/message.h>

#include <google/protobuf/stubs/common.h>
#include <google/protobuf/stubs/once.h>
#include <google/protobuf/io/coded_stream.h>
#include <google/protobuf/io/zero_copy_stream_impl.h>
#include <google/protobuf/descriptor.pb.h>
#include <google/protobuf/descriptor.h>
#include <google/protobuf/generated_message_util.h>
#include <google/protobuf/reflection_ops.h>
#include <google/protobuf/wire_format.h>
#include <google/protobuf/stubs/strutil.h>
#include <google/protobuf/stubs/map-util.h>
#include <google/protobuf/stubs/stl_util.h>

namespace google {
namespace protobuf {

using internal::WireFormat;
using internal::ReflectionOps;

Message::~Message() {}

void Message::MergeFrom(const Message& from) {
  const Descriptor* descriptor = GetDescriptor();
  GOOGLE_CHECK_EQ(from.GetDescriptor(), descriptor)
    << ": Tried to merge from a message with a different type.  "
       "to: " << descriptor->full_name() << ", "
       "from:" << from.GetDescriptor()->full_name();
  ReflectionOps::Merge(from, this);
}

void Message::CheckTypeAndMergeFrom(const MessageLite& other) {
  MergeFrom(*down_cast<const Message*>(&other));
}

void Message::CopyFrom(const Message& from) {
  const Descriptor* descriptor = GetDescriptor();
  GOOGLE_CHECK_EQ(from.GetDescriptor(), descriptor)
    << ": Tried to copy from a message with a different type."
       "to: " << descriptor->full_name() << ", "
       "from:" << from.GetDescriptor()->full_name();
  ReflectionOps::Copy(from, this);
}

string Message::GetTypeName() const {
  return GetDescriptor()->full_name();
}

void Message::Clear() {
  ReflectionOps::Clear(this);
}

bool Message::IsInitialized() const {
  return ReflectionOps::IsInitialized(*this);
}

void Message::FindInitializationErrors(vector<string>* errors) const {
  return ReflectionOps::FindInitializationErrors(*this, "", errors);
}

string Message::InitializationErrorString() const {
  vector<string> errors;
  FindInitializationErrors(&errors);
  return JoinStrings(errors, ", ");
}

void Message::CheckInitialized() const {
  GOOGLE_CHECK(IsInitialized())
    << "Message of type \"" << GetDescriptor()->full_name()
    << "\" is missing required fields: " << InitializationErrorString();
}

void Message::DiscardUnknownFields() {
  return ReflectionOps::DiscardUnknownFields(this);
}

bool Message::MergePartialFromCodedStream(io::CodedInputStream* input) {
  return WireFormat::ParseAndMergePartial(input, this);
}

bool Message::ParseFromFileDescriptor(int file_descriptor) {
  io::FileInputStream input(file_descriptor);
  return ParseFromZeroCopyStream(&input) && input.GetErrno() == 0;
}

bool Message::ParsePartialFromFileDescriptor(int file_descriptor) {
  io::FileInputStream input(file_descriptor);
  return ParsePartialFromZeroCopyStream(&input) && input.GetErrno() == 0;
}

bool Message::ParseFromIstream(istream* input) {
  io::IstreamInputStream zero_copy_input(input);
  return ParseFromZeroCopyStream(&zero_copy_input) && input->eof();
}

bool Message::ParsePartialFromIstream(istream* input) {
  io::IstreamInputStream zero_copy_input(input);
  return ParsePartialFromZeroCopyStream(&zero_copy_input) && input->eof();
}


void Message::SerializeWithCachedSizes(
    io::CodedOutputStream* output) const {
  WireFormat::SerializeWithCachedSizes(*this, GetCachedSize(), output);
}

int Message::ByteSize() const {
  int size = WireFormat::ByteSize(*this);
  SetCachedSize(size);
  return size;
}

void Message::SetCachedSize(int size) const {
  GOOGLE_LOG(FATAL) << "Message class \"" << GetDescriptor()->full_name()
             << "\" implements neither SetCachedSize() nor ByteSize().  "
                "Must implement one or the other.";
}

int Message::SpaceUsed() const {
  return GetReflection()->SpaceUsed(*this);
}

bool Message::SerializeToFileDescriptor(int file_descriptor) const {
  io::FileOutputStream output(file_descriptor);
  return SerializeToZeroCopyStream(&output);
}

bool Message::SerializePartialToFileDescriptor(int file_descriptor) const {
  io::FileOutputStream output(file_descriptor);
  return SerializePartialToZeroCopyStream(&output);
}

bool Message::SerializeToOstream(ostream* output) const {
  {
    io::OstreamOutputStream zero_copy_output(output);
    if (!SerializeToZeroCopyStream(&zero_copy_output)) return false;
  }
  return output->good();
}

bool Message::SerializePartialToOstream(ostream* output) const {
  io::OstreamOutputStream zero_copy_output(output);
  return SerializePartialToZeroCopyStream(&zero_copy_output);
}


// =============================================================================
// Reflection and associated Template Specializations

Reflection::~Reflection() {}

#define HANDLE_TYPE(TYPE, CPPTYPE, CTYPE)                             \
template<>                                                            \
const RepeatedField<TYPE>& Reflection::GetRepeatedField<TYPE>(        \
    const Message& message, const FieldDescriptor* field) const {     \
  return *static_cast<RepeatedField<TYPE>* >(                         \
      MutableRawRepeatedField(const_cast<Message*>(&message),         \
                          field, CPPTYPE, CTYPE, NULL));              \
}                                                                     \
                                                                      \
template<>                                                            \
RepeatedField<TYPE>* Reflection::MutableRepeatedField<TYPE>(          \
    Message* message, const FieldDescriptor* field) const {           \
  return static_cast<RepeatedField<TYPE>* >(                          \
      MutableRawRepeatedField(message, field, CPPTYPE, CTYPE, NULL)); \
}

HANDLE_TYPE(int32,  FieldDescriptor::CPPTYPE_INT32,  -1);
HANDLE_TYPE(int64,  FieldDescriptor::CPPTYPE_INT64,  -1);
HANDLE_TYPE(uint32, FieldDescriptor::CPPTYPE_UINT32, -1);
HANDLE_TYPE(uint64, FieldDescriptor::CPPTYPE_UINT64, -1);
HANDLE_TYPE(float,  FieldDescriptor::CPPTYPE_FLOAT,  -1);
HANDLE_TYPE(double, FieldDescriptor::CPPTYPE_DOUBLE, -1);
HANDLE_TYPE(bool,   FieldDescriptor::CPPTYPE_BOOL,   -1);


#undef HANDLE_TYPE

void* Reflection::MutableRawRepeatedString(
    Message* message, const FieldDescriptor* field, bool is_string) const {
  return MutableRawRepeatedField(message, field,
      FieldDescriptor::CPPTYPE_STRING, FieldOptions::STRING, NULL);
}


// =============================================================================
// MessageFactory

MessageFactory::~MessageFactory() {}

namespace {

class GeneratedMessageFactory : public MessageFactory {
 public:
  GeneratedMessageFactory();
  ~GeneratedMessageFactory();

  static GeneratedMessageFactory* singleton();

  typedef void RegistrationFunc(const string&);
  void RegisterFile(const char* file, RegistrationFunc* registration_func);
  void RegisterType(const Descriptor* descriptor, const Message* prototype);

  // implements MessageFactory ---------------------------------------
  const Message* GetPrototype(const Descriptor* type);

 private:
  // Only written at static init time, so does not require locking.
  hash_map<const char*, RegistrationFunc*,
           hash<const char*>, streq> file_map_;

  // Initialized lazily, so requires locking.
  Mutex mutex_;
  hash_map<const Descriptor*, const Message*> type_map_;
};

GeneratedMessageFactory* generated_message_factory_ = NULL;
GOOGLE_PROTOBUF_DECLARE_ONCE(generated_message_factory_once_init_);

void ShutdownGeneratedMessageFactory() {
  delete generated_message_factory_;
}

void InitGeneratedMessageFactory() {
  generated_message_factory_ = new GeneratedMessageFactory;
  internal::OnShutdown(&ShutdownGeneratedMessageFactory);
}

GeneratedMessageFactory::GeneratedMessageFactory() {}
GeneratedMessageFactory::~GeneratedMessageFactory() {}

GeneratedMessageFactory* GeneratedMessageFactory::singleton() {
  ::google::protobuf::GoogleOnceInit(&generated_message_factory_once_init_,
                 &InitGeneratedMessageFactory);
  return generated_message_factory_;
}

void GeneratedMessageFactory::RegisterFile(
    const char* file, RegistrationFunc* registration_func) {
  if (!InsertIfNotPresent(&file_map_, file, registration_func)) {
    GOOGLE_LOG(FATAL) << "File is already registered: " << file;
  }
}

void GeneratedMessageFactory::RegisterType(const Descriptor* descriptor,
                                           const Message* prototype) {
  GOOGLE_DCHECK_EQ(descriptor->file()->pool(), DescriptorPool::generated_pool())
    << "Tried to register a non-generated type with the generated "
       "type registry.";

  // This should only be called as a result of calling a file registration
  // function during GetPrototype(), in which case we already have locked
  // the mutex.
  mutex_.AssertHeld();
  if (!InsertIfNotPresent(&type_map_, descriptor, prototype)) {
    GOOGLE_LOG(DFATAL) << "Type is already registered: " << descriptor->full_name();
  }
}


const Message* GeneratedMessageFactory::GetPrototype(const Descriptor* type) {
  {
    ReaderMutexLock lock(&mutex_);
    const Message* result = FindPtrOrNull(type_map_, type);
    if (result != NULL) return result;
  }

  // If the type is not in the generated pool, then we can't possibly handle
  // it.
  if (type->file()->pool() != DescriptorPool::generated_pool()) return NULL;

  // Apparently the file hasn't been registered yet.  Let's do that now.
  RegistrationFunc* registration_func =
      FindPtrOrNull(file_map_, type->file()->name().c_str());
  if (registration_func == NULL) {
    GOOGLE_LOG(DFATAL) << "File appears to be in generated pool but wasn't "
                   "registered: " << type->file()->name();
    return NULL;
  }

  WriterMutexLock lock(&mutex_);

  // Check if another thread preempted us.
  const Message* result = FindPtrOrNull(type_map_, type);
  if (result == NULL) {
    // Nope.  OK, register everything.
    registration_func(type->file()->name());
    // Should be here now.
    result = FindPtrOrNull(type_map_, type);
  }

  if (result == NULL) {
    GOOGLE_LOG(DFATAL) << "Type appears to be in generated pool but wasn't "
                << "registered: " << type->full_name();
  }

  return result;
}

}  // namespace

MessageFactory* MessageFactory::generated_factory() {
  return GeneratedMessageFactory::singleton();
}

void MessageFactory::InternalRegisterGeneratedFile(
    const char* filename, void (*register_messages)(const string&)) {
  GeneratedMessageFactory::singleton()->RegisterFile(filename,
                                                     register_messages);
}

void MessageFactory::InternalRegisterGeneratedMessage(
    const Descriptor* descriptor, const Message* prototype) {
  GeneratedMessageFactory::singleton()->RegisterType(descriptor, prototype);
}


}  // namespace protobuf
}  // namespace google
