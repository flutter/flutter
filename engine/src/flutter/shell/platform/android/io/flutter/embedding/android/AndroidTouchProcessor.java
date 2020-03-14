package io.flutter.embedding.android;

import android.os.Build;
import android.view.InputDevice;
import android.view.MotionEvent;
import androidx.annotation.IntDef;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;

/** Sends touch information from Android to Flutter in a format that Flutter understands. */
public class AndroidTouchProcessor {

  // Must match the PointerChange enum in pointer.dart.
  @IntDef({
    PointerChange.CANCEL,
    PointerChange.ADD,
    PointerChange.REMOVE,
    PointerChange.HOVER,
    PointerChange.DOWN,
    PointerChange.MOVE,
    PointerChange.UP
  })
  private @interface PointerChange {
    int CANCEL = 0;
    int ADD = 1;
    int REMOVE = 2;
    int HOVER = 3;
    int DOWN = 4;
    int MOVE = 5;
    int UP = 6;
  }

  // Must match the PointerDeviceKind enum in pointer.dart.
  @IntDef({
    PointerDeviceKind.TOUCH,
    PointerDeviceKind.MOUSE,
    PointerDeviceKind.STYLUS,
    PointerDeviceKind.INVERTED_STYLUS,
    PointerDeviceKind.UNKNOWN
  })
  private @interface PointerDeviceKind {
    int TOUCH = 0;
    int MOUSE = 1;
    int STYLUS = 2;
    int INVERTED_STYLUS = 3;
    int UNKNOWN = 4;
  }

  // Must match the PointerSignalKind enum in pointer.dart.
  @IntDef({PointerSignalKind.NONE, PointerSignalKind.SCROLL, PointerSignalKind.UNKNOWN})
  private @interface PointerSignalKind {
    int NONE = 0;
    int SCROLL = 1;
    int UNKNOWN = 2;
  }

  // Must match the unpacking code in hooks.dart.
  private static final int POINTER_DATA_FIELD_COUNT = 28;
  private static final int BYTES_PER_FIELD = 8;

  // This value must match the value in framework's platform_view.dart.
  // This flag indicates whether the original Android pointer events were batched together.
  private static final int POINTER_DATA_FLAG_BATCHED = 1;

  @NonNull private final FlutterRenderer renderer;

  private static final int _POINTER_BUTTON_PRIMARY = 1;

  /**
   * Constructs an {@code AndroidTouchProcessor} that will send touch event data to the Flutter
   * execution context represented by the given {@link FlutterRenderer}.
   */
  // TODO(mattcarroll): consider moving packet behavior to a FlutterInteractionSurface instead of
  // FlutterRenderer
  public AndroidTouchProcessor(@NonNull FlutterRenderer renderer) {
    this.renderer = renderer;
  }

  /** Sends the given {@link MotionEvent} data to Flutter in a format that Flutter understands. */
  public boolean onTouchEvent(@NonNull MotionEvent event) {
    int pointerCount = event.getPointerCount();

    // Prepare a data packet of the appropriate size and order.
    ByteBuffer packet =
        ByteBuffer.allocateDirect(pointerCount * POINTER_DATA_FIELD_COUNT * BYTES_PER_FIELD);
    packet.order(ByteOrder.LITTLE_ENDIAN);

    int maskedAction = event.getActionMasked();
    int pointerChange = getPointerChangeForAction(event.getActionMasked());
    boolean updateForSinglePointer =
        maskedAction == MotionEvent.ACTION_DOWN || maskedAction == MotionEvent.ACTION_POINTER_DOWN;
    boolean updateForMultiplePointers =
        !updateForSinglePointer
            && (maskedAction == MotionEvent.ACTION_UP
                || maskedAction == MotionEvent.ACTION_POINTER_UP);
    if (updateForSinglePointer) {
      // ACTION_DOWN and ACTION_POINTER_DOWN always apply to a single pointer only.
      addPointerForIndex(event, event.getActionIndex(), pointerChange, 0, packet);
    } else if (updateForMultiplePointers) {
      // ACTION_UP and ACTION_POINTER_UP may contain position updates for other pointers.
      // We are converting these updates to move events here in order to preserve this data.
      // We also mark these events with a flag in order to help the framework reassemble
      // the original Android event later, should it need to forward it to a PlatformView.
      for (int p = 0; p < pointerCount; p++) {
        if (p != event.getActionIndex() && event.getToolType(p) == MotionEvent.TOOL_TYPE_FINGER) {
          addPointerForIndex(event, p, PointerChange.MOVE, POINTER_DATA_FLAG_BATCHED, packet);
        }
      }
      // It's important that we're sending the UP event last. This allows PlatformView
      // to correctly batch everything back into the original Android event if needed.
      addPointerForIndex(event, event.getActionIndex(), pointerChange, 0, packet);
    } else {
      // ACTION_MOVE may not actually mean all pointers have moved
      // but it's the responsibility of a later part of the system to
      // ignore 0-deltas if desired.
      for (int p = 0; p < pointerCount; p++) {
        addPointerForIndex(event, p, pointerChange, 0, packet);
      }
    }

    // Verify that the packet is the expected size.
    if (packet.position() % (POINTER_DATA_FIELD_COUNT * BYTES_PER_FIELD) != 0) {
      throw new AssertionError("Packet position is not on field boundary");
    }

    // Send the packet to Flutter.
    renderer.dispatchPointerDataPacket(packet, packet.position());

    return true;
  }

