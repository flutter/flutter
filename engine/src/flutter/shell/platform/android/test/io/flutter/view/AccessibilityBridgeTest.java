// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import static io.flutter.Build.API_LEVELS;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.any;
import static org.mockito.Mockito.anyInt;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.annotation.TargetApi;
import android.content.ContentResolver;
import android.content.Context;
import android.content.res.Configuration;
import android.content.res.Resources;
import android.database.ContentObserver;
import android.graphics.Rect;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.text.SpannableString;
import android.text.SpannedString;
import android.text.style.LocaleSpan;
import android.text.style.TtsSpan;
import android.text.style.URLSpan;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewParent;
import android.view.accessibility.AccessibilityEvent;
import android.view.accessibility.AccessibilityManager;
import android.view.accessibility.AccessibilityNodeInfo;
import androidx.test.core.app.ApplicationProvider;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.systemchannels.AccessibilityChannel;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.platform.PlatformViewsAccessibilityDelegate;
import io.flutter.view.AccessibilityBridge.Action;
import io.flutter.view.AccessibilityBridge.Flag;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import org.junit.Ignore;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.invocation.InvocationOnMock;
import org.robolectric.annotation.Config;

@RunWith(AndroidJUnit4.class)
public class AccessibilityBridgeTest {

  private static final int ACCESSIBILITY_FEATURE_NAVIGATION = 1 << 0;
  private static final int ACCESSIBILITY_FEATURE_DISABLE_ANIMATIONS = 1 << 2;
  private static final int ACCESSIBILITY_FEATURE_BOLD_TEXT = 1 << 3;
  private static final int ACCESSIBILITY_FEATURE_NO_ANNOUNCE = 1 << 7;

