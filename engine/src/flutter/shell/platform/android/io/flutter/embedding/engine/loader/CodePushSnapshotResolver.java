// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.loader;

import android.content.Context;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.Log;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * Resolves OTA Dart isolate snapshot blobs written by flutter_code_push.
 *
 * <p>Only the application isolate AOT heap and instruction buffers are replaced. The VM snapshot
 * and {@code libapp.so} packaged in the APK remain the store-delivered artifacts.
 */
final class CodePushSnapshotResolver {
  private static final String TAG = "CodePushSnapshotResolver";

  static final String ROOT_DIRECTORY_NAME = "code_push";
  static final String ACTIVE_DIRECTORY_NAME = "active";
  static final String MANIFEST_FILE_NAME = "patch_manifest.json";
  static final String ISOLATE_SNAPSHOT_DATA_FILE_NAME = "isolate_snapshot_data";
  static final String ISOLATE_SNAPSHOT_INSTR_FILE_NAME = "isolate_snapshot_instr";

  /** Paths to isolate snapshot blobs, or {@code null} if no valid active patch exists. */
  static final class IsolateSnapshotPaths {
    final String dataPath;
    final String instructionsPath;

    IsolateSnapshotPaths(String dataPath, String instructionsPath) {
      this.dataPath = dataPath;
      this.instructionsPath = instructionsPath;
    }
  }

  private CodePushSnapshotResolver() {}

  @Nullable
  static IsolateSnapshotPaths resolveActiveIsolateSnapshotPaths(
      @NonNull Context applicationContext) {
    File activeDirectory =
        new File(
            applicationContext.getFilesDir(),
            ROOT_DIRECTORY_NAME + File.separator + ACTIVE_DIRECTORY_NAME);
    File manifestFile = new File(activeDirectory, MANIFEST_FILE_NAME);
    File dataFile = new File(activeDirectory, ISOLATE_SNAPSHOT_DATA_FILE_NAME);
    File instructionsFile = new File(activeDirectory, ISOLATE_SNAPSHOT_INSTR_FILE_NAME);

    if (!manifestFile.exists() || !dataFile.exists() || !instructionsFile.exists()) {
      return null;
    }

    try {
      JSONObject manifest = readManifest(manifestFile);
      if (!manifest.optBoolean("enabled", true)) {
        Log.w(TAG, "Active code push patch is disabled; using bundled isolate snapshot.");
        return null;
      }
      long expectedDataLength = manifest.optLong("isolate_data_length_bytes", -1);
      long expectedInstrLength = manifest.optLong("isolate_instr_length_bytes", -1);
      if (expectedDataLength > 0 && dataFile.length() != expectedDataLength) {
        Log.e(TAG, "Active isolate_snapshot_data size mismatch.");
        return null;
      }
      if (expectedInstrLength > 0 && instructionsFile.length() != expectedInstrLength) {
        Log.e(TAG, "Active isolate_snapshot_instr size mismatch.");
        return null;
      }

      return new IsolateSnapshotPaths(
          dataFile.getCanonicalPath(), instructionsFile.getCanonicalPath());
    } catch (IOException | JSONException exception) {
      Log.e(TAG, "Failed to read active code push manifest.", exception);
      return null;
    }
  }

  private static JSONObject readManifest(@NonNull File manifestFile)
      throws IOException, JSONException {
    try (FileInputStream inputStream = new FileInputStream(manifestFile)) {
      byte[] bytes = readAllBytes(inputStream);
      return new JSONObject(new String(bytes, java.nio.charset.StandardCharsets.UTF_8));
    }
  }

  private static byte[] readAllBytes(@NonNull FileInputStream inputStream) throws IOException {
    byte[] buffer = new byte[4096];
    int read;
    java.io.ByteArrayOutputStream outputStream = new java.io.ByteArrayOutputStream();
    while ((read = inputStream.read(buffer)) != -1) {
      outputStream.write(buffer, 0, read);
    }
    return outputStream.toByteArray();
  }
}
