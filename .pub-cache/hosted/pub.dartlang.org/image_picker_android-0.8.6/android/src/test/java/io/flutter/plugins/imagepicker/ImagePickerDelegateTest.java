// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.imagepicker;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.core.IsEqual.equalTo;
import static org.junit.Assert.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoMoreInteractions;
import static org.mockito.Mockito.when;

import android.Manifest;
import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.Mockito;
import org.mockito.MockitoAnnotations;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@RunWith(RobolectricTestRunner.class)
public class ImagePickerDelegateTest {
  private static final Double WIDTH = 10.0;
  private static final Double HEIGHT = 10.0;
  private static final Double MAX_DURATION = 10.0;
  private static final Integer IMAGE_QUALITY = 90;

  @Mock Activity mockActivity;
  @Mock ImageResizer mockImageResizer;
  @Mock MethodCall mockMethodCall;
  @Mock MethodChannel.Result mockResult;
  @Mock ImagePickerDelegate.PermissionManager mockPermissionManager;
  @Mock FileUtils mockFileUtils;
  @Mock Intent mockIntent;
  @Mock ImagePickerCache cache;

  ImagePickerDelegate.FileUriResolver mockFileUriResolver;
  MockedStatic<File> mockStaticFile;

  AutoCloseable mockCloseable;

  private static class MockFileUriResolver implements ImagePickerDelegate.FileUriResolver {
    @Override
    public Uri resolveFileProviderUriForFile(String fileProviderName, File imageFile) {
      return null;
    }

    @Override
    public void getFullImagePath(Uri imageUri, ImagePickerDelegate.OnPathReadyListener listener) {
      listener.onPathReady("pathFromUri");
    }
  }

  @Before
  public void setUp() {
    mockCloseable = MockitoAnnotations.openMocks(this);

    mockStaticFile = Mockito.mockStatic(File.class);
    mockStaticFile
        .when(() -> File.createTempFile(any(), any(), any()))
        .thenReturn(new File("/tmpfile"));

    when(mockActivity.getPackageName()).thenReturn("com.example.test");
    when(mockActivity.getPackageManager()).thenReturn(mock(PackageManager.class));

    when(mockFileUtils.getPathFromUri(any(Context.class), any(Uri.class)))
        .thenReturn("pathFromUri");

    when(mockImageResizer.resizeImageIfNeeded("pathFromUri", null, null, null))
        .thenReturn("originalPath");
    when(mockImageResizer.resizeImageIfNeeded("pathFromUri", null, null, IMAGE_QUALITY))
        .thenReturn("originalPath");
    when(mockImageResizer.resizeImageIfNeeded("pathFromUri", WIDTH, HEIGHT, null))
        .thenReturn("scaledPath");
    when(mockImageResizer.resizeImageIfNeeded("pathFromUri", WIDTH, null, null))
        .thenReturn("scaledPath");
    when(mockImageResizer.resizeImageIfNeeded("pathFromUri", null, HEIGHT, null))
        .thenReturn("scaledPath");

    mockFileUriResolver = new MockFileUriResolver();

    Uri mockUri = mock(Uri.class);
    when(mockIntent.getData()).thenReturn(mockUri);
  }

  @After
  public void tearDown() throws Exception {
    mockStaticFile.close();
    mockCloseable.close();
  }

  @Test
  public void whenConstructed_setsCorrectFileProviderName() {
    ImagePickerDelegate delegate = createDelegate();
    assertThat(delegate.fileProviderName, equalTo("com.example.test.flutter.image_provider"));
  }

  @Test
  public void chooseImageFromGallery_WhenPendingResultExists_FinishesWithAlreadyActiveError() {
    ImagePickerDelegate delegate = createDelegateWithPendingResultAndMethodCall();

    delegate.chooseImageFromGallery(mockMethodCall, mockResult);

    verifyFinishedWithAlreadyActiveError();
    verifyNoMoreInteractions(mockResult);
  }

  @Test
  public void chooseMultiImageFromGallery_WhenPendingResultExists_FinishesWithAlreadyActiveError() {
    ImagePickerDelegate delegate = createDelegateWithPendingResultAndMethodCall();

    delegate.chooseMultiImageFromGallery(mockMethodCall, mockResult);

    verifyFinishedWithAlreadyActiveError();
    verifyNoMoreInteractions(mockResult);
  }

