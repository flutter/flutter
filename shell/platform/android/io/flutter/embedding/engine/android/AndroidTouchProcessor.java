package io.flutter.embedding.engine.android;

import android.support.annotation.NonNull;
import android.view.MotionEvent;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;

import io.flutter.embedding.engine.renderer.FlutterRenderer;

/**
 * Sends touch information from Android to Flutter in a format that Flutter
 * understands.
 */
public class AndroidTouchProcessor {

  // Must match the PointerChange enum in pointer.dart.
  // TODO(mattcarroll): convert these to an IntDef
  private static final int POINTER_CHANGE_CANCEL = 0;
  private static final int POINTER_CHANGE_ADD = 1;
  private static final int POINTER_CHANGE_REMOVE = 2;
  private static final int POINTER_CHANGE_HOVER = 3;
  private static final int POINTER_CHANGE_DOWN = 4;
  private static final int POINTER_CHANGE_MOVE = 5;
  private static final int POINTER_CHANGE_UP = 6;

  // Must match the PointerDeviceKind enum in pointer.dart.
  // TODO(mattcarroll): convert these to an IntDef
  private static final int POINTER_DEVICE_KIND_TOUCH = 0;
  private static final int POINTER_DEVICE_KIND_MOUSE = 1;
  private static final int POINTER_DEVICE_KIND_STYLUS = 2;
  private static final int POINTER_DEVICE_KIND_INVERTED_STYLUS = 3;
  private static final int POINTER_DEVICE_KIND_UNKNOWN = 4;

  // Must match the unpacking code in hooks.dart.
  private static final int POINTER_DATA_FIELD_COUNT = 19;
  private static final int BYTE_PER_FIELD = 8;

  @NonNull
  private final FlutterRenderer renderer;

  /**
   * Constructs an {@code AndroidTouchProcessor} that will send touch event data
   * to the Flutter execution context represented by the given {@link FlutterRenderer}.
   */
  // TODO(mattcarroll): consider moving packet behavior to a FlutterInteractionSurface instead of FlutterRenderer
  public AndroidTouchProcessor(@NonNull FlutterRenderer renderer) {
    this.renderer = renderer;
  }

  /**
   * Sends the given {@link MotionEvent} data to Flutter in a format that
   * Flutter understands.
   */
  public boolean onTouchEvent(MotionEvent event) {
    int pointerCount = event.getPointerCount();

    // Prepare a data packet of the appropriate size and order.
    ByteBuffer packet = ByteBuffer.allocateDirect(
        pointerCount * POINTER_DATA_FIELD_COUNT * BYTE_PER_FIELD
    );
    packet.order(ByteOrder.LITTLE_ENDIAN);

    int maskedAction = event.getActionMasked();
    // ACTION_UP, ACTION_POINTER_UP, ACTION_DOWN, and ACTION_POINTER_DOWN
    // only apply to a single pointer, other events apply to all pointers.
    if (maskedAction == MotionEvent.ACTION_UP || maskedAction == MotionEvent.ACTION_POINTER_UP
        || maskedAction == MotionEvent.ACTION_DOWN || maskedAction == MotionEvent.ACTION_POINTER_DOWN) {
      addPointerForIndex(event, event.getActionIndex(), packet);
    } else {
      // ACTION_MOVE may not actually mean all pointers have moved
      // but it's the responsibility of a later part of the system to
      // ignore 0-deltas if desired.
      for (int p = 0; p < pointerCount; p++) {
        addPointerForIndex(event, p, packet);
      }
    }

    // Verify that the packet is the expected size.
    assert packet.position() % (POINTER_DATA_FIELD_COUNT * BYTE_PER_FIELD) == 0;

    // Send the packet to Flutter.
    renderer.dispatchPointerDataPacket(packet, packet.position());

    return true;
  }

