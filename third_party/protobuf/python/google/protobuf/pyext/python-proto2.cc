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

// Author: petar@google.com (Petar Petrov)

#include <Python.h>
#include <map>
#include <string>
#include <vector>

#include <google/protobuf/stubs/common.h>
#include <google/protobuf/pyext/python_descriptor.h>
#include <google/protobuf/io/coded_stream.h>
#include <google/protobuf/descriptor.h>
#include <google/protobuf/dynamic_message.h>
#include <google/protobuf/message.h>
#include <google/protobuf/unknown_field_set.h>
#include <google/protobuf/pyext/python_protobuf.h>

/* Is 64bit */
#define IS_64BIT (SIZEOF_LONG == 8)

#define FIELD_BELONGS_TO_MESSAGE(field_descriptor, message) \
    ((message)->GetDescriptor() == (field_descriptor)->containing_type())

#define FIELD_IS_REPEATED(field_descriptor)                 \
    ((field_descriptor)->label() == google::protobuf::FieldDescriptor::LABEL_REPEATED)

#define GOOGLE_CHECK_GET_INT32(arg, value)                         \
    int32 value;                                            \
    if (!CheckAndGetInteger(arg, &value, kint32min_py, kint32max_py)) { \
      return NULL;                                          \
    }

#define GOOGLE_CHECK_GET_INT64(arg, value)                         \
    int64 value;                                            \
    if (!CheckAndGetInteger(arg, &value, kint64min_py, kint64max_py)) { \
      return NULL;                                          \
    }

#define GOOGLE_CHECK_GET_UINT32(arg, value)                        \
    uint32 value;                                           \
    if (!CheckAndGetInteger(arg, &value, kPythonZero, kuint32max_py)) { \
      return NULL;                                          \
    }

#define GOOGLE_CHECK_GET_UINT64(arg, value)                        \
    uint64 value;                                           \
    if (!CheckAndGetInteger(arg, &value, kPythonZero, kuint64max_py)) { \
      return NULL;                                          \
    }

#define GOOGLE_CHECK_GET_FLOAT(arg, value)                         \
    float value;                                            \
    if (!CheckAndGetFloat(arg, &value)) {                   \
      return NULL;                                          \
    }                                                       \

#define GOOGLE_CHECK_GET_DOUBLE(arg, value)                        \
    double value;                                           \
    if (!CheckAndGetDouble(arg, &value)) {                  \
      return NULL;                                          \
    }

#define GOOGLE_CHECK_GET_BOOL(arg, value)                          \
    bool value;                                             \
    if (!CheckAndGetBool(arg, &value)) {                    \
      return NULL;                                          \
    }

#define C(str) const_cast<char*>(str)

// --- Globals:

// Constants used for integer type range checking.
static PyObject* kPythonZero;
static PyObject* kint32min_py;
static PyObject* kint32max_py;
static PyObject* kuint32max_py;
static PyObject* kint64min_py;
static PyObject* kint64max_py;
static PyObject* kuint64max_py;

