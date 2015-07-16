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

#include <google/protobuf/stubs/hash.h>
#include <google/protobuf/stubs/common.h>
#include <google/protobuf/stubs/once.h>
#include <google/protobuf/extension_set.h>
#include <google/protobuf/message_lite.h>
#include <google/protobuf/io/coded_stream.h>
#include <google/protobuf/io/zero_copy_stream_impl.h>
#include <google/protobuf/wire_format_lite_inl.h>
#include <google/protobuf/repeated_field.h>
#include <google/protobuf/stubs/map-util.h>

namespace google {
namespace protobuf {
namespace internal {

namespace {

inline WireFormatLite::FieldType real_type(FieldType type) {
  GOOGLE_DCHECK(type > 0 && type <= WireFormatLite::MAX_FIELD_TYPE);
  return static_cast<WireFormatLite::FieldType>(type);
}

inline WireFormatLite::CppType cpp_type(FieldType type) {
  return WireFormatLite::FieldTypeToCppType(real_type(type));
}

// Registry stuff.
typedef hash_map<pair<const MessageLite*, int>,
                 ExtensionInfo> ExtensionRegistry;
ExtensionRegistry* registry_ = NULL;
GOOGLE_PROTOBUF_DECLARE_ONCE(registry_init_);

void DeleteRegistry() {
  delete registry_;
  registry_ = NULL;
}

void InitRegistry() {
  registry_ = new ExtensionRegistry;
  OnShutdown(&DeleteRegistry);
}

// This function is only called at startup, so there is no need for thread-
// safety.
void Register(const MessageLite* containing_type,
              int number, ExtensionInfo info) {
  ::google::protobuf::GoogleOnceInit(&registry_init_, &InitRegistry);

  if (!InsertIfNotPresent(registry_, make_pair(containing_type, number),
                          info)) {
    GOOGLE_LOG(FATAL) << "Multiple extension registrations for type \""
               << containing_type->GetTypeName()
               << "\", field number " << number << ".";
  }
}

const ExtensionInfo* FindRegisteredExtension(
    const MessageLite* containing_type, int number) {
  return (registry_ == NULL) ? NULL :
         FindOrNull(*registry_, make_pair(containing_type, number));
}

}  // namespace

ExtensionFinder::~ExtensionFinder() {}

bool GeneratedExtensionFinder::Find(int number, ExtensionInfo* output) {
  const ExtensionInfo* extension =
      FindRegisteredExtension(containing_type_, number);
  if (extension == NULL) {
    return false;
  } else {
    *output = *extension;
    return true;
  }
}

void ExtensionSet::RegisterExtension(const MessageLite* containing_type,
                                     int number, FieldType type,
                                     bool is_repeated, bool is_packed) {
  GOOGLE_CHECK_NE(type, WireFormatLite::TYPE_ENUM);
  GOOGLE_CHECK_NE(type, WireFormatLite::TYPE_MESSAGE);
  GOOGLE_CHECK_NE(type, WireFormatLite::TYPE_GROUP);
  ExtensionInfo info(type, is_repeated, is_packed);
  Register(containing_type, number, info);
}

static bool CallNoArgValidityFunc(const void* arg, int number) {
  // Note:  Must use C-style cast here rather than reinterpret_cast because
  //   the C++ standard at one point did not allow casts between function and
  //   data pointers and some compilers enforce this for C++-style casts.  No
  //   compiler enforces it for C-style casts since lots of C-style code has
  //   relied on these kinds of casts for a long time, despite being
  //   technically undefined.  See:
  //     http://www.open-std.org/jtc1/sc22/wg21/docs/cwg_defects.html#195
  // Also note:  Some compilers do not allow function pointers to be "const".
  //   Which makes sense, I suppose, because it's meaningless.
  return ((EnumValidityFunc*)arg)(number);
}

void ExtensionSet::RegisterEnumExtension(const MessageLite* containing_type,
                                         int number, FieldType type,
                                         bool is_repeated, bool is_packed,
                                         EnumValidityFunc* is_valid) {
  GOOGLE_CHECK_EQ(type, WireFormatLite::TYPE_ENUM);
  ExtensionInfo info(type, is_repeated, is_packed);
  info.enum_validity_check.func = CallNoArgValidityFunc;
  // See comment in CallNoArgValidityFunc() about why we use a c-style cast.
  info.enum_validity_check.arg = (void*)is_valid;
  Register(containing_type, number, info);
}

void ExtensionSet::RegisterMessageExtension(const MessageLite* containing_type,
                                            int number, FieldType type,
                                            bool is_repeated, bool is_packed,
                                            const MessageLite* prototype) {
  GOOGLE_CHECK(type == WireFormatLite::TYPE_MESSAGE ||
        type == WireFormatLite::TYPE_GROUP);
  ExtensionInfo info(type, is_repeated, is_packed);
  info.message_prototype = prototype;
  Register(containing_type, number, info);
}


// ===================================================================
// Constructors and basic methods.

ExtensionSet::ExtensionSet() {}

ExtensionSet::~ExtensionSet() {
  for (map<int, Extension>::iterator iter = extensions_.begin();
       iter != extensions_.end(); ++iter) {
    iter->second.Free();
  }
}

// Defined in extension_set_heavy.cc.
// void ExtensionSet::AppendToList(const Descriptor* containing_type,
//                                 const DescriptorPool* pool,
//                                 vector<const FieldDescriptor*>* output) const

bool ExtensionSet::Has(int number) const {
  map<int, Extension>::const_iterator iter = extensions_.find(number);
  if (iter == extensions_.end()) return false;
  GOOGLE_DCHECK(!iter->second.is_repeated);
  return !iter->second.is_cleared;
}

int ExtensionSet::NumExtensions() const {
  int result = 0;
  for (map<int, Extension>::const_iterator iter = extensions_.begin();
       iter != extensions_.end(); ++iter) {
    if (!iter->second.is_cleared) {
      ++result;
    }
  }
  return result;
}

int ExtensionSet::ExtensionSize(int number) const {
  map<int, Extension>::const_iterator iter = extensions_.find(number);
  if (iter == extensions_.end()) return false;
  return iter->second.GetSize();
}

FieldType ExtensionSet::ExtensionType(int number) const {
  map<int, Extension>::const_iterator iter = extensions_.find(number);
  if (iter == extensions_.end()) {
    GOOGLE_LOG(DFATAL) << "Don't lookup extension types if they aren't present (1). ";
    return 0;
  }
  if (iter->second.is_cleared) {
    GOOGLE_LOG(DFATAL) << "Don't lookup extension types if they aren't present (2). ";
  }
  return iter->second.type;
}

void ExtensionSet::ClearExtension(int number) {
  map<int, Extension>::iterator iter = extensions_.find(number);
  if (iter == extensions_.end()) return;
  iter->second.Clear();
}

// ===================================================================
// Field accessors

namespace {

enum Cardinality {
  REPEATED,
  OPTIONAL
};

}  // namespace

#define GOOGLE_DCHECK_TYPE(EXTENSION, LABEL, CPPTYPE)                             \
  GOOGLE_DCHECK_EQ((EXTENSION).is_repeated ? REPEATED : OPTIONAL, LABEL);         \
  GOOGLE_DCHECK_EQ(cpp_type((EXTENSION).type), WireFormatLite::CPPTYPE_##CPPTYPE)

// -------------------------------------------------------------------
// Primitives

#define PRIMITIVE_ACCESSORS(UPPERCASE, LOWERCASE, CAMELCASE)                   \
                                                                               \
LOWERCASE ExtensionSet::Get##CAMELCASE(int number,                             \
                                       LOWERCASE default_value) const {        \
  map<int, Extension>::const_iterator iter = extensions_.find(number);         \
  if (iter == extensions_.end() || iter->second.is_cleared) {                  \
    return default_value;                                                      \
  } else {                                                                     \
    GOOGLE_DCHECK_TYPE(iter->second, OPTIONAL, UPPERCASE);                            \
    return iter->second.LOWERCASE##_value;                                     \
  }                                                                            \
}                                                                              \
                                                                               \
void ExtensionSet::Set##CAMELCASE(int number, FieldType type,                  \
                                  LOWERCASE value,                             \
                                  const FieldDescriptor* descriptor) {         \
  Extension* extension;                                                        \
  if (MaybeNewExtension(number, descriptor, &extension)) {                     \
    extension->type = type;                                                    \
    GOOGLE_DCHECK_EQ(cpp_type(extension->type), WireFormatLite::CPPTYPE_##UPPERCASE); \
    extension->is_repeated = false;                                            \
  } else {                                                                     \
    GOOGLE_DCHECK_TYPE(*extension, OPTIONAL, UPPERCASE);                              \
  }                                                                            \
  extension->is_cleared = false;                                               \
  extension->LOWERCASE##_value = value;                                        \
}                                                                              \
                                                                               \
LOWERCASE ExtensionSet::GetRepeated##CAMELCASE(int number, int index) const {  \
  map<int, Extension>::const_iterator iter = extensions_.find(number);         \
  GOOGLE_CHECK(iter != extensions_.end()) << "Index out-of-bounds (field is empty)."; \
  GOOGLE_DCHECK_TYPE(iter->second, REPEATED, UPPERCASE);                              \
  return iter->second.repeated_##LOWERCASE##_value->Get(index);                \
}                                                                              \
                                                                               \
void ExtensionSet::SetRepeated##CAMELCASE(                                     \
    int number, int index, LOWERCASE value) {                                  \
  map<int, Extension>::iterator iter = extensions_.find(number);               \
  GOOGLE_CHECK(iter != extensions_.end()) << "Index out-of-bounds (field is empty)."; \
  GOOGLE_DCHECK_TYPE(iter->second, REPEATED, UPPERCASE);                              \
  iter->second.repeated_##LOWERCASE##_value->Set(index, value);                \
}                                                                              \
                                                                               \
void ExtensionSet::Add##CAMELCASE(int number, FieldType type,                  \
                                  bool packed, LOWERCASE value,                \
                                  const FieldDescriptor* descriptor) {         \
  Extension* extension;                                                        \
  if (MaybeNewExtension(number, descriptor, &extension)) {                     \
    extension->type = type;                                                    \
    GOOGLE_DCHECK_EQ(cpp_type(extension->type), WireFormatLite::CPPTYPE_##UPPERCASE); \
    extension->is_repeated = true;                                             \
    extension->is_packed = packed;                                             \
    extension->repeated_##LOWERCASE##_value = new RepeatedField<LOWERCASE>();  \
  } else {                                                                     \
    GOOGLE_DCHECK_TYPE(*extension, REPEATED, UPPERCASE);                              \
    GOOGLE_DCHECK_EQ(extension->is_packed, packed);                                   \
  }                                                                            \
  extension->repeated_##LOWERCASE##_value->Add(value);                         \
}

PRIMITIVE_ACCESSORS( INT32,  int32,  Int32)
PRIMITIVE_ACCESSORS( INT64,  int64,  Int64)
PRIMITIVE_ACCESSORS(UINT32, uint32, UInt32)
PRIMITIVE_ACCESSORS(UINT64, uint64, UInt64)
PRIMITIVE_ACCESSORS( FLOAT,  float,  Float)
PRIMITIVE_ACCESSORS(DOUBLE, double, Double)
PRIMITIVE_ACCESSORS(  BOOL,   bool,   Bool)

#undef PRIMITIVE_ACCESSORS

void* ExtensionSet::MutableRawRepeatedField(int number) {
  // We assume that all the RepeatedField<>* pointers have the same
  // size and alignment within the anonymous union in Extension.
  map<int, Extension>::const_iterator iter = extensions_.find(number);
  GOOGLE_CHECK(iter != extensions_.end()) << "no extension numbered " << number;
  return iter->second.repeated_int32_value;
}

// -------------------------------------------------------------------
// Enums

int ExtensionSet::GetEnum(int number, int default_value) const {
  map<int, Extension>::const_iterator iter = extensions_.find(number);
  if (iter == extensions_.end() || iter->second.is_cleared) {
    // Not present.  Return the default value.
    return default_value;
  } else {
    GOOGLE_DCHECK_TYPE(iter->second, OPTIONAL, ENUM);
    return iter->second.enum_value;
  }
}

void ExtensionSet::SetEnum(int number, FieldType type, int value,
                           const FieldDescriptor* descriptor) {
  Extension* extension;
  if (MaybeNewExtension(number, descriptor, &extension)) {
    extension->type = type;
    GOOGLE_DCHECK_EQ(cpp_type(extension->type), WireFormatLite::CPPTYPE_ENUM);
    extension->is_repeated = false;
  } else {
    GOOGLE_DCHECK_TYPE(*extension, OPTIONAL, ENUM);
  }
  extension->is_cleared = false;
  extension->enum_value = value;
}

int ExtensionSet::GetRepeatedEnum(int number, int index) const {
  map<int, Extension>::const_iterator iter = extensions_.find(number);
  GOOGLE_CHECK(iter != extensions_.end()) << "Index out-of-bounds (field is empty).";
  GOOGLE_DCHECK_TYPE(iter->second, REPEATED, ENUM);
  return iter->second.repeated_enum_value->Get(index);
}

void ExtensionSet::SetRepeatedEnum(int number, int index, int value) {
  map<int, Extension>::iterator iter = extensions_.find(number);
  GOOGLE_CHECK(iter != extensions_.end()) << "Index out-of-bounds (field is empty).";
  GOOGLE_DCHECK_TYPE(iter->second, REPEATED, ENUM);
  iter->second.repeated_enum_value->Set(index, value);
}

void ExtensionSet::AddEnum(int number, FieldType type,
                           bool packed, int value,
                           const FieldDescriptor* descriptor) {
  Extension* extension;
  if (MaybeNewExtension(number, descriptor, &extension)) {
    extension->type = type;
    GOOGLE_DCHECK_EQ(cpp_type(extension->type), WireFormatLite::CPPTYPE_ENUM);
    extension->is_repeated = true;
    extension->is_packed = packed;
    extension->repeated_enum_value = new RepeatedField<int>();
  } else {
    GOOGLE_DCHECK_TYPE(*extension, REPEATED, ENUM);
    GOOGLE_DCHECK_EQ(extension->is_packed, packed);
  }
  extension->repeated_enum_value->Add(value);
}

// -------------------------------------------------------------------
// Strings

const string& ExtensionSet::GetString(int number,
                                      const string& default_value) const {
  map<int, Extension>::const_iterator iter = extensions_.find(number);
  if (iter == extensions_.end() || iter->second.is_cleared) {
    // Not present.  Return the default value.
    return default_value;
  } else {
    GOOGLE_DCHECK_TYPE(iter->second, OPTIONAL, STRING);
    return *iter->second.string_value;
  }
}

string* ExtensionSet::MutableString(int number, FieldType type,
                                    const FieldDescriptor* descriptor) {
  Extension* extension;
  if (MaybeNewExtension(number, descriptor, &extension)) {
    extension->type = type;
    GOOGLE_DCHECK_EQ(cpp_type(extension->type), WireFormatLite::CPPTYPE_STRING);
    extension->is_repeated = false;
    extension->string_value = new string;
  } else {
    GOOGLE_DCHECK_TYPE(*extension, OPTIONAL, STRING);
  }
  extension->is_cleared = false;
  return extension->string_value;
}

const string& ExtensionSet::GetRepeatedString(int number, int index) const {
  map<int, Extension>::const_iterator iter = extensions_.find(number);
  GOOGLE_CHECK(iter != extensions_.end()) << "Index out-of-bounds (field is empty).";
  GOOGLE_DCHECK_TYPE(iter->second, REPEATED, STRING);
  return iter->second.repeated_string_value->Get(index);
}

string* ExtensionSet::MutableRepeatedString(int number, int index) {
  map<int, Extension>::iterator iter = extensions_.find(number);
  GOOGLE_CHECK(iter != extensions_.end()) << "Index out-of-bounds (field is empty).";
  GOOGLE_DCHECK_TYPE(iter->second, REPEATED, STRING);
  return iter->second.repeated_string_value->Mutable(index);
}

string* ExtensionSet::AddString(int number, FieldType type,
                                const FieldDescriptor* descriptor) {
  Extension* extension;
  if (MaybeNewExtension(number, descriptor, &extension)) {
    extension->type = type;
    GOOGLE_DCHECK_EQ(cpp_type(extension->type), WireFormatLite::CPPTYPE_STRING);
    extension->is_repeated = true;
    extension->is_packed = false;
    extension->repeated_string_value = new RepeatedPtrField<string>();
  } else {
    GOOGLE_DCHECK_TYPE(*extension, REPEATED, STRING);
  }
  return extension->repeated_string_value->Add();
}

// -------------------------------------------------------------------
// Messages

const MessageLite& ExtensionSet::GetMessage(
    int number, const MessageLite& default_value) const {
  map<int, Extension>::const_iterator iter = extensions_.find(number);
  if (iter == extensions_.end()) {
    // Not present.  Return the default value.
    return default_value;
  } else {
    GOOGLE_DCHECK_TYPE(iter->second, OPTIONAL, MESSAGE);
    if (iter->second.is_lazy) {
      return iter->second.lazymessage_value->GetMessage(default_value);
    } else {
      return *iter->second.message_value;
    }
  }
}

// Defined in extension_set_heavy.cc.
// const MessageLite& ExtensionSet::GetMessage(int number,
//                                             const Descriptor* message_type,
//                                             MessageFactory* factory) const

MessageLite* ExtensionSet::MutableMessage(int number, FieldType type,
                                          const MessageLite& prototype,
                                          const FieldDescriptor* descriptor) {
  Extension* extension;
  if (MaybeNewExtension(number, descriptor, &extension)) {
    extension->type = type;
    GOOGLE_DCHECK_EQ(cpp_type(extension->type), WireFormatLite::CPPTYPE_MESSAGE);
    extension->is_repeated = false;
    extension->is_lazy = false;
    extension->message_value = prototype.New();
    extension->is_cleared = false;
    return extension->message_value;
  } else {
    GOOGLE_DCHECK_TYPE(*extension, OPTIONAL, MESSAGE);
    extension->is_cleared = false;
    if (extension->is_lazy) {
      return extension->lazymessage_value->MutableMessage(prototype);
    } else {
      return extension->message_value;
    }
  }
}

// Defined in extension_set_heavy.cc.
// MessageLite* ExtensionSet::MutableMessage(int number, FieldType type,
//                                           const Descriptor* message_type,
//                                           MessageFactory* factory)

void ExtensionSet::SetAllocatedMessage(int number, FieldType type,
                                       const FieldDescriptor* descriptor,
                                       MessageLite* message) {
  if (message == NULL) {
    ClearExtension(number);
    return;
  }
  Extension* extension;
  if (MaybeNewExtension(number, descriptor, &extension)) {
    extension->type = type;
    GOOGLE_DCHECK_EQ(cpp_type(extension->type), WireFormatLite::CPPTYPE_MESSAGE);
    extension->is_repeated = false;
    extension->is_lazy = false;
    extension->message_value = message;
  } else {
    GOOGLE_DCHECK_TYPE(*extension, OPTIONAL, MESSAGE);
    if (extension->is_lazy) {
      extension->lazymessage_value->SetAllocatedMessage(message);
    } else {
      delete extension->message_value;
      extension->message_value = message;
    }
  }
  extension->is_cleared = false;
}

MessageLite* ExtensionSet::ReleaseMessage(int number,
                                          const MessageLite& prototype) {
  map<int, Extension>::iterator iter = extensions_.find(number);
  if (iter == extensions_.end()) {
    // Not present.  Return NULL.
    return NULL;
  } else {
    GOOGLE_DCHECK_TYPE(iter->second, OPTIONAL, MESSAGE);
    MessageLite* ret = NULL;
    if (iter->second.is_lazy) {
      ret = iter->second.lazymessage_value->ReleaseMessage(prototype);
      delete iter->second.lazymessage_value;
    } else {
      ret = iter->second.message_value;
    }
    extensions_.erase(number);
    return ret;
  }
}

// Defined in extension_set_heavy.cc.
// MessageLite* ExtensionSet::ReleaseMessage(const FieldDescriptor* descriptor,
//                                           MessageFactory* factory);

const MessageLite& ExtensionSet::GetRepeatedMessage(
    int number, int index) const {
  map<int, Extension>::const_iterator iter = extensions_.find(number);
  GOOGLE_CHECK(iter != extensions_.end()) << "Index out-of-bounds (field is empty).";
  GOOGLE_DCHECK_TYPE(iter->second, REPEATED, MESSAGE);
  return iter->second.repeated_message_value->Get(index);
}

MessageLite* ExtensionSet::MutableRepeatedMessage(int number, int index) {
  map<int, Extension>::iterator iter = extensions_.find(number);
  GOOGLE_CHECK(iter != extensions_.end()) << "Index out-of-bounds (field is empty).";
  GOOGLE_DCHECK_TYPE(iter->second, REPEATED, MESSAGE);
  return iter->second.repeated_message_value->Mutable(index);
}

MessageLite* ExtensionSet::AddMessage(int number, FieldType type,
                                      const MessageLite& prototype,
                                      const FieldDescriptor* descriptor) {
  Extension* extension;
  if (MaybeNewExtension(number, descriptor, &extension)) {
    extension->type = type;
    GOOGLE_DCHECK_EQ(cpp_type(extension->type), WireFormatLite::CPPTYPE_MESSAGE);
    extension->is_repeated = true;
    extension->repeated_message_value =
      new RepeatedPtrField<MessageLite>();
  } else {
    GOOGLE_DCHECK_TYPE(*extension, REPEATED, MESSAGE);
  }

  // RepeatedPtrField<MessageLite> does not know how to Add() since it cannot
  // allocate an abstract object, so we have to be tricky.
  MessageLite* result = extension->repeated_message_value
      ->AddFromCleared<GenericTypeHandler<MessageLite> >();
  if (result == NULL) {
    result = prototype.New();
    extension->repeated_message_value->AddAllocated(result);
  }
  return result;
}

// Defined in extension_set_heavy.cc.
// MessageLite* ExtensionSet::AddMessage(int number, FieldType type,
//                                       const Descriptor* message_type,
//                                       MessageFactory* factory)

#undef GOOGLE_DCHECK_TYPE

void ExtensionSet::RemoveLast(int number) {
  map<int, Extension>::iterator iter = extensions_.find(number);
  GOOGLE_CHECK(iter != extensions_.end()) << "Index out-of-bounds (field is empty).";

  Extension* extension = &iter->second;
  GOOGLE_DCHECK(extension->is_repeated);

  switch(cpp_type(extension->type)) {
    case WireFormatLite::CPPTYPE_INT32:
      extension->repeated_int32_value->RemoveLast();
      break;
    case WireFormatLite::CPPTYPE_INT64:
      extension->repeated_int64_value->RemoveLast();
      break;
    case WireFormatLite::CPPTYPE_UINT32:
      extension->repeated_uint32_value->RemoveLast();
      break;
    case WireFormatLite::CPPTYPE_UINT64:
      extension->repeated_uint64_value->RemoveLast();
      break;
    case WireFormatLite::CPPTYPE_FLOAT:
      extension->repeated_float_value->RemoveLast();
      break;
    case WireFormatLite::CPPTYPE_DOUBLE:
      extension->repeated_double_value->RemoveLast();
      break;
    case WireFormatLite::CPPTYPE_BOOL:
      extension->repeated_bool_value->RemoveLast();
      break;
    case WireFormatLite::CPPTYPE_ENUM:
      extension->repeated_enum_value->RemoveLast();
      break;
    case WireFormatLite::CPPTYPE_STRING:
      extension->repeated_string_value->RemoveLast();
      break;
    case WireFormatLite::CPPTYPE_MESSAGE:
      extension->repeated_message_value->RemoveLast();
      break;
  }
}

MessageLite* ExtensionSet::ReleaseLast(int number) {
  map<int, Extension>::iterator iter = extensions_.find(number);
  GOOGLE_CHECK(iter != extensions_.end()) << "Index out-of-bounds (field is empty).";

  Extension* extension = &iter->second;
  GOOGLE_DCHECK(extension->is_repeated);
  GOOGLE_DCHECK(cpp_type(extension->type) == WireFormatLite::CPPTYPE_MESSAGE);
  return extension->repeated_message_value->ReleaseLast();
}

void ExtensionSet::SwapElements(int number, int index1, int index2) {
  map<int, Extension>::iterator iter = extensions_.find(number);
  GOOGLE_CHECK(iter != extensions_.end()) << "Index out-of-bounds (field is empty).";

  Extension* extension = &iter->second;
  GOOGLE_DCHECK(extension->is_repeated);

  switch(cpp_type(extension->type)) {
    case WireFormatLite::CPPTYPE_INT32:
      extension->repeated_int32_value->SwapElements(index1, index2);
      break;
    case WireFormatLite::CPPTYPE_INT64:
      extension->repeated_int64_value->SwapElements(index1, index2);
      break;
    case WireFormatLite::CPPTYPE_UINT32:
      extension->repeated_uint32_value->SwapElements(index1, index2);
      break;
    case WireFormatLite::CPPTYPE_UINT64:
      extension->repeated_uint64_value->SwapElements(index1, index2);
      break;
    case WireFormatLite::CPPTYPE_FLOAT:
      extension->repeated_float_value->SwapElements(index1, index2);
      break;
    case WireFormatLite::CPPTYPE_DOUBLE:
      extension->repeated_double_value->SwapElements(index1, index2);
      break;
    case WireFormatLite::CPPTYPE_BOOL:
      extension->repeated_bool_value->SwapElements(index1, index2);
      break;
    case WireFormatLite::CPPTYPE_ENUM:
      extension->repeated_enum_value->SwapElements(index1, index2);
      break;
    case WireFormatLite::CPPTYPE_STRING:
      extension->repeated_string_value->SwapElements(index1, index2);
      break;
    case WireFormatLite::CPPTYPE_MESSAGE:
      extension->repeated_message_value->SwapElements(index1, index2);
      break;
  }
}

// ===================================================================

void ExtensionSet::Clear() {
  for (map<int, Extension>::iterator iter = extensions_.begin();
       iter != extensions_.end(); ++iter) {
    iter->second.Clear();
  }
}

void ExtensionSet::MergeFrom(const ExtensionSet& other) {
  for (map<int, Extension>::const_iterator iter = other.extensions_.begin();
       iter != other.extensions_.end(); ++iter) {
    const Extension& other_extension = iter->second;

    if (other_extension.is_repeated) {
      Extension* extension;
      bool is_new = MaybeNewExtension(iter->first, other_extension.descriptor,
                                      &extension);
      if (is_new) {
        // Extension did not already exist in set.
        extension->type = other_extension.type;
        extension->is_packed = other_extension.is_packed;
        extension->is_repeated = true;
      } else {
        GOOGLE_DCHECK_EQ(extension->type, other_extension.type);
        GOOGLE_DCHECK_EQ(extension->is_packed, other_extension.is_packed);
        GOOGLE_DCHECK(extension->is_repeated);
      }

      switch (cpp_type(other_extension.type)) {
#define HANDLE_TYPE(UPPERCASE, LOWERCASE, REPEATED_TYPE)             \
        case WireFormatLite::CPPTYPE_##UPPERCASE:                    \
          if (is_new) {                                              \
            extension->repeated_##LOWERCASE##_value =                \
              new REPEATED_TYPE;                                     \
          }                                                          \
          extension->repeated_##LOWERCASE##_value->MergeFrom(        \
            *other_extension.repeated_##LOWERCASE##_value);          \
          break;

        HANDLE_TYPE(  INT32,   int32, RepeatedField   <  int32>);
        HANDLE_TYPE(  INT64,   int64, RepeatedField   <  int64>);
        HANDLE_TYPE( UINT32,  uint32, RepeatedField   < uint32>);
        HANDLE_TYPE( UINT64,  uint64, RepeatedField   < uint64>);
        HANDLE_TYPE(  FLOAT,   float, RepeatedField   <  float>);
        HANDLE_TYPE( DOUBLE,  double, RepeatedField   < double>);
        HANDLE_TYPE(   BOOL,    bool, RepeatedField   <   bool>);
        HANDLE_TYPE(   ENUM,    enum, RepeatedField   <    int>);
        HANDLE_TYPE( STRING,  string, RepeatedPtrField< string>);
#undef HANDLE_TYPE

        case WireFormatLite::CPPTYPE_MESSAGE:
          if (is_new) {
            extension->repeated_message_value =
              new RepeatedPtrField<MessageLite>();
          }
          // We can't call RepeatedPtrField<MessageLite>::MergeFrom() because
          // it would attempt to allocate new objects.
          RepeatedPtrField<MessageLite>* other_repeated_message =
              other_extension.repeated_message_value;
          for (int i = 0; i < other_repeated_message->size(); i++) {
            const MessageLite& other_message = other_repeated_message->Get(i);
            MessageLite* target = extension->repeated_message_value
                     ->AddFromCleared<GenericTypeHandler<MessageLite> >();
            if (target == NULL) {
              target = other_message.New();
              extension->repeated_message_value->AddAllocated(target);
            }
            target->CheckTypeAndMergeFrom(other_message);
          }
          break;
      }
    } else {
      if (!other_extension.is_cleared) {
        switch (cpp_type(other_extension.type)) {
#define HANDLE_TYPE(UPPERCASE, LOWERCASE, CAMELCASE)                         \
          case WireFormatLite::CPPTYPE_##UPPERCASE:                          \
            Set##CAMELCASE(iter->first, other_extension.type,                \
                           other_extension.LOWERCASE##_value,                \
                           other_extension.descriptor);                      \
            break;

          HANDLE_TYPE( INT32,  int32,  Int32);
          HANDLE_TYPE( INT64,  int64,  Int64);
          HANDLE_TYPE(UINT32, uint32, UInt32);
          HANDLE_TYPE(UINT64, uint64, UInt64);
          HANDLE_TYPE( FLOAT,  float,  Float);
          HANDLE_TYPE(DOUBLE, double, Double);
          HANDLE_TYPE(  BOOL,   bool,   Bool);
          HANDLE_TYPE(  ENUM,   enum,   Enum);
#undef HANDLE_TYPE
          case WireFormatLite::CPPTYPE_STRING:
            SetString(iter->first, other_extension.type,
                      *other_extension.string_value,
                      other_extension.descriptor);
            break;
          case WireFormatLite::CPPTYPE_MESSAGE: {
            Extension* extension;
            bool is_new = MaybeNewExtension(iter->first,
                                            other_extension.descriptor,
                                            &extension);
            if (is_new) {
              extension->type = other_extension.type;
              extension->is_packed = other_extension.is_packed;
              extension->is_repeated = false;
              if (other_extension.is_lazy) {
                extension->is_lazy = true;
                extension->lazymessage_value =
                    other_extension.lazymessage_value->New();
                extension->lazymessage_value->MergeFrom(
                    *other_extension.lazymessage_value);
              } else {
                extension->is_lazy = false;
                extension->message_value =
                    other_extension.message_value->New();
                extension->message_value->CheckTypeAndMergeFrom(
                    *other_extension.message_value);
              }
            } else {
              GOOGLE_DCHECK_EQ(extension->type, other_extension.type);
              GOOGLE_DCHECK_EQ(extension->is_packed,other_extension.is_packed);
              GOOGLE_DCHECK(!extension->is_repeated);
              if (other_extension.is_lazy) {
                if (extension->is_lazy) {
                  extension->lazymessage_value->MergeFrom(
                      *other_extension.lazymessage_value);
                } else {
                  extension->message_value->CheckTypeAndMergeFrom(
                      other_extension.lazymessage_value->GetMessage(
                          *extension->message_value));
                }
              } else {
                if (extension->is_lazy) {
                  extension->lazymessage_value->MutableMessage(
                      *other_extension.message_value)->CheckTypeAndMergeFrom(
                          *other_extension.message_value);
                } else {
                  extension->message_value->CheckTypeAndMergeFrom(
                      *other_extension.message_value);
                }
              }
            }
            extension->is_cleared = false;
            break;
          }
        }
      }
    }
  }
}

