// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.imagepicker;

import static java.nio.charset.StandardCharsets.UTF_8;
import static org.junit.Assert.assertTrue;
import static org.robolectric.Shadows.shadowOf;

import android.content.ContentProvider;
import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.MatrixCursor;
import android.net.Uri;
import android.provider.MediaStore;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.test.core.app.ApplicationProvider;
import java.io.BufferedInputStream;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.shadows.ShadowContentResolver;

@RunWith(RobolectricTestRunner.class)
public class FileUtilTest {

  private Context context;
  private FileUtils fileUtils;
  ShadowContentResolver shadowContentResolver;

  @Before
  public void before() {
    context = ApplicationProvider.getApplicationContext();
    shadowContentResolver = shadowOf(context.getContentResolver());
    fileUtils = new FileUtils();
  }

  @Test
  public void FileUtil_GetPathFromUri() throws IOException {
    Uri uri = Uri.parse("content://dummy/dummy.png");
    shadowContentResolver.registerInputStream(
        uri, new ByteArrayInputStream("imageStream".getBytes(UTF_8)));
    String path = fileUtils.getPathFromUri(context, uri);
    File file = new File(path);
    int size = (int) file.length();
    byte[] bytes = new byte[size];

    BufferedInputStream buf = new BufferedInputStream(new FileInputStream(file));
    buf.read(bytes, 0, bytes.length);
    buf.close();

    assertTrue(bytes.length > 0);
    String imageStream = new String(bytes, UTF_8);
    assertTrue(imageStream.equals("imageStream"));
  }

  @Test
  public void FileUtil_getImageExtension() throws IOException {
    Uri uri = Uri.parse("content://dummy/dummy.png");
    shadowContentResolver.registerInputStream(
        uri, new ByteArrayInputStream("imageStream".getBytes(UTF_8)));
    String path = fileUtils.getPathFromUri(context, uri);
    assertTrue(path.endsWith(".jpg"));
  }

  @Test
  public void FileUtil_getImageName() throws IOException {
    Uri uri = Uri.parse("content://dummy/dummy.png");
    Robolectric.buildContentProvider(MockContentProvider.class).create("dummy");
    shadowContentResolver.registerInputStream(
        uri, new ByteArrayInputStream("imageStream".getBytes(UTF_8)));
    String path = fileUtils.getPathFromUri(context, uri);
    assertTrue(path.endsWith("dummy.png"));
  }

  private static class MockContentProvider extends ContentProvider {

    @Override
    public boolean onCreate() {
      return true;
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
}
