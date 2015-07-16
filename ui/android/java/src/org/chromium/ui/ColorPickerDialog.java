// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.ui;

import android.app.AlertDialog;
import android.app.Dialog;
import android.content.Context;
import android.content.DialogInterface;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

/**
 * UI for the color chooser that shows on the Android platform as a result of
 * &lt;input type=color &gt; form element.
 */
public class ColorPickerDialog extends AlertDialog implements OnColorChangedListener {
    private final ColorPickerAdvanced mAdvancedColorPicker;

    private final ColorPickerSimple mSimpleColorPicker;

    private final Button mMoreButton;

    // The view up in the corner that shows the user the color they've currently selected.
    private final View mCurrentColorView;

    private final OnColorChangedListener mListener;

    private final int mInitialColor;

    private int mCurrentColor;

    /**
     * @param context The context the dialog is to run in.
     * @param listener The object to notify when the color is set.
     * @param color The initial color to set.
     * @param suggestions The list of suggestions.
     */
    public ColorPickerDialog(Context context,
                             OnColorChangedListener listener,
                             int color,
                             ColorSuggestion[] suggestions) {
        super(context, 0);

        mListener = listener;
        mInitialColor = color;
        mCurrentColor = mInitialColor;

        // Initialize title
        LayoutInflater inflater = (LayoutInflater) context
                .getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        View title = inflater.inflate(R.layout.color_picker_dialog_title, null);
        setCustomTitle(title);

        mCurrentColorView = title.findViewById(R.id.selected_color_view);

        TextView titleText = (TextView) title.findViewById(R.id.title);
        titleText.setText(R.string.color_picker_dialog_title);

        // Initialize Set/Cancel buttons
        String positiveButtonText = context.getString(R.string.color_picker_button_set);
        setButton(BUTTON_POSITIVE, positiveButtonText,
                new Dialog.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialogInterface, int i) {
                        tryNotifyColorSet(mCurrentColor);
                    }
                });

        // Note that with the color picker there's not really any such thing as
        // "cancelled".
        // The color picker flow only finishes when we return a color, so we
        // have to always
        // return something. The concept of "cancelled" in this case just means
        // returning
        // the color that we were initialized with.
        String negativeButtonText = context.getString(R.string.color_picker_button_cancel);
        setButton(BUTTON_NEGATIVE, negativeButtonText,
                new Dialog.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialogInterface, int i) {
                        tryNotifyColorSet(mInitialColor);
                    }
                });

        setOnCancelListener(new DialogInterface.OnCancelListener() {
            @Override
            public void onCancel(DialogInterface arg0) {
                tryNotifyColorSet(mInitialColor);
            }
        });

        // Initialize main content view
        View content = inflater.inflate(R.layout.color_picker_dialog_content, null);
        setView(content);

        // Initialize More button.
        mMoreButton = (Button) content.findViewById(R.id.more_colors_button);
        mMoreButton.setOnClickListener(new Button.OnClickListener() {
            @Override
            public void onClick(View v) {
                showAdvancedView();
            }
        });

        // Initialize advanced color view (hidden initially).
        mAdvancedColorPicker =
                (ColorPickerAdvanced) content.findViewById(R.id.color_picker_advanced);
        mAdvancedColorPicker.setVisibility(View.GONE);

        // Initialize simple color view (default view).
        mSimpleColorPicker = (ColorPickerSimple) content.findViewById(R.id.color_picker_simple);
        mSimpleColorPicker.init(suggestions, this);

        updateCurrentColor(mInitialColor);
    }

    /**
     * Listens to the ColorPicker for when the user has changed the selected color, and
     * updates the current color (the color shown in the title) accordingly.
     *
     * @param color The new color chosen by the user.
     */
    @Override
    public void onColorChanged(int color) {
        updateCurrentColor(color);
    }

    /**
     * Hides the simple view (the default) and shows the advanced one instead, hiding the
     * "More" button at the same time.
     */
    private void showAdvancedView() {
        // Only need to hide the borders, not the Views themselves, since the Views are
        // contained within the borders.
        View buttonBorder = findViewById(R.id.more_colors_button_border);
        buttonBorder.setVisibility(View.GONE);

        View simpleView = findViewById(R.id.color_picker_simple);
        simpleView.setVisibility(View.GONE);

        mAdvancedColorPicker.setVisibility(View.VISIBLE);
        mAdvancedColorPicker.setListener(this);
        mAdvancedColorPicker.setColor(mCurrentColor);
    }

    /**
     * Tries to notify any listeners that the color has been set.
     */
    private void tryNotifyColorSet(int color) {
        if (mListener != null) mListener.onColorChanged(color);
    }

    /**
     * Updates the internal cache of the currently selected color, updating the colorful little
     * box in the title at the same time.
     */
    private void updateCurrentColor(int color) {
        mCurrentColor = color;
        if (mCurrentColorView != null) mCurrentColorView.setBackgroundColor(color);
    }
}
