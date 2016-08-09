// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This is almost the source from N3656 ("make_unique (Revision 1)";
// https://isocpp.org/files/papers/N3656.txt) almost verbatim, so that we have a
// "make_unique" to use until we can use C++14. The following changes have been
// made:
//   - It's called |MakeUnique| instead of |make_unique|.
//   - It's in the |mojo::util| namespace instead of |std|; this also
//     necessitates adding some |std::|s.
//   - It's been formatted.

#ifndef MOJO_EDK_UTIL_MAKE_UNIQUE_H_
#define MOJO_EDK_UTIL_MAKE_UNIQUE_H_

#include <stddef.h>

#include <memory>
#include <type_traits>
#include <utility>

namespace mojo {
namespace util {

template <class T>
struct _Unique_if {
  typedef std::unique_ptr<T> _Single_object;
};

template <class T>
struct _Unique_if<T[]> {
  typedef std::unique_ptr<T[]> _Unknown_bound;
};

template <class T, size_t N>
struct _Unique_if<T[N]> {
  typedef void _Known_bound;
};

template <class T, class... Args>
typename _Unique_if<T>::_Single_object MakeUnique(Args&&... args) {
  return std::unique_ptr<T>(new T(std::forward<Args>(args)...));
}

template <class T>
typename _Unique_if<T>::_Unknown_bound MakeUnique(size_t n) {
  typedef typename std::remove_extent<T>::type U;
  return std::unique_ptr<T>(new U[n]());
}

template <class T, class... Args>
typename _Unique_if<T>::_Known_bound MakeUnique(Args&&...) = delete;

}  // namespace util
}  // namespace mojo

#endif  // MOJO_EDK_UTIL_MAKE_UNIQUE_H_
