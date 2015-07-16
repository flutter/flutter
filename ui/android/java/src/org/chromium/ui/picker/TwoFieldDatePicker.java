// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.ui.picker;

import android.content.Context;
import android.text.format.DateUtils;
import android.view.LayoutInflater;
import android.view.accessibility.AccessibilityEvent;
import android.widget.FrameLayout;
import android.widget.NumberPicker;
import android.widget.NumberPicker.OnValueChangeListener;

import org.chromium.ui.R;

import java.util.Calendar;
import java.util.TimeZone;

/**
 * This class is heavily based on android.widget.DatePicker.
 */
public abstract class TwoFieldDatePicker extends FrameLayout {

    private final NumberPicker mPositionInYearSpinner;

    private final NumberPicker mYearSpinner;

    private OnMonthOrWeekChangedListener mMonthOrWeekChangedListener;

    // It'd be nice to use android.text.Time like in other Dialogs but
    // it suffers from the 2038 effect so it would prevent us from
    // having dates over 2038.
    private Calendar mMinDate;

    private Calendar mMaxDate;

    private Calendar mCurrentDate;

    /**
     * The callback used to indicate the user changes\d the date.
     */
    public interface OnMonthOrWeekChangedListener {

        /**
         * Called upon a date change.
         *
         * @param view The view associated with this listener.
         * @param year The year that was set.
         * @param positionInYear The month or week in year.
         */
        void onMonthOrWeekChanged(TwoFieldDatePicker view, int year, int positionInYear);
    }

    public TwoFieldDatePicker(Context context, double minValue, double maxValue) {
        super(context, null, android.R.attr.datePickerStyle);

        LayoutInflater inflater = (LayoutInflater) context
                .getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        inflater.inflate(R.layout.two_field_date_picker, this, true);

        OnValueChangeListener onChangeListener = new OnValueChangeListener() {
            @Override
            public void onValueChange(NumberPicker picker, int oldVal, int newVal) {
                int year = getYear();
                int positionInYear = getPositionInYear();
                // take care of wrapping of days and months to update greater fields
                if (picker == mPositionInYearSpinner) {
                    positionInYear = newVal;
                    if (oldVal == picker.getMaxValue() && newVal == picker.getMinValue()) {
                        year += 1;
                        positionInYear = getMinPositionInYear(year);
                    } else if (oldVal == picker.getMinValue() && newVal == picker.getMaxValue()) {
                        year -= 1;
                        positionInYear = getMaxPositionInYear(year);
                    }
                } else if (picker == mYearSpinner) {
                    year = newVal;
                } else {
                    throw new IllegalArgumentException();
                }

                // now set the date to the adjusted one
                setCurrentDate(year, positionInYear);
                updateSpinners();
                notifyDateChanged();
            }
        };

        mCurrentDate = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
        if (minValue >= maxValue) {
            mMinDate = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
            mMinDate.set(0, 0, 1);
            mMaxDate = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
            mMaxDate.set(9999, 0, 1);
        } else {
            mMinDate = getDateForValue(minValue);
            mMaxDate = getDateForValue(maxValue);
        }

        // month
        mPositionInYearSpinner = (NumberPicker) findViewById(R.id.position_in_year);
        mPositionInYearSpinner.setOnLongPressUpdateInterval(200);
        mPositionInYearSpinner.setOnValueChangedListener(onChangeListener);

        // year
        mYearSpinner = (NumberPicker) findViewById(R.id.year);
        mYearSpinner.setOnLongPressUpdateInterval(100);
        mYearSpinner.setOnValueChangedListener(onChangeListener);
    }

    /**
     * Initialize the state. If the provided values designate an inconsistent
     * date the values are normalized before updating the spinners.
     *
     * @param year The initial year.
     * @param positionInYear The initial month <strong>starting from zero</strong> or week in year.
     * @param onMonthOrWeekChangedListener How user is notified date is changed by
     *            user, can be null.
     */
    public void init(int year, int positionInYear,
            OnMonthOrWeekChangedListener onMonthOrWeekChangedListener) {
        setCurrentDate(year, positionInYear);
        updateSpinners();
        mMonthOrWeekChangedListener = onMonthOrWeekChangedListener;
    }

