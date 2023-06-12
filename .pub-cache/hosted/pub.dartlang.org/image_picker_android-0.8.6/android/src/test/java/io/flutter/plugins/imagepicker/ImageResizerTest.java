// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.imagepicker;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.core.IsEqual.equalTo;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import java.io.File;
import java.io.IOException;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import org.junit.runner.RunWith;
import org.mockito.MockitoAnnotations;
import org.robolectric.RobolectricTestRunner;

// RobolectricTestRunner always creates a default mock bitmap when reading from file. So we cannot actually test the scaling.
// But we can still test whether the original or scaled file is created.
@RunWith(RobolectricTestRunner.class)
public class ImageResizerTest {

  ImageResizer resizer;
  File imageFile;
  File externalDirectory;
  Bitmap originalImageBitmap;

  AutoCloseable mockCloseable;

  @Before
  public void setUp() throws IOException {
    mockCloseable = MockitoAnnotations.openMocks(this);
    imageFile = new File(getClass().getClassLoader().getResource("pngImage.png").getFile());
    originalImageBitmap = BitmapFactory.decodeFile(imageFile.getPath());
    TemporaryFolder temporaryFolder = new TemporaryFolder();
    temporaryFolder.create();
    externalDirectory = temporaryFolder.newFolder("image_picker_testing_path");
    resizer = new ImageResizer(externalDirectory, new ExifDataCopier());
  }

  @After
  public void tearDown() throws Exception {
    mockCloseable.close();
  }

  @Test
  public void onResizeImageIfNeeded_WhenQualityIsNull_ShoultNotResize_ReturnTheUnscaledFile() {
    String outoutFile = resizer.resizeImageIfNeeded(imageFile.getPath(), null, null, null);
    assertThat(outoutFile, equalTo(imageFile.getPath()));
  }

  @Test
  public void onResizeImageIfNeeded_WhenQualityIsNotNull_ShoulResize_ReturnResizedFile() {
    String outoutFile = resizer.resizeImageIfNeeded(imageFile.getPath(), null, null, 50);
    assertThat(outoutFile, equalTo(externalDirectory.getPath() + "/scaled_pngImage.png"));
  }

  @Test
  public void onResizeImageIfNeeded_WhenWidthIsNotNull_ShoulResize_ReturnResizedFile() {
    String outoutFile = resizer.resizeImageIfNeeded(imageFile.getPath(), 50.0, null, null);
    assertThat(outoutFile, equalTo(externalDirectory.getPath() + "/scaled_pngImage.png"));
  }

  @Test
  public void onResizeImageIfNeeded_WhenHeightIsNotNull_ShoulResize_ReturnResizedFile() {
    String outoutFile = resizer.resizeImageIfNeeded(imageFile.getPath(), null, 50.0, null);
    assertThat(outoutFile, equalTo(externalDirectory.getPath() + "/scaled_pngImage.png"));
  }

  @Test
  public void onResizeImageIfNeeded_WhenParentDirectoryDoesNotExists_ShouldNotCrash() {
    File nonExistentDirectory = new File(externalDirectory, "/nonExistent");
    ImageResizer invalidResizer = new ImageResizer(nonExistentDirectory, new ExifDataCopier());
    String outoutFile = invalidResizer.resizeImageIfNeeded(imageFile.getPath(), null, 50.0, null);
    assertThat(outoutFile, equalTo(nonExistentDirectory.getPath() + "/scaled_pngImage.png"));
  }
}