void ExtensionSet::Swap(ExtensionSet* x) {
  extensions_.swap(x->extensions_);
}

bool ExtensionSet::IsInitialized() const {
  // Extensions are never required.  However, we need to check that all
  // embedded messages are initialized.
  for (map<int, Extension>::const_iterator iter = extensions_.begin();
       iter != extensions_.end(); ++iter) {
    const Extension& extension = iter->second;
    if (cpp_type(extension.type) == WireFormatLite::CPPTYPE_MESSAGE) {
      if (extension.is_repeated) {
        for (int i = 0; i < extension.repeated_message_value->size(); i++) {
          if (!extension.repeated_message_value->Get(i).IsInitialized()) {
            return false;
          }
        }
      } else {
        if (!extension.is_cleared) {
          if (extension.is_lazy) {
            if (!extension.lazymessage_value->IsInitialized()) return false;
          } else {
            if (!extension.message_value->IsInitialized()) return false;
          }
        }
      }
    }
  }

  return true;
}

bool ExtensionSet::FindExtensionInfoFromTag(
    uint32 tag, ExtensionFinder* extension_finder,
    int* field_number, ExtensionInfo* extension) {
  *field_number = WireFormatLite::GetTagFieldNumber(tag);
  WireFormatLite::WireType wire_type = WireFormatLite::GetTagWireType(tag);

  bool is_unknown;
  if (!extension_finder->Find(*field_number, extension)) {
    is_unknown = true;
  } else if (extension->is_packed) {
    is_unknown = (wire_type != WireFormatLite::WIRETYPE_LENGTH_DELIMITED);
  } else {
    WireFormatLite::WireType expected_wire_type =
        WireFormatLite::WireTypeForFieldType(real_type(extension->type));
    is_unknown = (wire_type != expected_wire_type);
  }
  return !is_unknown;
}

