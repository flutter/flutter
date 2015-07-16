// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_CALLBACK_H_
#define BASE_CALLBACK_H_

#include "base/callback_forward.h"
#include "base/callback_internal.h"
#include "base/template_util.h"

// NOTE: Header files that do not require the full definition of Callback or
// Closure should #include "base/callback_forward.h" instead of this file.

// -----------------------------------------------------------------------------
// Introduction
// -----------------------------------------------------------------------------
//
// The templated Callback class is a generalized function object. Together
// with the Bind() function in bind.h, they provide a type-safe method for
// performing partial application of functions.
//
// Partial application (or "currying") is the process of binding a subset of
// a function's arguments to produce another function that takes fewer
// arguments. This can be used to pass around a unit of delayed execution,
// much like lexical closures are used in other languages. For example, it
// is used in Chromium code to schedule tasks on different MessageLoops.
//
// A callback with no unbound input parameters (base::Callback<void(void)>)
// is called a base::Closure. Note that this is NOT the same as what other
// languages refer to as a closure -- it does not retain a reference to its
// enclosing environment.
//
// MEMORY MANAGEMENT AND PASSING
//
// The Callback objects themselves should be passed by const-reference, and
// stored by copy. They internally store their state via a refcounted class
// and thus do not need to be deleted.
//
// The reason to pass via a const-reference is to avoid unnecessary
// AddRef/Release pairs to the internal state.
//
//
// -----------------------------------------------------------------------------
// Quick reference for basic stuff
// -----------------------------------------------------------------------------
//
// BINDING A BARE FUNCTION
//
//   int Return5() { return 5; }
//   base::Callback<int(void)> func_cb = base::Bind(&Return5);
//   LOG(INFO) << func_cb.Run();  // Prints 5.
//
// BINDING A CLASS METHOD
//
//   The first argument to bind is the member function to call, the second is
//   the object on which to call it.
//
//   class Ref : public base::RefCountedThreadSafe<Ref> {
//    public:
//     int Foo() { return 3; }
//     void PrintBye() { LOG(INFO) << "bye."; }
//   };
//   scoped_refptr<Ref> ref = new Ref();
//   base::Callback<void(void)> ref_cb = base::Bind(&Ref::Foo, ref);
//   LOG(INFO) << ref_cb.Run();  // Prints out 3.
//
//   By default the object must support RefCounted or you will get a compiler
//   error. If you're passing between threads, be sure it's
//   RefCountedThreadSafe! See "Advanced binding of member functions" below if
//   you don't want to use reference counting.
//
// RUNNING A CALLBACK
//
//   Callbacks can be run with their "Run" method, which has the same
//   signature as the template argument to the callback.
//
//   void DoSomething(const base::Callback<void(int, std::string)>& callback) {
//     callback.Run(5, "hello");
//   }
//
//   Callbacks can be run more than once (they don't get deleted or marked when
//   run). However, this precludes using base::Passed (see below).
//
//   void DoSomething(const base::Callback<double(double)>& callback) {
//     double myresult = callback.Run(3.14159);
//     myresult += callback.Run(2.71828);
//   }
//
// PASSING UNBOUND INPUT PARAMETERS
//
//   Unbound parameters are specified at the time a callback is Run(). They are
//   specified in the Callback template type:
//
//   void MyFunc(int i, const std::string& str) {}
//   base::Callback<void(int, const std::string&)> cb = base::Bind(&MyFunc);
//   cb.Run(23, "hello, world");
//
// PASSING BOUND INPUT PARAMETERS
//
//   Bound parameters are specified when you create thee callback as arguments
//   to Bind(). They will be passed to the function and the Run()ner of the
//   callback doesn't see those values or even know that the function it's
//   calling.
//
//   void MyFunc(int i, const std::string& str) {}
//   base::Callback<void(void)> cb = base::Bind(&MyFunc, 23, "hello world");
//   cb.Run();
//
//   A callback with no unbound input parameters (base::Callback<void(void)>)
//   is called a base::Closure. So we could have also written:
//
//   base::Closure cb = base::Bind(&MyFunc, 23, "hello world");
//
//   When calling member functions, bound parameters just go after the object
//   pointer.
//
//   base::Closure cb = base::Bind(&MyClass::MyFunc, this, 23, "hello world");
//
// PARTIAL BINDING OF PARAMETERS
//
//   You can specify some parameters when you create the callback, and specify
//   the rest when you execute the callback.
//
//   void MyFunc(int i, const std::string& str) {}
//   base::Callback<void(const std::string&)> cb = base::Bind(&MyFunc, 23);
//   cb.Run("hello world");
//
//   When calling a function bound parameters are first, followed by unbound
//   parameters.
//
//
// -----------------------------------------------------------------------------
// Quick reference for advanced binding
// -----------------------------------------------------------------------------
//
// BINDING A CLASS METHOD WITH WEAK POINTERS
//
//   base::Bind(&MyClass::Foo, GetWeakPtr());
//
//   The callback will not be run if the object has already been destroyed.
//   DANGER: weak pointers are not threadsafe, so don't use this
//   when passing between threads!
//
// BINDING A CLASS METHOD WITH MANUAL LIFETIME MANAGEMENT
//
//   base::Bind(&MyClass::Foo, base::Unretained(this));
//
//   This disables all lifetime management on the object. You're responsible
//   for making sure the object is alive at the time of the call. You break it,
//   you own it!
//
// BINDING A CLASS METHOD AND HAVING THE CALLBACK OWN THE CLASS
//
//   MyClass* myclass = new MyClass;
//   base::Bind(&MyClass::Foo, base::Owned(myclass));
//
//   The object will be deleted when the callback is destroyed, even if it's
//   not run (like if you post a task during shutdown). Potentially useful for
//   "fire and forget" cases.
//
// IGNORING RETURN VALUES
//
//   Sometimes you want to call a function that returns a value in a callback
//   that doesn't expect a return value.
//
//   int DoSomething(int arg) { cout << arg << endl; }
//   base::Callback<void<int>) cb =
//       base::Bind(base::IgnoreResult(&DoSomething));
//
//
// -----------------------------------------------------------------------------
// Quick reference for binding parameters to Bind()
// -----------------------------------------------------------------------------
//
// Bound parameters are specified as arguments to Bind() and are passed to the
// function. A callback with no parameters or no unbound parameters is called a
// Closure (base::Callback<void(void)> and base::Closure are the same thing).
//
// PASSING PARAMETERS OWNED BY THE CALLBACK
//
//   void Foo(int* arg) { cout << *arg << endl; }
//   int* pn = new int(1);
//   base::Closure foo_callback = base::Bind(&foo, base::Owned(pn));
//
//   The parameter will be deleted when the callback is destroyed, even if it's
//   not run (like if you post a task during shutdown).
//
// PASSING PARAMETERS AS A scoped_ptr
//
//   void TakesOwnership(scoped_ptr<Foo> arg) {}
//   scoped_ptr<Foo> f(new Foo);
//   // f becomes null during the following call.
//   base::Closure cb = base::Bind(&TakesOwnership, base::Passed(&f));
//
//   Ownership of the parameter will be with the callback until the it is run,
//   when ownership is passed to the callback function. This means the callback
//   can only be run once. If the callback is never run, it will delete the
//   object when it's destroyed.
//
// PASSING PARAMETERS AS A scoped_refptr
//
//   void TakesOneRef(scoped_refptr<Foo> arg) {}
//   scoped_refptr<Foo> f(new Foo)
//   base::Closure cb = base::Bind(&TakesOneRef, f);
//
//   This should "just work." The closure will take a reference as long as it
//   is alive, and another reference will be taken for the called function.
//
// PASSING PARAMETERS BY REFERENCE
//
//   Const references are *copied* unless ConstRef is used. Example:
//
//   void foo(const int& arg) { printf("%d %p\n", arg, &arg); }
//   int n = 1;
//   base::Closure has_copy = base::Bind(&foo, n);
//   base::Closure has_ref = base::Bind(&foo, base::ConstRef(n));
//   n = 2;
//   foo(n);                        // Prints "2 0xaaaaaaaaaaaa"
//   has_copy.Run();                // Prints "1 0xbbbbbbbbbbbb"
//   has_ref.Run();                 // Prints "2 0xaaaaaaaaaaaa"
//
//   Normally parameters are copied in the closure. DANGER: ConstRef stores a
//   const reference instead, referencing the original parameter. This means
//   that you must ensure the object outlives the callback!
//
//
// -----------------------------------------------------------------------------
// Implementation notes
// -----------------------------------------------------------------------------
//
// WHERE IS THIS DESIGN FROM:
//
// The design Callback and Bind is heavily influenced by C++'s
// tr1::function/tr1::bind, and by the "Google Callback" system used inside
// Google.
//
//
// HOW THE IMPLEMENTATION WORKS:
//
// There are three main components to the system:
//   1) The Callback classes.
//   2) The Bind() functions.
//   3) The arguments wrappers (e.g., Unretained() and ConstRef()).
//
// The Callback classes represent a generic function pointer. Internally,
// it stores a refcounted piece of state that represents the target function
// and all its bound parameters.  Each Callback specialization has a templated
// constructor that takes an BindState<>*.  In the context of the constructor,
// the static type of this BindState<> pointer uniquely identifies the
// function it is representing, all its bound parameters, and a Run() method
// that is capable of invoking the target.
//
// Callback's constructor takes the BindState<>* that has the full static type
// and erases the target function type as well as the types of the bound
// parameters.  It does this by storing a pointer to the specific Run()
// function, and upcasting the state of BindState<>* to a
// BindStateBase*. This is safe as long as this BindStateBase pointer
// is only used with the stored Run() pointer.
//
// To BindState<> objects are created inside the Bind() functions.
// These functions, along with a set of internal templates, are responsible for
//
//  - Unwrapping the function signature into return type, and parameters
//  - Determining the number of parameters that are bound
//  - Creating the BindState storing the bound parameters
//  - Performing compile-time asserts to avoid error-prone behavior
//  - Returning an Callback<> with an arity matching the number of unbound
//    parameters and that knows the correct refcounting semantics for the
//    target object if we are binding a method.
//
// The Bind functions do the above using type-inference, and template
// specializations.
//
// By default Bind() will store copies of all bound parameters, and attempt
// to refcount a target object if the function being bound is a class method.
// These copies are created even if the function takes parameters as const
// references. (Binding to non-const references is forbidden, see bind.h.)
//
// To change this behavior, we introduce a set of argument wrappers
// (e.g., Unretained(), and ConstRef()).  These are simple container templates
// that are passed by value, and wrap a pointer to argument.  See the
// file-level comment in base/bind_helpers.h for more info.
//
// These types are passed to the Unwrap() functions, and the MaybeRefcount()
// functions respectively to modify the behavior of Bind().  The Unwrap()
// and MaybeRefcount() functions change behavior by doing partial
// specialization based on whether or not a parameter is a wrapper type.
//
// ConstRef() is similar to tr1::cref.  Unretained() is specific to Chromium.
//
//
// WHY NOT TR1 FUNCTION/BIND?
//
// Direct use of tr1::function and tr1::bind was considered, but ultimately
// rejected because of the number of copy constructors invocations involved
// in the binding of arguments during construction, and the forwarding of
// arguments during invocation.  These copies will no longer be an issue in
// C++0x because C++0x will support rvalue reference allowing for the compiler
// to avoid these copies.  However, waiting for C++0x is not an option.
//
// Measured with valgrind on gcc version 4.4.3 (Ubuntu 4.4.3-4ubuntu5), the
// tr1::bind call itself will invoke a non-trivial copy constructor three times
// for each bound parameter.  Also, each when passing a tr1::function, each
// bound argument will be copied again.
//
// In addition to the copies taken at binding and invocation, copying a
// tr1::function causes a copy to be made of all the bound parameters and
// state.
//
// Furthermore, in Chromium, it is desirable for the Callback to take a
// reference on a target object when representing a class method call.  This
// is not supported by tr1.
//
// Lastly, tr1::function and tr1::bind has a more general and flexible API.
// This includes things like argument reordering by use of
// tr1::bind::placeholder, support for non-const reference parameters, and some
// limited amount of subtyping of the tr1::function object (e.g.,
// tr1::function<int(int)> is convertible to tr1::function<void(int)>).
//
// These are not features that are required in Chromium. Some of them, such as
// allowing for reference parameters, and subtyping of functions, may actually
// become a source of errors. Removing support for these features actually
// allows for a simpler implementation, and a terser Currying API.
//
//
// WHY NOT GOOGLE CALLBACKS?
//
// The Google callback system also does not support refcounting.  Furthermore,
// its implementation has a number of strange edge cases with respect to type
// conversion of its arguments.  In particular, the argument's constness must
// at times match exactly the function signature, or the type-inference might
// break.  Given the above, writing a custom solution was easier.
//
//
// MISSING FUNCTIONALITY
//  - Invoking the return of Bind.  Bind(&foo).Run() does not work;
//  - Binding arrays to functions that take a non-const pointer.
//    Example:
//      void Foo(const char* ptr);
//      void Bar(char* ptr);
//      Bind(&Foo, "test");
//      Bind(&Bar, "test");  // This fails because ptr is not const.

