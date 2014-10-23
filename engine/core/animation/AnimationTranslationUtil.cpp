/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"

#include "core/animation/AnimationTranslationUtil.h"

#include "platform/graphics/filters/FilterOperations.h"
#include "platform/graphics/filters/SkiaImageFilterBuilder.h"
#include "platform/transforms/InterpolatedTransformOperation.h"
#include "platform/transforms/Matrix3DTransformOperation.h"
#include "platform/transforms/MatrixTransformOperation.h"
#include "platform/transforms/PerspectiveTransformOperation.h"
#include "platform/transforms/RotateTransformOperation.h"
#include "platform/transforms/ScaleTransformOperation.h"
#include "platform/transforms/SkewTransformOperation.h"
#include "platform/transforms/TransformOperations.h"
#include "platform/transforms/TransformationMatrix.h"
#include "platform/transforms/TranslateTransformOperation.h"
#include "public/platform/WebTransformOperations.h"

namespace blink {

void toWebTransformOperations(const TransformOperations& transformOperations, WebTransformOperations* webTransformOperations)
{
    // We need to do a deep copy the transformOperations may contain ref pointers to TransformOperation objects.
    for (size_t j = 0; j < transformOperations.size(); ++j) {
        switch (transformOperations.operations()[j]->type()) {
        case TransformOperation::ScaleX:
        case TransformOperation::ScaleY:
        case TransformOperation::ScaleZ:
        case TransformOperation::Scale3D:
        case TransformOperation::Scale: {
            ScaleTransformOperation* transform = static_cast<ScaleTransformOperation*>(transformOperations.operations()[j].get());
            webTransformOperations->appendScale(transform->x(), transform->y(), transform->z());
            break;
        }
        case TransformOperation::TranslateX:
        case TransformOperation::TranslateY:
        case TransformOperation::TranslateZ:
        case TransformOperation::Translate3D:
        case TransformOperation::Translate: {
            TranslateTransformOperation* transform = static_cast<TranslateTransformOperation*>(transformOperations.operations()[j].get());
            ASSERT(transform->x().isFixed() && transform->y().isFixed());
            webTransformOperations->appendTranslate(transform->x().value(), transform->y().value(), transform->z());
            break;
        }
        case TransformOperation::RotateX:
        case TransformOperation::RotateY:
        case TransformOperation::Rotate3D:
        case TransformOperation::Rotate: {
            RotateTransformOperation* transform = static_cast<RotateTransformOperation*>(transformOperations.operations()[j].get());
            webTransformOperations->appendRotate(transform->x(), transform->y(), transform->z(), transform->angle());
            break;
        }
        case TransformOperation::SkewX:
        case TransformOperation::SkewY:
        case TransformOperation::Skew: {
            SkewTransformOperation* transform = static_cast<SkewTransformOperation*>(transformOperations.operations()[j].get());
            webTransformOperations->appendSkew(transform->angleX(), transform->angleY());
            break;
        }
        case TransformOperation::Matrix: {
            MatrixTransformOperation* transform = static_cast<MatrixTransformOperation*>(transformOperations.operations()[j].get());
            TransformationMatrix m = transform->matrix();
            webTransformOperations->appendMatrix(TransformationMatrix::toSkMatrix44(m));
            break;
        }
        case TransformOperation::Matrix3D: {
            Matrix3DTransformOperation* transform = static_cast<Matrix3DTransformOperation*>(transformOperations.operations()[j].get());
            TransformationMatrix m = transform->matrix();
            webTransformOperations->appendMatrix(TransformationMatrix::toSkMatrix44(m));
            break;
        }
        case TransformOperation::Perspective: {
            PerspectiveTransformOperation* transform = static_cast<PerspectiveTransformOperation*>(transformOperations.operations()[j].get());
            webTransformOperations->appendPerspective(transform->perspective());
            break;
        }
        case TransformOperation::Interpolated: {
            TransformationMatrix m;
            transformOperations.operations()[j]->apply(m, FloatSize());
            webTransformOperations->appendMatrix(TransformationMatrix::toSkMatrix44(m));
            break;
        }
        case TransformOperation::Identity:
            webTransformOperations->appendIdentity();
            break;
        case TransformOperation::None:
            // Do nothing.
            break;
        } // switch
    } // for each operation
}

void toWebFilterOperations(const FilterOperations& inOperations, WebFilterOperations* outOperations)
{
    SkiaImageFilterBuilder builder;
    FilterOutsets outsets = inOperations.outsets();
    builder.setCropOffset(FloatSize(outsets.left(), outsets.top()));
    builder.buildFilterOperations(inOperations, outOperations);
}

} // namespace blink
