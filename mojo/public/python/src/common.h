// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_PYTHON_SRC_COMMON_H_
#define MOJO_PUBLIC_PYTHON_SRC_COMMON_H_

#include <Python.h>

#include <map>

#include "mojo/public/c/environment/async_waiter.h"
#include "mojo/public/cpp/bindings/callback.h"
#include "mojo/public/cpp/bindings/lib/shared_ptr.h"
#include "mojo/public/cpp/system/core.h"

namespace mojo {
namespace python {

class ScopedGIL {
 public:
  ScopedGIL();

  ~ScopedGIL();

 private:
  PyGILState_STATE state_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ScopedGIL);
};

enum ScopedPyRefAcquire {
  kAcquire,
};

class ScopedPyRef {
 public:
  explicit ScopedPyRef(PyObject* object);
  ScopedPyRef(PyObject* object, ScopedPyRefAcquire);
  ScopedPyRef(const ScopedPyRef& other);

  ~ScopedPyRef();

  // Releases ownership of the python object contained by this instance.
  PyObject* Release();

  operator PyObject*() const { return object_; }

  ScopedPyRef& operator=(const ScopedPyRef& other);

 private:
  PyObject* object_;
};


class PythonClosure : public mojo::Closure::Runnable {
 public:
  PythonClosure(PyObject* callable, const mojo::Closure& quit);
  ~PythonClosure() override;

  void Run() const override;

 private:
  ScopedPyRef callable_;
  const mojo::Closure quit_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(PythonClosure);
};

// Create a mojo::Closure from a callable python object.
Closure::Runnable* NewRunnableFromCallable(PyObject* callable,
                                           const Closure& quit_closure);

// AsyncWaiter for python, used to execute a python closure after waiting. If an
// error occurs while executing the closure, the current message loop will be
// exited. See |AsyncWaiter| in mojo/public/c/environment/async_waiter.h for
// more details.
class PythonAsyncWaiter {
 public:
  explicit PythonAsyncWaiter(const mojo::Closure& quit_closure);
  ~PythonAsyncWaiter();
  MojoAsyncWaitID AsyncWait(MojoHandle handle,
                            MojoHandleSignals signals,
                            MojoDeadline deadline,
                            PyObject* callable);

  void CancelWait(MojoAsyncWaitID wait_id);

 private:
  class AsyncWaiterRunnable;

  typedef std::map<MojoAsyncWaitID,
                   internal::SharedPtr<mojo::Callback<void(MojoResult)> > >
      CallbackMap;

  CallbackMap callbacks_;
  const MojoAsyncWaiter* async_waiter_;
  const mojo::Closure quit_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(PythonAsyncWaiter);
};

}  // namespace python
}  // namespace mojo

#endif  // MOJO_PUBLIC_PYTHON_SRC_COMMON_H_

