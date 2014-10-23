/*
 * Copyright (C) 2014 Google Inc. All rights reserved.
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

#include "config.h"
#include "bindings/core/v8/V8Element.h"

#include "bindings/core/v8/Dictionary.h"
#include "bindings/core/v8/ExceptionState.h"
#include "bindings/core/v8/V8AnimationEffect.h"
#include "bindings/core/v8/V8AnimationPlayer.h"
#include "bindings/core/v8/V8Binding.h"
#include "bindings/core/v8/V8BindingMacros.h"
#include "core/animation/ElementAnimation.h"
#include "core/dom/Element.h"
#include "core/frame/UseCounter.h"
#include "platform/RuntimeEnabledFeatures.h"
#include "wtf/GetPtr.h"

namespace blink {

void V8Element::scrollLeftAttributeSetterCustom(v8::Local<v8::Value> value, const v8::PropertyCallbackInfo<void>& info)
{
    ExceptionState exceptionState(ExceptionState::SetterContext, "scrollLeft", "Element", info.Holder(), info.GetIsolate());
    Element* impl = V8Element::toNative(info.Holder());

    if (RuntimeEnabledFeatures::cssomSmoothScrollEnabled() && value->IsObject()) {
        TONATIVE_VOID(Dictionary, scrollOptionsHorizontal, Dictionary(value, info.GetIsolate()));
        impl->setScrollLeft(scrollOptionsHorizontal, exceptionState);
        exceptionState.throwIfNeeded();
        return;
    }

    TONATIVE_VOID_EXCEPTIONSTATE(float, position, toInt32(value, exceptionState), exceptionState);
    impl->setScrollLeft(position);
}

void V8Element::scrollTopAttributeSetterCustom(v8::Local<v8::Value> value, const v8::PropertyCallbackInfo<void>& info)
{
    ExceptionState exceptionState(ExceptionState::SetterContext, "scrollTop", "Element", info.Holder(), info.GetIsolate());
    Element* impl = V8Element::toNative(info.Holder());

    if (RuntimeEnabledFeatures::cssomSmoothScrollEnabled() && value->IsObject()) {
        TONATIVE_VOID(Dictionary, scrollOptionsVertical, Dictionary(value, info.GetIsolate()));
        impl->setScrollTop(scrollOptionsVertical, exceptionState);
        exceptionState.throwIfNeeded();
        return;
    }

    TONATIVE_VOID_EXCEPTIONSTATE(float, position, toInt32(value, exceptionState), exceptionState);
    impl->setScrollTop(position);
}

////////////////////////////////////////////////////////////////////////////////
// Overload resolution for animate()
// FIXME: needs support for union types http://crbug.com/240176
////////////////////////////////////////////////////////////////////////////////

// AnimationPlayer animate(AnimationEffect? effect);
void animate1Method(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    Element* impl = V8Element::toNative(info.Holder());
    TONATIVE_VOID(AnimationEffect*, effect, V8AnimationEffect::toNativeWithTypeCheck(info.GetIsolate(), info[0]));
    v8SetReturnValueFast(info, WTF::getPtr(ElementAnimation::animate(*impl, effect)), impl);
}

// [RaisesException] AnimationPlayer animate(sequence<Dictionary> effect);
void animate2Method(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "animate", "Element", info.Holder(), info.GetIsolate());
    Element* impl = V8Element::toNative(info.Holder());
    TONATIVE_VOID(Vector<Dictionary>, keyframes, toNativeArray<Dictionary>(info[0], 1, info.GetIsolate()));
    RefPtrWillBeRawPtr<AnimationPlayer> result = ElementAnimation::animate(*impl, keyframes, exceptionState);
    if (exceptionState.throwIfNeeded())
        return;
    v8SetReturnValueFast(info, WTF::getPtr(result.release()), impl);
}

// AnimationPlayer animate(AnimationEffect? effect, double timing);
void animate3Method(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    Element* impl = V8Element::toNative(info.Holder());
    TONATIVE_VOID(AnimationEffect*, effect, V8AnimationEffect::toNativeWithTypeCheck(info.GetIsolate(), info[0]));
    TONATIVE_VOID(double, duration, static_cast<double>(info[1]->NumberValue()));
    v8SetReturnValueFast(info, WTF::getPtr(ElementAnimation::animate(*impl, effect, duration)), impl);
}

// AnimationPlayer animate(AnimationEffect? effect, Dictionary timing);
void animate4Method(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    Element* impl = V8Element::toNative(info.Holder());
    TONATIVE_VOID(AnimationEffect*, effect, V8AnimationEffect::toNativeWithTypeCheck(info.GetIsolate(), info[0]));
    TONATIVE_VOID(Dictionary, timingInput, Dictionary(info[1], info.GetIsolate()));
    if (!timingInput.isUndefinedOrNull() && !timingInput.isObject()) {
        V8ThrowException::throwTypeError(ExceptionMessages::failedToExecute("animate", "Element", "parameter 2 ('timingInput') is not an object."), info.GetIsolate());
        return;
    }
    v8SetReturnValueFast(info, WTF::getPtr(ElementAnimation::animate(*impl, effect, timingInput)), impl);
}

// [RaisesException] AnimationPlayer animate(sequence<Dictionary> effect, double timing);
void animate5Method(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "animate", "Element", info.Holder(), info.GetIsolate());
    Element* impl = V8Element::toNative(info.Holder());
    TONATIVE_VOID(Vector<Dictionary>, keyframes, toNativeArray<Dictionary>(info[0], 1, info.GetIsolate()));
    TONATIVE_VOID(double, duration, static_cast<double>(info[1]->NumberValue()));
    RefPtrWillBeRawPtr<AnimationPlayer> result = ElementAnimation::animate(*impl, keyframes, duration, exceptionState);
    if (exceptionState.throwIfNeeded())
        return;
    v8SetReturnValueFast(info, WTF::getPtr(result.release()), impl);
}

// [RaisesException] AnimationPlayer animate(sequence<Dictionary> effect, Dictionary timing);
void animate6Method(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "animate", "Element", info.Holder(), info.GetIsolate());
    Element* impl = V8Element::toNative(info.Holder());
    TONATIVE_VOID(Vector<Dictionary>, keyframes, toNativeArray<Dictionary>(info[0], 1, info.GetIsolate()));
    TONATIVE_VOID(Dictionary, timingInput, Dictionary(info[1], info.GetIsolate()));
    if (!timingInput.isUndefinedOrNull() && !timingInput.isObject()) {
        exceptionState.throwTypeError("parameter 2 ('timingInput') is not an object.");
        exceptionState.throwIfNeeded();
        return;
    }
    RefPtrWillBeRawPtr<AnimationPlayer> result = ElementAnimation::animate(*impl, keyframes, timingInput, exceptionState);
    if (exceptionState.throwIfNeeded())
        return;
    v8SetReturnValueFast(info, WTF::getPtr(result.release()), impl);
}

void V8Element::animateMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    v8::Isolate* isolate = info.GetIsolate();
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "animate", "Element", info.Holder(), isolate);
    // AnimationPlayer animate(
    //     (AnimationEffect or sequence<Dictionary>)? effect,
    //     optional (double or Dictionary) timing);
    switch (info.Length()) {
    case 1:
        // null resolved as to AnimationEffect, as if the member were nullable:
        // (AnimationEffect? or sequence<Dictionary>)
        // instead of the *union* being nullable:
        // (AnimationEffect or sequence<Dictionary>)?
        // AnimationPlayer animate(AnimationEffect? effect);
        if (info[0]->IsNull()) {
            animate1Method(info);
            return;
        }
        // AnimationPlayer animate(AnimationEffect effect);
        if (V8AnimationEffect::hasInstance(info[0], isolate)) {
            animate1Method(info);
            return;
        }
        // [MeasureAs=ElementAnimateKeyframeListEffectNoTiming]
        // AnimationPlayer animate(sequence<Dictionary> effect);
        if (info[0]->IsArray()) {
            UseCounter::count(callingExecutionContext(isolate), UseCounter::ElementAnimateKeyframeListEffectNoTiming);
            animate2Method(info);
            return;
        }
        break;
    case 2:
        // As above, null resolved to AnimationEffect
        // AnimationPlayer animate(AnimationEffect? effect, Dictionary timing);
        if (info[0]->IsNull() && info[1]->IsObject()) {
            animate4Method(info);
            return;
        }
        // AnimationPlayer animate(AnimationEffect? effect, double timing);
        if (info[0]->IsNull()) {
            animate3Method(info);
            return;
        }
        // AnimationPlayer animate(AnimationEffect effect, Dictionary timing);
        if (V8AnimationEffect::hasInstance(info[0], isolate)
            && info[1]->IsObject()) {
            animate4Method(info);
            return;
        }
        // AnimationPlayer animate(AnimationEffect effect, double timing);
        if (V8AnimationEffect::hasInstance(info[0], isolate)) {
            animate3Method(info);
            return;
        }
        // [MeasureAs=ElementAnimateKeyframeListEffectObjectTiming]
        // AnimationPlayer animate(sequence<Dictionary> effect, Dictionary timing);
        if (info[0]->IsArray() && info[1]->IsObject()) {
            UseCounter::count(callingExecutionContext(isolate), UseCounter::ElementAnimateKeyframeListEffectObjectTiming);
            animate6Method(info);
            return;
        }
        // [MeasureAs=ElementAnimateKeyframeListEffectDoubleTiming]
        // AnimationPlayer animate(sequence<Dictionary> effect, double timing);
        if (info[0]->IsArray()) {
            UseCounter::count(callingExecutionContext(isolate), UseCounter::ElementAnimateKeyframeListEffectDoubleTiming);
            animate5Method(info);
            return;
        }
        break;
    default:
        setArityTypeError(exceptionState, "[1]", info.Length());
        exceptionState.throwIfNeeded();
        return;
        break;
    }
    exceptionState.throwTypeError("No function was found that matched the signature provided.");
    exceptionState.throwIfNeeded();
}

} // namespace blink
