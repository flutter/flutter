package io.flutter.plugin.common;

import java.nio.ByteBuffer;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * A {@link MethodCodec} using UTF-8 encoded JSON method calls and result envelopes.
 * Values supported as methods arguments and result payloads are those supported by
 * {@link JSONMessageCodec}.
 */
public final class JSONMethodCodec implements MethodCodec {
  public static final JSONMethodCodec INSTANCE = new JSONMethodCodec();

  private JSONMethodCodec() {
  }

  @Override
  public MethodCall decodeMethodCall(ByteBuffer message) {
    try {
      final Object json = JSONMessageCodec.INSTANCE.decodeMessage(message);
      if (json instanceof JSONArray) {
        final JSONArray pair = (JSONArray) json;
        if (pair.length() == 2 && pair.get(0) instanceof String) {
          return new MethodCall(pair.getString(0), pair.get(1));
        }
      }
      throw new IllegalArgumentException("Invalid method call: " + json);
    } catch (JSONException e) {
      throw new IllegalArgumentException("Invalid JSON", e);
    }
  }

  @Override
  public ByteBuffer encodeSuccessEnvelope(Object result) {
    return JSONMessageCodec.INSTANCE.encodeMessage(new JSONArray().put(JSONObject.wrap(result)));
  }

  @Override
  public ByteBuffer encodeErrorEnvelope(String errorCode, String errorMessage, Object errorDetails) {
    return JSONMessageCodec.INSTANCE.encodeMessage(new JSONArray()
        .put(errorCode)
        .put(errorMessage)
        .put(JSONObject.wrap(errorDetails)));
  }
}
