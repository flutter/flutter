package io.flutter.embedding.android;

import static junit.framework.TestCase.assertEquals;
import static org.mockito.Mockito.any;
import static org.mockito.Mockito.isNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.notNull;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.annotation.TargetApi;
import android.view.KeyEvent;
import android.view.View;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.systemchannels.KeyEventChannel;
import io.flutter.embedding.engine.systemchannels.TextInputChannel;
import io.flutter.plugin.editing.TextInputPlugin;
import io.flutter.util.FakeKeyEvent;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.mockito.invocation.InvocationOnMock;
import org.mockito.stubbing.Answer;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
@TargetApi(28)
public class AndroidKeyProcessorTest {
  @Mock FlutterJNI mockFlutterJni;

  @Before
  public void setUp() {
    MockitoAnnotations.initMocks(this);
    when(mockFlutterJni.isAttached()).thenReturn(true);
  }

  @Test
  public void respondsTrueWhenHandlingNewEvents() {
    FlutterEngine flutterEngine = mockFlutterEngine();
    KeyEventChannel fakeKeyEventChannel = flutterEngine.getKeyEventChannel();
    View fakeView = mock(View.class);

    AndroidKeyProcessor processor =
        new AndroidKeyProcessor(fakeView, fakeKeyEventChannel, mock(TextInputPlugin.class));

    boolean result = processor.onKeyEvent(new FakeKeyEvent(KeyEvent.ACTION_DOWN, 65));
    assertEquals(true, result);
    verify(fakeKeyEventChannel, times(1)).keyDown(any(KeyEventChannel.FlutterKeyEvent.class));
    verify(fakeKeyEventChannel, times(0)).keyUp(any(KeyEventChannel.FlutterKeyEvent.class));
    verify(fakeView, times(0)).dispatchKeyEvent(any(KeyEvent.class));
  }

  @Test
  public void destroyTest() {
    FlutterEngine flutterEngine = mockFlutterEngine();
    KeyEventChannel fakeKeyEventChannel = flutterEngine.getKeyEventChannel();
    View fakeView = mock(View.class);

    AndroidKeyProcessor processor =
        new AndroidKeyProcessor(fakeView, fakeKeyEventChannel, mock(TextInputPlugin.class));

    verify(fakeKeyEventChannel, times(1))
        .setEventResponseHandler(notNull(KeyEventChannel.EventResponseHandler.class));
    processor.destroy();
    verify(fakeKeyEventChannel, times(1))
        .setEventResponseHandler(isNull(KeyEventChannel.EventResponseHandler.class));
  }

  public void synthesizesEventsWhenKeyDownNotHandled() {
    FlutterEngine flutterEngine = mockFlutterEngine();
    KeyEventChannel fakeKeyEventChannel = flutterEngine.getKeyEventChannel();
    View fakeView = mock(View.class);
    View fakeRootView = mock(View.class);
    when(fakeView.getRootView())
        .then(
            new Answer<View>() {
              @Override
              public View answer(InvocationOnMock invocation) throws Throwable {
                return fakeRootView;
              }
            });

    ArgumentCaptor<KeyEventChannel.EventResponseHandler> handlerCaptor =
        ArgumentCaptor.forClass(KeyEventChannel.EventResponseHandler.class);
    verify(fakeKeyEventChannel).setEventResponseHandler(handlerCaptor.capture());
    AndroidKeyProcessor processor =
        new AndroidKeyProcessor(fakeView, fakeKeyEventChannel, mock(TextInputPlugin.class));
    ArgumentCaptor<KeyEventChannel.FlutterKeyEvent> eventCaptor =
        ArgumentCaptor.forClass(KeyEventChannel.FlutterKeyEvent.class);
    FakeKeyEvent fakeKeyEvent = new FakeKeyEvent(KeyEvent.ACTION_DOWN, 65);

    boolean result = processor.onKeyEvent(fakeKeyEvent);
    assertEquals(true, result);

    // Capture the FlutterKeyEvent so we can find out its event ID to use when
    // faking our response.
    verify(fakeKeyEventChannel, times(1)).keyDown(eventCaptor.capture());
    boolean[] dispatchResult = {true};
    when(fakeView.dispatchKeyEvent(any(KeyEvent.class)))
        .then(
            new Answer<Boolean>() {
              @Override
              public Boolean answer(InvocationOnMock invocation) throws Throwable {
                KeyEvent event = (KeyEvent) invocation.getArguments()[0];
                assertEquals(fakeKeyEvent, event);
                dispatchResult[0] = processor.onKeyEvent(event);
                return dispatchResult[0];
              }
            });

    // Fake a response from the framework.
    handlerCaptor.getValue().onKeyEventNotHandled(eventCaptor.getValue().eventId);
    verify(fakeView, times(1)).dispatchKeyEvent(fakeKeyEvent);
    assertEquals(false, dispatchResult[0]);
    verify(fakeKeyEventChannel, times(0)).keyUp(any(KeyEventChannel.FlutterKeyEvent.class));
    verify(fakeRootView, times(1)).dispatchKeyEvent(fakeKeyEvent);
  }

