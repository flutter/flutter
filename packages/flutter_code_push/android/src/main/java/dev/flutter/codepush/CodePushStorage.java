package dev.flutter.codepush;

import android.content.Context;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Locale;
import org.json.JSONObject;

/** Stages and promotes OTA Dart isolate snapshot blobs (not native .so libraries). */
final class CodePushStorage {
  static final String ROOT_DIRECTORY_NAME = "code_push";
  static final String ACTIVE_DIRECTORY_NAME = "active";
  static final String STAGING_DIRECTORY_NAME = "staging";
  static final String MANIFEST_FILE_NAME = "patch_manifest.json";
  static final String ISOLATE_SNAPSHOT_DATA_FILE_NAME = "isolate_snapshot_data";
  static final String ISOLATE_SNAPSHOT_INSTR_FILE_NAME = "isolate_snapshot_instr";

  private final Context context;

  CodePushStorage(@NonNull Context context) {
    this.context = context.getApplicationContext();
  }

  @Nullable
  Integer readCurrentPatchNumber() throws IOException {
    File manifestFile = new File(getActiveDirectory(), MANIFEST_FILE_NAME);
    if (!manifestFile.exists()) {
      return null;
    }
    JSONObject manifest = readManifest(manifestFile);
    return manifest.has("patch_number") ? manifest.getInt("patch_number") : null;
  }

  void stagePatchFromUrls(
      int patchNumber,
      @NonNull String releaseVersion,
      @NonNull String dataDownloadUrl,
      @NonNull String instrDownloadUrl,
      @NonNull String dataSha256,
      @NonNull String instrSha256,
      @Nullable Long expectedDataLengthBytes,
      @Nullable Long expectedInstrLengthBytes,
      boolean enabled)
      throws IOException {
    File stagingDirectory = getStagingDirectory();
    deleteDirectoryContents(stagingDirectory);

    File dataFile = new File(stagingDirectory, ISOLATE_SNAPSHOT_DATA_FILE_NAME);
    File instrFile = new File(stagingDirectory, ISOLATE_SNAPSHOT_INSTR_FILE_NAME);
    downloadAndVerify(dataDownloadUrl, dataFile, dataSha256, expectedDataLengthBytes);
    downloadAndVerify(instrDownloadUrl, instrFile, instrSha256, expectedInstrLengthBytes);

    JSONObject manifest =
        new JSONObject()
            .put("patch_number", patchNumber)
            .put("release_version", releaseVersion)
            .put("isolate_data_sha256", dataSha256.toLowerCase(Locale.US))
            .put("isolate_instr_sha256", instrSha256.toLowerCase(Locale.US))
            .put("isolate_data_length_bytes", dataFile.length())
            .put("isolate_instr_length_bytes", instrFile.length())
            .put("enabled", enabled);
    writeManifest(new File(stagingDirectory, MANIFEST_FILE_NAME), manifest);
  }

  void applyStagedPatch() throws IOException {
    File stagingDirectory = getStagingDirectory();
    File stagedData = new File(stagingDirectory, ISOLATE_SNAPSHOT_DATA_FILE_NAME);
    File stagedInstr = new File(stagingDirectory, ISOLATE_SNAPSHOT_INSTR_FILE_NAME);
    File stagedManifest = new File(stagingDirectory, MANIFEST_FILE_NAME);
    if (!stagedData.exists() || !stagedInstr.exists() || !stagedManifest.exists()) {
      throw new IOException("No staged code push patch is available.");
    }

    File activeDirectory = getActiveDirectory();
    deleteDirectoryContents(activeDirectory);

    copyFile(stagedData, new File(activeDirectory, ISOLATE_SNAPSHOT_DATA_FILE_NAME));
    copyFile(stagedInstr, new File(activeDirectory, ISOLATE_SNAPSHOT_INSTR_FILE_NAME));
    copyFile(stagedManifest, new File(activeDirectory, MANIFEST_FILE_NAME));
    deleteDirectoryContents(stagingDirectory);
  }

  void clearActivePatch() {
    deleteDirectoryContents(getActiveDirectory());
    deleteDirectoryContents(getStagingDirectory());
  }

