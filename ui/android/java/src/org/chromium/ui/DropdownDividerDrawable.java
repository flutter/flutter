// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.ui;

import android.graphics.Canvas;
import android.graphics.ColorFilter;
import android.graphics.Paint;
import android.graphics.PixelFormat;
import android.graphics.Rect;
import android.graphics.drawable.Drawable;

class DropdownDividerDrawable extends Drawable {

    private Paint mPaint;
    private Rect mDividerRect;

    public DropdownDividerDrawable() {
        mPaint = new Paint();
        mDividerRect = new Rect();
    }

    @Override
    public void draw(Canvas canvas) {
        canvas.drawRect(mDividerRect, mPaint);
    }

    @Override
    public void onBoundsChange(Rect bounds) {
        mDividerRect.set(0, 0, bounds.width(), mDividerRect.height());
    }

    public void setHeight(int height) {
        mDividerRect.set(0, 0, mDividerRect.right, height);
    }

    public void setColor(int color) {
        mPaint.setColor(color);
    }

    @Override
    public void setAlpha(int alpha) {
    }

    @Override
    public void setColorFilter(ColorFilter cf) {
    }

    @Override
    public int getOpacity() {
        return PixelFormat.OPAQUE;
    }
}