  public void synthesizesEventsWhenKeyUpNotHandled() {
    FlutterEngine flutterEngine = mockFlutterEngine();
    KeyEventChannel fakeKeyEventChannel = flutterEngine.getKeyEventChannel();
    View fakeView = mock(View.class);
    View fakeRootView = mock(View.class);
    when(fakeView.getRootView())
        .then(
            new Answer<View>() {
              @Override
              public View answer(InvocationOnMock invocation) throws Throwable {
                return fakeRootView;
              }
            });

    ArgumentCaptor<KeyEventChannel.EventResponseHandler> handlerCaptor =
        ArgumentCaptor.forClass(KeyEventChannel.EventResponseHandler.class);
    verify(fakeKeyEventChannel).setEventResponseHandler(handlerCaptor.capture());
    AndroidKeyProcessor processor =
        new AndroidKeyProcessor(fakeView, fakeKeyEventChannel, mock(TextInputPlugin.class));
    ArgumentCaptor<KeyEventChannel.FlutterKeyEvent> eventCaptor =
        ArgumentCaptor.forClass(KeyEventChannel.FlutterKeyEvent.class);
    FakeKeyEvent fakeKeyEvent = new FakeKeyEvent(KeyEvent.ACTION_UP, 65);

    boolean result = processor.onKeyEvent(fakeKeyEvent);
    assertEquals(true, result);

    // Capture the FlutterKeyEvent so we can find out its event ID to use when
    // faking our response.
    verify(fakeKeyEventChannel, times(1)).keyUp(eventCaptor.capture());
    boolean[] dispatchResult = {true};
    when(fakeView.dispatchKeyEvent(any(KeyEvent.class)))
        .then(
            new Answer<Boolean>() {
              @Override
              public Boolean answer(InvocationOnMock invocation) throws Throwable {
                KeyEvent event = (KeyEvent) invocation.getArguments()[0];
                assertEquals(fakeKeyEvent, event);
                dispatchResult[0] = processor.onKeyEvent(event);
                return dispatchResult[0];
              }
            });

    // Fake a response from the framework.
    handlerCaptor.getValue().onKeyEventNotHandled(eventCaptor.getValue().eventId);
    verify(fakeView, times(1)).dispatchKeyEvent(fakeKeyEvent);
    assertEquals(false, dispatchResult[0]);
    verify(fakeKeyEventChannel, times(0)).keyUp(any(KeyEventChannel.FlutterKeyEvent.class));
    verify(fakeRootView, times(1)).dispatchKeyEvent(fakeKeyEvent);
  }

  @NonNull
  private FlutterEngine mockFlutterEngine() {
    // Mock FlutterEngine and all of its required direct calls.
    FlutterEngine engine = mock(FlutterEngine.class);
    when(engine.getKeyEventChannel()).thenReturn(mock(KeyEventChannel.class));
    when(engine.getTextInputChannel()).thenReturn(mock(TextInputChannel.class));

    return engine;
  }
}
