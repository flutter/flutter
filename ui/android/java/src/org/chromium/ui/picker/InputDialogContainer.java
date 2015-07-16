// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.ui.picker;

import android.app.AlertDialog;
import android.app.DatePickerDialog.OnDateSetListener;
import android.content.Context;
import android.content.DialogInterface;
import android.content.DialogInterface.OnDismissListener;
import android.text.format.DateFormat;
import android.view.View;
import android.widget.AdapterView;
import android.widget.DatePicker;
import android.widget.ListView;
import android.widget.TimePicker;

import org.chromium.ui.R;
import org.chromium.ui.picker.DateTimePickerDialog.OnDateTimeSetListener;
import org.chromium.ui.picker.MultiFieldTimePickerDialog.OnMultiFieldTimeSetListener;

import java.util.Arrays;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.TimeZone;
import java.util.concurrent.TimeUnit;

/**
 * Opens the appropriate date/time picker dialog for the given dialog type.
 */
public class InputDialogContainer {

    public interface InputActionDelegate {
        void cancelDateTimeDialog();
        void replaceDateTime(double value);
    }

    private static int sTextInputTypeDate;
    private static int sTextInputTypeDateTime;
    private static int sTextInputTypeDateTimeLocal;
    private static int sTextInputTypeMonth;
    private static int sTextInputTypeTime;
    private static int sTextInputTypeWeek;

    private final Context mContext;

    // Prevents sending two notifications (from onClick and from onDismiss)
    private boolean mDialogAlreadyDismissed;

    private AlertDialog mDialog;
    private final InputActionDelegate mInputActionDelegate;

    public static void initializeInputTypes(int textInputTypeDate,
            int textInputTypeDateTime, int textInputTypeDateTimeLocal,
            int textInputTypeMonth, int textInputTypeTime,
            int textInputTypeWeek) {
        sTextInputTypeDate = textInputTypeDate;
        sTextInputTypeDateTime = textInputTypeDateTime;
        sTextInputTypeDateTimeLocal = textInputTypeDateTimeLocal;
        sTextInputTypeMonth = textInputTypeMonth;
        sTextInputTypeTime = textInputTypeTime;
        sTextInputTypeWeek = textInputTypeWeek;
    }

    public static boolean isDialogInputType(int type) {
        return type == sTextInputTypeDate || type == sTextInputTypeTime
                || type == sTextInputTypeDateTime || type == sTextInputTypeDateTimeLocal
                || type == sTextInputTypeMonth || type == sTextInputTypeWeek;
    }

    public InputDialogContainer(Context context, InputActionDelegate inputActionDelegate) {
        mContext = context;
        mInputActionDelegate = inputActionDelegate;
    }

    public void showPickerDialog(final int dialogType, double dialogValue,
            double min, double max, double step) {
        Calendar cal;
        // |dialogValue|, |min|, |max| mean different things depending on the |dialogType|.
        // For input type=month is the number of months since 1970.
        // For input type=time it is milliseconds since midnight.
        // For other types they are just milliseconds since 1970.
        // If |dialogValue| is NaN it means an empty value. We will show the current time.
        if (Double.isNaN(dialogValue)) {
            cal = Calendar.getInstance();
            cal.set(Calendar.MILLISECOND, 0);
        } else {
            if (dialogType == sTextInputTypeMonth) {
                cal = MonthPicker.createDateFromValue(dialogValue);
            } else if (dialogType == sTextInputTypeWeek) {
                cal = WeekPicker.createDateFromValue(dialogValue);
            } else {
                GregorianCalendar gregorianCalendar =
                        new GregorianCalendar(TimeZone.getTimeZone("UTC"));
                // According to the HTML spec we only use the Gregorian calendar
                // so we ignore the Julian/Gregorian transition.
                gregorianCalendar.setGregorianChange(new Date(Long.MIN_VALUE));
                gregorianCalendar.setTimeInMillis((long) dialogValue);
                cal =  gregorianCalendar;
            }
        }
        if (dialogType == sTextInputTypeDate) {
            showPickerDialog(dialogType,
                    cal.get(Calendar.YEAR),
                    cal.get(Calendar.MONTH),
                    cal.get(Calendar.DAY_OF_MONTH),
                    0, 0, 0, 0, 0, min, max, step);
        } else if (dialogType == sTextInputTypeTime) {
            showPickerDialog(dialogType, 0, 0, 0,
                    cal.get(Calendar.HOUR_OF_DAY),
                    cal.get(Calendar.MINUTE),
                    0, 0, 0, min, max, step);
        } else if (dialogType == sTextInputTypeDateTime ||
                dialogType == sTextInputTypeDateTimeLocal) {
            showPickerDialog(dialogType,
                    cal.get(Calendar.YEAR),
                    cal.get(Calendar.MONTH),
                    cal.get(Calendar.DAY_OF_MONTH),
                    cal.get(Calendar.HOUR_OF_DAY),
                    cal.get(Calendar.MINUTE),
                    cal.get(Calendar.SECOND),
                    cal.get(Calendar.MILLISECOND),
                    0, min, max, step);
        } else if (dialogType == sTextInputTypeMonth) {
            showPickerDialog(dialogType, cal.get(Calendar.YEAR), cal.get(Calendar.MONTH), 0,
                    0, 0, 0, 0, 0, min, max, step);
        } else if (dialogType == sTextInputTypeWeek) {
            int year = WeekPicker.getISOWeekYearForDate(cal);
            int week = WeekPicker.getWeekForDate(cal);
            showPickerDialog(dialogType, year, 0, 0, 0, 0, 0, 0, week, min, max, step);
        }
    }

