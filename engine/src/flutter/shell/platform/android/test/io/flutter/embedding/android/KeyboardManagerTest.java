package io.flutter.embedding.android;

import static junit.framework.TestCase.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.mockito.Mockito.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.annotation.TargetApi;
import android.view.KeyEvent;
import android.view.View;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.KeyboardManager.Responder;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.systemchannels.KeyEventChannel;
import io.flutter.embedding.engine.systemchannels.TextInputChannel;
import io.flutter.plugin.editing.TextInputPlugin;
import io.flutter.util.FakeKeyEvent;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
@TargetApi(28)
public class KeyboardManagerTest {
  static class FakeResponder implements Responder {
    KeyEvent mLastKeyEvent;
    OnKeyEventHandledCallback mLastKeyEventHandledCallback;

    @Override
    public void handleEvent(
        @NonNull KeyEvent keyEvent, @NonNull OnKeyEventHandledCallback onKeyEventHandledCallback) {
      mLastKeyEvent = keyEvent;
      mLastKeyEventHandledCallback = onKeyEventHandledCallback;
    }

    void eventHandled(boolean isHandled) {
      mLastKeyEventHandledCallback.onKeyEventHandled(isHandled);
    }
  }

  @Mock FlutterJNI mockFlutterJni;

  FlutterEngine mockEngine;
  KeyEventChannel mockKeyEventChannel;
  @Mock TextInputPlugin mockTextInputPlugin;
  @Mock View mockView;
  @Mock View mockRootView;
  KeyboardManager keyboardManager;

  @NonNull
  private FlutterEngine mockFlutterEngine() {
    // Mock FlutterEngine and all of its required direct calls.
    FlutterEngine engine = mock(FlutterEngine.class);
    when(engine.getKeyEventChannel()).thenReturn(mock(KeyEventChannel.class));
    when(engine.getTextInputChannel()).thenReturn(mock(TextInputChannel.class));
    return engine;
  }

  @Before
  public void setUp() {
    MockitoAnnotations.initMocks(this);
    when(mockFlutterJni.isAttached()).thenReturn(true);
    mockEngine = mockFlutterEngine();
    mockKeyEventChannel = mockEngine.getKeyEventChannel();
    when(mockView.getRootView()).thenAnswer(invocation -> mockRootView);
    when(mockView.dispatchKeyEvent(any(KeyEvent.class)))
        .thenAnswer(
            invocation -> keyboardManager.handleEvent((KeyEvent) invocation.getArguments()[0]));
    when(mockRootView.dispatchKeyEvent(any(KeyEvent.class)))
        .thenAnswer(
            invocation -> mockView.dispatchKeyEvent((KeyEvent) invocation.getArguments()[0]));
    keyboardManager =
        new KeyboardManager(
            mockView,
            mockTextInputPlugin,
            new Responder[] {new KeyChannelResponder(mockKeyEventChannel)});
  }

  // Tests start

  @Test
  public void respondsTrueWhenHandlingNewEvents() {
    final FakeResponder fakeResponder = new FakeResponder();
    keyboardManager =
        new KeyboardManager(
            mockView, mockTextInputPlugin, new KeyboardManager.Responder[] {fakeResponder});
    final KeyEvent keyEvent = new FakeKeyEvent(KeyEvent.ACTION_DOWN, 65);
    final boolean result = keyboardManager.handleEvent(keyEvent);

    assertEquals(true, result);
    assertEquals(keyEvent, fakeResponder.mLastKeyEvent);
    // Don't send the key event to the text plugin if the only primary responder
    // hasn't responded.
    verify(mockTextInputPlugin, times(0)).handleKeyEvent(any(KeyEvent.class));
    verify(mockRootView, times(0)).dispatchKeyEvent(any(KeyEvent.class));
  }

