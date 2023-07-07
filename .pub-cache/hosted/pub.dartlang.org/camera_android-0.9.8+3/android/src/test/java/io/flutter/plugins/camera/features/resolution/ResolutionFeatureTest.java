// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera.features.resolution;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.when;

import android.media.CamcorderProfile;
import android.media.EncoderProfiles;
import io.flutter.plugins.camera.CameraProperties;
import java.util.List;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.MockedStatic;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@RunWith(RobolectricTestRunner.class)
public class ResolutionFeatureTest {
  private static final String cameraName = "1";
  private CamcorderProfile mockProfileLowLegacy;
  private EncoderProfiles mockProfileLow;
  private MockedStatic<CamcorderProfile> mockedStaticProfile;

  @Before
  @SuppressWarnings("deprecation")
  public void beforeLegacy() {
    mockedStaticProfile = mockStatic(CamcorderProfile.class);
    mockProfileLowLegacy = mock(CamcorderProfile.class);
    CamcorderProfile mockProfileLegacy = mock(CamcorderProfile.class);

    mockedStaticProfile
        .when(() -> CamcorderProfile.hasProfile(1, CamcorderProfile.QUALITY_HIGH))
        .thenReturn(true);
    mockedStaticProfile
        .when(() -> CamcorderProfile.hasProfile(1, CamcorderProfile.QUALITY_2160P))
        .thenReturn(true);
    mockedStaticProfile
        .when(() -> CamcorderProfile.hasProfile(1, CamcorderProfile.QUALITY_1080P))
        .thenReturn(true);
    mockedStaticProfile
        .when(() -> CamcorderProfile.hasProfile(1, CamcorderProfile.QUALITY_720P))
        .thenReturn(true);
    mockedStaticProfile
        .when(() -> CamcorderProfile.hasProfile(1, CamcorderProfile.QUALITY_480P))
        .thenReturn(true);
    mockedStaticProfile
        .when(() -> CamcorderProfile.hasProfile(1, CamcorderProfile.QUALITY_QVGA))
        .thenReturn(true);
    mockedStaticProfile
        .when(() -> CamcorderProfile.hasProfile(1, CamcorderProfile.QUALITY_LOW))
        .thenReturn(true);

    mockedStaticProfile
        .when(() -> CamcorderProfile.get(1, CamcorderProfile.QUALITY_HIGH))
        .thenReturn(mockProfileLegacy);
    mockedStaticProfile
        .when(() -> CamcorderProfile.get(1, CamcorderProfile.QUALITY_2160P))
        .thenReturn(mockProfileLegacy);
    mockedStaticProfile
        .when(() -> CamcorderProfile.get(1, CamcorderProfile.QUALITY_1080P))
        .thenReturn(mockProfileLegacy);
    mockedStaticProfile
        .when(() -> CamcorderProfile.get(1, CamcorderProfile.QUALITY_720P))
        .thenReturn(mockProfileLegacy);
    mockedStaticProfile
        .when(() -> CamcorderProfile.get(1, CamcorderProfile.QUALITY_480P))
        .thenReturn(mockProfileLegacy);
    mockedStaticProfile
        .when(() -> CamcorderProfile.get(1, CamcorderProfile.QUALITY_QVGA))
        .thenReturn(mockProfileLegacy);
    mockedStaticProfile
        .when(() -> CamcorderProfile.get(1, CamcorderProfile.QUALITY_LOW))
        .thenReturn(mockProfileLowLegacy);
  }

  public void before() {
    mockProfileLow = mock(EncoderProfiles.class);
    EncoderProfiles mockProfile = mock(EncoderProfiles.class);
    EncoderProfiles.VideoProfile mockVideoProfile = mock(EncoderProfiles.VideoProfile.class);
    List<EncoderProfiles.VideoProfile> mockVideoProfilesList = List.of(mockVideoProfile);

    mockedStaticProfile
        .when(() -> CamcorderProfile.getAll("1", CamcorderProfile.QUALITY_HIGH))
        .thenReturn(mockProfile);
    mockedStaticProfile
        .when(() -> CamcorderProfile.getAll("1", CamcorderProfile.QUALITY_2160P))
        .thenReturn(mockProfile);
    mockedStaticProfile
        .when(() -> CamcorderProfile.getAll("1", CamcorderProfile.QUALITY_1080P))
        .thenReturn(mockProfile);
    mockedStaticProfile
        .when(() -> CamcorderProfile.getAll("1", CamcorderProfile.QUALITY_720P))
        .thenReturn(mockProfile);
    mockedStaticProfile
        .when(() -> CamcorderProfile.getAll("1", CamcorderProfile.QUALITY_480P))
        .thenReturn(mockProfile);
    mockedStaticProfile
        .when(() -> CamcorderProfile.getAll("1", CamcorderProfile.QUALITY_QVGA))
        .thenReturn(mockProfile);
    mockedStaticProfile
        .when(() -> CamcorderProfile.getAll("1", CamcorderProfile.QUALITY_LOW))
        .thenReturn(mockProfileLow);

    when(mockProfile.getVideoProfiles()).thenReturn(mockVideoProfilesList);
    when(mockVideoProfile.getHeight()).thenReturn(100);
    when(mockVideoProfile.getWidth()).thenReturn(100);
  }

