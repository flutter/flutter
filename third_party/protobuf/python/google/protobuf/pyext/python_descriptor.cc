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
#include <string>

#include <google/protobuf/pyext/python_descriptor.h>
#include <google/protobuf/descriptor.pb.h>

#define C(str) const_cast<char*>(str)

namespace google {
namespace protobuf {
namespace python {


static void CFieldDescriptorDealloc(CFieldDescriptor* self);

static google::protobuf::DescriptorPool* g_descriptor_pool = NULL;

static PyObject* CFieldDescriptor_GetFullName(
    CFieldDescriptor* self, void *closure) {
  Py_XINCREF(self->full_name);
  return self->full_name;
}

static PyObject* CFieldDescriptor_GetName(
    CFieldDescriptor *self, void *closure) {
  Py_XINCREF(self->name);
  return self->name;
}

static PyObject* CFieldDescriptor_GetCppType(
    CFieldDescriptor *self, void *closure) {
  Py_XINCREF(self->cpp_type);
  return self->cpp_type;
}

static PyObject* CFieldDescriptor_GetLabel(
    CFieldDescriptor *self, void *closure) {
  Py_XINCREF(self->label);
  return self->label;
}

static PyObject* CFieldDescriptor_GetID(
    CFieldDescriptor *self, void *closure) {
  Py_XINCREF(self->id);
  return self->id;
}


static PyGetSetDef CFieldDescriptorGetters[] = {
  { C("full_name"),
    (getter)CFieldDescriptor_GetFullName, NULL, "Full name", NULL},
  { C("name"),
    (getter)CFieldDescriptor_GetName, NULL, "last name", NULL},
  { C("cpp_type"),
    (getter)CFieldDescriptor_GetCppType, NULL, "C++ Type", NULL},
  { C("label"),
    (getter)CFieldDescriptor_GetLabel, NULL, "Label", NULL},
  { C("id"),
    (getter)CFieldDescriptor_GetID, NULL, "ID", NULL},
  {NULL}
};

PyTypeObject CFieldDescriptor_Type = {
  PyObject_HEAD_INIT(&PyType_Type)
  0,
  C("google.protobuf.internal."
    "_net_proto2___python."
    "CFieldDescriptor"),                // tp_name
  sizeof(CFieldDescriptor),             // tp_basicsize
  0,                                    // tp_itemsize
  (destructor)CFieldDescriptorDealloc,  // tp_dealloc
  0,                                    // tp_print
  0,                                    // tp_getattr
  0,                                    // tp_setattr
  0,                                    // tp_compare
  0,                                    // tp_repr
  0,                                    // tp_as_number
  0,                                    // tp_as_sequence
  0,                                    // tp_as_mapping
  0,                                    // tp_hash
  0,                                    // tp_call
  0,                                    // tp_str
  0,                                    // tp_getattro
  0,                                    // tp_setattro
  0,                                    // tp_as_buffer
  Py_TPFLAGS_DEFAULT,                   // tp_flags
  C("A Field Descriptor"),              // tp_doc
  0,                                    // tp_traverse
  0,                                    // tp_clear
  0,                                    // tp_richcompare
  0,                                    // tp_weaklistoffset
  0,                                    // tp_iter
  0,                                    // tp_iternext
  0,                                    // tp_methods
  0,                                    // tp_members
  CFieldDescriptorGetters,              // tp_getset
  0,                                    // tp_base
  0,                                    // tp_dict
  0,                                    // tp_descr_get
  0,                                    // tp_descr_set
  0,                                    // tp_dictoffset
  0,                                    // tp_init
  PyType_GenericAlloc,                  // tp_alloc
  PyType_GenericNew,                    // tp_new
  PyObject_Del,                         // tp_free
};

static void CFieldDescriptorDealloc(CFieldDescriptor* self) {
  Py_DECREF(self->full_name);
  Py_DECREF(self->name);
  Py_DECREF(self->cpp_type);
  Py_DECREF(self->label);
  Py_DECREF(self->id);
  self->ob_type->tp_free(reinterpret_cast<PyObject*>(self));
}

typedef struct {
  PyObject_HEAD

  const google::protobuf::DescriptorPool* pool;
} CDescriptorPool;

static void CDescriptorPoolDealloc(CDescriptorPool* self);

static PyObject* CDescriptorPool_NewCDescriptor(
    const google::protobuf::FieldDescriptor* field_descriptor) {
  CFieldDescriptor* cfield_descriptor = PyObject_New(
      CFieldDescriptor, &CFieldDescriptor_Type);
  if (cfield_descriptor == NULL) {
    return NULL;
  }
  cfield_descriptor->descriptor = field_descriptor;

  cfield_descriptor->full_name = PyString_FromString(
      field_descriptor->full_name().c_str());
  cfield_descriptor->name = PyString_FromString(
      field_descriptor->name().c_str());
  cfield_descriptor->cpp_type = PyLong_FromLong(field_descriptor->cpp_type());
  cfield_descriptor->label = PyLong_FromLong(field_descriptor->label());
  cfield_descriptor->id = PyLong_FromVoidPtr(cfield_descriptor);
  return reinterpret_cast<PyObject*>(cfield_descriptor);
}

static PyObject* CDescriptorPool_FindFieldByName(
    CDescriptorPool* self, PyObject* arg) {
  const char* full_field_name = PyString_AsString(arg);
  if (full_field_name == NULL) {
    return NULL;
  }

  const google::protobuf::FieldDescriptor* field_descriptor = NULL;

  field_descriptor = self->pool->FindFieldByName(full_field_name);


  if (field_descriptor == NULL) {
    PyErr_Format(PyExc_TypeError, "Couldn't find field %.200s",
                 full_field_name);
    return NULL;
  }

  return CDescriptorPool_NewCDescriptor(field_descriptor);
}

static PyObject* CDescriptorPool_FindExtensionByName(
    CDescriptorPool* self, PyObject* arg) {
  const char* full_field_name = PyString_AsString(arg);
  if (full_field_name == NULL) {
    return NULL;
  }

  const google::protobuf::FieldDescriptor* field_descriptor =
      self->pool->FindExtensionByName(full_field_name);
  if (field_descriptor == NULL) {
    PyErr_Format(PyExc_TypeError, "Couldn't find field %.200s",
                 full_field_name);
    return NULL;
  }

  return CDescriptorPool_NewCDescriptor(field_descriptor);
}

static PyMethodDef CDescriptorPoolMethods[] = {
  { C("FindFieldByName"),
    (PyCFunction)CDescriptorPool_FindFieldByName,
    METH_O,
    C("Searches for a field descriptor by full name.") },
  { C("FindExtensionByName"),
    (PyCFunction)CDescriptorPool_FindExtensionByName,
    METH_O,
    C("Searches for extension descriptor by full name.") },
  {NULL}
};

PyTypeObject CDescriptorPool_Type = {
  PyObject_HEAD_INIT(&PyType_Type)
  0,
  C("google.protobuf.internal."
    "_net_proto2___python."
    "CFieldDescriptor"),               // tp_name
  sizeof(CDescriptorPool),             // tp_basicsize
  0,                                   // tp_itemsize
  (destructor)CDescriptorPoolDealloc,  // tp_dealloc
  0,                                   // tp_print
  0,                                   // tp_getattr
  0,                                   // tp_setattr
  0,                                   // tp_compare
  0,                                   // tp_repr
  0,                                   // tp_as_number
  0,                                   // tp_as_sequence
  0,                                   // tp_as_mapping
  0,                                   // tp_hash
  0,                                   // tp_call
  0,                                   // tp_str
  0,                                   // tp_getattro
  0,                                   // tp_setattro
  0,                                   // tp_as_buffer
  Py_TPFLAGS_DEFAULT,                  // tp_flags
  C("A Descriptor Pool"),              // tp_doc
  0,                                   // tp_traverse
  0,                                   // tp_clear
  0,                                   // tp_richcompare
  0,                                   // tp_weaklistoffset
  0,                                   // tp_iter
  0,                                   // tp_iternext
  CDescriptorPoolMethods,              // tp_methods
  0,                                   // tp_members
  0,                                   // tp_getset
  0,                                   // tp_base
  0,                                   // tp_dict
  0,                                   // tp_descr_get
  0,                                   // tp_descr_set
  0,                                   // tp_dictoffset
  0,                                   // tp_init
  PyType_GenericAlloc,                 // tp_alloc
  PyType_GenericNew,                   // tp_new
  PyObject_Del,                        // tp_free
};

static void CDescriptorPoolDealloc(CDescriptorPool* self) {
  self->ob_type->tp_free(reinterpret_cast<PyObject*>(self));
}

google::protobuf::DescriptorPool* GetDescriptorPool() {
  if (g_descriptor_pool == NULL) {
    g_descriptor_pool = new google::protobuf::DescriptorPool(
        google::protobuf::DescriptorPool::generated_pool());
  }
  return g_descriptor_pool;
}

PyObject* Python_NewCDescriptorPool(PyObject* ignored, PyObject* args) {
  CDescriptorPool* cdescriptor_pool = PyObject_New(
      CDescriptorPool, &CDescriptorPool_Type);
  if (cdescriptor_pool == NULL) {
    return NULL;
  }
  cdescriptor_pool->pool = GetDescriptorPool();
  return reinterpret_cast<PyObject*>(cdescriptor_pool);
}

PyObject* Python_BuildFile(PyObject* ignored, PyObject* arg) {
  char* message_type;
  Py_ssize_t message_len;

  if (PyString_AsStringAndSize(arg, &message_type, &message_len) < 0) {
    return NULL;
  }

  google::protobuf::FileDescriptorProto file_proto;
  if (!file_proto.ParseFromArray(message_type, message_len)) {
    PyErr_SetString(PyExc_TypeError, "Couldn't parse file content!");
    return NULL;
  }

  if (google::protobuf::DescriptorPool::generated_pool()->FindFileByName(
      file_proto.name()) != NULL) {
    Py_RETURN_NONE;
  }

  const google::protobuf::FileDescriptor* descriptor = GetDescriptorPool()->BuildFile(
      file_proto);
  if (descriptor == NULL) {
    PyErr_SetString(PyExc_TypeError,
                    "Couldn't build proto file into descriptor pool!");
    return NULL;
  }

  Py_RETURN_NONE;
}

bool InitDescriptor() {
  CFieldDescriptor_Type.tp_new = PyType_GenericNew;
  if (PyType_Ready(&CFieldDescriptor_Type) < 0)
    return false;

  CDescriptorPool_Type.tp_new = PyType_GenericNew;
  if (PyType_Ready(&CDescriptorPool_Type) < 0)
    return false;
  return true;
}

}  // namespace python
}  // namespace protobuf
}  // namespace google
