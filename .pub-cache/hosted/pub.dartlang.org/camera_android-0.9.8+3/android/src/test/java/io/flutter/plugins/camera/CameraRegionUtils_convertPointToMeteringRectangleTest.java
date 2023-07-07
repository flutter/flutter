// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
package io.flutter.plugins.camera;

import static org.junit.Assert.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.when;

import android.hardware.camera2.params.MeteringRectangle;
import android.util.Size;
import io.flutter.embedding.engine.systemchannels.PlatformChannel;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.mockito.MockedStatic;
import org.mockito.invocation.InvocationOnMock;
import org.mockito.stubbing.Answer;

public class CameraRegionUtils_convertPointToMeteringRectangleTest {
  private MockedStatic<CameraRegionUtils.MeteringRectangleFactory> mockedMeteringRectangleFactory;
  private Size mockCameraBoundaries;

  @Before
  public void setUp() {
    this.mockCameraBoundaries = mock(Size.class);
    when(this.mockCameraBoundaries.getWidth()).thenReturn(100);
    when(this.mockCameraBoundaries.getHeight()).thenReturn(100);
    mockedMeteringRectangleFactory = mockStatic(CameraRegionUtils.MeteringRectangleFactory.class);

    mockedMeteringRectangleFactory
        .when(
            () ->
                CameraRegionUtils.MeteringRectangleFactory.create(
                    anyInt(), anyInt(), anyInt(), anyInt(), anyInt()))
        .thenAnswer(
            new Answer<MeteringRectangle>() {
              @Override
              public MeteringRectangle answer(InvocationOnMock createInvocation) throws Throwable {
                MeteringRectangle mockMeteringRectangle = mock(MeteringRectangle.class);
                when(mockMeteringRectangle.getX()).thenReturn(createInvocation.getArgument(0));
                when(mockMeteringRectangle.getY()).thenReturn(createInvocation.getArgument(1));
                when(mockMeteringRectangle.getWidth()).thenReturn(createInvocation.getArgument(2));
                when(mockMeteringRectangle.getHeight()).thenReturn(createInvocation.getArgument(3));
                when(mockMeteringRectangle.getMeteringWeight())
                    .thenReturn(createInvocation.getArgument(4));
                when(mockMeteringRectangle.equals(any()))
                    .thenAnswer(
                        new Answer<Boolean>() {
                          @Override
                          public Boolean answer(InvocationOnMock equalsInvocation)
                              throws Throwable {
                            MeteringRectangle otherMockMeteringRectangle =
                                equalsInvocation.getArgument(0);
                            return mockMeteringRectangle.getX() == otherMockMeteringRectangle.getX()
                                && mockMeteringRectangle.getY() == otherMockMeteringRectangle.getY()
                                && mockMeteringRectangle.getWidth()
                                    == otherMockMeteringRectangle.getWidth()
                                && mockMeteringRectangle.getHeight()
                                    == otherMockMeteringRectangle.getHeight()
                                && mockMeteringRectangle.getMeteringWeight()
                                    == otherMockMeteringRectangle.getMeteringWeight();
                          }
                        });
                return mockMeteringRectangle;
              }
            });
  }

  @After
  public void tearDown() {
    mockedMeteringRectangleFactory.close();
  }

  @Test
  public void convertPointToMeteringRectangle_shouldReturnValidMeteringRectangleForCenterCoord() {
    MeteringRectangle r =
        CameraRegionUtils.convertPointToMeteringRectangle(
            this.mockCameraBoundaries, 0.5, 0.5, PlatformChannel.DeviceOrientation.LANDSCAPE_LEFT);
    assertTrue(CameraRegionUtils.MeteringRectangleFactory.create(45, 45, 10, 10, 1).equals(r));
  }

  @Test
  public void convertPointToMeteringRectangle_shouldReturnValidMeteringRectangleForTopLeftCoord() {
    MeteringRectangle r =
        CameraRegionUtils.convertPointToMeteringRectangle(
            this.mockCameraBoundaries, 0, 0, PlatformChannel.DeviceOrientation.LANDSCAPE_LEFT);
    assertTrue(CameraRegionUtils.MeteringRectangleFactory.create(0, 0, 10, 10, 1).equals(r));
  }

  @Test
  public void convertPointToMeteringRectangle_ShouldReturnValidMeteringRectangleForTopRightCoord() {
    MeteringRectangle r =
        CameraRegionUtils.convertPointToMeteringRectangle(
            this.mockCameraBoundaries, 1, 0, PlatformChannel.DeviceOrientation.LANDSCAPE_LEFT);
    assertTrue(CameraRegionUtils.MeteringRectangleFactory.create(89, 0, 10, 10, 1).equals(r));
  }

  @Test
  public void
      convertPointToMeteringRectangle_shouldReturnValidMeteringRectangleForBottomLeftCoord() {
    MeteringRectangle r =
        CameraRegionUtils.convertPointToMeteringRectangle(
            this.mockCameraBoundaries, 0, 1, PlatformChannel.DeviceOrientation.LANDSCAPE_LEFT);
    assertTrue(CameraRegionUtils.MeteringRectangleFactory.create(0, 89, 10, 10, 1).equals(r));
  }

