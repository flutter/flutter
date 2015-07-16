// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.ui.picker;

import android.content.Context;
import android.content.DialogInterface;
import android.widget.DatePicker;

/**
 * The behavior of the DatePickerDialog changed after JellyBean so it now calls
 * OndateSetListener.onDateSet() even when the dialog is dismissed (e.g. back button, tap
 * outside). This class will call the listener instead of the DatePickerDialog only when the
 * BUTTON_POSITIVE has been clicked.
 */
class ChromeDatePickerDialog extends android.app.DatePickerDialog {
    private final OnDateSetListener mCallBack;

    public ChromeDatePickerDialog(Context context,
            OnDateSetListener callBack,
            int year,
            int monthOfYear,
            int dayOfMonth) {
        super(context, 0, callBack, year, monthOfYear, dayOfMonth);
        mCallBack = callBack;
    }

    /**
     * The superclass DatePickerDialog has null for OnDateSetListener so we need to call the
     * listener manually.
     */
    @Override
    public void onClick(DialogInterface dialog, int which) {
        if (which == BUTTON_POSITIVE && mCallBack != null) {
            DatePicker datePicker = getDatePicker();
            datePicker.clearFocus();
            mCallBack.onDateSet(datePicker, datePicker.getYear(),
                    datePicker.getMonth(), datePicker.getDayOfMonth());
        }
    }
}
