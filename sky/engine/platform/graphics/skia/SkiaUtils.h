/*
 * Copyright (c) 2006,2007,2008, Google Inc. All rights reserved.
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

// All of the functions in this file should move to new homes and this file should be deleted.

#ifndef SKY_ENGINE_PLATFORM_GRAPHICS_SKIA_SKIAUTILS_H_
#define SKY_ENGINE_PLATFORM_GRAPHICS_SKIA_SKIAUTILS_H_

#include "sky/engine/platform/PlatformExport.h"
#include "sky/engine/platform/geometry/FloatRect.h"
#include "sky/engine/platform/graphics/Color.h"
#include "sky/engine/platform/graphics/GraphicsTypes.h"
#include "sky/engine/platform/transforms/AffineTransform.h"
#include "sky/engine/wtf/MathExtras.h"
#include "third_party/skia/include/core/SkMatrix.h"
#include "third_party/skia/include/core/SkPaint.h"
#include "third_party/skia/include/core/SkPath.h"
#include "third_party/skia/include/core/SkRefCnt.h"
#include "third_party/skia/include/core/SkXfermode.h"

namespace blink {

class GraphicsContext;

SkXfermode::Mode PLATFORM_EXPORT WebCoreCompositeToSkiaComposite(CompositeOperator, WebBlendMode = WebBlendModeNormal);

// move this guy into SkColor.h
SkColor SkPMColorToColor(SkPMColor);

inline SkFilterQuality WebCoreInterpolationQualityToSkFilterQuality(InterpolationQuality quality)
{
    // FIXME: this reflects existing client mappings, but should probably
    // be expanded to map higher level interpolations more accurately.
    return quality != InterpolationNone ? kLow_SkFilterQuality : kNone_SkFilterQuality;
}

// Skia has problems when passed infinite, etc floats, filter them to 0.
inline SkScalar WebCoreFloatToSkScalar(float f)
{
    return SkFloatToScalar(std::isfinite(f) ? f : 0);
}

inline SkScalar WebCoreDoubleToSkScalar(double d)
{
    return SkDoubleToScalar(std::isfinite(d) ? d : 0);
}

inline SkRect WebCoreFloatRectToSKRect(const FloatRect& rect)
{
    return SkRect::MakeLTRB(SkFloatToScalar(rect.x()), SkFloatToScalar(rect.y()),
        SkFloatToScalar(rect.maxX()), SkFloatToScalar(rect.maxY()));
}

inline bool WebCoreFloatNearlyEqual(float a, float b)
{
    return SkScalarNearlyEqual(WebCoreFloatToSkScalar(a), WebCoreFloatToSkScalar(b));
}

inline SkPath::FillType WebCoreWindRuleToSkFillType(WindRule rule)
{
    return static_cast<SkPath::FillType>(rule);
}

// Determine if a given WebKit point is contained in a path
bool PLATFORM_EXPORT SkPathContainsPoint(const SkPath&, const FloatPoint&, SkPath::FillType);

SkMatrix PLATFORM_EXPORT affineTransformToSkMatrix(const AffineTransform&);

bool nearlyIntegral(float value);

InterpolationQuality limitInterpolationQuality(const GraphicsContext*, InterpolationQuality resampling);

InterpolationQuality computeInterpolationQuality(
    const SkMatrix&,
    float srcWidth,
    float srcHeight,
    float destWidth,
    float destHeight,
    bool isDataComplete = true);

bool shouldDrawAntiAliased(const GraphicsContext*, const SkRect& destRect);

// Skia's smart pointer APIs are preferable over their legacy raw pointer counterparts.
// The following helpers ensure interoperability between Skia's SkRefCnt wrapper sk_sp<T> and
// Blink's RefPtr<T>/PassRefPtr<T>.
//
//   - fromSkSp(sk_sp<T>):       adopts an sk_sp into a PassRefPtr (to be used when transferring
//                               ownership from Skia to Blink).
//   - toSkSp(PassRefPtr<T>):    releases a PassRefPtr into a sk_sp (to be used when transferring
//                               ownership from Blink to Skia).
//   - toSkSp(const RefPtr<T>&): shares a RefPtr as a new sk_sp (to be used when sharing
//                               ownership).
//
// General guidelines
//
// When receiving ref counted objects from Skia:
//
//   1) use sk_sp-based Skia factories if available (e.g. SkShader::MakeFoo() instead of
//      SkShader::CreateFoo())
//
//   2) use sk_sp<T> locals for temporary objects (to be immediately transferred back to Skia)
//
//   3) use RefPtr<T>/PassRefPtr<T> for objects to be retained in Blink, use
//      fromSkSp(sk_sp<T>) to convert
//
// When passing ref counted objects to Skia:
//
//   1) use sk_sk-based Skia APIs when available (e.g. SkPaint::setShader(sk_sp<SkShader>)
//      instead of SkPaint::setShader(SkShader*))
//
//   2) if the object ownership is being passed to Skia, use std::move(sk_sp<T>) or
//      toSkSp(PassRefPtr<T>) to transfer without refcount churn
//
//   3) if the object ownership is shared with Skia (Blink retains a reference), use
//      toSkSp(const RefPtr<T>&)
//
// Example (creating a SkShader and setting it on SkPaint):
//
// a) legacy/old style
//
//     RefPtr<SkShader> shader = adoptRef(SkShader::CreateFoo(...));
//     paint.setShader(shader.get());
//
//  (Note: the legacy approach introduces refcount churn as Skia grabs a ref while Blink is
//   temporarily holding on to its own)
//
// b) new style, ownership transferred
//
//     // using Skia smart pointer locals
//     sk_sp<SkShader> shader = SkShader::MakeFoo(...);
//     paint.setShader(std::move(shader));
//
//     // using Blink smart pointer locals
//     RefPtr<SkShader> shader = fromSkSp(SkShader::MakeFoo(...));
//     paint.setShader(toSkSp(shader.release());
//
//     // using no locals
//     paint.setShader(SkShader::MakeFoo(...));
//
// c) new style, shared ownership
//
//     RefPtr<SkShader> shader = fromSkSp(SkShader::MakeFoo(...));
//     paint.setShader(toSkSp(shader));
//
template <typename T> PassRefPtr<T> fromSkSp(sk_sp<T> sp)
{
    return adoptRef(sp.release());
}

template <typename T> sk_sp<T> toSkSp(PassRefPtr<T> ref)
{
    return sk_sp<T>(ref.leakRef());
}

template <typename T> sk_sp<T> toSkSp(const RefPtr<T>& ref)
{
    return toSkSp(PassRefPtr<T>(ref));
}

} // namespace blink

#endif  // SKY_ENGINE_PLATFORM_GRAPHICS_SKIA_SKIAUTILS_H_