    public boolean isNewDate(int year, int positionInYear) {
        return (getYear() != year || getPositionInYear() != positionInYear);
    }

    /**
     * Subclasses know the semantics of @value, and need to return
     * a Calendar corresponding to it.
     */
    protected abstract Calendar getDateForValue(double value);

    /**
     * Updates the current date.
     *
     * @param year The year.
     * @param positionInYear The month or week in year.
     */
    public void updateDate(int year, int positionInYear) {
        if (!isNewDate(year, positionInYear)) {
            return;
        }
        setCurrentDate(year, positionInYear);
        updateSpinners();
        notifyDateChanged();
    }

    /**
     * Subclasses know the semantics of @positionInYear, and need to update @mCurrentDate to the
     * appropriate date.
     */
    protected abstract void setCurrentDate(int year, int positionInYear);

    protected void setCurrentDate(Calendar date) {
        mCurrentDate = date;
    }

    @Override
    public boolean dispatchPopulateAccessibilityEvent(AccessibilityEvent event) {
        onPopulateAccessibilityEvent(event);
        return true;
    }

    @Override
    public void onPopulateAccessibilityEvent(AccessibilityEvent event) {
        super.onPopulateAccessibilityEvent(event);

        final int flags = DateUtils.FORMAT_SHOW_DATE | DateUtils.FORMAT_SHOW_YEAR;
        String selectedDateUtterance = DateUtils.formatDateTime(getContext(),
                mCurrentDate.getTimeInMillis(), flags);
        event.getText().add(selectedDateUtterance);
    }

    /**
     * @return The selected year.
     */
    public int getYear() {
        return mCurrentDate.get(Calendar.YEAR);
    }

    /**
     * @return The selected month or week.
     */
    public abstract int getPositionInYear();

    protected abstract int getMaxYear();

    protected abstract int getMinYear();

    protected abstract int getMaxPositionInYear(int year);

    protected abstract int getMinPositionInYear(int year);

    protected Calendar getMaxDate() {
        return mMaxDate;
    }

    protected Calendar getMinDate() {
        return mMinDate;
    }

    protected Calendar getCurrentDate() {
        return mCurrentDate;
    }

    protected NumberPicker getPositionInYearSpinner() {
        return mPositionInYearSpinner;
    }

    protected NumberPicker getYearSpinner() {
        return mYearSpinner;
    }

    /**
     * This method should be subclassed to update the spinners based on mCurrentDate.
     */
    protected void updateSpinners() {
        mPositionInYearSpinner.setDisplayedValues(null);

        // set the spinner ranges respecting the min and max dates
        mPositionInYearSpinner.setMinValue(getMinPositionInYear(getYear()));
        mPositionInYearSpinner.setMaxValue(getMaxPositionInYear(getYear()));
        mPositionInYearSpinner.setWrapSelectorWheel(
                !mCurrentDate.equals(mMinDate) && !mCurrentDate.equals(mMaxDate));

        // year spinner range does not change based on the current date
        mYearSpinner.setMinValue(getMinYear());
        mYearSpinner.setMaxValue(getMaxYear());
        mYearSpinner.setWrapSelectorWheel(false);

        // set the spinner values
        mYearSpinner.setValue(getYear());
        mPositionInYearSpinner.setValue(getPositionInYear());
    }

    /**
     * Notifies the listener, if such, for a change in the selected date.
     */
    protected void notifyDateChanged() {
        sendAccessibilityEvent(AccessibilityEvent.TYPE_VIEW_SELECTED);
        if (mMonthOrWeekChangedListener != null) {
            mMonthOrWeekChangedListener.onMonthOrWeekChanged(this, getYear(), getPositionInYear());
        }
    }
}
