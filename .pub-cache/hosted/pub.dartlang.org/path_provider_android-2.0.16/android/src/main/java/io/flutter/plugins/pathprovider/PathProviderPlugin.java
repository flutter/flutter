// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.pathprovider;

import android.content.Context;
import android.os.Build.VERSION;
import android.os.Build.VERSION_CODES;
import android.util.Log;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.BinaryMessenger.TaskQueue;
import io.flutter.plugins.pathprovider.Messages.PathProviderApi;
import io.flutter.util.PathUtils;
import java.io.File;
import java.util.ArrayList;
import java.util.List;
import javax.annotation.Nullable;

public class PathProviderPlugin implements FlutterPlugin, PathProviderApi {
  static final String TAG = "PathProviderPlugin";
  private Context context;

  public PathProviderPlugin() {}

  private void setup(BinaryMessenger messenger, Context context) {
    TaskQueue taskQueue = messenger.makeBackgroundTaskQueue();

    try {
      PathProviderApi.setup(messenger, this);
    } catch (Exception ex) {
      Log.e(TAG, "Received exception while setting up PathProviderPlugin", ex);
    }

    this.context = context;
  }

  @SuppressWarnings("deprecation")
  public static void registerWith(io.flutter.plugin.common.PluginRegistry.Registrar registrar) {
    PathProviderPlugin instance = new PathProviderPlugin();
    instance.setup(registrar.messenger(), registrar.context());
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    setup(binding.getBinaryMessenger(), binding.getApplicationContext());
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    PathProviderApi.setup(binding.getBinaryMessenger(), null);
  }

  @Override
  public @Nullable String getTemporaryPath() {
    return getPathProviderTemporaryDirectory();
  }

  @Override
  public @Nullable String getApplicationSupportPath() {
    return getApplicationSupportDirectory();
  }

  @Override
  public @Nullable String getApplicationDocumentsPath() {
    return getPathProviderApplicationDocumentsDirectory();
  }

  @Override
  public @Nullable String getExternalStoragePath() {
    return getPathProviderStorageDirectory();
  }

  @Override
  public @NonNull List<String> getExternalCachePaths() {
    return getPathProviderExternalCacheDirectories();
  }

  @Override
  public @NonNull List<String> getExternalStoragePaths(
      @NonNull Messages.StorageDirectory directory) {
    return getPathProviderExternalStorageDirectories(directory);
  }

  private String getPathProviderTemporaryDirectory() {
    return context.getCacheDir().getPath();
  }

  private String getApplicationSupportDirectory() {
    return PathUtils.getFilesDir(context);
  }

  private String getPathProviderApplicationDocumentsDirectory() {
    return PathUtils.getDataDirectory(context);
  }

  private String getPathProviderStorageDirectory() {
    final File dir = context.getExternalFilesDir(null);
    if (dir == null) {
      return null;
    }
    return dir.getAbsolutePath();
  }

  private List<String> getPathProviderExternalCacheDirectories() {
    final List<String> paths = new ArrayList<String>();

    if (VERSION.SDK_INT >= VERSION_CODES.KITKAT) {
      for (File dir : context.getExternalCacheDirs()) {
        if (dir != null) {
          paths.add(dir.getAbsolutePath());
        }
      }
    } else {
      File dir = context.getExternalCacheDir();
      if (dir != null) {
        paths.add(dir.getAbsolutePath());
      }
    }

    return paths;
  }

  private String getStorageDirectoryString(@NonNull Messages.StorageDirectory directory) {
    switch (directory) {
      case root:
        return null;
      case music:
        return "music";
      case podcasts:
        return "podcasts";
      case ringtones:
        return "ringtones";
      case alarms:
        return "alarms";
      case notifications:
        return "notifications";
      case pictures:
        return "pictures";
      case movies:
        return "movies";
      case downloads:
        return "downloads";
      case dcim:
        return "dcim";
      case documents:
        return "documents";
      default:
        throw new RuntimeException("Unrecognized directory: " + directory);
    }
  }

  private List<String> getPathProviderExternalStorageDirectories(
      @NonNull Messages.StorageDirectory directory) {
    final List<String> paths = new ArrayList<String>();

    if (VERSION.SDK_INT >= VERSION_CODES.KITKAT) {
      for (File dir : context.getExternalFilesDirs(getStorageDirectoryString(directory))) {
        if (dir != null) {
          paths.add(dir.getAbsolutePath());
        }
      }
    } else {
      File dir = context.getExternalFilesDir(getStorageDirectoryString(directory));
      if (dir != null) {
        paths.add(dir.getAbsolutePath());
      }
    }

    return paths;
  }
}
