// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.ui;

/**
 * Dropdown item interface used to access all the information needed to show the item.
 */
public interface DropdownItem {
    /**
     * Returns the label that should be shown in the dropdown.
     */
    String getLabel();
    /**
     * Returns the sublabel that should be shown in the dropdown.
     */
    String getSublabel();
    /**
     * Returns true if the item should be enabled in the dropdown.
     */
    boolean isEnabled();
    /**
     * Returns true if the item should be a group header in the dropdown.
     */
    boolean isGroupHeader();
}
