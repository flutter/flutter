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
//         wink@google.com (Wink Saville) (refactored from wire_format.h)
//  Based on original Protocol Buffers design by
//  Sanjay Ghemawat, Jeff Dean, and others.

#ifndef GOOGLE_PROTOBUF_WIRE_FORMAT_LITE_INL_H__
#define GOOGLE_PROTOBUF_WIRE_FORMAT_LITE_INL_H__

#include <string>
#include <google/protobuf/stubs/common.h>
#include <google/protobuf/message_lite.h>
#include <google/protobuf/repeated_field.h>
#include <google/protobuf/wire_format_lite.h>
#include <google/protobuf/io/coded_stream.h>


namespace google {
namespace protobuf {
namespace internal {

// Implementation details of ReadPrimitive.

template <>
inline bool WireFormatLite::ReadPrimitive<int32, WireFormatLite::TYPE_INT32>(
    io::CodedInputStream* input,
    int32* value) {
  uint32 temp;
  if (!input->ReadVarint32(&temp)) return false;
  *value = static_cast<int32>(temp);
  return true;
}
template <>
inline bool WireFormatLite::ReadPrimitive<int64, WireFormatLite::TYPE_INT64>(
    io::CodedInputStream* input,
    int64* value) {
  uint64 temp;
  if (!input->ReadVarint64(&temp)) return false;
  *value = static_cast<int64>(temp);
  return true;
}
template <>
inline bool WireFormatLite::ReadPrimitive<uint32, WireFormatLite::TYPE_UINT32>(
    io::CodedInputStream* input,
    uint32* value) {
  return input->ReadVarint32(value);
}
template <>
inline bool WireFormatLite::ReadPrimitive<uint64, WireFormatLite::TYPE_UINT64>(
    io::CodedInputStream* input,
    uint64* value) {
  return input->ReadVarint64(value);
}
template <>
inline bool WireFormatLite::ReadPrimitive<int32, WireFormatLite::TYPE_SINT32>(
    io::CodedInputStream* input,
    int32* value) {
  uint32 temp;
  if (!input->ReadVarint32(&temp)) return false;
  *value = ZigZagDecode32(temp);
  return true;
}
template <>
inline bool WireFormatLite::ReadPrimitive<int64, WireFormatLite::TYPE_SINT64>(
    io::CodedInputStream* input,
    int64* value) {
  uint64 temp;
  if (!input->ReadVarint64(&temp)) return false;
  *value = ZigZagDecode64(temp);
  return true;
}
template <>
inline bool WireFormatLite::ReadPrimitive<uint32, WireFormatLite::TYPE_FIXED32>(
    io::CodedInputStream* input,
    uint32* value) {
  return input->ReadLittleEndian32(value);
}
template <>
inline bool WireFormatLite::ReadPrimitive<uint64, WireFormatLite::TYPE_FIXED64>(
    io::CodedInputStream* input,
    uint64* value) {
  return input->ReadLittleEndian64(value);
}
template <>
inline bool WireFormatLite::ReadPrimitive<int32, WireFormatLite::TYPE_SFIXED32>(
    io::CodedInputStream* input,
    int32* value) {
  uint32 temp;
  if (!input->ReadLittleEndian32(&temp)) return false;
  *value = static_cast<int32>(temp);
  return true;
}
template <>
inline bool WireFormatLite::ReadPrimitive<int64, WireFormatLite::TYPE_SFIXED64>(
    io::CodedInputStream* input,
    int64* value) {
  uint64 temp;
  if (!input->ReadLittleEndian64(&temp)) return false;
  *value = static_cast<int64>(temp);
  return true;
}
template <>
inline bool WireFormatLite::ReadPrimitive<float, WireFormatLite::TYPE_FLOAT>(
    io::CodedInputStream* input,
    float* value) {
  uint32 temp;
  if (!input->ReadLittleEndian32(&temp)) return false;
  *value = DecodeFloat(temp);
  return true;
}
template <>
inline bool WireFormatLite::ReadPrimitive<double, WireFormatLite::TYPE_DOUBLE>(
    io::CodedInputStream* input,
    double* value) {
  uint64 temp;
  if (!input->ReadLittleEndian64(&temp)) return false;
  *value = DecodeDouble(temp);
  return true;
}
template <>
inline bool WireFormatLite::ReadPrimitive<bool, WireFormatLite::TYPE_BOOL>(
    io::CodedInputStream* input,
    bool* value) {
  uint32 temp;
  if (!input->ReadVarint32(&temp)) return false;
  *value = temp != 0;
  return true;
}
template <>
inline bool WireFormatLite::ReadPrimitive<int, WireFormatLite::TYPE_ENUM>(
    io::CodedInputStream* input,
    int* value) {
  uint32 temp;
  if (!input->ReadVarint32(&temp)) return false;
  *value = static_cast<int>(temp);
  return true;
}

template <>
inline const uint8* WireFormatLite::ReadPrimitiveFromArray<
  uint32, WireFormatLite::TYPE_FIXED32>(
    const uint8* buffer,
    uint32* value) {
  return io::CodedInputStream::ReadLittleEndian32FromArray(buffer, value);
}
template <>
inline const uint8* WireFormatLite::ReadPrimitiveFromArray<
  uint64, WireFormatLite::TYPE_FIXED64>(
    const uint8* buffer,
    uint64* value) {
  return io::CodedInputStream::ReadLittleEndian64FromArray(buffer, value);
}
template <>
inline const uint8* WireFormatLite::ReadPrimitiveFromArray<
  int32, WireFormatLite::TYPE_SFIXED32>(
    const uint8* buffer,
    int32* value) {
  uint32 temp;
  buffer = io::CodedInputStream::ReadLittleEndian32FromArray(buffer, &temp);
  *value = static_cast<int32>(temp);
  return buffer;
}
template <>
inline const uint8* WireFormatLite::ReadPrimitiveFromArray<
  int64, WireFormatLite::TYPE_SFIXED64>(
    const uint8* buffer,
    int64* value) {
  uint64 temp;
  buffer = io::CodedInputStream::ReadLittleEndian64FromArray(buffer, &temp);
  *value = static_cast<int64>(temp);
  return buffer;
}
template <>
inline const uint8* WireFormatLite::ReadPrimitiveFromArray<
  float, WireFormatLite::TYPE_FLOAT>(
    const uint8* buffer,
    float* value) {
  uint32 temp;
  buffer = io::CodedInputStream::ReadLittleEndian32FromArray(buffer, &temp);
  *value = DecodeFloat(temp);
  return buffer;
}
template <>
inline const uint8* WireFormatLite::ReadPrimitiveFromArray<
  double, WireFormatLite::TYPE_DOUBLE>(
    const uint8* buffer,
    double* value) {
  uint64 temp;
  buffer = io::CodedInputStream::ReadLittleEndian64FromArray(buffer, &temp);
  *value = DecodeDouble(temp);
  return buffer;
}

template <typename CType, enum WireFormatLite::FieldType DeclaredType>
inline bool WireFormatLite::ReadRepeatedPrimitive(int, // tag_size, unused.
                                               uint32 tag,
                                               io::CodedInputStream* input,
                                               RepeatedField<CType>* values) {
  CType value;
  if (!ReadPrimitive<CType, DeclaredType>(input, &value)) return false;
  values->Add(value);
  int elements_already_reserved = values->Capacity() - values->size();
  while (elements_already_reserved > 0 && input->ExpectTag(tag)) {
    if (!ReadPrimitive<CType, DeclaredType>(input, &value)) return false;
    values->AddAlreadyReserved(value);
    elements_already_reserved--;
  }
  return true;
}

template <typename CType, enum WireFormatLite::FieldType DeclaredType>
inline bool WireFormatLite::ReadRepeatedFixedSizePrimitive(
    int tag_size,
    uint32 tag,
    io::CodedInputStream* input,
    RepeatedField<CType>* values) {
  GOOGLE_DCHECK_EQ(UInt32Size(tag), tag_size);
  CType value;
  if (!ReadPrimitive<CType, DeclaredType>(input, &value))
    return false;
  values->Add(value);

  // For fixed size values, repeated values can be read more quickly by
  // reading directly from a raw array.
  //
  // We can get a tight loop by only reading as many elements as can be
  // added to the RepeatedField without having to do any resizing. Additionally,
  // we only try to read as many elements as are available from the current
  // buffer space. Doing so avoids having to perform boundary checks when
  // reading the value: the maximum number of elements that can be read is
  // known outside of the loop.
  const void* void_pointer;
  int size;
  input->GetDirectBufferPointerInline(&void_pointer, &size);
  if (size > 0) {
    const uint8* buffer = reinterpret_cast<const uint8*>(void_pointer);
    // The number of bytes each type occupies on the wire.
    const int per_value_size = tag_size + sizeof(value);

    int elements_available = min(values->Capacity() - values->size(),
                                 size / per_value_size);
    int num_read = 0;
    while (num_read < elements_available &&
           (buffer = io::CodedInputStream::ExpectTagFromArray(
               buffer, tag)) != NULL) {
      buffer = ReadPrimitiveFromArray<CType, DeclaredType>(buffer, &value);
      values->AddAlreadyReserved(value);
      ++num_read;
    }
    const int read_bytes = num_read * per_value_size;
    if (read_bytes > 0) {
      input->Skip(read_bytes);
    }
  }
  return true;
}

// Specializations of ReadRepeatedPrimitive for the fixed size types, which use 
// the optimized code path.
#define READ_REPEATED_FIXED_SIZE_PRIMITIVE(CPPTYPE, DECLARED_TYPE)             \
template <>                                                                    \
inline bool WireFormatLite::ReadRepeatedPrimitive<                             \
  CPPTYPE, WireFormatLite::DECLARED_TYPE>(                                     \
    int tag_size,                                                              \
    uint32 tag,                                                                \
    io::CodedInputStream* input,                                               \
    RepeatedField<CPPTYPE>* values) {                                          \
  return ReadRepeatedFixedSizePrimitive<                                       \
    CPPTYPE, WireFormatLite::DECLARED_TYPE>(                                   \
      tag_size, tag, input, values);                                           \
}

READ_REPEATED_FIXED_SIZE_PRIMITIVE(uint32, TYPE_FIXED32)
READ_REPEATED_FIXED_SIZE_PRIMITIVE(uint64, TYPE_FIXED64)
READ_REPEATED_FIXED_SIZE_PRIMITIVE(int32, TYPE_SFIXED32)
READ_REPEATED_FIXED_SIZE_PRIMITIVE(int64, TYPE_SFIXED64)
READ_REPEATED_FIXED_SIZE_PRIMITIVE(float, TYPE_FLOAT)
READ_REPEATED_FIXED_SIZE_PRIMITIVE(double, TYPE_DOUBLE)

#undef READ_REPEATED_FIXED_SIZE_PRIMITIVE

template <typename CType, enum WireFormatLite::FieldType DeclaredType>
bool WireFormatLite::ReadRepeatedPrimitiveNoInline(
    int tag_size,
    uint32 tag,
    io::CodedInputStream* input,
    RepeatedField<CType>* value) {
  return ReadRepeatedPrimitive<CType, DeclaredType>(
      tag_size, tag, input, value);
}

template <typename CType, enum WireFormatLite::FieldType DeclaredType>
inline bool WireFormatLite::ReadPackedPrimitive(io::CodedInputStream* input,
                                                RepeatedField<CType>* values) {
  uint32 length;
  if (!input->ReadVarint32(&length)) return false;
  io::CodedInputStream::Limit limit = input->PushLimit(length);
  while (input->BytesUntilLimit() > 0) {
    CType value;
    if (!ReadPrimitive<CType, DeclaredType>(input, &value)) return false;
    values->Add(value);
  }
  input->PopLimit(limit);
  return true;
}

template <typename CType, enum WireFormatLite::FieldType DeclaredType>
bool WireFormatLite::ReadPackedPrimitiveNoInline(io::CodedInputStream* input,
                                                 RepeatedField<CType>* values) {
  return ReadPackedPrimitive<CType, DeclaredType>(input, values);
}


inline bool WireFormatLite::ReadGroup(int field_number,
                                      io::CodedInputStream* input,
                                      MessageLite* value) {
  if (!input->IncrementRecursionDepth()) return false;
  if (!value->MergePartialFromCodedStream(input)) return false;
  input->DecrementRecursionDepth();
  // Make sure the last thing read was an end tag for this group.
  if (!input->LastTagWas(MakeTag(field_number, WIRETYPE_END_GROUP))) {
    return false;
  }
  return true;
}
inline bool WireFormatLite::ReadMessage(io::CodedInputStream* input,
                                        MessageLite* value) {
  uint32 length;
  if (!input->ReadVarint32(&length)) return false;
  if (!input->IncrementRecursionDepth()) return false;
  io::CodedInputStream::Limit limit = input->PushLimit(length);
  if (!value->MergePartialFromCodedStream(input)) return false;
  // Make sure that parsing stopped when the limit was hit, not at an endgroup
  // tag.
  if (!input->ConsumedEntireMessage()) return false;
  input->PopLimit(limit);
  input->DecrementRecursionDepth();
  return true;
}

// We name the template parameter something long and extremely unlikely to occur
// elsewhere because a *qualified* member access expression designed to avoid
// virtual dispatch, C++03 [basic.lookup.classref] 3.4.5/4 requires that the
// name of the qualifying class to be looked up both in the context of the full
// expression (finding the template parameter) and in the context of the object
// whose member we are accessing. This could potentially find a nested type
// within that object. The standard goes on to require these names to refer to
// the same entity, which this collision would violate. The lack of a safe way
// to avoid this collision appears to be a defect in the standard, but until it
// is corrected, we choose the name to avoid accidental collisions.
template<typename MessageType_WorkAroundCppLookupDefect>
inline bool WireFormatLite::ReadGroupNoVirtual(
    int field_number, io::CodedInputStream* input,
    MessageType_WorkAroundCppLookupDefect* value) {
  if (!input->IncrementRecursionDepth()) return false;
  if (!value->
      MessageType_WorkAroundCppLookupDefect::MergePartialFromCodedStream(input))
    return false;
  input->DecrementRecursionDepth();
  // Make sure the last thing read was an end tag for this group.
  if (!input->LastTagWas(MakeTag(field_number, WIRETYPE_END_GROUP))) {
    return false;
  }
  return true;
}
template<typename MessageType_WorkAroundCppLookupDefect>
inline bool WireFormatLite::ReadMessageNoVirtual(
    io::CodedInputStream* input, MessageType_WorkAroundCppLookupDefect* value) {
  uint32 length;
  if (!input->ReadVarint32(&length)) return false;
  if (!input->IncrementRecursionDepth()) return false;
  io::CodedInputStream::Limit limit = input->PushLimit(length);
  if (!value->
      MessageType_WorkAroundCppLookupDefect::MergePartialFromCodedStream(input))
    return false;
  // Make sure that parsing stopped when the limit was hit, not at an endgroup
  // tag.
  if (!input->ConsumedEntireMessage()) return false;
  input->PopLimit(limit);
  input->DecrementRecursionDepth();
  return true;
}

// ===================================================================

inline void WireFormatLite::WriteTag(int field_number, WireType type,
                                     io::CodedOutputStream* output) {
  output->WriteTag(MakeTag(field_number, type));
}

inline void WireFormatLite::WriteInt32NoTag(int32 value,
                                            io::CodedOutputStream* output) {
  output->WriteVarint32SignExtended(value);
}
inline void WireFormatLite::WriteInt64NoTag(int64 value,
                                            io::CodedOutputStream* output) {
  output->WriteVarint64(static_cast<uint64>(value));
}
inline void WireFormatLite::WriteUInt32NoTag(uint32 value,
                                             io::CodedOutputStream* output) {
  output->WriteVarint32(value);
}
inline void WireFormatLite::WriteUInt64NoTag(uint64 value,
                                             io::CodedOutputStream* output) {
  output->WriteVarint64(value);
}
inline void WireFormatLite::WriteSInt32NoTag(int32 value,
                                             io::CodedOutputStream* output) {
  output->WriteVarint32(ZigZagEncode32(value));
}
inline void WireFormatLite::WriteSInt64NoTag(int64 value,
                                             io::CodedOutputStream* output) {
  output->WriteVarint64(ZigZagEncode64(value));
}
inline void WireFormatLite::WriteFixed32NoTag(uint32 value,
                                              io::CodedOutputStream* output) {
  output->WriteLittleEndian32(value);
}
inline void WireFormatLite::WriteFixed64NoTag(uint64 value,
                                              io::CodedOutputStream* output) {
  output->WriteLittleEndian64(value);
}
inline void WireFormatLite::WriteSFixed32NoTag(int32 value,
                                               io::CodedOutputStream* output) {
  output->WriteLittleEndian32(static_cast<uint32>(value));
}
inline void WireFormatLite::WriteSFixed64NoTag(int64 value,
                                               io::CodedOutputStream* output) {
  output->WriteLittleEndian64(static_cast<uint64>(value));
}
inline void WireFormatLite::WriteFloatNoTag(float value,
                                            io::CodedOutputStream* output) {
  output->WriteLittleEndian32(EncodeFloat(value));
}
inline void WireFormatLite::WriteDoubleNoTag(double value,
                                             io::CodedOutputStream* output) {
  output->WriteLittleEndian64(EncodeDouble(value));
}
inline void WireFormatLite::WriteBoolNoTag(bool value,
                                           io::CodedOutputStream* output) {
  output->WriteVarint32(value ? 1 : 0);
}
inline void WireFormatLite::WriteEnumNoTag(int value,
                                           io::CodedOutputStream* output) {
  output->WriteVarint32SignExtended(value);
}

// See comment on ReadGroupNoVirtual to understand the need for this template
// parameter name.
template<typename MessageType_WorkAroundCppLookupDefect>
inline void WireFormatLite::WriteGroupNoVirtual(
    int field_number, const MessageType_WorkAroundCppLookupDefect& value,
    io::CodedOutputStream* output) {
  WriteTag(field_number, WIRETYPE_START_GROUP, output);
  value.MessageType_WorkAroundCppLookupDefect::SerializeWithCachedSizes(output);
  WriteTag(field_number, WIRETYPE_END_GROUP, output);
}
template<typename MessageType_WorkAroundCppLookupDefect>
inline void WireFormatLite::WriteMessageNoVirtual(
    int field_number, const MessageType_WorkAroundCppLookupDefect& value,
    io::CodedOutputStream* output) {
  WriteTag(field_number, WIRETYPE_LENGTH_DELIMITED, output);
  output->WriteVarint32(
      value.MessageType_WorkAroundCppLookupDefect::GetCachedSize());
  value.MessageType_WorkAroundCppLookupDefect::SerializeWithCachedSizes(output);
}

// ===================================================================

inline uint8* WireFormatLite::WriteTagToArray(int field_number,
                                              WireType type,
                                              uint8* target) {
  return io::CodedOutputStream::WriteTagToArray(MakeTag(field_number, type),
                                                target);
}

inline uint8* WireFormatLite::WriteInt32NoTagToArray(int32 value,
                                                     uint8* target) {
  return io::CodedOutputStream::WriteVarint32SignExtendedToArray(value, target);
}
inline uint8* WireFormatLite::WriteInt64NoTagToArray(int64 value,
                                                     uint8* target) {
  return io::CodedOutputStream::WriteVarint64ToArray(
      static_cast<uint64>(value), target);
}
inline uint8* WireFormatLite::WriteUInt32NoTagToArray(uint32 value,
                                                      uint8* target) {
  return io::CodedOutputStream::WriteVarint32ToArray(value, target);
}
inline uint8* WireFormatLite::WriteUInt64NoTagToArray(uint64 value,
                                                      uint8* target) {
  return io::CodedOutputStream::WriteVarint64ToArray(value, target);
}
inline uint8* WireFormatLite::WriteSInt32NoTagToArray(int32 value,
                                                      uint8* target) {
  return io::CodedOutputStream::WriteVarint32ToArray(ZigZagEncode32(value),
                                                     target);
}
inline uint8* WireFormatLite::WriteSInt64NoTagToArray(int64 value,
                                                      uint8* target) {
  return io::CodedOutputStream::WriteVarint64ToArray(ZigZagEncode64(value),
                                                     target);
}
inline uint8* WireFormatLite::WriteFixed32NoTagToArray(uint32 value,
                                                       uint8* target) {
  return io::CodedOutputStream::WriteLittleEndian32ToArray(value, target);
}
inline uint8* WireFormatLite::WriteFixed64NoTagToArray(uint64 value,
                                                       uint8* target) {
  return io::CodedOutputStream::WriteLittleEndian64ToArray(value, target);
}
inline uint8* WireFormatLite::WriteSFixed32NoTagToArray(int32 value,
                                                        uint8* target) {
  return io::CodedOutputStream::WriteLittleEndian32ToArray(
      static_cast<uint32>(value), target);
}
inline uint8* WireFormatLite::WriteSFixed64NoTagToArray(int64 value,
                                                        uint8* target) {
  return io::CodedOutputStream::WriteLittleEndian64ToArray(
      static_cast<uint64>(value), target);
}
inline uint8* WireFormatLite::WriteFloatNoTagToArray(float value,
                                                     uint8* target) {
  return io::CodedOutputStream::WriteLittleEndian32ToArray(EncodeFloat(value),
                                                           target);
}
inline uint8* WireFormatLite::WriteDoubleNoTagToArray(double value,
                                                      uint8* target) {
  return io::CodedOutputStream::WriteLittleEndian64ToArray(EncodeDouble(value),
                                                           target);
}
inline uint8* WireFormatLite::WriteBoolNoTagToArray(bool value,
                                                    uint8* target) {
  return io::CodedOutputStream::WriteVarint32ToArray(value ? 1 : 0, target);
}
inline uint8* WireFormatLite::WriteEnumNoTagToArray(int value,
                                                    uint8* target) {
  return io::CodedOutputStream::WriteVarint32SignExtendedToArray(value, target);
}

inline uint8* WireFormatLite::WriteInt32ToArray(int field_number,
                                                int32 value,
                                                uint8* target) {
  target = WriteTagToArray(field_number, WIRETYPE_VARINT, target);
  return WriteInt32NoTagToArray(value, target);
}
inline uint8* WireFormatLite::WriteInt64ToArray(int field_number,
                                                int64 value,
                                                uint8* target) {
  target = WriteTagToArray(field_number, WIRETYPE_VARINT, target);
  return WriteInt64NoTagToArray(value, target);
}
inline uint8* WireFormatLite::WriteUInt32ToArray(int field_number,
                                                 uint32 value,
                                                 uint8* target) {
  target = WriteTagToArray(field_number, WIRETYPE_VARINT, target);
  return WriteUInt32NoTagToArray(value, target);
}
inline uint8* WireFormatLite::WriteUInt64ToArray(int field_number,
                                                 uint64 value,
                                                 uint8* target) {
  target = WriteTagToArray(field_number, WIRETYPE_VARINT, target);
  return WriteUInt64NoTagToArray(value, target);
}
inline uint8* WireFormatLite::WriteSInt32ToArray(int field_number,
                                                 int32 value,
                                                 uint8* target) {
  target = WriteTagToArray(field_number, WIRETYPE_VARINT, target);
  return WriteSInt32NoTagToArray(value, target);
}
inline uint8* WireFormatLite::WriteSInt64ToArray(int field_number,
                                                 int64 value,
                                                 uint8* target) {
  target = WriteTagToArray(field_number, WIRETYPE_VARINT, target);
  return WriteSInt64NoTagToArray(value, target);
}
inline uint8* WireFormatLite::WriteFixed32ToArray(int field_number,
                                                  uint32 value,
                                                  uint8* target) {
  target = WriteTagToArray(field_number, WIRETYPE_FIXED32, target);
  return WriteFixed32NoTagToArray(value, target);
}
inline uint8* WireFormatLite::WriteFixed64ToArray(int field_number,
                                                  uint64 value,
                                                  uint8* target) {
  target = WriteTagToArray(field_number, WIRETYPE_FIXED64, target);
  return WriteFixed64NoTagToArray(value, target);
}
inline uint8* WireFormatLite::WriteSFixed32ToArray(int field_number,
                                                   int32 value,
                                                   uint8* target) {
  target = WriteTagToArray(field_number, WIRETYPE_FIXED32, target);
  return WriteSFixed32NoTagToArray(value, target);
}
inline uint8* WireFormatLite::WriteSFixed64ToArray(int field_number,
                                                   int64 value,
                                                   uint8* target) {
  target = WriteTagToArray(field_number, WIRETYPE_FIXED64, target);
  return WriteSFixed64NoTagToArray(value, target);
}
inline uint8* WireFormatLite::WriteFloatToArray(int field_number,
                                                float value,
                                                uint8* target) {
  target = WriteTagToArray(field_number, WIRETYPE_FIXED32, target);
  return WriteFloatNoTagToArray(value, target);
}
inline uint8* WireFormatLite::WriteDoubleToArray(int field_number,
                                                 double value,
                                                 uint8* target) {
  target = WriteTagToArray(field_number, WIRETYPE_FIXED64, target);
  return WriteDoubleNoTagToArray(value, target);
}
inline uint8* WireFormatLite::WriteBoolToArray(int field_number,
                                               bool value,
                                               uint8* target) {
  target = WriteTagToArray(field_number, WIRETYPE_VARINT, target);
  return WriteBoolNoTagToArray(value, target);
}
inline uint8* WireFormatLite::WriteEnumToArray(int field_number,
                                               int value,
                                               uint8* target) {
  target = WriteTagToArray(field_number, WIRETYPE_VARINT, target);
  return WriteEnumNoTagToArray(value, target);
}

inline uint8* WireFormatLite::WriteStringToArray(int field_number,
                                                 const string& value,
                                                 uint8* target) {
  // String is for UTF-8 text only
  // WARNING:  In wire_format.cc, both strings and bytes are handled by
  //   WriteString() to avoid code duplication.  If the implementations become
  //   different, you will need to update that usage.
  target = WriteTagToArray(field_number, WIRETYPE_LENGTH_DELIMITED, target);
  target = io::CodedOutputStream::WriteVarint32ToArray(value.size(), target);
  return io::CodedOutputStream::WriteStringToArray(value, target);
}
inline uint8* WireFormatLite::WriteBytesToArray(int field_number,
                                                const string& value,
                                                uint8* target) {
  target = WriteTagToArray(field_number, WIRETYPE_LENGTH_DELIMITED, target);
  target = io::CodedOutputStream::WriteVarint32ToArray(value.size(), target);
  return io::CodedOutputStream::WriteStringToArray(value, target);
}


inline uint8* WireFormatLite::WriteGroupToArray(int field_number,
                                                const MessageLite& value,
                                                uint8* target) {
  target = WriteTagToArray(field_number, WIRETYPE_START_GROUP, target);
  target = value.SerializeWithCachedSizesToArray(target);
  return WriteTagToArray(field_number, WIRETYPE_END_GROUP, target);
}
inline uint8* WireFormatLite::WriteMessageToArray(int field_number,
                                                  const MessageLite& value,
                                                  uint8* target) {
  target = WriteTagToArray(field_number, WIRETYPE_LENGTH_DELIMITED, target);
  target = io::CodedOutputStream::WriteVarint32ToArray(
    value.GetCachedSize(), target);
  return value.SerializeWithCachedSizesToArray(target);
}

// See comment on ReadGroupNoVirtual to understand the need for this template
// parameter name.
template<typename MessageType_WorkAroundCppLookupDefect>
inline uint8* WireFormatLite::WriteGroupNoVirtualToArray(
    int field_number, const MessageType_WorkAroundCppLookupDefect& value,
    uint8* target) {
  target = WriteTagToArray(field_number, WIRETYPE_START_GROUP, target);
  target = value.MessageType_WorkAroundCppLookupDefect
      ::SerializeWithCachedSizesToArray(target);
  return WriteTagToArray(field_number, WIRETYPE_END_GROUP, target);
}
template<typename MessageType_WorkAroundCppLookupDefect>
inline uint8* WireFormatLite::WriteMessageNoVirtualToArray(
    int field_number, const MessageType_WorkAroundCppLookupDefect& value,
    uint8* target) {
  target = WriteTagToArray(field_number, WIRETYPE_LENGTH_DELIMITED, target);
  target = io::CodedOutputStream::WriteVarint32ToArray(
    value.MessageType_WorkAroundCppLookupDefect::GetCachedSize(), target);
  return value.MessageType_WorkAroundCppLookupDefect
      ::SerializeWithCachedSizesToArray(target);
}

// ===================================================================

inline int WireFormatLite::Int32Size(int32 value) {
  return io::CodedOutputStream::VarintSize32SignExtended(value);
}
inline int WireFormatLite::Int64Size(int64 value) {
  return io::CodedOutputStream::VarintSize64(static_cast<uint64>(value));
}
inline int WireFormatLite::UInt32Size(uint32 value) {
  return io::CodedOutputStream::VarintSize32(value);
}
inline int WireFormatLite::UInt64Size(uint64 value) {
  return io::CodedOutputStream::VarintSize64(value);
}
inline int WireFormatLite::SInt32Size(int32 value) {
  return io::CodedOutputStream::VarintSize32(ZigZagEncode32(value));
}
inline int WireFormatLite::SInt64Size(int64 value) {
  return io::CodedOutputStream::VarintSize64(ZigZagEncode64(value));
}
inline int WireFormatLite::EnumSize(int value) {
  return io::CodedOutputStream::VarintSize32SignExtended(value);
}

inline int WireFormatLite::StringSize(const string& value) {
  return io::CodedOutputStream::VarintSize32(value.size()) +
         value.size();
}
inline int WireFormatLite::BytesSize(const string& value) {
  return io::CodedOutputStream::VarintSize32(value.size()) +
         value.size();
}


inline int WireFormatLite::GroupSize(const MessageLite& value) {
  return value.ByteSize();
}
inline int WireFormatLite::MessageSize(const MessageLite& value) {
  return LengthDelimitedSize(value.ByteSize());
}

// See comment on ReadGroupNoVirtual to understand the need for this template
// parameter name.
template<typename MessageType_WorkAroundCppLookupDefect>
inline int WireFormatLite::GroupSizeNoVirtual(
    const MessageType_WorkAroundCppLookupDefect& value) {
  return value.MessageType_WorkAroundCppLookupDefect::ByteSize();
}
template<typename MessageType_WorkAroundCppLookupDefect>
inline int WireFormatLite::MessageSizeNoVirtual(
    const MessageType_WorkAroundCppLookupDefect& value) {
  return LengthDelimitedSize(
      value.MessageType_WorkAroundCppLookupDefect::ByteSize());
}

inline int WireFormatLite::LengthDelimitedSize(int length) {
  return io::CodedOutputStream::VarintSize32(length) + length;
}

}  // namespace internal
}  // namespace protobuf

}  // namespace google
#endif  // GOOGLE_PROTOBUF_WIRE_FORMAT_LITE_INL_H__
