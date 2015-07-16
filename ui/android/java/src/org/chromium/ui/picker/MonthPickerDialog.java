// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.ui.picker;

import android.content.Context;

import org.chromium.ui.R;

public class MonthPickerDialog extends TwoFieldDatePickerDialog {

    /**
     * @param context The context the dialog is to run in.
     * @param callBack How the parent is notified that the date is set.
     * @param year The initial year of the dialog.
     * @param monthOfYear The initial month of the dialog.
     */
    public MonthPickerDialog(Context context,  OnValueSetListener callBack,
            int year, int monthOfYear, double minMonth, double maxMonth) {
        super(context, callBack, year, monthOfYear, minMonth, maxMonth);
        setTitle(R.string.month_picker_dialog_title);
    }

    @Override
    protected TwoFieldDatePicker createPicker(Context context, double minValue, double maxValue) {
        return new MonthPicker(context, minValue, maxValue);
    }

    /**
     * Gets the {@link MonthPicker} contained in this dialog.
     *
     * @return The calendar view.
     */
    public MonthPicker getMonthPicker() {
        return (MonthPicker) mPicker;
    }
}