  @After
  public void after() {
    mockedStaticProfile.reset();
    mockedStaticProfile.close();
  }

  @Test
  public void getDebugName_shouldReturnTheNameOfTheFeature() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    ResolutionFeature resolutionFeature =
        new ResolutionFeature(mockCameraProperties, ResolutionPreset.max, cameraName);

    assertEquals("ResolutionFeature", resolutionFeature.getDebugName());
  }

  @Test
  public void getValue_shouldReturnInitialValueWhenNotSet() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    ResolutionFeature resolutionFeature =
        new ResolutionFeature(mockCameraProperties, ResolutionPreset.max, cameraName);

    assertEquals(ResolutionPreset.max, resolutionFeature.getValue());
  }

  @Test
  public void getValue_shouldEchoSetValue() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    ResolutionFeature resolutionFeature =
        new ResolutionFeature(mockCameraProperties, ResolutionPreset.max, cameraName);

    resolutionFeature.setValue(ResolutionPreset.high);

    assertEquals(ResolutionPreset.high, resolutionFeature.getValue());
  }

  @Test
  public void checkIsSupport_returnsTrue() {
    CameraProperties mockCameraProperties = mock(CameraProperties.class);
    ResolutionFeature resolutionFeature =
        new ResolutionFeature(mockCameraProperties, ResolutionPreset.max, cameraName);

    assertTrue(resolutionFeature.checkIsSupported());
  }

  @Config(maxSdk = 30)
  @SuppressWarnings("deprecation")
  @Test
  public void getBestAvailableCamcorderProfileForResolutionPreset_shouldFallThroughLegacy() {
    mockedStaticProfile
        .when(() -> CamcorderProfile.hasProfile(1, CamcorderProfile.QUALITY_HIGH))
        .thenReturn(false);
    mockedStaticProfile
        .when(() -> CamcorderProfile.hasProfile(1, CamcorderProfile.QUALITY_2160P))
        .thenReturn(false);
    mockedStaticProfile
        .when(() -> CamcorderProfile.hasProfile(1, CamcorderProfile.QUALITY_1080P))
        .thenReturn(false);
    mockedStaticProfile
        .when(() -> CamcorderProfile.hasProfile(1, CamcorderProfile.QUALITY_720P))
        .thenReturn(false);
    mockedStaticProfile
        .when(() -> CamcorderProfile.hasProfile(1, CamcorderProfile.QUALITY_480P))
        .thenReturn(false);
    mockedStaticProfile
        .when(() -> CamcorderProfile.hasProfile(1, CamcorderProfile.QUALITY_QVGA))
        .thenReturn(false);
    mockedStaticProfile
        .when(() -> CamcorderProfile.hasProfile(1, CamcorderProfile.QUALITY_LOW))
        .thenReturn(true);

    assertEquals(
        mockProfileLowLegacy,
        ResolutionFeature.getBestAvailableCamcorderProfileForResolutionPresetLegacy(
            1, ResolutionPreset.max));
  }

  @Config(minSdk = 31)
  @Test
  public void getBestAvailableCamcorderProfileForResolutionPreset_shouldFallThrough() {
    mockedStaticProfile
        .when(() -> CamcorderProfile.hasProfile(1, CamcorderProfile.QUALITY_HIGH))
        .thenReturn(false);
    mockedStaticProfile
        .when(() -> CamcorderProfile.hasProfile(1, CamcorderProfile.QUALITY_2160P))
        .thenReturn(false);
    mockedStaticProfile
        .when(() -> CamcorderProfile.hasProfile(1, CamcorderProfile.QUALITY_1080P))
        .thenReturn(false);
    mockedStaticProfile
        .when(() -> CamcorderProfile.hasProfile(1, CamcorderProfile.QUALITY_720P))
        .thenReturn(false);
    mockedStaticProfile
        .when(() -> CamcorderProfile.hasProfile(1, CamcorderProfile.QUALITY_480P))
        .thenReturn(false);
    mockedStaticProfile
        .when(() -> CamcorderProfile.hasProfile(1, CamcorderProfile.QUALITY_QVGA))
        .thenReturn(false);
    mockedStaticProfile
        .when(() -> CamcorderProfile.hasProfile(1, CamcorderProfile.QUALITY_LOW))
        .thenReturn(true);

    assertEquals(
        mockProfileLow,
        ResolutionFeature.getBestAvailableCamcorderProfileForResolutionPreset(
            1, ResolutionPreset.max));
  }

  @Config(maxSdk = 30)
  @SuppressWarnings("deprecation")
  @Test
  public void computeBestPreviewSize_shouldUse720PWhenResolutionPresetMaxLegacy() {
    ResolutionFeature.computeBestPreviewSize(1, ResolutionPreset.max);

    mockedStaticProfile.verify(() -> CamcorderProfile.get(1, CamcorderProfile.QUALITY_720P));
  }

  @Config(minSdk = 31)
  @Test
  public void computeBestPreviewSize_shouldUse720PWhenResolutionPresetMax() {
    before();
    ResolutionFeature.computeBestPreviewSize(1, ResolutionPreset.max);

    mockedStaticProfile.verify(() -> CamcorderProfile.getAll("1", CamcorderProfile.QUALITY_720P));
  }

  @Config(maxSdk = 30)
  @SuppressWarnings("deprecation")
  @Test
  public void computeBestPreviewSize_shouldUse720PWhenResolutionPresetUltraHighLegacy() {
    ResolutionFeature.computeBestPreviewSize(1, ResolutionPreset.ultraHigh);

    mockedStaticProfile.verify(() -> CamcorderProfile.get(1, CamcorderProfile.QUALITY_720P));
  }

  @Config(minSdk = 31)
  @Test
  public void computeBestPreviewSize_shouldUse720PWhenResolutionPresetUltraHigh() {
    before();
    ResolutionFeature.computeBestPreviewSize(1, ResolutionPreset.ultraHigh);

    mockedStaticProfile.verify(() -> CamcorderProfile.getAll("1", CamcorderProfile.QUALITY_720P));
  }

  @Config(maxSdk = 30)
  @SuppressWarnings("deprecation")
  @Test
  public void computeBestPreviewSize_shouldUse720PWhenResolutionPresetVeryHighLegacy() {
    ResolutionFeature.computeBestPreviewSize(1, ResolutionPreset.veryHigh);

    mockedStaticProfile.verify(() -> CamcorderProfile.get(1, CamcorderProfile.QUALITY_720P));
  }

  @Config(minSdk = 31)
  @SuppressWarnings("deprecation")
  @Test
  public void computeBestPreviewSize_shouldUse720PWhenResolutionPresetVeryHigh() {
    before();
    ResolutionFeature.computeBestPreviewSize(1, ResolutionPreset.veryHigh);

    mockedStaticProfile.verify(() -> CamcorderProfile.getAll("1", CamcorderProfile.QUALITY_720P));
  }

  @Config(maxSdk = 30)
  @SuppressWarnings("deprecation")
  @Test
  public void computeBestPreviewSize_shouldUse720PWhenResolutionPresetHighLegacy() {
    ResolutionFeature.computeBestPreviewSize(1, ResolutionPreset.high);

    mockedStaticProfile.verify(() -> CamcorderProfile.get(1, CamcorderProfile.QUALITY_720P));
  }

  @Config(minSdk = 31)
  @Test
  public void computeBestPreviewSize_shouldUse720PWhenResolutionPresetHigh() {
    before();
    ResolutionFeature.computeBestPreviewSize(1, ResolutionPreset.high);

    mockedStaticProfile.verify(() -> CamcorderProfile.getAll("1", CamcorderProfile.QUALITY_720P));
  }

  @Config(maxSdk = 30)
  @SuppressWarnings("deprecation")
  @Test
  public void computeBestPreviewSize_shouldUse480PWhenResolutionPresetMediumLegacy() {
    ResolutionFeature.computeBestPreviewSize(1, ResolutionPreset.medium);

    mockedStaticProfile.verify(() -> CamcorderProfile.get(1, CamcorderProfile.QUALITY_480P));
  }

  @Config(minSdk = 31)
  @Test
  public void computeBestPreviewSize_shouldUse480PWhenResolutionPresetMedium() {
    before();
    ResolutionFeature.computeBestPreviewSize(1, ResolutionPreset.medium);

    mockedStaticProfile.verify(() -> CamcorderProfile.getAll("1", CamcorderProfile.QUALITY_480P));
  }

  @Config(maxSdk = 30)
  @SuppressWarnings("deprecation")
  @Test
  public void computeBestPreviewSize_shouldUseQVGAWhenResolutionPresetLowLegacy() {
    ResolutionFeature.computeBestPreviewSize(1, ResolutionPreset.low);

    mockedStaticProfile.verify(() -> CamcorderProfile.get(1, CamcorderProfile.QUALITY_QVGA));
  }

  @Config(minSdk = 31)
  @Test
  public void computeBestPreviewSize_shouldUseQVGAWhenResolutionPresetLow() {
    before();
    ResolutionFeature.computeBestPreviewSize(1, ResolutionPreset.low);

    mockedStaticProfile.verify(() -> CamcorderProfile.getAll("1", CamcorderProfile.QUALITY_QVGA));
  }
}
