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
//         atenasio@google.com (Chris Atenasio) (ZigZag transform)
//  Based on original Protocol Buffers design by
//  Sanjay Ghemawat, Jeff Dean, and others.
//
// This header is logically internal, but is made public because it is used
// from protocol-compiler-generated code, which may reside in other components.

#ifndef GOOGLE_PROTOBUF_WIRE_FORMAT_H__
#define GOOGLE_PROTOBUF_WIRE_FORMAT_H__

#include <string>
#include <google/protobuf/stubs/common.h>
#include <google/protobuf/descriptor.pb.h>
#include <google/protobuf/descriptor.h>
#include <google/protobuf/message.h>
#include <google/protobuf/wire_format_lite.h>

// Do UTF-8 validation on string type in Debug build only
#ifndef NDEBUG
#define GOOGLE_PROTOBUF_UTF8_VALIDATION_ENABLED
#endif

namespace google {
namespace protobuf {
  namespace io {
    class CodedInputStream;      // coded_stream.h
    class CodedOutputStream;     // coded_stream.h
  }
  class UnknownFieldSet;         // unknown_field_set.h
}

namespace protobuf {
namespace internal {

// This class is for internal use by the protocol buffer library and by
// protocol-complier-generated message classes.  It must not be called
// directly by clients.
//
// This class contains code for implementing the binary protocol buffer
// wire format via reflection.  The WireFormatLite class implements the
// non-reflection based routines.
//
// This class is really a namespace that contains only static methods
class LIBPROTOBUF_EXPORT WireFormat {
 public:

  // Given a field return its WireType
  static inline WireFormatLite::WireType WireTypeForField(
      const FieldDescriptor* field);

  // Given a FieldSescriptor::Type return its WireType
  static inline WireFormatLite::WireType WireTypeForFieldType(
      FieldDescriptor::Type type);

  // Compute the byte size of a tag.  For groups, this includes both the start
  // and end tags.
  static inline int TagSize(int field_number, FieldDescriptor::Type type);

  // These procedures can be used to implement the methods of Message which
  // handle parsing and serialization of the protocol buffer wire format
  // using only the Reflection interface.  When you ask the protocol
  // compiler to optimize for code size rather than speed, it will implement
  // those methods in terms of these procedures.  Of course, these are much
  // slower than the specialized implementations which the protocol compiler
  // generates when told to optimize for speed.

  // Read a message in protocol buffer wire format.
  //
  // This procedure reads either to the end of the input stream or through
  // a WIRETYPE_END_GROUP tag ending the message, whichever comes first.
  // It returns false if the input is invalid.
  //
  // Required fields are NOT checked by this method.  You must call
  // IsInitialized() on the resulting message yourself.
  static bool ParseAndMergePartial(io::CodedInputStream* input,
                                   Message* message);

  // Serialize a message in protocol buffer wire format.
  //
  // Any embedded messages within the message must have their correct sizes
  // cached.  However, the top-level message need not; its size is passed as
  // a parameter to this procedure.
  //
  // These return false iff the underlying stream returns a write error.
  static void SerializeWithCachedSizes(
      const Message& message,
      int size, io::CodedOutputStream* output);

  // Implements Message::ByteSize() via reflection.  WARNING:  The result
  // of this method is *not* cached anywhere.  However, all embedded messages
  // will have their ByteSize() methods called, so their sizes will be cached.
  // Therefore, calling this method is sufficient to allow you to call
  // WireFormat::SerializeWithCachedSizes() on the same object.
  static int ByteSize(const Message& message);


  // Helper functions for encoding and decoding tags.  (Inlined below and in
  // _inl.h)
  //
  // This is different from MakeTag(field->number(), field->type()) in the case
  // of packed repeated fields.
  static uint32 MakeTag(const FieldDescriptor* field);

  // Parse a single field.  The input should start out positioned immidately
  // after the tag.
  static bool ParseAndMergeField(
      uint32 tag,
      const FieldDescriptor* field,        // May be NULL for unknown
      Message* message,
      io::CodedInputStream* input);

  // Serialize a single field.
  static void SerializeFieldWithCachedSizes(
      const FieldDescriptor* field,        // Cannot be NULL
      const Message& message,
      io::CodedOutputStream* output);

  // Compute size of a single field.  If the field is a message type, this
  // will call ByteSize() for the embedded message, insuring that it caches
  // its size.
  static int FieldByteSize(
      const FieldDescriptor* field,        // Cannot be NULL
      const Message& message);

  // Parse/serialize a MessageSet::Item group.  Used with messages that use
  // opion message_set_wire_format = true.
  static bool ParseAndMergeMessageSetItem(
      io::CodedInputStream* input,
      Message* message);
  static void SerializeMessageSetItemWithCachedSizes(
      const FieldDescriptor* field,
      const Message& message,
      io::CodedOutputStream* output);
  static int MessageSetItemByteSize(
      const FieldDescriptor* field,
      const Message& message);

  // Computes the byte size of a field, excluding tags. For packed fields, it
  // only includes the size of the raw data, and not the size of the total
  // length, but for other length-delimited types, the size of the length is
  // included.
  static int FieldDataOnlyByteSize(
      const FieldDescriptor* field,        // Cannot be NULL
      const Message& message);

  enum Operation {
    PARSE,
    SERIALIZE,
  };

  // Verifies that a string field is valid UTF8, logging an error if not.
  static void VerifyUTF8String(const char* data, int size, Operation op);

 private:
  // Verifies that a string field is valid UTF8, logging an error if not.
  static void VerifyUTF8StringFallback(
      const char* data,
      int size,
      Operation op);



  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(WireFormat);
};

// inline methods ====================================================

inline WireFormatLite::WireType WireFormat::WireTypeForField(
    const FieldDescriptor* field) {
  if (field->options().packed()) {
    return WireFormatLite::WIRETYPE_LENGTH_DELIMITED;
  } else {
    return WireTypeForFieldType(field->type());
  }
}

inline WireFormatLite::WireType WireFormat::WireTypeForFieldType(
    FieldDescriptor::Type type) {
  // Some compilers don't like enum -> enum casts, so we implicit_cast to
  // int first.
  return WireFormatLite::WireTypeForFieldType(
      static_cast<WireFormatLite::FieldType>(
        implicit_cast<int>(type)));
}

inline uint32 WireFormat::MakeTag(const FieldDescriptor* field) {
  return WireFormatLite::MakeTag(field->number(), WireTypeForField(field));
}

inline int WireFormat::TagSize(int field_number, FieldDescriptor::Type type) {
  // Some compilers don't like enum -> enum casts, so we implicit_cast to
  // int first.
  return WireFormatLite::TagSize(field_number,
      static_cast<WireFormatLite::FieldType>(
        implicit_cast<int>(type)));
}

inline void WireFormat::VerifyUTF8String(const char* data, int size,
    WireFormat::Operation op) {
#ifdef GOOGLE_PROTOBUF_UTF8_VALIDATION_ENABLED
  WireFormat::VerifyUTF8StringFallback(data, size, op);
#else
  // Avoid the compiler warning about unsued variables.
  (void)data; (void)size; (void)op;
#endif
}


}  // namespace internal
}  // namespace protobuf

}  // namespace google
#endif  // GOOGLE_PROTOBUF_WIRE_FORMAT_H__