    void showSuggestionDialog(final int dialogType,
            final double dialogValue,
            final double min, final double max, final double step,
            DateTimeSuggestion[] suggestions) {
        ListView suggestionListView = new ListView(mContext);
        final DateTimeSuggestionListAdapter adapter =
                new DateTimeSuggestionListAdapter(mContext, Arrays.asList(suggestions));
        suggestionListView.setAdapter(adapter);
        suggestionListView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
                if (position == adapter.getCount() - 1) {
                    dismissDialog();
                    showPickerDialog(dialogType, dialogValue, min, max, step);
                } else {
                    double suggestionValue = adapter.getItem(position).value();
                    mInputActionDelegate.replaceDateTime(suggestionValue);
                    dismissDialog();
                    mDialogAlreadyDismissed = true;
                }
            }
        });

        int dialogTitleId = R.string.date_picker_dialog_title;
        if (dialogType == sTextInputTypeTime) {
            dialogTitleId = R.string.time_picker_dialog_title;
        } else if (dialogType == sTextInputTypeDateTime ||
                dialogType == sTextInputTypeDateTimeLocal) {
            dialogTitleId = R.string.date_time_picker_dialog_title;
        } else if (dialogType == sTextInputTypeMonth) {
            dialogTitleId = R.string.month_picker_dialog_title;
        } else if (dialogType == sTextInputTypeWeek) {
            dialogTitleId = R.string.week_picker_dialog_title;
        }

        mDialog = new AlertDialog.Builder(mContext)
            .setTitle(dialogTitleId)
            .setView(suggestionListView)
            .setNegativeButton(mContext.getText(android.R.string.cancel),
                new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        dismissDialog();
                    }
                })
            .create();

        mDialog.setOnDismissListener(new DialogInterface.OnDismissListener() {
            @Override
            public void onDismiss(DialogInterface dialog) {
                if (mDialog == dialog && !mDialogAlreadyDismissed) {
                    mDialogAlreadyDismissed = true;
                    mInputActionDelegate.cancelDateTimeDialog();
                }
            }
        });
        mDialogAlreadyDismissed = false;
        mDialog.show();
    }

    public void showDialog(final int type, final double value,
                    double min, double max, double step,
                    DateTimeSuggestion[] suggestions) {
        // When the web page asks to show a dialog while there is one already open,
        // dismiss the old one.
        dismissDialog();
        if (suggestions == null) {
            showPickerDialog(type, value, min, max, step);
        } else {
            showSuggestionDialog(type, value, min, max, step, suggestions);
        }
    }

    protected void showPickerDialog(final int dialogType,
            int year, int month, int monthDay,
            int hourOfDay, int minute, int second, int millis, int week,
            double min, double max, double step) {
        if (isDialogShowing()) mDialog.dismiss();

        int stepTime = (int) step;

        if (dialogType == sTextInputTypeDate) {
            ChromeDatePickerDialog dialog = new ChromeDatePickerDialog(mContext,
                    new DateListener(dialogType),
                    year, month, monthDay);
            DateDialogNormalizer.normalize(dialog.getDatePicker(), dialog,
                    year, month, monthDay,
                    0, 0,
                    (long) min, (long) max);

            dialog.setTitle(mContext.getText(R.string.date_picker_dialog_title));
            mDialog = dialog;
        } else if (dialogType == sTextInputTypeTime) {
            mDialog = new MultiFieldTimePickerDialog(
                mContext, 0 /* theme */ ,
                hourOfDay, minute, second, millis,
                (int) min, (int) max, stepTime,
                DateFormat.is24HourFormat(mContext),
                new FullTimeListener(dialogType));
        } else if (dialogType == sTextInputTypeDateTime ||
                dialogType == sTextInputTypeDateTimeLocal) {
            mDialog = new DateTimePickerDialog(mContext,
                    new DateTimeListener(dialogType),
                    year, month, monthDay,
                    hourOfDay, minute,
                    DateFormat.is24HourFormat(mContext), min, max);
        } else if (dialogType == sTextInputTypeMonth) {
            mDialog = new MonthPickerDialog(mContext, new MonthOrWeekListener(dialogType),
                    year, month, min, max);
        } else if (dialogType == sTextInputTypeWeek) {
            mDialog = new WeekPickerDialog(mContext, new MonthOrWeekListener(dialogType),
                    year, week, min, max);
        }

        mDialog.setButton(DialogInterface.BUTTON_POSITIVE,
                mContext.getText(R.string.date_picker_dialog_set),
                (DialogInterface.OnClickListener) mDialog);

        mDialog.setButton(DialogInterface.BUTTON_NEGATIVE,
                mContext.getText(android.R.string.cancel),
                (DialogInterface.OnClickListener) null);

        mDialog.setButton(DialogInterface.BUTTON_NEUTRAL,
                mContext.getText(R.string.date_picker_dialog_clear),
                new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        mDialogAlreadyDismissed = true;
                        mInputActionDelegate.replaceDateTime(Double.NaN);
                    }
                });

        mDialog.setOnDismissListener(
                new OnDismissListener() {
                    @Override
                    public void onDismiss(final DialogInterface dialog) {
                        if (!mDialogAlreadyDismissed) {
                            mDialogAlreadyDismissed = true;
                            mInputActionDelegate.cancelDateTimeDialog();
                        }
                    }
                });

        mDialogAlreadyDismissed = false;
        mDialog.show();
    }

    boolean isDialogShowing() {
        return mDialog != null && mDialog.isShowing();
    }

    void dismissDialog() {
        if (isDialogShowing()) mDialog.dismiss();
    }

    private class DateListener implements OnDateSetListener {
        private final int mDialogType;

        DateListener(int dialogType) {
            mDialogType = dialogType;
        }

        @Override
        public void onDateSet(DatePicker view, int year, int month, int monthDay) {
            setFieldDateTimeValue(mDialogType, year, month, monthDay, 0, 0, 0, 0, 0);
        }
    }

    private class FullTimeListener implements OnMultiFieldTimeSetListener {
        private final int mDialogType;
        FullTimeListener(int dialogType) {
            mDialogType = dialogType;
        }

        @Override
        public void onTimeSet(int hourOfDay, int minute, int second, int milli) {
            setFieldDateTimeValue(mDialogType, 0, 0, 0, hourOfDay, minute, second, milli, 0);
        }
    }

    private class DateTimeListener implements OnDateTimeSetListener {
        private final boolean mLocal;
        private final int mDialogType;

        public DateTimeListener(int dialogType) {
            mLocal = dialogType == sTextInputTypeDateTimeLocal;
            mDialogType = dialogType;
        }

        @Override
        public void onDateTimeSet(DatePicker dateView, TimePicker timeView,
                int year, int month, int monthDay,
                int hourOfDay, int minute) {
            setFieldDateTimeValue(mDialogType, year, month, monthDay, hourOfDay, minute, 0, 0, 0);
        }
    }

    private class MonthOrWeekListener implements TwoFieldDatePickerDialog.OnValueSetListener {
        private final int mDialogType;

        MonthOrWeekListener(int dialogType) {
            mDialogType = dialogType;
        }

        @Override
        public void onValueSet(int year, int positionInYear) {
            if (mDialogType == sTextInputTypeMonth) {
                setFieldDateTimeValue(mDialogType, year, positionInYear, 0, 0, 0, 0, 0, 0);
            } else {
                setFieldDateTimeValue(mDialogType, year, 0, 0, 0, 0, 0, 0, positionInYear);
            }
        }
    }

    protected void setFieldDateTimeValue(int dialogType,
                                       int year, int month, int monthDay,
                                       int hourOfDay, int minute, int second, int millis,
                                       int week) {
        // Prevents more than one callback being sent to the native
        // side when the dialog triggers multiple events.
        if (mDialogAlreadyDismissed)
            return;
        mDialogAlreadyDismissed = true;

        if (dialogType == sTextInputTypeMonth) {
            mInputActionDelegate.replaceDateTime((year - 1970) * 12 + month);
        } else if (dialogType == sTextInputTypeWeek) {
            mInputActionDelegate.replaceDateTime(
                    WeekPicker.createDateFromWeek(year, week).getTimeInMillis());
        } else if (dialogType == sTextInputTypeTime) {
            mInputActionDelegate.replaceDateTime(TimeUnit.HOURS.toMillis(hourOfDay) +
                                                 TimeUnit.MINUTES.toMillis(minute) +
                                                 TimeUnit.SECONDS.toMillis(second) +
                                                 millis);
        } else {
            Calendar cal = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
            cal.clear();
            cal.set(Calendar.YEAR, year);
            cal.set(Calendar.MONTH, month);
            cal.set(Calendar.DAY_OF_MONTH, monthDay);
            cal.set(Calendar.HOUR_OF_DAY, hourOfDay);
            cal.set(Calendar.MINUTE, minute);
            cal.set(Calendar.SECOND, second);
            cal.set(Calendar.MILLISECOND, millis);
            mInputActionDelegate.replaceDateTime(cal.getTimeInMillis());
        }
    }
}
