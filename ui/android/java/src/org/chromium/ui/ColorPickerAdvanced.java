// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.ui;

import android.content.Context;
import android.graphics.Color;
import android.util.AttributeSet;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.SeekBar;
import android.widget.SeekBar.OnSeekBarChangeListener;

/**
 * Represents a more advanced way for the user to choose a color, based on selecting each of
 * the Hue, Saturation and Value attributes.
 */
public class ColorPickerAdvanced extends LinearLayout implements OnSeekBarChangeListener {
    private static final int HUE_SEEK_BAR_MAX = 360;

    private static final int HUE_COLOR_COUNT = 7;

    private static final int SATURATION_SEEK_BAR_MAX = 100;

    private static final int SATURATION_COLOR_COUNT = 2;

    private static final int VALUE_SEEK_BAR_MAX = 100;

    private static final int VALUE_COLOR_COUNT = 2;

    ColorPickerAdvancedComponent mHueDetails;

    ColorPickerAdvancedComponent mSaturationDetails;

    ColorPickerAdvancedComponent mValueDetails;

    private OnColorChangedListener mOnColorChangedListener;

    private int mCurrentColor;

    private final float[] mCurrentHsvValues = new float[3];

    public ColorPickerAdvanced(Context context, AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    public ColorPickerAdvanced(Context context, AttributeSet attrs, int defStyle) {
        super(context, attrs, defStyle);
        init();
    }

    public ColorPickerAdvanced(Context context) {
        super(context);
        init();
    }

    /**
     * Initializes all the views and variables in the advanced view.
     */
    private void init() {
        setOrientation(LinearLayout.VERTICAL);

        mHueDetails = createAndAddNewGradient(R.string.color_picker_hue,
                HUE_SEEK_BAR_MAX, this);
        mSaturationDetails = createAndAddNewGradient(R.string.color_picker_saturation,
                SATURATION_SEEK_BAR_MAX, this);
        mValueDetails = createAndAddNewGradient(R.string.color_picker_value,
                VALUE_SEEK_BAR_MAX, this);
        refreshGradientComponents();
    }

    /**
     * Creates a new GradientDetails object from the parameters provided, initializes it,
     * and adds it to this advanced view.
     *
     * @param textResourceId The text to display for the label.
     * @param seekBarMax The maximum value of the seek bar for the gradient.
     * @param seekBarListener Object listening to when the user changes the seek bar.
     *
     * @return A new GradientDetails object initialized with the given parameters.
     */
    public ColorPickerAdvancedComponent createAndAddNewGradient(int textResourceId,
            int seekBarMax,
            OnSeekBarChangeListener seekBarListener) {
        LayoutInflater inflater = (LayoutInflater) getContext()
                .getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        View newComponent = inflater.inflate(R.layout.color_picker_advanced_component, null);
        addView(newComponent);

        return new ColorPickerAdvancedComponent(newComponent,
                textResourceId,
                seekBarMax,
                seekBarListener);
    }

    /**
     * Sets the listener for when the user changes the color.
     *
     * @param onColorChangedListener The object listening for the change in color.
     */
    public void setListener(OnColorChangedListener onColorChangedListener) {
        mOnColorChangedListener = onColorChangedListener;
    }

    /**
     * @return The color the user has currently chosen.
     */
    public int getColor() {
        return mCurrentColor;
    }

    /**
     * Sets the color that the user has currently chosen.
     *
     * @param color The currently chosen color.
     */
    public void setColor(int color) {
        mCurrentColor = color;
        Color.colorToHSV(mCurrentColor, mCurrentHsvValues);
        refreshGradientComponents();
    }

    /**
     * Notifies the listener, if there is one, of a change in the selected color.
     */
    private void notifyColorChanged() {
        if (mOnColorChangedListener != null) {
            mOnColorChangedListener.onColorChanged(getColor());
        }
    }

    /**
     * Callback for when a slider is updated on the advanced view.
     *
     * @param seekBar The color slider that was updated.
     * @param progress The new value of the color slider.
     * @param fromUser Whether it was the user the changed the value, or whether
     *            we were setting it up.
     */
    @Override
    public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
        if (fromUser) {
            mCurrentHsvValues[0] = mHueDetails.getValue();
            mCurrentHsvValues[1] = mSaturationDetails.getValue() / 100.0f;
            mCurrentHsvValues[2] = mValueDetails.getValue() / 100.0f;

            mCurrentColor = Color.HSVToColor(mCurrentHsvValues);

            updateHueGradient();
            updateSaturationGradient();
            updateValueGradient();

            notifyColorChanged();
        }
    }

