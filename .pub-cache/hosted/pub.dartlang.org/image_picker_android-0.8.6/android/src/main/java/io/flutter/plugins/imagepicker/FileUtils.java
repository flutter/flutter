// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/*
 * Copyright (C) 2007-2008 OpenIntents.org
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * This file was modified by the Flutter authors from the following original file:
 * https://raw.githubusercontent.com/iPaulPro/aFileChooser/master/aFileChooser/src/com/ipaulpro/afilechooser/utils/FileUtils.java
 */

package io.flutter.plugins.imagepicker;

import android.content.ContentResolver;
import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.provider.MediaStore;
import android.webkit.MimeTypeMap;
import io.flutter.Log;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.UUID;

class FileUtils {
  /**
   * Copies the file from the given content URI to a temporary directory, retaining the original
   * file name if possible.
   *
   * <p>Each file is placed in its own directory to avoid conflicts according to the following
   * scheme: {cacheDir}/{randomUuid}/{fileName}
   *
   * <p>If the original file name is unknown, a predefined "image_picker" filename is used and the
   * file extension is deduced from the mime type (with fallback to ".jpg" in case of failure).
   */
  String getPathFromUri(final Context context, final Uri uri) {
    try (InputStream inputStream = context.getContentResolver().openInputStream(uri)) {
      String uuid = UUID.randomUUID().toString();
      File targetDirectory = new File(context.getCacheDir(), uuid);
      targetDirectory.mkdir();
      // TODO(SynSzakala) according to the docs, `deleteOnExit` does not work reliably on Android; we should preferably
      //  just clear the picked files after the app startup.
      targetDirectory.deleteOnExit();
      String fileName = getImageName(context, uri);
      if (fileName == null) {
        Log.w("FileUtils", "Cannot get file name for " + uri);
        fileName = "image_picker" + getImageExtension(context, uri);
      }
      File file = new File(targetDirectory, fileName);
      try (OutputStream outputStream = new FileOutputStream(file)) {
        copy(inputStream, outputStream);
        return file.getPath();
      }
    } catch (IOException e) {
      // If closing the output stream fails, we cannot be sure that the
      // target file was written in full. Flushing the stream merely moves
      // the bytes into the OS, not necessarily to the file.
      return null;
    }
  }

  /** @return extension of image with dot, or default .jpg if it none. */
  private static String getImageExtension(Context context, Uri uriImage) {
    String extension;

    try {
      if (uriImage.getScheme().equals(ContentResolver.SCHEME_CONTENT)) {
        final MimeTypeMap mime = MimeTypeMap.getSingleton();
        extension = mime.getExtensionFromMimeType(context.getContentResolver().getType(uriImage));
      } else {
        extension =
            MimeTypeMap.getFileExtensionFromUrl(
                Uri.fromFile(new File(uriImage.getPath())).toString());
      }
    } catch (Exception e) {
      extension = null;
    }

    if (extension == null || extension.isEmpty()) {
      //default extension for matches the previous behavior of the plugin
      extension = "jpg";
    }

    return "." + extension;
  }

  /** @return name of the image provided by ContentResolver; this may be null. */
  private static String getImageName(Context context, Uri uriImage) {
    try (Cursor cursor = queryImageName(context, uriImage)) {
      if (cursor == null || !cursor.moveToFirst() || cursor.getColumnCount() < 1) return null;
      return cursor.getString(0);
    }
  }

  private static Cursor queryImageName(Context context, Uri uriImage) {
    return context
        .getContentResolver()
        .query(uriImage, new String[] {MediaStore.MediaColumns.DISPLAY_NAME}, null, null, null);
  }

  private static void copy(InputStream in, OutputStream out) throws IOException {
    final byte[] buffer = new byte[4 * 1024];
    int bytesRead;
    while ((bytesRead = in.read(buffer)) != -1) {
      out.write(buffer, 0, bytesRead);
    }
    out.flush();
  }
}
