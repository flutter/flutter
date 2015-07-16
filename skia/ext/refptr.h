// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKIA_EXT_REFPTR_H_
#define SKIA_EXT_REFPTR_H_

#include "third_party/skia/include/core/SkRefCnt.h"

namespace skia {

// When creating/receiving a ref-counted pointer from Skia, wrap that pointer in
// this class to avoid dealing with the ref-counting and prevent leaks/crashes
// due to ref-counting bugs.
//
// Example of creating a new SkShader* and setting it on a SkPaint:
//   skia::RefPtr<SkShader> shader = skia::AdoptRef(SkGradientShader::Create());
//   paint.setShader(shader.get());
//
// When passing around a ref-counted pointer to methods outside of Skia, always
// pass around the skia::RefPtr instead of the raw pointer. An example method
// that takes a SkShader* parameter and saves the SkShader* in the class.
//   void AMethodThatSavesAShader(const skia::RefPtr<SkShader>& shader) {
//     member_refptr_ = shader;
//   }
//   skia::RefPtr<SkShader> member_refptr_;
//
// When returning a ref-counted pointer, also return the skia::RefPtr instead.
// An example method that creates an SkShader* and returns it:
//   skia::RefPtr<SkShader> MakeAShader() {
//     return skia::AdoptRef(SkGradientShader::Create());
//   }
//
// To take a scoped reference to an object whose references are all owned
// by other objects (i.e. does not have one that needs to be adopted) use the
// skia::SharePtr helper:
//
//   skia::RefPtr<SkShader> shader = skia::SharePtr(paint.getShader());
//
// Never call ref() or unref() on the underlying ref-counted pointer. If you
// AdoptRef() the raw pointer immediately into a skia::RefPtr and always work
// with skia::RefPtr instances instead, the ref-counting will be taken care of
// for you.
template<typename T>
class RefPtr {
 public:
  RefPtr() : ptr_(NULL) {}

  RefPtr(const RefPtr& other)
      : ptr_(other.get()) {
    SkSafeRef(ptr_);
  }

  template<typename U>
  RefPtr(const RefPtr<U>& other)
      : ptr_(other.get()) {
    SkSafeRef(ptr_);
  }

  ~RefPtr() {
    clear();
  }

  RefPtr& operator=(const RefPtr& other) {
    SkRefCnt_SafeAssign(ptr_, other.get());
    return *this;
  }

  template<typename U>
  RefPtr& operator=(const RefPtr<U>& other) {
    SkRefCnt_SafeAssign(ptr_, other.get());
    return *this;
  }

  void clear() {
    T* to_unref = ptr_;
    ptr_ = NULL;
    SkSafeUnref(to_unref);
  }

  T* get() const { return ptr_; }
  T& operator*() const { return *ptr_; }
  T* operator->() const { return ptr_; }

  typedef T* RefPtr::*unspecified_bool_type;
  operator unspecified_bool_type() const {
    return ptr_ ? &RefPtr::ptr_ : NULL;
  }

 private:
  T* ptr_;

  // This function cannot be public because Skia starts its ref-counted
  // objects at refcnt=1.  This makes it impossible to differentiate
  // between a newly created object (that doesn't need to be ref'd) or an
  // already existing object with one owner (that does need to be ref'd so that
  // this RefPtr can also manage its lifetime).
  explicit RefPtr(T* ptr) : ptr_(ptr) {}

  template<typename U>
  friend RefPtr<U> AdoptRef(U* ptr);

  template<typename U>
  friend RefPtr<U> SharePtr(U* ptr);
};

// For objects that have an unowned reference (such as newly created objects).
template<typename T>
RefPtr<T> AdoptRef(T* ptr) { return RefPtr<T>(ptr); }

// For objects that are already owned. This doesn't take ownership of existing
// references and adds a new one.
template<typename T>
RefPtr<T> SharePtr(T* ptr) { return RefPtr<T>(SkSafeRef(ptr)); }

}  // namespace skia

#endif  // SKIA_EXT_REFPTR_H_