  @Test
  @Config(sdk = 30)
  public void
      chooseImageFromGallery_WhenHasExternalStoragePermission_LaunchesChooseFromGalleryIntent() {
    when(mockPermissionManager.isPermissionGranted(Manifest.permission.READ_EXTERNAL_STORAGE))
        .thenReturn(true);

    ImagePickerDelegate delegate = createDelegate();
    delegate.chooseImageFromGallery(mockMethodCall, mockResult);

    verify(mockActivity)
        .startActivityForResult(
            any(Intent.class), eq(ImagePickerDelegate.REQUEST_CODE_CHOOSE_IMAGE_FROM_GALLERY));
  }

  @Test
  @Config(minSdk = 33)
  public void
      chooseImageFromGallery_WithPhotoPicker_WhenHasExternalStoragePermission_LaunchesChooseFromGalleryIntent() {
    when(mockPermissionManager.isPermissionGranted(Manifest.permission.READ_EXTERNAL_STORAGE))
        .thenReturn(true);
    when(mockMethodCall.argument("useAndroidPhotoPicker")).thenReturn(true);

    ImagePickerDelegate delegate = createDelegate();
    delegate.chooseImageFromGallery(mockMethodCall, mockResult);

    verify(mockActivity)
        .startActivityForResult(
            any(Intent.class), eq(ImagePickerDelegate.REQUEST_CODE_CHOOSE_IMAGE_FROM_GALLERY));
  }

  @Test
  @Config(sdk = 30)
  public void
      chooseMultiImageFromGallery_WhenHasExternalStoragePermission_LaunchesChooseFromGalleryIntent() {
    when(mockPermissionManager.isPermissionGranted(Manifest.permission.READ_EXTERNAL_STORAGE))
        .thenReturn(true);
    when(mockMethodCall.argument("useAndroidPhotoPicker")).thenReturn(true);

    ImagePickerDelegate delegate = createDelegate();
    delegate.chooseMultiImageFromGallery(mockMethodCall, mockResult);

    verify(mockActivity)
        .startActivityForResult(
            any(Intent.class),
            eq(ImagePickerDelegate.REQUEST_CODE_CHOOSE_MULTI_IMAGE_FROM_GALLERY));
  }

  @Test
  @Config(minSdk = 33)
  public void
      chooseMultiImageFromGallery_WithPhotoPicker_WhenHasExternalStoragePermission_LaunchesChooseFromGalleryIntent() {
    when(mockPermissionManager.isPermissionGranted(Manifest.permission.READ_EXTERNAL_STORAGE))
        .thenReturn(true);
    when(mockMethodCall.argument("useAndroidPhotoPicker")).thenReturn(true);

    ImagePickerDelegate delegate = createDelegate();
    delegate.chooseMultiImageFromGallery(mockMethodCall, mockResult);

    verify(mockActivity)
        .startActivityForResult(
            any(Intent.class),
            eq(ImagePickerDelegate.REQUEST_CODE_CHOOSE_MULTI_IMAGE_FROM_GALLERY));
  }

  @Test
  @Config(sdk = 30)
  public void
      chooseVideoFromGallery_WhenHasExternalStoragePermission_LaunchesChooseFromGalleryIntent() {
    when(mockPermissionManager.isPermissionGranted(Manifest.permission.READ_EXTERNAL_STORAGE))
        .thenReturn(true);
    when(mockMethodCall.argument("useAndroidPhotoPicker")).thenReturn(true);

    ImagePickerDelegate delegate = createDelegate();
    delegate.chooseVideoFromGallery(mockMethodCall, mockResult);

    verify(mockActivity)
        .startActivityForResult(
            any(Intent.class), eq(ImagePickerDelegate.REQUEST_CODE_CHOOSE_VIDEO_FROM_GALLERY));
  }

  @Test
  @Config(minSdk = 33)
  public void
      chooseVideoFromGallery_WithPhotoPicker_WhenHasExternalStoragePermission_LaunchesChooseFromGalleryIntent() {
    when(mockPermissionManager.isPermissionGranted(Manifest.permission.READ_EXTERNAL_STORAGE))
        .thenReturn(true);
    when(mockMethodCall.argument("useAndroidPhotoPicker")).thenReturn(true);

    ImagePickerDelegate delegate = createDelegate();
    delegate.chooseVideoFromGallery(mockMethodCall, mockResult);

    verify(mockActivity)
        .startActivityForResult(
            any(Intent.class), eq(ImagePickerDelegate.REQUEST_CODE_CHOOSE_VIDEO_FROM_GALLERY));
  }

  @Test
  public void takeImageWithCamera_WhenPendingResultExists_FinishesWithAlreadyActiveError() {
    ImagePickerDelegate delegate = createDelegateWithPendingResultAndMethodCall();

    delegate.takeImageWithCamera(mockMethodCall, mockResult);

    verifyFinishedWithAlreadyActiveError();
    verifyNoMoreInteractions(mockResult);
  }

