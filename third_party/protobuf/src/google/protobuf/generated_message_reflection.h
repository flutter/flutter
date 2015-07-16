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
// This header is logically internal, but is made public because it is used
// from protocol-compiler-generated code, which may reside in other components.

#ifndef GOOGLE_PROTOBUF_GENERATED_MESSAGE_REFLECTION_H__
#define GOOGLE_PROTOBUF_GENERATED_MESSAGE_REFLECTION_H__

#include <string>
#include <vector>
#include <google/protobuf/stubs/common.h>
// TODO(jasonh): Remove this once the compiler change to directly include this
// is released to components.
#include <google/protobuf/generated_enum_reflection.h>
#include <google/protobuf/message.h>
#include <google/protobuf/unknown_field_set.h>


namespace google {
namespace upb {
namespace google_opensource {
class GMR_Handlers;
}  // namespace google_opensource
}  // namespace upb

namespace protobuf {
  class DescriptorPool;
}

namespace protobuf {
namespace internal {

// Defined in this file.
class GeneratedMessageReflection;

// Defined in other files.
class ExtensionSet;             // extension_set.h

// THIS CLASS IS NOT INTENDED FOR DIRECT USE.  It is intended for use
// by generated code.  This class is just a big hack that reduces code
// size.
//
// A GeneratedMessageReflection is an implementation of Reflection
// which expects all fields to be backed by simple variables located in
// memory.  The locations are given using a base pointer and a set of
// offsets.
//
// It is required that the user represents fields of each type in a standard
// way, so that GeneratedMessageReflection can cast the void* pointer to
// the appropriate type.  For primitive fields and string fields, each field
// should be represented using the obvious C++ primitive type.  Enums and
// Messages are different:
//  - Singular Message fields are stored as a pointer to a Message.  These
//    should start out NULL, except for in the default instance where they
//    should start out pointing to other default instances.
//  - Enum fields are stored as an int.  This int must always contain
//    a valid value, such that EnumDescriptor::FindValueByNumber() would
//    not return NULL.
//  - Repeated fields are stored as RepeatedFields or RepeatedPtrFields
//    of whatever type the individual field would be.  Strings and
//    Messages use RepeatedPtrFields while everything else uses
//    RepeatedFields.
class LIBPROTOBUF_EXPORT GeneratedMessageReflection : public Reflection {
 public:
  // Constructs a GeneratedMessageReflection.
  // Parameters:
  //   descriptor:    The descriptor for the message type being implemented.
  //   default_instance:  The default instance of the message.  This is only
  //                  used to obtain pointers to default instances of embedded
  //                  messages, which GetMessage() will return if the particular
  //                  sub-message has not been initialized yet.  (Thus, all
  //                  embedded message fields *must* have non-NULL pointers
  //                  in the default instance.)
  //   offsets:       An array of ints giving the byte offsets, relative to
  //                  the start of the message object, of each field.  These can
  //                  be computed at compile time using the
  //                  GOOGLE_PROTOBUF_GENERATED_MESSAGE_FIELD_OFFSET() macro, defined
  //                  below.
  //   has_bits_offset:  Offset in the message of an array of uint32s of size
  //                  descriptor->field_count()/32, rounded up.  This is a
  //                  bitfield where each bit indicates whether or not the
  //                  corresponding field of the message has been initialized.
  //                  The bit for field index i is obtained by the expression:
  //                    has_bits[i / 32] & (1 << (i % 32))
  //   unknown_fields_offset:  Offset in the message of the UnknownFieldSet for
  //                  the message.
  //   extensions_offset:  Offset in the message of the ExtensionSet for the
  //                  message, or -1 if the message type has no extension
  //                  ranges.
  //   pool:          DescriptorPool to search for extension definitions.  Only
  //                  used by FindKnownExtensionByName() and
  //                  FindKnownExtensionByNumber().
  //   factory:       MessageFactory to use to construct extension messages.
  //   object_size:   The size of a message object of this type, as measured
  //                  by sizeof().
  GeneratedMessageReflection(const Descriptor* descriptor,
                             const Message* default_instance,
                             const int offsets[],
                             int has_bits_offset,
                             int unknown_fields_offset,
                             int extensions_offset,
                             const DescriptorPool* pool,
                             MessageFactory* factory,
                             int object_size);
  ~GeneratedMessageReflection();

