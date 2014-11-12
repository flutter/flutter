 /*
 * Copyright (C) 2006, 2007, 2008 Apple Inc. All rights reserved.
 * Copyright (C) 2009, 2010 Google Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 */

#ifndef TypeTraits_h
#define TypeTraits_h

#include <utility>

namespace WTF {

    // The following are provided in this file:
    //
    //   IsInteger<T>::value
    //   IsPod<T>::value, see the definition for a note about its limitations
    //   IsConvertibleToInteger<T>::value
    //
    //   IsArray<T>::value
    //
    //   IsSameType<T, U>::value
    //
    //   RemovePointer<T>::Type
    //   RemoveReference<T>::Type
    //   RemoveConst<T>::Type
    //   RemoveVolatile<T>::Type
    //   RemoveConstVolatile<T>::Type
    //   RemoveExtent<T>::Type
    //
    //   COMPILE_ASSERT's in TypeTraits.cpp illustrate their usage and what they do.

    template<bool Predicate, class T = void> struct EnableIf;
    template<class T> struct EnableIf<true, T> { typedef T Type; };

    template<typename T> struct IsInteger           { static const bool value = false; };
    template<> struct IsInteger<bool>               { static const bool value = true; };
    template<> struct IsInteger<char>               { static const bool value = true; };
    template<> struct IsInteger<signed char>        { static const bool value = true; };
    template<> struct IsInteger<unsigned char>      { static const bool value = true; };
    template<> struct IsInteger<short>              { static const bool value = true; };
    template<> struct IsInteger<unsigned short>     { static const bool value = true; };
    template<> struct IsInteger<int>                { static const bool value = true; };
    template<> struct IsInteger<unsigned int>       { static const bool value = true; };
    template<> struct IsInteger<long>               { static const bool value = true; };
    template<> struct IsInteger<unsigned long>      { static const bool value = true; };
    template<> struct IsInteger<long long>          { static const bool value = true; };
    template<> struct IsInteger<unsigned long long> { static const bool value = true; };
#if !COMPILER(MSVC) || defined(_NATIVE_WCHAR_T_DEFINED)
    template<> struct IsInteger<wchar_t>            { static const bool value = true; };
#endif

    template<typename T> struct IsFloatingPoint     { static const bool value = false; };
    template<> struct IsFloatingPoint<float>        { static const bool value = true; };
    template<> struct IsFloatingPoint<double>       { static const bool value = true; };
    template<> struct IsFloatingPoint<long double>  { static const bool value = true; };

    template<typename T> struct IsArithmetic        { static const bool value = IsInteger<T>::value || IsFloatingPoint<T>::value; };

    template<typename T> struct IsWeak              { static const bool value = false; };

    enum WeakHandlingFlag {
        NoWeakHandlingInCollections,
        WeakHandlingInCollections
    };

    // IsPod is misnamed as it doesn't cover all plain old data (pod) types.
    // Specifically, it doesn't allow for enums or for structs.
    template <typename T> struct IsPod              { static const bool value = IsArithmetic<T>::value; };
    template <typename P> struct IsPod<P*>          { static const bool value = true; };

    template<typename T> class IsConvertibleToInteger {
        // Avoid "possible loss of data" warning when using Microsoft's C++ compiler
        // by not converting int's to doubles.
        template<bool performCheck, typename U> class IsConvertibleToDouble;
        template<typename U> class IsConvertibleToDouble<false, U> {
        public:
            static const bool value = false;
        };

        template<typename U> class IsConvertibleToDouble<true, U> {
            typedef char YesType;
            struct NoType {
                char padding[8];
            };

            static YesType floatCheck(long double);
            static NoType floatCheck(...);
            static T& t;
        public:
            static const bool value = sizeof(floatCheck(t)) == sizeof(YesType);
        };

    public:
        static const bool value = IsInteger<T>::value || IsConvertibleToDouble<!IsInteger<T>::value, T>::value;
    };

    template<typename From, typename To> class IsPointerConvertible {
        typedef char YesType;
        struct NoType {
            char padding[8];
        };

        static YesType convertCheck(To* x);
        static NoType convertCheck(...);
    public:
        enum {
            Value = (sizeof(YesType) == sizeof(convertCheck(static_cast<From*>(0))))
        };
    };

    template <class T> struct IsArray {
        static const bool value = false;
    };

    template <class T> struct IsArray<T[]> {
        static const bool value = true;
    };

    template <class T, size_t N> struct IsArray<T[N]> {
        static const bool value = true;
    };


    template <typename T, typename U> struct IsSameType {
        static const bool value = false;
    };

    template <typename T> struct IsSameType<T, T> {
        static const bool value = true;
    };

    template <typename T, typename U> class IsSubclass {
        typedef char YesType;
        struct NoType {
            char padding[8];
        };

        static YesType subclassCheck(U*);
        static NoType subclassCheck(...);
        static T* t;
    public:
        static const bool value = sizeof(subclassCheck(t)) == sizeof(YesType);
    };

    template <typename T, template<class V> class U> class IsSubclassOfTemplate {
        typedef char YesType;
        struct NoType {
            char padding[8];
        };

        template<typename W> static YesType subclassCheck(U<W>*);
        static NoType subclassCheck(...);
        static T* t;
    public:
        static const bool value = sizeof(subclassCheck(t)) == sizeof(YesType);
    };

