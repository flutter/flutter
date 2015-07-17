// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MEMORY_REF_COUNTED_DELETE_ON_MESSAGE_LOOP_H_
#define BASE_MEMORY_REF_COUNTED_DELETE_ON_MESSAGE_LOOP_H_

#include "base/location.h"
#include "base/logging.h"
#include "base/memory/ref_counted.h"
#include "base/single_thread_task_runner.h"

namespace base {

// RefCountedDeleteOnMessageLoop is similar to RefCountedThreadSafe, and ensures
// that the object will be deleted on a specified message loop.
//
// Sample usage:
// class Foo : public RefCountedDeleteOnMessageLoop<Foo> {
//
//   Foo(const scoped_refptr<SingleThreadTaskRunner>& loop)
//       : RefCountedDeleteOnMessageLoop<Foo>(loop) {
//     ...
//   }
//   ...
//  private:
//   friend class RefCountedDeleteOnMessageLoop<Foo>;
//   friend class DeleteHelper<Foo>;
//
//   ~Foo();
// };

// TODO(skyostil): Rename this to RefCountedDeleteOnTaskRunner.
template <class T>
class RefCountedDeleteOnMessageLoop : public subtle::RefCountedThreadSafeBase {
 public:
  // This constructor will accept a MessageL00pProxy object, but new code should
  // prefer a SingleThreadTaskRunner. A SingleThreadTaskRunner for the
  // MessageLoop on the current thread can be acquired by calling
  // MessageLoop::current()->task_runner().
  RefCountedDeleteOnMessageLoop(
      const scoped_refptr<SingleThreadTaskRunner>& task_runner)
      : task_runner_(task_runner) {
    DCHECK(task_runner_);
  }

  void AddRef() const {
    subtle::RefCountedThreadSafeBase::AddRef();
  }

  void Release() const {
    if (subtle::RefCountedThreadSafeBase::Release())
      DestructOnMessageLoop();
  }

 protected:
  friend class DeleteHelper<RefCountedDeleteOnMessageLoop>;
  ~RefCountedDeleteOnMessageLoop() {}

  void DestructOnMessageLoop() const {
    const T* t = static_cast<const T*>(this);
    if (task_runner_->BelongsToCurrentThread())
      delete t;
    else
      task_runner_->DeleteSoon(FROM_HERE, t);
  }

  scoped_refptr<SingleThreadTaskRunner> task_runner_;

 private:
  DISALLOW_COPY_AND_ASSIGN(RefCountedDeleteOnMessageLoop);
};

}  // namespace base

#endif  // BASE_MEMORY_REF_COUNTED_DELETE_ON_MESSAGE_LOOP_H_