  @Test
  public void takeImageWithCamera_WhenHasNoCameraPermission_RequestsForPermission() {
    when(mockPermissionManager.isPermissionGranted(Manifest.permission.CAMERA)).thenReturn(false);
    when(mockPermissionManager.needRequestCameraPermission()).thenReturn(true);

    ImagePickerDelegate delegate = createDelegate();
    delegate.takeImageWithCamera(mockMethodCall, mockResult);

    verify(mockPermissionManager)
        .askForPermission(
            Manifest.permission.CAMERA, ImagePickerDelegate.REQUEST_CAMERA_IMAGE_PERMISSION);
  }

  @Test
  public void takeImageWithCamera_WhenCameraPermissionNotPresent_RequestsForPermission() {
    when(mockPermissionManager.needRequestCameraPermission()).thenReturn(false);

    ImagePickerDelegate delegate = createDelegate();
    delegate.takeImageWithCamera(mockMethodCall, mockResult);

    verify(mockActivity)
        .startActivityForResult(
            any(Intent.class), eq(ImagePickerDelegate.REQUEST_CODE_TAKE_IMAGE_WITH_CAMERA));
  }

  @Test
  public void
      takeImageWithCamera_WhenHasCameraPermission_AndAnActivityCanHandleCameraIntent_LaunchesTakeWithCameraIntent() {
    when(mockPermissionManager.isPermissionGranted(Manifest.permission.CAMERA)).thenReturn(true);

    ImagePickerDelegate delegate = createDelegate();
    delegate.takeImageWithCamera(mockMethodCall, mockResult);

    verify(mockActivity)
        .startActivityForResult(
            any(Intent.class), eq(ImagePickerDelegate.REQUEST_CODE_TAKE_IMAGE_WITH_CAMERA));
  }

  @Test
  public void
      takeImageWithCamera_WhenHasCameraPermission_AndNoActivityToHandleCameraIntent_FinishesWithNoCamerasAvailableError() {
    when(mockPermissionManager.isPermissionGranted(Manifest.permission.CAMERA)).thenReturn(true);
    doThrow(ActivityNotFoundException.class)
        .when(mockActivity)
        .startActivityForResult(any(Intent.class), anyInt());
    ImagePickerDelegate delegate = createDelegate();
    delegate.takeImageWithCamera(mockMethodCall, mockResult);

    verify(mockResult)
        .error("no_available_camera", "No cameras available for taking pictures.", null);
    verifyNoMoreInteractions(mockResult);
  }

  @Test
  public void takeImageWithCamera_WritesImageToCacheDirectory() {
    when(mockPermissionManager.isPermissionGranted(Manifest.permission.CAMERA)).thenReturn(true);

    ImagePickerDelegate delegate = createDelegate();
    delegate.takeImageWithCamera(mockMethodCall, mockResult);

    mockStaticFile.verify(
        () -> File.createTempFile(any(), eq(".jpg"), eq(new File("/image_picker_cache"))),
        times(1));
  }

  @Test
  public void onRequestPermissionsResult_WhenCameraPermissionDenied_FinishesWithError() {
    ImagePickerDelegate delegate = createDelegateWithPendingResultAndMethodCall();

    delegate.onRequestPermissionsResult(
        ImagePickerDelegate.REQUEST_CAMERA_IMAGE_PERMISSION,
        new String[] {Manifest.permission.CAMERA},
        new int[] {PackageManager.PERMISSION_DENIED});

    verify(mockResult).error("camera_access_denied", "The user did not allow camera access.", null);
    verifyNoMoreInteractions(mockResult);
  }

  @Test
  public void
      onRequestTakeVideoPermissionsResult_WhenCameraPermissionGranted_LaunchesTakeVideoWithCameraIntent() {

    ImagePickerDelegate delegate = createDelegateWithPendingResultAndMethodCall();
    delegate.onRequestPermissionsResult(
        ImagePickerDelegate.REQUEST_CAMERA_VIDEO_PERMISSION,
        new String[] {Manifest.permission.CAMERA},
        new int[] {PackageManager.PERMISSION_GRANTED});

    verify(mockActivity)
        .startActivityForResult(
            any(Intent.class), eq(ImagePickerDelegate.REQUEST_CODE_TAKE_VIDEO_WITH_CAMERA));
  }

