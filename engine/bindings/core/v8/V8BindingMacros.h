/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef V8BindingMacros_h
#define V8BindingMacros_h

namespace blink {

// Naming scheme:
// TO*_RETURNTYPE[_ARGTYPE]...
// ...using _DEFAULT instead of _ANY..._ANY when returing a default value.

#define TONATIVE_EXCEPTION(type, var, value) \
    type var;                                \
    {                                        \
        v8::TryCatch block;                  \
        var = (value);                       \
        if (UNLIKELY(block.HasCaught()))     \
            return block.ReThrow();          \
    }

#define TONATIVE_VOID_INTERNAL(var, value) \
    var = (value);                         \
    if (UNLIKELY(block.HasCaught()))       \
        return;

#define TONATIVE_VOID(type, var, value)        \
    type var;                                  \
    {                                          \
        v8::TryCatch block;                    \
        V8RethrowTryCatchScope rethrow(block); \
        TONATIVE_VOID_INTERNAL(var, value);    \
    }

#define TONATIVE_DEFAULT(type, var, value, retVal) \
    type var;                                      \
    {                                              \
        v8::TryCatch block;                        \
        var = (value);                             \
        if (UNLIKELY(block.HasCaught())) {         \
            block.ReThrow();                       \
            return retVal;                         \
        }                                          \
    }

// We need to cancel the exception propergation when we return a rejected
// Promise.
#define TONATIVE_VOID_PROMISE_INTERNAL(var, value, info)                                        \
    var = (value);                                                                              \
    if (UNLIKELY(block.HasCaught())) {                                                          \
        v8SetReturnValue(info, ScriptPromise::rejectRaw(info.GetIsolate(), block.Exception())); \
        block.Reset();                                                                          \
        return;                                                                                 \
    }

#define TONATIVE_VOID_PROMISE(type, var, value, info)     \
    type var;                                             \
    {                                                     \
        v8::TryCatch block;                               \
        TONATIVE_VOID_PROMISE_INTERNAL(var, value, info); \
    }


#define TONATIVE_VOID_EXCEPTIONSTATE_INTERNAL(var, value, exceptionState) \
    var = (value);                                                        \
    if (UNLIKELY(block.HasCaught() || exceptionState.throwIfNeeded()))    \
        return;                                                           \

#define TONATIVE_VOID_EXCEPTIONSTATE(type, var, value, exceptionState)     \
    type var;                                                              \
    {                                                                      \
        v8::TryCatch block;                                                \
        V8RethrowTryCatchScope rethrow(block);                             \
        TONATIVE_VOID_EXCEPTIONSTATE_INTERNAL(var, value, exceptionState); \
    }

#define TONATIVE_DEFAULT_EXCEPTIONSTATE(type, var, value, exceptionState, retVal) \
    type var;                                                                     \
    {                                                                             \
        v8::TryCatch block;                                                       \
        V8RethrowTryCatchScope rethrow(block);                                    \
        var = (value);                                                            \
        if (UNLIKELY(block.HasCaught() || exceptionState.throwIfNeeded()))        \
            return retVal;                                                        \
    }

// We need to cancel the exception propergation when we return a rejected
// Promise.
#define TONATIVE_VOID_EXCEPTIONSTATE_PROMISE_INTERNAL(var, value, exceptionState, info, scriptState) \
    var = (value);                                                                                   \
    if (UNLIKELY(block.HasCaught())) {                                                               \
        v8SetReturnValue(info, ScriptPromise::rejectRaw(info.GetIsolate(), block.Exception()));      \
        block.Reset();                                                                               \
        return;                                                                                      \
    }                                                                                                \
    if (UNLIKELY(exceptionState.hadException())) {                                                   \
        v8SetReturnValue(info, exceptionState.reject(scriptState).v8Value());                        \
        return;                                                                                      \
    }

#define TONATIVE_VOID_EXCEPTIONSTATE_PROMISE(type, var, value, exceptionState, info, scriptState)     \
    type var;                                                                                         \
    {                                                                                                 \
        v8::TryCatch block;                                                                           \
        TONATIVE_VOID_EXCEPTIONSTATE_PROMISE_INTERNAL(var, value, exceptionState, info, scriptState); \
    }

// type is an instance of class template V8StringResource<>,
// but Mode argument varies; using type (not Mode) for consistency
// with other macros and ease of code generation
#define TOSTRING_VOID(type, var, value) \
    type var(value);                    \
    if (UNLIKELY(!var.prepare()))       \
        return;

#define TOSTRING_VOID_INTERNAL(var, value) \
    var = (value);                         \
    if (UNLIKELY(!var.prepare()))          \
        return;

#define TOSTRING_DEFAULT(type, var, value, retVal) \
    type var(value);                               \
    if (UNLIKELY(!var.prepare()))                  \
        return retVal;

// We need to cancel the exception propergation when we return a rejected
// Promise.
#define TOSTRING_VOID_PROMISE_INTERNAL(var, value, info)                                           \
    var = (value);                                                                                 \
    if (UNLIKELY(!var.prepare()))  {                                                               \
        info.GetReturnValue().Set(ScriptPromise::rejectRaw(info.GetIsolate(), block.Exception())); \
        block.Reset();                                                                             \
        return;                                                                                    \
    }

#define TOSTRING_VOID_PROMISE(type, var, value, info)           \
    type var;                                                   \
    {                                                           \
        v8::TryCatch block;                                     \
        TOSTRING_VOID_PROMISE_INTERNAL(type, var, value, info); \
    }

} // namespace blink

#endif // V8BindingMacros_h
