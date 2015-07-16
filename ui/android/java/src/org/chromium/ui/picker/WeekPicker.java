// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.ui.picker;

import android.content.Context;

import org.chromium.ui.R;

import java.util.Calendar;
import java.util.TimeZone;

// This class is heavily based on android.widget.DatePicker.
public class WeekPicker extends TwoFieldDatePicker {

    public WeekPicker(Context context, double minValue, double maxValue) {
        super(context, minValue, maxValue);

        getPositionInYearSpinner().setContentDescription(
                getResources().getString(R.string.accessibility_date_picker_week));

        // initialize to current date
        Calendar cal = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
        cal.setFirstDayOfWeek(Calendar.MONDAY);
        cal.setMinimalDaysInFirstWeek(4);
        cal.setTimeInMillis(System.currentTimeMillis());
        init(getISOWeekYearForDate(cal), getWeekForDate(cal), null);
    }

    /**
     * Creates a date object from the |year| and |week|.
     */
    public static Calendar createDateFromWeek(int year, int week) {
        Calendar date = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
        date.clear();
        date.setFirstDayOfWeek(Calendar.MONDAY);
        date.setMinimalDaysInFirstWeek(4);
        date.set(Calendar.DAY_OF_WEEK, Calendar.MONDAY);
        date.set(Calendar.YEAR, year);
        date.set(Calendar.WEEK_OF_YEAR, week);
        return date;
    }

    /**
     * Creates a date object from the |value| which is milliseconds since epoch.
     */
    public static Calendar createDateFromValue(double value) {
        Calendar date = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
        date.clear();
        date.setFirstDayOfWeek(Calendar.MONDAY);
        date.setMinimalDaysInFirstWeek(4);
        date.setTimeInMillis((long) value);
        return date;
    }

    @Override
    protected Calendar getDateForValue(double value) {
        return WeekPicker.createDateFromValue(value);
    }

    public static int getISOWeekYearForDate(Calendar date) {
        int year = date.get(Calendar.YEAR);
        int month = date.get(Calendar.MONTH);
        int week = date.get(Calendar.WEEK_OF_YEAR);
        if (month == 0 && week > 51) {
            year--;
        } else if (month == 11 && week == 1) {
            year++;
        }
        return year;
    }

    public static int getWeekForDate(Calendar date) {
        return date.get(Calendar.WEEK_OF_YEAR);
    }

    @Override
    protected void setCurrentDate(int year, int week) {
        Calendar date = createDateFromWeek(year, week);
        if (date.before(getMinDate())) {
            setCurrentDate(getMinDate());
        } else if (date.after(getMaxDate())) {
            setCurrentDate(getMaxDate());
        } else {
            setCurrentDate(date);
        }
    }

    private int getNumberOfWeeks(int year) {
        // Create a date in the middle of the year, where the week year matches the year.
        Calendar date = createDateFromWeek(year, 20);
        return date.getActualMaximum(Calendar.WEEK_OF_YEAR);
    }

    /**
     * @return The selected year.
     */
    @Override
    public int getYear() {
        return getISOWeekYearForDate(getCurrentDate());
    }

    /**
     * @return The selected week.
     */
    public int getWeek() {
        return getWeekForDate(getCurrentDate());
    }

    @Override
    public int getPositionInYear() {
        return getWeek();
    }

    @Override
    protected int getMaxYear() {
        return getISOWeekYearForDate(getMaxDate());
    }

    @Override
    protected int getMinYear() {
        return getISOWeekYearForDate(getMinDate());
    }

    @Override
    protected int getMaxPositionInYear(int year) {
        if (year == getISOWeekYearForDate(getMaxDate())) {
            return getWeekForDate(getMaxDate());
        }
        return getNumberOfWeeks(year);
    }

    @Override
    protected int getMinPositionInYear(int year) {
        if (year == getISOWeekYearForDate(getMinDate())) {
            return getWeekForDate(getMinDate());
        }
        return 1;
    }
}
