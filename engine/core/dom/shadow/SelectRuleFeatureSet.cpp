/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
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
#include "sky/engine/core/dom/shadow/SelectRuleFeatureSet.h"

#include "sky/engine/core/css/CSSSelector.h"

#include "sky/engine/wtf/BitVector.h"

namespace blink {

SelectRuleFeatureSet::SelectRuleFeatureSet()
{
}

void SelectRuleFeatureSet::add(const SelectRuleFeatureSet& featureSet)
{
    m_cssRuleFeatureSet.add(featureSet.m_cssRuleFeatureSet);
}

void SelectRuleFeatureSet::clear()
{
    m_cssRuleFeatureSet.clear();
}

void SelectRuleFeatureSet::collectFeaturesFromSelector(const CSSSelector& selector)
{
    m_cssRuleFeatureSet.collectFeaturesFromSelector(selector);
}

bool SelectRuleFeatureSet::checkSelectorsForClassChange(const SpaceSplitString& changedClasses) const
{
    unsigned changedSize = changedClasses.size();
    for (unsigned i = 0; i < changedSize; ++i) {
        if (hasSelectorForClass(changedClasses[i]))
            return true;
    }
    return false;
}

bool SelectRuleFeatureSet::checkSelectorsForClassChange(const SpaceSplitString& oldClasses, const SpaceSplitString& newClasses) const
{
    if (!oldClasses.size())
        return checkSelectorsForClassChange(newClasses);

    // Class vectors tend to be very short. This is faster than using a hash table.
    BitVector remainingClassBits;
    remainingClassBits.ensureSize(oldClasses.size());

    for (unsigned i = 0; i < newClasses.size(); ++i) {
        bool found = false;
        for (unsigned j = 0; j < oldClasses.size(); ++j) {
            if (newClasses[i] == oldClasses[j]) {
                // Mark each class that is still in the newClasses so we can skip doing
                // an n^2 search below when looking for removals. We can't break from
                // this loop early since a class can appear more than once.
                remainingClassBits.quickSet(j);
                found = true;
            }
        }
        // Class was added.
        if (!found) {
            if (hasSelectorForClass(newClasses[i]))
                return true;
        }
    }

    for (unsigned i = 0; i < oldClasses.size(); ++i) {
        if (remainingClassBits.quickGet(i))
            continue;

        // Class was removed.
        if (hasSelectorForClass(oldClasses[i]))
            return true;
    }
    return false;
}

}

