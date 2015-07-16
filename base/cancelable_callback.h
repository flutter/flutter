// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// CancelableCallback is a wrapper around base::Callback that allows
// cancellation of a callback. CancelableCallback takes a reference on the
// wrapped callback until this object is destroyed or Reset()/Cancel() are
// called.
//
// NOTE:
//
// Calling CancelableCallback::Cancel() brings the object back to its natural,
// default-constructed state, i.e., CancelableCallback::callback() will return
// a null callback.
//
// THREAD-SAFETY:
//
// CancelableCallback objects must be created on, posted to, cancelled on, and
// destroyed on the same thread.
//
//
// EXAMPLE USAGE:
//
// In the following example, the test is verifying that RunIntensiveTest()
// Quit()s the message loop within 4 seconds. The cancelable callback is posted
// to the message loop, the intensive test runs, the message loop is run,
// then the callback is cancelled.
//
// void TimeoutCallback(const std::string& timeout_message) {
//   FAIL() << timeout_message;
//   MessageLoop::current()->QuitWhenIdle();
// }
//
// CancelableClosure timeout(base::Bind(&TimeoutCallback, "Test timed out."));
// MessageLoop::current()->PostDelayedTask(FROM_HERE, timeout.callback(),
//                                         4000)  // 4 seconds to run.
// RunIntensiveTest();
// MessageLoop::current()->Run();
// timeout.Cancel();  // Hopefully this is hit before the timeout callback runs.
//

#ifndef BASE_CANCELABLE_CALLBACK_H_
#define BASE_CANCELABLE_CALLBACK_H_

#include "base/base_export.h"
#include "base/bind.h"
#include "base/callback.h"
#include "base/callback_internal.h"
#include "base/compiler_specific.h"
#include "base/logging.h"
#include "base/memory/weak_ptr.h"

namespace base {

template <typename Sig>
class CancelableCallback;

template <typename... A>
class CancelableCallback<void(A...)> {
 public:
  CancelableCallback() : weak_factory_(this) {}

  // |callback| must not be null.
  explicit CancelableCallback(const base::Callback<void(A...)>& callback)
      : callback_(callback), weak_factory_(this) {
    DCHECK(!callback.is_null());
    InitializeForwarder();
  }

  ~CancelableCallback() {}

  // Cancels and drops the reference to the wrapped callback.
  void Cancel() {
    weak_factory_.InvalidateWeakPtrs();
    forwarder_.Reset();
    callback_.Reset();
  }

  // Returns true if the wrapped callback has been cancelled.
  bool IsCancelled() const {
    return callback_.is_null();
  }

  // Sets |callback| as the closure that may be cancelled. |callback| may not
  // be null. Outstanding and any previously wrapped callbacks are cancelled.
  void Reset(const base::Callback<void(A...)>& callback) {
    DCHECK(!callback.is_null());

    // Outstanding tasks (e.g., posted to a message loop) must not be called.
    Cancel();

    // |forwarder_| is no longer valid after Cancel(), so re-bind.
    InitializeForwarder();

    callback_ = callback;
  }

  // Returns a callback that can be disabled by calling Cancel().
  const base::Callback<void(A...)>& callback() const {
    return forwarder_;
  }

 private:
  void Forward(A... args) const {
    callback_.Run(args...);
  }

  // Helper method to bind |forwarder_| using a weak pointer from
  // |weak_factory_|.
  void InitializeForwarder() {
    forwarder_ = base::Bind(&CancelableCallback<void(A...)>::Forward,
                            weak_factory_.GetWeakPtr());
  }

  // The wrapper closure.
  base::Callback<void(A...)> forwarder_;

  // The stored closure that may be cancelled.
  base::Callback<void(A...)> callback_;

  // Used to ensure Forward() is not run when this object is destroyed.
  base::WeakPtrFactory<CancelableCallback<void(A...)>> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(CancelableCallback);
};

typedef CancelableCallback<void(void)> CancelableClosure;

}  // namespace base

#endif  // BASE_CANCELABLE_CALLBACK_H_