bool ExtensionSet::ParseField(uint32 tag, io::CodedInputStream* input,
                              ExtensionFinder* extension_finder,
                              FieldSkipper* field_skipper) {
  int number;
  ExtensionInfo extension;
  if (!FindExtensionInfoFromTag(tag, extension_finder, &number, &extension)) {
    return field_skipper->SkipField(input, tag);
  } else {
    return ParseFieldWithExtensionInfo(number, extension, input, field_skipper);
  }
}

bool ExtensionSet::ParseFieldWithExtensionInfo(
    int number, const ExtensionInfo& extension,
    io::CodedInputStream* input,
    FieldSkipper* field_skipper) {
  if (extension.is_packed) {
    uint32 size;
    if (!input->ReadVarint32(&size)) return false;
    io::CodedInputStream::Limit limit = input->PushLimit(size);

    switch (extension.type) {
#define HANDLE_TYPE(UPPERCASE, CPP_CAMELCASE, CPP_LOWERCASE)        \
      case WireFormatLite::TYPE_##UPPERCASE:                                   \
        while (input->BytesUntilLimit() > 0) {                                 \
          CPP_LOWERCASE value;                                                 \
          if (!WireFormatLite::ReadPrimitive<                                  \
                  CPP_LOWERCASE, WireFormatLite::TYPE_##UPPERCASE>(            \
                input, &value)) return false;                                  \
          Add##CPP_CAMELCASE(number, WireFormatLite::TYPE_##UPPERCASE,         \
                             true, value, extension.descriptor);               \
        }                                                                      \
        break

      HANDLE_TYPE(   INT32,  Int32,   int32);
      HANDLE_TYPE(   INT64,  Int64,   int64);
      HANDLE_TYPE(  UINT32, UInt32,  uint32);
      HANDLE_TYPE(  UINT64, UInt64,  uint64);
      HANDLE_TYPE(  SINT32,  Int32,   int32);
      HANDLE_TYPE(  SINT64,  Int64,   int64);
      HANDLE_TYPE( FIXED32, UInt32,  uint32);
      HANDLE_TYPE( FIXED64, UInt64,  uint64);
      HANDLE_TYPE(SFIXED32,  Int32,   int32);
      HANDLE_TYPE(SFIXED64,  Int64,   int64);
      HANDLE_TYPE(   FLOAT,  Float,   float);
      HANDLE_TYPE(  DOUBLE, Double,  double);
      HANDLE_TYPE(    BOOL,   Bool,    bool);
#undef HANDLE_TYPE

      case WireFormatLite::TYPE_ENUM:
        while (input->BytesUntilLimit() > 0) {
          int value;
          if (!WireFormatLite::ReadPrimitive<int, WireFormatLite::TYPE_ENUM>(
                  input, &value)) return false;
          if (extension.enum_validity_check.func(
                  extension.enum_validity_check.arg, value)) {
            AddEnum(number, WireFormatLite::TYPE_ENUM, true, value,
                    extension.descriptor);
          }
        }
        break;

      case WireFormatLite::TYPE_STRING:
      case WireFormatLite::TYPE_BYTES:
      case WireFormatLite::TYPE_GROUP:
      case WireFormatLite::TYPE_MESSAGE:
        GOOGLE_LOG(FATAL) << "Non-primitive types can't be packed.";
        break;
    }

    input->PopLimit(limit);
  } else {
    switch (extension.type) {
#define HANDLE_TYPE(UPPERCASE, CPP_CAMELCASE, CPP_LOWERCASE)                   \
      case WireFormatLite::TYPE_##UPPERCASE: {                                 \
        CPP_LOWERCASE value;                                                   \
        if (!WireFormatLite::ReadPrimitive<                                    \
                CPP_LOWERCASE, WireFormatLite::TYPE_##UPPERCASE>(              \
               input, &value)) return false;                                   \
        if (extension.is_repeated) {                                          \
          Add##CPP_CAMELCASE(number, WireFormatLite::TYPE_##UPPERCASE,         \
                             false, value, extension.descriptor);              \
        } else {                                                               \
          Set##CPP_CAMELCASE(number, WireFormatLite::TYPE_##UPPERCASE, value,  \
                             extension.descriptor);                            \
        }                                                                      \
      } break

      HANDLE_TYPE(   INT32,  Int32,   int32);
      HANDLE_TYPE(   INT64,  Int64,   int64);
      HANDLE_TYPE(  UINT32, UInt32,  uint32);
      HANDLE_TYPE(  UINT64, UInt64,  uint64);
      HANDLE_TYPE(  SINT32,  Int32,   int32);
      HANDLE_TYPE(  SINT64,  Int64,   int64);
      HANDLE_TYPE( FIXED32, UInt32,  uint32);
      HANDLE_TYPE( FIXED64, UInt64,  uint64);
      HANDLE_TYPE(SFIXED32,  Int32,   int32);
      HANDLE_TYPE(SFIXED64,  Int64,   int64);
      HANDLE_TYPE(   FLOAT,  Float,   float);
      HANDLE_TYPE(  DOUBLE, Double,  double);
      HANDLE_TYPE(    BOOL,   Bool,    bool);
