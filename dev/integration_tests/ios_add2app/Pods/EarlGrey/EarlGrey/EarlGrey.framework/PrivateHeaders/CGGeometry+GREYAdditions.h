//
// Copyright 2016 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#include <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

#pragma mark - Constants

/**
 *  Value used to denote a null CGPoint.
 */
extern const CGPoint GREYCGPointNull;

#pragma mark - CGVector

/**
 *  @return The scalar length of @c vector.
 */
CGFloat CGVectorLength(CGVector vector);

/**
 *  @return The the vector obtained by scaling the given @c vector by the given @c scale amount.
 */
CGVector CGVectorScale(CGVector vector, CGFloat scale);

/**
 *  Creates a vector with the given end points and optionally normalizes it if @c normalize is
 *  @c YES.
 *
 *  @param startPoint Start point for the vector.
 *  @param endPoint   End point for the vector.
 *  @param normalize  A @c BOOL indicating whether to normalize (@c YES) or not (@c NO).
 *
 *  @return A vector with the given end points and optionally normalized if @c normalize is
 *          @c YES.
 */
CGVector CGVectorFromEndPoints(CGPoint startPoint, CGPoint endPoint, BOOL normalize);

#pragma mark - CGPoint

/**
 *  Adds the corresponding coordinates of the given @c vector and @c point and returns the result as
 *  a CGPoint.
 *
 *  @param point  The point to add.
 *  @param vector The vector to add.
 *
 *  @return A point with corresponding coordinates of the given @c point and @c vector added.
 */
CGPoint CGPointAddVector(CGPoint point, CGVector vector);

/**
 *  @return The center of the provided @c rect.
 */
CGPoint CGRectCenter(CGRect rect);

/**
 *  Multiplies both the coordinates of the given @c inPoint by the given @c amount and returns
 *  the resulting point.
 *
 *  @param inPoint The input point to multiply.
 *  @param amount  The amount to multiply with.
 *
 *  @return The point obtained by multiplying the given @c inPoint and the given @c amount.
 */
CGPoint CGPointMultiply(CGPoint inPoint, double amount);

/**
 *  @return The point obtained by converting @c pointToConvertToPixel from points to pixels as per
 *          the screen scale.
 */
CGPoint CGPointToPixel(CGPoint positionInPoints);

/**
 *  @return The point obtained by converting @c pixelToConvertToPoint from pixels to points as per
 *          the screen scale.
 */
CGPoint CGPixelToPoint(CGPoint positionInPixels);

/**
 *  @return The point obtained after rounding the coordinates of the given @c cgpointInPoints to
 *          the nearest whole pixel and then to points.
 */
CGPoint CGPointAfterRemovingFractionalPixels(CGPoint cgpointInPoints);

/**
 *  @return The point obtained by converting the given @c pointInFixed from fixed to variable
 *          coordinate system.
 */
CGPoint CGPointFixedToVariable(CGPoint pointInFixed);

/**
 *  @return The point obtained by converting the given @c pointInVariable from variable to fixed
 *          coordinate system.
 */
CGPoint CGPointVariableToFixed(CGPoint pointInVariable);

/**
 *  @return @c YES if the given @c point represents an null point, @c NO otherwise.
 */
BOOL CGPointIsNull(CGPoint point);

#pragma mark - CGFloat

/**
 *  @return The value obtained by rounding the given @c floatInPoints to the nearest whole pixel
 *          and converting it to points as per the screen scale.
 */
CGFloat CGFloatAfterRemovingFractionalPixels(CGFloat floatInPoints);

#pragma mark - CGRect

/**
 *  @return The area of the given @c rect.
 */
double CGRectArea(CGRect rect);

/**
 *  Scales the given rectangle @c inRect, by a factor of the given @c amount and then translates
 *  the origin by a factor of @c amount. This is same as multiplying x, y, width and height of the
 *  given rectangle by the given @c amount.
 *
 *  @param inRect The rectangle to be scaled and translated.
 *  @param amount The amount by which to scale (and the factor by which to translate).
 *
 *  @return The scaled and translated rectangle.
 */
CGRect CGRectScaleAndTranslate(CGRect inRect, double amount);

/**
 *  @return The rect obtained by converting the given @c rectInPoints from points to pixels as per
 *          the screen scale.
 */
CGRect CGRectPointToPixel(CGRect rectInPoints);

/**
 *  @return The rect obtained by converting the given @c rectInPoints from pixels to points as
 *          per the screen scale.
 */
CGRect CGRectPixelToPoint(CGRect rectInPixel);

/**
 *  Starting with iOS 8.0 window and screen coordinates rotates with the the app's interface
 *  orientation. This method converts the given rect in fixed coordinate space to an oriented rect
 *  matching the current app orientation.
 *
 *  @param rectInFixedCoordinates The rect in fixed coordinates to be transformed to variable
 *                                coordinates.
 *
 *  @return The rect obtained by converting the given @c rectInFixedCoordinates from fixed screen
 *          coordinates to variable screen coordinates.
 */
CGRect CGRectFixedToVariableScreenCoordinates(CGRect rectInFixedCoordinates);

/**
 *  Starting with iOS 8.0 window and screen coordinates rotates with the the app's interface
 *  orientation. This method converts the given rect in variable coordinate space to fixed
 *  coordinates.
 *
 *  @param rectInVariableCoordinates The rect in variable coordinates to be transformed to fixed
 *                                   coordinates.
 *
 *  @return The rect obtained by converting the given @c rectInVariableCoordinates from variable
 *          screen coordinates to fixed screen coordinates.
 */
CGRect CGRectVariableToFixedScreenCoordinates(CGRect rectInVariableCoordinates);

/**
 *  Return the intersection of @c rect1 and @c rect2. The built-in function can produce floating
 *  errors on 32-bit platform (i.e. iphone 5), which results in a bigger rectangle than both
 *  sources. This will remove the errors by forcing the resulting rectangle to be no greater than
 *  the sources.
 *
 *  @param rect1 The first source rectangle.
 *  @param rect2 The second source rectangle.
 *
 *  @return A rectangle that represents the intersection of the two specified rectangles. If the two
 *          rectangles do not intersect, returns the null rectangle. To check for this condition,
 *          use CGRectIsNull.
 */
CGRect CGRectIntersectionStrict(CGRect rect1, CGRect rect2);

/**
 *  Normalizes @c rectInPixels to the largest rectangle that is within rectInPixels and
 *  pixel-boundary aligned. If the fractional part of height or width are > 0.5, they are rounded up
 *  otherwise rounded down.
 *
 *  @param rectInPixels A rect in pixel coordinates.
 *
 *  @return The normalized rect.
 */
CGRect CGRectIntegralInside(CGRect rectInPixels);

#pragma mark - CGAffineTransform

/**
 *  Returns the transform required for transforming from fixed coordinate system (iOS 7 and below)
 *  to variable coordinate system.
 *
 *  @remark This method is only applicable on iOS 7 and below as the later OSes use variable
 *          coordinate system by default.
 *
 *  @param statusBarOrientation A status bar orientation in fixed coordinate system.
 *
 *  @return The transformed status bar orientation for variable coordinate system.
 */
CGAffineTransform CGAffineTransformForFixedToVariable(UIInterfaceOrientation statusBarOrientation);
