// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/callback_list.h"

#include "base/basictypes.h"
#include "base/bind.h"
#include "base/bind_helpers.h"
#include "base/memory/scoped_ptr.h"

namespace base {

class Foo {
 public:
  Foo() {}
  ~Foo() {}
};

class FooListener {
 public:
  FooListener() {}

  void GotAScopedFoo(scoped_ptr<Foo> f) { foo_ = f.Pass(); }

  scoped_ptr<Foo> foo_;

 private:
  DISALLOW_COPY_AND_ASSIGN(FooListener);
};


#if defined(NCTEST_MOVE_ONLY_TYPE_PARAMETER)  // [r"calling a private constructor of class"]

// Callbacks run with a move-only typed parameter.
//
// CallbackList does not support move-only typed parameters. Notify() is
// designed to take zero or more parameters, and run each registered callback
// with them. With move-only types, the parameter will be set to NULL after the
// first callback has been run.
void WontCompile() {
  FooListener f;
  CallbackList<void(scoped_ptr<Foo>)> c1;
  scoped_ptr<CallbackList<void(scoped_ptr<Foo>)>::Subscription> sub =
      c1.Add(Bind(&FooListener::GotAScopedFoo, Unretained(&f)));
  c1.Notify(scoped_ptr<Foo>(new Foo()));
}

#endif

}  // namespace base