#undef HANDLE_TYPE

      case WireFormatLite::TYPE_ENUM: {
        int value;
        if (!WireFormatLite::ReadPrimitive<int, WireFormatLite::TYPE_ENUM>(
                input, &value)) return false;

        if (!extension.enum_validity_check.func(
                extension.enum_validity_check.arg, value)) {
          // Invalid value.  Treat as unknown.
          field_skipper->SkipUnknownEnum(number, value);
        } else if (extension.is_repeated) {
          AddEnum(number, WireFormatLite::TYPE_ENUM, false, value,
                  extension.descriptor);
        } else {
          SetEnum(number, WireFormatLite::TYPE_ENUM, value,
                  extension.descriptor);
        }
        break;
      }

      case WireFormatLite::TYPE_STRING:  {
        string* value = extension.is_repeated ?
          AddString(number, WireFormatLite::TYPE_STRING, extension.descriptor) :
          MutableString(number, WireFormatLite::TYPE_STRING,
                        extension.descriptor);
        if (!WireFormatLite::ReadString(input, value)) return false;
        break;
      }

      case WireFormatLite::TYPE_BYTES:  {
        string* value = extension.is_repeated ?
          AddString(number, WireFormatLite::TYPE_BYTES, extension.descriptor) :
          MutableString(number, WireFormatLite::TYPE_BYTES,
                        extension.descriptor);
        if (!WireFormatLite::ReadBytes(input, value)) return false;
        break;
      }

      case WireFormatLite::TYPE_GROUP: {
        MessageLite* value = extension.is_repeated ?
            AddMessage(number, WireFormatLite::TYPE_GROUP,
                       *extension.message_prototype, extension.descriptor) :
            MutableMessage(number, WireFormatLite::TYPE_GROUP,
                           *extension.message_prototype, extension.descriptor);
        if (!WireFormatLite::ReadGroup(number, input, value)) return false;
        break;
      }

      case WireFormatLite::TYPE_MESSAGE: {
        MessageLite* value = extension.is_repeated ?
            AddMessage(number, WireFormatLite::TYPE_MESSAGE,
                       *extension.message_prototype, extension.descriptor) :
            MutableMessage(number, WireFormatLite::TYPE_MESSAGE,
                           *extension.message_prototype, extension.descriptor);
        if (!WireFormatLite::ReadMessage(input, value)) return false;
        break;
      }
    }
  }

  return true;
}