  @Test
  public void
      onRequestTakeImagePermissionsResult_WhenCameraPermissionGranted_LaunchesTakeWithCameraIntent() {

    ImagePickerDelegate delegate = createDelegateWithPendingResultAndMethodCall();
    delegate.onRequestPermissionsResult(
        ImagePickerDelegate.REQUEST_CAMERA_IMAGE_PERMISSION,
        new String[] {Manifest.permission.CAMERA},
        new int[] {PackageManager.PERMISSION_GRANTED});

    verify(mockActivity)
        .startActivityForResult(
            any(Intent.class), eq(ImagePickerDelegate.REQUEST_CODE_TAKE_IMAGE_WITH_CAMERA));
  }

  @Test
  public void onActivityResult_WhenPickFromGalleryCanceled_FinishesWithNull() {
    ImagePickerDelegate delegate = createDelegateWithPendingResultAndMethodCall();

    delegate.onActivityResult(
        ImagePickerDelegate.REQUEST_CODE_CHOOSE_IMAGE_FROM_GALLERY, Activity.RESULT_CANCELED, null);

    verify(mockResult).success(null);
    verifyNoMoreInteractions(mockResult);
  }

  @Test
  public void onActivityResult_WhenPickFromGalleryCanceled_StoresNothingInCache() {
    ImagePickerDelegate delegate = createDelegate();

    delegate.onActivityResult(
        ImagePickerDelegate.REQUEST_CODE_CHOOSE_IMAGE_FROM_GALLERY, Activity.RESULT_CANCELED, null);

    verify(cache, never()).saveResult(any(), any(), any());
  }

  @Test
  public void
      onActivityResult_WhenImagePickedFromGallery_AndNoResizeNeeded_FinishesWithImagePath() {
    ImagePickerDelegate delegate = createDelegateWithPendingResultAndMethodCall();

    delegate.onActivityResult(
        ImagePickerDelegate.REQUEST_CODE_CHOOSE_IMAGE_FROM_GALLERY, Activity.RESULT_OK, mockIntent);

    verify(mockResult).success("originalPath");
    verifyNoMoreInteractions(mockResult);
  }

  @Test
  public void onActivityResult_WhenImagePickedFromGallery_AndNoResizeNeeded_StoresImageInCache() {
    ImagePickerDelegate delegate = createDelegate();

    delegate.onActivityResult(
        ImagePickerDelegate.REQUEST_CODE_CHOOSE_IMAGE_FROM_GALLERY, Activity.RESULT_OK, mockIntent);

    @SuppressWarnings("unchecked")
    ArgumentCaptor<ArrayList<String>> pathListCapture = ArgumentCaptor.forClass(ArrayList.class);
    verify(cache, times(1)).saveResult(pathListCapture.capture(), any(), any());
    assertEquals("pathFromUri", pathListCapture.getValue().get(0));
  }

  @Test
  public void
      onActivityResult_WhenImagePickedFromGallery_AndResizeNeeded_FinishesWithScaledImagePath() {
    when(mockMethodCall.argument("maxWidth")).thenReturn(WIDTH);

    ImagePickerDelegate delegate = createDelegateWithPendingResultAndMethodCall();
    delegate.onActivityResult(
        ImagePickerDelegate.REQUEST_CODE_CHOOSE_IMAGE_FROM_GALLERY, Activity.RESULT_OK, mockIntent);

    verify(mockResult).success("scaledPath");
    verifyNoMoreInteractions(mockResult);
  }

  @Test
  public void
      onActivityResult_WhenVideoPickedFromGallery_AndResizeParametersSupplied_FinishesWithFilePath() {
    when(mockMethodCall.argument("maxWidth")).thenReturn(WIDTH);

    ImagePickerDelegate delegate = createDelegateWithPendingResultAndMethodCall();
    delegate.onActivityResult(
        ImagePickerDelegate.REQUEST_CODE_CHOOSE_VIDEO_FROM_GALLERY, Activity.RESULT_OK, mockIntent);

    verify(mockResult).success("pathFromUri");
    verifyNoMoreInteractions(mockResult);
  }

  @Test
  public void onActivityResult_WhenTakeImageWithCameraCanceled_FinishesWithNull() {
    ImagePickerDelegate delegate = createDelegateWithPendingResultAndMethodCall();

    delegate.onActivityResult(
        ImagePickerDelegate.REQUEST_CODE_TAKE_IMAGE_WITH_CAMERA, Activity.RESULT_CANCELED, null);

    verify(mockResult).success(null);
    verifyNoMoreInteractions(mockResult);
  }