  // implements Reflection -------------------------------------------

  const UnknownFieldSet& GetUnknownFields(const Message& message) const;
  UnknownFieldSet* MutableUnknownFields(Message* message) const;

  int SpaceUsed(const Message& message) const;

  bool HasField(const Message& message, const FieldDescriptor* field) const;
  int FieldSize(const Message& message, const FieldDescriptor* field) const;
  void ClearField(Message* message, const FieldDescriptor* field) const;
  void RemoveLast(Message* message, const FieldDescriptor* field) const;
  Message* ReleaseLast(Message* message, const FieldDescriptor* field) const;
  void Swap(Message* message1, Message* message2) const;
  void SwapElements(Message* message, const FieldDescriptor* field,
            int index1, int index2) const;
  void ListFields(const Message& message,
                  vector<const FieldDescriptor*>* output) const;

  int32  GetInt32 (const Message& message,
                   const FieldDescriptor* field) const;
  int64  GetInt64 (const Message& message,
                   const FieldDescriptor* field) const;
  uint32 GetUInt32(const Message& message,
                   const FieldDescriptor* field) const;
  uint64 GetUInt64(const Message& message,
                   const FieldDescriptor* field) const;
  float  GetFloat (const Message& message,
                   const FieldDescriptor* field) const;
  double GetDouble(const Message& message,
                   const FieldDescriptor* field) const;
  bool   GetBool  (const Message& message,
                   const FieldDescriptor* field) const;
  string GetString(const Message& message,
                   const FieldDescriptor* field) const;
  const string& GetStringReference(const Message& message,
                                   const FieldDescriptor* field,
                                   string* scratch) const;
  const EnumValueDescriptor* GetEnum(const Message& message,
                                     const FieldDescriptor* field) const;
  const Message& GetMessage(const Message& message,
                            const FieldDescriptor* field,
                            MessageFactory* factory = NULL) const;

  void SetInt32 (Message* message,
                 const FieldDescriptor* field, int32  value) const;
  void SetInt64 (Message* message,
                 const FieldDescriptor* field, int64  value) const;
  void SetUInt32(Message* message,
                 const FieldDescriptor* field, uint32 value) const;
  void SetUInt64(Message* message,
                 const FieldDescriptor* field, uint64 value) const;
  void SetFloat (Message* message,
                 const FieldDescriptor* field, float  value) const;
  void SetDouble(Message* message,
                 const FieldDescriptor* field, double value) const;
  void SetBool  (Message* message,
                 const FieldDescriptor* field, bool   value) const;
  void SetString(Message* message,
                 const FieldDescriptor* field,
                 const string& value) const;
  void SetEnum  (Message* message, const FieldDescriptor* field,
                 const EnumValueDescriptor* value) const;
  Message* MutableMessage(Message* message, const FieldDescriptor* field,
                          MessageFactory* factory = NULL) const;
  Message* ReleaseMessage(Message* message, const FieldDescriptor* field,
                          MessageFactory* factory = NULL) const;

  int32  GetRepeatedInt32 (const Message& message,
                           const FieldDescriptor* field, int index) const;
  int64  GetRepeatedInt64 (const Message& message,
                           const FieldDescriptor* field, int index) const;
  uint32 GetRepeatedUInt32(const Message& message,
                           const FieldDescriptor* field, int index) const;
  uint64 GetRepeatedUInt64(const Message& message,
                           const FieldDescriptor* field, int index) const;
  float  GetRepeatedFloat (const Message& message,
                           const FieldDescriptor* field, int index) const;
  double GetRepeatedDouble(const Message& message,
                           const FieldDescriptor* field, int index) const;
  bool   GetRepeatedBool  (const Message& message,
                           const FieldDescriptor* field, int index) const;
  string GetRepeatedString(const Message& message,
                           const FieldDescriptor* field, int index) const;
  const string& GetRepeatedStringReference(const Message& message,
                                           const FieldDescriptor* field,
                                           int index, string* scratch) const;
  const EnumValueDescriptor* GetRepeatedEnum(const Message& message,
                                             const FieldDescriptor* field,
                                             int index) const;
  const Message& GetRepeatedMessage(const Message& message,
                                    const FieldDescriptor* field,
                                    int index) const;