  // TODO(mattcarroll): consider creating a PointerPacket class instead of using a procedure that mutates inputs.
  private void addPointerForIndex(MotionEvent event, int pointerIndex, ByteBuffer packet) {
    int pointerChange = getPointerChangeForAction(event.getActionMasked());
    if (pointerChange == -1) {
      return;
    }

    int pointerKind = getPointerDeviceTypeForToolType(event.getToolType(pointerIndex));

    long timeStamp = event.getEventTime() * 1000; // Convert from milliseconds to microseconds.

    packet.putLong(timeStamp); // time_stamp
    packet.putLong(pointerChange); // change
    packet.putLong(pointerKind); // kind
    packet.putLong(event.getPointerId(pointerIndex)); // device
    packet.putDouble(event.getX(pointerIndex)); // physical_x
    packet.putDouble(event.getY(pointerIndex)); // physical_y

    if (pointerKind == POINTER_DEVICE_KIND_MOUSE) {
      packet.putLong(event.getButtonState() & 0x1F); // buttons
    } else if (pointerKind == POINTER_DEVICE_KIND_STYLUS) {
      packet.putLong((event.getButtonState() >> 4) & 0xF); // buttons
    } else {
      packet.putLong(0); // buttons
    }

    packet.putLong(0); // obscured

    // TODO(eseidel): Could get the calibrated range if necessary:
    // event.getDevice().getMotionRange(MotionEvent.AXIS_PRESSURE)
    packet.putDouble(event.getPressure(pointerIndex)); // pressure
    packet.putDouble(0.0); // pressure_min
    packet.putDouble(1.0); // pressure_max

    if (pointerKind == POINTER_DEVICE_KIND_STYLUS) {
      packet.putDouble(event.getAxisValue(MotionEvent.AXIS_DISTANCE, pointerIndex)); // distance
      packet.putDouble(0.0); // distance_max
    } else {
      packet.putDouble(0.0); // distance
      packet.putDouble(0.0); // distance_max
    }

    packet.putDouble(event.getToolMajor(pointerIndex)); // radius_major
    packet.putDouble(event.getToolMinor(pointerIndex)); // radius_minor

    packet.putDouble(0.0); // radius_min
    packet.putDouble(0.0); // radius_max

    packet.putDouble(event.getAxisValue(MotionEvent.AXIS_ORIENTATION, pointerIndex)); // orientation

    if (pointerKind == POINTER_DEVICE_KIND_STYLUS) {
      packet.putDouble(event.getAxisValue(MotionEvent.AXIS_TILT, pointerIndex)); // tilt
    } else {
      packet.putDouble(0.0); // tilt
    }
  }

  private int getPointerChangeForAction(int maskedAction) {
    // Primary pointer:
    if (maskedAction == MotionEvent.ACTION_DOWN) {
      return POINTER_CHANGE_DOWN;
    }
    if (maskedAction == MotionEvent.ACTION_UP) {
      return POINTER_CHANGE_UP;
    }
    // Secondary pointer:
    if (maskedAction == MotionEvent.ACTION_POINTER_DOWN) {
      return POINTER_CHANGE_DOWN;
    }
    if (maskedAction == MotionEvent.ACTION_POINTER_UP) {
      return POINTER_CHANGE_UP;
    }
    // All pointers:
    if (maskedAction == MotionEvent.ACTION_MOVE) {
      return POINTER_CHANGE_MOVE;
    }
    if (maskedAction == MotionEvent.ACTION_CANCEL) {
      return POINTER_CHANGE_CANCEL;
    }
    return -1;
  }

  // TODO(mattcarroll): introduce IntDef for toolType.
  private int getPointerDeviceTypeForToolType(int toolType) {
    switch (toolType) {
      case MotionEvent.TOOL_TYPE_FINGER:
        return POINTER_DEVICE_KIND_TOUCH;
      case MotionEvent.TOOL_TYPE_STYLUS:
        return POINTER_DEVICE_KIND_STYLUS;
      case MotionEvent.TOOL_TYPE_MOUSE:
        return POINTER_DEVICE_KIND_MOUSE;
      case MotionEvent.TOOL_TYPE_ERASER:
        return POINTER_DEVICE_KIND_INVERTED_STYLUS;
      default:
        // MotionEvent.TOOL_TYPE_UNKNOWN will reach here.
        return POINTER_DEVICE_KIND_UNKNOWN;
    }
  }
}