bool ExtensionSet::ParseField(uint32 tag, io::CodedInputStream* input,
                              const MessageLite* containing_type,
                              UnknownFieldSet* unknown_fields) {
  FieldSkipper skipper(unknown_fields);
  GeneratedExtensionFinder finder(containing_type);
  return ParseField(tag, input, &finder, &skipper);
}

// Defined in extension_set_heavy.cc.
// bool ExtensionSet::ParseFieldHeavy(uint32 tag, io::CodedInputStream* input,
//                                    const Message* containing_type,
//                                    UnknownFieldSet* unknown_fields)

// Defined in extension_set_heavy.cc.
// bool ExtensionSet::ParseMessageSetHeavy(io::CodedInputStream* input,
//                                         const Message* containing_type,
//                                         UnknownFieldSet* unknown_fields);

void ExtensionSet::SerializeWithCachedSizes(
    int start_field_number, int end_field_number,
    io::CodedOutputStream* output) const {
  map<int, Extension>::const_iterator iter;
  for (iter = extensions_.lower_bound(start_field_number);
       iter != extensions_.end() && iter->first < end_field_number;
       ++iter) {
    iter->second.SerializeFieldWithCachedSizes(iter->first, output);
  }
}

int ExtensionSet::ByteSize() const {
  int total_size = 0;

  for (map<int, Extension>::const_iterator iter = extensions_.begin();
       iter != extensions_.end(); ++iter) {
    total_size += iter->second.ByteSize(iter->first);
  }

  return total_size;
}