  @Test
  public void onActivityResult_WhenImageTakenWithCamera_AndNoResizeNeeded_FinishesWithImagePath() {
    ImagePickerDelegate delegate = createDelegateWithPendingResultAndMethodCall();
    when(cache.retrievePendingCameraMediaUriPath()).thenReturn("testString");

    delegate.onActivityResult(
        ImagePickerDelegate.REQUEST_CODE_TAKE_IMAGE_WITH_CAMERA, Activity.RESULT_OK, mockIntent);

    verify(mockResult).success("originalPath");
    verifyNoMoreInteractions(mockResult);
  }

  @Test
  public void
      onActivityResult_WhenImageTakenWithCamera_AndResizeNeeded_FinishesWithScaledImagePath() {
    when(mockMethodCall.argument("maxWidth")).thenReturn(WIDTH);
    when(cache.retrievePendingCameraMediaUriPath()).thenReturn("testString");

    ImagePickerDelegate delegate = createDelegateWithPendingResultAndMethodCall();
    delegate.onActivityResult(
        ImagePickerDelegate.REQUEST_CODE_TAKE_IMAGE_WITH_CAMERA, Activity.RESULT_OK, mockIntent);

    verify(mockResult).success("scaledPath");
    verifyNoMoreInteractions(mockResult);
  }

  @Test
  public void
      onActivityResult_WhenVideoTakenWithCamera_AndResizeParametersSupplied_FinishesWithFilePath() {
    when(mockMethodCall.argument("maxWidth")).thenReturn(WIDTH);
    when(cache.retrievePendingCameraMediaUriPath()).thenReturn("testString");

    ImagePickerDelegate delegate = createDelegateWithPendingResultAndMethodCall();
    delegate.onActivityResult(
        ImagePickerDelegate.REQUEST_CODE_TAKE_VIDEO_WITH_CAMERA, Activity.RESULT_OK, mockIntent);

    verify(mockResult).success("pathFromUri");
    verifyNoMoreInteractions(mockResult);
  }

  @Test
  public void
      onActivityResult_WhenVideoTakenWithCamera_AndMaxDurationParametersSupplied_FinishesWithFilePath() {
    when(mockMethodCall.argument("maxDuration")).thenReturn(MAX_DURATION);
    when(cache.retrievePendingCameraMediaUriPath()).thenReturn("testString");

    ImagePickerDelegate delegate = createDelegateWithPendingResultAndMethodCall();
    delegate.onActivityResult(
        ImagePickerDelegate.REQUEST_CODE_TAKE_VIDEO_WITH_CAMERA, Activity.RESULT_OK, mockIntent);

    verify(mockResult).success("pathFromUri");
    verifyNoMoreInteractions(mockResult);
  }

  @Test
  public void
      retrieveLostImage_ShouldBeAbleToReturnLastItemFromResultMapWhenSingleFileIsRecovered() {
    Map<String, Object> resultMap = new HashMap<>();
    ArrayList<String> pathList = new ArrayList<>();
    pathList.add("/example/first_item");
    pathList.add("/example/last_item");
    resultMap.put("pathList", pathList);

    when(mockImageResizer.resizeImageIfNeeded(pathList.get(0), null, null, 100))
        .thenReturn(pathList.get(0));
    when(mockImageResizer.resizeImageIfNeeded(pathList.get(1), null, null, 100))
        .thenReturn(pathList.get(1));
    when(cache.getCacheMap()).thenReturn(resultMap);

    MethodChannel.Result mockResult = mock(MethodChannel.Result.class);

    ImagePickerDelegate mockDelegate = createDelegate();

    @SuppressWarnings("unchecked")
    ArgumentCaptor<Map<String, Object>> valueCapture = ArgumentCaptor.forClass(Map.class);

    doNothing().when(mockResult).success(valueCapture.capture());

    mockDelegate.retrieveLostImage(mockResult);

    assertEquals("/example/last_item", valueCapture.getValue().get("path"));
  }

  private ImagePickerDelegate createDelegate() {
    return new ImagePickerDelegate(
        mockActivity,
        new File("/image_picker_cache"),
        mockImageResizer,
        null,
        null,
        cache,
        mockPermissionManager,
        mockFileUriResolver,
        mockFileUtils);
  }

  private ImagePickerDelegate createDelegateWithPendingResultAndMethodCall() {
    return new ImagePickerDelegate(
        mockActivity,
        new File("/image_picker_cache"),
        mockImageResizer,
        mockResult,
        mockMethodCall,
        cache,
        mockPermissionManager,
        mockFileUriResolver,
        mockFileUtils);
  }

  private void verifyFinishedWithAlreadyActiveError() {
    verify(mockResult).error("already_active", "Image picker is already active", null);
  }
}
