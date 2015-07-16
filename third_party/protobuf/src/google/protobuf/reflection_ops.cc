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

#include <string>
#include <vector>

#include <google/protobuf/reflection_ops.h>
#include <google/protobuf/descriptor.h>
#include <google/protobuf/descriptor.pb.h>
#include <google/protobuf/unknown_field_set.h>
#include <google/protobuf/stubs/strutil.h>

namespace google {
namespace protobuf {
namespace internal {

void ReflectionOps::Copy(const Message& from, Message* to) {
  if (&from == to) return;
  Clear(to);
  Merge(from, to);
}

void ReflectionOps::Merge(const Message& from, Message* to) {
  GOOGLE_CHECK_NE(&from, to);

  const Descriptor* descriptor = from.GetDescriptor();
  GOOGLE_CHECK_EQ(to->GetDescriptor(), descriptor)
    << "Tried to merge messages of different types.";

  const Reflection* from_reflection = from.GetReflection();
  const Reflection* to_reflection = to->GetReflection();

  vector<const FieldDescriptor*> fields;
  from_reflection->ListFields(from, &fields);
  for (int i = 0; i < fields.size(); i++) {
    const FieldDescriptor* field = fields[i];

    if (field->is_repeated()) {
      int count = from_reflection->FieldSize(from, field);
      for (int j = 0; j < count; j++) {
        switch (field->cpp_type()) {
#define HANDLE_TYPE(CPPTYPE, METHOD)                                     \
          case FieldDescriptor::CPPTYPE_##CPPTYPE:                       \
            to_reflection->Add##METHOD(to, field,                        \
              from_reflection->GetRepeated##METHOD(from, field, j));     \
            break;

          HANDLE_TYPE(INT32 , Int32 );
          HANDLE_TYPE(INT64 , Int64 );
          HANDLE_TYPE(UINT32, UInt32);
          HANDLE_TYPE(UINT64, UInt64);
          HANDLE_TYPE(FLOAT , Float );
          HANDLE_TYPE(DOUBLE, Double);
          HANDLE_TYPE(BOOL  , Bool  );
          HANDLE_TYPE(STRING, String);
          HANDLE_TYPE(ENUM  , Enum  );
#undef HANDLE_TYPE

          case FieldDescriptor::CPPTYPE_MESSAGE:
            to_reflection->AddMessage(to, field)->MergeFrom(
              from_reflection->GetRepeatedMessage(from, field, j));
            break;
        }
      }
    } else {
      switch (field->cpp_type()) {
#define HANDLE_TYPE(CPPTYPE, METHOD)                                        \
        case FieldDescriptor::CPPTYPE_##CPPTYPE:                            \
          to_reflection->Set##METHOD(to, field,                             \
            from_reflection->Get##METHOD(from, field));                     \
          break;

        HANDLE_TYPE(INT32 , Int32 );
        HANDLE_TYPE(INT64 , Int64 );
        HANDLE_TYPE(UINT32, UInt32);
        HANDLE_TYPE(UINT64, UInt64);
        HANDLE_TYPE(FLOAT , Float );
        HANDLE_TYPE(DOUBLE, Double);
        HANDLE_TYPE(BOOL  , Bool  );
        HANDLE_TYPE(STRING, String);
        HANDLE_TYPE(ENUM  , Enum  );
#undef HANDLE_TYPE

        case FieldDescriptor::CPPTYPE_MESSAGE:
          to_reflection->MutableMessage(to, field)->MergeFrom(
            from_reflection->GetMessage(from, field));
          break;
      }
    }
  }

  to_reflection->MutableUnknownFields(to)->MergeFrom(
    from_reflection->GetUnknownFields(from));
}

void ReflectionOps::Clear(Message* message) {
  const Reflection* reflection = message->GetReflection();

  vector<const FieldDescriptor*> fields;
  reflection->ListFields(*message, &fields);
  for (int i = 0; i < fields.size(); i++) {
    reflection->ClearField(message, fields[i]);
  }

  reflection->MutableUnknownFields(message)->Clear();
}

bool ReflectionOps::IsInitialized(const Message& message) {
  const Descriptor* descriptor = message.GetDescriptor();
  const Reflection* reflection = message.GetReflection();

  // Check required fields of this message.
  for (int i = 0; i < descriptor->field_count(); i++) {
    if (descriptor->field(i)->is_required()) {
      if (!reflection->HasField(message, descriptor->field(i))) {
        return false;
      }
    }
  }

  // Check that sub-messages are initialized.
  vector<const FieldDescriptor*> fields;
  reflection->ListFields(message, &fields);
  for (int i = 0; i < fields.size(); i++) {
    const FieldDescriptor* field = fields[i];
    if (field->cpp_type() == FieldDescriptor::CPPTYPE_MESSAGE) {

      if (field->is_repeated()) {
        int size = reflection->FieldSize(message, field);

        for (int j = 0; j < size; j++) {
          if (!reflection->GetRepeatedMessage(message, field, j)
                          .IsInitialized()) {
            return false;
          }
        }
      } else {
        if (!reflection->GetMessage(message, field).IsInitialized()) {
          return false;
        }
      }
    }
  }

  return true;
}

void ReflectionOps::DiscardUnknownFields(Message* message) {
  const Reflection* reflection = message->GetReflection();

  reflection->MutableUnknownFields(message)->Clear();

  vector<const FieldDescriptor*> fields;
  reflection->ListFields(*message, &fields);
  for (int i = 0; i < fields.size(); i++) {
    const FieldDescriptor* field = fields[i];
    if (field->cpp_type() == FieldDescriptor::CPPTYPE_MESSAGE) {
      if (field->is_repeated()) {
        int size = reflection->FieldSize(*message, field);
        for (int j = 0; j < size; j++) {
          reflection->MutableRepeatedMessage(message, field, j)
                    ->DiscardUnknownFields();
        }
      } else {
        reflection->MutableMessage(message, field)->DiscardUnknownFields();
      }
    }
  }
}

static string SubMessagePrefix(const string& prefix,
                               const FieldDescriptor* field,
                               int index) {
  string result(prefix);
  if (field->is_extension()) {
    result.append("(");
    result.append(field->full_name());
    result.append(")");
  } else {
    result.append(field->name());
  }
  if (index != -1) {
    result.append("[");
    result.append(SimpleItoa(index));
    result.append("]");
  }
  result.append(".");
  return result;
}

void ReflectionOps::FindInitializationErrors(
    const Message& message,
    const string& prefix,
    vector<string>* errors) {
  const Descriptor* descriptor = message.GetDescriptor();
  const Reflection* reflection = message.GetReflection();

  // Check required fields of this message.
  for (int i = 0; i < descriptor->field_count(); i++) {
    if (descriptor->field(i)->is_required()) {
      if (!reflection->HasField(message, descriptor->field(i))) {
        errors->push_back(prefix + descriptor->field(i)->name());
      }
    }
  }

  // Check sub-messages.
  vector<const FieldDescriptor*> fields;
  reflection->ListFields(message, &fields);
  for (int i = 0; i < fields.size(); i++) {
    const FieldDescriptor* field = fields[i];
    if (field->cpp_type() == FieldDescriptor::CPPTYPE_MESSAGE) {

      if (field->is_repeated()) {
        int size = reflection->FieldSize(message, field);

        for (int j = 0; j < size; j++) {
          const Message& sub_message =
            reflection->GetRepeatedMessage(message, field, j);
          FindInitializationErrors(sub_message,
                                   SubMessagePrefix(prefix, field, j),
                                   errors);
        }
      } else {
        const Message& sub_message = reflection->GetMessage(message, field);
        FindInitializationErrors(sub_message,
                                 SubMessagePrefix(prefix, field, -1),
                                 errors);
      }
    }
  }
}

}  // namespace internal
}  // namespace protobuf
}  // namespace google