// Defined in extension_set_heavy.cc.
// int ExtensionSet::SpaceUsedExcludingSelf() const

bool ExtensionSet::MaybeNewExtension(int number,
                                     const FieldDescriptor* descriptor,
                                     Extension** result) {
  pair<map<int, Extension>::iterator, bool> insert_result =
      extensions_.insert(make_pair(number, Extension()));
  *result = &insert_result.first->second;
  (*result)->descriptor = descriptor;
  return insert_result.second;
}

// ===================================================================
// Methods of ExtensionSet::Extension

void ExtensionSet::Extension::Clear() {
  if (is_repeated) {
    switch (cpp_type(type)) {
#define HANDLE_TYPE(UPPERCASE, LOWERCASE)                          \
      case WireFormatLite::CPPTYPE_##UPPERCASE:                    \
        repeated_##LOWERCASE##_value->Clear();                     \
        break

      HANDLE_TYPE(  INT32,   int32);
      HANDLE_TYPE(  INT64,   int64);
      HANDLE_TYPE( UINT32,  uint32);
      HANDLE_TYPE( UINT64,  uint64);
      HANDLE_TYPE(  FLOAT,   float);
      HANDLE_TYPE( DOUBLE,  double);
      HANDLE_TYPE(   BOOL,    bool);
      HANDLE_TYPE(   ENUM,    enum);
      HANDLE_TYPE( STRING,  string);
      HANDLE_TYPE(MESSAGE, message);
#undef HANDLE_TYPE
    }
  } else {
    if (!is_cleared) {
      switch (cpp_type(type)) {
        case WireFormatLite::CPPTYPE_STRING:
          string_value->clear();
          break;
        case WireFormatLite::CPPTYPE_MESSAGE:
          if (is_lazy) {
            lazymessage_value->Clear();
          } else {
            message_value->Clear();
          }
          break;
        default:
          // No need to do anything.  Get*() will return the default value
          // as long as is_cleared is true and Set*() will overwrite the
          // previous value.
          break;
      }

      is_cleared = true;
    }
  }
}