  @Test
  public void
      convertPointToMeteringRectangle_shouldReturnValidMeteringRectangleForBottomRightCoord() {
    MeteringRectangle r =
        CameraRegionUtils.convertPointToMeteringRectangle(
            this.mockCameraBoundaries, 1, 1, PlatformChannel.DeviceOrientation.LANDSCAPE_LEFT);
    assertTrue(CameraRegionUtils.MeteringRectangleFactory.create(89, 89, 10, 10, 1).equals(r));
  }

  @Test(expected = AssertionError.class)
  public void convertPointToMeteringRectangle_shouldThrowForXUpperBound() {
    CameraRegionUtils.convertPointToMeteringRectangle(
        this.mockCameraBoundaries, 1.5, 0, PlatformChannel.DeviceOrientation.PORTRAIT_UP);
  }

  @Test(expected = AssertionError.class)
  public void convertPointToMeteringRectangle_shouldThrowForXLowerBound() {
    CameraRegionUtils.convertPointToMeteringRectangle(
        this.mockCameraBoundaries, -0.5, 0, PlatformChannel.DeviceOrientation.PORTRAIT_UP);
  }

  @Test(expected = AssertionError.class)
  public void convertPointToMeteringRectangle_shouldThrowForYUpperBound() {
    CameraRegionUtils.convertPointToMeteringRectangle(
        this.mockCameraBoundaries, 0, 1.5, PlatformChannel.DeviceOrientation.PORTRAIT_UP);
  }

  @Test(expected = AssertionError.class)
  public void convertPointToMeteringRectangle_shouldThrowForYLowerBound() {
    CameraRegionUtils.convertPointToMeteringRectangle(
        this.mockCameraBoundaries, 0, -0.5, PlatformChannel.DeviceOrientation.PORTRAIT_UP);
  }

  @Test()
  public void
      convertPointToMeteringRectangle_shouldRotateMeteringRectangleAccordingToUiOrientationForPortraitUp() {
    MeteringRectangle r =
        CameraRegionUtils.convertPointToMeteringRectangle(
            this.mockCameraBoundaries, 1, 1, PlatformChannel.DeviceOrientation.PORTRAIT_UP);
    assertTrue(CameraRegionUtils.MeteringRectangleFactory.create(89, 0, 10, 10, 1).equals(r));
  }

  @Test()
  public void
      convertPointToMeteringRectangle_shouldRotateMeteringRectangleAccordingToUiOrientationForPortraitDown() {
    MeteringRectangle r =
        CameraRegionUtils.convertPointToMeteringRectangle(
            this.mockCameraBoundaries, 1, 1, PlatformChannel.DeviceOrientation.PORTRAIT_DOWN);
    assertTrue(CameraRegionUtils.MeteringRectangleFactory.create(0, 89, 10, 10, 1).equals(r));
  }

  @Test()
  public void
      convertPointToMeteringRectangle_shouldRotateMeteringRectangleAccordingToUiOrientationForLandscapeLeft() {
    MeteringRectangle r =
        CameraRegionUtils.convertPointToMeteringRectangle(
            this.mockCameraBoundaries, 1, 1, PlatformChannel.DeviceOrientation.LANDSCAPE_LEFT);
    assertTrue(CameraRegionUtils.MeteringRectangleFactory.create(89, 89, 10, 10, 1).equals(r));
  }

  @Test()
  public void
      convertPointToMeteringRectangle_shouldRotateMeteringRectangleAccordingToUiOrientationForLandscapeRight() {
    MeteringRectangle r =
        CameraRegionUtils.convertPointToMeteringRectangle(
            this.mockCameraBoundaries, 1, 1, PlatformChannel.DeviceOrientation.LANDSCAPE_RIGHT);
    assertTrue(CameraRegionUtils.MeteringRectangleFactory.create(0, 0, 10, 10, 1).equals(r));
  }

  @Test(expected = AssertionError.class)
  public void convertPointToMeteringRectangle_shouldThrowFor0WidthBoundary() {
    Size mockCameraBoundaries = mock(Size.class);
    when(mockCameraBoundaries.getWidth()).thenReturn(0);
    when(mockCameraBoundaries.getHeight()).thenReturn(50);
    CameraRegionUtils.convertPointToMeteringRectangle(
        mockCameraBoundaries, 0, -0.5, PlatformChannel.DeviceOrientation.PORTRAIT_UP);
  }

  @Test(expected = AssertionError.class)
  public void convertPointToMeteringRectangle_shouldThrowFor0HeightBoundary() {
    Size mockCameraBoundaries = mock(Size.class);
    when(mockCameraBoundaries.getWidth()).thenReturn(50);
    when(mockCameraBoundaries.getHeight()).thenReturn(0);
    CameraRegionUtils.convertPointToMeteringRectangle(
        this.mockCameraBoundaries, 0, -0.5, PlatformChannel.DeviceOrientation.PORTRAIT_UP);
  }
}
