// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TOOLS_ANDROID_FORWARDER2_SELF_DELETER_HELPER_H_
#define TOOLS_ANDROID_FORWARDER2_SELF_DELETER_HELPER_H_

#include "base/basictypes.h"
#include "base/bind.h"
#include "base/callback.h"
#include "base/location.h"
#include "base/logging.h"
#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "base/memory/weak_ptr.h"
#include "base/message_loop/message_loop_proxy.h"

namespace base {

class SingleThreadTaskRunner;

}  // namespace base

namespace forwarder2 {

// Helper template class to be used in the following case:
//   * T is the type of an object that implements some work through an internal
//     or worker thread.
//   * T wants the internal thread to invoke deletion of its own instance, on
//     the thread where the instance was created.
//
// To make this easier, do something like:
//   1) Add a SelfDeleteHelper<T> member to your class T, and default-initialize
//      it in its constructor.
//   2) In the internal thread, to trigger self-deletion, call the
//      MaybeDeleteSoon() method on this member.
//
// MaybeDeleteSoon() posts a task on the message loop where the T instance was
// created to delete it. The task will be safely ignored if the instance is
// otherwise deleted.
//
// Usage example:
// class Object {
//  public:
//   typedef base::Callback<void (scoped_ptr<Object>)> ErrorCallback;
//
//   Object(const ErrorCallback& error_callback)
//       : self_deleter_helper_(this, error_callback) {
//   }
//
//   void StartWork() {
//     // Post a callback to DoSomethingOnWorkerThread() below to another
//     // thread.
//   }
//
//   void DoSomethingOnWorkerThread() {
//     ...
//     if (error_happened)
//       self_deleter_helper_.MaybeDeleteSoon();
//   }
//
//  private:
//   SelfDeleterHelper<MySelfDeletingClass> self_deleter_helper_;
// };
//
// class ObjectOwner {
//  public:
//   ObjectOwner()
//      : object_(new Object(base::Bind(&ObjectOwner::DeleteObjectOnError,
//                                      base::Unretained(this))) {
//      // To keep this example simple base::Unretained(this) is used above but
//      // note that in a real world scenario the client would have to make sure
//      // that the ObjectOwner instance is still alive when
//      // DeleteObjectOnError() gets called below. This can be achieved by
//      // using a WeakPtr<ObjectOwner> for instance.
//   }
//
//   void StartWork() {
//     object_->StartWork();
//   }
//
//  private:
//   void DeleteObjectOnError(scoped_ptr<Object> object) {
//     DCHECK(thread_checker_.CalledOnValidThread());
//     DCHECK_EQ(object_, object);
//     // Do some extra work with |object| before it gets deleted...
//     object_.reset();
//     ignore_result(object.release());
//   }
//
//   base::ThreadChecker thread_checker_;
//   scoped_ptr<Object> object_;
// };
//
template <typename T>
class SelfDeleterHelper {
 public:
  typedef base::Callback<void (scoped_ptr<T>)> DeletionCallback;

  SelfDeleterHelper(T* self_deleting_object,
                    const DeletionCallback& deletion_callback)
      : construction_runner_(base::MessageLoopProxy::current()),
        self_deleting_object_(self_deleting_object),
        deletion_callback_(deletion_callback),
        weak_ptr_factory_(this) {
  }

  ~SelfDeleterHelper() {
    DCHECK(construction_runner_->RunsTasksOnCurrentThread());
  }

  void MaybeSelfDeleteSoon() {
    DCHECK(!construction_runner_->RunsTasksOnCurrentThread());
    construction_runner_->PostTask(
        FROM_HERE,
        base::Bind(&SelfDeleterHelper::SelfDelete,
                   weak_ptr_factory_.GetWeakPtr()));
  }

 private:
  void SelfDelete() {
    DCHECK(construction_runner_->RunsTasksOnCurrentThread());
    deletion_callback_.Run(make_scoped_ptr(self_deleting_object_));
  }

  const scoped_refptr<base::SingleThreadTaskRunner> construction_runner_;
  T* const self_deleting_object_;
  const DeletionCallback deletion_callback_;

  //WeakPtrFactory's documentation says:
  // Member variables should appear before the WeakPtrFactory, to ensure
  // that any WeakPtrs to Controller are invalidated before its members
  // variable's destructors are executed, rendering them invalid.
  base::WeakPtrFactory<SelfDeleterHelper<T> > weak_ptr_factory_;

  DISALLOW_COPY_AND_ASSIGN(SelfDeleterHelper);
};

}  // namespace forwarder2

#endif  // TOOLS_ANDROID_FORWARDER2_SELF_DELETER_HELPER_H_
