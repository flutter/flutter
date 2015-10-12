// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Provides a base class for reference-counted classes.

#ifndef MOJO_EDK_SYSTEM_REF_COUNTED_H_
#define MOJO_EDK_SYSTEM_REF_COUNTED_H_

#include <assert.h>

#include <cstddef>
#include <utility>

#include "mojo/edk/system/ref_counted_internal.h"
#include "mojo/edk/system/ref_ptr.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {

// A base class for (thread-safe) reference-counted classes. Use like:
//
//   class Foo : public RefCountedThreadSafe<Foo> {
//     ...
//   };
//
// |~Foo()| *may* be made private (e.g., to avoid accidental deletion of objects
// while there are still references to them), |Foo| should friend
// |RefCountedThreadSafe<Foo>|; use |FRIEND_REF_COUNTED_THREAD_SAFE()| for this:
//
//   class Foo : public RefCountedThreadSafe<Foo> {
//     ...
//    private:
//     FRIEND_REF_COUNTED_THREAD_SAFE(Foo);
//     ~Foo();
//     ...
//   };
//
// Similarly, |Foo(...)| may be made private. In this case, there should either
// be a static factory method performing the requisite adoption:
//
//   class Foo : public RefCountedThreadSafe<Foo> {
//     ...
//    public:
//     inline static RefPtr<Foo> Create() { return AdoptRef(new Foo()); }
//     ...
//    private:
//     Foo();
//     ...
//   };
//
// Or, to allow |MakeRefCounted()| to be used, use |FRIEND_MAKE_REF_COUNTED()|:
//
//   class Foo : public RefCountedThreadSafe<Foo> {
//     ...
//    private:
//     FRIEND_MAKE_REF_COUNTED(Foo);
//     Foo();
//     Foo(const Bar& bar, bool maybe);
//     ...
//   };
//
// For now, we only have thread-safe reference counting, since that's all we
// need. It's easy enough to add thread-unsafe versions if necessary.
template <typename T>
class RefCountedThreadSafe : public internal::RefCountedThreadSafeBase {
 public:
  void Release() const {
    if (internal::RefCountedThreadSafeBase::Release())
      delete static_cast<const T*>(this);
  }

 protected:
  RefCountedThreadSafe() {}
  ~RefCountedThreadSafe() {}

#ifndef NDEBUG
  template <typename U>
  friend RefPtr<U> AdoptRef(U*);
  void Adopt() { internal::RefCountedThreadSafeBase::Adopt(); }
#endif

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(RefCountedThreadSafe);
};

// If you subclass |RefCountedThreadSafe| and want to keep your destructor
// private, use this. (See the example above |RefCountedThreadSafe|.)
#define FRIEND_REF_COUNTED_THREAD_SAFE(T) \
  friend class ::mojo::system::RefCountedThreadSafe<T>

// If you want to keep your constructor(s) private and still want to use
// |MakeRefCounted<T>()|, use this. (See the example above
// |RefCountedThreadSafe|.)
#define FRIEND_MAKE_REF_COUNTED(T) \
  friend class ::mojo::system::internal::MakeRefCountedHelper<T>

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_REF_COUNTED_H_
