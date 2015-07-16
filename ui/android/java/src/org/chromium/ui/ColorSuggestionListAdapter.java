// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.ui;

import android.content.Context;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.graphics.drawable.LayerDrawable;
import android.text.TextUtils;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AbsListView;
import android.widget.BaseAdapter;
import android.widget.LinearLayout;

import org.chromium.base.ApiCompatibilityUtils;

/**
 * The adapter used to populate ColorPickerSimple.
 */
public class ColorSuggestionListAdapter extends BaseAdapter implements View.OnClickListener {
    private Context mContext;
    private ColorSuggestion[] mSuggestions;
    private OnColorSuggestionClickListener mListener;

    /**
     * The callback used to indicate the user has clicked on a suggestion.
     */
    public interface OnColorSuggestionClickListener {

        /**
         * Called upon a click on a suggestion.
         *
         * @param suggestion The suggestion that was clicked.
         */
        void onColorSuggestionClick(ColorSuggestion suggestion);
    }

    private static final int COLORS_PER_ROW = 4;

    ColorSuggestionListAdapter(Context context, ColorSuggestion[] suggestions) {
        mContext = context;
        mSuggestions = suggestions;
    }

    /**
     * Sets the listener that will be notified upon a click on a suggestion.
     */
    public void setOnColorSuggestionClickListener(OnColorSuggestionClickListener listener) {
        mListener = listener;
    }

    /**
     * Sets up the color button to represent a color suggestion.
     *
     * @param button The button view to set up.
     * @param index The index of the suggestion in mSuggestions.
     */
    private void setUpColorButton(View button, int index) {
        if (index >= mSuggestions.length) {
            button.setTag(null);
            button.setContentDescription(null);
            button.setVisibility(View.INVISIBLE);
            return;
        }
        button.setTag(mSuggestions[index]);
        button.setVisibility(View.VISIBLE);
        ColorSuggestion suggestion = mSuggestions[index];
        LayerDrawable layers = (LayerDrawable) button.getBackground();
        GradientDrawable swatch =
                (GradientDrawable) layers.findDrawableByLayerId(R.id.color_button_swatch);
        swatch.setColor(suggestion.mColor);
        String description = suggestion.mLabel;
        if (TextUtils.isEmpty(description)) {
            description = String.format("#%06X", (0xFFFFFF & suggestion.mColor));
        }
        button.setContentDescription(description);
        button.setOnClickListener(this);
    }

    @Override
    public void onClick(View v) {
        if (mListener == null) {
            return;
        }
        ColorSuggestion suggestion = (ColorSuggestion) v.getTag();
        if (suggestion == null) {
            return;
        }
        mListener.onColorSuggestionClick(suggestion);
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent) {
        LinearLayout layout;
        if (convertView != null && convertView instanceof LinearLayout) {
            layout = (LinearLayout) convertView;
        } else {
            layout = new LinearLayout(mContext);
            layout.setLayoutParams(new AbsListView.LayoutParams(
                    AbsListView.LayoutParams.MATCH_PARENT,
                    AbsListView.LayoutParams.WRAP_CONTENT));
            layout.setOrientation(LinearLayout.HORIZONTAL);
            layout.setBackgroundColor(Color.WHITE);
            int buttonHeight =
                    mContext.getResources().getDimensionPixelOffset(R.dimen.color_button_height);
            for (int i = 0; i < COLORS_PER_ROW; ++i) {
                View button = new View(mContext);
                LinearLayout.LayoutParams layoutParams =
                        new LinearLayout.LayoutParams(0, buttonHeight, 1f);
                ApiCompatibilityUtils.setMarginStart(layoutParams, -1);
                if (i == COLORS_PER_ROW - 1) {
                    ApiCompatibilityUtils.setMarginEnd(layoutParams, -1);
                }
                button.setLayoutParams(layoutParams);
                button.setBackgroundResource(R.drawable.color_button_background);
                layout.addView(button);
            }
        }
        for (int i = 0; i < COLORS_PER_ROW; ++i) {
            setUpColorButton(layout.getChildAt(i), position * COLORS_PER_ROW + i);
        }
        return layout;
    }

    @Override
    public long getItemId(int position) {
        return position;
    }

    @Override
    public Object getItem(int position) {
        return null;
    }

    @Override
    public int getCount() {
        return (mSuggestions.length + COLORS_PER_ROW - 1) / COLORS_PER_ROW;
    }
}