  /**
   * Sends the given generic {@link MotionEvent} data to Flutter in a format that Flutter
   * understands.
   *
   * <p>Generic motion events include joystick movement, mouse hover, track pad touches, scroll
   * wheel movements, etc.
   */
  public boolean onGenericMotionEvent(@NonNull MotionEvent event) {
    // Method isFromSource is only available in API 18+ (Jelly Bean MR2)
    // Mouse hover support is not implemented for API < 18.
    boolean isPointerEvent =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2
            && event.isFromSource(InputDevice.SOURCE_CLASS_POINTER);
    boolean isMovementEvent =
        (event.getActionMasked() == MotionEvent.ACTION_HOVER_MOVE
            || event.getActionMasked() == MotionEvent.ACTION_SCROLL);
    if (!isPointerEvent || !isMovementEvent) {
      return false;
    }

    int pointerChange = getPointerChangeForAction(event.getActionMasked());
    ByteBuffer packet =
        ByteBuffer.allocateDirect(
            event.getPointerCount() * POINTER_DATA_FIELD_COUNT * BYTES_PER_FIELD);
    packet.order(ByteOrder.LITTLE_ENDIAN);

    // ACTION_HOVER_MOVE always applies to a single pointer only.
    addPointerForIndex(event, event.getActionIndex(), pointerChange, 0, packet);
    if (packet.position() % (POINTER_DATA_FIELD_COUNT * BYTES_PER_FIELD) != 0) {
      throw new AssertionError("Packet position is not on field boundary.");
    }
    renderer.dispatchPointerDataPacket(packet, packet.position());
    return true;
  }

