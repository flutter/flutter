// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.mockito.Matchers.eq;
import static org.mockito.Mockito.any;
import static org.mockito.Mockito.anyInt;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.annotation.TargetApi;
import android.content.ContentResolver;
import android.content.Context;
import android.graphics.Rect;
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
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
@TargetApi(19)
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
  public void itAnnouncesRouteNameWhenAddingNewRoute() {
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    AccessibilityBridge accessibilityBridge =
        setUpBridge(mockRootView, mockManager, mockViewEmbedder);
    ViewParent mockParent = mock(ViewParent.class);
    when(mockRootView.getParent()).thenReturn(mockParent);
    when(mockManager.isEnabled()).thenReturn(true);

    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;
    TestSemanticsNode node1 = new TestSemanticsNode();
    node1.id = 1;
    node1.addFlag(AccessibilityBridge.Flag.SCOPES_ROUTE);
    node1.addFlag(AccessibilityBridge.Flag.NAMES_ROUTE);
    node1.label = "node1";
    root.children.add(node1);
    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    accessibilityBridge.updateSemantics(testSemanticsUpdate.buffer, testSemanticsUpdate.strings);

    ArgumentCaptor<AccessibilityEvent> eventCaptor =
        ArgumentCaptor.forClass(AccessibilityEvent.class);
    verify(mockParent, times(2))
        .requestSendAccessibilityEvent(eq(mockRootView), eventCaptor.capture());
    AccessibilityEvent event = eventCaptor.getAllValues().get(0);
    assertEquals(event.getEventType(), AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED);
    List<CharSequence> sentences = event.getText();
    assertEquals(sentences.size(), 1);
    assertEquals(sentences.get(0).toString(), "node1");

    TestSemanticsNode new_root = new TestSemanticsNode();
    new_root.id = 0;
    TestSemanticsNode new_node1 = new TestSemanticsNode();
    new_node1.id = 1;
    new_node1.addFlag(AccessibilityBridge.Flag.SCOPES_ROUTE);
    new_node1.addFlag(AccessibilityBridge.Flag.NAMES_ROUTE);
    new_node1.label = "new_node1";
    new_root.children.add(new_node1);
    TestSemanticsNode new_node2 = new TestSemanticsNode();
    new_node2.id = 2;
    new_node2.addFlag(AccessibilityBridge.Flag.SCOPES_ROUTE);
    new_node2.addFlag(AccessibilityBridge.Flag.NAMES_ROUTE);
    new_node2.label = "new_node2";
    new_node1.children.add(new_node2);
    testSemanticsUpdate = new_root.toUpdate();
    accessibilityBridge.updateSemantics(testSemanticsUpdate.buffer, testSemanticsUpdate.strings);

    eventCaptor = ArgumentCaptor.forClass(AccessibilityEvent.class);
    verify(mockParent, times(4))
        .requestSendAccessibilityEvent(eq(mockRootView), eventCaptor.capture());
    event = eventCaptor.getAllValues().get(2);
    assertEquals(event.getEventType(), AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED);
    sentences = event.getText();
    assertEquals(sentences.size(), 1);
    assertEquals(sentences.get(0).toString(), "new_node2");
  }

  @Test
  public void itIgnoresUnfocusableNodeDuringHitTest() {
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    AccessibilityBridge accessibilityBridge =
        setUpBridge(mockRootView, mockManager, mockViewEmbedder);
    ViewParent mockParent = mock(ViewParent.class);
    when(mockRootView.getParent()).thenReturn(mockParent);
    when(mockManager.isEnabled()).thenReturn(true);
    when(mockManager.isTouchExplorationEnabled()).thenReturn(true);

    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;
    root.left = 0;
    root.top = 0;
    root.bottom = 20;
    root.right = 20;
    TestSemanticsNode ignored = new TestSemanticsNode();
    ignored.id = 1;
    ignored.addFlag(AccessibilityBridge.Flag.SCOPES_ROUTE);
    ignored.left = 0;
    ignored.top = 0;
    ignored.bottom = 20;
    ignored.right = 20;
    root.children.add(ignored);
    TestSemanticsNode child = new TestSemanticsNode();
    child.id = 2;
    child.label = "label";
    child.left = 0;
    child.top = 0;
    child.bottom = 20;
    child.right = 20;
    root.children.add(child);
    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    accessibilityBridge.updateSemantics(testSemanticsUpdate.buffer, testSemanticsUpdate.strings);

    ArgumentCaptor<AccessibilityEvent> eventCaptor =
        ArgumentCaptor.forClass(AccessibilityEvent.class);
    verify(mockParent, times(2))
        .requestSendAccessibilityEvent(eq(mockRootView), eventCaptor.capture());
    AccessibilityEvent event = eventCaptor.getAllValues().get(0);
    assertEquals(event.getEventType(), AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED);

    // Synthesize an accessibility hit test event.
    MotionEvent mockEvent = mock(MotionEvent.class);
    when(mockEvent.getX()).thenReturn(10.0f);
    when(mockEvent.getY()).thenReturn(10.0f);
    when(mockEvent.getAction()).thenReturn(MotionEvent.ACTION_HOVER_ENTER);
    boolean hit = accessibilityBridge.onAccessibilityHoverEvent(mockEvent);

    assertEquals(hit, true);

    eventCaptor = ArgumentCaptor.forClass(AccessibilityEvent.class);
    verify(mockParent, times(3))
        .requestSendAccessibilityEvent(eq(mockRootView), eventCaptor.capture());
    event = eventCaptor.getAllValues().get(2);
    assertEquals(event.getEventType(), AccessibilityEvent.TYPE_VIEW_HOVER_ENTER);
    assertEquals(accessibilityBridge.getHoveredObjectId(), 2);
  }

  @Test
  public void itAnnouncesRouteNameWhenRemoveARoute() {
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    AccessibilityBridge accessibilityBridge =
        setUpBridge(mockRootView, mockManager, mockViewEmbedder);
    ViewParent mockParent = mock(ViewParent.class);
    when(mockRootView.getParent()).thenReturn(mockParent);
    when(mockManager.isEnabled()).thenReturn(true);

    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;
    TestSemanticsNode node1 = new TestSemanticsNode();
    node1.id = 1;
    node1.addFlag(AccessibilityBridge.Flag.SCOPES_ROUTE);
    node1.addFlag(AccessibilityBridge.Flag.NAMES_ROUTE);
    node1.label = "node1";
    root.children.add(node1);
    TestSemanticsNode node2 = new TestSemanticsNode();
    node2.id = 2;
    node2.addFlag(AccessibilityBridge.Flag.SCOPES_ROUTE);
    node2.addFlag(AccessibilityBridge.Flag.NAMES_ROUTE);
    node2.label = "node2";
    node1.children.add(node2);
    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    accessibilityBridge.updateSemantics(testSemanticsUpdate.buffer, testSemanticsUpdate.strings);

    ArgumentCaptor<AccessibilityEvent> eventCaptor =
        ArgumentCaptor.forClass(AccessibilityEvent.class);
    verify(mockParent, times(2))
        .requestSendAccessibilityEvent(eq(mockRootView), eventCaptor.capture());
    AccessibilityEvent event = eventCaptor.getAllValues().get(0);
    assertEquals(event.getEventType(), AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED);
    List<CharSequence> sentences = event.getText();
    assertEquals(sentences.size(), 1);
    assertEquals(sentences.get(0).toString(), "node2");

    TestSemanticsNode new_root = new TestSemanticsNode();
    new_root.id = 0;
    TestSemanticsNode new_node1 = new TestSemanticsNode();
    new_node1.id = 1;
    new_node1.label = "new_node1";
    new_root.children.add(new_node1);
    TestSemanticsNode new_node2 = new TestSemanticsNode();
    new_node2.id = 2;
    new_node2.addFlag(AccessibilityBridge.Flag.SCOPES_ROUTE);
    new_node2.addFlag(AccessibilityBridge.Flag.NAMES_ROUTE);
    new_node2.label = "new_node2";
    new_node1.children.add(new_node2);
    testSemanticsUpdate = new_root.toUpdate();
    accessibilityBridge.updateSemantics(testSemanticsUpdate.buffer, testSemanticsUpdate.strings);

    eventCaptor = ArgumentCaptor.forClass(AccessibilityEvent.class);
    verify(mockParent, times(4))
        .requestSendAccessibilityEvent(eq(mockRootView), eventCaptor.capture());
    event = eventCaptor.getAllValues().get(2);
    assertEquals(event.getEventType(), AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED);
    sentences = event.getText();
    assertEquals(sentences.size(), 1);
    assertEquals(sentences.get(0).toString(), "new_node2");
  }

  @Test
  public void itAnnouncesWhiteSpaceWhenNoNamesRoute() {
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    AccessibilityBridge accessibilityBridge =
        setUpBridge(mockRootView, mockManager, mockViewEmbedder);
    ViewParent mockParent = mock(ViewParent.class);
    when(mockRootView.getParent()).thenReturn(mockParent);
    when(mockManager.isEnabled()).thenReturn(true);

    // Sent a11y tree with scopeRoute without namesRoute.
    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;
    TestSemanticsNode scopeRoute = new TestSemanticsNode();
    scopeRoute.id = 1;
    scopeRoute.addFlag(AccessibilityBridge.Flag.SCOPES_ROUTE);
    root.children.add(scopeRoute);
    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    accessibilityBridge.updateSemantics(testSemanticsUpdate.buffer, testSemanticsUpdate.strings);

    ArgumentCaptor<AccessibilityEvent> eventCaptor =
        ArgumentCaptor.forClass(AccessibilityEvent.class);
    verify(mockParent, times(2))
        .requestSendAccessibilityEvent(eq(mockRootView), eventCaptor.capture());
    AccessibilityEvent event = eventCaptor.getAllValues().get(0);
    assertEquals(event.getEventType(), AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED);
    List<CharSequence> sentences = event.getText();
    assertEquals(sentences.size(), 1);
    assertEquals(sentences.get(0).toString(), " ");
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

  @Test
  public void itProducesPlatformViewNodeForHybridComposition() {
    PlatformViewsAccessibilityDelegate accessibilityDelegate =
        mock(PlatformViewsAccessibilityDelegate.class);

    Context context = RuntimeEnvironment.application.getApplicationContext();
    View rootAccessibilityView = new View(context);
    AccessibilityViewEmbedder accessibilityViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            rootAccessibilityView,
            /*accessibilityChannel=*/ null,
            /*accessibilityManager=*/ null,
            /*contentResolver=*/ null,
            accessibilityViewEmbedder,
            accessibilityDelegate);

    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;

    TestSemanticsNode platformView = new TestSemanticsNode();
    platformView.id = 1;
    platformView.platformViewId = 1;
    root.addChild(platformView);

    TestSemanticsUpdate testSemanticsRootUpdate = root.toUpdate();
    accessibilityBridge.updateSemantics(
        testSemanticsRootUpdate.buffer, testSemanticsRootUpdate.strings);

    TestSemanticsUpdate testSemanticsPlatformViewUpdate = platformView.toUpdate();
    accessibilityBridge.updateSemantics(
        testSemanticsPlatformViewUpdate.buffer, testSemanticsPlatformViewUpdate.strings);

    View embeddedView = mock(View.class);
    when(accessibilityDelegate.getPlatformViewById(1)).thenReturn(embeddedView);
    when(accessibilityDelegate.usesVirtualDisplay(1)).thenReturn(false);

    AccessibilityNodeInfo nodeInfo = mock(AccessibilityNodeInfo.class);
    when(embeddedView.createAccessibilityNodeInfo()).thenReturn(nodeInfo);

    AccessibilityNodeInfo result = accessibilityBridge.createAccessibilityNodeInfo(0);
    assertNotNull(result);
    assertEquals(result.getChildCount(), 1);
    assertEquals(result.getClassName(), "android.view.View");
  }

  @Test
  public void itProducesPlatformViewNodeForVirtualDisplay() {
    PlatformViewsAccessibilityDelegate accessibilityDelegate =
        mock(PlatformViewsAccessibilityDelegate.class);
    AccessibilityViewEmbedder accessibilityViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            /*rootAccessibilityView=*/ null,
            /*accessibilityChannel=*/ null,
            /*accessibilityManager=*/ null,
            /*contentResolver=*/ null,
            accessibilityViewEmbedder,
            accessibilityDelegate);

    TestSemanticsNode platformView = new TestSemanticsNode();
    platformView.platformViewId = 1;

    TestSemanticsUpdate testSemanticsUpdate = platformView.toUpdate();
    accessibilityBridge.updateSemantics(testSemanticsUpdate.buffer, testSemanticsUpdate.strings);

    View embeddedView = mock(View.class);
    when(accessibilityDelegate.getPlatformViewById(1)).thenReturn(embeddedView);
    when(accessibilityDelegate.usesVirtualDisplay(1)).thenReturn(true);

    accessibilityBridge.createAccessibilityNodeInfo(0);
    verify(accessibilityViewEmbedder).getRootNode(eq(embeddedView), eq(0), any(Rect.class));
  }

  @Test
  public void releaseDropsChannelMessageHandler() {
    AccessibilityChannel mockChannel = mock(AccessibilityChannel.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    ContentResolver mockContentResolver = mock(ContentResolver.class);
    when(mockManager.isEnabled()).thenReturn(true);
    AccessibilityBridge accessibilityBridge =
        setUpBridge(null, mockChannel, mockManager, mockContentResolver, null, null);
    verify(mockChannel)
        .setAccessibilityMessageHandler(
            any(AccessibilityChannel.AccessibilityMessageHandler.class));
    ArgumentCaptor<AccessibilityManager.AccessibilityStateChangeListener> stateListenerCaptor =
        ArgumentCaptor.forClass(AccessibilityManager.AccessibilityStateChangeListener.class);
    ArgumentCaptor<AccessibilityManager.TouchExplorationStateChangeListener> touchListenerCaptor =
        ArgumentCaptor.forClass(AccessibilityManager.TouchExplorationStateChangeListener.class);
    verify(mockManager).addAccessibilityStateChangeListener(stateListenerCaptor.capture());
    verify(mockManager).addTouchExplorationStateChangeListener(touchListenerCaptor.capture());
    accessibilityBridge.release();
    verify(mockChannel).setAccessibilityMessageHandler(null);
    reset(mockChannel);
    stateListenerCaptor.getValue().onAccessibilityStateChanged(true);
    verify(mockChannel, never()).onAndroidAccessibilityEnabled();
    touchListenerCaptor.getValue().onTouchExplorationStateChanged(true);
    verify(mockChannel, never()).setAccessibilityFeatures(anyInt());
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

    public void addChild(TestSemanticsNode child) {
      children.add(child);
    }
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