namespace google {
namespace protobuf {
namespace python {

// --- Support Routines:

static void AddConstants(PyObject* module) {
  struct NameValue {
    char* name;
    int32 value;
  } constants[] = {
    // Labels:
    {"LABEL_OPTIONAL", google::protobuf::FieldDescriptor::LABEL_OPTIONAL},
    {"LABEL_REQUIRED", google::protobuf::FieldDescriptor::LABEL_REQUIRED},
    {"LABEL_REPEATED", google::protobuf::FieldDescriptor::LABEL_REPEATED},
    // CPP types:
    {"CPPTYPE_MESSAGE", google::protobuf::FieldDescriptor::CPPTYPE_MESSAGE},
    // Field Types:
    {"TYPE_MESSAGE", google::protobuf::FieldDescriptor::TYPE_MESSAGE},
    // End.
    {NULL, 0}
  };

  for (NameValue* constant = constants;
       constant->name != NULL; constant++) {
    PyModule_AddIntConstant(module, constant->name, constant->value);
  }
}

// --- CMessage Custom Type:

// ------ Type Forward Declaration:

struct CMessage;
struct CMessage_Type;

static void CMessageDealloc(CMessage* self);
static int CMessageInit(CMessage* self, PyObject *args, PyObject *kwds);
static PyObject* CMessageStr(CMessage* self);

static PyObject* CMessage_AddMessage(CMessage* self, PyObject* args);
static PyObject* CMessage_AddRepeatedScalar(CMessage* self, PyObject* args);
static PyObject* CMessage_AssignRepeatedScalar(CMessage* self, PyObject* args);
static PyObject* CMessage_ByteSize(CMessage* self, PyObject* args);
static PyObject* CMessage_Clear(CMessage* self, PyObject* args);
static PyObject* CMessage_ClearField(CMessage* self, PyObject* args);
static PyObject* CMessage_ClearFieldByDescriptor(
    CMessage* self, PyObject* args);
static PyObject* CMessage_CopyFrom(CMessage* self, PyObject* args);
static PyObject* CMessage_DebugString(CMessage* self, PyObject* args);
static PyObject* CMessage_DeleteRepeatedField(CMessage* self, PyObject* args);
static PyObject* CMessage_Equals(CMessage* self, PyObject* args);
static PyObject* CMessage_FieldLength(CMessage* self, PyObject* args);
static PyObject* CMessage_FindInitializationErrors(CMessage* self);
static PyObject* CMessage_GetRepeatedMessage(CMessage* self, PyObject* args);
static PyObject* CMessage_GetRepeatedScalar(CMessage* self, PyObject* args);
static PyObject* CMessage_GetScalar(CMessage* self, PyObject* args);
static PyObject* CMessage_HasField(CMessage* self, PyObject* args);
static PyObject* CMessage_HasFieldByDescriptor(CMessage* self, PyObject* args);
static PyObject* CMessage_IsInitialized(CMessage* self, PyObject* args);
static PyObject* CMessage_ListFields(CMessage* self, PyObject* args);
static PyObject* CMessage_MergeFrom(CMessage* self, PyObject* args);
static PyObject* CMessage_MergeFromString(CMessage* self, PyObject* args);
static PyObject* CMessage_MutableMessage(CMessage* self, PyObject* args);
static PyObject* CMessage_NewSubMessage(CMessage* self, PyObject* args);
static PyObject* CMessage_SetScalar(CMessage* self, PyObject* args);
static PyObject* CMessage_SerializePartialToString(
    CMessage* self, PyObject* args);
static PyObject* CMessage_SerializeToString(CMessage* self, PyObject* args);
static PyObject* CMessage_SetInParent(CMessage* self, PyObject* args);
static PyObject* CMessage_SwapRepeatedFieldElements(
    CMessage* self, PyObject* args);

// ------ Object Definition:

typedef struct CMessage {
  PyObject_HEAD

  struct CMessage* parent;  // NULL if wasn't created from another message.
  CFieldDescriptor* parent_field;
  const char* full_name;
  google::protobuf::Message* message;
  bool free_message;
  bool read_only;
} CMessage;

// ------ Method Table:

#define CMETHOD(name, args, doc)   \
  { C(#name), (PyCFunction)CMessage_##name, args, C(doc) }
static PyMethodDef CMessageMethods[] = {
  CMETHOD(AddMessage, METH_O,
          "Adds a new message to a repeated composite field."),
  CMETHOD(AddRepeatedScalar, METH_VARARGS,
          "Adds a scalar to a repeated scalar field."),
  CMETHOD(AssignRepeatedScalar, METH_VARARGS,
          "Clears and sets the values of a repeated scalar field."),
  CMETHOD(ByteSize, METH_NOARGS,
          "Returns the size of the message in bytes."),
  CMETHOD(Clear, METH_O,
          "Clears a protocol message."),
  CMETHOD(ClearField, METH_VARARGS,
          "Clears a protocol message field by name."),
  CMETHOD(ClearFieldByDescriptor, METH_O,
          "Clears a protocol message field by descriptor."),
  CMETHOD(CopyFrom, METH_O,
          "Copies a protocol message into the current message."),
  CMETHOD(DebugString, METH_NOARGS,
          "Returns the debug string of a protocol message."),
  CMETHOD(DeleteRepeatedField, METH_VARARGS,
          "Deletes a slice of values from a repeated field."),
  CMETHOD(Equals, METH_O,
          "Checks if two protocol messages are equal (by identity)."),
  CMETHOD(FieldLength, METH_O,
          "Returns the number of elements in a repeated field."),
  CMETHOD(FindInitializationErrors, METH_NOARGS,
          "Returns the initialization errors of a message."),
  CMETHOD(GetRepeatedMessage, METH_VARARGS,
          "Returns a message from a repeated composite field."),
  CMETHOD(GetRepeatedScalar, METH_VARARGS,
          "Returns a scalar value from a repeated scalar field."),
  CMETHOD(GetScalar, METH_O,
          "Returns the scalar value of a field."),
  CMETHOD(HasField, METH_O,
          "Checks if a message field is set."),
  CMETHOD(HasFieldByDescriptor, METH_O,
          "Checks if a message field is set by given its descriptor"),
  CMETHOD(IsInitialized, METH_NOARGS,
          "Checks if all required fields of a protocol message are set."),
  CMETHOD(ListFields, METH_NOARGS,
          "Lists all set fields of a message."),
  CMETHOD(MergeFrom, METH_O,
          "Merges a protocol message into the current message."),
  CMETHOD(MergeFromString, METH_O,
          "Merges a serialized message into the current message."),
  CMETHOD(MutableMessage, METH_O,
          "Returns a new instance of a nested protocol message."),
  CMETHOD(NewSubMessage, METH_O,
          "Creates and returns a python message given the descriptor of a "
          "composite field of the current message."),
  CMETHOD(SetScalar, METH_VARARGS,
          "Sets the value of a singular scalar field."),
  CMETHOD(SerializePartialToString, METH_VARARGS,
          "Serializes the message to a string, even if it isn't initialized."),
  CMETHOD(SerializeToString, METH_NOARGS,
          "Serializes the message to a string, only for initialized messages."),
  CMETHOD(SetInParent, METH_NOARGS,
          "Sets the has bit of the given field in its parent message."),
  CMETHOD(SwapRepeatedFieldElements, METH_VARARGS,
          "Swaps the elements in two positions in a repeated field."),
  { NULL, NULL }
};
#undef CMETHOD

static PyMemberDef CMessageMembers[] = {
  { C("full_name"), T_STRING, offsetof(CMessage, full_name), 0, "Full name" },
  { NULL }
};

// ------ Type Definition:

// The definition for the type object that captures the type of CMessage
// in Python.
PyTypeObject CMessage_Type = {
  PyObject_HEAD_INIT(&PyType_Type)
  0,
  C("google.protobuf.internal."
    "_net_proto2___python."
    "CMessage"),                       // tp_name
  sizeof(CMessage),                    //  tp_basicsize
  0,                                   //  tp_itemsize
  (destructor)CMessageDealloc,         //  tp_dealloc
  0,                                   //  tp_print
  0,                                   //  tp_getattr
  0,                                   //  tp_setattr
  0,                                   //  tp_compare
  0,                                   //  tp_repr
  0,                                   //  tp_as_number
  0,                                   //  tp_as_sequence
  0,                                   //  tp_as_mapping
  0,                                   //  tp_hash
  0,                                   //  tp_call
  (reprfunc)CMessageStr,               //  tp_str
  0,                                   //  tp_getattro
  0,                                   //  tp_setattro
  0,                                   //  tp_as_buffer
  Py_TPFLAGS_DEFAULT,                  //  tp_flags
  C("A ProtocolMessage"),              //  tp_doc
  0,                                   //  tp_traverse
  0,                                   //  tp_clear
  0,                                   //  tp_richcompare
  0,                                   //  tp_weaklistoffset
  0,                                   //  tp_iter
  0,                                   //  tp_iternext
  CMessageMethods,                     //  tp_methods
  CMessageMembers,                     //  tp_members
  0,                                   //  tp_getset
  0,                                   //  tp_base
  0,                                   //  tp_dict
  0,                                   //  tp_descr_get
  0,                                   //  tp_descr_set
  0,                                   //  tp_dictoffset
  (initproc)CMessageInit,              //  tp_init
  PyType_GenericAlloc,                 //  tp_alloc
  PyType_GenericNew,                   //  tp_new
  PyObject_Del,                        //  tp_free
};

// ------ Helper Functions:

static void FormatTypeError(PyObject* arg, char* expected_types) {
  PyObject* repr = PyObject_Repr(arg);
  PyErr_Format(PyExc_TypeError,
               "%.100s has type %.100s, but expected one of: %s",
               PyString_AS_STRING(repr),
               arg->ob_type->tp_name,
               expected_types);
  Py_DECREF(repr);
}

template <class T>
static bool CheckAndGetInteger(
    PyObject* arg, T* value, PyObject* min, PyObject* max) {
  bool is_long = PyLong_Check(arg);
  if (!PyInt_Check(arg) && !is_long) {
    FormatTypeError(arg, "int, long");
    return false;
  }

  if (PyObject_Compare(min, arg) > 0 || PyObject_Compare(max, arg) < 0) {
    PyObject* s = PyObject_Str(arg);
    PyErr_Format(PyExc_ValueError,
                 "Value out of range: %s",
                 PyString_AS_STRING(s));
    Py_DECREF(s);
    return false;
  }
  if (is_long) {
    if (min == kPythonZero) {
      *value = static_cast<T>(PyLong_AsUnsignedLongLong(arg));
    } else {
      *value = static_cast<T>(PyLong_AsLongLong(arg));
    }
  } else {
    *value = static_cast<T>(PyInt_AsLong(arg));
  }
  return true;
}

static bool CheckAndGetDouble(PyObject* arg, double* value) {
  if (!PyInt_Check(arg) && !PyLong_Check(arg) &&
      !PyFloat_Check(arg)) {
    FormatTypeError(arg, "int, long, float");
    return false;
  }
  *value = PyFloat_AsDouble(arg);
  return true;
}

static bool CheckAndGetFloat(PyObject* arg, float* value) {
  double double_value;
  if (!CheckAndGetDouble(arg, &double_value)) {
    return false;
  }
  *value = static_cast<float>(double_value);
  return true;
}

static bool CheckAndGetBool(PyObject* arg, bool* value) {
  if (!PyInt_Check(arg) && !PyBool_Check(arg) && !PyLong_Check(arg)) {
    FormatTypeError(arg, "int, long, bool");
    return false;
  }
  *value = static_cast<bool>(PyInt_AsLong(arg));
  return true;
}

google::protobuf::DynamicMessageFactory* global_message_factory = NULL;
static const google::protobuf::Message* CreateMessage(const char* message_type) {
  string message_name(message_type);
  const google::protobuf::Descriptor* descriptor =
      GetDescriptorPool()->FindMessageTypeByName(message_name);
  if (descriptor == NULL) {
    return NULL;
  }
  return global_message_factory->GetPrototype(descriptor);
}

static void ReleaseSubMessage(google::protobuf::Message* message,
                           const google::protobuf::FieldDescriptor* field_descriptor,
                           CMessage* child_cmessage) {
  Message* released_message = message->GetReflection()->ReleaseMessage(
      message, field_descriptor, global_message_factory);
  GOOGLE_DCHECK(child_cmessage->message != NULL);
  // ReleaseMessage will return NULL which differs from
  // child_cmessage->message, if the field does not exist.  In this case,
  // the latter points to the default instance via a const_cast<>, so we
  // have to reset it to a new mutable object since we are taking ownership.
  if (released_message == NULL) {
    const Message* prototype = global_message_factory->GetPrototype(
        child_cmessage->message->GetDescriptor());
    GOOGLE_DCHECK(prototype != NULL);
    child_cmessage->message = prototype->New();
  }
  child_cmessage->parent = NULL;
  child_cmessage->parent_field = NULL;
  child_cmessage->free_message = true;
  child_cmessage->read_only = false;
}

static bool CheckAndSetString(
    PyObject* arg, google::protobuf::Message* message,
    const google::protobuf::FieldDescriptor* descriptor,
    const google::protobuf::Reflection* reflection,
    bool append,
    int index) {
  GOOGLE_DCHECK(descriptor->type() == google::protobuf::FieldDescriptor::TYPE_STRING ||
         descriptor->type() == google::protobuf::FieldDescriptor::TYPE_BYTES);
  if (descriptor->type() == google::protobuf::FieldDescriptor::TYPE_STRING) {
    if (!PyString_Check(arg) && !PyUnicode_Check(arg)) {
      FormatTypeError(arg, "str, unicode");
      return false;
    }

    if (PyString_Check(arg)) {
      PyObject* unicode = PyUnicode_FromEncodedObject(arg, "ascii", NULL);
      if (unicode == NULL) {
        PyObject* repr = PyObject_Repr(arg);
        PyErr_Format(PyExc_ValueError,
                     "%s has type str, but isn't in 7-bit ASCII "
                     "encoding. Non-ASCII strings must be converted to "
                     "unicode objects before being added.",
                     PyString_AS_STRING(repr));
        Py_DECREF(repr);
        return false;
      } else {
        Py_DECREF(unicode);
      }
    }
  } else if (!PyString_Check(arg)) {
    FormatTypeError(arg, "str");
    return false;
  }

  PyObject* encoded_string = NULL;
  if (descriptor->type() == google::protobuf::FieldDescriptor::TYPE_STRING) {
    if (PyString_Check(arg)) {
      encoded_string = PyString_AsEncodedObject(arg, "utf-8", NULL);
    } else {
      encoded_string = PyUnicode_AsEncodedObject(arg, "utf-8", NULL);
    }
  } else {
    // In this case field type is "bytes".
    encoded_string = arg;
    Py_INCREF(encoded_string);
  }

  if (encoded_string == NULL) {
    return false;
  }

  char* value;
  Py_ssize_t value_len;
  if (PyString_AsStringAndSize(encoded_string, &value, &value_len) < 0) {
    Py_DECREF(encoded_string);
    return false;
  }

  string value_string(value, value_len);
  if (append) {
    reflection->AddString(message, descriptor, value_string);
  } else if (index < 0) {
    reflection->SetString(message, descriptor, value_string);
  } else {
    reflection->SetRepeatedString(message, descriptor, index, value_string);
  }
  Py_DECREF(encoded_string);
  return true;
}

static PyObject* ToStringObject(
    const google::protobuf::FieldDescriptor* descriptor, string value) {
  if (descriptor->type() != google::protobuf::FieldDescriptor::TYPE_STRING) {
    return PyString_FromStringAndSize(value.c_str(), value.length());
  }

  PyObject* result = PyUnicode_DecodeUTF8(value.c_str(), value.length(), NULL);
  // If the string can't be decoded in UTF-8, just return a string object that
  // contains the raw bytes. This can't happen if the value was assigned using
  // the members of the Python message object, but can happen if the values were
  // parsed from the wire (binary).
  if (result == NULL) {
    PyErr_Clear();
    result = PyString_FromStringAndSize(value.c_str(), value.length());
  }
  return result;
}

static void AssureWritable(CMessage* self) {
  if (self == NULL ||
      self->parent == NULL ||
      self->parent_field == NULL) {
    return;
  }

  if (!self->read_only) {
    return;
  }

  AssureWritable(self->parent);

  google::protobuf::Message* message = self->parent->message;
  const google::protobuf::Reflection* reflection = message->GetReflection();
  self->message = reflection->MutableMessage(
      message, self->parent_field->descriptor, global_message_factory);
  self->read_only = false;
}

static PyObject* InternalGetScalar(
    google::protobuf::Message* message,
    const google::protobuf::FieldDescriptor* field_descriptor) {
  const google::protobuf::Reflection* reflection = message->GetReflection();

  if (!FIELD_BELONGS_TO_MESSAGE(field_descriptor, message)) {
    PyErr_SetString(
        PyExc_KeyError, "Field does not belong to message!");
    return NULL;
  }

  PyObject* result = NULL;
  switch (field_descriptor->cpp_type()) {
    case google::protobuf::FieldDescriptor::CPPTYPE_INT32: {
      int32 value = reflection->GetInt32(*message, field_descriptor);
      result = PyInt_FromLong(value);
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_INT64: {
      int64 value = reflection->GetInt64(*message, field_descriptor);
#if IS_64BIT
      result = PyInt_FromLong(value);
#else
      result = PyLong_FromLongLong(value);
#endif
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_UINT32: {
      uint32 value = reflection->GetUInt32(*message, field_descriptor);
#if IS_64BIT
      result = PyInt_FromLong(value);
#else
      result = PyLong_FromLongLong(value);
#endif
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_UINT64: {
      uint64 value = reflection->GetUInt64(*message, field_descriptor);
#if IS_64BIT
      if (value <= static_cast<uint64>(kint64max)) {
        result = PyInt_FromLong(static_cast<uint64>(value));
      }
#else
      if (value <= static_cast<uint32>(kint32max)) {
        result = PyInt_FromLong(static_cast<uint32>(value));
      }
#endif
      else {  // NOLINT
        result = PyLong_FromUnsignedLongLong(value);
      }
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_FLOAT: {
      float value = reflection->GetFloat(*message, field_descriptor);
      result = PyFloat_FromDouble(value);
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_DOUBLE: {
      double value = reflection->GetDouble(*message, field_descriptor);
      result = PyFloat_FromDouble(value);
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_BOOL: {
      bool value = reflection->GetBool(*message, field_descriptor);
      result = PyBool_FromLong(value);
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_STRING: {
      string value = reflection->GetString(*message, field_descriptor);
      result = ToStringObject(field_descriptor, value);
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_ENUM: {
      if (!message->GetReflection()->HasField(*message, field_descriptor)) {
        // Look for the value in the unknown fields.
        google::protobuf::UnknownFieldSet* unknown_field_set =
            message->GetReflection()->MutableUnknownFields(message);
        for (int i = 0; i < unknown_field_set->field_count(); ++i) {
          if (unknown_field_set->field(i).number() ==
              field_descriptor->number()) {
            result = PyInt_FromLong(unknown_field_set->field(i).varint());
            break;
          }
        }
      }

      if (result == NULL) {
        const google::protobuf::EnumValueDescriptor* enum_value =
            message->GetReflection()->GetEnum(*message, field_descriptor);
        result = PyInt_FromLong(enum_value->number());
      }
      break;
    }
    default:
      PyErr_Format(
          PyExc_SystemError, "Getting a value from a field of unknown type %d",
          field_descriptor->cpp_type());
  }

  return result;
}

static PyObject* InternalSetScalar(
    google::protobuf::Message* message, const google::protobuf::FieldDescriptor* field_descriptor,
    PyObject* arg) {
  const google::protobuf::Reflection* reflection = message->GetReflection();

  if (!FIELD_BELONGS_TO_MESSAGE(field_descriptor, message)) {
    PyErr_SetString(
        PyExc_KeyError, "Field does not belong to message!");
    return NULL;
  }

  switch (field_descriptor->cpp_type()) {
    case google::protobuf::FieldDescriptor::CPPTYPE_INT32: {
      GOOGLE_CHECK_GET_INT32(arg, value);
      reflection->SetInt32(message, field_descriptor, value);
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_INT64: {
      GOOGLE_CHECK_GET_INT64(arg, value);
      reflection->SetInt64(message, field_descriptor, value);
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_UINT32: {
      GOOGLE_CHECK_GET_UINT32(arg, value);
      reflection->SetUInt32(message, field_descriptor, value);
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_UINT64: {
      GOOGLE_CHECK_GET_UINT64(arg, value);
      reflection->SetUInt64(message, field_descriptor, value);
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_FLOAT: {
      GOOGLE_CHECK_GET_FLOAT(arg, value);
      reflection->SetFloat(message, field_descriptor, value);
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_DOUBLE: {
      GOOGLE_CHECK_GET_DOUBLE(arg, value);
      reflection->SetDouble(message, field_descriptor, value);
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_BOOL: {
      GOOGLE_CHECK_GET_BOOL(arg, value);
      reflection->SetBool(message, field_descriptor, value);
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_STRING: {
      if (!CheckAndSetString(
          arg, message, field_descriptor, reflection, false, -1)) {
        return NULL;
      }
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_ENUM: {
      GOOGLE_CHECK_GET_INT32(arg, value);
      const google::protobuf::EnumDescriptor* enum_descriptor =
          field_descriptor->enum_type();
      const google::protobuf::EnumValueDescriptor* enum_value =
          enum_descriptor->FindValueByNumber(value);
      if (enum_value != NULL) {
        reflection->SetEnum(message, field_descriptor, enum_value);
      } else {
        bool added = false;
        // Add the value to the unknown fields.
        google::protobuf::UnknownFieldSet* unknown_field_set =
            message->GetReflection()->MutableUnknownFields(message);
        for (int i = 0; i < unknown_field_set->field_count(); ++i) {
          if (unknown_field_set->field(i).number() ==
              field_descriptor->number()) {
            unknown_field_set->mutable_field(i)->set_varint(value);
            added = true;
            break;
          }
        }

        if (!added) {
          unknown_field_set->AddVarint(field_descriptor->number(), value);
        }
        reflection->ClearField(message, field_descriptor);
      }
      break;
    }
    default:
      PyErr_Format(
          PyExc_SystemError, "Setting value to a field of unknown type %d",
          field_descriptor->cpp_type());
  }

  Py_RETURN_NONE;
}

static PyObject* InternalAddRepeatedScalar(
    google::protobuf::Message* message, const google::protobuf::FieldDescriptor* field_descriptor,
    PyObject* arg) {

  if (!FIELD_BELONGS_TO_MESSAGE(field_descriptor, message)) {
    PyErr_SetString(
        PyExc_KeyError, "Field does not belong to message!");
    return NULL;
  }

  const google::protobuf::Reflection* reflection = message->GetReflection();
  switch (field_descriptor->cpp_type()) {
    case google::protobuf::FieldDescriptor::CPPTYPE_INT32: {
      GOOGLE_CHECK_GET_INT32(arg, value);
      reflection->AddInt32(message, field_descriptor, value);
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_INT64: {
      GOOGLE_CHECK_GET_INT64(arg, value);
      reflection->AddInt64(message, field_descriptor, value);
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_UINT32: {
      GOOGLE_CHECK_GET_UINT32(arg, value);
      reflection->AddUInt32(message, field_descriptor, value);
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_UINT64: {
      GOOGLE_CHECK_GET_UINT64(arg, value);
      reflection->AddUInt64(message, field_descriptor, value);
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_FLOAT: {
      GOOGLE_CHECK_GET_FLOAT(arg, value);
      reflection->AddFloat(message, field_descriptor, value);
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_DOUBLE: {
      GOOGLE_CHECK_GET_DOUBLE(arg, value);
      reflection->AddDouble(message, field_descriptor, value);
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_BOOL: {
      GOOGLE_CHECK_GET_BOOL(arg, value);
      reflection->AddBool(message, field_descriptor, value);
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_STRING: {
      if (!CheckAndSetString(
          arg, message, field_descriptor, reflection, true, -1)) {
        return NULL;
      }
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_ENUM: {
      GOOGLE_CHECK_GET_INT32(arg, value);
      const google::protobuf::EnumDescriptor* enum_descriptor =
          field_descriptor->enum_type();
      const google::protobuf::EnumValueDescriptor* enum_value =
          enum_descriptor->FindValueByNumber(value);
      if (enum_value != NULL) {
        reflection->AddEnum(message, field_descriptor, enum_value);
      } else {
        PyObject* s = PyObject_Str(arg);
        PyErr_Format(PyExc_ValueError, "Unknown enum value: %s",
                     PyString_AS_STRING(s));
        Py_DECREF(s);
        return NULL;
      }
      break;
    }
    default:
      PyErr_Format(
          PyExc_SystemError, "Adding value to a field of unknown type %d",
          field_descriptor->cpp_type());
  }

  Py_RETURN_NONE;
}

static PyObject* InternalGetRepeatedScalar(
    CMessage* cmessage, const google::protobuf::FieldDescriptor* field_descriptor,
    int index) {
  google::protobuf::Message* message = cmessage->message;
  const google::protobuf::Reflection* reflection = message->GetReflection();

  int field_size = reflection->FieldSize(*message, field_descriptor);
  if (index < 0) {
    index = field_size + index;
  }
  if (index < 0 || index >= field_size) {
    PyErr_Format(PyExc_IndexError,
                 "list assignment index (%d) out of range", index);
    return NULL;
  }

  PyObject* result = NULL;
  switch (field_descriptor->cpp_type()) {
    case google::protobuf::FieldDescriptor::CPPTYPE_INT32: {
      int32 value = reflection->GetRepeatedInt32(
          *message, field_descriptor, index);
      result = PyInt_FromLong(value);
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_INT64: {
      int64 value = reflection->GetRepeatedInt64(
          *message, field_descriptor, index);
      result = PyLong_FromLongLong(value);
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_UINT32: {
      uint32 value = reflection->GetRepeatedUInt32(
          *message, field_descriptor, index);
      result = PyLong_FromLongLong(value);
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_UINT64: {
      uint64 value = reflection->GetRepeatedUInt64(
          *message, field_descriptor, index);
      result = PyLong_FromUnsignedLongLong(value);
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_FLOAT: {
      float value = reflection->GetRepeatedFloat(
          *message, field_descriptor, index);
      result = PyFloat_FromDouble(value);
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_DOUBLE: {
      double value = reflection->GetRepeatedDouble(
          *message, field_descriptor, index);
      result = PyFloat_FromDouble(value);
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_BOOL: {
      bool value = reflection->GetRepeatedBool(
          *message, field_descriptor, index);
      result = PyBool_FromLong(value ? 1 : 0);
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_ENUM: {
      const google::protobuf::EnumValueDescriptor* enum_value =
          message->GetReflection()->GetRepeatedEnum(
              *message, field_descriptor, index);
      result = PyInt_FromLong(enum_value->number());
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_STRING: {
      string value = reflection->GetRepeatedString(
          *message, field_descriptor, index);
      result = ToStringObject(field_descriptor, value);
      break;
    }
    case google::protobuf::FieldDescriptor::CPPTYPE_MESSAGE: {
      CMessage* py_cmsg = PyObject_New(CMessage, &CMessage_Type);
      if (py_cmsg == NULL) {
        return NULL;
      }
      const google::protobuf::Message& msg = reflection->GetRepeatedMessage(
          *message, field_descriptor, index);
      py_cmsg->parent = cmessage;
      py_cmsg->full_name = field_descriptor->full_name().c_str();
      py_cmsg->message = const_cast<google::protobuf::Message*>(&msg);
      py_cmsg->free_message = false;
      py_cmsg->read_only = false;
      result = reinterpret_cast<PyObject*>(py_cmsg);
      break;
    }
    default:
      PyErr_Format(
          PyExc_SystemError,
          "Getting value from a repeated field of unknown type %d",
          field_descriptor->cpp_type());
  }

  return result;
}

static PyObject* InternalGetRepeatedScalarSlice(
    CMessage* cmessage, const google::protobuf::FieldDescriptor* field_descriptor,
    PyObject* slice) {
  Py_ssize_t from;
  Py_ssize_t to;
  Py_ssize_t step;
  Py_ssize_t length;
  bool return_list = false;
  google::protobuf::Message* message = cmessage->message;

  if (PyInt_Check(slice)) {
    from = to = PyInt_AsLong(slice);
  } else if (PyLong_Check(slice)) {
    from = to = PyLong_AsLong(slice);
  } else if (PySlice_Check(slice)) {
    const google::protobuf::Reflection* reflection = message->GetReflection();
    length = reflection->FieldSize(*message, field_descriptor);
    PySlice_GetIndices(
        reinterpret_cast<PySliceObject*>(slice), length, &from, &to, &step);
    return_list = true;
  } else {
    PyErr_SetString(PyExc_TypeError, "list indices must be integers");
    return NULL;
  }

  if (!return_list) {
    return InternalGetRepeatedScalar(cmessage, field_descriptor, from);
  }

  PyObject* list = PyList_New(0);
  if (list == NULL) {
    return NULL;
  }

  if (from <= to) {
    if (step < 0) return list;
    for (Py_ssize_t index = from; index < to; index += step) {
      if (index < 0 || index >= length) break;
      PyObject* s = InternalGetRepeatedScalar(
          cmessage, field_descriptor, index);
      PyList_Append(list, s);
      Py_DECREF(s);
    }
  } else {
    if (step > 0) return list;
    for (Py_ssize_t index = from; index > to; index += step) {
      if (index < 0 || index >= length) break;
      PyObject* s = InternalGetRepeatedScalar(
          cmessage, field_descriptor, index);
      PyList_Append(list, s);
      Py_DECREF(s);
    }
  }
  return list;
}

// ------ C Constructor/Destructor:

static int CMessageInit(CMessage* self, PyObject *args, PyObject *kwds) {
  self->message = NULL;
  return 0;
}

static void CMessageDealloc(CMessage* self) {
  if (self->free_message) {
    if (self->read_only) {
      PyErr_WriteUnraisable(reinterpret_cast<PyObject*>(self));
    }
    delete self->message;
  }
  self->ob_type->tp_free(reinterpret_cast<PyObject*>(self));
}

// ------ Methods:

static PyObject* CMessage_Clear(CMessage* self, PyObject* arg) {
  AssureWritable(self);
  google::protobuf::Message* message = self->message;

  // This block of code is equivalent to the following:
  // for cfield_descriptor, child_cmessage in arg:
  //   ReleaseSubMessage(cfield_descriptor, child_cmessage)
  if (!PyList_Check(arg)) {
    PyErr_SetString(PyExc_TypeError, "Must be a list");
    return NULL;
  }
  PyObject* messages_to_clear = arg;
  Py_ssize_t num_messages_to_clear = PyList_GET_SIZE(messages_to_clear);
  for(int i = 0; i < num_messages_to_clear; ++i) {
    PyObject* message_tuple = PyList_GET_ITEM(messages_to_clear, i);
    if (!PyTuple_Check(message_tuple) || PyTuple_GET_SIZE(message_tuple) != 2) {
      PyErr_SetString(PyExc_TypeError, "Must be a tuple of size 2");
      return NULL;
    }

    PyObject* py_cfield_descriptor = PyTuple_GET_ITEM(message_tuple, 0);
    PyObject* py_child_cmessage = PyTuple_GET_ITEM(message_tuple, 1);
    if (!PyObject_TypeCheck(py_cfield_descriptor, &CFieldDescriptor_Type) ||
        !PyObject_TypeCheck(py_child_cmessage, &CMessage_Type)) {
      PyErr_SetString(PyExc_ValueError, "Invalid Tuple");
      return NULL;
    }

    CFieldDescriptor* cfield_descriptor = reinterpret_cast<CFieldDescriptor *>(
        py_cfield_descriptor);
    CMessage* child_cmessage = reinterpret_cast<CMessage *>(py_child_cmessage);
    ReleaseSubMessage(message, cfield_descriptor->descriptor, child_cmessage);
  }

  message->Clear();
  Py_RETURN_NONE;
}

static PyObject* CMessage_IsInitialized(CMessage* self, PyObject* args) {
  return PyBool_FromLong(self->message->IsInitialized() ? 1 : 0);
}

static PyObject* CMessage_HasField(CMessage* self, PyObject* arg) {
  char* field_name;
  if (PyString_AsStringAndSize(arg, &field_name, NULL) < 0) {
    return NULL;
  }

  google::protobuf::Message* message = self->message;
  const google::protobuf::Descriptor* descriptor = message->GetDescriptor();
  const google::protobuf::FieldDescriptor* field_descriptor =
      descriptor->FindFieldByName(field_name);
  if (field_descriptor == NULL) {
    PyErr_Format(PyExc_ValueError, "Unknown field %s.", field_name);
    return NULL;
  }

  bool has_field =
      message->GetReflection()->HasField(*message, field_descriptor);
  return PyBool_FromLong(has_field ? 1 : 0);
}

static PyObject* CMessage_HasFieldByDescriptor(CMessage* self, PyObject* arg) {
  CFieldDescriptor* cfield_descriptor = NULL;
  if (!PyObject_TypeCheck(reinterpret_cast<PyObject *>(arg),
                          &CFieldDescriptor_Type)) {
    PyErr_SetString(PyExc_TypeError, "Must be a field descriptor");
    return NULL;
  }
  cfield_descriptor = reinterpret_cast<CFieldDescriptor*>(arg);

  google::protobuf::Message* message = self->message;
  const google::protobuf::FieldDescriptor* field_descriptor =
      cfield_descriptor->descriptor;

  if (!FIELD_BELONGS_TO_MESSAGE(field_descriptor, message)) {
    PyErr_SetString(PyExc_KeyError,
                    "Field does not belong to message!");
    return NULL;
  }

  if (FIELD_IS_REPEATED(field_descriptor)) {
    PyErr_SetString(PyExc_KeyError,
                    "Field is repeated. A singular method is required.");
    return NULL;
  }

  bool has_field =
      message->GetReflection()->HasField(*message, field_descriptor);
  return PyBool_FromLong(has_field ? 1 : 0);
}

static PyObject* CMessage_ClearFieldByDescriptor(
    CMessage* self, PyObject* arg) {
  CFieldDescriptor* cfield_descriptor = NULL;
  if (!PyObject_TypeCheck(reinterpret_cast<PyObject *>(arg),
                          &CFieldDescriptor_Type)) {
    PyErr_SetString(PyExc_TypeError, "Must be a field descriptor");
    return NULL;
  }
  cfield_descriptor = reinterpret_cast<CFieldDescriptor*>(arg);

  google::protobuf::Message* message = self->message;
  const google::protobuf::FieldDescriptor* field_descriptor =
      cfield_descriptor->descriptor;

  if (!FIELD_BELONGS_TO_MESSAGE(field_descriptor, message)) {
    PyErr_SetString(PyExc_KeyError,
                    "Field does not belong to message!");
    return NULL;
  }

  message->GetReflection()->ClearField(message, field_descriptor);
  Py_RETURN_NONE;
}

static PyObject* CMessage_ClearField(CMessage* self, PyObject* args) {
  char* field_name;
  CMessage* child_cmessage = NULL;
  if (!PyArg_ParseTuple(args, C("s|O!:ClearField"), &field_name,
                        &CMessage_Type, &child_cmessage)) {
    return NULL;
  }

  google::protobuf::Message* message = self->message;
  const google::protobuf::Descriptor* descriptor = message->GetDescriptor();
  const google::protobuf::FieldDescriptor* field_descriptor =
      descriptor->FindFieldByName(field_name);
  if (field_descriptor == NULL) {
    PyErr_Format(PyExc_ValueError, "Unknown field %s.", field_name);
    return NULL;
  }

  if (child_cmessage != NULL && !FIELD_IS_REPEATED(field_descriptor)) {
    ReleaseSubMessage(message, field_descriptor, child_cmessage);
  } else {
    message->GetReflection()->ClearField(message, field_descriptor);
  }
  Py_RETURN_NONE;
}

static PyObject* CMessage_GetScalar(CMessage* self, PyObject* arg) {
  CFieldDescriptor* cdescriptor = NULL;
  if (!PyObject_TypeCheck(reinterpret_cast<PyObject *>(arg),
                          &CFieldDescriptor_Type)) {
    PyErr_SetString(PyExc_TypeError, "Must be a field descriptor");
    return NULL;
  }
  cdescriptor = reinterpret_cast<CFieldDescriptor*>(arg);

  google::protobuf::Message* message = self->message;
  return InternalGetScalar(message, cdescriptor->descriptor);
}

static PyObject* CMessage_GetRepeatedScalar(CMessage* self, PyObject* args) {
  CFieldDescriptor* cfield_descriptor;
  PyObject* slice;
  if (!PyArg_ParseTuple(args, C("O!O:GetRepeatedScalar"),
                        &CFieldDescriptor_Type, &cfield_descriptor, &slice)) {
    return NULL;
  }

  return InternalGetRepeatedScalarSlice(
      self, cfield_descriptor->descriptor, slice);
}

static PyObject* CMessage_AssignRepeatedScalar(CMessage* self, PyObject* args) {
  CFieldDescriptor* cfield_descriptor;
  PyObject* slice;
  if (!PyArg_ParseTuple(args, C("O!O:AssignRepeatedScalar"),
                        &CFieldDescriptor_Type, &cfield_descriptor, &slice)) {
    return NULL;
  }

  AssureWritable(self);
  google::protobuf::Message* message = self->message;
  message->GetReflection()->ClearField(message, cfield_descriptor->descriptor);

  PyObject* iter = PyObject_GetIter(slice);
  PyObject* next;
  while ((next = PyIter_Next(iter)) != NULL) {
    if (InternalAddRepeatedScalar(
            message, cfield_descriptor->descriptor, next) == NULL) {
      Py_DECREF(next);
      Py_DECREF(iter);
      return NULL;
    }
    Py_DECREF(next);
  }
  Py_DECREF(iter);
  Py_RETURN_NONE;
}

static PyObject* CMessage_DeleteRepeatedField(CMessage* self, PyObject* args) {
  CFieldDescriptor* cfield_descriptor;
  PyObject* slice;
  if (!PyArg_ParseTuple(args, C("O!O:DeleteRepeatedField"),
                        &CFieldDescriptor_Type, &cfield_descriptor, &slice)) {
    return NULL;
  }
  AssureWritable(self);

  Py_ssize_t length, from, to, step, slice_length;
  google::protobuf::Message* message = self->message;
  const google::protobuf::FieldDescriptor* field_descriptor =
      cfield_descriptor->descriptor;
  const google::protobuf::Reflection* reflection = message->GetReflection();
  int min, max;
  length = reflection->FieldSize(*message, field_descriptor);

  if (PyInt_Check(slice) || PyLong_Check(slice)) {
    from = to = PyLong_AsLong(slice);
    if (from < 0) {
      from = to = length + from;
    }
    step = 1;
    min = max = from;

    // Range check.
    if (from < 0 || from >= length) {
      PyErr_Format(PyExc_IndexError, "list assignment index out of range");
      return NULL;
    }
  } else if (PySlice_Check(slice)) {
    from = to = step = slice_length = 0;
    PySlice_GetIndicesEx(
        reinterpret_cast<PySliceObject*>(slice),
        length, &from, &to, &step, &slice_length);
    if (from < to) {
      min = from;
      max = to - 1;
    } else {
      min = to + 1;
      max = from;
    }
  } else {
    PyErr_SetString(PyExc_TypeError, "list indices must be integers");
    return NULL;
  }

  Py_ssize_t i = from;
  std::vector<bool> to_delete(length, false);
  while (i >= min && i <= max) {
    to_delete[i] = true;
    i += step;
  }

  to = 0;
  for (i = 0; i < length; ++i) {
    if (!to_delete[i]) {
      if (i != to) {
        reflection->SwapElements(message, field_descriptor, i, to);
      }
      ++to;
    }
  }

  while (i > to) {
    reflection->RemoveLast(message, field_descriptor);
    --i;
  }

  Py_RETURN_NONE;
}


static PyObject* CMessage_SetScalar(CMessage* self, PyObject* args) {
  CFieldDescriptor* cfield_descriptor;
  PyObject* arg;
  if (!PyArg_ParseTuple(args, C("O!O:SetScalar"),
                        &CFieldDescriptor_Type, &cfield_descriptor, &arg)) {
    return NULL;
  }
  AssureWritable(self);

  return InternalSetScalar(self->message, cfield_descriptor->descriptor, arg);
}

static PyObject* CMessage_AddRepeatedScalar(CMessage* self, PyObject* args) {
  CFieldDescriptor* cfield_descriptor;
  PyObject* value;
  if (!PyArg_ParseTuple(args, C("O!O:AddRepeatedScalar"),
                        &CFieldDescriptor_Type, &cfield_descriptor, &value)) {
    return NULL;
  }
  AssureWritable(self);

  return InternalAddRepeatedScalar(
      self->message, cfield_descriptor->descriptor, value);
}

static PyObject* CMessage_FieldLength(CMessage* self, PyObject* arg) {
  CFieldDescriptor* cfield_descriptor;
  if (!PyObject_TypeCheck(reinterpret_cast<PyObject *>(arg),
                          &CFieldDescriptor_Type)) {
    PyErr_SetString(PyExc_TypeError, "Must be a field descriptor");
    return NULL;
  }
  cfield_descriptor = reinterpret_cast<CFieldDescriptor*>(arg);

  google::protobuf::Message* message = self->message;
  int length = message->GetReflection()->FieldSize(
      *message, cfield_descriptor->descriptor);
  return PyInt_FromLong(length);
}

static PyObject* CMessage_DebugString(CMessage* self, PyObject* args) {
  return PyString_FromString(self->message->DebugString().c_str());
}

static PyObject* CMessage_SerializeToString(CMessage* self, PyObject* args) {
  int size = self->message->ByteSize();
  if (size <= 0) {
    return PyString_FromString("");
  }
  PyObject* result = PyString_FromStringAndSize(NULL, size);
  if (result == NULL) {
    return NULL;
  }
  char* buffer = PyString_AS_STRING(result);
  self->message->SerializeWithCachedSizesToArray(
      reinterpret_cast<uint8*>(buffer));
  return result;
}

static PyObject* CMessage_SerializePartialToString(
    CMessage* self, PyObject* args) {
  string contents;
  self->message->SerializePartialToString(&contents);
  return PyString_FromStringAndSize(contents.c_str(), contents.size());
}

static PyObject* CMessageStr(CMessage* self) {
  char str[1024];
  str[sizeof(str) - 1] = 0;
  snprintf(str, sizeof(str) - 1, "CMessage: <%p>", self->message);
  return PyString_FromString(str);
}

static PyObject* CMessage_MergeFrom(CMessage* self, PyObject* arg) {
  CMessage* other_message;
  if (!PyObject_TypeCheck(reinterpret_cast<PyObject *>(arg), &CMessage_Type)) {
    PyErr_SetString(PyExc_TypeError, "Must be a message");
    return NULL;
  }

  other_message = reinterpret_cast<CMessage*>(arg);
  if (other_message->message->GetDescriptor() !=
      self->message->GetDescriptor()) {
    PyErr_Format(PyExc_TypeError,
                 "Tried to merge from a message with a different type. "
                 "to: %s, from: %s",
                 self->message->GetDescriptor()->full_name().c_str(),
                 other_message->message->GetDescriptor()->full_name().c_str());
    return NULL;
  }
  AssureWritable(self);

  self->message->MergeFrom(*other_message->message);
  Py_RETURN_NONE;
}

static PyObject* CMessage_CopyFrom(CMessage* self, PyObject* arg) {
  CMessage* other_message;
  if (!PyObject_TypeCheck(reinterpret_cast<PyObject *>(arg), &CMessage_Type)) {
    PyErr_SetString(PyExc_TypeError, "Must be a message");
    return NULL;
  }

  other_message = reinterpret_cast<CMessage*>(arg);
  if (other_message->message->GetDescriptor() !=
      self->message->GetDescriptor()) {
    PyErr_Format(PyExc_TypeError,
                 "Tried to copy from a message with a different type. "
                 "to: %s, from: %s",
                 self->message->GetDescriptor()->full_name().c_str(),
                 other_message->message->GetDescriptor()->full_name().c_str());
    return NULL;
  }

  AssureWritable(self);

  self->message->CopyFrom(*other_message->message);
  Py_RETURN_NONE;
}

static PyObject* CMessage_MergeFromString(CMessage* self, PyObject* arg) {
  const void* data;
  Py_ssize_t data_length;
  if (PyObject_AsReadBuffer(arg, &data, &data_length) < 0) {
    return NULL;
  }

  AssureWritable(self);
  google::protobuf::io::CodedInputStream input(
      reinterpret_cast<const uint8*>(data), data_length);
  input.SetExtensionRegistry(GetDescriptorPool(), global_message_factory);
  bool success = self->message->MergePartialFromCodedStream(&input);
  if (success) {
    return PyInt_FromLong(self->message->ByteSize());
  } else {
    return PyInt_FromLong(-1);
  }
}

static PyObject* CMessage_ByteSize(CMessage* self, PyObject* args) {
  return PyLong_FromLong(self->message->ByteSize());
}

static PyObject* CMessage_SetInParent(CMessage* self, PyObject* args) {
  AssureWritable(self);
  Py_RETURN_NONE;
}

static PyObject* CMessage_SwapRepeatedFieldElements(
    CMessage* self, PyObject* args) {
  CFieldDescriptor* cfield_descriptor;
  int index1, index2;
  if (!PyArg_ParseTuple(args, C("O!ii:SwapRepeatedFieldElements"),
                        &CFieldDescriptor_Type, &cfield_descriptor,
                        &index1, &index2)) {
    return NULL;
  }

  google::protobuf::Message* message = self->message;
  const google::protobuf::Reflection* reflection = message->GetReflection();

  reflection->SwapElements(
      message, cfield_descriptor->descriptor, index1, index2);
  Py_RETURN_NONE;
}

static PyObject* CMessage_AddMessage(CMessage* self, PyObject* arg) {
  CFieldDescriptor* cfield_descriptor;
  if (!PyObject_TypeCheck(reinterpret_cast<PyObject *>(arg),
                          &CFieldDescriptor_Type)) {
    PyErr_SetString(PyExc_TypeError, "Must be a field descriptor");
    return NULL;
  }
  cfield_descriptor = reinterpret_cast<CFieldDescriptor*>(arg);
  AssureWritable(self);

  CMessage* py_cmsg = PyObject_New(CMessage, &CMessage_Type);
  if (py_cmsg == NULL) {
    return NULL;
  }

  google::protobuf::Message* message = self->message;
  const google::protobuf::Reflection* reflection = message->GetReflection();
  google::protobuf::Message* sub_message =
      reflection->AddMessage(message, cfield_descriptor->descriptor);

  py_cmsg->parent = NULL;
  py_cmsg->full_name = sub_message->GetDescriptor()->full_name().c_str();
  py_cmsg->message = sub_message;
  py_cmsg->free_message = false;
  py_cmsg->read_only = false;
  return reinterpret_cast<PyObject*>(py_cmsg);
}

static PyObject* CMessage_GetRepeatedMessage(CMessage* self, PyObject* args) {
  CFieldDescriptor* cfield_descriptor;
  PyObject* slice;
  if (!PyArg_ParseTuple(args, C("O!O:GetRepeatedMessage"),
                        &CFieldDescriptor_Type, &cfield_descriptor, &slice)) {
    return NULL;
  }

  return InternalGetRepeatedScalarSlice(
      self, cfield_descriptor->descriptor, slice);
}

static PyObject* CMessage_NewSubMessage(CMessage* self, PyObject* arg) {
  CFieldDescriptor* cfield_descriptor;
  if (!PyObject_TypeCheck(reinterpret_cast<PyObject *>(arg),
                          &CFieldDescriptor_Type)) {
    PyErr_SetString(PyExc_TypeError, "Must be a field descriptor");
    return NULL;
  }
  cfield_descriptor = reinterpret_cast<CFieldDescriptor*>(arg);

  CMessage* py_cmsg = PyObject_New(CMessage, &CMessage_Type);
  if (py_cmsg == NULL) {
    return NULL;
  }

  google::protobuf::Message* message = self->message;
  const google::protobuf::Reflection* reflection = message->GetReflection();
  const google::protobuf::Message& sub_message =
      reflection->GetMessage(*message, cfield_descriptor->descriptor,
                             global_message_factory);

  py_cmsg->full_name = sub_message.GetDescriptor()->full_name().c_str();
  py_cmsg->parent = self;
  py_cmsg->parent_field = cfield_descriptor;
  py_cmsg->message = const_cast<google::protobuf::Message*>(&sub_message);
  py_cmsg->free_message = false;
  py_cmsg->read_only = true;
  return reinterpret_cast<PyObject*>(py_cmsg);
}

static PyObject* CMessage_MutableMessage(CMessage* self, PyObject* arg) {
  CFieldDescriptor* cfield_descriptor;
  if (!PyObject_TypeCheck(reinterpret_cast<PyObject *>(arg),
                          &CFieldDescriptor_Type)) {
    PyErr_SetString(PyExc_TypeError, "Must be a field descriptor");
    return NULL;
  }
  cfield_descriptor = reinterpret_cast<CFieldDescriptor*>(arg);
  AssureWritable(self);

  CMessage* py_cmsg = PyObject_New(CMessage, &CMessage_Type);
  if (py_cmsg == NULL) {
    return NULL;
  }

  google::protobuf::Message* message = self->message;
  const google::protobuf::Reflection* reflection = message->GetReflection();
  google::protobuf::Message* mutable_message =
      reflection->MutableMessage(message, cfield_descriptor->descriptor,
                                 global_message_factory);

  py_cmsg->full_name = mutable_message->GetDescriptor()->full_name().c_str();
  py_cmsg->message = mutable_message;
  py_cmsg->free_message = false;
  py_cmsg->read_only = false;
  return reinterpret_cast<PyObject*>(py_cmsg);
}

static PyObject* CMessage_Equals(CMessage* self, PyObject* arg) {
  CMessage* other_message;
  if (!PyObject_TypeCheck(reinterpret_cast<PyObject *>(arg), &CMessage_Type)) {
    PyErr_SetString(PyExc_TypeError, "Must be a message");
    return NULL;
  }
  other_message = reinterpret_cast<CMessage*>(arg);

  if (other_message->message == self->message) {
    return PyBool_FromLong(1);
  }

  if (other_message->message->GetDescriptor() !=
      self->message->GetDescriptor()) {
    return PyBool_FromLong(0);
  }

  return PyBool_FromLong(1);
}

static PyObject* CMessage_ListFields(CMessage* self, PyObject* args) {
  google::protobuf::Message* message = self->message;
  const google::protobuf::Reflection* reflection = message->GetReflection();
  vector<const google::protobuf::FieldDescriptor*> fields;
  reflection->ListFields(*message, &fields);

  PyObject* list = PyList_New(fields.size());
  if (list == NULL) {
    return NULL;
  }

  for (unsigned int i = 0; i < fields.size(); ++i) {
    bool is_extension = fields[i]->is_extension();
    PyObject* t = PyTuple_New(2);
    if (t == NULL) {
      Py_DECREF(list);
      return NULL;
    }

    PyObject* is_extension_object = PyBool_FromLong(is_extension ? 1 : 0);

    PyObject* field_name;
    const string* s;
    if (is_extension) {
      s = &fields[i]->full_name();
    } else {
      s = &fields[i]->name();
    }
    field_name = PyString_FromStringAndSize(s->c_str(), s->length());
    if (field_name == NULL) {
      Py_DECREF(list);
      Py_DECREF(t);
      return NULL;
    }

    PyTuple_SET_ITEM(t, 0, is_extension_object);
    PyTuple_SET_ITEM(t, 1, field_name);
    PyList_SET_ITEM(list, i, t);
  }

  return list;
}

static PyObject* CMessage_FindInitializationErrors(CMessage* self) {
  google::protobuf::Message* message = self->message;
  vector<string> errors;
  message->FindInitializationErrors(&errors);

  PyObject* error_list = PyList_New(errors.size());
  if (error_list == NULL) {
    return NULL;
  }
  for (unsigned int i = 0; i < errors.size(); ++i) {
    const string& error = errors[i];
    PyObject* error_string = PyString_FromStringAndSize(
        error.c_str(), error.length());
    if (error_string == NULL) {
      Py_DECREF(error_list);
      return NULL;
    }
    PyList_SET_ITEM(error_list, i, error_string);
  }
  return error_list;
}

// ------ Python Constructor:

PyObject* Python_NewCMessage(PyObject* ignored, PyObject* arg) {
  const char* message_type = PyString_AsString(arg);
  if (message_type == NULL) {
    return NULL;
  }

  const google::protobuf::Message* message = CreateMessage(message_type);
  if (message == NULL) {
    PyErr_Format(PyExc_TypeError, "Couldn't create message of type %s!",
                 message_type);
    return NULL;
  }

  CMessage* py_cmsg = PyObject_New(CMessage, &CMessage_Type);
  if (py_cmsg == NULL) {
    return NULL;
  }
  py_cmsg->message = message->New();
  py_cmsg->free_message = true;
  py_cmsg->full_name = message->GetDescriptor()->full_name().c_str();
  py_cmsg->read_only = false;
  py_cmsg->parent = NULL;
  py_cmsg->parent_field = NULL;
  return reinterpret_cast<PyObject*>(py_cmsg);
}

// --- Module Functions (exposed to Python):

PyMethodDef methods[] = {
  { C("NewCMessage"), (PyCFunction)Python_NewCMessage,
    METH_O,
    C("Creates a new C++ protocol message, given its full name.") },
  { C("NewCDescriptorPool"), (PyCFunction)Python_NewCDescriptorPool,
    METH_NOARGS,
    C("Creates a new C++ descriptor pool.") },
  { C("BuildFile"), (PyCFunction)Python_BuildFile,
    METH_O,
    C("Registers a new protocol buffer file in the global C++ descriptor "
      "pool.") },
  {NULL}
};

// --- Exposing the C proto living inside Python proto to C code:

extern const Message* (*GetCProtoInsidePyProtoPtr)(PyObject* msg);
extern Message* (*MutableCProtoInsidePyProtoPtr)(PyObject* msg);

static const google::protobuf::Message* GetCProtoInsidePyProtoImpl(PyObject* msg) {
  PyObject* c_msg_obj = PyObject_GetAttrString(msg, "_cmsg");
  if (c_msg_obj == NULL) {
    PyErr_Clear();
    return NULL;
  }
  Py_DECREF(c_msg_obj);
  if (!PyObject_TypeCheck(c_msg_obj, &CMessage_Type)) {
    return NULL;
  }
  CMessage* c_msg = reinterpret_cast<CMessage*>(c_msg_obj);
  return c_msg->message;
}

static google::protobuf::Message* MutableCProtoInsidePyProtoImpl(PyObject* msg) {
  PyObject* c_msg_obj = PyObject_GetAttrString(msg, "_cmsg");
  if (c_msg_obj == NULL) {
    PyErr_Clear();
    return NULL;
  }
  Py_DECREF(c_msg_obj);
  if (!PyObject_TypeCheck(c_msg_obj, &CMessage_Type)) {
    return NULL;
  }
  CMessage* c_msg = reinterpret_cast<CMessage*>(c_msg_obj);
  AssureWritable(c_msg);
  return c_msg->message;
}

// --- Module Init Function:

static const char module_docstring[] =
"python-proto2 is a module that can be used to enhance proto2 Python API\n"
"performance.\n"
"\n"
"It provides access to the protocol buffers C++ reflection API that\n"
"implements the basic protocol buffer functions.";

extern "C" {
  void init_net_proto2___python() {
    // Initialize constants.
    kPythonZero = PyInt_FromLong(0);
    kint32min_py = PyInt_FromLong(kint32min);
    kint32max_py = PyInt_FromLong(kint32max);
    kuint32max_py = PyLong_FromLongLong(kuint32max);
    kint64min_py = PyLong_FromLongLong(kint64min);
    kint64max_py = PyLong_FromLongLong(kint64max);
    kuint64max_py = PyLong_FromUnsignedLongLong(kuint64max);

    global_message_factory = new DynamicMessageFactory(GetDescriptorPool());
    global_message_factory->SetDelegateToGeneratedFactory(true);

    // Export our functions to Python.
    PyObject *m;
    m = Py_InitModule3(C("_net_proto2___python"), methods, C(module_docstring));
    if (m == NULL) {
      return;
    }

    AddConstants(m);

    CMessage_Type.tp_new = PyType_GenericNew;
    if (PyType_Ready(&CMessage_Type) < 0) {
      return;
    }

    if (!InitDescriptor()) {
      return;
    }

    // Override {Get,Mutable}CProtoInsidePyProto.
    GetCProtoInsidePyProtoPtr = GetCProtoInsidePyProtoImpl;
    MutableCProtoInsidePyProtoPtr = MutableCProtoInsidePyProtoImpl;
  }
}

}  // namespace python
}  // namespace protobuf
}  // namespace google
