// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera;

import static org.junit.Assert.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.app.Activity;
import android.hardware.camera2.CameraCaptureSession;
import android.hardware.camera2.CaptureRequest;
import android.media.CamcorderProfile;
import android.media.EncoderProfiles;
import android.os.Handler;
import android.os.HandlerThread;
import androidx.annotation.NonNull;
import io.flutter.plugins.camera.features.CameraFeatureFactory;
import io.flutter.plugins.camera.features.autofocus.AutoFocusFeature;
import io.flutter.plugins.camera.features.exposurelock.ExposureLockFeature;
import io.flutter.plugins.camera.features.exposureoffset.ExposureOffsetFeature;
import io.flutter.plugins.camera.features.exposurepoint.ExposurePointFeature;
import io.flutter.plugins.camera.features.flash.FlashFeature;
import io.flutter.plugins.camera.features.focuspoint.FocusPointFeature;
import io.flutter.plugins.camera.features.fpsrange.FpsRangeFeature;
import io.flutter.plugins.camera.features.noisereduction.NoiseReductionFeature;
import io.flutter.plugins.camera.features.resolution.ResolutionFeature;
import io.flutter.plugins.camera.features.resolution.ResolutionPreset;
import io.flutter.plugins.camera.features.sensororientation.SensorOrientationFeature;
import io.flutter.plugins.camera.features.zoomlevel.ZoomLevelFeature;
import io.flutter.view.TextureRegistry;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.MockedStatic;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@RunWith(RobolectricTestRunner.class)
public class CameraTest_getRecordingProfileTest {

  private CameraProperties mockCameraProperties;
  private CameraFeatureFactory mockCameraFeatureFactory;
  private DartMessenger mockDartMessenger;
  private Camera camera;
  private CameraCaptureSession mockCaptureSession;
  private CaptureRequest.Builder mockPreviewRequestBuilder;
  private MockedStatic<Camera.HandlerThreadFactory> mockHandlerThreadFactory;
  private HandlerThread mockHandlerThread;
  private MockedStatic<Camera.HandlerFactory> mockHandlerFactory;
  private Handler mockHandler;

  @Before
  public void before() {
    mockCameraProperties = mock(CameraProperties.class);
    mockCameraFeatureFactory = new TestCameraFeatureFactory();
    mockDartMessenger = mock(DartMessenger.class);

    final Activity mockActivity = mock(Activity.class);
    final TextureRegistry.SurfaceTextureEntry mockFlutterTexture =
        mock(TextureRegistry.SurfaceTextureEntry.class);
    final ResolutionPreset resolutionPreset = ResolutionPreset.high;
    final boolean enableAudio = false;

    camera =
        new Camera(
            mockActivity,
            mockFlutterTexture,
            mockCameraFeatureFactory,
            mockDartMessenger,
            mockCameraProperties,
            resolutionPreset,
            enableAudio);
  }

  @Config(maxSdk = 30)
  @Test
  public void getRecordingProfileLegacy() {
    ResolutionFeature mockResolutionFeature =
        mockCameraFeatureFactory.createResolutionFeature(mockCameraProperties, null, null);
    CamcorderProfile mockCamcorderProfile = mock(CamcorderProfile.class);

    when(mockResolutionFeature.getRecordingProfileLegacy()).thenReturn(mockCamcorderProfile);

    CamcorderProfile actualRecordingProfile = camera.getRecordingProfileLegacy();

    verify(mockResolutionFeature, times(1)).getRecordingProfileLegacy();
    assertEquals(mockCamcorderProfile, actualRecordingProfile);
  }

  @Config(minSdk = 31)
  @Test
  public void getRecordingProfile() {
    ResolutionFeature mockResolutionFeature =
        mockCameraFeatureFactory.createResolutionFeature(mockCameraProperties, null, null);
    EncoderProfiles mockRecordingProfile = mock(EncoderProfiles.class);

    when(mockResolutionFeature.getRecordingProfile()).thenReturn(mockRecordingProfile);

    EncoderProfiles actualRecordingProfile = camera.getRecordingProfile();

    verify(mockResolutionFeature, times(1)).getRecordingProfile();
    assertEquals(mockRecordingProfile, actualRecordingProfile);
  }

