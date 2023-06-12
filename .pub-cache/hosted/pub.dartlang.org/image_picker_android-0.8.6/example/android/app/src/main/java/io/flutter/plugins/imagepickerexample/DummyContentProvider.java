// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.imagepickerexample;

import android.content.ContentProvider;
import android.content.ContentValues;
import android.content.res.AssetFileDescriptor;
import android.database.Cursor;
import android.database.MatrixCursor;
import android.net.Uri;
import android.provider.MediaStore;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

public class DummyContentProvider extends ContentProvider {
  @Override
  public boolean onCreate() {
    return true;
  }

  @Nullable
  @Override
  public AssetFileDescriptor openAssetFile(@NonNull Uri uri, @NonNull String mode) {
    return getContext().getResources().openRawResourceFd(R.raw.ic_launcher);
  }

  @Nullable
  @Override
  public Cursor query(
      @NonNull Uri uri,
      @Nullable String[] projection,
      @Nullable String selection,
      @Nullable String[] selectionArgs,
      @Nullable String sortOrder) {
    MatrixCursor cursor = new MatrixCursor(new String[] {MediaStore.MediaColumns.DISPLAY_NAME});
    cursor.addRow(new Object[] {"dummy.png"});
    return cursor;
  }

  @Nullable
  @Override
  public String getType(@NonNull Uri uri) {
    return "image/png";
  }

  @Nullable
  @Override
  public Uri insert(@NonNull Uri uri, @Nullable ContentValues values) {
    return null;
  }

  @Override
  public int delete(
      @NonNull Uri uri, @Nullable String selection, @Nullable String[] selectionArgs) {
    return 0;
  }

  @Override
  public int update(
      @NonNull Uri uri,
      @Nullable ContentValues values,
      @Nullable String selection,
      @Nullable String[] selectionArgs) {
    return 0;
  }
}