  // TODO(mattcarroll): consider creating a PointerPacket class instead of using a procedure that
  // mutates inputs.
  private void addPointerForIndex(
      MotionEvent event, int pointerIndex, int pointerChange, int pointerData, ByteBuffer packet) {
    if (pointerChange == -1) {
      return;
    }

    int pointerKind = getPointerDeviceTypeForToolType(event.getToolType(pointerIndex));

    int signalKind =
        event.getActionMasked() == MotionEvent.ACTION_SCROLL
            ? PointerSignalKind.SCROLL
            : PointerSignalKind.NONE;

    long timeStamp = event.getEventTime() * 1000; // Convert from milliseconds to microseconds.

    packet.putLong(timeStamp); // time_stamp
    packet.putLong(pointerChange); // change
    packet.putLong(pointerKind); // kind
    packet.putLong(signalKind); // signal_kind
    packet.putLong(event.getPointerId(pointerIndex)); // device
    packet.putLong(0); // pointer_identifier, will be generated in pointer_data_packet_converter.cc.
    packet.putDouble(event.getX(pointerIndex)); // physical_x
    packet.putDouble(event.getY(pointerIndex)); // physical_y
    packet.putDouble(
        0.0); // physical_delta_x, will be generated in pointer_data_packet_converter.cc.
    packet.putDouble(
        0.0); // physical_delta_y, will be generated in pointer_data_packet_converter.cc.

    long buttons;
    if (pointerKind == PointerDeviceKind.MOUSE) {
      buttons = event.getButtonState() & 0x1F;
      // TODO(dkwingsmt): Remove this fix after implementing touchpad gestures
      // https://github.com/flutter/flutter/issues/23604#issuecomment-524471152
      if (buttons == 0
          && event.getSource() == InputDevice.SOURCE_MOUSE
          && (pointerChange == PointerChange.DOWN || pointerChange == PointerChange.MOVE)) {
        buttons = _POINTER_BUTTON_PRIMARY;
      }
    } else if (pointerKind == PointerDeviceKind.STYLUS) {
      buttons = (event.getButtonState() >> 4) & 0xF;
    } else {
      buttons = 0;
    }
    packet.putLong(buttons); // buttons

    packet.putLong(0); // obscured

    packet.putLong(0); // synthesized

    packet.putDouble(event.getPressure(pointerIndex)); // pressure
    double pressureMin = 0.0;
    double pressureMax = 1.0;
    if (event.getDevice() != null) {
      InputDevice.MotionRange pressureRange =
          event.getDevice().getMotionRange(MotionEvent.AXIS_PRESSURE);
      if (pressureRange != null) {
        pressureMin = pressureRange.getMin();
        pressureMax = pressureRange.getMax();
      }
    }
    packet.putDouble(pressureMin); // pressure_min
    packet.putDouble(pressureMax); // pressure_max

    if (pointerKind == PointerDeviceKind.STYLUS) {
      packet.putDouble(event.getAxisValue(MotionEvent.AXIS_DISTANCE, pointerIndex)); // distance
      packet.putDouble(0.0); // distance_max
    } else {
      packet.putDouble(0.0); // distance
      packet.putDouble(0.0); // distance_max
    }

    packet.putDouble(event.getSize(pointerIndex)); // size

    packet.putDouble(event.getToolMajor(pointerIndex)); // radius_major
    packet.putDouble(event.getToolMinor(pointerIndex)); // radius_minor

    packet.putDouble(0.0); // radius_min
    packet.putDouble(0.0); // radius_max

    packet.putDouble(event.getAxisValue(MotionEvent.AXIS_ORIENTATION, pointerIndex)); // orientation

    if (pointerKind == PointerDeviceKind.STYLUS) {
      packet.putDouble(event.getAxisValue(MotionEvent.AXIS_TILT, pointerIndex)); // tilt
    } else {
      packet.putDouble(0.0); // tilt
    }

    packet.putLong(pointerData); // platformData

    if (signalKind == PointerSignalKind.SCROLL) {
      packet.putDouble(-event.getAxisValue(MotionEvent.AXIS_HSCROLL)); // scroll_delta_x
      packet.putDouble(-event.getAxisValue(MotionEvent.AXIS_VSCROLL)); // scroll_delta_y
    } else {
      packet.putDouble(0.0); // scroll_delta_x
      packet.putDouble(0.0); // scroll_delta_x
    }
  }

  @PointerChange
  private int getPointerChangeForAction(int maskedAction) {
    // Primary pointer:
    if (maskedAction == MotionEvent.ACTION_DOWN) {
      return PointerChange.DOWN;
    }
    if (maskedAction == MotionEvent.ACTION_UP) {
      return PointerChange.UP;
    }
    // Secondary pointer:
    if (maskedAction == MotionEvent.ACTION_POINTER_DOWN) {
      return PointerChange.DOWN;
    }
    if (maskedAction == MotionEvent.ACTION_POINTER_UP) {
      return PointerChange.UP;
    }
    // All pointers:
    if (maskedAction == MotionEvent.ACTION_MOVE) {
      return PointerChange.MOVE;
    }
    if (maskedAction == MotionEvent.ACTION_HOVER_MOVE) {
      return PointerChange.HOVER;
    }
    if (maskedAction == MotionEvent.ACTION_CANCEL) {
      return PointerChange.CANCEL;
    }
    if (maskedAction == MotionEvent.ACTION_SCROLL) {
      return PointerChange.HOVER;
    }
    return -1;
  }

  @PointerDeviceKind
  private int getPointerDeviceTypeForToolType(int toolType) {
    switch (toolType) {
      case MotionEvent.TOOL_TYPE_FINGER:
        return PointerDeviceKind.TOUCH;
      case MotionEvent.TOOL_TYPE_STYLUS:
        return PointerDeviceKind.STYLUS;
      case MotionEvent.TOOL_TYPE_MOUSE:
        return PointerDeviceKind.MOUSE;
      case MotionEvent.TOOL_TYPE_ERASER:
        return PointerDeviceKind.INVERTED_STYLUS;
      default:
        // MotionEvent.TOOL_TYPE_UNKNOWN will reach here.
        return PointerDeviceKind.UNKNOWN;
    }
  }
}