void ExtensionSet::Extension::SerializeFieldWithCachedSizes(
    int number,
    io::CodedOutputStream* output) const {
  if (is_repeated) {
    if (is_packed) {
      if (cached_size == 0) return;

      WireFormatLite::WriteTag(number,
          WireFormatLite::WIRETYPE_LENGTH_DELIMITED, output);
      output->WriteVarint32(cached_size);

      switch (real_type(type)) {
#define HANDLE_TYPE(UPPERCASE, CAMELCASE, LOWERCASE)                        \
        case WireFormatLite::TYPE_##UPPERCASE:                              \
          for (int i = 0; i < repeated_##LOWERCASE##_value->size(); i++) {  \
            WireFormatLite::Write##CAMELCASE##NoTag(                        \
              repeated_##LOWERCASE##_value->Get(i), output);                \
          }                                                                 \
          break

        HANDLE_TYPE(   INT32,    Int32,   int32);
        HANDLE_TYPE(   INT64,    Int64,   int64);
        HANDLE_TYPE(  UINT32,   UInt32,  uint32);
        HANDLE_TYPE(  UINT64,   UInt64,  uint64);
        HANDLE_TYPE(  SINT32,   SInt32,   int32);
        HANDLE_TYPE(  SINT64,   SInt64,   int64);
        HANDLE_TYPE( FIXED32,  Fixed32,  uint32);
        HANDLE_TYPE( FIXED64,  Fixed64,  uint64);
        HANDLE_TYPE(SFIXED32, SFixed32,   int32);
        HANDLE_TYPE(SFIXED64, SFixed64,   int64);
        HANDLE_TYPE(   FLOAT,    Float,   float);
        HANDLE_TYPE(  DOUBLE,   Double,  double);
        HANDLE_TYPE(    BOOL,     Bool,    bool);
        HANDLE_TYPE(    ENUM,     Enum,    enum);
#undef HANDLE_TYPE

        case WireFormatLite::TYPE_STRING:
        case WireFormatLite::TYPE_BYTES:
        case WireFormatLite::TYPE_GROUP:
        case WireFormatLite::TYPE_MESSAGE:
          GOOGLE_LOG(FATAL) << "Non-primitive types can't be packed.";
          break;
      }
    } else {
      switch (real_type(type)) {
#define HANDLE_TYPE(UPPERCASE, CAMELCASE, LOWERCASE)                        \
        case WireFormatLite::TYPE_##UPPERCASE:                              \
          for (int i = 0; i < repeated_##LOWERCASE##_value->size(); i++) {  \
            WireFormatLite::Write##CAMELCASE(number,                        \
              repeated_##LOWERCASE##_value->Get(i), output);                \
          }                                                                 \
          break

        HANDLE_TYPE(   INT32,    Int32,   int32);
        HANDLE_TYPE(   INT64,    Int64,   int64);
        HANDLE_TYPE(  UINT32,   UInt32,  uint32);
        HANDLE_TYPE(  UINT64,   UInt64,  uint64);
        HANDLE_TYPE(  SINT32,   SInt32,   int32);
        HANDLE_TYPE(  SINT64,   SInt64,   int64);
        HANDLE_TYPE( FIXED32,  Fixed32,  uint32);
        HANDLE_TYPE( FIXED64,  Fixed64,  uint64);
        HANDLE_TYPE(SFIXED32, SFixed32,   int32);
        HANDLE_TYPE(SFIXED64, SFixed64,   int64);
        HANDLE_TYPE(   FLOAT,    Float,   float);
        HANDLE_TYPE(  DOUBLE,   Double,  double);
        HANDLE_TYPE(    BOOL,     Bool,    bool);
        HANDLE_TYPE(  STRING,   String,  string);
        HANDLE_TYPE(   BYTES,    Bytes,  string);
        HANDLE_TYPE(    ENUM,     Enum,    enum);
        HANDLE_TYPE(   GROUP,    Group, message);
        HANDLE_TYPE( MESSAGE,  Message, message);
#undef HANDLE_TYPE
      }
    }
  } else if (!is_cleared) {
    switch (real_type(type)) {
#define HANDLE_TYPE(UPPERCASE, CAMELCASE, VALUE)                 \
      case WireFormatLite::TYPE_##UPPERCASE:                     \
        WireFormatLite::Write##CAMELCASE(number, VALUE, output); \
        break

      HANDLE_TYPE(   INT32,    Int32,    int32_value);
      HANDLE_TYPE(   INT64,    Int64,    int64_value);
      HANDLE_TYPE(  UINT32,   UInt32,   uint32_value);
      HANDLE_TYPE(  UINT64,   UInt64,   uint64_value);
      HANDLE_TYPE(  SINT32,   SInt32,    int32_value);
      HANDLE_TYPE(  SINT64,   SInt64,    int64_value);
      HANDLE_TYPE( FIXED32,  Fixed32,   uint32_value);
      HANDLE_TYPE( FIXED64,  Fixed64,   uint64_value);
      HANDLE_TYPE(SFIXED32, SFixed32,    int32_value);
      HANDLE_TYPE(SFIXED64, SFixed64,    int64_value);
      HANDLE_TYPE(   FLOAT,    Float,    float_value);
      HANDLE_TYPE(  DOUBLE,   Double,   double_value);
      HANDLE_TYPE(    BOOL,     Bool,     bool_value);
      HANDLE_TYPE(  STRING,   String,  *string_value);
      HANDLE_TYPE(   BYTES,    Bytes,  *string_value);
      HANDLE_TYPE(    ENUM,     Enum,     enum_value);
      HANDLE_TYPE(   GROUP,    Group, *message_value);
#undef HANDLE_TYPE
      case WireFormatLite::TYPE_MESSAGE:
        if (is_lazy) {
          lazymessage_value->WriteMessage(number, output);
        } else {
          WireFormatLite::WriteMessage(number, *message_value, output);
        }
        break;
    }
  }
}

