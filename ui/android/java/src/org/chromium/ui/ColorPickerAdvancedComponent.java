// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.ui;

import android.content.Context;
import android.graphics.drawable.GradientDrawable;
import android.graphics.drawable.GradientDrawable.Orientation;
import android.os.Build;
import android.view.View;
import android.widget.SeekBar;
import android.widget.SeekBar.OnSeekBarChangeListener;
import android.widget.TextView;

/**
 * Encapsulates a single gradient view of the HSV color display, including its label, gradient
 * view and seek bar.
 *
 * Mirrors a "color_picker_advanced_component" layout.
 */
public class ColorPickerAdvancedComponent {
    // The view that displays the gradient.
    private final View mGradientView;
    // The seek bar that allows the user to change the value of this component.
    private final SeekBar mSeekBar;
    // The set of colors to interpolate the gradient through.
    private int[] mGradientColors;
    // The Drawable that represents the gradient.
    private GradientDrawable mGradientDrawable;
    // The text label for the component.
    private final TextView mText;

    /**
     * Initializes the views.
     *
     * @param rootView View that contains all the content, such as the label, gradient view, etc.
     * @param textResourceId The resource ID of the text to show on the label.
     * @param seekBarMax The range of the seek bar.
     * @param seekBarListener The listener for when the seek bar value changes.
     */
    ColorPickerAdvancedComponent(final View rootView,
            final int textResourceId,
            final int seekBarMax,
            final OnSeekBarChangeListener seekBarListener) {
        mGradientView = rootView.findViewById(R.id.gradient);
        mText = (TextView) rootView.findViewById(R.id.text);
        mText.setText(textResourceId);
        mGradientDrawable = new GradientDrawable(GradientDrawable.Orientation.LEFT_RIGHT, null);
        mSeekBar = (SeekBar) rootView.findViewById(R.id.seek_bar);
        mSeekBar.setOnSeekBarChangeListener(seekBarListener);
        mSeekBar.setMax(seekBarMax);
        // Setting the thumb offset means the seek bar thumb can move all the way to each end
        // of the gradient view.
        Context context = rootView.getContext();
        int offset = context.getResources()
                            .getDrawable(R.drawable.color_picker_advanced_select_handle)
                            .getIntrinsicWidth();
        mSeekBar.setThumbOffset(offset / 2);
    }

    /**
     * @return The value represented by this component, maintained by the seek bar progress.
     */
    public float getValue() {
        return mSeekBar.getProgress();
    }

    /**
     * Sets the value of the component (by setting the seek bar value).
     *
     * @param newValue The value to give the component.
     */
    public void setValue(float newValue) {
        mSeekBar.setProgress((int) newValue);
    }

    /**
     * Sets the colors for the gradient view to interpolate through.
     *
     * @param newColors The set of colors representing the interpolation points for the gradient.
     */
    public void setGradientColors(int[] newColors) {
        mGradientColors = newColors.clone();
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.JELLY_BEAN) {
            Orientation currentOrientation = Orientation.LEFT_RIGHT;
            mGradientDrawable = new GradientDrawable(currentOrientation, mGradientColors);
        } else {
            mGradientDrawable.setColors(mGradientColors);
        }
        mGradientView.setBackground(mGradientDrawable);
    }
}
