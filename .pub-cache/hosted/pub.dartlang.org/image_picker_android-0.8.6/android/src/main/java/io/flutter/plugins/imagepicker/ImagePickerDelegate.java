// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.imagepicker;

import android.Manifest;
import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.hardware.camera2.CameraCharacteristics;
import android.media.MediaScannerConnection;
import android.net.Uri;
import android.os.Build;
import android.provider.MediaStore;
import androidx.activity.result.PickVisualMediaRequest;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import androidx.core.app.ActivityCompat;
import androidx.core.content.FileProvider;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * A delegate class doing the heavy lifting for the plugin.
 *
 * <p>When invoked, both the {@link #chooseImageFromGallery} and {@link #takeImageWithCamera}
 * methods go through the same steps:
 *
 * <p>1. Check for an existing {@link #pendingResult}. If a previous pendingResult exists, this
 * means that the chooseImageFromGallery() or takeImageWithCamera() method was called at least
 * twice. In this case, stop executing and finish with an error.
 *
 * <p>2. Check that a required runtime permission has been granted. The takeImageWithCamera() method
 * checks that {@link Manifest.permission#CAMERA} has been granted.
 *
 * <p>The permission check can end up in two different outcomes:
 *
 * <p>A) If the permission has already been granted, continue with picking the image from gallery or
 * camera.
 *
 * <p>B) If the permission hasn't already been granted, ask for the permission from the user. If the
 * user grants the permission, proceed with step #3. If the user denies the permission, stop doing
 * anything else and finish with a null result.
 *
 * <p>3. Launch the gallery or camera for picking the image, depending on whether
 * chooseImageFromGallery() or takeImageWithCamera() was called.
 *
 * <p>This can end up in three different outcomes:
 *
 * <p>A) User picks an image. No maxWidth or maxHeight was specified when calling {@code
 * pickImage()} method in the Dart side of this plugin. Finish with full path for the picked image
 * as the result.
 *
 * <p>B) User picks an image. A maxWidth and/or maxHeight was provided when calling {@code
 * pickImage()} method in the Dart side of this plugin. A scaled copy of the image is created.
 * Finish with full path for the scaled image as the result.
 *
 * <p>C) User cancels picking an image. Finish with null result.
 */
