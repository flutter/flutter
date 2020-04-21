// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import static org.junit.Assert.assertEquals;
import static org.mockito.Matchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.content.ContentResolver;
import android.content.Context;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewParent;
import android.view.accessibility.AccessibilityEvent;
import android.view.accessibility.AccessibilityManager;
import android.view.accessibility.AccessibilityNodeInfo;
import io.flutter.embedding.engine.systemchannels.AccessibilityChannel;
import io.flutter.plugin.platform.PlatformViewsAccessibilityDelegate;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.List;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
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

  @Test
  public void itUnfocusesPlatformViewWhenPlatformViewGoesAway() {
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    AccessibilityBridge accessibilityBridge =
        setUpBridge(mockRootView, mockManager, mockViewEmbedder);

    // Sent a11y tree with platform view.
    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;
    TestSemanticsNode platformView = new TestSemanticsNode();
    platformView.id = 1;
    platformView.platformViewId = 42;
    root.children.add(platformView);
    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    accessibilityBridge.updateSemantics(testSemanticsUpdate.buffer, testSemanticsUpdate.strings);

    // Set a11y focus to platform view.
    View mockView = mock(View.class);
    AccessibilityEvent focusEvent = mock(AccessibilityEvent.class);
    when(mockViewEmbedder.requestSendAccessibilityEvent(mockView, mockView, focusEvent))
        .thenReturn(true);
    when(mockViewEmbedder.getRecordFlutterId(mockView, focusEvent)).thenReturn(42);
    when(focusEvent.getEventType()).thenReturn(AccessibilityEvent.TYPE_VIEW_ACCESSIBILITY_FOCUSED);
    accessibilityBridge.externalViewRequestSendAccessibilityEvent(mockView, mockView, focusEvent);

    // Replace the platform view.
    TestSemanticsNode node = new TestSemanticsNode();
    node.id = 2;
    root.children.clear();
    root.children.add(node);
    testSemanticsUpdate = root.toUpdate();
    when(mockManager.isEnabled()).thenReturn(true);
    ViewParent mockParent = mock(ViewParent.class);
    when(mockRootView.getParent()).thenReturn(mockParent);
    accessibilityBridge.updateSemantics(testSemanticsUpdate.buffer, testSemanticsUpdate.strings);

    // Check that unfocus event was sent.
    ArgumentCaptor<AccessibilityEvent> eventCaptor =
        ArgumentCaptor.forClass(AccessibilityEvent.class);
    verify(mockParent, times(2))
        .requestSendAccessibilityEvent(eq(mockRootView), eventCaptor.capture());
    AccessibilityEvent event = eventCaptor.getAllValues().get(0);
    assertEquals(event.getEventType(), AccessibilityEvent.TYPE_VIEW_ACCESSIBILITY_FOCUS_CLEARED);
  }

  @Test
  public void itHoverOverOutOfBoundsDoesNotCrash() {
    // SementicsNode.hitTest() returns null when out of bounds.
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    AccessibilityBridge accessibilityBridge =
        setUpBridge(mockRootView, mockManager, mockViewEmbedder);

    // Sent a11y tree with platform view.
    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;
    TestSemanticsNode platformView = new TestSemanticsNode();
    platformView.id = 1;
    platformView.platformViewId = 42;
    root.children.add(platformView);
    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    accessibilityBridge.updateSemantics(testSemanticsUpdate.buffer, testSemanticsUpdate.strings);

    // Pass an out of bounds MotionEvent.
    accessibilityBridge.onAccessibilityHoverEvent(MotionEvent.obtain(1, 1, 1, -10, -10, 0));
  }

  AccessibilityBridge setUpBridge() {
    return setUpBridge(null, null, null, null, null, null);
  }

  AccessibilityBridge setUpBridge(
      View rootAccessibilityView,
      AccessibilityManager accessibilityManager,
      AccessibilityViewEmbedder accessibilityViewEmbedder) {
    return setUpBridge(
        rootAccessibilityView, null, accessibilityManager, null, accessibilityViewEmbedder, null);
  }

  AccessibilityBridge setUpBridge(
      View rootAccessibilityView,
      AccessibilityChannel accessibilityChannel,
      AccessibilityManager accessibilityManager,
      ContentResolver contentResolver,
      AccessibilityViewEmbedder accessibilityViewEmbedder,
      PlatformViewsAccessibilityDelegate platformViewsAccessibilityDelegate) {
    if (rootAccessibilityView == null) {
      rootAccessibilityView = mock(View.class);
      Context context = mock(Context.class);
      when(rootAccessibilityView.getContext()).thenReturn(context);
      when(context.getPackageName()).thenReturn("test");
    }
    if (accessibilityChannel == null) {
      accessibilityChannel = mock(AccessibilityChannel.class);
    }
    if (accessibilityManager == null) {
      accessibilityManager = mock(AccessibilityManager.class);
    }
    if (contentResolver == null) {
      contentResolver = mock(ContentResolver.class);
    }
    if (accessibilityViewEmbedder == null) {
      accessibilityViewEmbedder = mock(AccessibilityViewEmbedder.class);
    }
    if (platformViewsAccessibilityDelegate == null) {
      platformViewsAccessibilityDelegate = mock(PlatformViewsAccessibilityDelegate.class);
    }
    return new AccessibilityBridge(
        rootAccessibilityView,
        accessibilityChannel,
        accessibilityManager,
        contentResolver,
        accessibilityViewEmbedder,
        platformViewsAccessibilityDelegate);
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
    final List<TestSemanticsNode> children = new ArrayList<TestSemanticsNode>();
    // custom actions not supported.

    TestSemanticsUpdate toUpdate() {
      ArrayList<String> strings = new ArrayList<String>();
      ByteBuffer bytes = ByteBuffer.allocate(1000);
      addToBuffer(bytes, strings);
      bytes.flip();
      return new TestSemanticsUpdate(bytes, strings.toArray(new String[strings.size()]));
    }

    protected void addToBuffer(ByteBuffer bytes, ArrayList<String> strings) {
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
      bytes.putInt(children.size());
      for (TestSemanticsNode node : children) {
        bytes.putInt(node.id);
      }
      // children in hit test order.
      for (TestSemanticsNode node : children) {
        bytes.putInt(node.id);
      }
      // custom actions
      bytes.putInt(0);
      // child nodes
      for (TestSemanticsNode node : children) {
        node.addToBuffer(bytes, strings);
      }
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
