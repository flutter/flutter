/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2009 Apple Inc. All rights reserved.
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

#ifndef CSSHelper_h
#define CSSHelper_h

#include "wtf/Forward.h"

namespace blink {

// We always assume 96 CSS pixels in a CSS inch. This is the cold hard truth of the Web.
// At high DPI, we may scale a CSS pixel, but the ratio of the CSS pixel to the so-called
// "absolute" CSS length units like inch and pt is always fixed and never changes.
const double cssPixelsPerInch = 96;
const double cssPixelsPerCentimeter = cssPixelsPerInch / 2.54; // 2.54 cm/in
const double cssPixelsPerMillimeter = cssPixelsPerCentimeter / 10;
const double cssPixelsPerPoint = cssPixelsPerInch / 72;
const double cssPixelsPerPica = cssPixelsPerInch / 6;

} // namespace blink

#endif // CSSHelper_h