  private static class TestCameraFeatureFactory implements CameraFeatureFactory {
    private final AutoFocusFeature mockAutoFocusFeature;
    private final ExposureLockFeature mockExposureLockFeature;
    private final ExposureOffsetFeature mockExposureOffsetFeature;
    private final ExposurePointFeature mockExposurePointFeature;
    private final FlashFeature mockFlashFeature;
    private final FocusPointFeature mockFocusPointFeature;
    private final FpsRangeFeature mockFpsRangeFeature;
    private final NoiseReductionFeature mockNoiseReductionFeature;
    private final ResolutionFeature mockResolutionFeature;
    private final SensorOrientationFeature mockSensorOrientationFeature;
    private final ZoomLevelFeature mockZoomLevelFeature;

    public TestCameraFeatureFactory() {
      this.mockAutoFocusFeature = mock(AutoFocusFeature.class);
      this.mockExposureLockFeature = mock(ExposureLockFeature.class);
      this.mockExposureOffsetFeature = mock(ExposureOffsetFeature.class);
      this.mockExposurePointFeature = mock(ExposurePointFeature.class);
      this.mockFlashFeature = mock(FlashFeature.class);
      this.mockFocusPointFeature = mock(FocusPointFeature.class);
      this.mockFpsRangeFeature = mock(FpsRangeFeature.class);
      this.mockNoiseReductionFeature = mock(NoiseReductionFeature.class);
      this.mockResolutionFeature = mock(ResolutionFeature.class);
      this.mockSensorOrientationFeature = mock(SensorOrientationFeature.class);
      this.mockZoomLevelFeature = mock(ZoomLevelFeature.class);
    }

    @Override
    public AutoFocusFeature createAutoFocusFeature(
        @NonNull CameraProperties cameraProperties, boolean recordingVideo) {
      return mockAutoFocusFeature;
    }

    @Override
    public ExposureLockFeature createExposureLockFeature(
        @NonNull CameraProperties cameraProperties) {
      return mockExposureLockFeature;
    }

    @Override
    public ExposureOffsetFeature createExposureOffsetFeature(
        @NonNull CameraProperties cameraProperties) {
      return mockExposureOffsetFeature;
    }

    @Override
    public FlashFeature createFlashFeature(@NonNull CameraProperties cameraProperties) {
      return mockFlashFeature;
    }

    @Override
    public ResolutionFeature createResolutionFeature(
        @NonNull CameraProperties cameraProperties,
        ResolutionPreset initialSetting,
        String cameraName) {
      return mockResolutionFeature;
    }

    @Override
    public FocusPointFeature createFocusPointFeature(
        @NonNull CameraProperties cameraProperties,
        @NonNull SensorOrientationFeature sensorOrienttionFeature) {
      return mockFocusPointFeature;
    }

    @Override
    public FpsRangeFeature createFpsRangeFeature(@NonNull CameraProperties cameraProperties) {
      return mockFpsRangeFeature;
    }

    @Override
    public SensorOrientationFeature createSensorOrientationFeature(
        @NonNull CameraProperties cameraProperties,
        @NonNull Activity activity,
        @NonNull DartMessenger dartMessenger) {
      return mockSensorOrientationFeature;
    }

    @Override
    public ZoomLevelFeature createZoomLevelFeature(@NonNull CameraProperties cameraProperties) {
      return mockZoomLevelFeature;
    }

    @Override
    public ExposurePointFeature createExposurePointFeature(
        @NonNull CameraProperties cameraProperties,
        @NonNull SensorOrientationFeature sensorOrientationFeature) {
      return mockExposurePointFeature;
    }

    @Override
    public NoiseReductionFeature createNoiseReductionFeature(
        @NonNull CameraProperties cameraProperties) {
      return mockNoiseReductionFeature;
    }
  }
}