public class ImagePickerDelegate
    implements PluginRegistry.ActivityResultListener,
        PluginRegistry.RequestPermissionsResultListener {
  @VisibleForTesting static final int REQUEST_CODE_CHOOSE_IMAGE_FROM_GALLERY = 2342;
  @VisibleForTesting static final int REQUEST_CODE_TAKE_IMAGE_WITH_CAMERA = 2343;
  @VisibleForTesting static final int REQUEST_CAMERA_IMAGE_PERMISSION = 2345;
  @VisibleForTesting static final int REQUEST_CODE_CHOOSE_MULTI_IMAGE_FROM_GALLERY = 2346;

  @VisibleForTesting static final int REQUEST_CODE_CHOOSE_VIDEO_FROM_GALLERY = 2352;
  @VisibleForTesting static final int REQUEST_CODE_TAKE_VIDEO_WITH_CAMERA = 2353;
  @VisibleForTesting static final int REQUEST_CAMERA_VIDEO_PERMISSION = 2355;

  public enum CameraDevice {
    REAR,
    FRONT
  }

  @VisibleForTesting final String fileProviderName;

  private final Activity activity;
  @VisibleForTesting final File externalFilesDirectory;
  private final ImageResizer imageResizer;
  private final ImagePickerCache cache;
  private final PermissionManager permissionManager;
  private final FileUriResolver fileUriResolver;
  private final FileUtils fileUtils;
  private CameraDevice cameraDevice;

  interface PermissionManager {
    boolean isPermissionGranted(String permissionName);

    void askForPermission(String permissionName, int requestCode);

    boolean needRequestCameraPermission();
  }

  interface FileUriResolver {
    Uri resolveFileProviderUriForFile(String fileProviderName, File imageFile);

    void getFullImagePath(Uri imageUri, OnPathReadyListener listener);
  }

  interface OnPathReadyListener {
    void onPathReady(String path);
  }

  private Uri pendingCameraMediaUri;
  private MethodChannel.Result pendingResult;
  private MethodCall methodCall;

  public ImagePickerDelegate(
      final Activity activity,
      final File externalFilesDirectory,
      final ImageResizer imageResizer,
      final ImagePickerCache cache) {
    this(
        activity,
        externalFilesDirectory,
        imageResizer,
        null,
        null,
        cache,
        new PermissionManager() {
          @Override
          public boolean isPermissionGranted(String permissionName) {
            return ActivityCompat.checkSelfPermission(activity, permissionName)
                == PackageManager.PERMISSION_GRANTED;
          }

          @Override
          public void askForPermission(String permissionName, int requestCode) {
            ActivityCompat.requestPermissions(activity, new String[] {permissionName}, requestCode);
          }

          @Override
          public boolean needRequestCameraPermission() {
            return ImagePickerUtils.needRequestCameraPermission(activity);
          }
        },
        new FileUriResolver() {
          @Override
          public Uri resolveFileProviderUriForFile(String fileProviderName, File file) {
            return FileProvider.getUriForFile(activity, fileProviderName, file);
          }

          @Override
          public void getFullImagePath(final Uri imageUri, final OnPathReadyListener listener) {
            MediaScannerConnection.scanFile(
                activity,
                new String[] {(imageUri != null) ? imageUri.getPath() : ""},
                null,
                new MediaScannerConnection.OnScanCompletedListener() {
                  @Override
                  public void onScanCompleted(String path, Uri uri) {
                    listener.onPathReady(path);
                  }
                });
          }
        },
        new FileUtils());
  }

  /**
   * This constructor is used exclusively for testing; it can be used to provide mocks to final
   * fields of this class. Otherwise those fields would have to be mutable and visible.
   */
  @VisibleForTesting
  ImagePickerDelegate(
      final Activity activity,
      final File externalFilesDirectory,
      final ImageResizer imageResizer,
      final MethodChannel.Result result,
      final MethodCall methodCall,
      final ImagePickerCache cache,
      final PermissionManager permissionManager,
      final FileUriResolver fileUriResolver,
      final FileUtils fileUtils) {
    this.activity = activity;
    this.externalFilesDirectory = externalFilesDirectory;
    this.imageResizer = imageResizer;
    this.fileProviderName = activity.getPackageName() + ".flutter.image_provider";
    this.pendingResult = result;
    this.methodCall = methodCall;
    this.permissionManager = permissionManager;
    this.fileUriResolver = fileUriResolver;
    this.fileUtils = fileUtils;
    this.cache = cache;
  }

  void setCameraDevice(CameraDevice device) {
    cameraDevice = device;
  }

  CameraDevice getCameraDevice() {
    return cameraDevice;
  }

  // Save the state of the image picker so it can be retrieved with `retrieveLostImage`.
  void saveStateBeforeResult() {
    if (methodCall == null) {
      return;
    }

    cache.saveTypeWithMethodCallName(methodCall.method);
    cache.saveDimensionWithMethodCall(methodCall);
    if (pendingCameraMediaUri != null) {
      cache.savePendingCameraMediaUriPath(pendingCameraMediaUri);
    }
  }

  void retrieveLostImage(MethodChannel.Result result) {
    Map<String, Object> resultMap = cache.getCacheMap();
    @SuppressWarnings("unchecked")
    ArrayList<String> pathList =
        (ArrayList<String>) resultMap.get(ImagePickerCache.MAP_KEY_PATH_LIST);
    ArrayList<String> newPathList = new ArrayList<>();
    if (pathList != null) {
      for (String path : pathList) {
        Double maxWidth = (Double) resultMap.get(ImagePickerCache.MAP_KEY_MAX_WIDTH);
        Double maxHeight = (Double) resultMap.get(ImagePickerCache.MAP_KEY_MAX_HEIGHT);
        int imageQuality =
            resultMap.get(ImagePickerCache.MAP_KEY_IMAGE_QUALITY) == null
                ? 100
                : (int) resultMap.get(ImagePickerCache.MAP_KEY_IMAGE_QUALITY);

        newPathList.add(imageResizer.resizeImageIfNeeded(path, maxWidth, maxHeight, imageQuality));
      }
      resultMap.put(ImagePickerCache.MAP_KEY_PATH_LIST, newPathList);
      resultMap.put(ImagePickerCache.MAP_KEY_PATH, newPathList.get(newPathList.size() - 1));
    }
    if (resultMap.isEmpty()) {
      result.success(null);
    } else {
      result.success(resultMap);
    }
    cache.clear();
  }

  public void chooseVideoFromGallery(MethodCall methodCall, MethodChannel.Result result) {
    if (!setPendingMethodCallAndResult(methodCall, result)) {
      finishWithAlreadyActiveError(result);
      return;
    }

    Boolean usePhotoPicker = methodCall.argument("useAndroidPhotoPicker");

    if (usePhotoPicker == null) {
      usePhotoPicker = false;
    }

    launchPickVideoFromGalleryIntent(usePhotoPicker);
  }

  private void launchPickVideoFromGalleryIntent(Boolean useAndroidPhotoPicker) {
    Intent pickVideoIntent;
    if (useAndroidPhotoPicker && Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
      pickVideoIntent =
          new ActivityResultContracts.PickVisualMedia()
              .createIntent(
                  activity,
                  new PickVisualMediaRequest.Builder()
                      .setMediaType(ActivityResultContracts.PickVisualMedia.VideoOnly.INSTANCE)
                      .build());
    } else {
      pickVideoIntent = new Intent(Intent.ACTION_GET_CONTENT);
      pickVideoIntent.setType("video/*");
    }

    activity.startActivityForResult(pickVideoIntent, REQUEST_CODE_CHOOSE_VIDEO_FROM_GALLERY);
  }

  public void takeVideoWithCamera(MethodCall methodCall, MethodChannel.Result result) {
    if (!setPendingMethodCallAndResult(methodCall, result)) {
      finishWithAlreadyActiveError(result);
      return;
    }

    if (needRequestCameraPermission()
        && !permissionManager.isPermissionGranted(Manifest.permission.CAMERA)) {
      permissionManager.askForPermission(
          Manifest.permission.CAMERA, REQUEST_CAMERA_VIDEO_PERMISSION);
      return;
    }

    launchTakeVideoWithCameraIntent();
  }

  private void launchTakeVideoWithCameraIntent() {
    Intent intent = new Intent(MediaStore.ACTION_VIDEO_CAPTURE);
    if (this.methodCall != null && this.methodCall.argument("maxDuration") != null) {
      int maxSeconds = this.methodCall.argument("maxDuration");
      intent.putExtra(MediaStore.EXTRA_DURATION_LIMIT, maxSeconds);
    }
    if (cameraDevice == CameraDevice.FRONT) {
      useFrontCamera(intent);
    }

    File videoFile = createTemporaryWritableVideoFile();
    pendingCameraMediaUri = Uri.parse("file:" + videoFile.getAbsolutePath());

    Uri videoUri = fileUriResolver.resolveFileProviderUriForFile(fileProviderName, videoFile);
    intent.putExtra(MediaStore.EXTRA_OUTPUT, videoUri);
    grantUriPermissions(intent, videoUri);

    try {
      activity.startActivityForResult(intent, REQUEST_CODE_TAKE_VIDEO_WITH_CAMERA);
    } catch (ActivityNotFoundException e) {
      try {
        // If we can't delete the file again here, there's not really anything we can do about it.
        //noinspection ResultOfMethodCallIgnored
        videoFile.delete();
      } catch (SecurityException exception) {
        exception.printStackTrace();
      }
      finishWithError("no_available_camera", "No cameras available for taking pictures.");
    }
  }

  public void chooseImageFromGallery(MethodCall methodCall, MethodChannel.Result result) {
    if (!setPendingMethodCallAndResult(methodCall, result)) {
      finishWithAlreadyActiveError(result);
      return;
    }

    Boolean usePhotoPicker = methodCall.argument("useAndroidPhotoPicker");

    if (usePhotoPicker == null) {
      usePhotoPicker = false;
    }

    launchPickImageFromGalleryIntent(usePhotoPicker);
  }

  public void chooseMultiImageFromGallery(MethodCall methodCall, MethodChannel.Result result) {
    if (!setPendingMethodCallAndResult(methodCall, result)) {
      finishWithAlreadyActiveError(result);
      return;
    }

    Boolean usePhotoPicker = methodCall.argument("useAndroidPhotoPicker");

    if (usePhotoPicker == null) {
      usePhotoPicker = false;
    }

    launchMultiPickImageFromGalleryIntent(usePhotoPicker);
  }

  private void launchPickImageFromGalleryIntent(Boolean useAndroidPhotoPicker) {
    Intent pickImageIntent;
    if (useAndroidPhotoPicker && Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
      pickImageIntent =
          new ActivityResultContracts.PickVisualMedia()
              .createIntent(
                  activity,
                  new PickVisualMediaRequest.Builder()
                      .setMediaType(ActivityResultContracts.PickVisualMedia.ImageOnly.INSTANCE)
                      .build());
    } else {
      pickImageIntent = new Intent(Intent.ACTION_GET_CONTENT);
      pickImageIntent.setType("image/*");
    }

    activity.startActivityForResult(pickImageIntent, REQUEST_CODE_CHOOSE_IMAGE_FROM_GALLERY);
  }

  private void launchMultiPickImageFromGalleryIntent(Boolean useAndroidPhotoPicker) {
    Intent pickMultiImageIntent;
    if (useAndroidPhotoPicker && Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
      pickMultiImageIntent =
          new ActivityResultContracts.PickMultipleVisualMedia()
              .createIntent(
                  activity,
                  new PickVisualMediaRequest.Builder()
                      .setMediaType(ActivityResultContracts.PickVisualMedia.ImageOnly.INSTANCE)
                      .build());
    } else {
      pickMultiImageIntent = new Intent(Intent.ACTION_GET_CONTENT);
      pickMultiImageIntent.setType("image/*");
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
        pickMultiImageIntent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true);
      }
    }
    activity.startActivityForResult(
        pickMultiImageIntent, REQUEST_CODE_CHOOSE_MULTI_IMAGE_FROM_GALLERY);
  }

  public void takeImageWithCamera(MethodCall methodCall, MethodChannel.Result result) {
    if (!setPendingMethodCallAndResult(methodCall, result)) {
      finishWithAlreadyActiveError(result);
      return;
    }

    if (needRequestCameraPermission()
        && !permissionManager.isPermissionGranted(Manifest.permission.CAMERA)) {
      permissionManager.askForPermission(
          Manifest.permission.CAMERA, REQUEST_CAMERA_IMAGE_PERMISSION);
      return;
    }
    launchTakeImageWithCameraIntent();
  }

  private boolean needRequestCameraPermission() {
    if (permissionManager == null) {
      return false;
    }
    return permissionManager.needRequestCameraPermission();
  }

  private void launchTakeImageWithCameraIntent() {
    Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
    if (cameraDevice == CameraDevice.FRONT) {
      useFrontCamera(intent);
    }

    File imageFile = createTemporaryWritableImageFile();
    pendingCameraMediaUri = Uri.parse("file:" + imageFile.getAbsolutePath());

    Uri imageUri = fileUriResolver.resolveFileProviderUriForFile(fileProviderName, imageFile);
    intent.putExtra(MediaStore.EXTRA_OUTPUT, imageUri);
    grantUriPermissions(intent, imageUri);

    try {
      activity.startActivityForResult(intent, REQUEST_CODE_TAKE_IMAGE_WITH_CAMERA);
    } catch (ActivityNotFoundException e) {
      try {
        // If we can't delete the file again here, there's not really anything we can do about it.
        //noinspection ResultOfMethodCallIgnored
        imageFile.delete();
      } catch (SecurityException exception) {
        exception.printStackTrace();
      }
      finishWithError("no_available_camera", "No cameras available for taking pictures.");
    }
  }

  private File createTemporaryWritableImageFile() {
    return createTemporaryWritableFile(".jpg");
  }

  private File createTemporaryWritableVideoFile() {
    return createTemporaryWritableFile(".mp4");
  }

  private File createTemporaryWritableFile(String suffix) {
    String filename = UUID.randomUUID().toString();
    File image;

    try {
      externalFilesDirectory.mkdirs();
      image = File.createTempFile(filename, suffix, externalFilesDirectory);
    } catch (IOException e) {
      throw new RuntimeException(e);
    }

    return image;
  }

  private void grantUriPermissions(Intent intent, Uri imageUri) {
    PackageManager packageManager = activity.getPackageManager();
    // TODO(stuartmorgan): Add new codepath: https://github.com/flutter/flutter/issues/121816
    @SuppressWarnings("deprecation")
    List<ResolveInfo> compatibleActivities =
        packageManager.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY);

    for (ResolveInfo info : compatibleActivities) {
      activity.grantUriPermission(
          info.activityInfo.packageName,
          imageUri,
          Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION);
    }
  }

  @Override
  public boolean onRequestPermissionsResult(
      int requestCode, String[] permissions, int[] grantResults) {
    boolean permissionGranted =
        grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED;

    switch (requestCode) {
      case REQUEST_CAMERA_IMAGE_PERMISSION:
        if (permissionGranted) {
          launchTakeImageWithCameraIntent();
        }
        break;
      case REQUEST_CAMERA_VIDEO_PERMISSION:
        if (permissionGranted) {
          launchTakeVideoWithCameraIntent();
        }
        break;
      default:
        return false;
    }

    if (!permissionGranted) {
      switch (requestCode) {
        case REQUEST_CAMERA_IMAGE_PERMISSION:
        case REQUEST_CAMERA_VIDEO_PERMISSION:
          finishWithError("camera_access_denied", "The user did not allow camera access.");
          break;
      }
    }

    return true;
  }

  @Override
  public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
    switch (requestCode) {
      case REQUEST_CODE_CHOOSE_IMAGE_FROM_GALLERY:
        handleChooseImageResult(resultCode, data);
        break;
      case REQUEST_CODE_CHOOSE_MULTI_IMAGE_FROM_GALLERY:
        handleChooseMultiImageResult(resultCode, data);
        break;
      case REQUEST_CODE_TAKE_IMAGE_WITH_CAMERA:
        handleCaptureImageResult(resultCode);
        break;
      case REQUEST_CODE_CHOOSE_VIDEO_FROM_GALLERY:
        handleChooseVideoResult(resultCode, data);
        break;
      case REQUEST_CODE_TAKE_VIDEO_WITH_CAMERA:
        handleCaptureVideoResult(resultCode);
        break;
      default:
        return false;
    }

    return true;
  }

  private void handleChooseImageResult(int resultCode, Intent data) {
    if (resultCode == Activity.RESULT_OK && data != null) {
      String path = fileUtils.getPathFromUri(activity, data.getData());
      handleImageResult(path, false);
      return;
    }

    // User cancelled choosing a picture.
    finishWithSuccess(null);
  }

  private void handleChooseMultiImageResult(int resultCode, Intent intent) {
    if (resultCode == Activity.RESULT_OK && intent != null) {
      ArrayList<String> paths = new ArrayList<>();
      if (intent.getClipData() != null) {
        for (int i = 0; i < intent.getClipData().getItemCount(); i++) {
          paths.add(fileUtils.getPathFromUri(activity, intent.getClipData().getItemAt(i).getUri()));
        }
      } else {
        paths.add(fileUtils.getPathFromUri(activity, intent.getData()));
      }
      handleMultiImageResult(paths, false);
      return;
    }

    // User cancelled choosing a picture.
    finishWithSuccess(null);
  }

  private void handleChooseVideoResult(int resultCode, Intent data) {
    if (resultCode == Activity.RESULT_OK && data != null) {
      String path = fileUtils.getPathFromUri(activity, data.getData());
      handleVideoResult(path);
      return;
    }

    // User cancelled choosing a picture.
    finishWithSuccess(null);
  }

  private void handleCaptureImageResult(int resultCode) {
    if (resultCode == Activity.RESULT_OK) {
      fileUriResolver.getFullImagePath(
          pendingCameraMediaUri != null
              ? pendingCameraMediaUri
              : Uri.parse(cache.retrievePendingCameraMediaUriPath()),
          new OnPathReadyListener() {
            @Override
            public void onPathReady(String path) {
              handleImageResult(path, true);
            }
          });
      return;
    }

    // User cancelled taking a picture.
    finishWithSuccess(null);
  }

  private void handleCaptureVideoResult(int resultCode) {
    if (resultCode == Activity.RESULT_OK) {
      fileUriResolver.getFullImagePath(
          pendingCameraMediaUri != null
              ? pendingCameraMediaUri
              : Uri.parse(cache.retrievePendingCameraMediaUriPath()),
          new OnPathReadyListener() {
            @Override
            public void onPathReady(String path) {
              handleVideoResult(path);
            }
          });
      return;
    }

    // User cancelled taking a picture.
    finishWithSuccess(null);
  }

  private void handleMultiImageResult(
      ArrayList<String> paths, boolean shouldDeleteOriginalIfScaled) {
    if (methodCall != null) {
      ArrayList<String> finalPath = new ArrayList<>();
      for (int i = 0; i < paths.size(); i++) {
        String finalImagePath = getResizedImagePath(paths.get(i));

        //delete original file if scaled
        if (finalImagePath != null
            && !finalImagePath.equals(paths.get(i))
            && shouldDeleteOriginalIfScaled) {
          new File(paths.get(i)).delete();
        }
        finalPath.add(i, finalImagePath);
      }
      finishWithListSuccess(finalPath);
    } else {
      finishWithListSuccess(paths);
    }
  }

  private void handleImageResult(String path, boolean shouldDeleteOriginalIfScaled) {
    if (methodCall != null) {
      String finalImagePath = getResizedImagePath(path);
      //delete original file if scaled
      if (finalImagePath != null && !finalImagePath.equals(path) && shouldDeleteOriginalIfScaled) {
        new File(path).delete();
      }
      finishWithSuccess(finalImagePath);
    } else {
      finishWithSuccess(path);
    }
  }

  private String getResizedImagePath(String path) {
    Double maxWidth = methodCall.argument("maxWidth");
    Double maxHeight = methodCall.argument("maxHeight");
    Integer imageQuality = methodCall.argument("imageQuality");

    return imageResizer.resizeImageIfNeeded(path, maxWidth, maxHeight, imageQuality);
  }

  private void handleVideoResult(String path) {
    finishWithSuccess(path);
  }

  private boolean setPendingMethodCallAndResult(
      MethodCall methodCall, MethodChannel.Result result) {
    if (pendingResult != null) {
      return false;
    }

    this.methodCall = methodCall;
    pendingResult = result;

    // Clean up cache if a new image picker is launched.
    cache.clear();

    return true;
  }

  // Handles completion of selection with a single result.
  //
  // A null imagePath indicates that the image picker was cancelled without
  // selection.
  private void finishWithSuccess(@Nullable String imagePath) {
    if (pendingResult == null) {
      // Only save data for later retrieval if something was actually selected.
      if (imagePath != null) {
        ArrayList<String> pathList = new ArrayList<>();
        pathList.add(imagePath);
        cache.saveResult(pathList, null, null);
      }
      return;
    }
    pendingResult.success(imagePath);
    clearMethodCallAndResult();
  }

  private void finishWithListSuccess(ArrayList<String> imagePaths) {
    if (pendingResult == null) {
      cache.saveResult(imagePaths, null, null);
      return;
    }
    pendingResult.success(imagePaths);
    clearMethodCallAndResult();
  }

  private void finishWithAlreadyActiveError(MethodChannel.Result result) {
    result.error("already_active", "Image picker is already active", null);
  }

  private void finishWithError(String errorCode, String errorMessage) {
    if (pendingResult == null) {
      cache.saveResult(null, errorCode, errorMessage);
      return;
    }
    pendingResult.error(errorCode, errorMessage, null);
    clearMethodCallAndResult();
  }

  private void clearMethodCallAndResult() {
    methodCall = null;
    pendingResult = null;
  }

  private void useFrontCamera(Intent intent) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
      intent.putExtra(
          "android.intent.extras.CAMERA_FACING", CameraCharacteristics.LENS_FACING_FRONT);
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        intent.putExtra("android.intent.extra.USE_FRONT_CAMERA", true);
      }
    } else {
      intent.putExtra("android.intent.extras.CAMERA_FACING", 1);
    }
  }
}
