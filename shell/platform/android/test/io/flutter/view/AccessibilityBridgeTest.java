// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import static org.junit.Assert.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import android.content.ContentResolver;
import android.content.Context;
import android.view.View;
import android.view.accessibility.AccessibilityManager;
import android.view.accessibility.AccessibilityNodeInfo;
import io.flutter.embedding.engine.systemchannels.AccessibilityChannel;
import io.flutter.plugin.platform.PlatformViewsAccessibilityDelegate;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class AccessibilityBridgeTest {

  @Test
  public void itDescribesNonTextFieldsWithAContentDescription() {
    AccessibilityBridge accessibilityBridge = setUpBridge();

    TestSemanticsNode testSemanticsNode = new TestSemanticsNode();
    testSemanticsNode.label = "Hello, World";
    TestSemanticsUpdate testSemanticsUpdate = testSemanticsNode.toUpdate();

    accessibilityBridge.updateSemantics(testSemanticsUpdate.buffer, testSemanticsUpdate.strings);
    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);

    assertEquals(nodeInfo.getContentDescription(), "Hello, World");
    assertEquals(nodeInfo.getText(), null);
  }

  @Test
  public void itDescribesTextFieldsWithText() {
    AccessibilityBridge accessibilityBridge = setUpBridge();

    TestSemanticsNode testSemanticsNode = new TestSemanticsNode();
    testSemanticsNode.label = "Hello, World";
    testSemanticsNode.addFlag(AccessibilityBridge.Flag.IS_TEXT_FIELD);
    TestSemanticsUpdate testSemanticsUpdate = testSemanticsNode.toUpdate();

    accessibilityBridge.updateSemantics(testSemanticsUpdate.buffer, testSemanticsUpdate.strings);
    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);

    assertEquals(nodeInfo.getContentDescription(), null);
    assertEquals(nodeInfo.getText(), "Hello, World");
  }

  @Test
  public void itDoesNotContainADescriptionIfScopesRoute() {
    AccessibilityBridge accessibilityBridge = setUpBridge();

    TestSemanticsNode testSemanticsNode = new TestSemanticsNode();
    testSemanticsNode.label = "Hello, World";
    testSemanticsNode.addFlag(AccessibilityBridge.Flag.SCOPES_ROUTE);
    TestSemanticsUpdate testSemanticsUpdate = testSemanticsNode.toUpdate();

    accessibilityBridge.updateSemantics(testSemanticsUpdate.buffer, testSemanticsUpdate.strings);
    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);

    assertEquals(nodeInfo.getContentDescription(), null);
    assertEquals(nodeInfo.getText(), null);
  }

  AccessibilityBridge setUpBridge() {
    View view = mock(View.class);
    Context context = mock(Context.class);
    when(view.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    AccessibilityChannel accessibilityChannel = mock(AccessibilityChannel.class);
    AccessibilityManager accessibilityManager = mock(AccessibilityManager.class);
    ContentResolver contentResolver = mock(ContentResolver.class);
    PlatformViewsAccessibilityDelegate platformViewsAccessibilityDelegate =
        mock(PlatformViewsAccessibilityDelegate.class);
    AccessibilityBridge accessibilityBridge =
        new AccessibilityBridge(
            view,
            accessibilityChannel,
            accessibilityManager,
            contentResolver,
            platformViewsAccessibilityDelegate);
    return accessibilityBridge;
  }

  /// The encoding for semantics is described in platform_view_android.cc
  class TestSemanticsUpdate {
    TestSemanticsUpdate(ByteBuffer buffer, String[] strings) {
      this.buffer = buffer;
      this.strings = strings;
    }

    final ByteBuffer buffer;
    final String[] strings;
  }

  class TestSemanticsNode {
    TestSemanticsNode() {}

    void addFlag(AccessibilityBridge.Flag flag) {
      flags |= flag.value;
    }

    // These fields are declared in the order they should be
    // encoded.
    int id = 0;
    int flags = 0;
    int actions = 0;
    int maxValueLength = 0;
    int currentValueLength = 0;
    int textSelectionBase = 0;
    int textSelectionExtent = 0;
    int platformViewId = -1;
    int scrollChildren = 0;
    int scrollIndex = 0;
    float scrollPosition = 0.0f;
    float scrollExtentMax = 0.0f;
    float scrollExtentMin = 0.0f;
    String label = null;
    String value = null;
    String increasedValue = null;
    String decreasedValue = null;
    String hint = null;
    int textDirection = 0;
    float left = 0.0f;
    float top = 0.0f;
    float right = 0.0f;
    float bottom = 0.0f;
    // children and custom actions not supported.

    TestSemanticsUpdate toUpdate() {
      ArrayList<String> strings = new ArrayList<String>();
      ByteBuffer bytes = ByteBuffer.allocate(1000);
      bytes.putInt(id);
      bytes.putInt(flags);
      bytes.putInt(actions);
      bytes.putInt(maxValueLength);
      bytes.putInt(currentValueLength);
      bytes.putInt(textSelectionBase);
      bytes.putInt(textSelectionExtent);
      bytes.putInt(platformViewId);
      bytes.putInt(scrollChildren);
      bytes.putInt(scrollIndex);
      bytes.putFloat(scrollPosition);
      bytes.putFloat(scrollExtentMax);
      bytes.putFloat(scrollExtentMin);
      updateString(label, bytes, strings);
      updateString(value, bytes, strings);
      updateString(increasedValue, bytes, strings);
      updateString(decreasedValue, bytes, strings);
      updateString(hint, bytes, strings);
      bytes.putInt(textDirection);
      bytes.putFloat(left);
      bytes.putFloat(top);
      bytes.putFloat(right);
      bytes.putFloat(bottom);
      // transform.
      for (int i = 0; i < 16; i++) {
        bytes.putFloat(0);
      }
      // children in traversal order.
      bytes.putInt(0);
      // custom actions
      bytes.putInt(0);
      bytes.flip();
      return new TestSemanticsUpdate(bytes, strings.toArray(new String[strings.size()]));
    }
  }

  static void updateString(String value, ByteBuffer bytes, ArrayList<String> strings) {
    if (value == null) {
      bytes.putInt(-1);
    } else {
      strings.add(value);
      bytes.putInt(strings.size() - 1);
    }
  }
}
