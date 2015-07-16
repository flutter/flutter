// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.ui.picker;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.TextView;

import org.chromium.ui.R;

import java.util.List;

/**
 * Date/time suggestion adapter for the suggestion dialog.
 */
class DateTimeSuggestionListAdapter extends ArrayAdapter<DateTimeSuggestion> {
    private final Context mContext;

    DateTimeSuggestionListAdapter(Context context, List<DateTimeSuggestion> objects) {
        super(context, R.layout.date_time_suggestion, objects);
        mContext = context;
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent) {
        View layout = convertView;
        if (convertView == null) {
            LayoutInflater inflater = LayoutInflater.from(mContext);
            layout = inflater.inflate(R.layout.date_time_suggestion, parent, false);
        }
        TextView labelView = (TextView) layout.findViewById(R.id.date_time_suggestion_value);
        TextView sublabelView = (TextView) layout.findViewById(R.id.date_time_suggestion_label);

        if (position == getCount() - 1) {
            labelView.setText(mContext.getText(R.string.date_picker_dialog_other_button_label));
            sublabelView.setText("");
        } else {
            labelView.setText(getItem(position).localizedValue());
            sublabelView.setText(getItem(position).label());
        }

        return layout;
    }

    @Override
    public int getCount() {
        return super.getCount() + 1;
    }
}