  @Test
  public void primaryRespondersHaveTheHighestPrecedence() {
    final FakeResponder fakeResponder = new FakeResponder();
    keyboardManager =
        new KeyboardManager(
            mockView, mockTextInputPlugin, new KeyboardManager.Responder[] {fakeResponder});
    final KeyEvent keyEvent = new FakeKeyEvent(KeyEvent.ACTION_DOWN, 65);
    final boolean result = keyboardManager.handleEvent(keyEvent);

    assertEquals(true, result);
    assertEquals(keyEvent, fakeResponder.mLastKeyEvent);

    // Don't send the key event to the text plugin if the only primary responder
    // hasn't responded.
    verify(mockTextInputPlugin, times(0)).handleKeyEvent(any(KeyEvent.class));
    verify(mockRootView, times(0)).dispatchKeyEvent(any(KeyEvent.class));

    // If a primary responder handles the key event the propagation stops.
    assertNotNull(fakeResponder.mLastKeyEventHandledCallback);
    fakeResponder.eventHandled(true);
    verify(mockTextInputPlugin, times(0)).handleKeyEvent(any(KeyEvent.class));
    verify(mockRootView, times(0)).dispatchKeyEvent(any(KeyEvent.class));
  }

  @Test
  public void zeroRespondersTest() {
    keyboardManager =
        new KeyboardManager(mockView, mockTextInputPlugin, new KeyboardManager.Responder[] {});
    final KeyEvent keyEvent = new FakeKeyEvent(KeyEvent.ACTION_DOWN, 65);
    final boolean result = keyboardManager.handleEvent(keyEvent);
    assertEquals(true, result);

    // Send the key event to the text plugin since there's 0 primary responders.
    verify(mockTextInputPlugin, times(1)).handleKeyEvent(any(KeyEvent.class));
  }

  @Test
  public void multipleRespondersTest() {
    final FakeResponder fakeResponder1 = new FakeResponder();
    final FakeResponder fakeResponder2 = new FakeResponder();
    keyboardManager =
        new KeyboardManager(
            mockView,
            mockTextInputPlugin,
            new KeyboardManager.Responder[] {fakeResponder1, fakeResponder2});
    final KeyEvent keyEvent = new FakeKeyEvent(KeyEvent.ACTION_DOWN, 65);
    final boolean result = keyboardManager.handleEvent(keyEvent);

    assertEquals(true, result);
    assertEquals(keyEvent, fakeResponder1.mLastKeyEvent);
    assertEquals(keyEvent, fakeResponder2.mLastKeyEvent);

    fakeResponder2.eventHandled(false);
    // Don't send the key event to the text plugin, since fakeResponder1
    // hasn't responded.
    verify(mockTextInputPlugin, times(0)).handleKeyEvent(any(KeyEvent.class));

    fakeResponder1.eventHandled(false);
    verify(mockTextInputPlugin, times(1)).handleKeyEvent(any(KeyEvent.class));
  }

  @Test
  public void multipleRespondersTest2() {
    final FakeResponder fakeResponder1 = new FakeResponder();
    final FakeResponder fakeResponder2 = new FakeResponder();
    keyboardManager =
        new KeyboardManager(
            mockView,
            mockTextInputPlugin,
            new KeyboardManager.Responder[] {fakeResponder1, fakeResponder2});
    final KeyEvent keyEvent = new FakeKeyEvent(KeyEvent.ACTION_DOWN, 65);
    final boolean result = keyboardManager.handleEvent(keyEvent);

    fakeResponder2.eventHandled(false);
    fakeResponder1.eventHandled(true);

    // Handled by primary responders, propagation stops.
    verify(mockTextInputPlugin, times(0)).handleKeyEvent(any(KeyEvent.class));
  }

  @Test
  public void multipleRespondersTest3() {
    final FakeResponder fakeResponder1 = new FakeResponder();
    final FakeResponder fakeResponder2 = new FakeResponder();
    keyboardManager =
        new KeyboardManager(
            mockView,
            mockTextInputPlugin,
            new KeyboardManager.Responder[] {fakeResponder1, fakeResponder2});
    final KeyEvent keyEvent = new FakeKeyEvent(KeyEvent.ACTION_DOWN, 65);
    final boolean result = keyboardManager.handleEvent(keyEvent);

    fakeResponder2.eventHandled(false);

    Exception exception = null;
    try {
      fakeResponder2.eventHandled(false);
    } catch (Exception e) {
      exception = e;
    }
    // Throws since the same handle is called twice.
    assertNotNull(exception);
  }

