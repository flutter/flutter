// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/python/src/common.h"

#include <Python.h>

#include "mojo/public/c/environment/async_waiter.h"
#include "mojo/public/cpp/bindings/callback.h"
#include "mojo/public/cpp/bindings/lib/shared_ptr.h"
#include "mojo/public/cpp/environment/logging.h"
#include "mojo/public/cpp/system/core.h"
#include "mojo/public/cpp/system/macros.h"
#include "mojo/public/cpp/utility/run_loop.h"

namespace {

void AsyncCallbackForwarder(void* closure, MojoResult result) {
  mojo::Callback<void(MojoResult)>* callback =
      static_cast<mojo::Callback<void(MojoResult)>*>(closure);
  // callback will be deleted when it is run.
  callback->Run(result);
}

}  // namespace

namespace mojo {
namespace python {

ScopedGIL::ScopedGIL() {
  state_ = PyGILState_Ensure();
}

ScopedGIL::~ScopedGIL() {
  PyGILState_Release(state_);
}

ScopedPyRef::ScopedPyRef(PyObject* object) : object_(object) {
}

ScopedPyRef::ScopedPyRef(PyObject* object, ScopedPyRefAcquire)
    : object_(object) {
  if (object_)
    Py_XINCREF(object_);
}

ScopedPyRef::ScopedPyRef(const ScopedPyRef& other)
    : ScopedPyRef(other, kAcquire) {
}

PyObject* ScopedPyRef::Release() {
  PyObject* object = object_;
  object_ = nullptr;
  return object;
}

ScopedPyRef::~ScopedPyRef() {
  if (object_) {
    ScopedGIL acquire_gil;
    Py_DECREF(object_);
  }
}

ScopedPyRef& ScopedPyRef::operator=(const ScopedPyRef& other) {
  if (other)
    Py_XINCREF(other);
  PyObject* old = object_;
  object_ = other;
  if (old)
    Py_DECREF(old);
  return *this;
}

PythonClosure::PythonClosure(PyObject* callable, const mojo::Closure& quit)
    : callable_(callable, kAcquire), quit_(quit) {
  MOJO_DCHECK(callable);
}

PythonClosure::~PythonClosure() {}

void PythonClosure::Run() const {
  ScopedGIL acquire_gil;
  ScopedPyRef empty_tuple(PyTuple_New(0));
  if (!empty_tuple) {
    quit_.Run();
    return;
  }

  ScopedPyRef result(PyObject_CallObject(callable_, empty_tuple));
  if (!result) {
    quit_.Run();
    return;
  }
}

Closure::Runnable* NewRunnableFromCallable(PyObject* callable,
                                          const mojo::Closure& quit_closure) {
  MOJO_DCHECK(PyCallable_Check(callable));

  return new PythonClosure(callable, quit_closure);
}

class PythonAsyncWaiter::AsyncWaiterRunnable
    : public mojo::Callback<void(MojoResult)>::Runnable {
 public:
  AsyncWaiterRunnable(PyObject* callable,
                      CallbackMap* callbacks,
                      const mojo::Closure& quit)
      : wait_id_(0),
        callable_(callable, kAcquire),
        callbacks_(callbacks),
        quit_(quit) {
    MOJO_DCHECK(callable_);
    MOJO_DCHECK(callbacks_);
  }

  void set_wait_id(MojoAsyncWaitID wait_id) { wait_id_ = wait_id; }

  void Run(MojoResult mojo_result) const override {
    MOJO_DCHECK(wait_id_);

    // Remove to reference to this object from PythonAsyncWaiter and ensure this
    // object will be destroyed when this method exits.
    MOJO_DCHECK(callbacks_->find(wait_id_) != callbacks_->end());
    internal::SharedPtr<mojo::Callback<void(MojoResult)>> self =
        (*callbacks_)[wait_id_];
    callbacks_->erase(wait_id_);

    ScopedGIL acquire_gil;
    ScopedPyRef args_tuple(Py_BuildValue("(i)", mojo_result));
    if (!args_tuple) {
      quit_.Run();
      return;
    }

    ScopedPyRef result(PyObject_CallObject(callable_, args_tuple));
    if (!result) {
      quit_.Run();
      return;
    }
  }

 private:
  MojoAsyncWaitID wait_id_;
  ScopedPyRef callable_;
  CallbackMap* callbacks_;
  const mojo::Closure quit_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(AsyncWaiterRunnable);
};

PythonAsyncWaiter::PythonAsyncWaiter(const mojo::Closure& quit_closure)
    : quit_(quit_closure) {
  async_waiter_ = Environment::GetDefaultAsyncWaiter();
}

PythonAsyncWaiter::~PythonAsyncWaiter() {
  for (CallbackMap::const_iterator it = callbacks_.begin();
       it != callbacks_.end();
       ++it) {
    async_waiter_->CancelWait(it->first);
  }
}

MojoAsyncWaitID PythonAsyncWaiter::AsyncWait(MojoHandle handle,
                                             MojoHandleSignals signals,
                                             MojoDeadline deadline,
                                             PyObject* callable) {
  AsyncWaiterRunnable* runner =
      new AsyncWaiterRunnable(callable, &callbacks_, quit_);
  internal::SharedPtr<mojo::Callback<void(MojoResult)>> callback(
      new mojo::Callback<void(MojoResult)>(
          static_cast<mojo::Callback<void(MojoResult)>::Runnable*>(runner)));
  MojoAsyncWaitID wait_id = async_waiter_->AsyncWait(
      handle, signals, deadline, &AsyncCallbackForwarder, callback.get());
  callbacks_[wait_id] = callback;
  runner->set_wait_id(wait_id);
  return wait_id;
}

void PythonAsyncWaiter::CancelWait(MojoAsyncWaitID wait_id) {
  if (callbacks_.find(wait_id) != callbacks_.end()) {
    async_waiter_->CancelWait(wait_id);
    callbacks_.erase(wait_id);
  }
}

}  // namespace python
}  // namespace mojo
