package io.flutter.embedding.android;

import android.graphics.Matrix;
import android.os.Build;
import android.view.InputDevice;
import android.view.MotionEvent;
import androidx.annotation.IntDef;
import androidx.annotation.NonNull;
import androidx.annotation.VisibleForTesting;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.HashMap;
import java.util.Map;

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
    PointerChange.UP,
    PointerChange.PAN_ZOOM_START,
    PointerChange.PAN_ZOOM_UPDATE,
    PointerChange.PAN_ZOOM_END
  })
  public @interface PointerChange {
    int CANCEL = 0;
    int ADD = 1;
    int REMOVE = 2;
    int HOVER = 3;
    int DOWN = 4;
    int MOVE = 5;
    int UP = 6;
    int PAN_ZOOM_START = 7;
    int PAN_ZOOM_UPDATE = 8;
    int PAN_ZOOM_END = 9;
  }

  // Must match the PointerDeviceKind enum in pointer.dart.
  @IntDef({
    PointerDeviceKind.TOUCH,
    PointerDeviceKind.MOUSE,
    PointerDeviceKind.STYLUS,
    PointerDeviceKind.INVERTED_STYLUS,
    PointerDeviceKind.TRACKPAD,
    PointerDeviceKind.UNKNOWN
  })
  public @interface PointerDeviceKind {
    int TOUCH = 0;
    int MOUSE = 1;
    int STYLUS = 2;
    int INVERTED_STYLUS = 3;
    int TRACKPAD = 4;
    int UNKNOWN = 5;
  }

  // Must match the PointerSignalKind enum in pointer.dart.
  @IntDef({PointerSignalKind.NONE, PointerSignalKind.SCROLL, PointerSignalKind.UNKNOWN})
  public @interface PointerSignalKind {
    int NONE = 0;
    int SCROLL = 1;
    int UNKNOWN = 2;
  }

  // Must match the unpacking code in hooks.dart.
  private static final int POINTER_DATA_FIELD_COUNT = 35;
  @VisibleForTesting static final int BYTES_PER_FIELD = 8;

  // This value must match the value in framework's platform_view.dart.
  // This flag indicates whether the original Android pointer events were batched together.
  private static final int POINTER_DATA_FLAG_BATCHED = 1;

  @NonNull private final FlutterRenderer renderer;
  @NonNull private final MotionEventTracker motionEventTracker;

  private static final Matrix IDENTITY_TRANSFORM = new Matrix();

  private final boolean trackMotionEvents;

  private final Map<Integer, float[]> ongoingPans = new HashMap<>();

  /**
   * Constructs an {@code AndroidTouchProcessor} that will send touch event data to the Flutter
   * execution context represented by the given {@link FlutterRenderer}.
   *
   * @param renderer The object that manages textures for rendering.
   * @param trackMotionEvents This is used to query motion events when platform views are rendered.
   */
  // TODO(mattcarroll): consider moving packet behavior to a FlutterInteractionSurface instead of
  // FlutterRenderer
  public AndroidTouchProcessor(@NonNull FlutterRenderer renderer, boolean trackMotionEvents) {
    this.renderer = renderer;
    this.motionEventTracker = MotionEventTracker.getInstance();
    this.trackMotionEvents = trackMotionEvents;
  }

  public boolean onTouchEvent(@NonNull MotionEvent event) {
    return onTouchEvent(event, IDENTITY_TRANSFORM);
  }

  /**
   * Sends the given {@link MotionEvent} data to Flutter in a format that Flutter understands.
   *
   * @param event The motion event from the view.
   * @param transformMatrix Applies to the view that originated the event. It's used to transform
   *     the gesture pointers into screen coordinates.
   * @return True if the event was handled.
   */
  public boolean onTouchEvent(@NonNull MotionEvent event, @NonNull Matrix transformMatrix) {
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
      addPointerForIndex(event, event.getActionIndex(), pointerChange, 0, transformMatrix, packet);
    } else if (updateForMultiplePointers) {
      // ACTION_UP and ACTION_POINTER_UP may contain position updates for other pointers.
      // We are converting these updates to move events here in order to preserve this data.
      // We also mark these events with a flag in order to help the framework reassemble
      // the original Android event later, should it need to forward it to a PlatformView.
      for (int p = 0; p < pointerCount; p++) {
        if (p != event.getActionIndex() && event.getToolType(p) == MotionEvent.TOOL_TYPE_FINGER) {
          addPointerForIndex(
              event, p, PointerChange.MOVE, POINTER_DATA_FLAG_BATCHED, transformMatrix, packet);
        }
      }
      // It's important that we're sending the UP event last. This allows PlatformView
      // to correctly batch everything back into the original Android event if needed.
      addPointerForIndex(event, event.getActionIndex(), pointerChange, 0, transformMatrix, packet);
    } else {
      // ACTION_MOVE may not actually mean all pointers have moved
      // but it's the responsibility of a later part of the system to
      // ignore 0-deltas if desired.
      for (int p = 0; p < pointerCount; p++) {
        addPointerForIndex(event, p, pointerChange, 0, transformMatrix, packet);
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
   *
   * @param event The generic motion event being processed.
   * @return True if the event was handled.
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
    addPointerForIndex(event, event.getActionIndex(), pointerChange, 0, IDENTITY_TRANSFORM, packet);
    if (packet.position() % (POINTER_DATA_FIELD_COUNT * BYTES_PER_FIELD) != 0) {
      throw new AssertionError("Packet position is not on field boundary.");
    }
    renderer.dispatchPointerDataPacket(packet, packet.position());
    return true;
  }

  // TODO(mattcarroll): consider creating a PointerPacket class instead of using a procedure that
  // mutates inputs.
  private void addPointerForIndex(
      MotionEvent event,
      int pointerIndex,
      int pointerChange,
      int pointerData,
      Matrix transformMatrix,
      ByteBuffer packet) {
    if (pointerChange == -1) {
      return;
    }

    long motionEventId = 0;
    if (trackMotionEvents) {
      MotionEventTracker.MotionEventId trackedEvent = motionEventTracker.track(event);
      motionEventId = trackedEvent.getId();
    }

    int pointerKind = getPointerDeviceTypeForToolType(event.getToolType(pointerIndex));
    // We use this in lieu of using event.getRawX and event.getRawY as we wish to support
    // earlier versions than API level 29.
    float viewToScreenCoords[] = {event.getX(pointerIndex), event.getY(pointerIndex)};
    transformMatrix.mapPoints(viewToScreenCoords);
    long buttons;
    if (pointerKind == PointerDeviceKind.MOUSE) {
      buttons = event.getButtonState() & 0x1F;
      if (buttons == 0
          && event.getSource() == InputDevice.SOURCE_MOUSE
          && pointerChange == PointerChange.DOWN) {
        // Some implementations translate trackpad scrolling into a mouse down-move-up event
        // sequence with buttons: 0, such as ARC on a Chromebook. See #11420, a legacy
        // implementation that uses the same condition but converts differently.
        ongoingPans.put(event.getPointerId(pointerIndex), viewToScreenCoords);
      }
    } else if (pointerKind == PointerDeviceKind.STYLUS) {
      buttons = (event.getButtonState() >> 4) & 0xF;
    } else {
      buttons = 0;
    }

    boolean isTrackpadPan = ongoingPans.containsKey(event.getPointerId(pointerIndex));

    int signalKind =
        event.getActionMasked() == MotionEvent.ACTION_SCROLL
            ? PointerSignalKind.SCROLL
            : PointerSignalKind.NONE;

    long timeStamp = event.getEventTime() * 1000; // Convert from milliseconds to microseconds.

    packet.putLong(motionEventId); // motionEventId
    packet.putLong(timeStamp); // time_stamp
    if (isTrackpadPan) {
      packet.putLong(getPointerChangeForPanZoom(pointerChange)); // change
      packet.putLong(PointerDeviceKind.TRACKPAD); // kind
    } else {
      packet.putLong(pointerChange); // change
      packet.putLong(pointerKind); // kind
    }
    packet.putLong(signalKind); // signal_kind
    packet.putLong(event.getPointerId(pointerIndex)); // device
    packet.putLong(0); // pointer_identifier, will be generated in pointer_data_packet_converter.cc.

    if (isTrackpadPan) {
      float[] panStart = ongoingPans.get(event.getPointerId(pointerIndex));
      packet.putDouble(panStart[0]);
      packet.putDouble(panStart[1]);
    } else {
      packet.putDouble(viewToScreenCoords[0]); // physical_x
      packet.putDouble(viewToScreenCoords[1]); // physical_y
    }

    packet.putDouble(
        0.0); // physical_delta_x, will be generated in pointer_data_packet_converter.cc.
    packet.putDouble(
        0.0); // physical_delta_y, will be generated in pointer_data_packet_converter.cc.

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

    if (isTrackpadPan) {
      float[] panStart = ongoingPans.get(event.getPointerId(pointerIndex));
      packet.putDouble(viewToScreenCoords[0] - panStart[0]);
      packet.putDouble(viewToScreenCoords[1] - panStart[1]);
    } else {
      packet.putDouble(0.0); // pan_x
      packet.putDouble(0.0); // pan_y
    }
    packet.putDouble(0.0); // pan_delta_x
    packet.putDouble(0.0); // pan_delta_y
    packet.putDouble(1.0); // scale
    packet.putDouble(0.0); // rotation

    if (isTrackpadPan && getPointerChangeForPanZoom(pointerChange) == PointerChange.PAN_ZOOM_END) {
      ongoingPans.remove(event.getPointerId(pointerIndex));
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
    throw new AssertionError("Unexpected masked action");
  }

  @PointerChange
  private int getPointerChangeForPanZoom(int pointerChange) {
    if (pointerChange == PointerChange.DOWN) {
      return PointerChange.PAN_ZOOM_START;
    } else if (pointerChange == PointerChange.MOVE) {
      return PointerChange.PAN_ZOOM_UPDATE;
    } else if (pointerChange == PointerChange.UP || pointerChange == PointerChange.CANCEL) {
      return PointerChange.PAN_ZOOM_END;
    }
    throw new AssertionError("Unexpected pointer change");
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