  @Test
  public void textInputPluginHasTheSecondHighestPrecedence() {
    final FakeResponder fakeResponder = new FakeResponder();
    keyboardManager =
        spy(
            new KeyboardManager(
                mockView, mockTextInputPlugin, new KeyboardManager.Responder[] {fakeResponder}));
    final KeyEvent keyEvent = new FakeKeyEvent(KeyEvent.ACTION_DOWN, 65);
    final boolean result = keyboardManager.handleEvent(keyEvent);

    assertEquals(true, result);
    assertEquals(keyEvent, fakeResponder.mLastKeyEvent);

    // Don't send the key event to the text plugin if the only primary responder
    // hasn't responded.
    verify(mockTextInputPlugin, times(0)).handleKeyEvent(any(KeyEvent.class));
    verify(mockRootView, times(0)).dispatchKeyEvent(any(KeyEvent.class));

    // If no primary responder handles the key event the propagates to the text
    // input plugin.
    assertNotNull(fakeResponder.mLastKeyEventHandledCallback);
    // Let text input plugin handle the key event.
    when(mockTextInputPlugin.handleKeyEvent(any())).thenAnswer(invocation -> true);
    fakeResponder.eventHandled(false);

    verify(mockTextInputPlugin, times(1)).handleKeyEvent(keyEvent);
    verify(mockRootView, times(0)).dispatchKeyEvent(any(KeyEvent.class));

    // It's not redispatched to the keyboard manager.
    verify(keyboardManager, times(1)).handleEvent(any(KeyEvent.class));
  }

  @Test
  public void RedispatchKeyEventIfTextInputPluginFailsToHandle() {
    final FakeResponder fakeResponder = new FakeResponder();
    keyboardManager =
        spy(
            new KeyboardManager(
                mockView, mockTextInputPlugin, new KeyboardManager.Responder[] {fakeResponder}));
    final KeyEvent keyEvent = new FakeKeyEvent(KeyEvent.ACTION_DOWN, 65);
    final boolean result = keyboardManager.handleEvent(keyEvent);

    assertEquals(true, result);
    assertEquals(keyEvent, fakeResponder.mLastKeyEvent);

    // Don't send the key event to the text plugin if the only primary responder
    // hasn't responded.
    verify(mockTextInputPlugin, times(0)).handleKeyEvent(any(KeyEvent.class));
    verify(mockRootView, times(0)).dispatchKeyEvent(any(KeyEvent.class));

    // Neither the primary responders nor text input plugin handles the event.
    when(mockTextInputPlugin.handleKeyEvent(any())).thenAnswer(invocation -> false);
    fakeResponder.mLastKeyEvent = null;
    fakeResponder.eventHandled(false);

    verify(mockTextInputPlugin, times(1)).handleKeyEvent(keyEvent);
    verify(mockRootView, times(1)).dispatchKeyEvent(keyEvent);
  }

  @Test
  public void respondsFalseWhenHandlingRedispatchedEvents() {
    final FakeResponder fakeResponder = new FakeResponder();
    keyboardManager =
        spy(
            new KeyboardManager(
                mockView, mockTextInputPlugin, new KeyboardManager.Responder[] {fakeResponder}));
    final KeyEvent keyEvent = new FakeKeyEvent(KeyEvent.ACTION_DOWN, 65);
    final boolean result = keyboardManager.handleEvent(keyEvent);

    assertEquals(true, result);
    assertEquals(keyEvent, fakeResponder.mLastKeyEvent);

    // Don't send the key event to the text plugin if the only primary responder
    // hasn't responded.
    verify(mockTextInputPlugin, times(0)).handleKeyEvent(any(KeyEvent.class));
    verify(mockRootView, times(0)).dispatchKeyEvent(any(KeyEvent.class));

    // Neither the primary responders nor text input plugin handles the event.
    when(mockTextInputPlugin.handleKeyEvent(any())).thenAnswer(invocation -> false);
    fakeResponder.mLastKeyEvent = null;
    fakeResponder.eventHandled(false);

    verify(mockTextInputPlugin, times(1)).handleKeyEvent(keyEvent);
    verify(mockRootView, times(1)).dispatchKeyEvent(keyEvent);

    // It's redispatched to the keyboard manager, but not the primary
    // responders.
    verify(keyboardManager, times(2)).handleEvent(any(KeyEvent.class));
    assertNull(fakeResponder.mLastKeyEvent);
  }
}
