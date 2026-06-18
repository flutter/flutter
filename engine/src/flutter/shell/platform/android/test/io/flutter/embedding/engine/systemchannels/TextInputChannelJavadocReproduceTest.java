// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.systemchannels;

import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;

import androidx.test.ext.junit.runners.AndroidJUnit4;
import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.annotation.Config;

@Config(shadows = {})
@RunWith(AndroidJUnit4.class)
public class TextInputChannelJavadocReproduceTest {

  @Test
  public void testTextInputChannelHasRequiredJavadocs() {
    File sourceFile = findSourceFile();
    assertNotNull(
        "Could not find TextInputChannel.java source file in the directory hierarchy. "
            + "Current working directory is: "
            + new File(".").getAbsolutePath(),
        sourceFile);

    String content;
    try {
      content = new String(Files.readAllBytes(sourceFile.toPath()), StandardCharsets.UTF_8);
    } catch (IOException e) {
      fail("Failed to read TextInputChannel.java: " + e.getMessage());
      return;
    }

    // Standardize line endings to simplify regex matching.
    content = content.replace("\r\n", "\n");

    // Extract the TextInputMethodHandler interface block to prevent false positive matches
    // in other parts of the file.
    int interfaceStart = content.indexOf("public interface TextInputMethodHandler {");
    assertTrue(
        "Could not find TextInputMethodHandler interface in TextInputChannel.java",
        interfaceStart != -1);

    int interfaceEnd = content.indexOf("public static class Configuration", interfaceStart);
    assertTrue("Could not find Configuration class in TextInputChannel.java", interfaceEnd != -1);

    String interfaceContent = content.substring(interfaceStart, interfaceEnd);

    // Verify Javadoc presence for each required method in the TextInputMethodHandler interface.
    assertMethodHasJavadoc(interfaceContent, "show");
    assertMethodHasJavadoc(interfaceContent, "hide");
    assertMethodHasJavadoc(interfaceContent, "setClient");
    assertMethodHasJavadoc(interfaceContent, "setEditingState");
    assertMethodHasJavadoc(interfaceContent, "clearClient");
  }

  /**
   * Helper to locate the TextInputChannel.java source file by walking up from the current working
   * directory to handle different test execution environments.
   */
  private File findSourceFile() {
    File dir = new File(".").getAbsoluteFile();
    while (dir != null) {
      File candidate =
          new File(
              dir,
              "src/flutter/shell/platform/android/io/flutter/embedding/engine/systemchannels/TextInputChannel.java");
      if (candidate.exists()) {
        return candidate;
      }
      candidate =
          new File(
              dir,
              "flutter/shell/platform/android/io/flutter/embedding/engine/systemchannels/TextInputChannel.java");
      if (candidate.exists()) {
        return candidate;
      }
      candidate = new File(dir, "io/flutter/embedding/engine/systemchannels/TextInputChannel.java");
      if (candidate.exists()) {
        return candidate;
      }
      dir = dir.getParentFile();
    }
    return null;
  }

  /**
   * Asserts that the specified method name is preceded by a valid Javadoc block (/** ... * /) in
   * the interface source code.
   */
  private void assertMethodHasJavadoc(String content, String methodName) {
    // Regex pattern matching:
    // 1. A Javadoc block: starts with /** and ends with */ (using non-greedy dotall matching)
    // 2. Optional whitespace
    // 3. Optional annotations (including those with parameters like
    // @SuppressWarnings("deprecation"))
    // 4. Return type (allowing generics or arrays) and the method name followed by opening
    // parenthesis
    String regex =
        "/\\*\\*.*?\\*/\\s*(?:@[a-zA-Z0-9_]+(?:\\([^)]*\\))?\\s+)*[a-zA-Z0-9_<>\\[\\]]+\\s+"
            + methodName
            + "\\s*\\(";
    Pattern pattern = Pattern.compile(regex, Pattern.DOTALL);
    Matcher matcher = pattern.matcher(content);
    assertTrue(
        "Method "
            + methodName
            + "() in TextInputMethodHandler is missing Javadoc documentation or does not match the expected signature pattern.",
        matcher.find());
  }
}
