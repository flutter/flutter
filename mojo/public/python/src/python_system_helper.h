// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_PYTHON_SRC_PYTHON_SYSTEM_HELPER_H_
#define MOJO_PUBLIC_PYTHON_SRC_PYTHON_SYSTEM_HELPER_H_

// Python must be the first include, as it defines preprocessor variable without
// checking if they already exist.
#include <Python.h>

#include <map>

#include "mojo/public/cpp/bindings/callback.h"
#include "mojo/public/python/src/common.h"


namespace mojo {
namespace python {
// Create a mojo::Closure from a callable python object. If an error occurs
// while executing callable, the closure will quit the current run loop.
Closure BuildClosure(PyObject* callable);

// Create a new PythonAsyncWaiter object. Ownership is passed to the caller.
PythonAsyncWaiter* NewAsyncWaiter();

}  // namespace python
}  // namespace mojo

#endif  // MOJO_PUBLIC_PYTHON_SRC_PYTHON_SYSTEM_HELPER_H_