  @Test
  public void itDescribesNonTextFieldsWithAContentDescription() {
    AccessibilityBridge accessibilityBridge = setUpBridge();

    TestSemanticsNode testSemanticsNode = new TestSemanticsNode();
    testSemanticsNode.label = "Hello, World";
    TestSemanticsUpdate testSemanticsUpdate = testSemanticsNode.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);
    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);

    assertEquals("Hello, World", nodeInfo.getContentDescription().toString());
    assertNull(nodeInfo.getText());
  }

  @Config(sdk = API_LEVELS.API_28)
  @TargetApi(API_LEVELS.API_28)
  @Test
  public void itDescribesTextFieldsWithTextAndHint() {
    AccessibilityBridge accessibilityBridge = setUpBridge();

    TestSemanticsNode testSemanticsNode = new TestSemanticsNode();
    testSemanticsNode.value = "Hello, World";
    testSemanticsNode.label = "some label";
    testSemanticsNode.hint = "some hint";
    testSemanticsNode.addFlag(AccessibilityBridge.Flag.IS_TEXT_FIELD);
    TestSemanticsUpdate testSemanticsUpdate = testSemanticsNode.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);
    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);

    assertNull(nodeInfo.getContentDescription());
    assertEquals("Hello, World", nodeInfo.getText().toString());
    assertEquals("some label, some hint", nodeInfo.getHintText().toString());
  }

  @Test
  public void itTakesGlobalCoordinatesOfFlutterViewIntoAccount() {
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    final int position = 88;
    // The getBoundsInScreen() in createAccessibilityNodeInfo() needs
    // View.getLocationOnScreen()
    doAnswer(
            invocation -> {
              int[] outLocation = (int[]) invocation.getArguments()[0];
              outLocation[0] = position;
              outLocation[1] = position;
              return null;
            })
        .when(mockRootView)
        .getLocationOnScreen(any(int[].class));

    when(context.getPackageName()).thenReturn("test");
    AccessibilityBridge accessibilityBridge =
        setUpBridge(mockRootView, mockManager, mockViewEmbedder);

    TestSemanticsNode testSemanticsNode = new TestSemanticsNode();
    TestSemanticsUpdate testSemanticsUpdate = testSemanticsNode.toUpdate();

    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);
    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);

    Rect outBoundsInScreen = new Rect();
    nodeInfo.getBoundsInScreen(outBoundsInScreen);
    assertEquals(position, outBoundsInScreen.left);
    assertEquals(position, outBoundsInScreen.top);
  }

  @Test
  public void itSetsNoAnnounceAccessibleFlagByDefault() {
    AccessibilityChannel mockChannel = mock(AccessibilityChannel.class);
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    when(mockManager.isTouchExplorationEnabled()).thenReturn(false);
    setUpBridge(
        /* rootAccessibilityView= */ mockRootView,
        /* accessibilityChannel= */ mockChannel,
        /* accessibilityManager= */ mockManager,
        /* contentResolver= */ null,
        /* accessibilityViewEmbedder= */ mockViewEmbedder,
        /* platformViewsAccessibilityDelegate= */ null);
    verify(mockChannel).setAccessibilityFeatures(ACCESSIBILITY_FEATURE_NO_ANNOUNCE);
  }

  @Test
  public void itSetsDelegateOnChannel() {
    AccessibilityChannel mockChannel = mock(AccessibilityChannel.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);

    AccessibilityBridge bridge =
        setUpBridge(
            /* rootAccessibilityView= */ mockRootView,
            /* accessibilityChannel= */ mockChannel,
            /* accessibilityManager= */ mockManager,
            /* contentResolver= */ null,
            /* accessibilityViewEmbedder= */ mockViewEmbedder,
            /* platformViewsAccessibilityDelegate= */ null);
    verify(mockChannel).setAccessibilityMessageHandler(bridge.accessibilityMessageHandler);
  }

  @Test
  public void setSemanticsTreeEnabledFalseClearsSemanticsTree() {
    AccessibilityChannel mockChannel = mock(AccessibilityChannel.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);

    AccessibilityBridge bridge =
        setUpBridge(
            /* rootAccessibilityView= */ mockRootView,
            /* accessibilityChannel= */ mockChannel,
            /* accessibilityManager= */ mockManager,
            /* contentResolver= */ null,
            /* accessibilityViewEmbedder= */ mockViewEmbedder,
            /* platformViewsAccessibilityDelegate= */ null);

    // Add a node to the semantics tree.
    TestSemanticsNode testSemanticsNode = new TestSemanticsNode();
    TestSemanticsUpdate testSemanticsUpdate = testSemanticsNode.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(bridge);
    assertFalse(bridge.flutterSemanticsTree.isEmpty());

    // Disable semantics and check that the tree is cleared.
    bridge.accessibilityMessageHandler.resetSemantics();
    assertTrue(bridge.flutterSemanticsTree.isEmpty());
  }

  @Test
  public void itSetsAccessibleNavigation() {
    AccessibilityChannel mockChannel = mock(AccessibilityChannel.class);
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    when(mockManager.isTouchExplorationEnabled()).thenReturn(false);
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            /* rootAccessibilityView= */ mockRootView,
            /* accessibilityChannel= */ mockChannel,
            /* accessibilityManager= */ mockManager,
            /* contentResolver= */ null,
            /* accessibilityViewEmbedder= */ mockViewEmbedder,
            /* platformViewsAccessibilityDelegate= */ null);
    ArgumentCaptor<AccessibilityManager.TouchExplorationStateChangeListener> listenerCaptor =
        ArgumentCaptor.forClass(AccessibilityManager.TouchExplorationStateChangeListener.class);
    verify(mockManager).addTouchExplorationStateChangeListener(listenerCaptor.capture());

    assertFalse(accessibilityBridge.getAccessibleNavigation());
    verify(mockChannel).setAccessibilityFeatures(ACCESSIBILITY_FEATURE_NO_ANNOUNCE);
    reset(mockChannel);

    // Simulate assistive technology accessing accessibility tree.
    accessibilityBridge.createAccessibilityNodeInfo(0);
    verify(mockChannel)
        .setAccessibilityFeatures(
            ACCESSIBILITY_FEATURE_NAVIGATION | ACCESSIBILITY_FEATURE_NO_ANNOUNCE);
    assertTrue(accessibilityBridge.getAccessibleNavigation());

    // Simulate turning off TalkBack.
    reset(mockChannel);
    listenerCaptor.getValue().onTouchExplorationStateChanged(false);
    verify(mockChannel).setAccessibilityFeatures(ACCESSIBILITY_FEATURE_NO_ANNOUNCE);
    assertFalse(accessibilityBridge.getAccessibleNavigation());
  }

  @Test
  public void itDoesNotContainADescriptionIfScopesRoute() {
    AccessibilityBridge accessibilityBridge = setUpBridge();

    TestSemanticsNode testSemanticsNode = new TestSemanticsNode();
    testSemanticsNode.label = "Hello, World";
    testSemanticsNode.addFlag(AccessibilityBridge.Flag.SCOPES_ROUTE);
    TestSemanticsUpdate testSemanticsUpdate = testSemanticsNode.toUpdate();

    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);
    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);

    assertNull(nodeInfo.getContentDescription());
    assertNull(nodeInfo.getText());
  }

  @Test
  public void itCreatesURLSpanForlinkURL() {
    AccessibilityBridge accessibilityBridge = setUpBridge();

    TestSemanticsNode testSemanticsNode = new TestSemanticsNode();
    testSemanticsNode.label = "Hello";
    testSemanticsNode.linkUrl = "https://flutter.dev";
    testSemanticsNode.addFlag(AccessibilityBridge.Flag.IS_LINK);
    TestSemanticsUpdate testSemanticsUpdate = testSemanticsNode.toUpdate();

    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);
    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
    SpannableString actual = (SpannableString) nodeInfo.getContentDescription();
    assertEquals("Hello", actual.toString());
    Object[] objectSpans = actual.getSpans(0, actual.length(), Object.class);
    assertEquals(1, objectSpans.length);
    URLSpan span = (URLSpan) objectSpans[0];
    assertEquals("https://flutter.dev", span.getURL());
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
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

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
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    // Check that unfocus event was sent.
    ArgumentCaptor<AccessibilityEvent> eventCaptor =
        ArgumentCaptor.forClass(AccessibilityEvent.class);
    verify(mockParent, times(2))
        .requestSendAccessibilityEvent(eq(mockRootView), eventCaptor.capture());
    AccessibilityEvent event = eventCaptor.getAllValues().get(0);
    assertEquals(AccessibilityEvent.TYPE_VIEW_ACCESSIBILITY_FOCUS_CLEARED, event.getEventType());
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
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    verify(mockRootView, times(1)).setAccessibilityPaneTitle(eq("node1"));

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
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    verify(mockRootView, times(1)).setAccessibilityPaneTitle(eq("new_node2"));
  }

  @Test
  public void itSetsTraversalAfter() {
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
    node1.label = "node1";
    root.children.add(node1);
    TestSemanticsNode node2 = new TestSemanticsNode();
    node2.id = 2;
    node2.label = "node2";
    root.children.add(node2);
    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    AccessibilityBridge spyAccessibilityBridge = spy(accessibilityBridge);
    AccessibilityNodeInfo mockNodeInfo2 = mock(AccessibilityNodeInfo.class);

    when(spyAccessibilityBridge.obtainAccessibilityNodeInfo(mockRootView, 2))
        .thenReturn(mockNodeInfo2);
    spyAccessibilityBridge.createAccessibilityNodeInfo(2);
    verify(mockNodeInfo2, times(1)).setTraversalAfter(eq(mockRootView), eq(1));
  }

  @Config(sdk = API_LEVELS.API_24)
  @TargetApi(API_LEVELS.API_24)
  @Test
  public void itSetsRootViewNotImportantForAccessibility() {
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
    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    AccessibilityBridge spyAccessibilityBridge = spy(accessibilityBridge);
    AccessibilityNodeInfo mockNodeInfo = mock(AccessibilityNodeInfo.class);

    when(spyAccessibilityBridge.obtainAccessibilityNodeInfo(mockRootView)).thenReturn(mockNodeInfo);
    spyAccessibilityBridge.createAccessibilityNodeInfo(View.NO_ID);
    verify(mockNodeInfo, times(1)).setImportantForAccessibility(eq(false));
  }

  @Config(sdk = API_LEVELS.API_24)
  @TargetApi(API_LEVELS.API_24)
  @Test
  public void itSetsNodeImportantForAccessibilityIfItHasContent() {
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
    root.label = "some label";
    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    AccessibilityBridge spyAccessibilityBridge = spy(accessibilityBridge);
    AccessibilityNodeInfo mockNodeInfo = mock(AccessibilityNodeInfo.class);

    when(spyAccessibilityBridge.obtainAccessibilityNodeInfo(mockRootView, 0))
        .thenReturn(mockNodeInfo);
    spyAccessibilityBridge.createAccessibilityNodeInfo(0);
    verify(mockNodeInfo, times(1)).setImportantForAccessibility(eq(true));
  }

  @Config(sdk = API_LEVELS.API_24)
  @TargetApi(API_LEVELS.API_24)
  @Test
  public void itSetsNodeImportantForAccessibilityIfItHasActions() {
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
    root.addAction(Action.TAP);
    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    AccessibilityBridge spyAccessibilityBridge = spy(accessibilityBridge);
    AccessibilityNodeInfo mockNodeInfo = mock(AccessibilityNodeInfo.class);

    when(spyAccessibilityBridge.obtainAccessibilityNodeInfo(mockRootView, 0))
        .thenReturn(mockNodeInfo);
    spyAccessibilityBridge.createAccessibilityNodeInfo(0);
    verify(mockNodeInfo, times(1)).setImportantForAccessibility(eq(true));
  }

  @Config(sdk = API_LEVELS.API_24)
  @TargetApi(API_LEVELS.API_24)
  @Test
  public void itSetsNodeUnImportantForAccessibilityIfItIsEmpty() {
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
    TestSemanticsNode node = new TestSemanticsNode();
    node.id = 1;
    root.children.add(node);
    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    AccessibilityBridge spyAccessibilityBridge = spy(accessibilityBridge);
    AccessibilityNodeInfo mockNodeInfo = mock(AccessibilityNodeInfo.class);

    when(spyAccessibilityBridge.obtainAccessibilityNodeInfo(mockRootView, 0))
        .thenReturn(mockNodeInfo);
    spyAccessibilityBridge.createAccessibilityNodeInfo(0);
    verify(mockNodeInfo, times(1)).setImportantForAccessibility(eq(false));

    AccessibilityNodeInfo mockNodeInfo1 = mock(AccessibilityNodeInfo.class);

    when(spyAccessibilityBridge.obtainAccessibilityNodeInfo(mockRootView, 1))
        .thenReturn(mockNodeInfo1);
    spyAccessibilityBridge.createAccessibilityNodeInfo(1);
    verify(mockNodeInfo1, times(1)).setImportantForAccessibility(eq(false));
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
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    verify(mockRootView, times(1)).setAccessibilityPaneTitle(eq(" "));

    // Synthesize an accessibility hit test event.
    MotionEvent mockEvent = mock(MotionEvent.class);
    when(mockEvent.getX()).thenReturn(10.0f);
    when(mockEvent.getY()).thenReturn(10.0f);
    when(mockEvent.getAction()).thenReturn(MotionEvent.ACTION_HOVER_ENTER);
    boolean hit = accessibilityBridge.onAccessibilityHoverEvent(mockEvent);

    assertTrue(hit);

    ArgumentCaptor<AccessibilityEvent> eventCaptor =
        ArgumentCaptor.forClass(AccessibilityEvent.class);
    verify(mockParent, times(2))
        .requestSendAccessibilityEvent(eq(mockRootView), eventCaptor.capture());
    AccessibilityEvent event = eventCaptor.getAllValues().get(1);
    assertEquals(AccessibilityEvent.TYPE_VIEW_HOVER_ENTER, event.getEventType());
    assertEquals(2, accessibilityBridge.getHoveredObjectId());
  }

  @Test
  public void itFindsPlatformViewsDuringHoverByDefault() {
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
    TestSemanticsNode platformView = new TestSemanticsNode();
    platformView.id = 1;
    platformView.platformViewId = 1;
    platformView.left = 0;
    platformView.top = 0;
    platformView.bottom = 20;
    platformView.right = 20;
    root.addChild(platformView);
    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    // Synthesize an accessibility hit test event.
    MotionEvent mockEvent = mock(MotionEvent.class);
    when(mockEvent.getX()).thenReturn(10.0f);
    when(mockEvent.getY()).thenReturn(10.0f);
    when(mockEvent.getAction()).thenReturn(MotionEvent.ACTION_HOVER_ENTER);

    final boolean handled = accessibilityBridge.onAccessibilityHoverEvent(mockEvent);

    assertTrue(handled);
  }

  @Test
  public void itIgnoresPlatformViewsDuringHoverIfRequested() {
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
    TestSemanticsNode platformView = new TestSemanticsNode();
    platformView.id = 1;
    platformView.platformViewId = 1;
    platformView.left = 0;
    platformView.top = 0;
    platformView.bottom = 20;
    platformView.right = 20;
    root.addChild(platformView);
    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    // Synthesize an accessibility hit test event.
    MotionEvent mockEvent = mock(MotionEvent.class);
    when(mockEvent.getX()).thenReturn(10.0f);
    when(mockEvent.getY()).thenReturn(10.0f);
    when(mockEvent.getAction()).thenReturn(MotionEvent.ACTION_HOVER_ENTER);

    final boolean handled = accessibilityBridge.onAccessibilityHoverEvent(mockEvent, true);

    assertFalse(handled);
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
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    verify(mockRootView, times(1)).setAccessibilityPaneTitle(eq("node2"));

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
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    verify(mockRootView, times(1)).setAccessibilityPaneTitle(eq("new_node2"));
  }

  @Test
  @Config(minSdk = API_LEVELS.FLUTTER_MIN)
  public void itCanPerformSetText() {
    AccessibilityChannel mockChannel = mock(AccessibilityChannel.class);
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            /* rootAccessibilityView= */ mockRootView,
            /* accessibilityChannel= */ mockChannel,
            /* accessibilityManager= */ mockManager,
            /* contentResolver= */ null,
            /* accessibilityViewEmbedder= */ mockViewEmbedder,
            /* platformViewsAccessibilityDelegate= */ null);

    ViewParent mockParent = mock(ViewParent.class);
    when(mockRootView.getParent()).thenReturn(mockParent);
    when(mockManager.isEnabled()).thenReturn(true);

    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;
    TestSemanticsNode node1 = new TestSemanticsNode();
    node1.id = 1;
    node1.addFlag(AccessibilityBridge.Flag.IS_TEXT_FIELD);
    root.children.add(node1);
    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);
    Bundle bundle = new Bundle();
    String expectedText = "some string";
    bundle.putString(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, expectedText);
    accessibilityBridge.performAction(1, AccessibilityNodeInfo.ACTION_SET_TEXT, bundle);
    verify(mockChannel)
        .dispatchSemanticsAction(1, AccessibilityBridge.Action.SET_TEXT, expectedText);
  }

  @Test
  @Config(minSdk = API_LEVELS.FLUTTER_MIN)
  public void itCanPredictSetText() {
    AccessibilityChannel mockChannel = mock(AccessibilityChannel.class);
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            /* rootAccessibilityView= */ mockRootView,
            /* accessibilityChannel= */ mockChannel,
            /* accessibilityManager= */ mockManager,
            /* contentResolver= */ null,
            /* accessibilityViewEmbedder= */ mockViewEmbedder,
            /* platformViewsAccessibilityDelegate= */ null);

    ViewParent mockParent = mock(ViewParent.class);
    when(mockRootView.getParent()).thenReturn(mockParent);
    when(mockManager.isEnabled()).thenReturn(true);

    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;
    TestSemanticsNode node1 = new TestSemanticsNode();
    node1.id = 1;
    node1.addFlag(AccessibilityBridge.Flag.IS_TEXT_FIELD);
    root.children.add(node1);
    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);
    Bundle bundle = new Bundle();
    String expectedText = "some string";
    bundle.putString(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, expectedText);
    accessibilityBridge.performAction(1, AccessibilityNodeInfo.ACTION_SET_TEXT, bundle);
    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(1);
    assertEquals(expectedText, nodeInfo.getText().toString());
  }

  @Test
  @Config(minSdk = API_LEVELS.FLUTTER_MIN)
  public void itBuildsAttributedString() {
    AccessibilityChannel mockChannel = mock(AccessibilityChannel.class);
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            /* rootAccessibilityView= */ mockRootView,
            /* accessibilityChannel= */ mockChannel,
            /* accessibilityManager= */ mockManager,
            /* contentResolver= */ null,
            /* accessibilityViewEmbedder= */ mockViewEmbedder,
            /* platformViewsAccessibilityDelegate= */ null);

    ViewParent mockParent = mock(ViewParent.class);
    when(mockRootView.getParent()).thenReturn(mockParent);
    when(mockManager.isEnabled()).thenReturn(true);

    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;
    root.label = "label";
    TestStringAttribute attribute = new TestStringAttributeSpellOut();
    attribute.start = 1;
    attribute.end = 2;
    attribute.type = TestStringAttributeType.SPELLOUT;
    root.labelAttributes =
        new ArrayList<TestStringAttribute>() {
          {
            add(attribute);
          }
        };
    root.value = "value";
    TestStringAttributeLocale localeAttribute = new TestStringAttributeLocale();
    localeAttribute.start = 1;
    localeAttribute.end = 2;
    localeAttribute.type = TestStringAttributeType.LOCALE;
    localeAttribute.locale = "es-MX";
    root.valueAttributes =
        new ArrayList<TestStringAttribute>() {
          {
            add(localeAttribute);
          }
        };

    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);
    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
    SpannedString actual = (SpannedString) nodeInfo.getContentDescription();
    assertEquals("value, label", actual.toString());
    Object[] objectSpans = actual.getSpans(0, actual.length(), Object.class);
    assertEquals(2, objectSpans.length);
    LocaleSpan localeSpan = (LocaleSpan) objectSpans[0];
    assertEquals("es-MX", localeSpan.getLocale().toLanguageTag());
    assertEquals(1, actual.getSpanStart(localeSpan));
    assertEquals(2, actual.getSpanEnd(localeSpan));
    TtsSpan spellOutSpan = (TtsSpan) objectSpans[1];
    assertEquals(TtsSpan.TYPE_VERBATIM, spellOutSpan.getType());
    assertEquals(8, actual.getSpanStart(spellOutSpan));
    assertEquals(9, actual.getSpanEnd(spellOutSpan));
  }

  @Test
  @Config(minSdk = API_LEVELS.FLUTTER_MIN)
  public void itBuildsAttributedStringWithLocale() {
    AccessibilityChannel mockChannel = mock(AccessibilityChannel.class);
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            /* rootAccessibilityView= */ mockRootView,
            /* accessibilityChannel= */ mockChannel,
            /* accessibilityManager= */ mockManager,
            /* contentResolver= */ null,
            /* accessibilityViewEmbedder= */ mockViewEmbedder,
            /* platformViewsAccessibilityDelegate= */ null);

    ViewParent mockParent = mock(ViewParent.class);
    when(mockRootView.getParent()).thenReturn(mockParent);
    when(mockManager.isEnabled()).thenReturn(true);

    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;
    root.label = "label";
    root.locale = "es-MX";

    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);
    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
    SpannableString actual = (SpannableString) nodeInfo.getContentDescription();
    assertEquals("label", actual.toString());
    Object[] objectSpans = actual.getSpans(0, actual.length(), Object.class);
    assertEquals(1, objectSpans.length);
    LocaleSpan localeSpan = (LocaleSpan) objectSpans[0];
    assertEquals("es-MX", localeSpan.getLocale().toLanguageTag());
    assertEquals(0, actual.getSpanStart(localeSpan));
    assertEquals(actual.getSpanEnd(localeSpan), actual.length());
  }

  @Test
  @Config(minSdk = API_LEVELS.FLUTTER_MIN)
  public void itSetsDefaultLocale() {
    AccessibilityChannel mockChannel = mock(AccessibilityChannel.class);
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            /* rootAccessibilityView= */ mockRootView,
            /* accessibilityChannel= */ mockChannel,
            /* accessibilityManager= */ mockManager,
            /* contentResolver= */ null,
            /* accessibilityViewEmbedder= */ mockViewEmbedder,
            /* platformViewsAccessibilityDelegate= */ null);

    ViewParent mockParent = mock(ViewParent.class);
    when(mockRootView.getParent()).thenReturn(mockParent);
    when(mockManager.isEnabled()).thenReturn(true);

    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;
    root.label = "label";

    accessibilityBridge.setLocale("es-MX");
    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);
    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
    SpannableString actual = (SpannableString) nodeInfo.getContentDescription();
    assertEquals("label", actual.toString());
    Object[] objectSpans = actual.getSpans(0, actual.length(), Object.class);
    assertEquals(1, objectSpans.length);
    LocaleSpan localeSpan = (LocaleSpan) objectSpans[0];
    assertEquals("es-MX", localeSpan.getLocale().toLanguageTag());
    assertEquals(0, actual.getSpanStart(localeSpan));
    assertEquals(actual.getSpanEnd(localeSpan), actual.length());
  }

  @Test
  @Config(minSdk = API_LEVELS.FLUTTER_MIN)
  public void itPrioritizesSectionLocale() {
    AccessibilityChannel mockChannel = mock(AccessibilityChannel.class);
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            /* rootAccessibilityView= */ mockRootView,
            /* accessibilityChannel= */ mockChannel,
            /* accessibilityManager= */ mockManager,
            /* contentResolver= */ null,
            /* accessibilityViewEmbedder= */ mockViewEmbedder,
            /* platformViewsAccessibilityDelegate= */ null);

    ViewParent mockParent = mock(ViewParent.class);
    when(mockRootView.getParent()).thenReturn(mockParent);
    when(mockManager.isEnabled()).thenReturn(true);

    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;
    root.label = "label";
    // Sets both section locale and main locale.
    root.locale = "fr-FR";
    accessibilityBridge.setLocale("es-MX");

    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);
    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
    SpannableString actual = (SpannableString) nodeInfo.getContentDescription();
    assertEquals("label", actual.toString());
    Object[] objectSpans = actual.getSpans(0, actual.length(), Object.class);
    assertEquals(1, objectSpans.length);
    LocaleSpan localeSpan = (LocaleSpan) objectSpans[0];
    // Prioritizes section locale over main locale.
    assertEquals("fr-FR", localeSpan.getLocale().toLanguageTag());
    assertEquals(0, actual.getSpanStart(localeSpan));
    assertEquals(actual.getSpanEnd(localeSpan), actual.length());
  }

  @Test
  @Config(minSdk = API_LEVELS.FLUTTER_MIN)
  public void itSetsTextCorrectly() {
    AccessibilityChannel mockChannel = mock(AccessibilityChannel.class);
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            /* rootAccessibilityView= */ mockRootView,
            /* accessibilityChannel= */ mockChannel,
            /* accessibilityManager= */ mockManager,
            /* contentResolver= */ null,
            /* accessibilityViewEmbedder= */ mockViewEmbedder,
            /* platformViewsAccessibilityDelegate= */ null);

    ViewParent mockParent = mock(ViewParent.class);
    when(mockRootView.getParent()).thenReturn(mockParent);
    when(mockManager.isEnabled()).thenReturn(true);

    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;
    root.value = "value";
    TestStringAttribute attribute = new TestStringAttributeSpellOut();
    attribute.start = 1;
    attribute.end = 2;
    attribute.type = TestStringAttributeType.SPELLOUT;
    root.valueAttributes = new ArrayList<>();
    root.valueAttributes.add(attribute);

    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);
    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
    SpannableString actual = (SpannableString) nodeInfo.getContentDescription();
    assertEquals("value", actual.toString());
    Object[] objectSpans = actual.getSpans(0, actual.length(), Object.class);
    assertEquals(1, objectSpans.length);
    TtsSpan spellOutSpan = (TtsSpan) objectSpans[0];
    assertEquals(TtsSpan.TYPE_VERBATIM, spellOutSpan.getType());
    assertEquals(1, actual.getSpanStart(spellOutSpan));
    assertEquals(2, actual.getSpanEnd(spellOutSpan));

    // Perform a set text action.
    Bundle bundle = new Bundle();
    String expectedText = "a";
    bundle.putString(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, expectedText);
    accessibilityBridge.performAction(0, AccessibilityNodeInfo.ACTION_SET_TEXT, bundle);

    // The action should remove the string attributes.
    nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
    actual = (SpannableString) nodeInfo.getContentDescription();
    assertEquals(expectedText, actual.toString());
    objectSpans = actual.getSpans(0, actual.length(), Object.class);
    assertEquals(0, objectSpans.length);
  }

  @Config(sdk = API_LEVELS.API_28)
  @TargetApi(API_LEVELS.API_28)
  @Test
  public void itSetsTooltipCorrectly() {
    AccessibilityChannel mockChannel = mock(AccessibilityChannel.class);
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            /* rootAccessibilityView= */ mockRootView,
            /* accessibilityChannel= */ mockChannel,
            /* accessibilityManager= */ mockManager,
            /* contentResolver= */ null,
            /* accessibilityViewEmbedder= */ mockViewEmbedder,
            /* platformViewsAccessibilityDelegate= */ null);

    ViewParent mockParent = mock(ViewParent.class);
    when(mockRootView.getParent()).thenReturn(mockParent);
    when(mockManager.isEnabled()).thenReturn(true);
    // Create a node with tooltip.
    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;
    root.tooltip = "tooltip";

    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    // Test the generated AccessibilityNodeInfo for the node we created
    // and verify it has correct tooltip text.
    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
    CharSequence actualTooltipText = nodeInfo.getTooltipText();
    CharSequence actualContentDescription = nodeInfo.getContentDescription();
    assertEquals(actualTooltipText.toString(), root.tooltip);
    assertEquals(actualContentDescription.toString(), root.tooltip);
  }

  @Config(minSdk = API_LEVELS.API_25)
  @Test
  public void itSetsTooltipCorrectlyWithContentDescription() {
    AccessibilityChannel mockChannel = mock(AccessibilityChannel.class);
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            /* rootAccessibilityView= */ mockRootView,
            /* accessibilityChannel= */ mockChannel,
            /* accessibilityManager= */ mockManager,
            /* contentResolver= */ null,
            /* accessibilityViewEmbedder= */ mockViewEmbedder,
            /* platformViewsAccessibilityDelegate= */ null);

    ViewParent mockParent = mock(ViewParent.class);
    when(mockRootView.getParent()).thenReturn(mockParent);
    when(mockManager.isEnabled()).thenReturn(true);
    // Create a node with tooltip.
    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;
    root.tooltip = "tooltip";
    root.label = "desc";

    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    // Test the generated AccessibilityNodeInfo for the node we created
    // and verify it has correct tooltip text.
    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
    CharSequence actualContentDescription = nodeInfo.getContentDescription();

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
      CharSequence actualTooltipText = nodeInfo.getTooltipText();
      assertEquals(actualTooltipText.toString(), root.tooltip);
      assertEquals(actualContentDescription.toString(), root.label);
    } else {
      assertEquals(actualContentDescription.toString(), root.label + "\n" + root.tooltip);
    }
  }

  @TargetApi(API_LEVELS.API_28)
  @Test
  public void itSetsIdentifierCorrectly() {
    AccessibilityChannel mockChannel = mock(AccessibilityChannel.class);
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            /* rootAccessibilityView= */ mockRootView,
            /* accessibilityChannel= */ mockChannel,
            /* accessibilityManager= */ mockManager,
            /* contentResolver= */ null,
            /* accessibilityViewEmbedder= */ mockViewEmbedder,
            /* platformViewsAccessibilityDelegate= */ null);

    ViewParent mockParent = mock(ViewParent.class);
    when(mockRootView.getParent()).thenReturn(mockParent);
    when(mockManager.isEnabled()).thenReturn(true);
    // Create a node with identifier.
    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;
    root.identifier = "identifier";

    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    // Test the generated AccessibilityNodeInfo for the node we created and
    // verify it has correct identifier (i.e. resource-id per Android
    // terminology).
    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
    CharSequence actual = nodeInfo.getViewIdResourceName();
    assertEquals(actual.toString(), root.identifier);
  }

  @Test
  @Config(minSdk = API_LEVELS.FLUTTER_MIN)
  public void itCanCreateAccessibilityNodeInfoWithSetText() {
    AccessibilityChannel mockChannel = mock(AccessibilityChannel.class);
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            /* rootAccessibilityView= */ mockRootView,
            /* accessibilityChannel= */ mockChannel,
            /* accessibilityManager= */ mockManager,
            /* contentResolver= */ null,
            /* accessibilityViewEmbedder= */ mockViewEmbedder,
            /* platformViewsAccessibilityDelegate= */ null);

    ViewParent mockParent = mock(ViewParent.class);
    when(mockRootView.getParent()).thenReturn(mockParent);
    when(mockManager.isEnabled()).thenReturn(true);

    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;
    TestSemanticsNode node1 = new TestSemanticsNode();
    node1.id = 1;
    node1.addFlag(AccessibilityBridge.Flag.IS_TEXT_FIELD);
    node1.addAction(AccessibilityBridge.Action.SET_TEXT);
    root.children.add(node1);
    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);
    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(1);
    List<AccessibilityNodeInfo.AccessibilityAction> actions = nodeInfo.getActionList();
    assertTrue(actions.contains(AccessibilityNodeInfo.AccessibilityAction.ACTION_SET_TEXT));
  }

  @Test
  public void itCanPredictSetSelection() {
    AccessibilityChannel mockChannel = mock(AccessibilityChannel.class);
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            /* rootAccessibilityView= */ mockRootView,
            /* accessibilityChannel= */ mockChannel,
            /* accessibilityManager= */ mockManager,
            /* contentResolver= */ null,
            /* accessibilityViewEmbedder= */ mockViewEmbedder,
            /* platformViewsAccessibilityDelegate= */ null);

    ViewParent mockParent = mock(ViewParent.class);
    when(mockRootView.getParent()).thenReturn(mockParent);
    when(mockManager.isEnabled()).thenReturn(true);

    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;
    TestSemanticsNode node1 = new TestSemanticsNode();
    node1.id = 1;
    node1.value = "some text";
    node1.textSelectionBase = -1;
    node1.textSelectionExtent = -1;
    node1.addFlag(AccessibilityBridge.Flag.IS_TEXT_FIELD);
    root.children.add(node1);
    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);
    Bundle bundle = new Bundle();
    int expectedStart = 1;
    int expectedEnd = 3;
    bundle.putInt(AccessibilityNodeInfo.ACTION_ARGUMENT_SELECTION_START_INT, expectedStart);
    bundle.putInt(AccessibilityNodeInfo.ACTION_ARGUMENT_SELECTION_END_INT, expectedEnd);
    accessibilityBridge.performAction(1, AccessibilityNodeInfo.ACTION_SET_SELECTION, bundle);
    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(1);
    assertEquals(expectedStart, nodeInfo.getTextSelectionStart());
    assertEquals(expectedEnd, nodeInfo.getTextSelectionEnd());
  }

  @Test
  public void itPerformsClearAccessibilityFocusCorrectly() {
    BasicMessageChannel mockChannel = mock(BasicMessageChannel.class);
    AccessibilityChannel accessibilityChannel =
        new AccessibilityChannel(mockChannel, mock(FlutterJNI.class));
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            /* rootAccessibilityView= */ mockRootView,
            /* accessibilityChannel= */ accessibilityChannel,
            /* accessibilityManager= */ mockManager,
            /* contentResolver= */ null,
            /* accessibilityViewEmbedder= */ mockViewEmbedder,
            /* platformViewsAccessibilityDelegate= */ null);

    ViewParent mockParent = mock(ViewParent.class);
    when(mockRootView.getParent()).thenReturn(mockParent);
    when(mockManager.isEnabled()).thenReturn(true);

    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;
    root.label = "root";
    TestSemanticsNode node1 = new TestSemanticsNode();
    node1.id = 1;
    node1.value = "some text";
    root.children.add(node1);

    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);
    accessibilityBridge.performAction(0, AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS, null);
    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
    assertTrue(nodeInfo.isAccessibilityFocused());

    HashMap<String, Object> message = new HashMap<>();
    message.put("type", "didGainFocus");
    message.put("nodeId", 0);
    verify(mockChannel).send(message);
    // Clear focus on non-focused node shouldn't do anything
    accessibilityBridge.performAction(
        1, AccessibilityNodeInfo.ACTION_CLEAR_ACCESSIBILITY_FOCUS, null);
    nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
    assertTrue(nodeInfo.isAccessibilityFocused());

    // Now, clear the focus for real.
    accessibilityBridge.performAction(
        0, AccessibilityNodeInfo.ACTION_CLEAR_ACCESSIBILITY_FOCUS, null);
    nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
    assertFalse(nodeInfo.isAccessibilityFocused());
  }

  @Test
  public void itSetsFocusabilityBasedOnFlagsCorrectly() {
    AccessibilityChannel mockChannel = mock(AccessibilityChannel.class);
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            /* rootAccessibilityView= */ mockRootView,
            /* accessibilityChannel= */ mockChannel,
            /* accessibilityManager= */ mockManager,
            /* contentResolver= */ null,
            /* accessibilityViewEmbedder= */ mockViewEmbedder,
            /* platformViewsAccessibilityDelegate= */ null);

    ViewParent mockParent = mock(ViewParent.class);
    when(mockRootView.getParent()).thenReturn(mockParent);
    when(mockManager.isEnabled()).thenReturn(true);

    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;
    root.addFlag(Flag.HAS_IMPLICIT_SCROLLING);
    TestSemanticsNode node1 = new TestSemanticsNode();
    node1.id = 1;
    node1.addFlag(Flag.IS_READ_ONLY);
    root.children.add(node1);
    TestSemanticsNode node2 = new TestSemanticsNode();
    node2.id = 2;
    node2.addFlag(Flag.HAS_CHECKED_STATE);
    root.children.add(node2);
    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    // Only node 2 is focusable because it has a flag that is not in
    // AccessibilityBridge.TRIVIAL_FLAGS.
    AccessibilityNodeInfo rootInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
    assertFalse(rootInfo.isFocusable());
    AccessibilityNodeInfo node1Info = accessibilityBridge.createAccessibilityNodeInfo(1);
    assertFalse(node1Info.isFocusable());
    AccessibilityNodeInfo node2Info = accessibilityBridge.createAccessibilityNodeInfo(2);
    assertTrue(node2Info.isFocusable());
  }

  @Config(sdk = API_LEVELS.API_31)
  @TargetApi(API_LEVELS.API_31)
  @Test
  public void itSetsBoldTextFlagCorrectly() {
    AccessibilityChannel mockChannel = mock(AccessibilityChannel.class);
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    Resources resource = mock(Resources.class);
    Configuration config = new Configuration();
    config.fontWeightAdjustment = 300;

    when(mockRootView.getContext()).thenReturn(context);
    when(mockRootView.getResources()).thenReturn(resource);
    when(resource.getConfiguration()).thenReturn(config);

    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            /* rootAccessibilityView= */ mockRootView,
            /* accessibilityChannel= */ mockChannel,
            /* accessibilityManager= */ mockManager,
            /* contentResolver= */ null,
            /* accessibilityViewEmbedder= */ mockViewEmbedder,
            /* platformViewsAccessibilityDelegate= */ null);

    verify(mockChannel)
        .setAccessibilityFeatures(
            ACCESSIBILITY_FEATURE_BOLD_TEXT | ACCESSIBILITY_FEATURE_NO_ANNOUNCE);
    reset(mockChannel);

    // Now verify that clearing the BOLD_TEXT flag doesn't touch any of the other
    // flags.
    // Ensure the DISABLE_ANIMATION flag will be set
    Settings.Global.putFloat(null, "transition_animation_scale", 0.0f);
    // Ensure the BOLD_TEXT flag will be cleared
    config.fontWeightAdjustment = 0;

    accessibilityBridge =
        setUpBridge(
            /* rootAccessibilityView= */ mockRootView,
            /* accessibilityChannel= */ mockChannel,
            /* accessibilityManager= */ mockManager,
            /* contentResolver= */ null,
            /* accessibilityViewEmbedder= */ mockViewEmbedder,
            /* platformViewsAccessibilityDelegate= */ null);

    // setAccessibilityFeatures() will be called multiple times from
    // AccessibilityBridge's
    // constructor, verify that the latest argument is correct
    ArgumentCaptor<Integer> captor = ArgumentCaptor.forClass(Integer.class);
    verify(mockChannel, atLeastOnce()).setAccessibilityFeatures(captor.capture());
    assertEquals(
        ACCESSIBILITY_FEATURE_DISABLE_ANIMATIONS | ACCESSIBILITY_FEATURE_NO_ANNOUNCE,
        captor.getValue().intValue());

    // Set back to default
    Settings.Global.putFloat(null, "transition_animation_scale", 1.0f);
  }

  @Test
  public void itSetsFocusedNodeBeforeSendingEvent() {
    BasicMessageChannel mockChannel = mock(BasicMessageChannel.class);
    AccessibilityChannel accessibilityChannel =
        new AccessibilityChannel(mockChannel, mock(FlutterJNI.class));

    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            /* rootAccessibilityView= */ mockRootView,
            /* accessibilityChannel= */ accessibilityChannel,
            /* accessibilityManager= */ mockManager,
            /* contentResolver= */ null,
            /* accessibilityViewEmbedder= */ mockViewEmbedder,
            /* platformViewsAccessibilityDelegate= */ null);

    ViewParent mockParent = mock(ViewParent.class);
    when(mockRootView.getParent()).thenReturn(mockParent);
    when(mockManager.isEnabled()).thenReturn(true);

    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;
    root.label = "root";

    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    class Verifier {
      public Verifier(AccessibilityBridge accessibilityBridge) {
        this.accessibilityBridge = accessibilityBridge;
      }

      public final AccessibilityBridge accessibilityBridge;
      public boolean verified = false;

      public boolean verify(InvocationOnMock invocation) {
        AccessibilityEvent event = (AccessibilityEvent) invocation.getArguments()[1];
        assertEquals(AccessibilityEvent.TYPE_VIEW_ACCESSIBILITY_FOCUSED, event.getEventType());
        // The accessibility focus must be set before sending out
        // the TYPE_VIEW_ACCESSIBILITY_FOCUSED event.
        AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
        assertTrue(nodeInfo.isAccessibilityFocused());
        verified = true;
        return true;
      }
    }
    Verifier verifier = new Verifier(accessibilityBridge);
    when(mockParent.requestSendAccessibilityEvent(eq(mockRootView), any(AccessibilityEvent.class)))
        .thenAnswer(verifier::verify);
    accessibilityBridge.performAction(0, AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS, null);
    assertTrue(verifier.verified);

    HashMap<String, Object> message = new HashMap<>();
    message.put("type", "didGainFocus");
    message.put("nodeId", 0);
    verify(mockChannel).send(message);
  }

  @Test
  public void itClearsFocusedNodeBeforeSendingEvent() {
    BasicMessageChannel mockChannel = mock(BasicMessageChannel.class);
    AccessibilityChannel accessibilityChannel =
        new AccessibilityChannel(mockChannel, mock(FlutterJNI.class));
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            /* rootAccessibilityView= */ mockRootView,
            /* accessibilityChannel= */ accessibilityChannel,
            /* accessibilityManager= */ mockManager,
            /* contentResolver= */ null,
            /* accessibilityViewEmbedder= */ mockViewEmbedder,
            /* platformViewsAccessibilityDelegate= */ null);

    ViewParent mockParent = mock(ViewParent.class);
    when(mockRootView.getParent()).thenReturn(mockParent);
    when(mockManager.isEnabled()).thenReturn(true);

    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;
    root.label = "root";

    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);
    // Set the focus on root.
    accessibilityBridge.performAction(0, AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS, null);
    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
    assertTrue(nodeInfo.isAccessibilityFocused());
    HashMap<String, Object> message = new HashMap<>();
    message.put("type", "didGainFocus");
    message.put("nodeId", 0);
    verify(mockChannel).send(message);

    class Verifier {
      public Verifier(AccessibilityBridge accessibilityBridge) {
        this.accessibilityBridge = accessibilityBridge;
      }

      public final AccessibilityBridge accessibilityBridge;
      public boolean verified = false;

      public boolean verify(InvocationOnMock invocation) {
        AccessibilityEvent event = (AccessibilityEvent) invocation.getArguments()[1];
        assertEquals(
            AccessibilityEvent.TYPE_VIEW_ACCESSIBILITY_FOCUS_CLEARED, event.getEventType());
        // The accessibility focus must be cleared before sending out
        // the TYPE_VIEW_ACCESSIBILITY_FOCUS_CLEARED event.
        AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
        assertFalse(nodeInfo.isAccessibilityFocused());
        verified = true;
        return true;
      }
    }
    Verifier verifier = new Verifier(accessibilityBridge);
    when(mockParent.requestSendAccessibilityEvent(eq(mockRootView), any(AccessibilityEvent.class)))
        .thenAnswer(verifier::verify);
    accessibilityBridge.performAction(
        0, AccessibilityNodeInfo.ACTION_CLEAR_ACCESSIBILITY_FOCUS, null);
    assertTrue(verifier.verified);
  }

  @Test
  public void itCanPredictCursorMovementsWithGranularityWord() {
    AccessibilityChannel mockChannel = mock(AccessibilityChannel.class);
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            /* rootAccessibilityView= */ mockRootView,
            /* accessibilityChannel= */ mockChannel,
            /* accessibilityManager= */ mockManager,
            /* contentResolver= */ null,
            /* accessibilityViewEmbedder= */ mockViewEmbedder,
            /* platformViewsAccessibilityDelegate= */ null);

    ViewParent mockParent = mock(ViewParent.class);
    when(mockRootView.getParent()).thenReturn(mockParent);
    when(mockManager.isEnabled()).thenReturn(true);

    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;
    TestSemanticsNode node1 = new TestSemanticsNode();
    node1.id = 1;
    node1.value = "some text";
    node1.textSelectionBase = 0;
    node1.textSelectionExtent = 0;
    node1.addFlag(AccessibilityBridge.Flag.IS_TEXT_FIELD);
    root.children.add(node1);
    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);
    Bundle bundle = new Bundle();
    bundle.putInt(
        AccessibilityNodeInfo.ACTION_ARGUMENT_MOVEMENT_GRANULARITY_INT,
        AccessibilityNodeInfo.MOVEMENT_GRANULARITY_WORD);
    bundle.putBoolean(AccessibilityNodeInfo.ACTION_ARGUMENT_EXTEND_SELECTION_BOOLEAN, false);
    accessibilityBridge.performAction(
        1, AccessibilityNodeInfo.ACTION_NEXT_AT_MOVEMENT_GRANULARITY, bundle);
    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(1);
    // The selection should be at the end of 'text'
    assertEquals(9, nodeInfo.getTextSelectionStart());
    assertEquals(9, nodeInfo.getTextSelectionEnd());

    bundle = new Bundle();
    bundle.putInt(
        AccessibilityNodeInfo.ACTION_ARGUMENT_MOVEMENT_GRANULARITY_INT,
        AccessibilityNodeInfo.MOVEMENT_GRANULARITY_WORD);
    bundle.putBoolean(AccessibilityNodeInfo.ACTION_ARGUMENT_EXTEND_SELECTION_BOOLEAN, false);
    accessibilityBridge.performAction(
        1, AccessibilityNodeInfo.ACTION_PREVIOUS_AT_MOVEMENT_GRANULARITY, bundle);
    nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(1);
    // The selection should be go to beginning of 'text'.
    assertEquals(5, nodeInfo.getTextSelectionStart());
    assertEquals(5, nodeInfo.getTextSelectionEnd());
  }

  @Test
  public void itAlsoFireSelectionEventWhenPredictCursorMovements() {
    AccessibilityChannel mockChannel = mock(AccessibilityChannel.class);
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            /* rootAccessibilityView= */ mockRootView,
            /* accessibilityChannel= */ mockChannel,
            /* accessibilityManager= */ mockManager,
            /* contentResolver= */ null,
            /* accessibilityViewEmbedder= */ mockViewEmbedder,
            /* platformViewsAccessibilityDelegate= */ null);

    ViewParent mockParent = mock(ViewParent.class);
    when(mockRootView.getParent()).thenReturn(mockParent);
    when(mockManager.isEnabled()).thenReturn(true);

    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;
    TestSemanticsNode node1 = new TestSemanticsNode();
    node1.id = 1;
    node1.value = "some text";
    node1.textSelectionBase = 0;
    node1.textSelectionExtent = 0;
    node1.addFlag(AccessibilityBridge.Flag.IS_TEXT_FIELD);
    root.children.add(node1);
    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);
    Bundle bundle = new Bundle();
    bundle.putInt(
        AccessibilityNodeInfo.ACTION_ARGUMENT_MOVEMENT_GRANULARITY_INT,
        AccessibilityNodeInfo.MOVEMENT_GRANULARITY_CHARACTER);
    bundle.putBoolean(AccessibilityNodeInfo.ACTION_ARGUMENT_EXTEND_SELECTION_BOOLEAN, false);
    accessibilityBridge.performAction(
        1, AccessibilityNodeInfo.ACTION_NEXT_AT_MOVEMENT_GRANULARITY, bundle);
    ArgumentCaptor<AccessibilityEvent> eventCaptor =
        ArgumentCaptor.forClass(AccessibilityEvent.class);
    verify(mockParent, times(2))
        .requestSendAccessibilityEvent(eq(mockRootView), eventCaptor.capture());
    AccessibilityEvent event = eventCaptor.getAllValues().get(1);
    assertEquals(AccessibilityEvent.TYPE_VIEW_TEXT_SELECTION_CHANGED, event.getEventType());
    assertEquals(event.getText().toString(), "[" + node1.value + "]");
    assertEquals(1, event.getFromIndex());
    assertEquals(1, event.getToIndex());
    assertEquals(event.getItemCount(), node1.value.length());
  }

  @Test
  public void itDoesNotFireSelectionEventWhenPredictCursorMovementsDoesNotChangeSelection() {
    AccessibilityChannel mockChannel = mock(AccessibilityChannel.class);
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            /* rootAccessibilityView= */ mockRootView,
            /* accessibilityChannel= */ mockChannel,
            /* accessibilityManager= */ mockManager,
            /* contentResolver= */ null,
            /* accessibilityViewEmbedder= */ mockViewEmbedder,
            /* platformViewsAccessibilityDelegate= */ null);

    ViewParent mockParent = mock(ViewParent.class);
    when(mockRootView.getParent()).thenReturn(mockParent);
    when(mockManager.isEnabled()).thenReturn(true);

    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;
    TestSemanticsNode node1 = new TestSemanticsNode();
    node1.id = 1;
    node1.value = "some text";
    node1.textSelectionBase = 0;
    node1.textSelectionExtent = 0;
    node1.addFlag(AccessibilityBridge.Flag.IS_TEXT_FIELD);
    root.children.add(node1);
    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);
    Bundle bundle = new Bundle();
    bundle.putInt(
        AccessibilityNodeInfo.ACTION_ARGUMENT_MOVEMENT_GRANULARITY_INT,
        AccessibilityNodeInfo.MOVEMENT_GRANULARITY_CHARACTER);
    bundle.putBoolean(AccessibilityNodeInfo.ACTION_ARGUMENT_EXTEND_SELECTION_BOOLEAN, false);
    accessibilityBridge.performAction(
        1, AccessibilityNodeInfo.ACTION_PREVIOUS_AT_MOVEMENT_GRANULARITY, bundle);
    ArgumentCaptor<AccessibilityEvent> eventCaptor =
        ArgumentCaptor.forClass(AccessibilityEvent.class);
    verify(mockParent, times(1))
        .requestSendAccessibilityEvent(eq(mockRootView), eventCaptor.capture());
    assertEquals(1, eventCaptor.getAllValues().size());
    AccessibilityEvent event = eventCaptor.getAllValues().get(0);
    assertNotEquals(AccessibilityEvent.TYPE_VIEW_TEXT_SELECTION_CHANGED, event.getEventType());
  }

  @Ignore(
      "Fails on JDK 19+ due to https://github.com/flutter/flutter/issues/175623. Not an actual bug on device; test-specific only.")
  @Test
  public void itCanPredictCursorMovementsWithGranularityWordUnicode() {
    AccessibilityChannel mockChannel = mock(AccessibilityChannel.class);
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            /* rootAccessibilityView= */ mockRootView,
            /* accessibilityChannel= */ mockChannel,
            /* accessibilityManager= */ mockManager,
            /* contentResolver= */ null,
            /* accessibilityViewEmbedder= */ mockViewEmbedder,
            /* platformViewsAccessibilityDelegate= */ null);

    ViewParent mockParent = mock(ViewParent.class);
    when(mockRootView.getParent()).thenReturn(mockParent);
    when(mockManager.isEnabled()).thenReturn(true);

    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;
    TestSemanticsNode node1 = new TestSemanticsNode();
    node1.id = 1;
    node1.value = "你 好 嗎";
    node1.textSelectionBase = 0;
    node1.textSelectionExtent = 0;
    node1.addFlag(AccessibilityBridge.Flag.IS_TEXT_FIELD);
    root.children.add(node1);
    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);
    Bundle bundle = new Bundle();
    bundle.putInt(
        AccessibilityNodeInfo.ACTION_ARGUMENT_MOVEMENT_GRANULARITY_INT,
        AccessibilityNodeInfo.MOVEMENT_GRANULARITY_WORD);
    bundle.putBoolean(AccessibilityNodeInfo.ACTION_ARGUMENT_EXTEND_SELECTION_BOOLEAN, false);
    accessibilityBridge.performAction(
        1, AccessibilityNodeInfo.ACTION_NEXT_AT_MOVEMENT_GRANULARITY, bundle);
    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(1);
    // The selection should be at the end of '好'
    assertEquals(3, nodeInfo.getTextSelectionStart());
    assertEquals(3, nodeInfo.getTextSelectionEnd());

    bundle = new Bundle();
    bundle.putInt(
        AccessibilityNodeInfo.ACTION_ARGUMENT_MOVEMENT_GRANULARITY_INT,
        AccessibilityNodeInfo.MOVEMENT_GRANULARITY_WORD);
    bundle.putBoolean(AccessibilityNodeInfo.ACTION_ARGUMENT_EXTEND_SELECTION_BOOLEAN, false);
    accessibilityBridge.performAction(
        1, AccessibilityNodeInfo.ACTION_PREVIOUS_AT_MOVEMENT_GRANULARITY, bundle);
    nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(1);
    // The selection should be go to beginning of '好'.
    assertEquals(2, nodeInfo.getTextSelectionStart());
    assertEquals(2, nodeInfo.getTextSelectionEnd());
  }

  @Test
  public void itCanPredictCursorMovementsWithGranularityLine() {
    AccessibilityChannel mockChannel = mock(AccessibilityChannel.class);
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            /* rootAccessibilityView= */ mockRootView,
            /* accessibilityChannel= */ mockChannel,
            /* accessibilityManager= */ mockManager,
            /* contentResolver= */ null,
            /* accessibilityViewEmbedder= */ mockViewEmbedder,
            /* platformViewsAccessibilityDelegate= */ null);

    ViewParent mockParent = mock(ViewParent.class);
    when(mockRootView.getParent()).thenReturn(mockParent);
    when(mockManager.isEnabled()).thenReturn(true);

    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;
    TestSemanticsNode node1 = new TestSemanticsNode();
    node1.id = 1;
    node1.value = "How are you\nI am fine\nThank you";
    // Selection is at the second line.
    node1.textSelectionBase = 14;
    node1.textSelectionExtent = 14;
    node1.addFlag(AccessibilityBridge.Flag.IS_TEXT_FIELD);
    root.children.add(node1);
    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);
    Bundle bundle = new Bundle();
    bundle.putInt(
        AccessibilityNodeInfo.ACTION_ARGUMENT_MOVEMENT_GRANULARITY_INT,
        AccessibilityNodeInfo.MOVEMENT_GRANULARITY_LINE);
    bundle.putBoolean(AccessibilityNodeInfo.ACTION_ARGUMENT_EXTEND_SELECTION_BOOLEAN, false);
    accessibilityBridge.performAction(
        1, AccessibilityNodeInfo.ACTION_NEXT_AT_MOVEMENT_GRANULARITY, bundle);
    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(1);
    // The selection should be at the beginning of the third line.
    assertEquals(21, nodeInfo.getTextSelectionStart());
    assertEquals(21, nodeInfo.getTextSelectionEnd());

    bundle = new Bundle();
    bundle.putInt(
        AccessibilityNodeInfo.ACTION_ARGUMENT_MOVEMENT_GRANULARITY_INT,
        AccessibilityNodeInfo.MOVEMENT_GRANULARITY_LINE);
    bundle.putBoolean(AccessibilityNodeInfo.ACTION_ARGUMENT_EXTEND_SELECTION_BOOLEAN, false);
    accessibilityBridge.performAction(
        1, AccessibilityNodeInfo.ACTION_PREVIOUS_AT_MOVEMENT_GRANULARITY, bundle);
    nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(1);
    // The selection should be at the beginning of the second line.
    assertEquals(11, nodeInfo.getTextSelectionStart());
    assertEquals(11, nodeInfo.getTextSelectionEnd());
  }

  @Test
  public void itCanPredictCursorMovementsWithGranularityCharacter() {
    AccessibilityChannel mockChannel = mock(AccessibilityChannel.class);
    AccessibilityViewEmbedder mockViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            /* rootAccessibilityView= */ mockRootView,
            /* accessibilityChannel= */ mockChannel,
            /* accessibilityManager= */ mockManager,
            /* contentResolver= */ null,
            /* accessibilityViewEmbedder= */ mockViewEmbedder,
            /* platformViewsAccessibilityDelegate= */ null);

    ViewParent mockParent = mock(ViewParent.class);
    when(mockRootView.getParent()).thenReturn(mockParent);
    when(mockManager.isEnabled()).thenReturn(true);

    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;
    TestSemanticsNode node1 = new TestSemanticsNode();
    node1.id = 1;
    node1.value = "some text";
    node1.textSelectionBase = 0;
    node1.textSelectionExtent = 0;
    node1.addFlag(AccessibilityBridge.Flag.IS_TEXT_FIELD);
    root.children.add(node1);
    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);
    Bundle bundle = new Bundle();
    bundle.putInt(
        AccessibilityNodeInfo.ACTION_ARGUMENT_MOVEMENT_GRANULARITY_INT,
        AccessibilityNodeInfo.MOVEMENT_GRANULARITY_CHARACTER);
    bundle.putBoolean(AccessibilityNodeInfo.ACTION_ARGUMENT_EXTEND_SELECTION_BOOLEAN, false);
    accessibilityBridge.performAction(
        1, AccessibilityNodeInfo.ACTION_NEXT_AT_MOVEMENT_GRANULARITY, bundle);
    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(1);
    assertEquals(1, nodeInfo.getTextSelectionStart());
    assertEquals(1, nodeInfo.getTextSelectionEnd());

    bundle = new Bundle();
    bundle.putInt(
        AccessibilityNodeInfo.ACTION_ARGUMENT_MOVEMENT_GRANULARITY_INT,
        AccessibilityNodeInfo.MOVEMENT_GRANULARITY_CHARACTER);
    bundle.putBoolean(AccessibilityNodeInfo.ACTION_ARGUMENT_EXTEND_SELECTION_BOOLEAN, false);
    accessibilityBridge.performAction(
        1, AccessibilityNodeInfo.ACTION_PREVIOUS_AT_MOVEMENT_GRANULARITY, bundle);
    nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(1);
    assertEquals(0, nodeInfo.getTextSelectionStart());
    assertEquals(0, nodeInfo.getTextSelectionEnd());
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
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    verify(mockRootView, times(1)).setAccessibilityPaneTitle(eq(" "));
  }

  @Test
  public void itHoverOverOutOfBoundsDoesNotCrash() {
    // SemanticsNode.hitTest() returns null when out of bounds.
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
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    // Pass an out of bounds MotionEvent.
    accessibilityBridge.onAccessibilityHoverEvent(MotionEvent.obtain(1, 1, 1, -10, -10, 0));
  }

  @Test
  public void itProducesPlatformViewNodeForHybridComposition() {
    PlatformViewsAccessibilityDelegate accessibilityDelegate =
        mock(PlatformViewsAccessibilityDelegate.class);

    Context context = ApplicationProvider.getApplicationContext();
    View rootAccessibilityView = new View(context);
    AccessibilityViewEmbedder accessibilityViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            rootAccessibilityView,
            /* accessibilityChannel= */ null,
            /* accessibilityManager= */ null,
            /* contentResolver= */ null,
            accessibilityViewEmbedder,
            accessibilityDelegate);

    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;

    TestSemanticsNode platformView = new TestSemanticsNode();
    platformView.id = 1;
    platformView.platformViewId = 1;
    root.addChild(platformView);

    TestSemanticsUpdate testSemanticsRootUpdate = root.toUpdate();
    testSemanticsRootUpdate.sendUpdateToBridge(accessibilityBridge);

    TestSemanticsUpdate testSemanticsPlatformViewUpdate = platformView.toUpdate();
    testSemanticsPlatformViewUpdate.sendUpdateToBridge(accessibilityBridge);

    View embeddedView = mock(View.class);
    when(accessibilityDelegate.getPlatformViewById(1)).thenReturn(embeddedView);
    when(accessibilityDelegate.usesVirtualDisplay(1)).thenReturn(false);

    AccessibilityNodeInfo nodeInfo = mock(AccessibilityNodeInfo.class);
    when(embeddedView.createAccessibilityNodeInfo()).thenReturn(nodeInfo);

    AccessibilityNodeInfo result = accessibilityBridge.createAccessibilityNodeInfo(0);
    assertNotNull(result);
    assertEquals(1, result.getChildCount());
    verify(embeddedView).setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_AUTO);
    assertEquals("android.view.View", result.getClassName());
  }

  @Test
  public void itMakesPlatformViewImportantForAccessibility() {
    PlatformViewsAccessibilityDelegate accessibilityDelegate =
        mock(PlatformViewsAccessibilityDelegate.class);

    Context context = ApplicationProvider.getApplicationContext();
    View rootAccessibilityView = new View(context);
    AccessibilityViewEmbedder accessibilityViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            rootAccessibilityView,
            /* accessibilityChannel= */ null,
            /* accessibilityManager= */ null,
            /* contentResolver= */ null,
            accessibilityViewEmbedder,
            accessibilityDelegate);

    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;

    TestSemanticsNode platformView = new TestSemanticsNode();
    platformView.id = 1;
    platformView.platformViewId = 1;
    root.addChild(platformView);

    View embeddedView = mock(View.class);
    when(accessibilityDelegate.getPlatformViewById(1)).thenReturn(embeddedView);
    when(accessibilityDelegate.usesVirtualDisplay(1)).thenReturn(false);

    TestSemanticsUpdate testSemanticsRootUpdate = root.toUpdate();
    testSemanticsRootUpdate.sendUpdateToBridge(accessibilityBridge);

    verify(embeddedView).setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_AUTO);
  }

  @Test
  public void itMakesPlatformViewNoImportantForAccessibility() {
    PlatformViewsAccessibilityDelegate accessibilityDelegate =
        mock(PlatformViewsAccessibilityDelegate.class);

    Context context = ApplicationProvider.getApplicationContext();
    View rootAccessibilityView = new View(context);
    AccessibilityViewEmbedder accessibilityViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            rootAccessibilityView,
            /* accessibilityChannel= */ null,
            /* accessibilityManager= */ null,
            /* contentResolver= */ null,
            accessibilityViewEmbedder,
            accessibilityDelegate);

    TestSemanticsNode rootWithPlatformView = new TestSemanticsNode();
    rootWithPlatformView.id = 0;

    TestSemanticsNode platformView = new TestSemanticsNode();
    platformView.id = 1;
    platformView.platformViewId = 1;
    rootWithPlatformView.addChild(platformView);

    View embeddedView = mock(View.class);
    when(accessibilityDelegate.getPlatformViewById(1)).thenReturn(embeddedView);
    when(accessibilityDelegate.usesVirtualDisplay(1)).thenReturn(false);

    TestSemanticsUpdate testSemanticsRootWithPlatformViewUpdate = rootWithPlatformView.toUpdate();
    testSemanticsRootWithPlatformViewUpdate.sendUpdateToBridge(accessibilityBridge);

    TestSemanticsNode rootWithoutPlatformView = new TestSemanticsNode();
    rootWithoutPlatformView.id = 0;
    TestSemanticsUpdate testSemanticsRootWithoutPlatformViewUpdate =
        rootWithoutPlatformView.toUpdate();
    testSemanticsRootWithoutPlatformViewUpdate.sendUpdateToBridge(accessibilityBridge);

    verify(embeddedView)
        .setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS);
  }

  @Test
  public void itProducesPlatformViewNodeForVirtualDisplay() {
    PlatformViewsAccessibilityDelegate accessibilityDelegate =
        mock(PlatformViewsAccessibilityDelegate.class);
    AccessibilityViewEmbedder accessibilityViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            /* rootAccessibilityView= */ null,
            /* accessibilityChannel= */ null,
            /* accessibilityManager= */ null,
            /* contentResolver= */ null,
            accessibilityViewEmbedder,
            accessibilityDelegate);

    TestSemanticsNode platformView = new TestSemanticsNode();
    platformView.platformViewId = 1;

    TestSemanticsUpdate testSemanticsUpdate = platformView.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    View embeddedView = mock(View.class);
    when(accessibilityDelegate.getPlatformViewById(1)).thenReturn(embeddedView);
    when(accessibilityDelegate.usesVirtualDisplay(1)).thenReturn(true);

    accessibilityBridge.createAccessibilityNodeInfo(0);
    verify(accessibilityViewEmbedder).getRootNode(eq(embeddedView), eq(0), any(Rect.class));
  }

  @Test
  public void itDoesNotCrashWhenEmbeddedViewIsNull() {
    PlatformViewsAccessibilityDelegate accessibilityDelegate =
        mock(PlatformViewsAccessibilityDelegate.class);
    AccessibilityViewEmbedder accessibilityViewEmbedder = mock(AccessibilityViewEmbedder.class);
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            /* rootAccessibilityView= */ null,
            /* accessibilityChannel= */ null,
            /* accessibilityManager= */ null,
            /* contentResolver= */ null,
            accessibilityViewEmbedder,
            accessibilityDelegate);

    TestSemanticsNode root = new TestSemanticsNode();
    root.id = 0;

    TestSemanticsNode platformView = new TestSemanticsNode();
    platformView.id = 1;
    platformView.platformViewId = 1;
    root.addChild(platformView);

    when(accessibilityDelegate.usesVirtualDisplay(1)).thenReturn(false);
    when(accessibilityDelegate.getPlatformViewById(1)).thenReturn(null);

    TestSemanticsUpdate testSemanticsUpdate = root.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    // This should not crash.
    AccessibilityNodeInfo result = accessibilityBridge.createAccessibilityNodeInfo(0);

    // Verify that we fell back to adding the child as a virtual node (standard semantics node)
    // instead of trying to add the null embedded view.
    boolean hasChild = false;
    for (int i = 0; i < result.getChildCount(); i++) {
      hasChild = true;
    }
    assertTrue("Should have added the virtual child node", hasChild);
  }

  @Test
  public void testItSetsDisableAnimationsFlagBasedOnTransitionAnimationScale() {
    AccessibilityChannel mockChannel = mock(AccessibilityChannel.class);
    ContentResolver mockContentResolver = mock(ContentResolver.class);

    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            /* rootAccessibilityView= */ null,
            /* accessibilityChannel= */ mockChannel,
            /* accessibilityManager= */ null,
            /* contentResolver= */ mockContentResolver,
            /* accessibilityViewEmbedder= */ null,
            /* platformViewsAccessibilityDelegate= */ null);

    // Capture the observer registered for
    // Settings.Global.TRANSITION_ANIMATION_SCALE
    ArgumentCaptor<ContentObserver> observerCaptor = ArgumentCaptor.forClass(ContentObserver.class);
    verify(mockContentResolver)
        .registerContentObserver(
            eq(Settings.Global.getUriFor(Settings.Global.TRANSITION_ANIMATION_SCALE)),
            eq(false),
            observerCaptor.capture());
    ContentObserver observer = observerCaptor.getValue();

    // Initial state
    verify(mockChannel).setAccessibilityFeatures(ACCESSIBILITY_FEATURE_NO_ANNOUNCE);
    reset(mockChannel);

    // Animations are disabled
    Settings.Global.putFloat(mockContentResolver, "transition_animation_scale", 0.0f);
    observer.onChange(false);
    verify(mockChannel)
        .setAccessibilityFeatures(
            ACCESSIBILITY_FEATURE_DISABLE_ANIMATIONS | ACCESSIBILITY_FEATURE_NO_ANNOUNCE);
    reset(mockChannel);

    // Animations are enabled
    Settings.Global.putFloat(mockContentResolver, "transition_animation_scale", 1.0f);
    observer.onChange(false);
    verify(mockChannel).setAccessibilityFeatures(ACCESSIBILITY_FEATURE_NO_ANNOUNCE);
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

  @Test
  public void sendFocusAccessibilityEvent() {
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    AccessibilityChannel accessibilityChannel =
        new AccessibilityChannel(mock(DartExecutor.class), mock(FlutterJNI.class));

    ContentResolver mockContentResolver = mock(ContentResolver.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    ViewParent mockParent = mock(ViewParent.class);
    when(mockRootView.getParent()).thenReturn(mockParent);
    when(mockManager.isEnabled()).thenReturn(true);

    AccessibilityBridge accessibilityBridge =
        setUpBridge(mockRootView, accessibilityChannel, mockManager, null, null, null);

    HashMap<String, Object> arguments = new HashMap<>();
    arguments.put("type", "focus");
    arguments.put("nodeId", 123);
    BasicMessageChannel.Reply reply = mock(BasicMessageChannel.Reply.class);
    accessibilityChannel.parsingMessageHandler.onMessage(arguments, reply);

    // Check that focus event was sent.
    ArgumentCaptor<AccessibilityEvent> eventCaptor =
        ArgumentCaptor.forClass(AccessibilityEvent.class);
    verify(mockParent).requestSendAccessibilityEvent(eq(mockRootView), eventCaptor.capture());
    AccessibilityEvent event = eventCaptor.getAllValues().get(0);
    assertEquals(AccessibilityEvent.TYPE_VIEW_FOCUSED, event.getEventType());
    assertNull(event.getSource());
  }

  @Test
  public void SetSourceAndPackageNameForAccessibilityEvent() {
    AccessibilityManager mockManager = mock(AccessibilityManager.class);
    ContentResolver mockContentResolver = mock(ContentResolver.class);
    View mockRootView = mock(View.class);
    Context context = mock(Context.class);
    when(mockRootView.getContext()).thenReturn(context);
    when(context.getPackageName()).thenReturn("test");
    when(mockManager.isEnabled()).thenReturn(true);
    ViewParent mockParent = mock(ViewParent.class);
    when(mockRootView.getParent()).thenReturn(mockParent);
    AccessibilityEvent mockEvent = mock(AccessibilityEvent.class);

    AccessibilityBridge accessibilityBridge =
        setUpBridge(mockRootView, null, mockManager, null, null, null);

    AccessibilityBridge spyAccessibilityBridge = spy(accessibilityBridge);

    when(spyAccessibilityBridge.obtainAccessibilityEvent(AccessibilityEvent.TYPE_VIEW_FOCUSED))
        .thenReturn(mockEvent);

    spyAccessibilityBridge.sendAccessibilityEvent(123, AccessibilityEvent.TYPE_VIEW_FOCUSED);

    verify(mockEvent).setPackageName("test");
    verify(mockEvent).setSource(eq(mockRootView), eq(123));
  }

  @Test
  public void itAddsButtonClassToLinkWithoutURL() {
    AccessibilityBridge accessibilityBridge = setUpBridge();

    TestSemanticsNode testSemanticsNode = new TestSemanticsNode();
    testSemanticsNode.addFlag(AccessibilityBridge.Flag.IS_LINK);
    TestSemanticsUpdate testSemanticsUpdate = testSemanticsNode.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);
    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);

    assertEquals("android.widget.Button", nodeInfo.getClassName());
  }

  @Test
  public void itAddsClickActionToSliderNodeInfo() {
    AccessibilityBridge accessibilityBridge = setUpBridge();

    TestSemanticsNode testSemanticsNode = new TestSemanticsNode();
    testSemanticsNode.addFlag(AccessibilityBridge.Flag.IS_SLIDER);
    TestSemanticsUpdate testSemanticsUpdate = testSemanticsNode.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);
    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);

    assertTrue(nodeInfo.isClickable());
    List<AccessibilityNodeInfo.AccessibilityAction> actions = nodeInfo.getActionList();
    assertTrue(actions.contains(AccessibilityNodeInfo.AccessibilityAction.ACTION_CLICK));
  }

  // Setup method for testing CollectionInfo
  // The logic has branching based on SDK version. The version tests are below
  public void itAddsCollectionInfo() {
    AccessibilityBridge accessibilityBridge = setUpBridge();

    TestSemanticsNode testSemanticsNode = new TestSemanticsNode();
    testSemanticsNode.addFlag(AccessibilityBridge.Flag.HAS_IMPLICIT_SCROLLING);
    // test with 1 scrollChild
    testSemanticsNode.scrollChildren = 1;
    TestSemanticsUpdate testSemanticsUpdate = testSemanticsNode.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);
    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
    assertNull(nodeInfo.getCollectionInfo());
    // test with 2 scrollChildren
    testSemanticsNode.scrollChildren = 2;
    testSemanticsUpdate = testSemanticsNode.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);
    nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
    AccessibilityNodeInfo.CollectionInfo collectionInfo = nodeInfo.getCollectionInfo();
    assertNotNull(collectionInfo);

    assertEquals(testSemanticsNode.scrollChildren, collectionInfo.getRowCount());
    assertEquals(1, collectionInfo.getColumnCount()); // 1 column for a list
    assertFalse(collectionInfo.isHierarchical());
  }

  @Config(sdk = API_LEVELS.API_32)
  @TargetApi(API_LEVELS.API_32)
  @Test
  public void itAddsCollectionInfoAPI32() {
    // Testing CollectionInfo creation for API 32
    itAddsCollectionInfo();
  }

  @Config(sdk = API_LEVELS.API_33)
  @TargetApi(API_LEVELS.API_33)
  @Test
  public void itAddsCollectionInfoAPI33() {
    // Testing CollectionInfo creation for API 33
    itAddsCollectionInfo();
  }

  // Setup method for testing CollectionItemInfo
  // The logic has branching based on SDK version. The version tests are below
  public void itAddsCollectionItemInfo() {
    AccessibilityBridge accessibilityBridge = setUpBridge();

    TestSemanticsNode parentTestSemanticsNode = new TestSemanticsNode();
    parentTestSemanticsNode.addFlag(AccessibilityBridge.Flag.HAS_IMPLICIT_SCROLLING);
    parentTestSemanticsNode.scrollChildren = 2;
    parentTestSemanticsNode.id = 0;
    // add children to parentTestSemanticsNode
    TestSemanticsNode childNode1 = new TestSemanticsNode();
    childNode1.id = 1;
    childNode1.label = "Test 1";
    TestSemanticsNode childNode2 = new TestSemanticsNode();
    childNode2.id = 2;
    childNode2.label = "Test 2";
    parentTestSemanticsNode.addChild(childNode1);
    parentTestSemanticsNode.addChild(childNode2);
    TestSemanticsUpdate testSemanticsUpdate = parentTestSemanticsNode.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);
    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(1);
    AccessibilityNodeInfo.CollectionItemInfo itemInfo = nodeInfo.getCollectionItemInfo();
    assertNotNull(itemInfo);

    assertEquals(0, itemInfo.getRowIndex()); // first item in the list
    assertEquals(1, itemInfo.getRowSpan());
    assertEquals(0, itemInfo.getColumnIndex()); // only a single column
    assertEquals(1, itemInfo.getColumnSpan());
    // Note: CollectionItemInfo.isHeading() was deprecated in API 28, and since this test node
    // doesn't have IS_HEADER flag,
    // we expect it to not be a heading. The heading state is set during CollectionItemInfo
    // construction.
    // Documentation says to check AccessibilityNodeInfo.isHeading() instead.
    assertFalse(nodeInfo.isHeading());
  }

  @Test
  public void itAddsScrollViewToClassName() {
    AccessibilityBridge accessibilityBridge = setUpBridge();
    // Vertical scroll view
    TestSemanticsNode testSemanticsNode = new TestSemanticsNode();
    testSemanticsNode.addFlag(AccessibilityBridge.Flag.HAS_IMPLICIT_SCROLLING);
    testSemanticsNode.addAction(Action.SCROLL_UP);
    testSemanticsNode.addAction(Action.SCROLL_DOWN);
    TestSemanticsUpdate testSemanticsUpdate = testSemanticsNode.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);
    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
    assertEquals("android.widget.ScrollView", nodeInfo.getClassName().toString());
    // Horizontal scroll view
    testSemanticsNode = new TestSemanticsNode();
    testSemanticsNode.addFlag(AccessibilityBridge.Flag.HAS_IMPLICIT_SCROLLING);
    testSemanticsNode.addAction(Action.SCROLL_LEFT);
    testSemanticsNode.addAction(Action.SCROLL_RIGHT);
    testSemanticsUpdate = testSemanticsNode.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);
    nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
    assertEquals("android.widget.HorizontalScrollView", nodeInfo.getClassName().toString());
  }

  @Config(sdk = API_LEVELS.API_32)
  @TargetApi(API_LEVELS.API_32)
  @Test
  public void itAddsCollectionItemInfoAPI32() {
    // Testing CollectionItemInfo creation for API 32
    itAddsCollectionItemInfo();
  }

  @Config(sdk = API_LEVELS.API_33)
  @TargetApi(API_LEVELS.API_33)
  @Test
  public void itAddsCollectionItemInfoAPI33() {
    // Testing CollectionItemInfo creation for API 33
    itAddsCollectionItemInfo();
  }

  @Config(sdk = API_LEVELS.API_36)
  @TargetApi(API_LEVELS.API_36)
  @Test
  public void itSetsExpandedStateBasedOnFlagsCorrectly() {
    AccessibilityBridge accessibilityBridge = setUpBridge();

    TestSemanticsNode node = new TestSemanticsNode();
    TestSemanticsUpdate testSemanticsUpdate = node.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
    assertEquals(AccessibilityNodeInfo.EXPANDED_STATE_UNDEFINED, nodeInfo.getExpandedState());

    node = new TestSemanticsNode();
    node.addFlag(AccessibilityBridge.Flag.HAS_EXPANDED_STATE);
    testSemanticsUpdate = node.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
    assertEquals(AccessibilityNodeInfo.EXPANDED_STATE_COLLAPSED, nodeInfo.getExpandedState());

    node = new TestSemanticsNode();
    node.addFlag(AccessibilityBridge.Flag.HAS_EXPANDED_STATE);
    node.addFlag(AccessibilityBridge.Flag.IS_EXPANDED);
    testSemanticsUpdate = node.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
    assertEquals(AccessibilityNodeInfo.EXPANDED_STATE_FULL, nodeInfo.getExpandedState());
  }

  @Config(sdk = API_LEVELS.API_36)
  @TargetApi(API_LEVELS.API_36)
  @Test
  public void itAddsExpandActionBasedOnFlagsCorrectly() {
    AccessibilityBridge accessibilityBridge = setUpBridge();

    TestSemanticsNode node = new TestSemanticsNode();
    TestSemanticsUpdate testSemanticsUpdate = node.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
    List<AccessibilityNodeInfo.AccessibilityAction> actions = nodeInfo.getActionList();
    assertFalse(actions.contains(AccessibilityNodeInfo.AccessibilityAction.ACTION_EXPAND));

    node = new TestSemanticsNode();
    node.addFlag(AccessibilityBridge.Flag.HAS_EXPANDED_STATE);
    testSemanticsUpdate = node.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
    actions = nodeInfo.getActionList();
    assertFalse(actions.contains(AccessibilityNodeInfo.AccessibilityAction.ACTION_EXPAND));

    node = new TestSemanticsNode();
    node.addFlag(AccessibilityBridge.Flag.HAS_EXPANDED_STATE);
    node.addAction(AccessibilityBridge.Action.EXPAND);
    testSemanticsUpdate = node.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
    actions = nodeInfo.getActionList();
    assertTrue(actions.contains(AccessibilityNodeInfo.AccessibilityAction.ACTION_EXPAND));
  }

  @Config(sdk = API_LEVELS.API_36)
  @TargetApi(API_LEVELS.API_36)
  @Test
  public void itCanPerformExpand() {
    AccessibilityChannel mockChannel = mock(AccessibilityChannel.class);
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            /* rootAccessibilityView= */ null,
            /* accessibilityChannel= */ mockChannel,
            /* accessibilityManager= */ null,
            /* contentResolver= */ null,
            /* accessibilityViewEmbedder= */ null,
            /* platformViewsAccessibilityDelegate= */ null);

    TestSemanticsNode node = new TestSemanticsNode();
    node.addFlag(AccessibilityBridge.Flag.HAS_EXPANDED_STATE);
    node.addAction(AccessibilityBridge.Action.EXPAND);
    TestSemanticsUpdate testSemanticsUpdate = node.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    accessibilityBridge.performAction(0, AccessibilityNodeInfo.ACTION_EXPAND, null);
    verify(mockChannel).dispatchSemanticsAction(0, AccessibilityBridge.Action.EXPAND);
  }

  @Config(sdk = API_LEVELS.API_36)
  @TargetApi(API_LEVELS.API_36)
  @Test
  public void itAddsCollapseActionBasedOnFlagsCorrectly() {
    AccessibilityBridge accessibilityBridge = setUpBridge();

    TestSemanticsNode node = new TestSemanticsNode();
    TestSemanticsUpdate testSemanticsUpdate = node.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    AccessibilityNodeInfo nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
    List<AccessibilityNodeInfo.AccessibilityAction> actions = nodeInfo.getActionList();
    assertFalse(actions.contains(AccessibilityNodeInfo.AccessibilityAction.ACTION_COLLAPSE));

    node = new TestSemanticsNode();
    node.addFlag(AccessibilityBridge.Flag.HAS_EXPANDED_STATE);
    node.addFlag(AccessibilityBridge.Flag.IS_EXPANDED);
    testSemanticsUpdate = node.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
    actions = nodeInfo.getActionList();
    assertFalse(actions.contains(AccessibilityNodeInfo.AccessibilityAction.ACTION_COLLAPSE));

    node = new TestSemanticsNode();
    node.addFlag(AccessibilityBridge.Flag.HAS_EXPANDED_STATE);
    node.addFlag(AccessibilityBridge.Flag.IS_EXPANDED);
    node.addAction(AccessibilityBridge.Action.COLLAPSE);
    testSemanticsUpdate = node.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    nodeInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
    actions = nodeInfo.getActionList();
    assertTrue(actions.contains(AccessibilityNodeInfo.AccessibilityAction.ACTION_COLLAPSE));
  }

  @Config(sdk = API_LEVELS.API_36)
  @TargetApi(API_LEVELS.API_36)
  @Test
  public void itCanPerformCollapse() {
    AccessibilityChannel mockChannel = mock(AccessibilityChannel.class);
    AccessibilityBridge accessibilityBridge =
        setUpBridge(
            /* rootAccessibilityView= */ null,
            /* accessibilityChannel= */ mockChannel,
            /* accessibilityManager= */ null,
            /* contentResolver= */ null,
            /* accessibilityViewEmbedder= */ null,
            /* platformViewsAccessibilityDelegate= */ null);

    TestSemanticsNode node = new TestSemanticsNode();
    node.addFlag(AccessibilityBridge.Flag.HAS_EXPANDED_STATE);
    node.addFlag(AccessibilityBridge.Flag.IS_EXPANDED);
    node.addAction(AccessibilityBridge.Action.COLLAPSE);
    TestSemanticsUpdate testSemanticsUpdate = node.toUpdate();
    testSemanticsUpdate.sendUpdateToBridge(accessibilityBridge);

    accessibilityBridge.performAction(0, AccessibilityNodeInfo.ACTION_COLLAPSE, null);
    verify(mockChannel).dispatchSemanticsAction(0, AccessibilityBridge.Action.COLLAPSE);
  }

  @Config(sdk = API_LEVELS.API_28)
  @TargetApi(API_LEVELS.API_28)
  @Test
  public void itSetsHeadingWhenHeadingLevelIsPositive() {
    AccessibilityBridge accessibilityBridge = setUpBridge();

    TestSemanticsNode headingNode = new TestSemanticsNode();
    headingNode.headingLevel = 2;
    headingNode.label = "Level 2 heading";
    TestSemanticsUpdate headingUpdate = headingNode.toUpdate();
    headingUpdate.sendUpdateToBridge(accessibilityBridge);
    AccessibilityNodeInfo headingInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
    assertTrue(headingInfo.isHeading());
  }

  @Config(sdk = API_LEVELS.API_28)
  @TargetApi(API_LEVELS.API_28)
  @Test
  public void itDoesNotSetHeadingWhenHeadingLevelIsZero() {
    AccessibilityBridge accessibilityBridge = setUpBridge();

    TestSemanticsNode nonHeadingNode = new TestSemanticsNode();
    nonHeadingNode.headingLevel = 0;
    nonHeadingNode.label = "Not a heading";
    TestSemanticsUpdate nonHeadingUpdate = nonHeadingNode.toUpdate();
    nonHeadingUpdate.sendUpdateToBridge(accessibilityBridge);
    AccessibilityNodeInfo nonHeadingInfo = accessibilityBridge.createAccessibilityNodeInfo(0);
    assertFalse(nonHeadingInfo.isHeading());
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
    TestSemanticsUpdate(ByteBuffer buffer, String[] strings, ByteBuffer[] stringAttributeArgs) {
      this.buffer = buffer;
      this.strings = strings;
      this.stringAttributeArgs = stringAttributeArgs;
    }

    void sendUpdateToBridge(AccessibilityBridge bridge) {
      bridge.updateSemantics(buffer, strings, stringAttributeArgs);
    }

    final ByteBuffer buffer;
    final String[] strings;
    final ByteBuffer[] stringAttributeArgs;
  }

  enum TestStringAttributeType {
    SPELLOUT(0),
    LOCALE(1);

    private final int value;

    TestStringAttributeType(int value) {
      this.value = value;
    }

    public int getValue() {
      return value;
    }
  }

  class TestStringAttribute {
    int start;
    int end;
    TestStringAttributeType type;
  }

  class TestStringAttributeSpellOut extends TestStringAttribute {}

  class TestStringAttributeLocale extends TestStringAttribute {
    String locale;
  }

  class TestSemanticsNode {
    TestSemanticsNode() {}

    void addFlag(AccessibilityBridge.Flag flag) {
      flags |= flag.value;
    }

    void addAction(AccessibilityBridge.Action action) {
      actions |= action.value;
    }

    // These fields are declared in the order they should be
    // encoded.
    int id = 0;
    long flags = 0;
    int actions = 0;
    int maxValueLength = 0;
    int currentValueLength = 0;
    int textSelectionBase = 0;
    int textSelectionExtent = 0;
    int platformViewId = -1;
    int scrollChildren = 0;
    int scrollIndex = 0;
    int traversalParent = -1;
    float scrollPosition = 0.0f;
    float scrollExtentMax = 0.0f;
    float scrollExtentMin = 0.0f;
    String identifier = null;
    String label = null;
    List<TestStringAttribute> labelAttributes;
    String value = null;
    List<TestStringAttribute> valueAttributes;
    String increasedValue = null;
    List<TestStringAttribute> increasedValueAttributes;
    String decreasedValue = null;
    List<TestStringAttribute> decreasedValueAttributes;
    String hint = null;
    List<TestStringAttribute> hintAttributes;
    String tooltip = null;
    String linkUrl = null;
    String locale = null;
    int headingLevel = 0;
    int textDirection = 0;
    float left = 0.0f;
    float top = 0.0f;
    float right = 0.0f;
    float bottom = 0.0f;
    float[] transform =
        new float[] {
          1.0f, 0.0f, 0.0f, 0.0f,
          0.0f, 1.0f, 0.0f, 0.0f,
          0.0f, 0.0f, 1.0f, 0.0f,
          0.0f, 0.0f, 0.0f, 1.0f
        };
    float[] hitTestTransform =
        new float[] {
          1.0f, 0.0f, 0.0f, 0.0f,
          0.0f, 1.0f, 0.0f, 0.0f,
          0.0f, 0.0f, 1.0f, 0.0f,
          0.0f, 0.0f, 0.0f, 1.0f
        };

    final List<TestSemanticsNode> children = new ArrayList<TestSemanticsNode>();

    public void addChild(TestSemanticsNode child) {
      children.add(child);
    }
    // custom actions not supported.

    TestSemanticsUpdate toUpdate() {
      ArrayList<String> strings = new ArrayList<String>();
      ByteBuffer bytes = ByteBuffer.allocate(1000);
      ArrayList<ByteBuffer> stringAttributeArgs = new ArrayList<ByteBuffer>();
      addToBuffer(bytes, strings, stringAttributeArgs);
      bytes.flip();
      return new TestSemanticsUpdate(
          bytes,
          strings.toArray(new String[strings.size()]),
          stringAttributeArgs.toArray(new ByteBuffer[stringAttributeArgs.size()]));
    }

    protected void addToBuffer(
        ByteBuffer bytes, ArrayList<String> strings, ArrayList<ByteBuffer> stringAttributeArgs) {
      bytes.putInt(id);
      bytes.putLong(flags);
      bytes.putInt(actions);
      bytes.putInt(maxValueLength);
      bytes.putInt(currentValueLength);
      bytes.putInt(textSelectionBase);
      bytes.putInt(textSelectionExtent);
      bytes.putInt(platformViewId);
      bytes.putInt(scrollChildren);
      bytes.putInt(scrollIndex);
      bytes.putInt(traversalParent);
      bytes.putFloat(scrollPosition);
      bytes.putFloat(scrollExtentMax);
      bytes.putFloat(scrollExtentMin);
      if (identifier == null) {
        bytes.putInt(-1);
      } else {
        strings.add(identifier);
        bytes.putInt(strings.size() - 1);
      }
      updateString(label, labelAttributes, bytes, strings, stringAttributeArgs);
      updateString(value, valueAttributes, bytes, strings, stringAttributeArgs);
      updateString(increasedValue, increasedValueAttributes, bytes, strings, stringAttributeArgs);
      updateString(decreasedValue, decreasedValueAttributes, bytes, strings, stringAttributeArgs);
      updateString(hint, hintAttributes, bytes, strings, stringAttributeArgs);
      if (tooltip == null) {
        bytes.putInt(-1);
      } else {
        strings.add(tooltip);
        bytes.putInt(strings.size() - 1);
      }
      if (linkUrl == null) {
        bytes.putInt(-1);
      } else {
        strings.add(linkUrl);
        bytes.putInt(strings.size() - 1);
      }
      if (locale == null) {
        bytes.putInt(-1);
      } else {
        strings.add(locale);
        bytes.putInt(strings.size() - 1);
      }
      bytes.putInt(headingLevel);
      bytes.putInt(textDirection);
      bytes.putFloat(left);
      bytes.putFloat(top);
      bytes.putFloat(right);
      bytes.putFloat(bottom);
      // transform.
      for (int i = 0; i < 16; i++) {
        bytes.putFloat(transform[i]);
      }
      // hitTestTransform.
      for (int i = 0; i < 16; i++) {
        bytes.putFloat(hitTestTransform[i]);
      }
      // children in traversal order.
      bytes.putInt(children.size());
      for (TestSemanticsNode node : children) {
        bytes.putInt(node.id);
      }
      // children in hit test order.
      bytes.putInt(children.size());
      for (TestSemanticsNode node : children) {
        bytes.putInt(node.id);
      }
      // custom actions
      bytes.putInt(0);
      // child nodes
      for (TestSemanticsNode node : children) {
        node.addToBuffer(bytes, strings, stringAttributeArgs);
      }
    }
  }

  static void updateString(
      String value,
      List<TestStringAttribute> attributes,
      ByteBuffer bytes,
      ArrayList<String> strings,
      ArrayList<ByteBuffer> stringAttributeArgs) {
    if (value == null) {
      bytes.putInt(-1);
    } else {
      strings.add(value);
      bytes.putInt(strings.size() - 1);
    }
    // attributes
    if (attributes == null || attributes.isEmpty()) {
      bytes.putInt(-1);
      return;
    }
    bytes.putInt(attributes.size());
    for (TestStringAttribute attribute : attributes) {
      bytes.putInt(attribute.start);
      bytes.putInt(attribute.end);
      bytes.putInt(attribute.type.getValue());
      switch (attribute.type) {
        case SPELLOUT:
          bytes.putInt(-1);
          break;
        case LOCALE:
          bytes.putInt(stringAttributeArgs.size());
          TestStringAttributeLocale localeAttribute = (TestStringAttributeLocale) attribute;
          stringAttributeArgs.add(StandardCharsets.UTF_8.encode(localeAttribute.locale));
          break;
      }
    }
  }
}
