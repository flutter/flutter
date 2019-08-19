package io.flutter.embedding.engine.systemchannels;

import org.hamcrest.Description;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentMatcher;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

import java.nio.ByteBuffer;
import java.util.Collections;

import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.JSONMethodCodec;
import io.flutter.plugin.common.MethodCall;

import static org.mockito.Matchers.argThat;
import static org.mockito.Matchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

@Config(manifest=Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class TextInputChannelTest {
  @Test
  public void itNotifiesFrameworkWhenPlatformClosesInputConnection() {
    // Setup test.
    final int INPUT_CLIENT_ID = 9; // Arbitrary integer.
    DartExecutor dartExecutor = mock(DartExecutor.class);

    TextInputChannel textInputChannel = new TextInputChannel(dartExecutor);

    // Execute behavior under test.
    textInputChannel.onConnectionClosed(INPUT_CLIENT_ID);

    // Verify results.
    verify(dartExecutor, times(1)).send(
        eq("flutter/textinput"),
        ByteBufferMatcher.eqByteBuffer(JSONMethodCodec.INSTANCE.encodeMethodCall(
            new MethodCall(
                "TextInputClient.onConnectionClosed",
                Collections.singletonList(INPUT_CLIENT_ID)
            )
        )),
        eq(null)
    );
  }

  /**
   * Mockito matcher that compares two {@link ByteBuffer}s by resetting both buffers and then
   * utilizing their standard {@code equals()} method.
   * <p>
   * This matcher will change the state of the expected and actual buffers. The exact change in
   * state depends on where the comparison fails or succeeds.
   */
  static class ByteBufferMatcher extends ArgumentMatcher<ByteBuffer> {

    static ByteBuffer eqByteBuffer(ByteBuffer expected) {
      return argThat(new ByteBufferMatcher(expected));
    }

    private ByteBuffer expected;

    ByteBufferMatcher(ByteBuffer expected) {
      this.expected = expected;
    }

    @Override
    public boolean matches(Object argument) {
      if (!(argument instanceof ByteBuffer)) {
        return false;
      }

      // Reset the buffers for content comparison.
      ((ByteBuffer) argument).position(0);
      expected.position(0);

      return expected.equals(argument);
    }

    // Implemented so that during a failure the expected value is
    // shown in logs, rather than the name of this class.
    @Override
    public void describeTo(Description description) {
      description.appendText(expected.toString());
    }
  }
}
