// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Macros for static thread-safety analysis.
//
// These are from http://clang.llvm.org/docs/ThreadSafetyAnalysis.html (and thus
// really derive from google3's thread_annotations.h).
//
// TODO(vtl): We're still using the old-fashioned, deprecated annotations
// ("locks" instead of "capabilities"), since the new ones don't work yet (in
// particular, |TRY_ACQUIRE()| doesn't work: b/19264527).
// https://github.com/domokit/mojo/issues/314

#ifndef FLUTTER_FML_SYNCHRONIZATION_THREAD_ANNOTATIONS_H_
#define FLUTTER_FML_SYNCHRONIZATION_THREAD_ANNOTATIONS_H_

#include "flutter/fml/build_config.h"

// Enable thread-safety attributes only with clang.
// The attributes can be safely erased when compiling with other compilers.
#if defined(__clang__) && !defined(OS_ANDROID)
#define FML_THREAD_ANNOTATION_ATTRIBUTE__(x) __attribute__((x))
#else
#define FML_THREAD_ANNOTATION_ATTRIBUTE__(x)
#endif

#define FML_GUARDED_BY(x) FML_THREAD_ANNOTATION_ATTRIBUTE__(guarded_by(x))

#define FML_PT_GUARDED_BY(x) FML_THREAD_ANNOTATION_ATTRIBUTE__(pt_guarded_by(x))

#define FML_ACQUIRE(...) \
  FML_THREAD_ANNOTATION_ATTRIBUTE__(acquire_capability(__VA_ARGS__))

#define FML_RELEASE(...) \
  FML_THREAD_ANNOTATION_ATTRIBUTE__(release_capability(__VA_ARGS__))

#define FML_ACQUIRED_AFTER(...) \
  FML_THREAD_ANNOTATION_ATTRIBUTE__(acquired_after(__VA_ARGS__))

#define FML_ACQUIRED_BEFORE(...) \
  FML_THREAD_ANNOTATION_ATTRIBUTE__(acquired_before(__VA_ARGS__))

#define FML_EXCLUSIVE_LOCKS_REQUIRED(...) \
  FML_THREAD_ANNOTATION_ATTRIBUTE__(exclusive_locks_required(__VA_ARGS__))

#define FML_SHARED_LOCKS_REQUIRED(...) \
  FML_THREAD_ANNOTATION_ATTRIBUTE__(shared_locks_required(__VA_ARGS__))

#define FML_LOCKS_EXCLUDED(...) \
  FML_THREAD_ANNOTATION_ATTRIBUTE__(locks_excluded(__VA_ARGS__))

#define FML_LOCK_RETURNED(x) FML_THREAD_ANNOTATION_ATTRIBUTE__(lock_returned(x))

#define FML_LOCKABLE FML_THREAD_ANNOTATION_ATTRIBUTE__(lockable)

#define FML_SCOPED_LOCKABLE FML_THREAD_ANNOTATION_ATTRIBUTE__(scoped_lockable)

#define FML_EXCLUSIVE_LOCK_FUNCTION(...) \
  FML_THREAD_ANNOTATION_ATTRIBUTE__(exclusive_lock_function(__VA_ARGS__))

#define FML_SHARED_LOCK_FUNCTION(...) \
  FML_THREAD_ANNOTATION_ATTRIBUTE__(shared_lock_function(__VA_ARGS__))

#define FML_ASSERT_EXCLUSIVE_LOCK(...) \
  FML_THREAD_ANNOTATION_ATTRIBUTE__(assert_exclusive_lock(__VA_ARGS__))

#define FML_ASSERT_SHARED_LOCK(...) \
  FML_THREAD_ANNOTATION_ATTRIBUTE__(assert_shared_lock(__VA_ARGS__))

#define FML_EXCLUSIVE_TRYLOCK_FUNCTION(...) \
  FML_THREAD_ANNOTATION_ATTRIBUTE__(exclusive_trylock_function(__VA_ARGS__))

#define FML_SHARED_TRYLOCK_FUNCTION(...) \
  FML_THREAD_ANNOTATION_ATTRIBUTE__(shared_trylock_function(__VA_ARGS__))

#define FML_UNLOCK_FUNCTION(...) \
  FML_THREAD_ANNOTATION_ATTRIBUTE__(unlock_function(__VA_ARGS__))

#define FML_NO_THREAD_SAFETY_ANALYSIS \
  FML_THREAD_ANNOTATION_ATTRIBUTE__(no_thread_safety_analysis)

// Use this in the header to annotate a function/method as not being
// thread-safe. This is equivalent to |FML_NO_THREAD_SAFETY_ANALYSIS|, but
// semantically different: it declares that the caller must abide by additional
// restrictions. Limitation: Unfortunately, you can't apply this to a method in
// an interface (i.e., pure virtual method) and have it applied automatically to
// implementations.
#define FML_NOT_THREAD_SAFE FML_NO_THREAD_SAFETY_ANALYSIS

#endif  // FLUTTER_FML_SYNCHRONIZATION_THREAD_ANNOTATIONS_H_
