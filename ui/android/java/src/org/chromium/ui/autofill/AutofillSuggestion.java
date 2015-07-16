// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.ui.autofill;

import org.chromium.ui.DropdownItem;

/**
 * Autofill suggestion container used to store information needed for each Autofill popup entry.
 */
public class AutofillSuggestion implements DropdownItem {
    private final String mLabel;
    private final String mSublabel;
    private final int mSuggestionId;

    /**
     * Constructs a Autofill suggestion container.
     * @param name The name of the Autofill suggestion.
     * @param label The describing label of the Autofill suggestion.
     * @param suggestionId The type of suggestion.
     */
    public AutofillSuggestion(String name, String label, int suggestionId) {
        mLabel = name;
        mSublabel = label;
        mSuggestionId = suggestionId;
    }

    @Override
    public String getLabel() {
        return mLabel;
    }

    @Override
    public String getSublabel() {
        return mSublabel;
    }

    @Override
    public boolean isEnabled() {
        return true;
    }

    @Override
    public boolean isGroupHeader() {
        return false;
    }

    public int getSuggestionId() {
        return mSuggestionId;
    }
}