int ExtensionSet::Extension::ByteSize(int number) const {
  int result = 0;

  if (is_repeated) {
    if (is_packed) {
      switch (real_type(type)) {
#define HANDLE_TYPE(UPPERCASE, CAMELCASE, LOWERCASE)                        \
        case WireFormatLite::TYPE_##UPPERCASE:                              \
          for (int i = 0; i < repeated_##LOWERCASE##_value->size(); i++) {  \
            result += WireFormatLite::CAMELCASE##Size(                      \
              repeated_##LOWERCASE##_value->Get(i));                        \
          }                                                                 \
          break

        HANDLE_TYPE(   INT32,    Int32,   int32);
        HANDLE_TYPE(   INT64,    Int64,   int64);
        HANDLE_TYPE(  UINT32,   UInt32,  uint32);
        HANDLE_TYPE(  UINT64,   UInt64,  uint64);
        HANDLE_TYPE(  SINT32,   SInt32,   int32);
        HANDLE_TYPE(  SINT64,   SInt64,   int64);
        HANDLE_TYPE(    ENUM,     Enum,    enum);
#undef HANDLE_TYPE

        // Stuff with fixed size.
#define HANDLE_TYPE(UPPERCASE, CAMELCASE, LOWERCASE)                        \
        case WireFormatLite::TYPE_##UPPERCASE:                              \
          result += WireFormatLite::k##CAMELCASE##Size *                    \
                    repeated_##LOWERCASE##_value->size();                   \
          break
        HANDLE_TYPE( FIXED32,  Fixed32, uint32);
        HANDLE_TYPE( FIXED64,  Fixed64, uint64);
        HANDLE_TYPE(SFIXED32, SFixed32,  int32);
        HANDLE_TYPE(SFIXED64, SFixed64,  int64);
        HANDLE_TYPE(   FLOAT,    Float,  float);
        HANDLE_TYPE(  DOUBLE,   Double, double);
        HANDLE_TYPE(    BOOL,     Bool,   bool);
#undef HANDLE_TYPE

        case WireFormatLite::TYPE_STRING:
        case WireFormatLite::TYPE_BYTES:
        case WireFormatLite::TYPE_GROUP:
        case WireFormatLite::TYPE_MESSAGE:
          GOOGLE_LOG(FATAL) << "Non-primitive types can't be packed.";
          break;
      }

      cached_size = result;
      if (result > 0) {
        result += io::CodedOutputStream::VarintSize32(result);
        result += io::CodedOutputStream::VarintSize32(
            WireFormatLite::MakeTag(number,
                WireFormatLite::WIRETYPE_LENGTH_DELIMITED));
      }
    } else {
      int tag_size = WireFormatLite::TagSize(number, real_type(type));

      switch (real_type(type)) {
#define HANDLE_TYPE(UPPERCASE, CAMELCASE, LOWERCASE)                        \
        case WireFormatLite::TYPE_##UPPERCASE:                              \
          result += tag_size * repeated_##LOWERCASE##_value->size();        \
          for (int i = 0; i < repeated_##LOWERCASE##_value->size(); i++) {  \
            result += WireFormatLite::CAMELCASE##Size(                      \
              repeated_##LOWERCASE##_value->Get(i));                        \
          }                                                                 \
          break

        HANDLE_TYPE(   INT32,    Int32,   int32);
        HANDLE_TYPE(   INT64,    Int64,   int64);
        HANDLE_TYPE(  UINT32,   UInt32,  uint32);
        HANDLE_TYPE(  UINT64,   UInt64,  uint64);
        HANDLE_TYPE(  SINT32,   SInt32,   int32);
        HANDLE_TYPE(  SINT64,   SInt64,   int64);
        HANDLE_TYPE(  STRING,   String,  string);
        HANDLE_TYPE(   BYTES,    Bytes,  string);
        HANDLE_TYPE(    ENUM,     Enum,    enum);
        HANDLE_TYPE(   GROUP,    Group, message);
        HANDLE_TYPE( MESSAGE,  Message, message);
#undef HANDLE_TYPE

        // Stuff with fixed size.
#define HANDLE_TYPE(UPPERCASE, CAMELCASE, LOWERCASE)                        \
        case WireFormatLite::TYPE_##UPPERCASE:                              \
          result += (tag_size + WireFormatLite::k##CAMELCASE##Size) *       \
                    repeated_##LOWERCASE##_value->size();                   \
          break
        HANDLE_TYPE( FIXED32,  Fixed32, uint32);
        HANDLE_TYPE( FIXED64,  Fixed64, uint64);
        HANDLE_TYPE(SFIXED32, SFixed32,  int32);
        HANDLE_TYPE(SFIXED64, SFixed64,  int64);
        HANDLE_TYPE(   FLOAT,    Float,  float);
        HANDLE_TYPE(  DOUBLE,   Double, double);
        HANDLE_TYPE(    BOOL,     Bool,   bool);
#undef HANDLE_TYPE
      }
    }
  } else if (!is_cleared) {
    result += WireFormatLite::TagSize(number, real_type(type));
    switch (real_type(type)) {
#define HANDLE_TYPE(UPPERCASE, CAMELCASE, LOWERCASE)                      \
      case WireFormatLite::TYPE_##UPPERCASE:                              \
        result += WireFormatLite::CAMELCASE##Size(LOWERCASE);             \
        break

      HANDLE_TYPE(   INT32,    Int32,    int32_value);
      HANDLE_TYPE(   INT64,    Int64,    int64_value);
      HANDLE_TYPE(  UINT32,   UInt32,   uint32_value);
      HANDLE_TYPE(  UINT64,   UInt64,   uint64_value);
      HANDLE_TYPE(  SINT32,   SInt32,    int32_value);
      HANDLE_TYPE(  SINT64,   SInt64,    int64_value);
      HANDLE_TYPE(  STRING,   String,  *string_value);
      HANDLE_TYPE(   BYTES,    Bytes,  *string_value);
      HANDLE_TYPE(    ENUM,     Enum,     enum_value);
      HANDLE_TYPE(   GROUP,    Group, *message_value);
#undef HANDLE_TYPE
      case WireFormatLite::TYPE_MESSAGE: {
        if (is_lazy) {
          int size = lazymessage_value->ByteSize();
          result += io::CodedOutputStream::VarintSize32(size) + size;
        } else {
          result += WireFormatLite::MessageSize(*message_value);
        }
        break;
      }

      // Stuff with fixed size.
#define HANDLE_TYPE(UPPERCASE, CAMELCASE)                                 \
      case WireFormatLite::TYPE_##UPPERCASE:                              \
        result += WireFormatLite::k##CAMELCASE##Size;                     \
        break
      HANDLE_TYPE( FIXED32,  Fixed32);
      HANDLE_TYPE( FIXED64,  Fixed64);
      HANDLE_TYPE(SFIXED32, SFixed32);
      HANDLE_TYPE(SFIXED64, SFixed64);
      HANDLE_TYPE(   FLOAT,    Float);
      HANDLE_TYPE(  DOUBLE,   Double);
      HANDLE_TYPE(    BOOL,     Bool);
#undef HANDLE_TYPE
    }
  }

  return result;
}

int ExtensionSet::Extension::GetSize() const {
  GOOGLE_DCHECK(is_repeated);
  switch (cpp_type(type)) {
#define HANDLE_TYPE(UPPERCASE, LOWERCASE)                        \
    case WireFormatLite::CPPTYPE_##UPPERCASE:                    \
      return repeated_##LOWERCASE##_value->size()

    HANDLE_TYPE(  INT32,   int32);
    HANDLE_TYPE(  INT64,   int64);
    HANDLE_TYPE( UINT32,  uint32);
    HANDLE_TYPE( UINT64,  uint64);
    HANDLE_TYPE(  FLOAT,   float);
    HANDLE_TYPE( DOUBLE,  double);
    HANDLE_TYPE(   BOOL,    bool);
    HANDLE_TYPE(   ENUM,    enum);
    HANDLE_TYPE( STRING,  string);
    HANDLE_TYPE(MESSAGE, message);
#undef HANDLE_TYPE
  }

  GOOGLE_LOG(FATAL) << "Can't get here.";
  return 0;
}

void ExtensionSet::Extension::Free() {
  if (is_repeated) {
    switch (cpp_type(type)) {
#define HANDLE_TYPE(UPPERCASE, LOWERCASE)                          \
      case WireFormatLite::CPPTYPE_##UPPERCASE:                    \
        delete repeated_##LOWERCASE##_value;                       \
        break

      HANDLE_TYPE(  INT32,   int32);
      HANDLE_TYPE(  INT64,   int64);
      HANDLE_TYPE( UINT32,  uint32);
      HANDLE_TYPE( UINT64,  uint64);
      HANDLE_TYPE(  FLOAT,   float);
      HANDLE_TYPE( DOUBLE,  double);
      HANDLE_TYPE(   BOOL,    bool);
      HANDLE_TYPE(   ENUM,    enum);
      HANDLE_TYPE( STRING,  string);
      HANDLE_TYPE(MESSAGE, message);
#undef HANDLE_TYPE
    }
  } else {
    switch (cpp_type(type)) {
      case WireFormatLite::CPPTYPE_STRING:
        delete string_value;
        break;
      case WireFormatLite::CPPTYPE_MESSAGE:
        if (is_lazy) {
          delete lazymessage_value;
        } else {
          delete message_value;
        }
        break;
      default:
        break;
    }
  }
}

// Defined in extension_set_heavy.cc.
// int ExtensionSet::Extension::SpaceUsedExcludingSelf() const

}  // namespace internal
}  // namespace protobuf
}  // namespace google
