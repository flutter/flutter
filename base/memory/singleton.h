// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// PLEASE READ: Do you really need a singleton?
//
// Singletons make it hard to determine the lifetime of an object, which can
// lead to buggy code and spurious crashes.
//
// Instead of adding another singleton into the mix, try to identify either:
//   a) An existing singleton that can manage your object's lifetime
//   b) Locations where you can deterministically create the object and pass
//      into other objects
//
// If you absolutely need a singleton, please keep them as trivial as possible
// and ideally a leaf dependency. Singletons get problematic when they attempt
// to do too much in their destructor or have circular dependencies.

#ifndef BASE_MEMORY_SINGLETON_H_
#define BASE_MEMORY_SINGLETON_H_

#include "base/at_exit.h"
#include "base/atomicops.h"
#include "base/base_export.h"
#include "base/memory/aligned_memory.h"
#include "base/threading/thread_restrictions.h"

namespace base {
namespace internal {

// Our AtomicWord doubles as a spinlock, where a value of
// kBeingCreatedMarker means the spinlock is being held for creation.
static const subtle::AtomicWord kBeingCreatedMarker = 1;

// We pull out some of the functionality into a non-templated function, so that
// we can implement the more complicated pieces out of line in the .cc file.
BASE_EXPORT subtle::AtomicWord WaitForInstance(subtle::AtomicWord* instance);

}  // namespace internal
}  // namespace base

// TODO(joth): Move more of this file into namespace base

// Default traits for Singleton<Type>. Calls operator new and operator delete on
// the object. Registers automatic deletion at process exit.
// Overload if you need arguments or another memory allocation function.
template<typename Type>
struct DefaultSingletonTraits {
  // Allocates the object.
  static Type* New() {
    // The parenthesis is very important here; it forces POD type
    // initialization.
    return new Type();
  }

  // Destroys the object.
  static void Delete(Type* x) {
    delete x;
  }

  // Set to true to automatically register deletion of the object on process
  // exit. See below for the required call that makes this happen.
  static const bool kRegisterAtExit = true;

#ifndef NDEBUG
  // Set to false to disallow access on a non-joinable thread.  This is
  // different from kRegisterAtExit because StaticMemorySingletonTraits allows
  // access on non-joinable threads, and gracefully handles this.
  static const bool kAllowedToAccessOnNonjoinableThread = false;
#endif
};


// Alternate traits for use with the Singleton<Type>.  Identical to
// DefaultSingletonTraits except that the Singleton will not be cleaned up
// at exit.
template<typename Type>
struct LeakySingletonTraits : public DefaultSingletonTraits<Type> {
  static const bool kRegisterAtExit = false;
#ifndef NDEBUG
  static const bool kAllowedToAccessOnNonjoinableThread = true;
#endif
};


// Alternate traits for use with the Singleton<Type>.  Allocates memory
// for the singleton instance from a static buffer.  The singleton will
// be cleaned up at exit, but can't be revived after destruction unless
// the Resurrect() method is called.
//
// This is useful for a certain category of things, notably logging and
// tracing, where the singleton instance is of a type carefully constructed to
// be safe to access post-destruction.
// In logging and tracing you'll typically get stray calls at odd times, like
// during static destruction, thread teardown and the like, and there's a
// termination race on the heap-based singleton - e.g. if one thread calls
// get(), but then another thread initiates AtExit processing, the first thread
// may call into an object residing in unallocated memory. If the instance is
// allocated from the data segment, then this is survivable.
//
// The destructor is to deallocate system resources, in this case to unregister
// a callback the system will invoke when logging levels change. Note that
// this is also used in e.g. Chrome Frame, where you have to allow for the
// possibility of loading briefly into someone else's process space, and
// so leaking is not an option, as that would sabotage the state of your host
// process once you've unloaded.
template <typename Type>
struct StaticMemorySingletonTraits {
  // WARNING: User has to deal with get() in the singleton class
  // this is traits for returning NULL.
  static Type* New() {
    // Only constructs once and returns pointer; otherwise returns NULL.
    if (base::subtle::NoBarrier_AtomicExchange(&dead_, 1))
      return NULL;

    return new(buffer_.void_data()) Type();
  }

  static void Delete(Type* p) {
    if (p != NULL)
      p->Type::~Type();
  }

  static const bool kRegisterAtExit = true;
  static const bool kAllowedToAccessOnNonjoinableThread = true;

  // Exposed for unittesting.
  static void Resurrect() {
    base::subtle::NoBarrier_Store(&dead_, 0);
  }

 private:
  static base::AlignedMemory<sizeof(Type), ALIGNOF(Type)> buffer_;
  // Signal the object was already deleted, so it is not revived.
  static base::subtle::Atomic32 dead_;
};

template <typename Type> base::AlignedMemory<sizeof(Type), ALIGNOF(Type)>
    StaticMemorySingletonTraits<Type>::buffer_;
template <typename Type> base::subtle::Atomic32
    StaticMemorySingletonTraits<Type>::dead_ = 0;

