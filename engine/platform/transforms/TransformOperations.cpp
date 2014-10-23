/*
 * Copyright (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008 Apple Inc. All rights reserved.
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

#include "config.h"
#include "platform/transforms/TransformOperations.h"

#include "platform/animation/AnimationUtilities.h"
#include "platform/geometry/FloatBox.h"
#include "platform/transforms/IdentityTransformOperation.h"
#include "platform/transforms/InterpolatedTransformOperation.h"
#include "platform/transforms/RotateTransformOperation.h"
#include <algorithm>

namespace blink {

TransformOperations::TransformOperations(bool makeIdentity)
{
    if (makeIdentity)
        m_operations.append(IdentityTransformOperation::create());
}

bool TransformOperations::operator==(const TransformOperations& o) const
{
    if (m_operations.size() != o.m_operations.size())
        return false;

    unsigned s = m_operations.size();
    for (unsigned i = 0; i < s; i++) {
        if (*m_operations[i] != *o.m_operations[i])
            return false;
    }

    return true;
}

bool TransformOperations::operationsMatch(const TransformOperations& other) const
{
    size_t numOperations = operations().size();
    // If the sizes of the function lists don't match, the lists don't match
    if (numOperations != other.operations().size())
        return false;

    // If the types of each function are not the same, the lists don't match
    for (size_t i = 0; i < numOperations; ++i) {
        if (!operations()[i]->isSameType(*other.operations()[i]))
            return false;
    }
    return true;
}

TransformOperations TransformOperations::blendByMatchingOperations(const TransformOperations& from, const double& progress) const
{
    TransformOperations result;

    unsigned fromSize = from.operations().size();
    unsigned toSize = operations().size();
    unsigned size = std::max(fromSize, toSize);
    for (unsigned i = 0; i < size; i++) {
        RefPtr<TransformOperation> fromOperation = (i < fromSize) ? from.operations()[i].get() : 0;
        RefPtr<TransformOperation> toOperation = (i < toSize) ? operations()[i].get() : 0;
        RefPtr<TransformOperation> blendedOperation = toOperation ? toOperation->blend(fromOperation.get(), progress) : (fromOperation ? fromOperation->blend(0, progress, true) : nullptr);
        if (blendedOperation)
            result.operations().append(blendedOperation);
        else {
            RefPtr<TransformOperation> identityOperation = IdentityTransformOperation::create();
            if (progress > 0.5)
                result.operations().append(toOperation ? toOperation : identityOperation);
            else
                result.operations().append(fromOperation ? fromOperation : identityOperation);
        }
    }

    return result;
}

TransformOperations TransformOperations::blendByUsingMatrixInterpolation(const TransformOperations& from, double progress) const
{
    TransformOperations result;
    result.operations().append(InterpolatedTransformOperation::create(from, *this, progress));
    return result;
}

TransformOperations TransformOperations::blend(const TransformOperations& from, double progress) const
{
    if (from == *this || (!from.size() && !size()))
        return *this;

    // If either list is empty, use blendByMatchingOperations which has special logic for this case.
    if (!from.size() || !size() || from.operationsMatch(*this))
        return blendByMatchingOperations(from, progress);

    return blendByUsingMatrixInterpolation(from, progress);
}

static void findCandidatesInPlane(double px, double py, double nz, double* candidates, int* numCandidates)
{
    // The angle that this point is rotated with respect to the plane nz
    double phi = atan2(px, py);

    *numCandidates = 4;
    candidates[0] = phi; // The element at 0deg (maximum x)

    for (int i = 1; i < *numCandidates; ++i)
        candidates[i] = candidates[i - 1] + M_PI_2; // every 90 deg
    if (nz < 0.f) {
        for (int i = 0; i < *numCandidates; ++i)
            candidates[i] *= -1;
    }
}

// This method returns the bounding box that contains the starting point,
// the ending point, and any of the extrema (in each dimension) found across
// the circle described by the arc. These are then filtered to points that
// actually reside on the arc.
static void boundingBoxForArc(const FloatPoint3D& point, const RotateTransformOperation& fromTransform, const RotateTransformOperation& toTransform, double minProgress, double maxProgress, FloatBox& box)
{
    double candidates[6];
    int numCandidates = 0;

    FloatPoint3D axis(fromTransform.axis());
    double fromDegrees = fromTransform.angle();
    double toDegrees = toTransform.angle();

    if (axis.dot(toTransform.axis()) < 0)
        toDegrees *= -1;

    fromDegrees  = blend(fromDegrees, toTransform.angle(), minProgress);
    toDegrees = blend(toDegrees, fromTransform.angle(), 1.0 - maxProgress);
    if (fromDegrees > toDegrees)
        std::swap(fromDegrees, toDegrees);

    TransformationMatrix fromMatrix;
    TransformationMatrix toMatrix;
    fromMatrix.rotate3d(fromTransform.x(), fromTransform.y(), fromTransform.z(), fromDegrees);
    toMatrix.rotate3d(fromTransform.x(), fromTransform.y(), fromTransform.z(), toDegrees);

    FloatPoint3D fromPoint = fromMatrix.mapPoint(point);
    FloatPoint3D toPoint = toMatrix.mapPoint(point);

    if (box.isEmpty())
        box.setOrigin(fromPoint);
    else
        box.expandTo(fromPoint);

    box.expandTo(toPoint);

    switch (fromTransform.type()) {
    case TransformOperation::RotateX:
        findCandidatesInPlane(point.y(), point.z(), fromTransform.x(), candidates, &numCandidates);
        break;
    case TransformOperation::RotateY:
        findCandidatesInPlane(point.z(), point.x(), fromTransform.y(), candidates, &numCandidates);
        break;
    case TransformOperation::RotateZ:
        findCandidatesInPlane(point.x(), point.y(), fromTransform.z(), candidates, &numCandidates);
        break;
    default:
        {
            FloatPoint3D normal = axis;
            if (normal.isZero())
                return;
            normal.normalize();
            FloatPoint3D origin;
            FloatPoint3D toPoint = point - origin;
            FloatPoint3D center = origin + normal * toPoint.dot(normal);
            FloatPoint3D v1 = point - center;
            if (v1.isZero())
                return;

            v1.normalize();
            FloatPoint3D v2 = normal.cross(v1);
            // v1 is the basis vector in the direction of the point.
            // i.e. with a rotation of 0, v1 is our +x vector.
            // v2 is a perpenticular basis vector of our plane (+y).

            // Take the parametric equation of a circle.
            // (x = r*cos(t); y = r*sin(t);
            // We can treat that as a circle on the plane v1xv2
            // From that we get the parametric equations for a circle on the
            // plane in 3d space of
            // x(t) = r*cos(t)*v1.x + r*sin(t)*v2.x + cx
            // y(t) = r*cos(t)*v1.y + r*sin(t)*v2.y + cy
            // z(t) = r*cos(t)*v1.z + r*sin(t)*v2.z + cz
            // taking the derivative of (x, y, z) and solving for 0 gives us our
            // maximum/minimum x, y, z values
            // x'(t) = r*cos(t)*v2.x - r*sin(t)*v1.x = 0
            // tan(t) = v2.x/v1.x
            // t = atan2(v2.x, v1.x) + n*M_PI;

            candidates[0] = atan2(v2.x(), v1.x());
            candidates[1] = candidates[0] + M_PI;
            candidates[2] = atan2(v2.y(), v1.y());
            candidates[3] = candidates[2] + M_PI;
            candidates[4] = atan2(v2.z(), v1.z());
            candidates[5] = candidates[4] + M_PI;
            numCandidates = 6;
        }
        break;
    }

    double minRadians = deg2rad(fromDegrees);
    double maxRadians = deg2rad(toDegrees);
    // Once we have the candidates, we now filter them down to ones that
    // actually live on the arc, rather than the entire circle.
    for (int i = 0; i < numCandidates; ++i) {
        double radians = candidates[i];

        while (radians < minRadians)
            radians += 2.0 * M_PI;
        while (radians > maxRadians)
            radians -= 2.0 * M_PI;
        if (radians < minRadians)
            continue;

        TransformationMatrix rotation;
        rotation.rotate3d(axis.x(), axis.y(), axis.z(), rad2deg(radians));
        box.expandTo(rotation.mapPoint(point));
    }
}

bool TransformOperations::blendedBoundsForBox(const FloatBox& box, const TransformOperations& from, const double& minProgress, const double& maxProgress, FloatBox* bounds) const
{

    int fromSize = from.operations().size();
    int toSize = operations().size();
    int size = std::max(fromSize, toSize);

    *bounds = box;
    for (int i = size - 1; i >= 0; i--) {
        RefPtr<TransformOperation> fromOperation = (i < fromSize) ? from.operations()[i] : nullptr;
        RefPtr<TransformOperation> toOperation = (i < toSize) ? operations()[i] : nullptr;
        if (fromOperation && fromOperation->type() == TransformOperation::None)
            fromOperation = nullptr;

        if (toOperation && toOperation->type() == TransformOperation::None)
            toOperation = nullptr;

        TransformOperation::OperationType interpolationType = toOperation ? toOperation->type() :
            fromOperation ? fromOperation->type() :
            TransformOperation::None;
        if (fromOperation && toOperation && !fromOperation->canBlendWith(*toOperation.get()))
            return false;

        switch (interpolationType) {
        case TransformOperation::Identity:
            bounds->expandTo(box);
            continue;
        case TransformOperation::Translate:
        case TransformOperation::TranslateX:
        case TransformOperation::TranslateY:
        case TransformOperation::TranslateZ:
        case TransformOperation::Translate3D:
        case TransformOperation::Scale:
        case TransformOperation::ScaleX:
        case TransformOperation::ScaleY:
        case TransformOperation::ScaleZ:
        case TransformOperation::Scale3D:
        case TransformOperation::Skew:
        case TransformOperation::SkewX:
        case TransformOperation::SkewY:
        case TransformOperation::Perspective:
            {
                RefPtr<TransformOperation> fromTransform;
                RefPtr<TransformOperation> toTransform;
                if (!toOperation) {
                    fromTransform = fromOperation->blend(toOperation.get(), 1-minProgress, false);
                    toTransform = fromOperation->blend(toOperation.get(), 1-maxProgress, false);
                } else {
                    fromTransform = toOperation->blend(fromOperation.get(), minProgress, false);
                    toTransform = toOperation->blend(fromOperation.get(), maxProgress, false);
                }
                if (!fromTransform || !toTransform)
                    continue;
                TransformationMatrix fromMatrix;
                TransformationMatrix toMatrix;
                fromTransform->apply(fromMatrix, FloatSize());
                toTransform->apply(toMatrix, FloatSize());
                FloatBox fromBox = *bounds;
                FloatBox toBox = *bounds;
                fromMatrix.transformBox(fromBox);
                toMatrix.transformBox(toBox);
                *bounds = fromBox;
                bounds->expandTo(toBox);
                continue;
            }
        case TransformOperation::Rotate: // This is also RotateZ
        case TransformOperation::Rotate3D:
        case TransformOperation::RotateX:
        case TransformOperation::RotateY:
            {
                RefPtr<RotateTransformOperation> identityRotation;
                const RotateTransformOperation* fromRotation = nullptr;
                const RotateTransformOperation* toRotation = nullptr;
                if (fromOperation) {
                    fromRotation = static_cast<const RotateTransformOperation*>(fromOperation.get());
                    if (fromRotation->axis().isZero())
                        fromRotation = nullptr;
                }

                if (toOperation) {
                    toRotation = static_cast<const RotateTransformOperation*>(toOperation.get());
                    if (toRotation->axis().isZero())
                        toRotation = nullptr;
                }

                double fromAngle;
                double toAngle;
                FloatPoint3D axis;
                if (!RotateTransformOperation::shareSameAxis(fromRotation, toRotation, &axis, &fromAngle, &toAngle)) {
                    return(false);
                }

                if (!fromRotation) {
                    identityRotation = RotateTransformOperation::create(axis.x(), axis.y(), axis.z(), 0, fromOperation ? fromOperation->type() : toOperation->type());
                    fromRotation = identityRotation.get();
                }

                if (!toRotation) {
                    if (!identityRotation)
                        identityRotation = RotateTransformOperation::create(axis.x(), axis.y(), axis.z(), 0, fromOperation ? fromOperation->type() : toOperation->type());
                    toRotation = identityRotation.get();
                }

                FloatBox fromBox = *bounds;
                bool first = true;
                for (size_t i = 0; i < 2; ++i) {
                    for (size_t j = 0; j < 2; ++j) {
                        for (size_t k = 0; k < 2; ++k) {
                            FloatBox boundsForArc;
                            FloatPoint3D corner(fromBox.x(), fromBox.y(), fromBox.z());
                            corner += FloatPoint3D(i * fromBox.width(), j * fromBox.height(), k * fromBox.depth());
                            boundingBoxForArc(corner, *fromRotation, *toRotation, minProgress, maxProgress, boundsForArc);
                            if (first) {
                                *bounds = boundsForArc;
                                first = false;
                            } else {
                                bounds->expandTo(boundsForArc);
                            }
                        }
                    }
                }
            }
            continue;
        case TransformOperation::None:
            continue;
        case TransformOperation::Matrix:
        case TransformOperation::Matrix3D:
        case TransformOperation::Interpolated:
            return(false);
        }
    }

    return true;
}

TransformOperations TransformOperations::add(const TransformOperations& addend) const
{
    TransformOperations result;
    result.m_operations = operations();
    result.m_operations.appendVector(addend.operations());
    return result;
}

} // namespace blink
