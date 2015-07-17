// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TASK_RUNNER_UTIL_H_
#define BASE_TASK_RUNNER_UTIL_H_

#include "base/bind.h"
#include "base/bind_helpers.h"
#include "base/callback_internal.h"
#include "base/logging.h"
#include "base/task_runner.h"

namespace base {

namespace internal {

// Adapts a function that produces a result via a return value to
// one that returns via an output parameter.
template <typename ReturnType>
void ReturnAsParamAdapter(const Callback<ReturnType(void)>& func,
                          ReturnType* result) {
  *result = func.Run();
}

// Adapts a T* result to a callblack that expects a T.
template <typename TaskReturnType, typename ReplyArgType>
void ReplyAdapter(const Callback<void(ReplyArgType)>& callback,
                  TaskReturnType* result) {
  // TODO(ajwong): Remove this conditional and add a DCHECK to enforce that
  // |reply| must be non-null in PostTaskAndReplyWithResult() below after
  // current code that relies on this API softness has been removed.
  // http://crbug.com/162712
  if (!callback.is_null())
    callback.Run(CallbackForward(*result));
}

}  // namespace internal

// When you have these methods
//
//   R DoWorkAndReturn();
//   void Callback(const R& result);
//
// and want to call them in a PostTaskAndReply kind of fashion where the
// result of DoWorkAndReturn is passed to the Callback, you can use
// PostTaskAndReplyWithResult as in this example:
//
// PostTaskAndReplyWithResult(
//     target_thread_.task_runner(),
//     FROM_HERE,
//     Bind(&DoWorkAndReturn),
//     Bind(&Callback));
template <typename TaskReturnType, typename ReplyArgType>
bool PostTaskAndReplyWithResult(
    TaskRunner* task_runner,
    const tracked_objects::Location& from_here,
    const Callback<TaskReturnType(void)>& task,
    const Callback<void(ReplyArgType)>& reply) {
  TaskReturnType* result = new TaskReturnType();
  return task_runner->PostTaskAndReply(
      from_here,
      base::Bind(&internal::ReturnAsParamAdapter<TaskReturnType>, task,
                 result),
      base::Bind(&internal::ReplyAdapter<TaskReturnType, ReplyArgType>, reply,
                 base::Owned(result)));
}

}  // namespace base

#endif  // BASE_TASK_RUNNER_UTIL_H_
