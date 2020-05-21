package io.flutter.plugin.common;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;

import java.nio.ByteBuffer;
import java.util.HashMap;
import java.util.Map;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class StandardMethodCodecTest {

  @Test
  public void encodeMethodTest() {
    final Map<String, String> args = new HashMap<>();
    args.put("testArg", "testValue");
    MethodCall call = new MethodCall("testMethod", args);
    final ByteBuffer buffer = StandardMethodCodec.INSTANCE.encodeMethodCall(call);
    assertNotNull(buffer);
    buffer.flip();
    final MethodCall result = StandardMethodCodec.INSTANCE.decodeMethodCall(buffer);
    assertEquals(call.method, result.method);
    assertEquals(call.arguments, result.arguments);
  }

  @Test
  public void encodeSuccessEnvelopeTest() {
    final Map<String, Integer> success = new HashMap<>();
    success.put("result", 1);
    final ByteBuffer buffer = StandardMethodCodec.INSTANCE.encodeSuccessEnvelope(success);
    assertNotNull(buffer);
    buffer.flip();
    final Object result = StandardMethodCodec.INSTANCE.decodeEnvelope(buffer);
    assertEquals(success, result);
  }

  @Test
  public void encodeSuccessEnvelopeUnsupportedObjectTest() {
    final StandardMethodCodecTest joke = new StandardMethodCodecTest();
    try {
      final ByteBuffer buffer = StandardMethodCodec.INSTANCE.encodeSuccessEnvelope(joke);
      fail("Should have failed to convert unsupported type.");
    } catch (IllegalArgumentException e) {
      // pass.
    }
  }

  @Test
  public void encodeErrorEnvelopeWithNullDetailsTest() {
    final ByteBuffer buffer =
        StandardMethodCodec.INSTANCE.encodeErrorEnvelope("code", "error", null);
    assertNotNull(buffer);
    buffer.flip();
    try {
      StandardMethodCodec.INSTANCE.decodeEnvelope(buffer);
      fail("Should have thrown a FlutterException since this is an error envelope.");
    } catch (FlutterException result) {
      assertEquals("code", result.code);
      assertEquals("error", result.getMessage());
      assertNull(result.details);
    }
  }

  @Test
  public void encodeErrorEnvelopeWithThrowableTest() {
    final Exception e = new IllegalArgumentException("foo");
    final ByteBuffer buffer =
        StandardMethodCodec.INSTANCE.encodeErrorEnvelope("code", e.getMessage(), e);
    assertNotNull(buffer);
    buffer.flip();
    try {
      StandardMethodCodec.INSTANCE.decodeEnvelope(buffer);
      fail("Should have thrown a FlutterException since this is an error envelope.");
    } catch (FlutterException result) {
      assertEquals("code", result.code);
      assertEquals("foo", result.getMessage());
      // Must contain part of a stack.
      String stack = (String) result.details;
      assertTrue(
          stack.contains(
              "at io.flutter.plugin.common.StandardMethodCodecTest.encodeErrorEnvelopeWithThrowableTest(StandardMethodCodecTest.java:"));
    }
  }
}
