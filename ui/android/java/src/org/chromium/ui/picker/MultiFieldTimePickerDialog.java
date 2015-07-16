// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.ui.picker;

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.DialogInterface.OnClickListener;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.NumberPicker;

import org.chromium.ui.R;

import java.util.ArrayList;

/**
 * A time picker dialog with upto 5 number pickers left to right:
 *  hour, minute, second, milli, AM/PM.
 *
 * If is24hourFormat is true then AM/PM picker is not displayed and
 * hour range is 0..23. Otherwise hour range is 1..12.
 * The milli picker is not displayed if step >= SECOND_IN_MILLIS
 * The second picker is not displayed if step >= MINUTE_IN_MILLIS.
 */
public class MultiFieldTimePickerDialog
        extends AlertDialog implements OnClickListener {

    private final NumberPicker mHourSpinner;
    private final NumberPicker mMinuteSpinner;
    private final NumberPicker mSecSpinner;
    private final NumberPicker mMilliSpinner;
    private final NumberPicker mAmPmSpinner;
    private final OnMultiFieldTimeSetListener mListener;
    private final int mStep;
    private final int mBaseMilli;
    private final boolean mIs24hourFormat;

    public interface OnMultiFieldTimeSetListener {
        void onTimeSet(int hourOfDay, int minute, int second, int milli);
    }

    private static final int SECOND_IN_MILLIS = 1000;
    private static final int MINUTE_IN_MILLIS = 60 * SECOND_IN_MILLIS;
    private static final int HOUR_IN_MILLIS = 60 * MINUTE_IN_MILLIS;

    public MultiFieldTimePickerDialog(
            Context context,
            int theme,
            int hour, int minute, int second, int milli,
            int min, int max, int step, boolean is24hourFormat,
            OnMultiFieldTimeSetListener listener) {
        super(context, theme);
        mListener = listener;
        mStep = step;
        mIs24hourFormat = is24hourFormat;

        if (min >= max) {
            min = 0;
            max = 24 * HOUR_IN_MILLIS - 1;
        }
        if (step < 0 || step >= 24 * HOUR_IN_MILLIS) {
            step = MINUTE_IN_MILLIS;
        }

        LayoutInflater inflater =
                (LayoutInflater) context.getSystemService(
                        Context.LAYOUT_INFLATER_SERVICE);
        View view = inflater.inflate(R.layout.multi_field_time_picker_dialog, null);
        setView(view);

        mHourSpinner = (NumberPicker) view.findViewById(R.id.hour);
        mMinuteSpinner = (NumberPicker) view.findViewById(R.id.minute);
        mSecSpinner = (NumberPicker) view.findViewById(R.id.second);
        mMilliSpinner = (NumberPicker) view.findViewById(R.id.milli);
        mAmPmSpinner = (NumberPicker) view.findViewById(R.id.ampm);

        int minHour = min / HOUR_IN_MILLIS;
        int maxHour = max / HOUR_IN_MILLIS;
        min -= minHour * HOUR_IN_MILLIS;
        max -= maxHour * HOUR_IN_MILLIS;

        if (minHour == maxHour) {
            mHourSpinner.setEnabled(false);
            hour = minHour;
        }

        if (is24hourFormat) {
            mAmPmSpinner.setVisibility(View.GONE);
        } else {
            int minAmPm = minHour / 12;
            int maxAmPm = maxHour / 12;
            int amPm = hour / 12;
            mAmPmSpinner.setMinValue(minAmPm);
            mAmPmSpinner.setMaxValue(maxAmPm);
            mAmPmSpinner.setDisplayedValues(new String[] {
                    context.getString(R.string.time_picker_dialog_am),
                    context.getString(R.string.time_picker_dialog_pm)
            });

            hour %= 12;
            if (hour == 0) {
                hour = 12;
            }
            if (minAmPm == maxAmPm) {
                mAmPmSpinner.setEnabled(false);
                amPm = minAmPm;

                minHour %= 12;
                maxHour %= 12;
                if (minHour == 0 && maxHour == 0) {
                    minHour = 12;
                    maxHour = 12;
                } else if (minHour == 0) {
                    minHour = maxHour;
                    maxHour = 12;
                } else if (maxHour == 0) {
                    maxHour = 12;
                }
            } else {
                minHour = 1;
                maxHour = 12;
            }
            mAmPmSpinner.setValue(amPm);
        }

        if (minHour == maxHour) {
            mHourSpinner.setEnabled(false);
        }
        mHourSpinner.setMinValue(minHour);
        mHourSpinner.setMaxValue(maxHour);
        mHourSpinner.setValue(hour);

        NumberFormatter twoDigitPaddingFormatter = new NumberFormatter("%02d");

        int minMinute = min / MINUTE_IN_MILLIS;
        int maxMinute = max / MINUTE_IN_MILLIS;
        min -= minMinute * MINUTE_IN_MILLIS;
        max -= maxMinute * MINUTE_IN_MILLIS;

        if (minHour == maxHour) {
            mMinuteSpinner.setMinValue(minMinute);
            mMinuteSpinner.setMaxValue(maxMinute);
            if (minMinute == maxMinute) {
                // Set this otherwise the box is empty until you stroke it.
                mMinuteSpinner.setDisplayedValues(
                        new String[] { twoDigitPaddingFormatter.format(minMinute) });
                mMinuteSpinner.setEnabled(false);
                minute = minMinute;
            }
        } else {
            mMinuteSpinner.setMinValue(0);
            mMinuteSpinner.setMaxValue(59);
        }

        if (step >= HOUR_IN_MILLIS) {
            mMinuteSpinner.setEnabled(false);
        }

        mMinuteSpinner.setValue(minute);
        mMinuteSpinner.setFormatter(twoDigitPaddingFormatter);

        if (step >= MINUTE_IN_MILLIS) {
            // Remove the ':' in front of the second spinner as well.
            view.findViewById(R.id.second_colon).setVisibility(View.GONE);
            mSecSpinner.setVisibility(View.GONE);
        }

        int minSecond = min / SECOND_IN_MILLIS;
        int maxSecond = max / SECOND_IN_MILLIS;
        min -= minSecond * SECOND_IN_MILLIS;
        max -= maxSecond * SECOND_IN_MILLIS;

        if (minHour == maxHour && minMinute == maxMinute) {
            mSecSpinner.setMinValue(minSecond);
            mSecSpinner.setMaxValue(maxSecond);
            if (minSecond == maxSecond) {
                // Set this otherwise the box is empty until you stroke it.
                mSecSpinner.setDisplayedValues(
                        new String[] { twoDigitPaddingFormatter.format(minSecond) });
                mSecSpinner.setEnabled(false);
                second = minSecond;
            }
        } else {
            mSecSpinner.setMinValue(0);
            mSecSpinner.setMaxValue(59);
        }

        mSecSpinner.setValue(second);
        mSecSpinner.setFormatter(twoDigitPaddingFormatter);

        if (step >= SECOND_IN_MILLIS) {
            // Remove the '.' in front of the milli spinner as well.
            view.findViewById(R.id.second_dot).setVisibility(View.GONE);
            mMilliSpinner.setVisibility(View.GONE);
        }

        // Round to the nearest step.
        milli = ((milli + step / 2) / step) * step;
        if (step == 1 || step == 10 || step == 100) {
            if (minHour == maxHour && minMinute == maxMinute && minSecond == maxSecond) {
                mMilliSpinner.setMinValue(min / step);
                mMilliSpinner.setMaxValue(max / step);

                if (min == max) {
                    mMilliSpinner.setEnabled(false);
                    milli = min;
                }
            } else {
                mMilliSpinner.setMinValue(0);
                mMilliSpinner.setMaxValue(999 / step);
            }

            if (step == 1) {
                mMilliSpinner.setFormatter(new NumberFormatter("%03d"));
            } else if (step == 10) {
                mMilliSpinner.setFormatter(new NumberFormatter("%02d"));
            } else if (step == 100) {
                mMilliSpinner.setFormatter(new NumberFormatter("%d"));
            }
            mMilliSpinner.setValue(milli / step);
            mBaseMilli = 0;
        } else if (step < SECOND_IN_MILLIS) {
            // Non-decimal step value.
            ArrayList<String> strValue = new ArrayList<String>();
            for (int i = min; i < max; i += step) {
                strValue.add(String.format("%03d", i));
            }
            mMilliSpinner.setMinValue(0);
            mMilliSpinner.setMaxValue(strValue.size() - 1);
            mMilliSpinner.setValue((milli - min) / step);
            mMilliSpinner.setDisplayedValues(strValue.toArray(new String[strValue.size()]));
            mBaseMilli = min;
        } else {
            mBaseMilli = 0;
        }
    }

    @Override
    public void onClick(DialogInterface dialog, int which) {
        notifyDateSet();
    }

    private void notifyDateSet() {
        int hour = mHourSpinner.getValue();
        int minute = mMinuteSpinner.getValue();
        int sec = mSecSpinner.getValue();
        int milli = mMilliSpinner.getValue() * mStep + mBaseMilli;
        if (!mIs24hourFormat) {
            int ampm = mAmPmSpinner.getValue();
            if (hour == 12) {
                hour = 0;
            }
            hour += ampm * 12;
        }
        mListener.onTimeSet(hour, minute, sec, milli);
    }

    private static class NumberFormatter implements NumberPicker.Formatter {
        private final String mFormat;

        NumberFormatter(String format) {
            mFormat = format;
        }

        @Override
        public String format(int value) {
            return String.format(mFormat, value);
        }
    }
}
