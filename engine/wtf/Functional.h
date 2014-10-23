/*
 * Copyright (C) 2011 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef WTF_Functional_h
#define WTF_Functional_h

#include "wtf/Assertions.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefPtr.h"
#include "wtf/ThreadSafeRefCounted.h"
#include "wtf/WeakPtr.h"

namespace WTF {

// Functional.h provides a very simple way to bind a function pointer and arguments together into a function object
// that can be stored, copied and invoked, similar to how boost::bind and std::bind in C++11.

// A FunctionWrapper is a class template that can wrap a function pointer or a member function pointer and
// provide a unified interface for calling that function.
template<typename>
class FunctionWrapper;

// Bound static functions:

template<typename R>
class FunctionWrapper<R(*)()> {
public:
    typedef R ResultType;

    explicit FunctionWrapper(R(*function)())
        : m_function(function)
    {
    }

    R operator()()
    {
        return m_function();
    }

private:
    R(*m_function)();
};

template<typename R, typename P1>
class FunctionWrapper<R(*)(P1)> {
public:
    typedef R ResultType;

    explicit FunctionWrapper(R(*function)(P1))
        : m_function(function)
    {
    }

    R operator()(P1 p1)
    {
        return m_function(p1);
    }

private:
    R(*m_function)(P1);
};

template<typename R, typename P1, typename P2>
class FunctionWrapper<R(*)(P1, P2)> {
public:
    typedef R ResultType;

    explicit FunctionWrapper(R(*function)(P1, P2))
        : m_function(function)
    {
    }

    R operator()(P1 p1, P2 p2)
    {
        return m_function(p1, p2);
    }

private:
    R(*m_function)(P1, P2);
};

template<typename R, typename P1, typename P2, typename P3>
class FunctionWrapper<R(*)(P1, P2, P3)> {
public:
    typedef R ResultType;

    explicit FunctionWrapper(R(*function)(P1, P2, P3))
        : m_function(function)
    {
    }

    R operator()(P1 p1, P2 p2, P3 p3)
    {
        return m_function(p1, p2, p3);
    }

private:
    R(*m_function)(P1, P2, P3);
};

template<typename R, typename P1, typename P2, typename P3, typename P4>
class FunctionWrapper<R(*)(P1, P2, P3, P4)> {
public:
    typedef R ResultType;

    explicit FunctionWrapper(R(*function)(P1, P2, P3, P4))
        : m_function(function)
    {
    }

    R operator()(P1 p1, P2 p2, P3 p3, P4 p4)
    {
        return m_function(p1, p2, p3, p4);
    }

private:
    R(*m_function)(P1, P2, P3, P4);
};

template<typename R, typename P1, typename P2, typename P3, typename P4, typename P5>
class FunctionWrapper<R(*)(P1, P2, P3, P4, P5)> {
public:
    typedef R ResultType;

    explicit FunctionWrapper(R(*function)(P1, P2, P3, P4, P5))
        : m_function(function)
    {
    }

    R operator()(P1 p1, P2 p2, P3 p3, P4 p4, P5 p5)
    {
        return m_function(p1, p2, p3, p4, p5);
    }

private:
    R(*m_function)(P1, P2, P3, P4, P5);
};

template<typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename P6>
class FunctionWrapper<R(*)(P1, P2, P3, P4, P5, P6)> {
public:
    typedef R ResultType;

    explicit FunctionWrapper(R(*function)(P1, P2, P3, P4, P5, P6))
        : m_function(function)
    {
    }

    R operator()(P1 p1, P2 p2, P3 p3, P4 p4, P5 p5, P6 p6)
    {
        return m_function(p1, p2, p3, p4, p5, p6);
    }

private:
    R(*m_function)(P1, P2, P3, P4, P5, P6);
};

// Bound member functions:

template<typename R, typename C>
class FunctionWrapper<R(C::*)()> {
public:
    typedef R ResultType;

    explicit FunctionWrapper(R(C::*function)())
        : m_function(function)
    {
    }

    R operator()(C* c)
    {
        return (c->*m_function)();
    }

    R operator()(const WeakPtr<C>& c)
    {
        C* obj = c.get();
        if (!obj)
            return R();
        return (obj->*m_function)();
    }

private:
    R(C::*m_function)();
};

template<typename R, typename C, typename P1>
class FunctionWrapper<R(C::*)(P1)> {
public:
    typedef R ResultType;

    explicit FunctionWrapper(R(C::*function)(P1))
        : m_function(function)
    {
    }

    R operator()(C* c, P1 p1)
    {
        return (c->*m_function)(p1);
    }

    R operator()(const WeakPtr<C>& c, P1 p1)
    {
        C* obj = c.get();
        if (!obj)
            return R();
        return (obj->*m_function)(p1);
    }

private:
    R(C::*m_function)(P1);
};

template<typename R, typename C, typename P1, typename P2>
class FunctionWrapper<R(C::*)(P1, P2)> {
public:
    typedef R ResultType;

    explicit FunctionWrapper(R(C::*function)(P1, P2))
        : m_function(function)
    {
    }

    R operator()(C* c, P1 p1, P2 p2)
    {
        return (c->*m_function)(p1, p2);
    }

    R operator()(const WeakPtr<C>& c, P1 p1, P2 p2)
    {
        C* obj = c.get();
        if (!obj)
            return R();
        return (obj->*m_function)(p1, p2);
    }

private:
    R(C::*m_function)(P1, P2);
};

template<typename R, typename C, typename P1, typename P2, typename P3>
class FunctionWrapper<R(C::*)(P1, P2, P3)> {
public:
    typedef R ResultType;

    explicit FunctionWrapper(R(C::*function)(P1, P2, P3))
        : m_function(function)
    {
    }

    R operator()(C* c, P1 p1, P2 p2, P3 p3)
    {
        return (c->*m_function)(p1, p2, p3);
    }

    R operator()(const WeakPtr<C>& c, P1 p1, P2 p2, P3 p3)
    {
        C* obj = c.get();
        if (!obj)
            return R();
        return (obj->*m_function)(p1, p2, p3);
    }

private:
    R(C::*m_function)(P1, P2, P3);
};

template<typename R, typename C, typename P1, typename P2, typename P3, typename P4>
class FunctionWrapper<R(C::*)(P1, P2, P3, P4)> {
public:
    typedef R ResultType;

    explicit FunctionWrapper(R(C::*function)(P1, P2, P3, P4))
        : m_function(function)
    {
    }

    R operator()(C* c, P1 p1, P2 p2, P3 p3, P4 p4)
    {
        return (c->*m_function)(p1, p2, p3, p4);
    }

    R operator()(const WeakPtr<C>& c, P1 p1, P2 p2, P3 p3, P4 p4)
    {
        C* obj = c.get();
        if (!obj)
            return R();
        return (obj->*m_function)(p1, p2, p3, p4);
    }

private:
    R(C::*m_function)(P1, P2, P3, P4);
};

template<typename R, typename C, typename P1, typename P2, typename P3, typename P4, typename P5>
class FunctionWrapper<R(C::*)(P1, P2, P3, P4, P5)> {
public:
    typedef R ResultType;

    explicit FunctionWrapper(R(C::*function)(P1, P2, P3, P4, P5))
        : m_function(function)
    {
    }

    R operator()(C* c, P1 p1, P2 p2, P3 p3, P4 p4, P5 p5)
    {
        return (c->*m_function)(p1, p2, p3, p4, p5);
    }

    R operator()(const WeakPtr<C>& c, P1 p1, P2 p2, P3 p3, P4 p4, P5 p5)
    {
        C* obj = c.get();
        if (!obj)
            return R();
        return (obj->*m_function)(p1, p2, p3, p4, p5);
    }

private:
    R(C::*m_function)(P1, P2, P3, P4, P5);
};

template<typename T> struct ParamStorageTraits {
    typedef T StorageType;

    static StorageType wrap(const T& value) { return value; }
    static const T& unwrap(const StorageType& value) { return value; }
};

template<typename T> struct ParamStorageTraits<PassRefPtr<T> > {
    typedef RefPtr<T> StorageType;

    static StorageType wrap(PassRefPtr<T> value) { return value; }
    static T* unwrap(const StorageType& value) { return value.get(); }
};

template<typename T> struct ParamStorageTraits<RefPtr<T> > {
    typedef RefPtr<T> StorageType;

    static StorageType wrap(RefPtr<T> value) { return value.release(); }
    static T* unwrap(const StorageType& value) { return value.get(); }
};

template<typename> class RetainPtr;

template<typename T> struct ParamStorageTraits<RetainPtr<T> > {
    typedef RetainPtr<T> StorageType;

    static StorageType wrap(const RetainPtr<T>& value) { return value; }
    static typename RetainPtr<T>::PtrType unwrap(const StorageType& value) { return value.get(); }
};

class FunctionImplBase : public ThreadSafeRefCounted<FunctionImplBase> {
public:
    virtual ~FunctionImplBase() { }
};

template<typename>
class FunctionImpl;

template<typename R>
class FunctionImpl<R()> : public FunctionImplBase {
public:
    virtual R operator()() = 0;
};

template<typename R, typename A1>
class FunctionImpl<R(A1)> : public FunctionImplBase {
public:
    virtual R operator()(A1 a1) = 0;
};

template<typename R, typename A1, typename A2>
class FunctionImpl<R(A1, A2)> : public FunctionImplBase {
public:
    virtual R operator()(A1 a1, A2 a2) = 0;
};

template<typename R, typename A1, typename A2, typename A3>
class FunctionImpl<R(A1, A2, A3)> : public FunctionImplBase {
public:
    virtual R operator()(A1 a1, A2 a2, A3 a3) = 0;
};

template<typename R, typename A1, typename A2, typename A3, typename A4>
class FunctionImpl<R(A1, A2, A3, A4)> : public FunctionImplBase {
public:
    virtual R operator()(A1 a1, A2 a2, A3 a3, A4 a4) = 0;
};

template<typename R, typename A1, typename A2, typename A3, typename A4, typename A5>
class FunctionImpl<R(A1, A2, A3, A4, A5)> : public FunctionImplBase {
public:
    virtual R operator()(A1 a1, A2 a2, A3 a3, A4 a4, A5 a5) = 0;
};

template<typename R, typename A1, typename A2, typename A3, typename A4, typename A5, typename A6>
class FunctionImpl<R(A1, A2, A3, A4, A5, A6)> : public FunctionImplBase {
public:
    virtual R operator()(A1 a1, A2 a2, A3 a3, A4 a4, A5 a5, A6 a6) = 0;
};

template<typename FunctionWrapper, typename FunctionType>
class UnboundFunctionImpl;

template<typename FunctionWrapper, typename R, typename P1>
class UnboundFunctionImpl<FunctionWrapper, R(P1)> FINAL : public FunctionImpl<typename FunctionWrapper::ResultType(P1)> {
public:
    UnboundFunctionImpl(FunctionWrapper functionWrapper)
        : m_functionWrapper(functionWrapper)
    {
    }

    virtual typename FunctionWrapper::ResultType operator()(P1 p1) OVERRIDE
    {
        return m_functionWrapper(p1);
    }

private:
    FunctionWrapper m_functionWrapper;
};

template<typename FunctionWrapper, typename R, typename P1, typename P2>
class UnboundFunctionImpl<FunctionWrapper, R(P1, P2)> FINAL : public FunctionImpl<typename FunctionWrapper::ResultType(P1, P2)> {
public:
    UnboundFunctionImpl(FunctionWrapper functionWrapper)
        : m_functionWrapper(functionWrapper)
    {
    }

    virtual typename FunctionWrapper::ResultType operator()(P1 p1, P2 p2) OVERRIDE
    {
        return m_functionWrapper(p1, p2);
    }

private:
    FunctionWrapper m_functionWrapper;
};

template<typename FunctionWrapper, typename R, typename P1, typename P2, typename P3>
class UnboundFunctionImpl<FunctionWrapper, R(P1, P2, P3)> FINAL : public FunctionImpl<typename FunctionWrapper::ResultType(P1, P2, P3)> {
public:
    UnboundFunctionImpl(FunctionWrapper functionWrapper)
        : m_functionWrapper(functionWrapper)
    {
    }

    virtual typename FunctionWrapper::ResultType operator()(P1 p1, P2 p2, P3 p3) OVERRIDE
    {
        return m_functionWrapper(p1, p2, p3);
    }

private:
    FunctionWrapper m_functionWrapper;
};

template<typename FunctionWrapper, typename R, typename P1, typename P2, typename P3, typename P4>
class UnboundFunctionImpl<FunctionWrapper, R(P1, P2, P3, P4)> FINAL : public FunctionImpl<typename FunctionWrapper::ResultType(P1, P2, P3, P4)> {
public:
    UnboundFunctionImpl(FunctionWrapper functionWrapper)
        : m_functionWrapper(functionWrapper)
    {
    }

    virtual typename FunctionWrapper::ResultType operator()(P1 p1, P2 p2, P3 p3, P4 p4) OVERRIDE
    {
        return m_functionWrapper(p1, p2, p3, p4);
    }

private:
    FunctionWrapper m_functionWrapper;
};

template<typename FunctionWrapper, typename R, typename P1, typename P2, typename P3, typename P4, typename P5>
class UnboundFunctionImpl<FunctionWrapper, R(P1, P2, P3, P4, P5)> FINAL : public FunctionImpl<typename FunctionWrapper::ResultType(P1, P2, P3, P4, P5)> {
public:
    UnboundFunctionImpl(FunctionWrapper functionWrapper)
        : m_functionWrapper(functionWrapper)
    {
    }

    virtual typename FunctionWrapper::ResultType operator()(P1 p1, P2 p2, P3 p3, P4 p4, P5 p5) OVERRIDE
    {
        return m_functionWrapper(p1, p2, p3, p4, p5);
    }

private:
    FunctionWrapper m_functionWrapper;
};

template<typename FunctionWrapper, typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename P6>
class UnboundFunctionImpl<FunctionWrapper, R(P1, P2, P3, P4, P5, P6)> FINAL : public FunctionImpl<typename FunctionWrapper::ResultType(P1, P2, P3, P4, P5, P6)> {
public:
    UnboundFunctionImpl(FunctionWrapper functionWrapper)
        : m_functionWrapper(functionWrapper)
    {
    }

    virtual typename FunctionWrapper::ResultType operator()(P1 p1, P2 p2, P3 p3, P4 p4, P5 p5, P6 p6) OVERRIDE
    {
        return m_functionWrapper(p1, p2, p3, p4, p5, p6);
    }

private:
    FunctionWrapper m_functionWrapper;
};

template<typename FunctionWrapper, typename FunctionType>
class OneArgPartBoundFunctionImpl;

template<typename FunctionWrapper, typename R, typename P1, typename P2>
class OneArgPartBoundFunctionImpl<FunctionWrapper, R(P1, P2)> FINAL : public FunctionImpl<typename FunctionWrapper::ResultType(P2)> {
public:
    OneArgPartBoundFunctionImpl(FunctionWrapper functionWrapper, const P1& p1)
        : m_functionWrapper(functionWrapper)
        , m_p1(ParamStorageTraits<P1>::wrap(p1))
    {
    }

    virtual typename FunctionWrapper::ResultType operator()(P2 p2) OVERRIDE
    {
        return m_functionWrapper(m_p1, p2);
    }

private:
    FunctionWrapper m_functionWrapper;
    typename ParamStorageTraits<P1>::StorageType m_p1;
};

template<typename FunctionWrapper, typename R, typename P1, typename P2, typename P3>
class OneArgPartBoundFunctionImpl<FunctionWrapper, R(P1, P2, P3)> FINAL : public FunctionImpl<typename FunctionWrapper::ResultType(P2, P3)> {
public:
    OneArgPartBoundFunctionImpl(FunctionWrapper functionWrapper, const P1& p1)
        : m_functionWrapper(functionWrapper)
        , m_p1(ParamStorageTraits<P1>::wrap(p1))
    {
    }

    virtual typename FunctionWrapper::ResultType operator()(P2 p2, P3 p3) OVERRIDE
    {
        return m_functionWrapper(m_p1, p2, p3);
    }

private:
    FunctionWrapper m_functionWrapper;
    typename ParamStorageTraits<P1>::StorageType m_p1;
};

template<typename FunctionWrapper, typename R, typename P1, typename P2, typename P3, typename P4>
class OneArgPartBoundFunctionImpl<FunctionWrapper, R(P1, P2, P3, P4)> FINAL : public FunctionImpl<typename FunctionWrapper::ResultType(P2, P3, P4)> {
public:
    OneArgPartBoundFunctionImpl(FunctionWrapper functionWrapper, const P1& p1)
        : m_functionWrapper(functionWrapper)
        , m_p1(ParamStorageTraits<P1>::wrap(p1))
    {
    }

    virtual typename FunctionWrapper::ResultType operator()(P2 p2, P3 p3, P4 p4) OVERRIDE
    {
        return m_functionWrapper(m_p1, p2, p3, p4);
    }

private:
    FunctionWrapper m_functionWrapper;
    typename ParamStorageTraits<P1>::StorageType m_p1;
};

template<typename FunctionWrapper, typename R, typename P1, typename P2, typename P3, typename P4, typename P5>
class OneArgPartBoundFunctionImpl<FunctionWrapper, R(P1, P2, P3, P4, P5)> FINAL : public FunctionImpl<typename FunctionWrapper::ResultType(P2, P3, P4, P5)> {
public:
    OneArgPartBoundFunctionImpl(FunctionWrapper functionWrapper, const P1& p1)
        : m_functionWrapper(functionWrapper)
        , m_p1(ParamStorageTraits<P1>::wrap(p1))
    {
    }

    virtual typename FunctionWrapper::ResultType operator()(P2 p2, P3 p3, P4 p4, P5 p5) OVERRIDE
    {
        return m_functionWrapper(m_p1, p2, p3, p4, p5);
    }

private:
    FunctionWrapper m_functionWrapper;
    typename ParamStorageTraits<P1>::StorageType m_p1;
};

template<typename FunctionWrapper, typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename P6>
class OneArgPartBoundFunctionImpl<FunctionWrapper, R(P1, P2, P3, P4, P5, P6)> FINAL : public FunctionImpl<typename FunctionWrapper::ResultType(P2, P3, P4, P5, P6)> {
public:
    OneArgPartBoundFunctionImpl(FunctionWrapper functionWrapper, const P1& p1)
        : m_functionWrapper(functionWrapper)
        , m_p1(ParamStorageTraits<P1>::wrap(p1))
    {
    }

    virtual typename FunctionWrapper::ResultType operator()(P2 p2, P3 p3, P4 p4, P5 p5, P6 p6) OVERRIDE
    {
        return m_functionWrapper(m_p1, p2, p3, p4, p5, p6);
    }

private:
    FunctionWrapper m_functionWrapper;
    typename ParamStorageTraits<P1>::StorageType m_p1;
};

template<typename FunctionWrapper, typename FunctionType>
class TwoArgPartBoundFunctionImpl;

template<typename FunctionWrapper, typename R, typename P1, typename P2, typename P3>
class TwoArgPartBoundFunctionImpl<FunctionWrapper, R(P1, P2, P3)> FINAL : public FunctionImpl<typename FunctionWrapper::ResultType(P3)> {
public:
    TwoArgPartBoundFunctionImpl(FunctionWrapper functionWrapper, const P1& p1, const P2& p2)
        : m_functionWrapper(functionWrapper)
        , m_p1(ParamStorageTraits<P1>::wrap(p1))
        , m_p2(ParamStorageTraits<P2>::wrap(p2))
    {
    }

    virtual typename FunctionWrapper::ResultType operator()(P3 p3) OVERRIDE
    {
        return m_functionWrapper(m_p1, m_p2, p3);
    }

private:
    FunctionWrapper m_functionWrapper;
    typename ParamStorageTraits<P1>::StorageType m_p1;
    typename ParamStorageTraits<P2>::StorageType m_p2;
};

template<typename FunctionWrapper, typename R, typename P1, typename P2, typename P3, typename P4>
class TwoArgPartBoundFunctionImpl<FunctionWrapper, R(P1, P2, P3, P4)> FINAL : public FunctionImpl<typename FunctionWrapper::ResultType(P3, P4)> {
public:
    TwoArgPartBoundFunctionImpl(FunctionWrapper functionWrapper, const P1& p1, const P2& p2)
        : m_functionWrapper(functionWrapper)
        , m_p1(ParamStorageTraits<P1>::wrap(p1))
        , m_p2(ParamStorageTraits<P2>::wrap(p2))
    {
    }

    virtual typename FunctionWrapper::ResultType operator()(P3 p3, P4 p4) OVERRIDE
    {
        return m_functionWrapper(m_p1, m_p2, p3, p4);
    }

private:
    FunctionWrapper m_functionWrapper;
    typename ParamStorageTraits<P1>::StorageType m_p1;
    typename ParamStorageTraits<P2>::StorageType m_p2;
};

template<typename FunctionWrapper, typename R, typename P1, typename P2, typename P3, typename P4, typename P5>
class TwoArgPartBoundFunctionImpl<FunctionWrapper, R(P1, P2, P3, P4, P5)> FINAL : public FunctionImpl<typename FunctionWrapper::ResultType(P3, P4, P5)> {
public:
    TwoArgPartBoundFunctionImpl(FunctionWrapper functionWrapper, const P1& p1, const P2& p2)
        : m_functionWrapper(functionWrapper)
        , m_p1(ParamStorageTraits<P1>::wrap(p1))
        , m_p2(ParamStorageTraits<P2>::wrap(p2))
    {
    }

    virtual typename FunctionWrapper::ResultType operator()(P3 p3, P4 p4, P5 p5) OVERRIDE
    {
        return m_functionWrapper(m_p1, m_p2, p3, p4, p5);
    }

private:
    FunctionWrapper m_functionWrapper;
    typename ParamStorageTraits<P1>::StorageType m_p1;
    typename ParamStorageTraits<P2>::StorageType m_p2;
};

template<typename FunctionWrapper, typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename P6>
class TwoArgPartBoundFunctionImpl<FunctionWrapper, R(P1, P2, P3, P4, P5, P6)> FINAL : public FunctionImpl<typename FunctionWrapper::ResultType(P3, P4, P5, P6)> {
public:
    TwoArgPartBoundFunctionImpl(FunctionWrapper functionWrapper, const P1& p1, const P2& p2)
        : m_functionWrapper(functionWrapper)
        , m_p1(ParamStorageTraits<P1>::wrap(p1))
        , m_p2(ParamStorageTraits<P2>::wrap(p2))
    {
    }

    virtual typename FunctionWrapper::ResultType operator()(P3 p3, P4 p4, P5 p5, P6 p6) OVERRIDE
    {
        return m_functionWrapper(m_p1, m_p2, p3, p4, p5, p6);
    }

private:
    FunctionWrapper m_functionWrapper;
    typename ParamStorageTraits<P1>::StorageType m_p1;
    typename ParamStorageTraits<P2>::StorageType m_p2;
};

template<typename FunctionWrapper, typename FunctionType>
class ThreeArgPartBoundFunctionImpl;

template<typename FunctionWrapper, typename R, typename P1, typename P2, typename P3, typename P4>
class ThreeArgPartBoundFunctionImpl<FunctionWrapper, R(P1, P2, P3, P4)> FINAL : public FunctionImpl<typename FunctionWrapper::ResultType(P4)> {
public:
    ThreeArgPartBoundFunctionImpl(FunctionWrapper functionWrapper, const P1& p1, const P2& p2, const P3& p3)
        : m_functionWrapper(functionWrapper)
        , m_p1(ParamStorageTraits<P1>::wrap(p1))
        , m_p2(ParamStorageTraits<P2>::wrap(p2))
        , m_p3(ParamStorageTraits<P3>::wrap(p3))
    {
    }

    virtual typename FunctionWrapper::ResultType operator()(P4 p4) OVERRIDE
    {
        return m_functionWrapper(m_p1, m_p2, m_p3, p4);
    }

private:
    FunctionWrapper m_functionWrapper;
    typename ParamStorageTraits<P1>::StorageType m_p1;
    typename ParamStorageTraits<P2>::StorageType m_p2;
    typename ParamStorageTraits<P3>::StorageType m_p3;
};

template<typename FunctionWrapper, typename R, typename P1, typename P2, typename P3, typename P4, typename P5>
class ThreeArgPartBoundFunctionImpl<FunctionWrapper, R(P1, P2, P3, P4, P5)> FINAL : public FunctionImpl<typename FunctionWrapper::ResultType(P4, P5)> {
public:
    ThreeArgPartBoundFunctionImpl(FunctionWrapper functionWrapper, const P1& p1, const P2& p2, const P3& p3)
        : m_functionWrapper(functionWrapper)
        , m_p1(ParamStorageTraits<P1>::wrap(p1))
        , m_p2(ParamStorageTraits<P2>::wrap(p2))
        , m_p3(ParamStorageTraits<P3>::wrap(p3))
    {
    }

    virtual typename FunctionWrapper::ResultType operator()(P4 p4, P5 p5) OVERRIDE
    {
        return m_functionWrapper(m_p1, m_p2, m_p3, p4, p5);
    }

private:
    FunctionWrapper m_functionWrapper;
    typename ParamStorageTraits<P1>::StorageType m_p1;
    typename ParamStorageTraits<P2>::StorageType m_p2;
    typename ParamStorageTraits<P3>::StorageType m_p3;
};

template<typename FunctionWrapper, typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename P6>
class ThreeArgPartBoundFunctionImpl<FunctionWrapper, R(P1, P2, P3, P4, P5, P6)> FINAL : public FunctionImpl<typename FunctionWrapper::ResultType(P4, P5, P6)> {
public:
    ThreeArgPartBoundFunctionImpl(FunctionWrapper functionWrapper, const P1& p1, const P2& p2, const P3& p3)
        : m_functionWrapper(functionWrapper)
        , m_p1(ParamStorageTraits<P1>::wrap(p1))
        , m_p2(ParamStorageTraits<P2>::wrap(p2))
        , m_p3(ParamStorageTraits<P3>::wrap(p3))
    {
    }

    virtual typename FunctionWrapper::ResultType operator()(P4 p4, P5 p5, P6 p6) OVERRIDE
    {
        return m_functionWrapper(m_p1, m_p2, m_p3, p4, p5, p6);
    }

private:
    FunctionWrapper m_functionWrapper;
    typename ParamStorageTraits<P1>::StorageType m_p1;
    typename ParamStorageTraits<P2>::StorageType m_p2;
    typename ParamStorageTraits<P3>::StorageType m_p3;
};

template<typename FunctionWrapper, typename FunctionType>
class FourArgPartBoundFunctionImpl;

template<typename FunctionWrapper, typename R, typename P1, typename P2, typename P3, typename P4, typename P5>
class FourArgPartBoundFunctionImpl<FunctionWrapper, R(P1, P2, P3, P4, P5)> FINAL : public FunctionImpl<typename FunctionWrapper::ResultType(P5)> {
public:
    FourArgPartBoundFunctionImpl(FunctionWrapper functionWrapper, const P1& p1, const P2& p2, const P3& p3, const P4& p4)
        : m_functionWrapper(functionWrapper)
        , m_p1(ParamStorageTraits<P1>::wrap(p1))
        , m_p2(ParamStorageTraits<P2>::wrap(p2))
        , m_p3(ParamStorageTraits<P3>::wrap(p3))
        , m_p4(ParamStorageTraits<P4>::wrap(p4))
    {
    }

    virtual typename FunctionWrapper::ResultType operator()(P5 p5) OVERRIDE
    {
        return m_functionWrapper(m_p1, m_p2, m_p3, m_p4, p5);
    }

private:
    FunctionWrapper m_functionWrapper;
    typename ParamStorageTraits<P1>::StorageType m_p1;
    typename ParamStorageTraits<P2>::StorageType m_p2;
    typename ParamStorageTraits<P3>::StorageType m_p3;
    typename ParamStorageTraits<P4>::StorageType m_p4;
};

template<typename FunctionWrapper, typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename P6>
class FourArgPartBoundFunctionImpl<FunctionWrapper, R(P1, P2, P3, P4, P5, P6)> FINAL : public FunctionImpl<typename FunctionWrapper::ResultType(P5, P6)> {
public:
    FourArgPartBoundFunctionImpl(FunctionWrapper functionWrapper, const P1& p1, const P2& p2, const P3& p3, const P4& p4)
        : m_functionWrapper(functionWrapper)
        , m_p1(ParamStorageTraits<P1>::wrap(p1))
        , m_p2(ParamStorageTraits<P2>::wrap(p2))
        , m_p3(ParamStorageTraits<P3>::wrap(p3))
        , m_p4(ParamStorageTraits<P4>::wrap(p4))
    {
    }

    virtual typename FunctionWrapper::ResultType operator()(P5 p5, P6 p6) OVERRIDE
    {
        return m_functionWrapper(m_p1, m_p2, m_p3, m_p4, p5, p6);
    }

private:
    FunctionWrapper m_functionWrapper;
    typename ParamStorageTraits<P1>::StorageType m_p1;
    typename ParamStorageTraits<P2>::StorageType m_p2;
    typename ParamStorageTraits<P3>::StorageType m_p3;
    typename ParamStorageTraits<P4>::StorageType m_p4;
};

template<typename FunctionWrapper, typename FunctionType>
class FiveArgPartBoundFunctionImpl;

template<typename FunctionWrapper, typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename P6>
class FiveArgPartBoundFunctionImpl<FunctionWrapper, R(P1, P2, P3, P4, P5, P6)> FINAL : public FunctionImpl<typename FunctionWrapper::ResultType(P6)> {
public:
    FiveArgPartBoundFunctionImpl(FunctionWrapper functionWrapper, const P1& p1, const P2& p2, const P3& p3, const P4& p4, const P5& p5)
        : m_functionWrapper(functionWrapper)
        , m_p1(ParamStorageTraits<P1>::wrap(p1))
        , m_p2(ParamStorageTraits<P2>::wrap(p2))
        , m_p3(ParamStorageTraits<P3>::wrap(p3))
        , m_p4(ParamStorageTraits<P4>::wrap(p4))
        , m_p5(ParamStorageTraits<P5>::wrap(p5))
    {
    }

    virtual typename FunctionWrapper::ResultType operator()(P6 p6) OVERRIDE
    {
        return m_functionWrapper(m_p1, m_p2, m_p3, m_p4, m_p5, p6);
    }

private:
    FunctionWrapper m_functionWrapper;
    typename ParamStorageTraits<P1>::StorageType m_p1;
    typename ParamStorageTraits<P2>::StorageType m_p2;
    typename ParamStorageTraits<P3>::StorageType m_p3;
    typename ParamStorageTraits<P4>::StorageType m_p4;
    typename ParamStorageTraits<P5>::StorageType m_p5;
};

template<typename FunctionWrapper, typename FunctionType>
class BoundFunctionImpl;

template<typename FunctionWrapper, typename R>
class BoundFunctionImpl<FunctionWrapper, R()> FINAL : public FunctionImpl<typename FunctionWrapper::ResultType()> {
public:
    explicit BoundFunctionImpl(FunctionWrapper functionWrapper)
        : m_functionWrapper(functionWrapper)
    {
    }

    virtual typename FunctionWrapper::ResultType operator()() OVERRIDE
    {
        return m_functionWrapper();
    }

private:
    FunctionWrapper m_functionWrapper;
};

template<typename FunctionWrapper, typename R, typename P1>
class BoundFunctionImpl<FunctionWrapper, R(P1)> FINAL : public FunctionImpl<typename FunctionWrapper::ResultType()> {
public:
    BoundFunctionImpl(FunctionWrapper functionWrapper, const P1& p1)
        : m_functionWrapper(functionWrapper)
        , m_p1(ParamStorageTraits<P1>::wrap(p1))
    {
    }

    virtual typename FunctionWrapper::ResultType operator()() OVERRIDE
    {
        return m_functionWrapper(ParamStorageTraits<P1>::unwrap(m_p1));
    }

private:
    FunctionWrapper m_functionWrapper;
    typename ParamStorageTraits<P1>::StorageType m_p1;
};

template<typename FunctionWrapper, typename R, typename P1, typename P2>
class BoundFunctionImpl<FunctionWrapper, R(P1, P2)> FINAL : public FunctionImpl<typename FunctionWrapper::ResultType()> {
public:
    BoundFunctionImpl(FunctionWrapper functionWrapper, const P1& p1, const P2& p2)
        : m_functionWrapper(functionWrapper)
        , m_p1(ParamStorageTraits<P1>::wrap(p1))
        , m_p2(ParamStorageTraits<P2>::wrap(p2))
    {
    }

    virtual typename FunctionWrapper::ResultType operator()() OVERRIDE
    {
        return m_functionWrapper(ParamStorageTraits<P1>::unwrap(m_p1), ParamStorageTraits<P2>::unwrap(m_p2));
    }

private:
    FunctionWrapper m_functionWrapper;
    typename ParamStorageTraits<P1>::StorageType m_p1;
    typename ParamStorageTraits<P2>::StorageType m_p2;
};

template<typename FunctionWrapper, typename R, typename P1, typename P2, typename P3>
class BoundFunctionImpl<FunctionWrapper, R(P1, P2, P3)> FINAL : public FunctionImpl<typename FunctionWrapper::ResultType()> {
public:
    BoundFunctionImpl(FunctionWrapper functionWrapper, const P1& p1, const P2& p2, const P3& p3)
        : m_functionWrapper(functionWrapper)
        , m_p1(ParamStorageTraits<P1>::wrap(p1))
        , m_p2(ParamStorageTraits<P2>::wrap(p2))
        , m_p3(ParamStorageTraits<P3>::wrap(p3))
    {
    }

    virtual typename FunctionWrapper::ResultType operator()() OVERRIDE
    {
        return m_functionWrapper(ParamStorageTraits<P1>::unwrap(m_p1), ParamStorageTraits<P2>::unwrap(m_p2), ParamStorageTraits<P3>::unwrap(m_p3));
    }

private:
    FunctionWrapper m_functionWrapper;
    typename ParamStorageTraits<P1>::StorageType m_p1;
    typename ParamStorageTraits<P2>::StorageType m_p2;
    typename ParamStorageTraits<P3>::StorageType m_p3;
};

template<typename FunctionWrapper, typename R, typename P1, typename P2, typename P3, typename P4>
class BoundFunctionImpl<FunctionWrapper, R(P1, P2, P3, P4)> FINAL : public FunctionImpl<typename FunctionWrapper::ResultType()> {
public:
    BoundFunctionImpl(FunctionWrapper functionWrapper, const P1& p1, const P2& p2, const P3& p3, const P4& p4)
        : m_functionWrapper(functionWrapper)
        , m_p1(ParamStorageTraits<P1>::wrap(p1))
        , m_p2(ParamStorageTraits<P2>::wrap(p2))
        , m_p3(ParamStorageTraits<P3>::wrap(p3))
        , m_p4(ParamStorageTraits<P4>::wrap(p4))
    {
    }

    virtual typename FunctionWrapper::ResultType operator()() OVERRIDE
    {
        return m_functionWrapper(ParamStorageTraits<P1>::unwrap(m_p1), ParamStorageTraits<P2>::unwrap(m_p2), ParamStorageTraits<P3>::unwrap(m_p3), ParamStorageTraits<P4>::unwrap(m_p4));
    }

private:
    FunctionWrapper m_functionWrapper;
    typename ParamStorageTraits<P1>::StorageType m_p1;
    typename ParamStorageTraits<P2>::StorageType m_p2;
    typename ParamStorageTraits<P3>::StorageType m_p3;
    typename ParamStorageTraits<P4>::StorageType m_p4;
};

template<typename FunctionWrapper, typename R, typename P1, typename P2, typename P3, typename P4, typename P5>
class BoundFunctionImpl<FunctionWrapper, R(P1, P2, P3, P4, P5)> FINAL : public FunctionImpl<typename FunctionWrapper::ResultType()> {
public:
    BoundFunctionImpl(FunctionWrapper functionWrapper, const P1& p1, const P2& p2, const P3& p3, const P4& p4, const P5& p5)
        : m_functionWrapper(functionWrapper)
        , m_p1(ParamStorageTraits<P1>::wrap(p1))
        , m_p2(ParamStorageTraits<P2>::wrap(p2))
        , m_p3(ParamStorageTraits<P3>::wrap(p3))
        , m_p4(ParamStorageTraits<P4>::wrap(p4))
        , m_p5(ParamStorageTraits<P5>::wrap(p5))
    {
    }

    virtual typename FunctionWrapper::ResultType operator()() OVERRIDE
    {
        return m_functionWrapper(ParamStorageTraits<P1>::unwrap(m_p1), ParamStorageTraits<P2>::unwrap(m_p2), ParamStorageTraits<P3>::unwrap(m_p3), ParamStorageTraits<P4>::unwrap(m_p4), ParamStorageTraits<P5>::unwrap(m_p5));
    }

private:
    FunctionWrapper m_functionWrapper;
    typename ParamStorageTraits<P1>::StorageType m_p1;
    typename ParamStorageTraits<P2>::StorageType m_p2;
    typename ParamStorageTraits<P3>::StorageType m_p3;
    typename ParamStorageTraits<P4>::StorageType m_p4;
    typename ParamStorageTraits<P5>::StorageType m_p5;
};

template<typename FunctionWrapper, typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename P6>
class BoundFunctionImpl<FunctionWrapper, R(P1, P2, P3, P4, P5, P6)> FINAL : public FunctionImpl<typename FunctionWrapper::ResultType()> {
public:
    BoundFunctionImpl(FunctionWrapper functionWrapper, const P1& p1, const P2& p2, const P3& p3, const P4& p4, const P5& p5, const P6& p6)
        : m_functionWrapper(functionWrapper)
        , m_p1(ParamStorageTraits<P1>::wrap(p1))
        , m_p2(ParamStorageTraits<P2>::wrap(p2))
        , m_p3(ParamStorageTraits<P3>::wrap(p3))
        , m_p4(ParamStorageTraits<P4>::wrap(p4))
        , m_p5(ParamStorageTraits<P5>::wrap(p5))
        , m_p6(ParamStorageTraits<P6>::wrap(p6))
    {
    }

    virtual typename FunctionWrapper::ResultType operator()() OVERRIDE
    {
        return m_functionWrapper(ParamStorageTraits<P1>::unwrap(m_p1), ParamStorageTraits<P2>::unwrap(m_p2), ParamStorageTraits<P3>::unwrap(m_p3), ParamStorageTraits<P4>::unwrap(m_p4), ParamStorageTraits<P5>::unwrap(m_p5), ParamStorageTraits<P6>::unwrap(m_p6));
    }

private:
    FunctionWrapper m_functionWrapper;
    typename ParamStorageTraits<P1>::StorageType m_p1;
    typename ParamStorageTraits<P2>::StorageType m_p2;
    typename ParamStorageTraits<P3>::StorageType m_p3;
    typename ParamStorageTraits<P4>::StorageType m_p4;
    typename ParamStorageTraits<P5>::StorageType m_p5;
    typename ParamStorageTraits<P6>::StorageType m_p6;
};

class FunctionBase {
public:
    bool isNull() const
    {
        return !m_impl;
    }

protected:
    FunctionBase()
    {
    }

    explicit FunctionBase(PassRefPtr<FunctionImplBase> impl)
        : m_impl(impl)
    {
    }

    template<typename FunctionType> FunctionImpl<FunctionType>* impl() const
    {
        return static_cast<FunctionImpl<FunctionType>*>(m_impl.get());
    }

private:
    RefPtr<FunctionImplBase> m_impl;
};

template<typename>
class Function;

template<typename R>
class Function<R()> : public FunctionBase {
public:
    Function()
    {
    }

    Function(PassRefPtr<FunctionImpl<R()> > impl)
        : FunctionBase(impl)
    {
    }

    R operator()() const
    {
        ASSERT(!isNull());
        return impl<R()>()->operator()();
    }
};

template<typename R, typename A1>
class Function<R(A1)> : public FunctionBase {
public:
    Function()
    {
    }

    Function(PassRefPtr<FunctionImpl<R(A1)> > impl)
        : FunctionBase(impl)
    {
    }

    R operator()(A1 a1) const
    {
        ASSERT(!isNull());
        return impl<R(A1)>()->operator()(a1);
    }
};

template<typename R, typename A1, typename A2>
class Function<R(A1, A2)> : public FunctionBase {
public:
    Function()
    {
    }

    Function(PassRefPtr<FunctionImpl<R(A1, A2)> > impl)
        : FunctionBase(impl)
    {
    }

    R operator()(A1 a1, A2 a2) const
    {
        ASSERT(!isNull());
        return impl<R(A1, A2)>()->operator()(a1, a2);
    }
};

template<typename R, typename A1, typename A2, typename A3>
class Function<R(A1, A2, A3)> : public FunctionBase {
public:
    Function()
    {
    }

    Function(PassRefPtr<FunctionImpl<R(A1, A2, A3)> > impl)
        : FunctionBase(impl)
    {
    }

    R operator()(A1 a1, A2 a2, A3 a3) const
    {
        ASSERT(!isNull());
        return impl<R(A1, A2, A3)>()->operator()(a1, a2, a3);
    }
};

template<typename R, typename A1, typename A2, typename A3, typename A4>
class Function<R(A1, A2, A3, A4)> : public FunctionBase {
public:
    Function()
    {
    }

    Function(PassRefPtr<FunctionImpl<R(A1, A2, A3, A4)> > impl)
        : FunctionBase(impl)
    {
    }

    R operator()(A1 a1, A2 a2, A3 a3, A4 a4) const
    {
        ASSERT(!isNull());
        return impl<R(A1, A2, A3, A4)>()->operator()(a1, a2, a3, a4);
    }
};

template<typename R, typename A1, typename A2, typename A3, typename A4, typename A5>
class Function<R(A1, A2, A3, A4, A5)> : public FunctionBase {
public:
    Function()
    {
    }

    Function(PassRefPtr<FunctionImpl<R(A1, A2, A3, A4, A5)> > impl)
        : FunctionBase(impl)
    {
    }

    R operator()(A1 a1, A2 a2, A3 a3, A4 a4, A5 a5) const
    {
        ASSERT(!isNull());
        return impl<R(A1, A2, A3, A4, A5)>()->operator()(a1, a2, a3, a4, a5);
    }
};

template<typename R, typename A1, typename A2, typename A3, typename A4, typename A5, typename A6>
class Function<R(A1, A2, A3, A4, A5, A6)> : public FunctionBase {
public:
    Function()
    {
    }

    Function(PassRefPtr<FunctionImpl<R(A1, A2, A3, A4, A5, A6)> > impl)
        : FunctionBase(impl)
    {
    }

    R operator()(A1 a1, A2 a2, A3 a3, A4 a4, A5 a5, A6 a6) const
    {
        ASSERT(!isNull());
        return impl<R(A1, A2, A3, A4, A5, A6)>()->operator()(a1, a2, a3, a4, a5, a6);
    }
};

template<typename FunctionType>
Function<typename FunctionWrapper<FunctionType>::ResultType()> bind(FunctionType function)
{
    return Function<typename FunctionWrapper<FunctionType>::ResultType()>(adoptRef(new BoundFunctionImpl<FunctionWrapper<FunctionType>, typename FunctionWrapper<FunctionType>::ResultType()>(FunctionWrapper<FunctionType>(function))));
}

template<typename FunctionType, typename A1>
Function<typename FunctionWrapper<FunctionType>::ResultType()> bind(FunctionType function, const A1& a1)
{
    return Function<typename FunctionWrapper<FunctionType>::ResultType()>(adoptRef(new BoundFunctionImpl<FunctionWrapper<FunctionType>, typename FunctionWrapper<FunctionType>::ResultType (A1)>(FunctionWrapper<FunctionType>(function), a1)));
}

template<typename FunctionType, typename A1, typename A2>
Function<typename FunctionWrapper<FunctionType>::ResultType()> bind(FunctionType function, const A1& a1, const A2& a2)
{
    return Function<typename FunctionWrapper<FunctionType>::ResultType()>(adoptRef(new BoundFunctionImpl<FunctionWrapper<FunctionType>, typename FunctionWrapper<FunctionType>::ResultType (A1, A2)>(FunctionWrapper<FunctionType>(function), a1, a2)));
}

template<typename FunctionType, typename A1, typename A2, typename A3>
Function<typename FunctionWrapper<FunctionType>::ResultType()> bind(FunctionType function, const A1& a1, const A2& a2, const A3& a3)
{
    return Function<typename FunctionWrapper<FunctionType>::ResultType()>(adoptRef(new BoundFunctionImpl<FunctionWrapper<FunctionType>, typename FunctionWrapper<FunctionType>::ResultType (A1, A2, A3)>(FunctionWrapper<FunctionType>(function), a1, a2, a3)));
}

template<typename FunctionType, typename A1, typename A2, typename A3, typename A4>
Function<typename FunctionWrapper<FunctionType>::ResultType()> bind(FunctionType function, const A1& a1, const A2& a2, const A3& a3, const A4& a4)
{
    return Function<typename FunctionWrapper<FunctionType>::ResultType()>(adoptRef(new BoundFunctionImpl<FunctionWrapper<FunctionType>, typename FunctionWrapper<FunctionType>::ResultType (A1, A2, A3, A4)>(FunctionWrapper<FunctionType>(function), a1, a2, a3, a4)));
}

template<typename FunctionType, typename A1, typename A2, typename A3, typename A4, typename A5>
Function<typename FunctionWrapper<FunctionType>::ResultType()> bind(FunctionType function, const A1& a1, const A2& a2, const A3& a3, const A4& a4, const A5& a5)
{
    return Function<typename FunctionWrapper<FunctionType>::ResultType()>(adoptRef(new BoundFunctionImpl<FunctionWrapper<FunctionType>, typename FunctionWrapper<FunctionType>::ResultType (A1, A2, A3, A4, A5)>(FunctionWrapper<FunctionType>(function), a1, a2, a3, a4, a5)));
}

template<typename FunctionType, typename A1, typename A2, typename A3, typename A4, typename A5, typename A6>
Function<typename FunctionWrapper<FunctionType>::ResultType()> bind(FunctionType function, const A1& a1, const A2& a2, const A3& a3, const A4& a4, const A5& a5, const A6& a6)
{
    return Function<typename FunctionWrapper<FunctionType>::ResultType()>(adoptRef(new BoundFunctionImpl<FunctionWrapper<FunctionType>, typename FunctionWrapper<FunctionType>::ResultType (A1, A2, A3, A4, A5, A6)>(FunctionWrapper<FunctionType>(function), a1, a2, a3, a4, a5, a6)));
}


// Partial parameter binding.

template<typename A1, typename FunctionType>
Function<typename FunctionWrapper<FunctionType>::ResultType(A1)> bind(FunctionType function)
{
    return Function<typename FunctionWrapper<FunctionType>::ResultType(A1)>(adoptRef(new UnboundFunctionImpl<FunctionWrapper<FunctionType>, typename FunctionWrapper<FunctionType>::ResultType (A1)>(FunctionWrapper<FunctionType>(function))));
}

template<typename A1, typename A2, typename FunctionType>
Function<typename FunctionWrapper<FunctionType>::ResultType(A1, A2)> bind(FunctionType function)
{
    return Function<typename FunctionWrapper<FunctionType>::ResultType(A1, A2)>(adoptRef(new UnboundFunctionImpl<FunctionWrapper<FunctionType>, typename FunctionWrapper<FunctionType>::ResultType (A1, A2)>(FunctionWrapper<FunctionType>(function))));
}

template<typename A2, typename FunctionType, typename A1>
Function<typename FunctionWrapper<FunctionType>::ResultType(A2)> bind(FunctionType function, const A1& a1)
{
    return Function<typename FunctionWrapper<FunctionType>::ResultType(A2)>(adoptRef(new OneArgPartBoundFunctionImpl<FunctionWrapper<FunctionType>, typename FunctionWrapper<FunctionType>::ResultType (A1, A2)>(FunctionWrapper<FunctionType>(function), a1)));
}

template<typename A1, typename A2, typename A3, typename FunctionType>
Function<typename FunctionWrapper<FunctionType>::ResultType(A1, A2, A3)> bind(FunctionType function)
{
    return Function<typename FunctionWrapper<FunctionType>::ResultType(A1, A2, A3)>(adoptRef(new UnboundFunctionImpl<FunctionWrapper<FunctionType>, typename FunctionWrapper<FunctionType>::ResultType (A1, A2, A3)>(FunctionWrapper<FunctionType>(function))));
}

template<typename A2, typename A3, typename FunctionType, typename A1>
Function<typename FunctionWrapper<FunctionType>::ResultType(A2, A3)> bind(FunctionType function, const A1& a1)
{
    return Function<typename FunctionWrapper<FunctionType>::ResultType(A2, A3)>(adoptRef(new OneArgPartBoundFunctionImpl<FunctionWrapper<FunctionType>, typename FunctionWrapper<FunctionType>::ResultType (A1, A2, A3)>(FunctionWrapper<FunctionType>(function), a1)));
}

template<typename A3, typename FunctionType, typename A1, typename A2>
Function<typename FunctionWrapper<FunctionType>::ResultType(A3)> bind(FunctionType function, const A1& a1, const A2& a2)
{
    return Function<typename FunctionWrapper<FunctionType>::ResultType(A3)>(adoptRef(new TwoArgPartBoundFunctionImpl<FunctionWrapper<FunctionType>, typename FunctionWrapper<FunctionType>::ResultType (A1, A2, A3)>(FunctionWrapper<FunctionType>(function), a1, a2)));
}

template<typename A1, typename A2, typename A3, typename A4, typename FunctionType>
Function<typename FunctionWrapper<FunctionType>::ResultType(A1, A2, A3, A4)> bind(FunctionType function)
{
    return Function<typename FunctionWrapper<FunctionType>::ResultType(A1, A2, A3, A4)>(adoptRef(new UnboundFunctionImpl<FunctionWrapper<FunctionType>, typename FunctionWrapper<FunctionType>::ResultType (A1, A2, A3, A4)>(FunctionWrapper<FunctionType>(function))));
}

template<typename A2, typename A3, typename A4, typename FunctionType, typename A1>
Function<typename FunctionWrapper<FunctionType>::ResultType(A2, A3, A4)> bind(FunctionType function, const A1& a1)
{
    return Function<typename FunctionWrapper<FunctionType>::ResultType(A2, A3, A4)>(adoptRef(new OneArgPartBoundFunctionImpl<FunctionWrapper<FunctionType>, typename FunctionWrapper<FunctionType>::ResultType (A1, A2, A3, A4)>(FunctionWrapper<FunctionType>(function), a1)));
}

template<typename A3, typename A4, typename FunctionType, typename A1, typename A2>
Function<typename FunctionWrapper<FunctionType>::ResultType(A3, A4)> bind(FunctionType function, const A1& a1, const A2& a2)
{
    return Function<typename FunctionWrapper<FunctionType>::ResultType(A3, A4)>(adoptRef(new TwoArgPartBoundFunctionImpl<FunctionWrapper<FunctionType>, typename FunctionWrapper<FunctionType>::ResultType (A1, A2, A3, A4)>(FunctionWrapper<FunctionType>(function), a1, a2)));
}

template<typename A4, typename FunctionType, typename A1, typename A2, typename A3>
Function<typename FunctionWrapper<FunctionType>::ResultType(A4)> bind(FunctionType function, const A1& a1, const A2& a2, const A3& a3)
{
    return Function<typename FunctionWrapper<FunctionType>::ResultType(A4)>(adoptRef(new ThreeArgPartBoundFunctionImpl<FunctionWrapper<FunctionType>, typename FunctionWrapper<FunctionType>::ResultType (A1, A2, A3, A4)>(FunctionWrapper<FunctionType>(function), a1, a2, a3)));
}

template<typename A1, typename A2, typename A3, typename A4, typename A5, typename FunctionType>
Function<typename FunctionWrapper<FunctionType>::ResultType(A1, A2, A3, A4, A5)> bind(FunctionType function)
{
    return Function<typename FunctionWrapper<FunctionType>::ResultType(A1, A2, A3, A4, A5)>(adoptRef(new UnboundFunctionImpl<FunctionWrapper<FunctionType>, typename FunctionWrapper<FunctionType>::ResultType (A1, A2, A3, A4, A5)>(FunctionWrapper<FunctionType>(function))));
}

template<typename A2, typename A3, typename A4, typename A5, typename FunctionType, typename A1>
Function<typename FunctionWrapper<FunctionType>::ResultType(A2, A3, A4, A5)> bind(FunctionType function, const A1& a1)
{
    return Function<typename FunctionWrapper<FunctionType>::ResultType(A2, A3, A4, A5)>(adoptRef(new OneArgPartBoundFunctionImpl<FunctionWrapper<FunctionType>, typename FunctionWrapper<FunctionType>::ResultType (A1, A2, A3, A4, A5)>(FunctionWrapper<FunctionType>(function), a1)));
}

template<typename A3, typename A4, typename A5, typename FunctionType, typename A1, typename A2>
Function<typename FunctionWrapper<FunctionType>::ResultType(A3, A4, A5)> bind(FunctionType function, const A1& a1, const A2& a2)
{
    return Function<typename FunctionWrapper<FunctionType>::ResultType(A3, A4, A5)>(adoptRef(new TwoArgPartBoundFunctionImpl<FunctionWrapper<FunctionType>, typename FunctionWrapper<FunctionType>::ResultType (A1, A2, A3, A4, A5)>(FunctionWrapper<FunctionType>(function), a1, a2)));
}

template<typename A4, typename A5, typename FunctionType, typename A1, typename A2, typename A3>
Function<typename FunctionWrapper<FunctionType>::ResultType(A4, A5)> bind(FunctionType function, const A1& a1, const A2& a2, const A3& a3)
{
    return Function<typename FunctionWrapper<FunctionType>::ResultType(A4, A5)>(adoptRef(new ThreeArgPartBoundFunctionImpl<FunctionWrapper<FunctionType>, typename FunctionWrapper<FunctionType>::ResultType (A1, A2, A3, A4, A5)>(FunctionWrapper<FunctionType>(function), a1, a2, a3)));
}

template<typename A5, typename FunctionType, typename A1, typename A2, typename A3, typename A4>
Function<typename FunctionWrapper<FunctionType>::ResultType(A5)> bind(FunctionType function, const A1& a1, const A2& a2, const A3& a3, const A4& a4)
{
    return Function<typename FunctionWrapper<FunctionType>::ResultType(A5)>(adoptRef(new FourArgPartBoundFunctionImpl<FunctionWrapper<FunctionType>, typename FunctionWrapper<FunctionType>::ResultType (A1, A2, A3, A4, A5)>(FunctionWrapper<FunctionType>(function), a1, a2, a3, a4)));
}

template<typename A1, typename A2, typename A3, typename A4, typename A5, typename A6, typename FunctionType>
Function<typename FunctionWrapper<FunctionType>::ResultType(A1, A2, A3, A4, A5, A6)> bind(FunctionType function)
{
    return Function<typename FunctionWrapper<FunctionType>::ResultType(A1, A2, A3, A4, A5, A6)>(adoptRef(new UnboundFunctionImpl<FunctionWrapper<FunctionType>, typename FunctionWrapper<FunctionType>::ResultType (A1, A2, A3, A4, A5, A6)>(FunctionWrapper<FunctionType>(function))));
}

template<typename A2, typename A3, typename A4, typename A5, typename A6, typename FunctionType, typename A1>
Function<typename FunctionWrapper<FunctionType>::ResultType(A2, A3, A4, A5, A6)> bind(FunctionType function, const A1& a1)
{
    return Function<typename FunctionWrapper<FunctionType>::ResultType(A2, A3, A4, A5, A6)>(adoptRef(new OneArgPartBoundFunctionImpl<FunctionWrapper<FunctionType>, typename FunctionWrapper<FunctionType>::ResultType (A1, A2, A3, A4, A5, A6)>(FunctionWrapper<FunctionType>(function), a1)));
}

template<typename A3, typename A4, typename A5, typename A6, typename FunctionType, typename A1, typename A2>
Function<typename FunctionWrapper<FunctionType>::ResultType(A3, A4, A5, A6)> bind(FunctionType function, const A1& a1, const A2& a2)
{
    return Function<typename FunctionWrapper<FunctionType>::ResultType(A3, A4, A5, A6)>(adoptRef(new TwoArgPartBoundFunctionImpl<FunctionWrapper<FunctionType>, typename FunctionWrapper<FunctionType>::ResultType (A1, A2, A3, A4, A5, A6)>(FunctionWrapper<FunctionType>(function), a1, a2)));
}

template<typename A4, typename A5, typename A6, typename FunctionType, typename A1, typename A2, typename A3>
Function<typename FunctionWrapper<FunctionType>::ResultType(A4, A5, A6)> bind(FunctionType function, const A1& a1, const A2& a2, const A3& a3)
{
    return Function<typename FunctionWrapper<FunctionType>::ResultType(A4, A5, A6)>(adoptRef(new ThreeArgPartBoundFunctionImpl<FunctionWrapper<FunctionType>, typename FunctionWrapper<FunctionType>::ResultType (A1, A2, A3, A4, A5, A6)>(FunctionWrapper<FunctionType>(function), a1, a2, a3)));
}

template<typename A5, typename A6, typename FunctionType, typename A1, typename A2, typename A3, typename A4>
Function<typename FunctionWrapper<FunctionType>::ResultType(A5, A6)> bind(FunctionType function, const A1& a1, const A2& a2, const A3& a3, const A4& a4)
{
    return Function<typename FunctionWrapper<FunctionType>::ResultType(A5, A6)>(adoptRef(new FourArgPartBoundFunctionImpl<FunctionWrapper<FunctionType>, typename FunctionWrapper<FunctionType>::ResultType (A1, A2, A3, A4, A5, A6)>(FunctionWrapper<FunctionType>(function), a1, a2, a3, a4)));
}

template<typename A6, typename FunctionType, typename A1, typename A2, typename A3, typename A4, typename A5>
Function<typename FunctionWrapper<FunctionType>::ResultType(A6)> bind(FunctionType function, const A1& a1, const A2& a2, const A3& a3, const A4& a4, const A5& a5)
{
    return Function<typename FunctionWrapper<FunctionType>::ResultType(A6)>(adoptRef(new FiveArgPartBoundFunctionImpl<FunctionWrapper<FunctionType>, typename FunctionWrapper<FunctionType>::ResultType (A1, A2, A3, A4, A5, A6)>(FunctionWrapper<FunctionType>(function), a1, a2, a3, a4, a5)));
}

typedef Function<void()> Closure;

}

using WTF::Function;
using WTF::Closure;

#endif // WTF_Functional_h
