// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.media.Image;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.mockito.MockedStatic;
import org.mockito.invocation.InvocationOnMock;
import org.mockito.stubbing.Answer;

public class ImageSaverTests {

  Image mockImage;
  File mockFile;
  ImageSaver.Callback mockCallback;
  ImageSaver imageSaver;
  Image.Plane mockPlane;
  ByteBuffer mockBuffer;
  MockedStatic<ImageSaver.FileOutputStreamFactory> mockFileOutputStreamFactory;
  FileOutputStream mockFileOutputStream;

  @Before
  public void setup() {
    // Set up mocked file dependency
    mockFile = mock(File.class);
    when(mockFile.getAbsolutePath()).thenReturn("absolute/path");
    mockPlane = mock(Image.Plane.class);
    mockBuffer = mock(ByteBuffer.class);
    when(mockBuffer.remaining()).thenReturn(3);
    when(mockBuffer.get(any()))
        .thenAnswer(
            new Answer<Object>() {
              @Override
              public Object answer(InvocationOnMock invocation) throws Throwable {
                byte[] bytes = invocation.getArgument(0);
                bytes[0] = 0x42;
                bytes[1] = 0x00;
                bytes[2] = 0x13;
                return mockBuffer;
              }
            });

    // Set up mocked image dependency
    mockImage = mock(Image.class);
    when(mockPlane.getBuffer()).thenReturn(mockBuffer);
    when(mockImage.getPlanes()).thenReturn(new Image.Plane[] {mockPlane});

    // Set up mocked FileOutputStream
    mockFileOutputStreamFactory = mockStatic(ImageSaver.FileOutputStreamFactory.class);
    mockFileOutputStream = mock(FileOutputStream.class);
    mockFileOutputStreamFactory
        .when(() -> ImageSaver.FileOutputStreamFactory.create(any()))
        .thenReturn(mockFileOutputStream);

    // Set up testable ImageSaver instance
    mockCallback = mock(ImageSaver.Callback.class);
    imageSaver = new ImageSaver(mockImage, mockFile, mockCallback);
  }

  @After
  public void teardown() {
    mockFileOutputStreamFactory.close();
  }

  @Test
  public void runWritesBytesToFileAndFinishesWithPath() throws IOException {
    imageSaver.run();

    verify(mockFileOutputStream, times(1)).write(new byte[] {0x42, 0x00, 0x13});
    verify(mockCallback, times(1)).onComplete("absolute/path");
    verify(mockCallback, never()).onError(any(), any());
  }

  @Test
  public void runCallsErrorOnWriteIoexception() throws IOException {
    doThrow(new IOException()).when(mockFileOutputStream).write(any());
    imageSaver.run();
    verify(mockCallback, times(1)).onError("IOError", "Failed saving image");
    verify(mockCallback, never()).onComplete(any());
  }

  @Test
  public void runCallsErrorOnCloseIoexception() throws IOException {
    doThrow(new IOException("message")).when(mockFileOutputStream).close();
    imageSaver.run();
    verify(mockCallback, times(1)).onError("cameraAccess", "message");
  }
}
