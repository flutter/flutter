package io.flutter.embedding.engine.dart;

import static junit.framework.TestCase.assertEquals;
import static junit.framework.TestCase.assertNotNull;
import static junit.framework.TestCase.assertTrue;
import static org.mockito.Matchers.any;
import static org.mockito.Mockito.mock;

import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.BinaryMessenger.BinaryMessageHandler;
import java.nio.ByteBuffer;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mockito;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class DartMessengerTest {
  private static class ReportingUncaughtExceptionHandler
      implements Thread.UncaughtExceptionHandler {
    public Throwable latestException;

    @Override
    public void uncaughtException(Thread t, Throwable e) {
      latestException = e;
    }
  }

  @Test
  public void itHandlesErrors() {
    // Setup test.
    final FlutterJNI fakeFlutterJni = mock(FlutterJNI.class);
    final Thread currentThread = Thread.currentThread();
    final Thread.UncaughtExceptionHandler savedHandler =
        currentThread.getUncaughtExceptionHandler();
    final ReportingUncaughtExceptionHandler reportingHandler =
        new ReportingUncaughtExceptionHandler();
    currentThread.setUncaughtExceptionHandler(reportingHandler);

    // Create object under test.
    final DartMessenger messenger = new DartMessenger(fakeFlutterJni);
    final BinaryMessageHandler throwingHandler = mock(BinaryMessageHandler.class);
    Mockito.doThrow(AssertionError.class)
        .when(throwingHandler)
        .onMessage(any(ByteBuffer.class), any(DartMessenger.Reply.class));

    messenger.setMessageHandler("test", throwingHandler);
    messenger.handleMessageFromDart("test", ByteBuffer.allocate(0), 0);
    assertNotNull(reportingHandler.latestException);
    assertTrue(reportingHandler.latestException instanceof AssertionError);
    currentThread.setUncaughtExceptionHandler(savedHandler);
  }

  @Test
  public void givesDirectByteBuffer() {
    // Setup test.
    final FlutterJNI fakeFlutterJni = mock(FlutterJNI.class);
    final DartMessenger messenger = new DartMessenger(fakeFlutterJni);
    final String channel = "foobar";
    final boolean[] wasDirect = {false};
    final BinaryMessenger.BinaryMessageHandler handler =
        (message, reply) -> {
          wasDirect[0] = message.isDirect();
        };
    messenger.setMessageHandler(channel, handler);
    final ByteBuffer message = ByteBuffer.allocateDirect(4 * 2);
    message.rewind();
    message.putChar('a');
    message.putChar('b');
    message.putChar('c');
    message.putChar('d');
    messenger.handleMessageFromDart(channel, message, /*replyId=*/ 123);
    assertTrue(wasDirect[0]);
  }

  @Test
  public void directByteBufferLimitZeroAfterUsage() {
    // Setup test.
    final FlutterJNI fakeFlutterJni = mock(FlutterJNI.class);
    final DartMessenger messenger = new DartMessenger(fakeFlutterJni);
    final String channel = "foobar";
    final ByteBuffer[] byteBuffers = {null};
    final int bufferSize = 4 * 2;
    final BinaryMessenger.BinaryMessageHandler handler =
        (message, reply) -> {
          byteBuffers[0] = message;
          assertEquals(bufferSize, byteBuffers[0].limit());
        };
    messenger.setMessageHandler(channel, handler);
    final ByteBuffer message = ByteBuffer.allocateDirect(bufferSize);
    message.rewind();
    message.putChar('a');
    message.putChar('b');
    message.putChar('c');
    message.putChar('d');
    messenger.handleMessageFromDart(channel, message, /*replyId=*/ 123);
    assertNotNull(byteBuffers[0]);
    assertTrue(byteBuffers[0].isDirect());
    assertEquals(0, byteBuffers[0].limit());
  }

  @Test
  public void directByteBufferLimitZeroAfterReply() {
    // Setup test.
    final FlutterJNI fakeFlutterJni = mock(FlutterJNI.class);
    final DartMessenger messenger = new DartMessenger(fakeFlutterJni);
    final ByteBuffer message = ByteBuffer.allocateDirect(4 * 2);
    final String channel = "foobar";
    message.rewind();
    message.putChar('a');
    message.putChar('b');
    message.putChar('c');
    message.putChar('d');
    final ByteBuffer[] byteBuffers = {null};
    BinaryMessenger.BinaryReply callback =
        (reply) -> {
          assertTrue(reply.isDirect());
          byteBuffers[0] = reply;
        };
    messenger.send(channel, null, callback);
    messenger.handlePlatformMessageResponse(1, message);
    assertEquals(0, byteBuffers[0].limit());
  }
}
