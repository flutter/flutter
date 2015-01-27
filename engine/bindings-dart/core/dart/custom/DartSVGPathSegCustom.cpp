// Copyright 2011, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//    * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//    * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#include "config.h"

#include "bindings/core/dart/DartSVGPathSeg.h"

#include "bindings/core/dart/DartDOMWrapper.h"
#include "bindings/core/dart/DartSVGPathSegArcAbs.h"
#include "bindings/core/dart/DartSVGPathSegArcRel.h"
#include "bindings/core/dart/DartSVGPathSegClosePath.h"
#include "bindings/core/dart/DartSVGPathSegCurvetoCubicAbs.h"
#include "bindings/core/dart/DartSVGPathSegCurvetoCubicRel.h"
#include "bindings/core/dart/DartSVGPathSegCurvetoCubicSmoothAbs.h"
#include "bindings/core/dart/DartSVGPathSegCurvetoCubicSmoothRel.h"
#include "bindings/core/dart/DartSVGPathSegCurvetoQuadraticAbs.h"
#include "bindings/core/dart/DartSVGPathSegCurvetoQuadraticRel.h"
#include "bindings/core/dart/DartSVGPathSegCurvetoQuadraticSmoothAbs.h"
#include "bindings/core/dart/DartSVGPathSegCurvetoQuadraticSmoothRel.h"
#include "bindings/core/dart/DartSVGPathSegLinetoAbs.h"
#include "bindings/core/dart/DartSVGPathSegLinetoHorizontalAbs.h"
#include "bindings/core/dart/DartSVGPathSegLinetoHorizontalRel.h"
#include "bindings/core/dart/DartSVGPathSegLinetoRel.h"
#include "bindings/core/dart/DartSVGPathSegLinetoVerticalAbs.h"
#include "bindings/core/dart/DartSVGPathSegLinetoVerticalRel.h"
#include "bindings/core/dart/DartSVGPathSegMovetoAbs.h"
#include "bindings/core/dart/DartSVGPathSegMovetoRel.h"
#include "bindings/core/dart/DartWindow.h"


namespace blink {

Dart_Handle DartSVGPathSeg::createWrapper(DartDOMData* domData, SVGPathSeg* value)
{
    if (!value)
        return Dart_Null();
    switch (value->pathSegType()) {
    case SVGPathSeg::PATHSEG_CLOSEPATH:
        return DartSVGPathSegClosePath::createWrapper(domData, static_cast<SVGPathSegClosePath*>(value));
    case SVGPathSeg::PATHSEG_MOVETO_ABS:
        return DartSVGPathSegMovetoAbs::createWrapper(domData, static_cast<SVGPathSegMovetoAbs*>(value));
    case SVGPathSeg::PATHSEG_MOVETO_REL:
        return DartSVGPathSegMovetoRel::createWrapper(domData, static_cast<SVGPathSegMovetoRel*>(value));
    case SVGPathSeg::PATHSEG_LINETO_ABS:
        return DartSVGPathSegLinetoAbs::createWrapper(domData, static_cast<SVGPathSegLinetoAbs*>(value));
    case SVGPathSeg::PATHSEG_LINETO_REL:
        return DartSVGPathSegLinetoRel::createWrapper(domData, static_cast<SVGPathSegLinetoRel*>(value));
    case SVGPathSeg::PATHSEG_CURVETO_CUBIC_ABS:
        return DartSVGPathSegCurvetoCubicAbs::createWrapper(domData, static_cast<SVGPathSegCurvetoCubicAbs*>(value));
    case SVGPathSeg::PATHSEG_CURVETO_CUBIC_REL:
        return DartSVGPathSegCurvetoCubicRel::createWrapper(domData, static_cast<SVGPathSegCurvetoCubicRel*>(value));
    case SVGPathSeg::PATHSEG_CURVETO_QUADRATIC_ABS:
        return DartSVGPathSegCurvetoQuadraticAbs::createWrapper(domData, static_cast<SVGPathSegCurvetoQuadraticAbs*>(value));
    case SVGPathSeg::PATHSEG_CURVETO_QUADRATIC_REL:
        return DartSVGPathSegCurvetoQuadraticRel::createWrapper(domData, static_cast<SVGPathSegCurvetoQuadraticRel*>(value));
    case SVGPathSeg::PATHSEG_ARC_ABS:
        return DartSVGPathSegArcAbs::createWrapper(domData, static_cast<SVGPathSegArcAbs*>(value));
    case SVGPathSeg::PATHSEG_ARC_REL:
        return DartSVGPathSegArcRel::createWrapper(domData, static_cast<SVGPathSegArcRel*>(value));
    case SVGPathSeg::PATHSEG_LINETO_HORIZONTAL_ABS:
        return DartSVGPathSegLinetoHorizontalAbs::createWrapper(domData, static_cast<SVGPathSegLinetoHorizontalAbs*>(value));
    case SVGPathSeg::PATHSEG_LINETO_HORIZONTAL_REL:
        return DartSVGPathSegLinetoHorizontalRel::createWrapper(domData, static_cast<SVGPathSegLinetoHorizontalRel*>(value));
    case SVGPathSeg::PATHSEG_LINETO_VERTICAL_ABS:
        return DartSVGPathSegLinetoVerticalAbs::createWrapper(domData, static_cast<SVGPathSegLinetoVerticalAbs*>(value));
    case SVGPathSeg::PATHSEG_LINETO_VERTICAL_REL:
        return DartSVGPathSegLinetoVerticalRel::createWrapper(domData, static_cast<SVGPathSegLinetoVerticalRel*>(value));
    case SVGPathSeg::PATHSEG_CURVETO_CUBIC_SMOOTH_ABS:
        return DartSVGPathSegCurvetoCubicSmoothAbs::createWrapper(domData, static_cast<SVGPathSegCurvetoCubicSmoothAbs*>(value));
    case SVGPathSeg::PATHSEG_CURVETO_CUBIC_SMOOTH_REL:
        return DartSVGPathSegCurvetoCubicSmoothRel::createWrapper(domData, static_cast<SVGPathSegCurvetoCubicSmoothRel*>(value));
    case SVGPathSeg::PATHSEG_CURVETO_QUADRATIC_SMOOTH_ABS:
        return DartSVGPathSegCurvetoQuadraticSmoothAbs::createWrapper(domData, static_cast<SVGPathSegCurvetoQuadraticSmoothAbs*>(value));
    case SVGPathSeg::PATHSEG_CURVETO_QUADRATIC_SMOOTH_REL:
        return DartSVGPathSegCurvetoQuadraticSmoothRel::createWrapper(domData, static_cast<SVGPathSegCurvetoQuadraticSmoothRel*>(value));
    }
    ASSERT_NOT_REACHED();
    return Dart_Null();
}

}
