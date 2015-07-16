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

#include <algorithm>
#include <google/protobuf/descriptor.pb.h>
#include <google/protobuf/generated_message_reflection.h>
#include <google/protobuf/descriptor.h>
#include <google/protobuf/repeated_field.h>
#include <google/protobuf/extension_set.h>
#include <google/protobuf/generated_message_util.h>
#include <google/protobuf/stubs/common.h>

namespace google {
namespace protobuf {
namespace internal {

bool ParseNamedEnum(const EnumDescriptor* descriptor,
                    const string& name,
                    int* value) {
  const EnumValueDescriptor* d = descriptor->FindValueByName(name);
  if (d == NULL) return false;
  *value = d->number();
  return true;
}

const string& NameOfEnum(const EnumDescriptor* descriptor, int value) {
  const EnumValueDescriptor* d = descriptor->FindValueByNumber(value);
  return (d == NULL ? GetEmptyString() : d->name());
}

// ===================================================================
// Helpers for reporting usage errors (e.g. trying to use GetInt32() on
// a string field).

namespace {

void ReportReflectionUsageError(
    const Descriptor* descriptor, const FieldDescriptor* field,
    const char* method, const char* description) {
  GOOGLE_LOG(FATAL)
    << "Protocol Buffer reflection usage error:\n"
       "  Method      : google::protobuf::Reflection::" << method << "\n"
       "  Message type: " << descriptor->full_name() << "\n"
       "  Field       : " << field->full_name() << "\n"
       "  Problem     : " << description;
}

const char* cpptype_names_[FieldDescriptor::MAX_CPPTYPE + 1] = {
  "INVALID_CPPTYPE",
  "CPPTYPE_INT32",
  "CPPTYPE_INT64",
  "CPPTYPE_UINT32",
  "CPPTYPE_UINT64",
  "CPPTYPE_DOUBLE",
  "CPPTYPE_FLOAT",
  "CPPTYPE_BOOL",
  "CPPTYPE_ENUM",
  "CPPTYPE_STRING",
  "CPPTYPE_MESSAGE"
};

static void ReportReflectionUsageTypeError(
    const Descriptor* descriptor, const FieldDescriptor* field,
    const char* method,
    FieldDescriptor::CppType expected_type) {
  GOOGLE_LOG(FATAL)
    << "Protocol Buffer reflection usage error:\n"
       "  Method      : google::protobuf::Reflection::" << method << "\n"
       "  Message type: " << descriptor->full_name() << "\n"
       "  Field       : " << field->full_name() << "\n"
       "  Problem     : Field is not the right type for this message:\n"
       "    Expected  : " << cpptype_names_[expected_type] << "\n"
       "    Field type: " << cpptype_names_[field->cpp_type()];
}

static void ReportReflectionUsageEnumTypeError(
    const Descriptor* descriptor, const FieldDescriptor* field,
    const char* method, const EnumValueDescriptor* value) {
  GOOGLE_LOG(FATAL)
    << "Protocol Buffer reflection usage error:\n"
       "  Method      : google::protobuf::Reflection::" << method << "\n"
       "  Message type: " << descriptor->full_name() << "\n"
       "  Field       : " << field->full_name() << "\n"
       "  Problem     : Enum value did not match field type:\n"
       "    Expected  : " << field->enum_type()->full_name() << "\n"
       "    Actual    : " << value->full_name();
}

#define USAGE_CHECK(CONDITION, METHOD, ERROR_DESCRIPTION)                      \
  if (!(CONDITION))                                                            \
    ReportReflectionUsageError(descriptor_, field, #METHOD, ERROR_DESCRIPTION)
#define USAGE_CHECK_EQ(A, B, METHOD, ERROR_DESCRIPTION)                        \
  USAGE_CHECK((A) == (B), METHOD, ERROR_DESCRIPTION)
#define USAGE_CHECK_NE(A, B, METHOD, ERROR_DESCRIPTION)                        \
  USAGE_CHECK((A) != (B), METHOD, ERROR_DESCRIPTION)

#define USAGE_CHECK_TYPE(METHOD, CPPTYPE)                                      \
  if (field->cpp_type() != FieldDescriptor::CPPTYPE_##CPPTYPE)                 \
    ReportReflectionUsageTypeError(descriptor_, field, #METHOD,                \
                                   FieldDescriptor::CPPTYPE_##CPPTYPE)

#define USAGE_CHECK_ENUM_VALUE(METHOD)                                         \
  if (value->type() != field->enum_type())                                     \
    ReportReflectionUsageEnumTypeError(descriptor_, field, #METHOD, value)

#define USAGE_CHECK_MESSAGE_TYPE(METHOD)                                       \
  USAGE_CHECK_EQ(field->containing_type(), descriptor_,                        \
                 METHOD, "Field does not match message type.");
#define USAGE_CHECK_SINGULAR(METHOD)                                           \
  USAGE_CHECK_NE(field->label(), FieldDescriptor::LABEL_REPEATED, METHOD,      \
                 "Field is repeated; the method requires a singular field.")
#define USAGE_CHECK_REPEATED(METHOD)                                           \
  USAGE_CHECK_EQ(field->label(), FieldDescriptor::LABEL_REPEATED, METHOD,      \
                 "Field is singular; the method requires a repeated field.")

#define USAGE_CHECK_ALL(METHOD, LABEL, CPPTYPE)                       \
    USAGE_CHECK_MESSAGE_TYPE(METHOD);                                 \
    USAGE_CHECK_##LABEL(METHOD);                                      \
    USAGE_CHECK_TYPE(METHOD, CPPTYPE)

}  // namespace

// ===================================================================

GeneratedMessageReflection::GeneratedMessageReflection(
    const Descriptor* descriptor,
    const Message* default_instance,
    const int offsets[],
    int has_bits_offset,
    int unknown_fields_offset,
    int extensions_offset,
    const DescriptorPool* descriptor_pool,
    MessageFactory* factory,
    int object_size)
  : descriptor_       (descriptor),
    default_instance_ (default_instance),
    offsets_          (offsets),
    has_bits_offset_  (has_bits_offset),
    unknown_fields_offset_(unknown_fields_offset),
    extensions_offset_(extensions_offset),
    object_size_      (object_size),
    descriptor_pool_  ((descriptor_pool == NULL) ?
                         DescriptorPool::generated_pool() :
                         descriptor_pool),
    message_factory_  (factory) {
}

GeneratedMessageReflection::~GeneratedMessageReflection() {}

const UnknownFieldSet& GeneratedMessageReflection::GetUnknownFields(
    const Message& message) const {
  const void* ptr = reinterpret_cast<const uint8*>(&message) +
                    unknown_fields_offset_;
  return *reinterpret_cast<const UnknownFieldSet*>(ptr);
}
UnknownFieldSet* GeneratedMessageReflection::MutableUnknownFields(
    Message* message) const {
  void* ptr = reinterpret_cast<uint8*>(message) + unknown_fields_offset_;
  return reinterpret_cast<UnknownFieldSet*>(ptr);
}

int GeneratedMessageReflection::SpaceUsed(const Message& message) const {
  // object_size_ already includes the in-memory representation of each field
  // in the message, so we only need to account for additional memory used by
  // the fields.
  int total_size = object_size_;

  total_size += GetUnknownFields(message).SpaceUsedExcludingSelf();

  if (extensions_offset_ != -1) {
    total_size += GetExtensionSet(message).SpaceUsedExcludingSelf();
  }

  for (int i = 0; i < descriptor_->field_count(); i++) {
    const FieldDescriptor* field = descriptor_->field(i);

    if (field->is_repeated()) {
      switch (field->cpp_type()) {
#define HANDLE_TYPE(UPPERCASE, LOWERCASE)                                     \
        case FieldDescriptor::CPPTYPE_##UPPERCASE :                           \
          total_size += GetRaw<RepeatedField<LOWERCASE> >(message, field)     \
                          .SpaceUsedExcludingSelf();                          \
          break

        HANDLE_TYPE( INT32,  int32);
        HANDLE_TYPE( INT64,  int64);
        HANDLE_TYPE(UINT32, uint32);
        HANDLE_TYPE(UINT64, uint64);
        HANDLE_TYPE(DOUBLE, double);
        HANDLE_TYPE( FLOAT,  float);
        HANDLE_TYPE(  BOOL,   bool);
        HANDLE_TYPE(  ENUM,    int);
#undef HANDLE_TYPE

        case FieldDescriptor::CPPTYPE_STRING:
          switch (field->options().ctype()) {
            default:  // TODO(kenton):  Support other string reps.
            case FieldOptions::STRING:
              total_size += GetRaw<RepeatedPtrField<string> >(message, field)
                              .SpaceUsedExcludingSelf();
              break;
          }
          break;

        case FieldDescriptor::CPPTYPE_MESSAGE:
          // We don't know which subclass of RepeatedPtrFieldBase the type is,
          // so we use RepeatedPtrFieldBase directly.
          total_size +=
              GetRaw<RepeatedPtrFieldBase>(message, field)
                .SpaceUsedExcludingSelf<GenericTypeHandler<Message> >();
          break;
      }
    } else {
      switch (field->cpp_type()) {
        case FieldDescriptor::CPPTYPE_INT32 :
        case FieldDescriptor::CPPTYPE_INT64 :
        case FieldDescriptor::CPPTYPE_UINT32:
        case FieldDescriptor::CPPTYPE_UINT64:
        case FieldDescriptor::CPPTYPE_DOUBLE:
        case FieldDescriptor::CPPTYPE_FLOAT :
        case FieldDescriptor::CPPTYPE_BOOL  :
        case FieldDescriptor::CPPTYPE_ENUM  :
          // Field is inline, so we've already counted it.
          break;

        case FieldDescriptor::CPPTYPE_STRING: {
          switch (field->options().ctype()) {
            default:  // TODO(kenton):  Support other string reps.
            case FieldOptions::STRING: {
              const string* ptr = GetField<const string*>(message, field);

              // Initially, the string points to the default value stored in
              // the prototype. Only count the string if it has been changed
              // from the default value.
              const string* default_ptr = DefaultRaw<const string*>(field);

              if (ptr != default_ptr) {
                // string fields are represented by just a pointer, so also
                // include sizeof(string) as well.
                total_size += sizeof(*ptr) + StringSpaceUsedExcludingSelf(*ptr);
              }
              break;
            }
          }
          break;
        }

        case FieldDescriptor::CPPTYPE_MESSAGE:
          if (&message == default_instance_) {
            // For singular fields, the prototype just stores a pointer to the
            // external type's prototype, so there is no extra memory usage.
          } else {
            const Message* sub_message = GetRaw<const Message*>(message, field);
            if (sub_message != NULL) {
              total_size += sub_message->SpaceUsed();
            }
          }
          break;
      }
    }
  }

  return total_size;
}

void GeneratedMessageReflection::Swap(
    Message* message1,
    Message* message2) const {
  if (message1 == message2) return;

  // TODO(kenton):  Other Reflection methods should probably check this too.
  GOOGLE_CHECK_EQ(message1->GetReflection(), this)
    << "First argument to Swap() (of type \""
    << message1->GetDescriptor()->full_name()
    << "\") is not compatible with this reflection object (which is for type \""
    << descriptor_->full_name()
    << "\").  Note that the exact same class is required; not just the same "
       "descriptor.";
  GOOGLE_CHECK_EQ(message2->GetReflection(), this)
    << "Second argument to Swap() (of type \""
    << message2->GetDescriptor()->full_name()
    << "\") is not compatible with this reflection object (which is for type \""
    << descriptor_->full_name()
    << "\").  Note that the exact same class is required; not just the same "
       "descriptor.";

  uint32* has_bits1 = MutableHasBits(message1);
  uint32* has_bits2 = MutableHasBits(message2);
  int has_bits_size = (descriptor_->field_count() + 31) / 32;

  for (int i = 0; i < has_bits_size; i++) {
    std::swap(has_bits1[i], has_bits2[i]);
  }

  for (int i = 0; i < descriptor_->field_count(); i++) {
    const FieldDescriptor* field = descriptor_->field(i);
    if (field->is_repeated()) {
      switch (field->cpp_type()) {
#define SWAP_ARRAYS(CPPTYPE, TYPE)                                           \
        case FieldDescriptor::CPPTYPE_##CPPTYPE:                             \
          MutableRaw<RepeatedField<TYPE> >(message1, field)->Swap(           \
              MutableRaw<RepeatedField<TYPE> >(message2, field));            \
          break;

          SWAP_ARRAYS(INT32 , int32 );
          SWAP_ARRAYS(INT64 , int64 );
          SWAP_ARRAYS(UINT32, uint32);
          SWAP_ARRAYS(UINT64, uint64);
          SWAP_ARRAYS(FLOAT , float );
          SWAP_ARRAYS(DOUBLE, double);
          SWAP_ARRAYS(BOOL  , bool  );
          SWAP_ARRAYS(ENUM  , int   );
#undef SWAP_ARRAYS

        case FieldDescriptor::CPPTYPE_STRING:
        case FieldDescriptor::CPPTYPE_MESSAGE:
          MutableRaw<RepeatedPtrFieldBase>(message1, field)->Swap(
              MutableRaw<RepeatedPtrFieldBase>(message2, field));
          break;

        default:
          GOOGLE_LOG(FATAL) << "Unimplemented type: " << field->cpp_type();
      }
    } else {
      switch (field->cpp_type()) {
#define SWAP_VALUES(CPPTYPE, TYPE)                                           \
        case FieldDescriptor::CPPTYPE_##CPPTYPE:                             \
          std::swap(*MutableRaw<TYPE>(message1, field),                      \
                    *MutableRaw<TYPE>(message2, field));                     \
          break;

          SWAP_VALUES(INT32 , int32 );
          SWAP_VALUES(INT64 , int64 );
          SWAP_VALUES(UINT32, uint32);
          SWAP_VALUES(UINT64, uint64);
          SWAP_VALUES(FLOAT , float );
          SWAP_VALUES(DOUBLE, double);
          SWAP_VALUES(BOOL  , bool  );
          SWAP_VALUES(ENUM  , int   );
#undef SWAP_VALUES
        case FieldDescriptor::CPPTYPE_MESSAGE:
          std::swap(*MutableRaw<Message*>(message1, field),
                    *MutableRaw<Message*>(message2, field));
          break;

        case FieldDescriptor::CPPTYPE_STRING:
          switch (field->options().ctype()) {
            default:  // TODO(kenton):  Support other string reps.
            case FieldOptions::STRING:
              std::swap(*MutableRaw<string*>(message1, field),
                        *MutableRaw<string*>(message2, field));
              break;
          }
          break;

        default:
          GOOGLE_LOG(FATAL) << "Unimplemented type: " << field->cpp_type();
      }
    }
  }

  if (extensions_offset_ != -1) {
    MutableExtensionSet(message1)->Swap(MutableExtensionSet(message2));
  }

  MutableUnknownFields(message1)->Swap(MutableUnknownFields(message2));
}

// -------------------------------------------------------------------

bool GeneratedMessageReflection::HasField(const Message& message,
                                          const FieldDescriptor* field) const {
  USAGE_CHECK_MESSAGE_TYPE(HasField);
  USAGE_CHECK_SINGULAR(HasField);

  if (field->is_extension()) {
    return GetExtensionSet(message).Has(field->number());
  } else {
    return HasBit(message, field);
  }
}

int GeneratedMessageReflection::FieldSize(const Message& message,
                                          const FieldDescriptor* field) const {
  USAGE_CHECK_MESSAGE_TYPE(FieldSize);
  USAGE_CHECK_REPEATED(FieldSize);

  if (field->is_extension()) {
    return GetExtensionSet(message).ExtensionSize(field->number());
  } else {
    switch (field->cpp_type()) {
#define HANDLE_TYPE(UPPERCASE, LOWERCASE)                                     \
      case FieldDescriptor::CPPTYPE_##UPPERCASE :                             \
        return GetRaw<RepeatedField<LOWERCASE> >(message, field).size()

      HANDLE_TYPE( INT32,  int32);
      HANDLE_TYPE( INT64,  int64);
      HANDLE_TYPE(UINT32, uint32);
      HANDLE_TYPE(UINT64, uint64);
      HANDLE_TYPE(DOUBLE, double);
      HANDLE_TYPE( FLOAT,  float);
      HANDLE_TYPE(  BOOL,   bool);
      HANDLE_TYPE(  ENUM,    int);
#undef HANDLE_TYPE

      case FieldDescriptor::CPPTYPE_STRING:
      case FieldDescriptor::CPPTYPE_MESSAGE:
        return GetRaw<RepeatedPtrFieldBase>(message, field).size();
    }

    GOOGLE_LOG(FATAL) << "Can't get here.";
    return 0;
  }
}

void GeneratedMessageReflection::ClearField(
    Message* message, const FieldDescriptor* field) const {
  USAGE_CHECK_MESSAGE_TYPE(ClearField);

  if (field->is_extension()) {
    MutableExtensionSet(message)->ClearExtension(field->number());
  } else if (!field->is_repeated()) {
    if (HasBit(*message, field)) {
      ClearBit(message, field);

      // We need to set the field back to its default value.
      switch (field->cpp_type()) {
#define CLEAR_TYPE(CPPTYPE, TYPE)                                            \
        case FieldDescriptor::CPPTYPE_##CPPTYPE:                             \
          *MutableRaw<TYPE>(message, field) =                                \
            field->default_value_##TYPE();                                   \
          break;

        CLEAR_TYPE(INT32 , int32 );
        CLEAR_TYPE(INT64 , int64 );
        CLEAR_TYPE(UINT32, uint32);
        CLEAR_TYPE(UINT64, uint64);
        CLEAR_TYPE(FLOAT , float );
        CLEAR_TYPE(DOUBLE, double);
        CLEAR_TYPE(BOOL  , bool  );
#undef CLEAR_TYPE

        case FieldDescriptor::CPPTYPE_ENUM:
          *MutableRaw<int>(message, field) =
            field->default_value_enum()->number();
          break;

        case FieldDescriptor::CPPTYPE_STRING: {
          switch (field->options().ctype()) {
            default:  // TODO(kenton):  Support other string reps.
            case FieldOptions::STRING:
              const string* default_ptr = DefaultRaw<const string*>(field);
              string** value = MutableRaw<string*>(message, field);
              if (*value != default_ptr) {
                if (field->has_default_value()) {
                  (*value)->assign(field->default_value_string());
                } else {
                  (*value)->clear();
                }
              }
              break;
          }
          break;
        }

        case FieldDescriptor::CPPTYPE_MESSAGE:
          (*MutableRaw<Message*>(message, field))->Clear();
          break;
      }
    }
  } else {
    switch (field->cpp_type()) {
#define HANDLE_TYPE(UPPERCASE, LOWERCASE)                                     \
      case FieldDescriptor::CPPTYPE_##UPPERCASE :                             \
        MutableRaw<RepeatedField<LOWERCASE> >(message, field)->Clear();       \
        break

      HANDLE_TYPE( INT32,  int32);
      HANDLE_TYPE( INT64,  int64);
      HANDLE_TYPE(UINT32, uint32);
      HANDLE_TYPE(UINT64, uint64);
      HANDLE_TYPE(DOUBLE, double);
      HANDLE_TYPE( FLOAT,  float);
      HANDLE_TYPE(  BOOL,   bool);
      HANDLE_TYPE(  ENUM,    int);
#undef HANDLE_TYPE

      case FieldDescriptor::CPPTYPE_STRING: {
        switch (field->options().ctype()) {
          default:  // TODO(kenton):  Support other string reps.
          case FieldOptions::STRING:
            MutableRaw<RepeatedPtrField<string> >(message, field)->Clear();
            break;
        }
        break;
      }

      case FieldDescriptor::CPPTYPE_MESSAGE: {
        // We don't know which subclass of RepeatedPtrFieldBase the type is,
        // so we use RepeatedPtrFieldBase directly.
        MutableRaw<RepeatedPtrFieldBase>(message, field)
            ->Clear<GenericTypeHandler<Message> >();
        break;
      }
    }
  }
}

void GeneratedMessageReflection::RemoveLast(
    Message* message,
    const FieldDescriptor* field) const {
  USAGE_CHECK_MESSAGE_TYPE(RemoveLast);
  USAGE_CHECK_REPEATED(RemoveLast);

  if (field->is_extension()) {
    MutableExtensionSet(message)->RemoveLast(field->number());
  } else {
    switch (field->cpp_type()) {
#define HANDLE_TYPE(UPPERCASE, LOWERCASE)                                     \
      case FieldDescriptor::CPPTYPE_##UPPERCASE :                             \
        MutableRaw<RepeatedField<LOWERCASE> >(message, field)->RemoveLast();  \
        break

      HANDLE_TYPE( INT32,  int32);
      HANDLE_TYPE( INT64,  int64);
      HANDLE_TYPE(UINT32, uint32);
      HANDLE_TYPE(UINT64, uint64);
      HANDLE_TYPE(DOUBLE, double);
      HANDLE_TYPE( FLOAT,  float);
      HANDLE_TYPE(  BOOL,   bool);
      HANDLE_TYPE(  ENUM,    int);
#undef HANDLE_TYPE

      case FieldDescriptor::CPPTYPE_STRING:
        switch (field->options().ctype()) {
          default:  // TODO(kenton):  Support other string reps.
          case FieldOptions::STRING:
            MutableRaw<RepeatedPtrField<string> >(message, field)->RemoveLast();
            break;
        }
        break;

      case FieldDescriptor::CPPTYPE_MESSAGE:
        MutableRaw<RepeatedPtrFieldBase>(message, field)
            ->RemoveLast<GenericTypeHandler<Message> >();
        break;
    }
  }
}

Message* GeneratedMessageReflection::ReleaseLast(
    Message* message,
    const FieldDescriptor* field) const {
  USAGE_CHECK_ALL(ReleaseLast, REPEATED, MESSAGE);

  if (field->is_extension()) {
    return static_cast<Message*>(
        MutableExtensionSet(message)->ReleaseLast(field->number()));
  } else {
    return MutableRaw<RepeatedPtrFieldBase>(message, field)
        ->ReleaseLast<GenericTypeHandler<Message> >();
  }
}

void GeneratedMessageReflection::SwapElements(
    Message* message,
    const FieldDescriptor* field,
    int index1,
    int index2) const {
  USAGE_CHECK_MESSAGE_TYPE(Swap);
  USAGE_CHECK_REPEATED(Swap);

  if (field->is_extension()) {
    MutableExtensionSet(message)->SwapElements(field->number(), index1, index2);
  } else {
    switch (field->cpp_type()) {
#define HANDLE_TYPE(UPPERCASE, LOWERCASE)                                     \
      case FieldDescriptor::CPPTYPE_##UPPERCASE :                             \
        MutableRaw<RepeatedField<LOWERCASE> >(message, field)                 \
            ->SwapElements(index1, index2);                                   \
        break

      HANDLE_TYPE( INT32,  int32);
      HANDLE_TYPE( INT64,  int64);
      HANDLE_TYPE(UINT32, uint32);
      HANDLE_TYPE(UINT64, uint64);
      HANDLE_TYPE(DOUBLE, double);
      HANDLE_TYPE( FLOAT,  float);
      HANDLE_TYPE(  BOOL,   bool);
      HANDLE_TYPE(  ENUM,    int);
#undef HANDLE_TYPE

      case FieldDescriptor::CPPTYPE_STRING:
      case FieldDescriptor::CPPTYPE_MESSAGE:
        MutableRaw<RepeatedPtrFieldBase>(message, field)
            ->SwapElements(index1, index2);
        break;
    }
  }
}

namespace {
// Comparison functor for sorting FieldDescriptors by field number.
struct FieldNumberSorter {
  bool operator()(const FieldDescriptor* left,
                  const FieldDescriptor* right) const {
    return left->number() < right->number();
  }
};
}  // namespace

void GeneratedMessageReflection::ListFields(
    const Message& message,
    vector<const FieldDescriptor*>* output) const {
  output->clear();

  // Optimization:  The default instance never has any fields set.
  if (&message == default_instance_) return;

  for (int i = 0; i < descriptor_->field_count(); i++) {
    const FieldDescriptor* field = descriptor_->field(i);
    if (field->is_repeated()) {
      if (FieldSize(message, field) > 0) {
        output->push_back(field);
      }
    } else {
      if (HasBit(message, field)) {
        output->push_back(field);
      }
    }
  }

  if (extensions_offset_ != -1) {
    GetExtensionSet(message).AppendToList(descriptor_, descriptor_pool_,
                                          output);
  }

  // ListFields() must sort output by field number.
  sort(output->begin(), output->end(), FieldNumberSorter());
}

// -------------------------------------------------------------------

#undef DEFINE_PRIMITIVE_ACCESSORS
#define DEFINE_PRIMITIVE_ACCESSORS(TYPENAME, TYPE, PASSTYPE, CPPTYPE)        \
  PASSTYPE GeneratedMessageReflection::Get##TYPENAME(                        \
      const Message& message, const FieldDescriptor* field) const {          \
    USAGE_CHECK_ALL(Get##TYPENAME, SINGULAR, CPPTYPE);                       \
    if (field->is_extension()) {                                             \
      return GetExtensionSet(message).Get##TYPENAME(                         \
        field->number(), field->default_value_##PASSTYPE());                 \
    } else {                                                                 \
      return GetField<TYPE>(message, field);                                 \
    }                                                                        \
  }                                                                          \
                                                                             \
  void GeneratedMessageReflection::Set##TYPENAME(                            \
      Message* message, const FieldDescriptor* field,                        \
      PASSTYPE value) const {                                                \
    USAGE_CHECK_ALL(Set##TYPENAME, SINGULAR, CPPTYPE);                       \
    if (field->is_extension()) {                                             \
      return MutableExtensionSet(message)->Set##TYPENAME(                    \
        field->number(), field->type(), value, field);                       \
    } else {                                                                 \
      SetField<TYPE>(message, field, value);                                 \
    }                                                                        \
  }                                                                          \
                                                                             \
  PASSTYPE GeneratedMessageReflection::GetRepeated##TYPENAME(                \
      const Message& message,                                                \
      const FieldDescriptor* field, int index) const {                       \
    USAGE_CHECK_ALL(GetRepeated##TYPENAME, REPEATED, CPPTYPE);               \
    if (field->is_extension()) {                                             \
      return GetExtensionSet(message).GetRepeated##TYPENAME(                 \
        field->number(), index);                                             \
    } else {                                                                 \
      return GetRepeatedField<TYPE>(message, field, index);                  \
    }                                                                        \
  }                                                                          \
                                                                             \
  void GeneratedMessageReflection::SetRepeated##TYPENAME(                    \
      Message* message, const FieldDescriptor* field,                        \
      int index, PASSTYPE value) const {                                     \
    USAGE_CHECK_ALL(SetRepeated##TYPENAME, REPEATED, CPPTYPE);               \
    if (field->is_extension()) {                                             \
      MutableExtensionSet(message)->SetRepeated##TYPENAME(                   \
        field->number(), index, value);                                      \
    } else {                                                                 \
      SetRepeatedField<TYPE>(message, field, index, value);                  \
    }                                                                        \
  }                                                                          \
                                                                             \
  void GeneratedMessageReflection::Add##TYPENAME(                            \
      Message* message, const FieldDescriptor* field,                        \
      PASSTYPE value) const {                                                \
    USAGE_CHECK_ALL(Add##TYPENAME, REPEATED, CPPTYPE);                       \
    if (field->is_extension()) {                                             \
      MutableExtensionSet(message)->Add##TYPENAME(                           \
        field->number(), field->type(), field->options().packed(), value,    \
        field);                                                              \
    } else {                                                                 \
      AddField<TYPE>(message, field, value);                                 \
    }                                                                        \
  }

DEFINE_PRIMITIVE_ACCESSORS(Int32 , int32 , int32 , INT32 )
DEFINE_PRIMITIVE_ACCESSORS(Int64 , int64 , int64 , INT64 )
DEFINE_PRIMITIVE_ACCESSORS(UInt32, uint32, uint32, UINT32)
DEFINE_PRIMITIVE_ACCESSORS(UInt64, uint64, uint64, UINT64)
DEFINE_PRIMITIVE_ACCESSORS(Float , float , float , FLOAT )
DEFINE_PRIMITIVE_ACCESSORS(Double, double, double, DOUBLE)
DEFINE_PRIMITIVE_ACCESSORS(Bool  , bool  , bool  , BOOL  )
#undef DEFINE_PRIMITIVE_ACCESSORS

// -------------------------------------------------------------------

string GeneratedMessageReflection::GetString(
    const Message& message, const FieldDescriptor* field) const {
  USAGE_CHECK_ALL(GetString, SINGULAR, STRING);
  if (field->is_extension()) {
    return GetExtensionSet(message).GetString(field->number(),
                                              field->default_value_string());
  } else {
    switch (field->options().ctype()) {
      default:  // TODO(kenton):  Support other string reps.
      case FieldOptions::STRING:
        return *GetField<const string*>(message, field);
    }

    GOOGLE_LOG(FATAL) << "Can't get here.";
    return GetEmptyString();  // Make compiler happy.
  }
}

const string& GeneratedMessageReflection::GetStringReference(
    const Message& message,
    const FieldDescriptor* field, string* scratch) const {
  USAGE_CHECK_ALL(GetStringReference, SINGULAR, STRING);
  if (field->is_extension()) {
    return GetExtensionSet(message).GetString(field->number(),
                                              field->default_value_string());
  } else {
    switch (field->options().ctype()) {
      default:  // TODO(kenton):  Support other string reps.
      case FieldOptions::STRING:
        return *GetField<const string*>(message, field);
    }

    GOOGLE_LOG(FATAL) << "Can't get here.";
    return GetEmptyString();  // Make compiler happy.
  }
}


void GeneratedMessageReflection::SetString(
    Message* message, const FieldDescriptor* field,
    const string& value) const {
  USAGE_CHECK_ALL(SetString, SINGULAR, STRING);
  if (field->is_extension()) {
    return MutableExtensionSet(message)->SetString(field->number(),
                                                   field->type(), value, field);
  } else {
    switch (field->options().ctype()) {
      default:  // TODO(kenton):  Support other string reps.
      case FieldOptions::STRING: {
        string** ptr = MutableField<string*>(message, field);
        if (*ptr == DefaultRaw<const string*>(field)) {
          *ptr = new string(value);
        } else {
          (*ptr)->assign(value);
        }
        break;
      }
    }
  }
}


string GeneratedMessageReflection::GetRepeatedString(
    const Message& message, const FieldDescriptor* field, int index) const {
  USAGE_CHECK_ALL(GetRepeatedString, REPEATED, STRING);
  if (field->is_extension()) {
    return GetExtensionSet(message).GetRepeatedString(field->number(), index);
  } else {
    switch (field->options().ctype()) {
      default:  // TODO(kenton):  Support other string reps.
      case FieldOptions::STRING:
        return GetRepeatedPtrField<string>(message, field, index);
    }

    GOOGLE_LOG(FATAL) << "Can't get here.";
    return GetEmptyString();  // Make compiler happy.
  }
}

const string& GeneratedMessageReflection::GetRepeatedStringReference(
    const Message& message, const FieldDescriptor* field,
    int index, string* scratch) const {
  USAGE_CHECK_ALL(GetRepeatedStringReference, REPEATED, STRING);
  if (field->is_extension()) {
    return GetExtensionSet(message).GetRepeatedString(field->number(), index);
  } else {
    switch (field->options().ctype()) {
      default:  // TODO(kenton):  Support other string reps.
      case FieldOptions::STRING:
        return GetRepeatedPtrField<string>(message, field, index);
    }

    GOOGLE_LOG(FATAL) << "Can't get here.";
    return GetEmptyString();  // Make compiler happy.
  }
}


void GeneratedMessageReflection::SetRepeatedString(
    Message* message, const FieldDescriptor* field,
    int index, const string& value) const {
  USAGE_CHECK_ALL(SetRepeatedString, REPEATED, STRING);
  if (field->is_extension()) {
    MutableExtensionSet(message)->SetRepeatedString(
      field->number(), index, value);
  } else {
    switch (field->options().ctype()) {
      default:  // TODO(kenton):  Support other string reps.
      case FieldOptions::STRING:
        *MutableRepeatedField<string>(message, field, index) = value;
        break;
    }
  }
}


void GeneratedMessageReflection::AddString(
    Message* message, const FieldDescriptor* field,
    const string& value) const {
  USAGE_CHECK_ALL(AddString, REPEATED, STRING);
  if (field->is_extension()) {
    MutableExtensionSet(message)->AddString(field->number(),
                                            field->type(), value, field);
  } else {
    switch (field->options().ctype()) {
      default:  // TODO(kenton):  Support other string reps.
      case FieldOptions::STRING:
        *AddField<string>(message, field) = value;
        break;
    }
  }
}


// -------------------------------------------------------------------

const EnumValueDescriptor* GeneratedMessageReflection::GetEnum(
    const Message& message, const FieldDescriptor* field) const {
  USAGE_CHECK_ALL(GetEnum, SINGULAR, ENUM);

  int value;
  if (field->is_extension()) {
    value = GetExtensionSet(message).GetEnum(
      field->number(), field->default_value_enum()->number());
  } else {
    value = GetField<int>(message, field);
  }
  const EnumValueDescriptor* result =
    field->enum_type()->FindValueByNumber(value);
  GOOGLE_CHECK(result != NULL) << "Value " << value << " is not valid for field "
                        << field->full_name() << " of type "
                        << field->enum_type()->full_name() << ".";
  return result;
}

void GeneratedMessageReflection::SetEnum(
    Message* message, const FieldDescriptor* field,
    const EnumValueDescriptor* value) const {
  USAGE_CHECK_ALL(SetEnum, SINGULAR, ENUM);
  USAGE_CHECK_ENUM_VALUE(SetEnum);

  if (field->is_extension()) {
    MutableExtensionSet(message)->SetEnum(field->number(), field->type(),
                                          value->number(), field);
  } else {
    SetField<int>(message, field, value->number());
  }
}

const EnumValueDescriptor* GeneratedMessageReflection::GetRepeatedEnum(
    const Message& message, const FieldDescriptor* field, int index) const {
  USAGE_CHECK_ALL(GetRepeatedEnum, REPEATED, ENUM);

  int value;
  if (field->is_extension()) {
    value = GetExtensionSet(message).GetRepeatedEnum(field->number(), index);
  } else {
    value = GetRepeatedField<int>(message, field, index);
  }
  const EnumValueDescriptor* result =
    field->enum_type()->FindValueByNumber(value);
  GOOGLE_CHECK(result != NULL) << "Value " << value << " is not valid for field "
                        << field->full_name() << " of type "
                        << field->enum_type()->full_name() << ".";
  return result;
}

void GeneratedMessageReflection::SetRepeatedEnum(
    Message* message,
    const FieldDescriptor* field, int index,
    const EnumValueDescriptor* value) const {
  USAGE_CHECK_ALL(SetRepeatedEnum, REPEATED, ENUM);
  USAGE_CHECK_ENUM_VALUE(SetRepeatedEnum);

  if (field->is_extension()) {
    MutableExtensionSet(message)->SetRepeatedEnum(
      field->number(), index, value->number());
  } else {
    SetRepeatedField<int>(message, field, index, value->number());
  }
}

void GeneratedMessageReflection::AddEnum(
    Message* message, const FieldDescriptor* field,
    const EnumValueDescriptor* value) const {
  USAGE_CHECK_ALL(AddEnum, REPEATED, ENUM);
  USAGE_CHECK_ENUM_VALUE(AddEnum);

  if (field->is_extension()) {
    MutableExtensionSet(message)->AddEnum(field->number(), field->type(),
                                          field->options().packed(),
                                          value->number(), field);
  } else {
    AddField<int>(message, field, value->number());
  }
}

// -------------------------------------------------------------------

const Message& GeneratedMessageReflection::GetMessage(
    const Message& message, const FieldDescriptor* field,
    MessageFactory* factory) const {
  USAGE_CHECK_ALL(GetMessage, SINGULAR, MESSAGE);

  if (factory == NULL) factory = message_factory_;

  if (field->is_extension()) {
    return static_cast<const Message&>(
        GetExtensionSet(message).GetMessage(
          field->number(), field->message_type(), factory));
  } else {
    const Message* result;
    result = GetRaw<const Message*>(message, field);
    if (result == NULL) {
      result = DefaultRaw<const Message*>(field);
    }
    return *result;
  }
}

Message* GeneratedMessageReflection::MutableMessage(
    Message* message, const FieldDescriptor* field,
    MessageFactory* factory) const {
  USAGE_CHECK_ALL(MutableMessage, SINGULAR, MESSAGE);

  if (factory == NULL) factory = message_factory_;

  if (field->is_extension()) {
    return static_cast<Message*>(
        MutableExtensionSet(message)->MutableMessage(field, factory));
  } else {
    Message* result;
    Message** result_holder = MutableField<Message*>(message, field);
    if (*result_holder == NULL) {
      const Message* default_message = DefaultRaw<const Message*>(field);
      *result_holder = default_message->New();
    }
    result = *result_holder;
    return result;
  }
}

Message* GeneratedMessageReflection::ReleaseMessage(
    Message* message,
    const FieldDescriptor* field,
    MessageFactory* factory) const {
  USAGE_CHECK_ALL(ReleaseMessage, SINGULAR, MESSAGE);

  if (factory == NULL) factory = message_factory_;

  if (field->is_extension()) {
    return static_cast<Message*>(
        MutableExtensionSet(message)->ReleaseMessage(field, factory));
  } else {
    ClearBit(message, field);
    Message** result = MutableRaw<Message*>(message, field);
    Message* ret = *result;
    *result = NULL;
    return ret;
  }
}

const Message& GeneratedMessageReflection::GetRepeatedMessage(
    const Message& message, const FieldDescriptor* field, int index) const {
  USAGE_CHECK_ALL(GetRepeatedMessage, REPEATED, MESSAGE);

  if (field->is_extension()) {
    return static_cast<const Message&>(
        GetExtensionSet(message).GetRepeatedMessage(field->number(), index));
  } else {
    return GetRaw<RepeatedPtrFieldBase>(message, field)
        .Get<GenericTypeHandler<Message> >(index);
  }
}

Message* GeneratedMessageReflection::MutableRepeatedMessage(
    Message* message, const FieldDescriptor* field, int index) const {
  USAGE_CHECK_ALL(MutableRepeatedMessage, REPEATED, MESSAGE);

  if (field->is_extension()) {
    return static_cast<Message*>(
        MutableExtensionSet(message)->MutableRepeatedMessage(
          field->number(), index));
  } else {
    return MutableRaw<RepeatedPtrFieldBase>(message, field)
        ->Mutable<GenericTypeHandler<Message> >(index);
  }
}

Message* GeneratedMessageReflection::AddMessage(
    Message* message, const FieldDescriptor* field,
    MessageFactory* factory) const {
  USAGE_CHECK_ALL(AddMessage, REPEATED, MESSAGE);

  if (factory == NULL) factory = message_factory_;

  if (field->is_extension()) {
    return static_cast<Message*>(
        MutableExtensionSet(message)->AddMessage(field, factory));
  } else {
    // We can't use AddField<Message>() because RepeatedPtrFieldBase doesn't
    // know how to allocate one.
    RepeatedPtrFieldBase* repeated =
        MutableRaw<RepeatedPtrFieldBase>(message, field);
    Message* result = repeated->AddFromCleared<GenericTypeHandler<Message> >();
    if (result == NULL) {
      // We must allocate a new object.
      const Message* prototype;
      if (repeated->size() == 0) {
        prototype = factory->GetPrototype(field->message_type());
      } else {
        prototype = &repeated->Get<GenericTypeHandler<Message> >(0);
      }
      result = prototype->New();
      repeated->AddAllocated<GenericTypeHandler<Message> >(result);
    }
    return result;
  }
}

void* GeneratedMessageReflection::MutableRawRepeatedField(
    Message* message, const FieldDescriptor* field,
    FieldDescriptor::CppType cpptype,
    int ctype, const Descriptor* desc) const {
  USAGE_CHECK_REPEATED("MutableRawRepeatedField");
  if (field->cpp_type() != cpptype)
    ReportReflectionUsageTypeError(descriptor_,
        field, "MutableRawRepeatedField", cpptype);
  if (ctype >= 0)
    GOOGLE_CHECK_EQ(field->options().ctype(), ctype) << "subtype mismatch";
  if (desc != NULL)
    GOOGLE_CHECK_EQ(field->message_type(), desc) << "wrong submessage type";
  if (field->is_extension())
    return MutableExtensionSet(message)->MutableRawRepeatedField(
        field->number());
  else
    return reinterpret_cast<uint8*>(message) + offsets_[field->index()];
}

// -----------------------------------------------------------------------------

const FieldDescriptor* GeneratedMessageReflection::FindKnownExtensionByName(
    const string& name) const {
  if (extensions_offset_ == -1) return NULL;

  const FieldDescriptor* result = descriptor_pool_->FindExtensionByName(name);
  if (result != NULL && result->containing_type() == descriptor_) {
    return result;
  }

  if (descriptor_->options().message_set_wire_format()) {
    // MessageSet extensions may be identified by type name.
    const Descriptor* type = descriptor_pool_->FindMessageTypeByName(name);
    if (type != NULL) {
      // Look for a matching extension in the foreign type's scope.
      for (int i = 0; i < type->extension_count(); i++) {
        const FieldDescriptor* extension = type->extension(i);
        if (extension->containing_type() == descriptor_ &&
            extension->type() == FieldDescriptor::TYPE_MESSAGE &&
            extension->is_optional() &&
            extension->message_type() == type) {
          // Found it.
          return extension;
        }
      }
    }
  }

  return NULL;
}

const FieldDescriptor* GeneratedMessageReflection::FindKnownExtensionByNumber(
    int number) const {
  if (extensions_offset_ == -1) return NULL;
  return descriptor_pool_->FindExtensionByNumber(descriptor_, number);
}

// ===================================================================
// Some private helpers.

// These simple template accessors obtain pointers (or references) to
// the given field.
template <typename Type>
inline const Type& GeneratedMessageReflection::GetRaw(
    const Message& message, const FieldDescriptor* field) const {
  const void* ptr = reinterpret_cast<const uint8*>(&message) +
                    offsets_[field->index()];
  return *reinterpret_cast<const Type*>(ptr);
}

template <typename Type>
inline Type* GeneratedMessageReflection::MutableRaw(
    Message* message, const FieldDescriptor* field) const {
  void* ptr = reinterpret_cast<uint8*>(message) + offsets_[field->index()];
  return reinterpret_cast<Type*>(ptr);
}

template <typename Type>
inline const Type& GeneratedMessageReflection::DefaultRaw(
    const FieldDescriptor* field) const {
  const void* ptr = reinterpret_cast<const uint8*>(default_instance_) +
                    offsets_[field->index()];
  return *reinterpret_cast<const Type*>(ptr);
}

inline const uint32* GeneratedMessageReflection::GetHasBits(
    const Message& message) const {
  const void* ptr = reinterpret_cast<const uint8*>(&message) + has_bits_offset_;
  return reinterpret_cast<const uint32*>(ptr);
}
inline uint32* GeneratedMessageReflection::MutableHasBits(
    Message* message) const {
  void* ptr = reinterpret_cast<uint8*>(message) + has_bits_offset_;
  return reinterpret_cast<uint32*>(ptr);
}

inline const ExtensionSet& GeneratedMessageReflection::GetExtensionSet(
    const Message& message) const {
  GOOGLE_DCHECK_NE(extensions_offset_, -1);
  const void* ptr = reinterpret_cast<const uint8*>(&message) +
                    extensions_offset_;
  return *reinterpret_cast<const ExtensionSet*>(ptr);
}
inline ExtensionSet* GeneratedMessageReflection::MutableExtensionSet(
    Message* message) const {
  GOOGLE_DCHECK_NE(extensions_offset_, -1);
  void* ptr = reinterpret_cast<uint8*>(message) + extensions_offset_;
  return reinterpret_cast<ExtensionSet*>(ptr);
}

// Simple accessors for manipulating has_bits_.
inline bool GeneratedMessageReflection::HasBit(
    const Message& message, const FieldDescriptor* field) const {
  return GetHasBits(message)[field->index() / 32] &
    (1 << (field->index() % 32));
}

inline void GeneratedMessageReflection::SetBit(
    Message* message, const FieldDescriptor* field) const {
  MutableHasBits(message)[field->index() / 32] |= (1 << (field->index() % 32));
}

inline void GeneratedMessageReflection::ClearBit(
    Message* message, const FieldDescriptor* field) const {
  MutableHasBits(message)[field->index() / 32] &= ~(1 << (field->index() % 32));
}

// Template implementations of basic accessors.  Inline because each
// template instance is only called from one location.  These are
// used for all types except messages.
template <typename Type>
inline const Type& GeneratedMessageReflection::GetField(
    const Message& message, const FieldDescriptor* field) const {
  return GetRaw<Type>(message, field);
}

template <typename Type>
inline void GeneratedMessageReflection::SetField(
    Message* message, const FieldDescriptor* field, const Type& value) const {
  *MutableRaw<Type>(message, field) = value;
  SetBit(message, field);
}

template <typename Type>
inline Type* GeneratedMessageReflection::MutableField(
    Message* message, const FieldDescriptor* field) const {
  SetBit(message, field);
  return MutableRaw<Type>(message, field);
}

template <typename Type>
inline const Type& GeneratedMessageReflection::GetRepeatedField(
    const Message& message, const FieldDescriptor* field, int index) const {
  return GetRaw<RepeatedField<Type> >(message, field).Get(index);
}

template <typename Type>
inline const Type& GeneratedMessageReflection::GetRepeatedPtrField(
    const Message& message, const FieldDescriptor* field, int index) const {
  return GetRaw<RepeatedPtrField<Type> >(message, field).Get(index);
}

template <typename Type>
inline void GeneratedMessageReflection::SetRepeatedField(
    Message* message, const FieldDescriptor* field,
    int index, Type value) const {
  MutableRaw<RepeatedField<Type> >(message, field)->Set(index, value);
}

template <typename Type>
inline Type* GeneratedMessageReflection::MutableRepeatedField(
    Message* message, const FieldDescriptor* field, int index) const {
  RepeatedPtrField<Type>* repeated =
    MutableRaw<RepeatedPtrField<Type> >(message, field);
  return repeated->Mutable(index);
}

template <typename Type>
inline void GeneratedMessageReflection::AddField(
    Message* message, const FieldDescriptor* field, const Type& value) const {
  MutableRaw<RepeatedField<Type> >(message, field)->Add(value);
}

template <typename Type>
inline Type* GeneratedMessageReflection::AddField(
    Message* message, const FieldDescriptor* field) const {
  RepeatedPtrField<Type>* repeated =
    MutableRaw<RepeatedPtrField<Type> >(message, field);
  return repeated->Add();
}

}  // namespace internal
}  // namespace protobuf
}  // namespace google
