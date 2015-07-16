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

// Authors: wink@google.com (Wink Saville),
//          kenton@google.com (Kenton Varda)
//  Based on original Protocol Buffers design by
//  Sanjay Ghemawat, Jeff Dean, and others.

#include <google/protobuf/message_lite.h>
#include <string>
#include <google/protobuf/stubs/common.h>
#include <google/protobuf/io/coded_stream.h>
#include <google/protobuf/io/zero_copy_stream_impl_lite.h>
#include <google/protobuf/stubs/stl_util.h>

namespace google {
namespace protobuf {

MessageLite::~MessageLite() {}

string MessageLite::InitializationErrorString() const {
  return "(cannot determine missing fields for lite message)";
}

namespace {

// When serializing, we first compute the byte size, then serialize the message.
// If serialization produces a different number of bytes than expected, we
// call this function, which crashes.  The problem could be due to a bug in the
// protobuf implementation but is more likely caused by concurrent modification
// of the message.  This function attempts to distinguish between the two and
// provide a useful error message.
void ByteSizeConsistencyError(int byte_size_before_serialization,
                              int byte_size_after_serialization,
                              int bytes_produced_by_serialization) {
  GOOGLE_CHECK_EQ(byte_size_before_serialization, byte_size_after_serialization)
      << "Protocol message was modified concurrently during serialization.";
  GOOGLE_CHECK_EQ(bytes_produced_by_serialization, byte_size_before_serialization)
      << "Byte size calculation and serialization were inconsistent.  This "
         "may indicate a bug in protocol buffers or it may be caused by "
         "concurrent modification of the message.";
  GOOGLE_LOG(FATAL) << "This shouldn't be called if all the sizes are equal.";
}

string InitializationErrorMessage(const char* action,
                                  const MessageLite& message) {
  // Note:  We want to avoid depending on strutil in the lite library, otherwise
  //   we'd use:
  //
  // return strings::Substitute(
  //   "Can't $0 message of type \"$1\" because it is missing required "
  //   "fields: $2",
  //   action, message.GetTypeName(),
  //   message.InitializationErrorString());

  string result;
  result += "Can't ";
  result += action;
  result += " message of type \"";
  result += message.GetTypeName();
  result += "\" because it is missing required fields: ";
  result += message.InitializationErrorString();
  return result;
}

// Several of the Parse methods below just do one thing and then call another
// method.  In a naive implementation, we might have ParseFromString() call
// ParseFromArray() which would call ParseFromZeroCopyStream() which would call
// ParseFromCodedStream() which would call MergeFromCodedStream() which would
// call MergePartialFromCodedStream().  However, when parsing very small
// messages, every function call introduces significant overhead.  To avoid
// this without reproducing code, we use these forced-inline helpers.
//
// Note:  GCC only allows GOOGLE_ATTRIBUTE_ALWAYS_INLINE on declarations, not
//   definitions.
inline bool InlineMergeFromCodedStream(io::CodedInputStream* input,
                                       MessageLite* message)
                                       GOOGLE_ATTRIBUTE_ALWAYS_INLINE;
inline bool InlineParseFromCodedStream(io::CodedInputStream* input,
                                       MessageLite* message)
                                       GOOGLE_ATTRIBUTE_ALWAYS_INLINE;
inline bool InlineParsePartialFromCodedStream(io::CodedInputStream* input,
                                              MessageLite* message)
                                              GOOGLE_ATTRIBUTE_ALWAYS_INLINE;
inline bool InlineParseFromArray(const void* data, int size,
                                 MessageLite* message)
                                 GOOGLE_ATTRIBUTE_ALWAYS_INLINE;
inline bool InlineParsePartialFromArray(const void* data, int size,
                                        MessageLite* message)
                                        GOOGLE_ATTRIBUTE_ALWAYS_INLINE;

bool InlineMergeFromCodedStream(io::CodedInputStream* input,
                                MessageLite* message) {
  if (!message->MergePartialFromCodedStream(input)) return false;
  if (!message->IsInitialized()) {
    GOOGLE_LOG(ERROR) << InitializationErrorMessage("parse", *message);
    return false;
  }
  return true;
}

bool InlineParseFromCodedStream(io::CodedInputStream* input,
                                MessageLite* message) {
  message->Clear();
  return InlineMergeFromCodedStream(input, message);
}

bool InlineParsePartialFromCodedStream(io::CodedInputStream* input,
                                       MessageLite* message) {
  message->Clear();
  return message->MergePartialFromCodedStream(input);
}

bool InlineParseFromArray(const void* data, int size, MessageLite* message) {
  io::CodedInputStream input(reinterpret_cast<const uint8*>(data), size);
  return InlineParseFromCodedStream(&input, message) &&
         input.ConsumedEntireMessage();
}

bool InlineParsePartialFromArray(const void* data, int size,
                                 MessageLite* message) {
  io::CodedInputStream input(reinterpret_cast<const uint8*>(data), size);
  return InlineParsePartialFromCodedStream(&input, message) &&
         input.ConsumedEntireMessage();
}

}  // namespace

bool MessageLite::MergeFromCodedStream(io::CodedInputStream* input) {
  return InlineMergeFromCodedStream(input, this);
}

bool MessageLite::ParseFromCodedStream(io::CodedInputStream* input) {
  return InlineParseFromCodedStream(input, this);
}

bool MessageLite::ParsePartialFromCodedStream(io::CodedInputStream* input) {
  return InlineParsePartialFromCodedStream(input, this);
}

bool MessageLite::ParseFromZeroCopyStream(io::ZeroCopyInputStream* input) {
  io::CodedInputStream decoder(input);
  return ParseFromCodedStream(&decoder) && decoder.ConsumedEntireMessage();
}

bool MessageLite::ParsePartialFromZeroCopyStream(
    io::ZeroCopyInputStream* input) {
  io::CodedInputStream decoder(input);
  return ParsePartialFromCodedStream(&decoder) &&
         decoder.ConsumedEntireMessage();
}

bool MessageLite::ParseFromBoundedZeroCopyStream(
    io::ZeroCopyInputStream* input, int size) {
  io::CodedInputStream decoder(input);
  decoder.PushLimit(size);
  return ParseFromCodedStream(&decoder) &&
         decoder.ConsumedEntireMessage() &&
         decoder.BytesUntilLimit() == 0;
}

bool MessageLite::ParsePartialFromBoundedZeroCopyStream(
    io::ZeroCopyInputStream* input, int size) {
  io::CodedInputStream decoder(input);
  decoder.PushLimit(size);
  return ParsePartialFromCodedStream(&decoder) &&
         decoder.ConsumedEntireMessage() &&
         decoder.BytesUntilLimit() == 0;
}

bool MessageLite::ParseFromString(const string& data) {
  return InlineParseFromArray(data.data(), data.size(), this);
}

bool MessageLite::ParsePartialFromString(const string& data) {
  return InlineParsePartialFromArray(data.data(), data.size(), this);
}

bool MessageLite::ParseFromArray(const void* data, int size) {
  return InlineParseFromArray(data, size, this);
}

bool MessageLite::ParsePartialFromArray(const void* data, int size) {
  return InlineParsePartialFromArray(data, size, this);
}


// ===================================================================

uint8* MessageLite::SerializeWithCachedSizesToArray(uint8* target) const {
  // We only optimize this when using optimize_for = SPEED.  In other cases
  // we just use the CodedOutputStream path.
  int size = GetCachedSize();
  io::ArrayOutputStream out(target, size);
  io::CodedOutputStream coded_out(&out);
  SerializeWithCachedSizes(&coded_out);
  GOOGLE_CHECK(!coded_out.HadError());
  return target + size;
}

bool MessageLite::SerializeToCodedStream(io::CodedOutputStream* output) const {
  GOOGLE_DCHECK(IsInitialized()) << InitializationErrorMessage("serialize", *this);
  return SerializePartialToCodedStream(output);
}

bool MessageLite::SerializePartialToCodedStream(
    io::CodedOutputStream* output) const {
  const int size = ByteSize();  // Force size to be cached.
  uint8* buffer = output->GetDirectBufferForNBytesAndAdvance(size);
  if (buffer != NULL) {
    uint8* end = SerializeWithCachedSizesToArray(buffer);
    if (end - buffer != size) {
      ByteSizeConsistencyError(size, ByteSize(), end - buffer);
    }
    return true;
  } else {
    int original_byte_count = output->ByteCount();
    SerializeWithCachedSizes(output);
    if (output->HadError()) {
      return false;
    }
    int final_byte_count = output->ByteCount();

    if (final_byte_count - original_byte_count != size) {
      ByteSizeConsistencyError(size, ByteSize(),
                               final_byte_count - original_byte_count);
    }

    return true;
  }
}

bool MessageLite::SerializeToZeroCopyStream(
    io::ZeroCopyOutputStream* output) const {
  io::CodedOutputStream encoder(output);
  return SerializeToCodedStream(&encoder);
}

bool MessageLite::SerializePartialToZeroCopyStream(
    io::ZeroCopyOutputStream* output) const {
  io::CodedOutputStream encoder(output);
  return SerializePartialToCodedStream(&encoder);
}

bool MessageLite::AppendToString(string* output) const {
  GOOGLE_DCHECK(IsInitialized()) << InitializationErrorMessage("serialize", *this);
  return AppendPartialToString(output);
}

bool MessageLite::AppendPartialToString(string* output) const {
  int old_size = output->size();
  int byte_size = ByteSize();
  STLStringResizeUninitialized(output, old_size + byte_size);
  uint8* start = reinterpret_cast<uint8*>(string_as_array(output) + old_size);
  uint8* end = SerializeWithCachedSizesToArray(start);
  if (end - start != byte_size) {
    ByteSizeConsistencyError(byte_size, ByteSize(), end - start);
  }
  return true;
}

bool MessageLite::SerializeToString(string* output) const {
  output->clear();
  return AppendToString(output);
}

bool MessageLite::SerializePartialToString(string* output) const {
  output->clear();
  return AppendPartialToString(output);
}

bool MessageLite::SerializeToArray(void* data, int size) const {
  GOOGLE_DCHECK(IsInitialized()) << InitializationErrorMessage("serialize", *this);
  return SerializePartialToArray(data, size);
}

bool MessageLite::SerializePartialToArray(void* data, int size) const {
  int byte_size = ByteSize();
  if (size < byte_size) return false;
  uint8* start = reinterpret_cast<uint8*>(data);
  uint8* end = SerializeWithCachedSizesToArray(start);
  if (end - start != byte_size) {
    ByteSizeConsistencyError(byte_size, ByteSize(), end - start);
  }
  return true;
}

string MessageLite::SerializeAsString() const {
  // If the compiler implements the (Named) Return Value Optimization,
  // the local variable 'result' will not actually reside on the stack
  // of this function, but will be overlaid with the object that the
  // caller supplied for the return value to be constructed in.
  string output;
  if (!AppendToString(&output))
    output.clear();
  return output;
}

string MessageLite::SerializePartialAsString() const {
  string output;
  if (!AppendPartialToString(&output))
    output.clear();
  return output;
}

}  // namespace protobuf
}  // namespace google
