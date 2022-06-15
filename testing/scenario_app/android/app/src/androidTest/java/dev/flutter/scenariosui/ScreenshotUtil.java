// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.flutter.scenariosui;

import android.graphics.Bitmap;
import androidx.annotation.NonNull;
import androidx.test.InstrumentationRegistry;
import dev.flutter.scenarios.TestableFlutterActivity;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.Socket;
import java.nio.ByteBuffer;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;

/**
 * Allows to capture screenshots, and transfers the screenshots to the host where they can be
 * further proccessed. On a LUCI environment, the screenshots are sent to Skia Gold.
 */
public class ScreenshotUtil {
  private static final String HOST = "localhost";
  private static final int PORT = 3000;

  private static Connection conn;
  private static Executor executor;

  private static class Connection {
    final Socket clientSocket;
    final OutputStream out;

    Connection(Socket socket) throws IOException {
      clientSocket = socket;
      out = socket.getOutputStream();
    }

    synchronized void writeFile(String name, byte[] fileContent) throws IOException {
      final ByteBuffer buffer = ByteBuffer.allocate(name.length() + fileContent.length + 8);
      // See ScreenshotBlobTransformer#bind in screenshot_transformer.dart for consumer side.
      buffer.putInt(name.length());
      buffer.putInt(fileContent.length);
      buffer.put(name.getBytes());
      buffer.put(fileContent);
      final byte[] bytes = buffer.array();
      out.write(bytes, 0, bytes.length);
      out.flush();
    }

    synchronized void close() throws IOException {
      clientSocket.close();
    }
  }

  /** Starts the connection with the host. */
  public static synchronized void onCreate() {
    if (executor == null) {
      executor = Executors.newSingleThreadExecutor();
    }
    if (conn == null) {
      executor.execute(
          () -> {
            try {
              final Socket socket = new Socket(HOST, PORT);
              conn = new Connection(socket);
            } catch (IOException e) {
              throw new RuntimeException(e);
            }
          });
    }
  }

  /** Closes the connection with the host. */
  public static synchronized void finish() {
    if (executor != null && conn != null) {
      executor.execute(
          () -> {
            try {
              conn.close();
              conn = null;
            } catch (IOException e) {
              throw new RuntimeException(e);
            }
          });
    }
  }

  /**
   * Sends the file to the host.
   *
   * @param filename The file name.
   * @param fileContent The file content.
   */
  public static synchronized void writeFile(@NonNull String filename, @NonNull byte[] fileContent) {
    if (executor != null && conn != null) {
      executor.execute(
          () -> {
            try {
              conn.writeFile(filename, fileContent);
            } catch (IOException e) {
              throw new RuntimeException(e);
            }
          });
    }
  }

  /**
   * Captures a screenshot of the activity, and sends the screenshot bytes to the host where it is
   * further processed.
   *
   * <p>The activity must be already launched.
   *
   * @param activity The target activity.
   * @param fileName The name of the file.
   */
  public static void capture(@NonNull TestableFlutterActivity activity, @NonNull String captureName)
      throws Exception {
    activity.waitUntilFlutterRendered();

    final Bitmap bitmap =
        InstrumentationRegistry.getInstrumentation().getUiAutomation().takeScreenshot();
    if (bitmap == null) {
      throw new RuntimeException("failed to capture screenshot");
    }
    final ByteArrayOutputStream out = new ByteArrayOutputStream();
    bitmap.compress(Bitmap.CompressFormat.PNG, 100, out);
    ScreenshotUtil.writeFile(captureName, out.toByteArray());
  }
}
