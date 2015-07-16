// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.ui;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.util.AttributeSet;
import android.widget.Button;

/**
 * Simple class that draws a white border around a button, purely for a UI change.
 */
public class ColorPickerMoreButton extends Button {

    // A cache for the paint used to draw the border, so it doesn't have to be created in
    // every onDraw() call.
    private Paint mBorderPaint;

    public ColorPickerMoreButton(Context context, AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    public ColorPickerMoreButton(Context context, AttributeSet attrs, int defStyle) {
        super(context, attrs, defStyle);
        init();
    }

    /**
     * Sets up the paint to use for drawing the border.
     */
    public void init() {
        mBorderPaint = new Paint();
        mBorderPaint.setStyle(Paint.Style.STROKE);
        mBorderPaint.setColor(Color.WHITE);
        // Set the width to one pixel.
        mBorderPaint.setStrokeWidth(1.0f);
        // And make sure the border doesn't bleed into the outside.
        mBorderPaint.setAntiAlias(false);
    }

    /**
     * Draws the border around the edge of the button.
     *
     * @param canvas The canvas to draw on.
     */
    @Override
    protected void onDraw(Canvas canvas) {
        canvas.drawRect(0.5f, 0.5f, getWidth() - 1.5f, getHeight() - 1.5f, mBorderPaint);
        super.onDraw(canvas);
    }
}