// The Singleton<Type, Traits, DifferentiatingType> class manages a single
// instance of Type which will be created on first use and will be destroyed at
// normal process exit). The Trait::Delete function will not be called on
// abnormal process exit.
//
// DifferentiatingType is used as a key to differentiate two different
// singletons having the same memory allocation functions but serving a
// different purpose. This is mainly used for Locks serving different purposes.
//
// Example usage:
//
// In your header:
//   template <typename T> struct DefaultSingletonTraits;
//   class FooClass {
//    public:
//     static FooClass* GetInstance();  <-- See comment below on this.
//     void Bar() { ... }
//    private:
//     FooClass() { ... }
//     friend struct DefaultSingletonTraits<FooClass>;
//
//     DISALLOW_COPY_AND_ASSIGN(FooClass);
//   };
//
// In your source file:
//  #include "base/memory/singleton.h"
//  FooClass* FooClass::GetInstance() {
//    return Singleton<FooClass>::get();
//  }
//
// And to call methods on FooClass:
//   FooClass::GetInstance()->Bar();
//
// NOTE: The method accessing Singleton<T>::get() has to be named as GetInstance
// and it is important that FooClass::GetInstance() is not inlined in the
// header. This makes sure that when source files from multiple targets include
// this header they don't end up with different copies of the inlined code
// creating multiple copies of the singleton.
//
// Singleton<> has no non-static members and doesn't need to actually be
// instantiated.
//
// This class is itself thread-safe. The underlying Type must of course be
// thread-safe if you want to use it concurrently. Two parameters may be tuned
// depending on the user's requirements.
//
// Glossary:
//   RAE = kRegisterAtExit
//
// On every platform, if Traits::RAE is true, the singleton will be destroyed at
// process exit. More precisely it uses base::AtExitManager which requires an
// object of this type to be instantiated. AtExitManager mimics the semantics
// of atexit() such as LIFO order but under Windows is safer to call. For more
// information see at_exit.h.
//
// If Traits::RAE is false, the singleton will not be freed at process exit,
// thus the singleton will be leaked if it is ever accessed. Traits::RAE
// shouldn't be false unless absolutely necessary. Remember that the heap where
// the object is allocated may be destroyed by the CRT anyway.
//
// Caveats:
// (a) Every call to get(), operator->() and operator*() incurs some overhead
//     (16ns on my P4/2.8GHz) to check whether the object has already been
//     initialized.  You may wish to cache the result of get(); it will not
//     change.
//
// (b) Your factory function must never throw an exception. This class is not
//     exception-safe.
//
template <typename Type,
          typename Traits = DefaultSingletonTraits<Type>,
          typename DifferentiatingType = Type>
class Singleton {
 private:
  // Classes using the Singleton<T> pattern should declare a GetInstance()
  // method and call Singleton::get() from within that.
  friend Type* Type::GetInstance();

  // Allow TraceLog tests to test tracing after OnExit.
  friend class DeleteTraceLogForTesting;

  // This class is safe to be constructed and copy-constructed since it has no
  // member.

  // Return a pointer to the one true instance of the class.
  static Type* get() {
#ifndef NDEBUG
    // Avoid making TLS lookup on release builds.
    if (!Traits::kAllowedToAccessOnNonjoinableThread)
      base::ThreadRestrictions::AssertSingletonAllowed();
#endif

    // The load has acquire memory ordering as the thread which reads the
    // instance_ pointer must acquire visibility over the singleton data.
    base::subtle::AtomicWord value = base::subtle::Acquire_Load(&instance_);
    if (value != 0 && value != base::internal::kBeingCreatedMarker) {
      return reinterpret_cast<Type*>(value);
    }

    // Object isn't created yet, maybe we will get to create it, let's try...
    if (base::subtle::Acquire_CompareAndSwap(
          &instance_, 0, base::internal::kBeingCreatedMarker) == 0) {
      // instance_ was NULL and is now kBeingCreatedMarker.  Only one thread
      // will ever get here.  Threads might be spinning on us, and they will
      // stop right after we do this store.
      Type* newval = Traits::New();

      // Releases the visibility over instance_ to the readers.
      base::subtle::Release_Store(
          &instance_, reinterpret_cast<base::subtle::AtomicWord>(newval));

      if (newval != NULL && Traits::kRegisterAtExit)
        base::AtExitManager::RegisterCallback(OnExit, NULL);

      return newval;
    }

    // We hit a race. Wait for the other thread to complete it.
    value = base::internal::WaitForInstance(&instance_);

    return reinterpret_cast<Type*>(value);
  }

  // Adapter function for use with AtExit().  This should be called single
  // threaded, so don't use atomic operations.
  // Calling OnExit while singleton is in use by other threads is a mistake.
  static void OnExit(void* /*unused*/) {
    // AtExit should only ever be register after the singleton instance was
    // created.  We should only ever get here with a valid instance_ pointer.
    Traits::Delete(
        reinterpret_cast<Type*>(base::subtle::NoBarrier_Load(&instance_)));
    instance_ = 0;
  }
  static base::subtle::AtomicWord instance_;
};

template <typename Type, typename Traits, typename DifferentiatingType>
base::subtle::AtomicWord Singleton<Type, Traits, DifferentiatingType>::
    instance_ = 0;

#endif  // BASE_MEMORY_SINGLETON_H_
