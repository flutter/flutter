// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/python/src/python_system_helper.h"

#include "Python.h"

#include "mojo/public/cpp/utility/run_loop.h"
#include "mojo/public/python/src/common.h"

namespace {
class QuitCurrentRunLoop : public mojo::Closure::Runnable {
 public:
  void Run() const override {
    mojo::RunLoop::current()->Quit();
  }

  static mojo::Closure NewQuitClosure() {
    return mojo::Closure(
        static_cast<mojo::Closure::Runnable*>(new QuitCurrentRunLoop()));
  }
};

}  // namespace

namespace mojo {
namespace python {

Closure BuildClosure(PyObject* callable) {
  if (!PyCallable_Check(callable))
    return Closure();

  return mojo::Closure(
      NewRunnableFromCallable(callable, QuitCurrentRunLoop::NewQuitClosure()));
}

PythonAsyncWaiter* NewAsyncWaiter() {
  return new PythonAsyncWaiter(QuitCurrentRunLoop::NewQuitClosure());
}

}  // namespace python
}  // namespace mojo