  private void downloadAndVerify(
      @NonNull String downloadUrl,
      @NonNull File destination,
      @NonNull String expectedSha256,
      @Nullable Long expectedLengthBytes)
      throws IOException {
    HttpURLConnection connection = null;
    try {
      connection = (HttpURLConnection) new URL(downloadUrl).openConnection();
      connection.setConnectTimeout(30_000);
      connection.setReadTimeout(300_000);
      connection.connect();
      if (connection.getResponseCode() != HttpURLConnection.HTTP_OK) {
        throw new IOException("Patch download failed with HTTP " + connection.getResponseCode());
      }

      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      try (InputStream inputStream = connection.getInputStream();
          FileOutputStream outputStream = new FileOutputStream(destination)) {
        byte[] buffer = new byte[8192];
        int read;
        long totalBytes = 0;
        while ((read = inputStream.read(buffer)) != -1) {
          digest.update(buffer, 0, read);
          outputStream.write(buffer, 0, read);
          totalBytes += read;
        }
        if (expectedLengthBytes != null && totalBytes != expectedLengthBytes) {
          throw new IOException(
              "Patch size mismatch. expected="
                  + expectedLengthBytes
                  + " actual="
                  + totalBytes);
        }
      }

      String actualSha256 = toHex(digest.digest());
      if (!actualSha256.equalsIgnoreCase(expectedSha256)) {
        destination.delete();
        throw new IOException("Patch SHA-256 mismatch.");
      }
    } catch (Exception exception) {
      destination.delete();
      if (exception instanceof IOException) {
        throw (IOException) exception;
      }
      throw new IOException(exception);
    } finally {
      if (connection != null) {
        connection.disconnect();
      }
    }
  }

  private File getRootDirectory() {
    return new File(context.getFilesDir(), ROOT_DIRECTORY_NAME);
  }

  private File getActiveDirectory() {
    File directory = new File(getRootDirectory(), ACTIVE_DIRECTORY_NAME);
    directory.mkdirs();
    return directory;
  }

  private File getStagingDirectory() {
    File directory = new File(getRootDirectory(), STAGING_DIRECTORY_NAME);
    directory.mkdirs();
    return directory;
  }

  private static JSONObject readManifest(@NonNull File manifestFile) throws IOException {
    try (FileInputStream inputStream = new FileInputStream(manifestFile)) {
      byte[] bytes = readAllBytes(inputStream);
      return new JSONObject(new String(bytes, StandardCharsets.UTF_8));
    } catch (org.json.JSONException exception) {
      throw new IOException(exception);
    }
  }

  private static void writeManifest(@NonNull File manifestFile, @NonNull JSONObject manifest)
      throws IOException {
    try (FileOutputStream outputStream = new FileOutputStream(manifestFile)) {
      outputStream.write(manifest.toString().getBytes(StandardCharsets.UTF_8));
    }
  }

  private static void copyFile(@NonNull File source, @NonNull File destination) throws IOException {
    try (FileInputStream inputStream = new FileInputStream(source);
        FileOutputStream outputStream = new FileOutputStream(destination)) {
      inputStream.transferTo(outputStream);
    }
  }

  private static void deleteDirectoryContents(@NonNull File directory) {
    if (!directory.exists()) {
      return;
    }
    File[] children = directory.listFiles();
    if (children == null) {
      return;
    }
    for (File child : children) {
      if (!child.delete()) {
        child.deleteOnExit();
      }
    }
  }

  private static byte[] readAllBytes(@NonNull FileInputStream inputStream) throws IOException {
    byte[] buffer = new byte[8192];
    int read;
    java.io.ByteArrayOutputStream outputStream = new java.io.ByteArrayOutputStream();
    while ((read = inputStream.read(buffer)) != -1) {
      outputStream.write(buffer, 0, read);
    }
    return outputStream.toByteArray();
  }

  private static String toHex(byte[] bytes) {
    StringBuilder builder = new StringBuilder(bytes.length * 2);
    for (byte value : bytes) {
      builder.append(String.format(Locale.US, "%02x", value));
    }
    return builder.toString();
  }
}
