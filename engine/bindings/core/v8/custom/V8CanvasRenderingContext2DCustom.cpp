/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
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
#include "bindings/core/v8/V8CanvasRenderingContext2D.h"

#include "bindings/core/v8/V8Binding.h"
#include "bindings/core/v8/V8CanvasGradient.h"
#include "bindings/core/v8/V8CanvasPattern.h"
#include "bindings/core/v8/V8HTMLCanvasElement.h"
#include "bindings/core/v8/V8HTMLImageElement.h"
#include "bindings/core/v8/V8HTMLVideoElement.h"
#include "bindings/core/v8/V8ImageData.h"
#include "core/html/canvas/CanvasGradient.h"
#include "core/html/canvas/CanvasPattern.h"
#include "core/html/canvas/CanvasRenderingContext2D.h"
#include "core/html/canvas/CanvasStyle.h"
#include "platform/geometry/FloatRect.h"

namespace blink {

static v8::Handle<v8::Value> toV8Object(CanvasStyle* style, v8::Handle<v8::Object> creationContext, v8::Isolate* isolate)
{
    if (style->canvasGradient())
        return toV8(style->canvasGradient(), creationContext, isolate);

    if (style->canvasPattern())
        return toV8(style->canvasPattern(), creationContext, isolate);

    return v8String(isolate, style->color());
}

static PassRefPtrWillBeRawPtr<CanvasStyle> toCanvasStyle(v8::Handle<v8::Value> value, v8::Isolate* isolate)
{
    RefPtrWillBeRawPtr<CanvasStyle> canvasStyle = CanvasStyle::createFromGradient(V8CanvasGradient::toNativeWithTypeCheck(isolate, value));
    if (canvasStyle)
        return canvasStyle;
    return CanvasStyle::createFromPattern(V8CanvasPattern::toNativeWithTypeCheck(isolate, value));
}

void V8CanvasRenderingContext2D::strokeStyleAttributeGetterCustom(const v8::PropertyCallbackInfo<v8::Value>& info)
{
    CanvasRenderingContext2D* impl = V8CanvasRenderingContext2D::toNative(info.Holder());
    v8SetReturnValue(info, toV8Object(impl->strokeStyle(), info.Holder(), info.GetIsolate()));
}

void V8CanvasRenderingContext2D::strokeStyleAttributeSetterCustom(v8::Local<v8::Value> value, const v8::PropertyCallbackInfo<void>& info)
{
    CanvasRenderingContext2D* impl = V8CanvasRenderingContext2D::toNative(info.Holder());
    if (RefPtrWillBeRawPtr<CanvasStyle> canvasStyle = toCanvasStyle(value, info.GetIsolate())) {
        impl->setStrokeStyle(canvasStyle);
    } else {
        TOSTRING_VOID(V8StringResource<>, colorString, value);
        impl->setStrokeColor(colorString);
    }
}

void V8CanvasRenderingContext2D::fillStyleAttributeGetterCustom(const v8::PropertyCallbackInfo<v8::Value>& info)
{
    CanvasRenderingContext2D* impl = V8CanvasRenderingContext2D::toNative(info.Holder());
    v8SetReturnValue(info, toV8Object(impl->fillStyle(), info.Holder(), info.GetIsolate()));
}

void V8CanvasRenderingContext2D::fillStyleAttributeSetterCustom(v8::Local<v8::Value> value, const v8::PropertyCallbackInfo<void>& info)
{
    CanvasRenderingContext2D* impl = V8CanvasRenderingContext2D::toNative(info.Holder());
    if (RefPtrWillBeRawPtr<CanvasStyle> canvasStyle = toCanvasStyle(value, info.GetIsolate())) {
        impl->setFillStyle(canvasStyle);
    } else {
        TOSTRING_VOID(V8StringResource<>, colorString, value);
        impl->setFillColor(colorString);
    }
}

} // namespace blink
