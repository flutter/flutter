// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/css/parser/BisonCSSParser.h"

#include "sky/engine/core/css/MediaList.h"
#include "sky/engine/core/css/StyleRule.h"
#include "sky/engine/wtf/dtoa/utils.h"

#include <gtest/gtest.h>

namespace blink {

static void testMediaQuery(const char* expected, MediaQuerySet& querySet)
{
    const Vector<OwnPtr<MediaQuery> >& queryVector = querySet.queryVector();
    size_t queryVectorSize = queryVector.size();
    StringBuilder output;

    for (size_t i = 0; i < queryVectorSize; ) {
        String queryText = queryVector[i]->cssText();
        output.append(queryText);
        ++i;
        if (i >= queryVectorSize)
            break;
        output.appendLiteral(", ");
    }
    ASSERT_STREQ(expected, output.toString().ascii().data());
}

} // namespace blink