    /**
     * Updates only the hue gradient display with the hue value for the
     * currently selected color.
     */
    private void updateHueGradient() {
        float[] tempHsvValues = new float[3];
        tempHsvValues[1] = mCurrentHsvValues[1];
        tempHsvValues[2] = mCurrentHsvValues[2];

        int[] newColors = new int[HUE_COLOR_COUNT];

        for (int i = 0; i < HUE_COLOR_COUNT; ++i) {
            tempHsvValues[0] = i * 60.0f;
            newColors[i] = Color.HSVToColor(tempHsvValues);
        }
        mHueDetails.setGradientColors(newColors);
    }

    /**
     * Updates only the saturation gradient display with the saturation value
     * for the currently selected color.
     */
    private void updateSaturationGradient() {
        float[] tempHsvValues = new float[3];
        tempHsvValues[0] = mCurrentHsvValues[0];
        tempHsvValues[1] = 0.0f;
        tempHsvValues[2] = mCurrentHsvValues[2];

        int[] newColors = new int[SATURATION_COLOR_COUNT];

        newColors[0] = Color.HSVToColor(tempHsvValues);

        tempHsvValues[1] = 1.0f;
        newColors[1] = Color.HSVToColor(tempHsvValues);
        mSaturationDetails.setGradientColors(newColors);
    }

    /**
     * Updates only the Value gradient display with the Value amount for
     * the currently selected color.
     */
    private void updateValueGradient() {
        float[] tempHsvValues = new float[3];
        tempHsvValues[0] = mCurrentHsvValues[0];
        tempHsvValues[1] = mCurrentHsvValues[1];
        tempHsvValues[2] = 0.0f;

        int[] newColors = new int[VALUE_COLOR_COUNT];

        newColors[0] = Color.HSVToColor(tempHsvValues);

        tempHsvValues[2] = 1.0f;
        newColors[1] = Color.HSVToColor(tempHsvValues);
        mValueDetails.setGradientColors(newColors);
    }

    /**
     * Updates all the gradient displays to show the currently selected color.
     */
    private void refreshGradientComponents() {
        // Round and bound the saturation value.
        int saturationValue = Math.round(mCurrentHsvValues[1] * 100.0f);
        saturationValue = Math.min(saturationValue, SATURATION_SEEK_BAR_MAX);
        saturationValue = Math.max(saturationValue, 0);

        // Round and bound the Value amount.
        int valueValue = Math.round(mCurrentHsvValues[2] * 100.0f);
        valueValue = Math.min(valueValue, VALUE_SEEK_BAR_MAX);
        valueValue = Math.max(valueValue, 0);

        // Don't need to round the hue value since its possible values match the seek bar
        // range directly.
        mHueDetails.setValue(mCurrentHsvValues[0]);
        mSaturationDetails.setValue(saturationValue);
        mValueDetails.setValue(valueValue);

        updateHueGradient();
        updateSaturationGradient();
        updateValueGradient();
    }

    @Override
    public void onStartTrackingTouch(SeekBar seekBar) {
        // Do nothing.
    }

    @Override
    public void onStopTrackingTouch(SeekBar seekBar) {
        // Do nothing.
    }
}
