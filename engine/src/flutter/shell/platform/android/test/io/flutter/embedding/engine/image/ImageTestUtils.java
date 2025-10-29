// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.image;

import android.graphics.Bitmap;
import android.graphics.Color;
import java.io.ByteArrayOutputStream;

public class ImageTestUtils {
  // This helper generates a valid PNG byte array. For this test, the actual image format
  // doesn't matter, only that BitmapFactory can decode it into a Bitmap object.
  static byte[] createTestImageBytes(int width, int height) {
    Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
    ByteArrayOutputStream stream = new ByteArrayOutputStream();
    bitmap.setPixel(0, 0, Color.BLUE);
    bitmap.setPixel(0, height - 1, Color.WHITE);
    bitmap.setPixel(width - 1, 0, Color.BLACK);
    bitmap.setPixel(width - 1, height - 1, Color.RED);
    bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream);
    bitmap.recycle();
    return stream.toByteArray();
  }
}
