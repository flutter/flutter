// Copyright (c) 2010 The Chromium Authors. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//    * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//    * Neither the name of Google Inc. nor the names of its
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
//
// Utility for using SideStep with unit tests.

#ifndef CEEE_TESTING_SIDESTEP_AUTO_TESTING_HOOK_H_
#define CEEE_TESTING_SIDESTEP_AUTO_TESTING_HOOK_H_

#include "base/basictypes.h"
#include "base/logging.h"
#include "preamble_patcher.h"

#define SIDESTEP_CHK(x)  CHECK(x)
#define SIDESTEP_EXPECT_TRUE(x)  SIDESTEP_CHK(x)

namespace sidestep {

// Same trick as common/scope_cleanup.h ScopeGuardImplBase
class AutoTestingHookBase {
 public:
  virtual ~AutoTestingHookBase() {}
};

// This is the typedef you normally use for the class, e.g.
//
// AutoTestingHook hook = MakeTestingHook(TargetFunc, HookTargetFunc);
//
// The 'hook' variable will then be destroyed when it goes out of scope.
//
// NOTE: You must not hold this type as a member of another class.  Its
// destructor will not get called.
typedef const AutoTestingHookBase& AutoTestingHook;

// This is the class you must use when holding a hook as a member of another
// class, e.g.
//
// public:
//  AutoTestingHookHolder holder_;
//  MyClass() : my_hook_holder(MakeTestingHookHolder(Target, Hook)) {}
class AutoTestingHookHolder {
 public:
  explicit AutoTestingHookHolder(AutoTestingHookBase* hook) : hook_(hook) {}
  ~AutoTestingHookHolder() { delete hook_; }
 private:
  AutoTestingHookHolder() {}  // disallow
  AutoTestingHookBase* hook_;
};

// This class helps patch a function, then unpatch it when the object exits
// scope, and also maintains the pointer to the original function stub.
//
// To enable use of the class without having to explicitly provide the
// type of the function pointers (and instead only providing it
// implicitly) we use the same trick as ScopeGuard (see
// common/scope_cleanup.h) uses, so to create a hook you use the MakeHook
// function rather than a constructor.
//
// NOTE:  This function is only safe for e.g. unit tests and _not_ for
// production code.  See PreamblePatcher class for details.
template <typename T>
class AutoTestingHookImpl : public AutoTestingHookBase {
 public:
  static AutoTestingHookImpl<T> MakeTestingHook(T target_function,
                                                T replacement_function,
                                                bool do_it) {
    return AutoTestingHookImpl<T>(target_function, replacement_function, do_it);
  }

  static AutoTestingHookImpl<T>* MakeTestingHookHolder(T target_function,
                                                       T replacement_function,
                                                       bool do_it) {
    return new AutoTestingHookImpl<T>(target_function,
                                      replacement_function, do_it);
  }

  ~AutoTestingHookImpl() {
    if (did_it_) {
      SIDESTEP_CHK(SIDESTEP_SUCCESS == PreamblePatcher::Unpatch(
          (void*)target_function_, (void*)replacement_function_,
          (void*)original_function_));
    }
  }

  // Returns a pointer to the original function.  To use this method you will
  // have to explicitly create an AutoTestingHookImpl of the specific
  // function pointer type (i.e. not use the AutoTestingHook typedef).
  T original_function() {
    return original_function_;
  }

 private:
  AutoTestingHookImpl(T target_function, T replacement_function, bool do_it)
      : target_function_(target_function),
        original_function_(NULL),
        replacement_function_(replacement_function),
        did_it_(do_it) {
    if (do_it) {
      SIDESTEP_CHK(SIDESTEP_SUCCESS == PreamblePatcher::Patch(target_function,
                                                     replacement_function,
                                                     &original_function_));
    }
  }

  T target_function_;  // always valid
  T original_function_;  // always valid
  T replacement_function_;  // always valid
  bool did_it_;  // Remember if we did it or not...
};

template <typename T>
inline AutoTestingHookImpl<T> MakeTestingHook(T target,
                                              T replacement,
                                              bool do_it) {
  return AutoTestingHookImpl<T>::MakeTestingHook(target, replacement, do_it);
}

template <typename T>
inline AutoTestingHookImpl<T> MakeTestingHook(T target, T replacement) {
  return AutoTestingHookImpl<T>::MakeTestingHook(target, replacement, true);
}

template <typename T>
inline AutoTestingHookImpl<T>* MakeTestingHookHolder(T target, T replacement) {
  return AutoTestingHookImpl<T>::MakeTestingHookHolder(target, replacement,
                                                       true);
}

};  // namespace sidestep

#endif  // CEEE_TESTING_SIDESTEP_AUTO_TESTING_HOOK_H_
