// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SCOPED_REFPTR_H_
#define SCOPED_REFPTR_H_

// Stub scoped_refptr<T> class that supports an implicit cast to T*.
template <class T>
class scoped_refptr {
 public:
  typedef T element_type;
  scoped_refptr() : ptr_(0) {}
  scoped_refptr(T* p) : ptr_(p) {}
  scoped_refptr(const scoped_refptr<T>& r) : ptr_(r.ptr_) {}

  template <typename U>
  scoped_refptr(const scoped_refptr<U>& r)
      : ptr_(r.get()) {}

  ~scoped_refptr() {}

  T* get() const { return ptr_; }
  operator T*() const { return ptr_; }
  T* operator->() const { return ptr_; }

  scoped_refptr<T>& operator=(T* p) {
    ptr_ = p;
    return *this;
  }
  scoped_refptr<T>& operator=(const scoped_refptr<T>& r) {
    return *this = r.ptr_;
  }
  template <typename U>
  scoped_refptr<T>& operator=(const scoped_refptr<U>& r) {
    return *this = r.get();
  }

 protected:
  T* ptr_;
};

#endif  // SCOPED_REFPTR_H_
