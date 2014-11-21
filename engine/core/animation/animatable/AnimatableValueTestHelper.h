/*
 * Copyright (c) 2013, Google Inc. All rights reserved.
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

/**
 * Make testing with gtest and gmock nicer by adding pretty print and other
 * helper functions.
 */

#ifndef AnimatableValueTestHelper_h
#define AnimatableValueTestHelper_h

#include "sky/engine/core/animation/animatable/AnimatableClipPathOperation.h"
#include "sky/engine/core/animation/animatable/AnimatableColor.h"
#include "sky/engine/core/animation/animatable/AnimatableImage.h"
#include "sky/engine/core/animation/animatable/AnimatableNeutral.h"
#include "sky/engine/core/animation/animatable/AnimatableRepeatable.h"
#include "sky/engine/core/animation/animatable/AnimatableShapeValue.h"
#include "sky/engine/core/animation/animatable/AnimatableTransform.h"
#include "sky/engine/core/animation/animatable/AnimatableUnknown.h"
#include "sky/engine/core/animation/animatable/AnimatableValue.h"

#include "sky/engine/core/css/CSSValueTestHelper.h"

// FIXME: Move to something like core/wtf/WTFTestHelpers.h
// Compares the targets of two RefPtrs for equality.
// (Objects still need an operator== defined for this to work).
#define EXPECT_REFV_EQ(a, b) EXPECT_EQ(*(a.get()), *(b.get()))

namespace blink {

bool operator==(const AnimatableValue&, const AnimatableValue&);

void PrintTo(const AnimatableClipPathOperation&, ::std::ostream*);
void PrintTo(const AnimatableColor&, ::std::ostream*);
void PrintTo(const AnimatableImage&, ::std::ostream*);
void PrintTo(const AnimatableNeutral&, ::std::ostream*);
void PrintTo(const AnimatableRepeatable&, ::std::ostream*);
void PrintTo(const AnimatableShapeValue&, ::std::ostream*);
void PrintTo(const AnimatableTransform&, ::std::ostream*);
void PrintTo(const AnimatableUnknown&, ::std::ostream*);
void PrintTo(const AnimatableValue&, ::std::ostream*);

} // namespace blink

#endif