    template <typename T, template<typename V, size_t W> class U> class IsSubclassOfTemplateTypenameSize {
        typedef char YesType;
        struct NoType {
            char padding[8];
        };

        template<typename X, size_t Y> static YesType subclassCheck(U<X, Y>*);
        static NoType subclassCheck(...);
        static T* t;
    public:
        static const bool value = sizeof(subclassCheck(t)) == sizeof(YesType);
    };

    template <typename T, template<typename V, size_t W, typename X> class U> class IsSubclassOfTemplateTypenameSizeTypename {
        typedef char YesType;
        struct NoType {
            char padding[8];
        };

        template<typename Y, size_t Z, typename A> static YesType subclassCheck(U<Y, Z, A>*);
        static NoType subclassCheck(...);
        static T* t;
    public:
        static const bool value = sizeof(subclassCheck(t)) == sizeof(YesType);
    };

    template <typename T, template<class A, class B, class C> class U> class IsSubclassOfTemplate3 {
        typedef char YesType;
        struct NoType {
            char padding[8];
        };

        template<typename D, typename E, typename F> static YesType subclassCheck(U<D, E, F>*);
        static NoType subclassCheck(...);
        static T* t;
    public:
        static const bool value = sizeof(subclassCheck(t)) == sizeof(YesType);
    };

    template <typename T, template<class A, class B, class C, class D, class E> class U> class IsSubclassOfTemplate5 {
        typedef char YesType;
        struct NoType {
            char padding[8];
        };

        template<typename F, typename G, typename H, typename I, typename J> static YesType subclassCheck(U<F, G, H, I, J>*);
        static NoType subclassCheck(...);
        static T* t;
    public:
        static const bool value = sizeof(subclassCheck(t)) == sizeof(YesType);
    };

    template <typename T, template <class V> class OuterTemplate> struct RemoveTemplate {
        typedef T Type;
    };

    template <typename T, template <class V> class OuterTemplate> struct RemoveTemplate<OuterTemplate<T>, OuterTemplate> {
        typedef T Type;
    };

    template <typename T> struct RemoveConst {
        typedef T Type;
    };

    template <typename T> struct RemoveConst<const T> {
        typedef T Type;
    };

    template <typename T> struct RemoveVolatile {
        typedef T Type;
    };

    template <typename T> struct RemoveVolatile<volatile T> {
        typedef T Type;
    };

    template <typename T> struct RemoveConstVolatile {
        typedef typename RemoveVolatile<typename RemoveConst<T>::Type>::Type Type;
    };

    template <typename T> struct RemovePointer {
        typedef T Type;
    };

    template <typename T> struct RemovePointer<T*> {
        typedef T Type;
    };

    template <typename T> struct RemoveReference {
        typedef T Type;
    };

    template <typename T> struct RemoveReference<T&> {
        typedef T Type;
    };

    template <typename T> struct RemoveExtent {
        typedef T Type;
    };

    template <typename T> struct RemoveExtent<T[]> {
        typedef T Type;
    };

    template <typename T, size_t N> struct RemoveExtent<T[N]> {
        typedef T Type;
    };

    // Determines whether this type has a vtable.
    template <typename T> struct IsPolymorphic {
        static const bool value = __is_polymorphic(T);
    };

#define EnsurePtrConvertibleArgDecl(From, To) \
    typename WTF::EnableIf<WTF::IsPointerConvertible<From, To>::Value, bool>::Type = true
#define EnsurePtrConvertibleArgDefn(From, To) \
    typename WTF::EnableIf<WTF::IsPointerConvertible<From, To>::Value, bool>::Type

} // namespace WTF

namespace blink {

class JSONValue;

} // namespace blink

namespace WTF {

    // FIXME: Disable pointer conversion checking against JSONValue.
    // The current CodeGeneratorInspector.py generates code which upcasts to JSONValue from undefined types.
    template<typename From> class IsPointerConvertible<From, blink::JSONValue> {
    public:
        enum {
            Value = true
        };
    };

template<typename T>
class NeedsTracing {
    typedef char YesType;
    typedef struct NoType {
        char padding[8];
    } NoType;
#if COMPILER(MSVC)
    template<typename V> static YesType checkHasTraceMethod(char[&V::trace != 0]);
#else
    template<size_t> struct HasMethod;
    template<typename V> static YesType checkHasTraceMethod(HasMethod<sizeof(&V::trace)>*);
#endif // COMPILER(MSVC)
    template<typename V> static NoType checkHasTraceMethod(...);
public:
    // We add sizeof(T) to both sides here, because we want it to fail for
    // incomplete types. Otherwise it just assumes that incomplete types do not
    // have a trace method, which may not be true.
    static const bool value = sizeof(YesType) + sizeof(T) == sizeof(checkHasTraceMethod<T>(0)) + sizeof(T);
};

// Convenience template wrapping the NeedsTracingLazily template in
// Collection Traits. It helps make the code more readable.
template<typename Traits>
class ShouldBeTraced {
public:
    static const bool value = Traits::template NeedsTracingLazily<>::value;
};

template<typename T, typename U>
struct NeedsTracing<std::pair<T, U> > {
    static const bool value = NeedsTracing<T>::value || NeedsTracing<U>::value || IsWeak<T>::value || IsWeak<U>::value;
};

} // namespace WTF

#endif // TypeTraits_h