  // Set the value of a field.
  void SetRepeatedInt32 (Message* message,
                         const FieldDescriptor* field, int index, int32  value) const;
  void SetRepeatedInt64 (Message* message,
                         const FieldDescriptor* field, int index, int64  value) const;
  void SetRepeatedUInt32(Message* message,
                         const FieldDescriptor* field, int index, uint32 value) const;
  void SetRepeatedUInt64(Message* message,
                         const FieldDescriptor* field, int index, uint64 value) const;
  void SetRepeatedFloat (Message* message,
                         const FieldDescriptor* field, int index, float  value) const;
  void SetRepeatedDouble(Message* message,
                         const FieldDescriptor* field, int index, double value) const;
  void SetRepeatedBool  (Message* message,
                         const FieldDescriptor* field, int index, bool   value) const;
  void SetRepeatedString(Message* message,
                         const FieldDescriptor* field, int index,
                         const string& value) const;
  void SetRepeatedEnum(Message* message, const FieldDescriptor* field,
                       int index, const EnumValueDescriptor* value) const;
  // Get a mutable pointer to a field with a message type.
  Message* MutableRepeatedMessage(Message* message,
                                  const FieldDescriptor* field,
                                  int index) const;

  void AddInt32 (Message* message,
                 const FieldDescriptor* field, int32  value) const;
  void AddInt64 (Message* message,
                 const FieldDescriptor* field, int64  value) const;
  void AddUInt32(Message* message,
                 const FieldDescriptor* field, uint32 value) const;
  void AddUInt64(Message* message,
                 const FieldDescriptor* field, uint64 value) const;
  void AddFloat (Message* message,
                 const FieldDescriptor* field, float  value) const;
  void AddDouble(Message* message,
                 const FieldDescriptor* field, double value) const;
  void AddBool  (Message* message,
                 const FieldDescriptor* field, bool   value) const;
  void AddString(Message* message,
                 const FieldDescriptor* field, const string& value) const;
  void AddEnum(Message* message,
               const FieldDescriptor* field,
               const EnumValueDescriptor* value) const;
  Message* AddMessage(Message* message, const FieldDescriptor* field,
                      MessageFactory* factory = NULL) const;

  const FieldDescriptor* FindKnownExtensionByName(const string& name) const;
  const FieldDescriptor* FindKnownExtensionByNumber(int number) const;

 protected:
  virtual void* MutableRawRepeatedField(
      Message* message, const FieldDescriptor* field, FieldDescriptor::CppType,
      int ctype, const Descriptor* desc) const;

 private:
  friend class GeneratedMessage;

  // To parse directly into a proto2 generated class, the class GMR_Handlers
  // needs access to member offsets and hasbits.
  friend class LIBPROTOBUF_EXPORT upb::google_opensource::GMR_Handlers;

  const Descriptor* descriptor_;
  const Message* default_instance_;
  const int* offsets_;

  int has_bits_offset_;
  int unknown_fields_offset_;
  int extensions_offset_;
  int object_size_;

  const DescriptorPool* descriptor_pool_;
  MessageFactory* message_factory_;

  template <typename Type>
  inline const Type& GetRaw(const Message& message,
                            const FieldDescriptor* field) const;
  template <typename Type>
  inline Type* MutableRaw(Message* message,
                          const FieldDescriptor* field) const;
  template <typename Type>
  inline const Type& DefaultRaw(const FieldDescriptor* field) const;

  inline const uint32* GetHasBits(const Message& message) const;
  inline uint32* MutableHasBits(Message* message) const;
  inline const ExtensionSet& GetExtensionSet(const Message& message) const;
  inline ExtensionSet* MutableExtensionSet(Message* message) const;

