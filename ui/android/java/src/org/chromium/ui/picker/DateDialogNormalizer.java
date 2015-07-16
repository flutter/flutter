// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.ui.picker;

import android.widget.DatePicker;
import android.widget.DatePicker.OnDateChangedListener;

import java.util.Calendar;
import java.util.TimeZone;

/**
 * Normalize a date dialog so that it respect min and max.
 */
public class DateDialogNormalizer {

    private static void setLimits(DatePicker picker, long minMillis, long maxMillis) {
        // DatePicker intervals are non inclusive, the DatePicker will throw an
        // exception when setting the min/max attribute to the current date
        // so make sure this never happens
        if (maxMillis <= minMillis) {
            return;
        }
        Calendar minCal = trimToDate(minMillis);
        Calendar maxCal = trimToDate(maxMillis);
        int currentYear = picker.getYear();
        int currentMonth = picker.getMonth();
        int currentDayOfMonth = picker.getDayOfMonth();
        picker.updateDate(maxCal.get(Calendar.YEAR),
                maxCal.get(Calendar.MONTH),
                maxCal.get(Calendar.DAY_OF_MONTH));
        picker.setMinDate(minCal.getTimeInMillis());
        picker.updateDate(minCal.get(Calendar.YEAR),
                minCal.get(Calendar.MONTH),
                minCal.get(Calendar.DAY_OF_MONTH));
        picker.setMaxDate(maxCal.getTimeInMillis());

        // Restore the current date, this will keep the min/max settings
        // previously set into account.
        picker.updateDate(currentYear, currentMonth, currentDayOfMonth);
    }

    private static Calendar trimToDate(long time) {
        Calendar cal = Calendar.getInstance(TimeZone.getTimeZone("GMT"));
        cal.clear();
        cal.setTimeInMillis(time);
        Calendar result = Calendar.getInstance(TimeZone.getTimeZone("GMT"));
        result.clear();
        result.set(cal.get(Calendar.YEAR), cal.get(Calendar.MONTH), cal.get(Calendar.DAY_OF_MONTH),
                0, 0, 0);
        return result;
    }

    /**
     * Normalizes an existing DateDialogPicker changing the default date if
     * needed to comply with the {@code min} and {@code max} attributes.
     */
    public static void normalize(DatePicker picker, OnDateChangedListener listener,
            int year, int month, int day, int hour, int minute, long minMillis, long maxMillis) {
        Calendar calendar = Calendar.getInstance(TimeZone.getTimeZone("GMT"));
        calendar.clear();
        calendar.set(year, month, day, hour, minute, 0);
        if (calendar.getTimeInMillis() < minMillis) {
            calendar.clear();
            calendar.setTimeInMillis(minMillis);
        } else if (calendar.getTimeInMillis() > maxMillis) {
            calendar.clear();
            calendar.setTimeInMillis(maxMillis);
        }
        picker.init(
                calendar.get(Calendar.YEAR), calendar.get(Calendar.MONTH),
                calendar.get(Calendar.DAY_OF_MONTH), listener);

        setLimits(picker, minMillis, maxMillis);
    }
}