namespace base {

// First, we forward declare the Callback class template. This informs the
// compiler that the template only has 1 type parameter which is the function
// signature that the Callback is representing.
//
// After this, create template specializations for 0-7 parameters. Note that
// even though the template typelist grows, the specialization still
// only has one type: the function signature.
//
// If you are thinking of forward declaring Callback in your own header file,
// please include "base/callback_forward.h" instead.
template <typename Sig>
class Callback;

namespace internal {
template <typename Runnable, typename RunType, typename BoundArgsType>
struct BindState;
}  // namespace internal

template <typename R, typename... Args>
class Callback<R(Args...)> : public internal::CallbackBase {
 public:
  typedef R(RunType)(Args...);

  Callback() : CallbackBase(NULL) { }

  // Note that this constructor CANNOT be explicit, and that Bind() CANNOT
  // return the exact Callback<> type.  See base/bind.h for details.
  template <typename Runnable, typename BindRunType, typename BoundArgsType>
  Callback(internal::BindState<Runnable, BindRunType,
           BoundArgsType>* bind_state)
      : CallbackBase(bind_state) {
    // Force the assignment to a local variable of PolymorphicInvoke
    // so the compiler will typecheck that the passed in Run() method has
    // the correct type.
    PolymorphicInvoke invoke_func =
        &internal::BindState<Runnable, BindRunType, BoundArgsType>
            ::InvokerType::Run;
    polymorphic_invoke_ = reinterpret_cast<InvokeFuncStorage>(invoke_func);
  }

  bool Equals(const Callback& other) const {
    return CallbackBase::Equals(other);
  }

  R Run(typename internal::CallbackParamTraits<Args>::ForwardType... args)
      const {
    PolymorphicInvoke f =
        reinterpret_cast<PolymorphicInvoke>(polymorphic_invoke_);

    return f(bind_state_.get(), internal::CallbackForward(args)...);
  }

 private:
  typedef R(*PolymorphicInvoke)(
      internal::BindStateBase*,
      typename internal::CallbackParamTraits<Args>::ForwardType...);
};

// Syntactic sugar to make Callback<void(void)> easier to declare since it
// will be used in a lot of APIs with delayed execution.
typedef Callback<void(void)> Closure;

}  // namespace base

#endif  // BASE_CALLBACK_H_