  inline bool HasBit(const Message& message,
                     const FieldDescriptor* field) const;
  inline void SetBit(Message* message,
                     const FieldDescriptor* field) const;
  inline void ClearBit(Message* message,
                       const FieldDescriptor* field) const;

  template <typename Type>
  inline const Type& GetField(const Message& message,
                              const FieldDescriptor* field) const;
  template <typename Type>
  inline void SetField(Message* message,
                       const FieldDescriptor* field, const Type& value) const;
  template <typename Type>
  inline Type* MutableField(Message* message,
                            const FieldDescriptor* field) const;
  template <typename Type>
  inline const Type& GetRepeatedField(const Message& message,
                                      const FieldDescriptor* field,
                                      int index) const;
  template <typename Type>
  inline const Type& GetRepeatedPtrField(const Message& message,
                                         const FieldDescriptor* field,
                                         int index) const;
  template <typename Type>
  inline void SetRepeatedField(Message* message,
                               const FieldDescriptor* field, int index,
                               Type value) const;
  template <typename Type>
  inline Type* MutableRepeatedField(Message* message,
                                    const FieldDescriptor* field,
                                    int index) const;
  template <typename Type>
  inline void AddField(Message* message,
                       const FieldDescriptor* field, const Type& value) const;
  template <typename Type>
  inline Type* AddField(Message* message,
                        const FieldDescriptor* field) const;

  int GetExtensionNumberOrDie(const Descriptor* type) const;

  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(GeneratedMessageReflection);
};

// Returns the offset of the given field within the given aggregate type.
// This is equivalent to the ANSI C offsetof() macro.  However, according
// to the C++ standard, offsetof() only works on POD types, and GCC
// enforces this requirement with a warning.  In practice, this rule is
// unnecessarily strict; there is probably no compiler or platform on
// which the offsets of the direct fields of a class are non-constant.
// Fields inherited from superclasses *can* have non-constant offsets,
// but that's not what this macro will be used for.
//
// Note that we calculate relative to the pointer value 16 here since if we
// just use zero, GCC complains about dereferencing a NULL pointer.  We
// choose 16 rather than some other number just in case the compiler would
// be confused by an unaligned pointer.
#define GOOGLE_PROTOBUF_GENERATED_MESSAGE_FIELD_OFFSET(TYPE, FIELD)    \
  static_cast<int>(                                           \
    reinterpret_cast<const char*>(                            \
      &reinterpret_cast<const TYPE*>(16)->FIELD) -            \
    reinterpret_cast<const char*>(16))

// There are some places in proto2 where dynamic_cast would be useful as an
// optimization.  For example, take Message::MergeFrom(const Message& other).
// For a given generated message FooMessage, we generate these two methods:
//   void MergeFrom(const FooMessage& other);
//   void MergeFrom(const Message& other);
// The former method can be implemented directly in terms of FooMessage's
// inline accessors, but the latter method must work with the reflection
// interface.  However, if the parameter to the latter method is actually of
// type FooMessage, then we'd like to be able to just call the other method
// as an optimization.  So, we use dynamic_cast to check this.
//
// That said, dynamic_cast requires RTTI, which many people like to disable
// for performance and code size reasons.  When RTTI is not available, we
// still need to produce correct results.  So, in this case we have to fall
// back to using reflection, which is what we would have done anyway if the
// objects were not of the exact same class.
//
// dynamic_cast_if_available() implements this logic.  If RTTI is
// enabled, it does a dynamic_cast.  If RTTI is disabled, it just returns
// NULL.
//
// If you need to compile without RTTI, simply #define GOOGLE_PROTOBUF_NO_RTTI.
// On MSVC, this should be detected automatically.
template<typename To, typename From>
inline To dynamic_cast_if_available(From from) {
#if defined(GOOGLE_PROTOBUF_NO_RTTI) || (defined(_MSC_VER)&&!defined(_CPPRTTI))
  return NULL;
#else
  return dynamic_cast<To>(from);
#endif
}

}  // namespace internal
}  // namespace protobuf

}  // namespace google
#endif  // GOOGLE_PROTOBUF_GENERATED_MESSAGE_REFLECTION_H__
