/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#include "sky/engine/config.h"
#include "sky/engine/core/css/resolver/StyleResolverStats.h"

#include "sky/engine/wtf/text/CString.h"
#include "sky/engine/wtf/text/StringBuilder.h"

#define PERCENT(x, y) ((!y) ? 0 : (((x) * 100.0) / (y)))

namespace blink {

void StyleResolverStats::reset()
{
    sharedStyleLookups = 0;
    sharedStyleCandidates = 0;
    sharedStyleFound = 0;
    sharedStyleMissed = 0;
    sharedStyleRejectedByAttributeRules = 0;
    matchedPropertyApply = 0;
    matchedPropertyCacheHit = 0;
    matchedPropertyCacheInheritedHit = 0;
    matchedPropertyCacheAdded = 0;
}

String StyleResolverStats::report() const
{
    StringBuilder output;

    unsigned sharedStylesRejected = sharedStyleRejectedByAttributeRules;
    unsigned sharedStylesUsed = sharedStyleFound - sharedStylesRejected;

    output.appendLiteral("Style sharing:\n");
    output.append(String::format("  %u elements were added to the sharing candidate list.\n", sharedStyleCandidates));
    output.append(String::format("  %u calls were made to findSharedStyle, %u found a candidate to share with (%.2f%%).\n", sharedStyleLookups, sharedStyleFound, PERCENT(sharedStyleFound, sharedStyleLookups)));
    if (printMissedCandidateCount)
        output.append(String::format("  %u candidates could have matched but were not in the list when searching (%.2f%%).\n", sharedStyleMissed, PERCENT(sharedStyleMissed, sharedStyleLookups)));
    output.append(String::format("  %u of found styles were rejected (%.2f%%), %.2f%% by attribute rules.\n",
        sharedStylesRejected,
        PERCENT(sharedStylesRejected, sharedStyleFound),
        PERCENT(sharedStyleRejectedByAttributeRules, sharedStylesRejected)));
    output.append(String::format("  %u of found styles were used for sharing (%.2f%%).\n", sharedStylesUsed, PERCENT(sharedStylesUsed, sharedStyleFound)));
    output.append(String::format("  %.2f%% of calls to findSharedStyle returned a shared style.\n", PERCENT(sharedStylesUsed, sharedStyleLookups)));

    output.append('\n');

    output.appendLiteral("Matched property cache:\n");
    output.append(String::format("  %u calls to applyMatchedProperties, %u hit the cache (%.2f%%).\n", matchedPropertyApply, matchedPropertyCacheHit, PERCENT(matchedPropertyCacheHit, matchedPropertyApply)));
    output.append(String::format("  %u cache hits also shared the inherited style (%.2f%%).\n", matchedPropertyCacheInheritedHit, PERCENT(matchedPropertyCacheInheritedHit, matchedPropertyCacheHit)));
    output.append(String::format("  %u styles created in applyMatchedProperties were added to the cache (%.2f%%).\n", matchedPropertyCacheAdded, PERCENT(matchedPropertyCacheAdded, matchedPropertyApply)));

    return output.toString();
}

} // namespace blink
