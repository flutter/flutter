// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.ui.picker;

import android.content.Context;

import org.chromium.ui.R;

public class WeekPickerDialog extends TwoFieldDatePickerDialog {

    /**
     * @param context The context the dialog is to run in.
     * @param callBack How the parent is notified that the date is set.
     * @param year The initial year of the dialog.
     * @param weekOfYear The initial week of the dialog.
     */
    public WeekPickerDialog(Context context,
             OnValueSetListener callBack,
            int year, int weekOfYear,
            double minValue, double maxValue) {
        this(context, 0, callBack, year, weekOfYear, minValue, maxValue);
    }

    /**
     * @param context The context the dialog is to run in.
     * @param theme the theme to apply to this dialog
     * @param callBack How the parent is notified that the date is set.
     * @param year The initial year of the dialog.
     * @param weekOfYear The initial week of the dialog.
     */
    public WeekPickerDialog(Context context,
            int theme,
             OnValueSetListener callBack,
            int year,
            int weekOfYear,
            double minValue, double maxValue) {
        super(context, theme, callBack, year, weekOfYear, minValue, maxValue);
        setTitle(R.string.week_picker_dialog_title);
    }

    @Override
    protected TwoFieldDatePicker createPicker(Context context, double minValue, double maxValue) {
        return new WeekPicker(context, minValue, maxValue);
    }

    /**
     * Gets the {@link WeekPicker} contained in this dialog.
     *
     * @return The calendar view.
     */
    public WeekPicker getWeekPicker() {
        return (WeekPicker) mPicker;
    }
}
