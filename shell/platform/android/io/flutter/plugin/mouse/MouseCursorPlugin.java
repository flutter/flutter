// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.mouse;

import android.annotation.TargetApi;
import android.os.Build;
import android.view.PointerIcon;
import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import io.flutter.embedding.engine.systemchannels.MouseCursorChannel;
import java.util.HashMap;

/** A mandatory plugin that handles mouse cursor requests. */
@TargetApi(Build.VERSION_CODES.N)
@RequiresApi(Build.VERSION_CODES.N)
public class MouseCursorPlugin {
  @NonNull private final MouseCursorViewDelegate mView;
  @NonNull private final MouseCursorChannel mouseCursorChannel;

  public MouseCursorPlugin(
      @NonNull MouseCursorViewDelegate view, @NonNull MouseCursorChannel mouseCursorChannel) {
    mView = view;

    this.mouseCursorChannel = mouseCursorChannel;
    mouseCursorChannel.setMethodHandler(
        new MouseCursorChannel.MouseCursorMethodHandler() {
          @Override
          public void activateSystemCursor(@NonNull String kind) {
            mView.setPointerIcon(resolveSystemCursor(kind));
          }
        });
  }

  /**
   * Return a pointer icon object for a system cursor.
   *
   * <p>This method guarantees to return a non-null object.
   */
  private PointerIcon resolveSystemCursor(@NonNull String kind) {
    if (MouseCursorPlugin.systemCursorConstants == null) {
      // Initialize the map when first used, because the map can grow big in the future (~70)
      // and most mobile devices will not use them.
      MouseCursorPlugin.systemCursorConstants =
          new HashMap<String, Integer>() {
            private static final long serialVersionUID = 1L;

            {
              put("none", Integer.valueOf(PointerIcon.TYPE_NULL));
              //  "basic": default
              put("click", Integer.valueOf(PointerIcon.TYPE_HAND));
              put("text", Integer.valueOf(PointerIcon.TYPE_TEXT));
              //  "forbidden": default
              put("grab", Integer.valueOf(PointerIcon.TYPE_GRAB));
              put("grabbing", Integer.valueOf(PointerIcon.TYPE_GRABBING));
              put(
                  "horizontalDoubleArrow",
                  Integer.valueOf(PointerIcon.TYPE_HORIZONTAL_DOUBLE_ARROW));
              put("verticalDoubleArrow", Integer.valueOf(PointerIcon.TYPE_VERTICAL_DOUBLE_ARROW));
            }
          };
    }

    final int cursorConstant =
        MouseCursorPlugin.systemCursorConstants.getOrDefault(kind, PointerIcon.TYPE_ARROW);
    return mView.getSystemPointerIcon(cursorConstant);
  }

  /**
   * Detaches the text input plugin from the platform views controller.
   *
   * <p>The MouseCursorPlugin instance should not be used after calling this.
   */
  public void destroy() {
    mouseCursorChannel.setMethodHandler(null);
  }

  /**
   * A map from Flutter's system cursor {@code kind} to Android's pointer icon constants.
   *
   * <p>It is null until the first time a system cursor is requested, at which time it is filled
   * with the entire mapping.
   */
  @NonNull private static HashMap<String, Integer> systemCursorConstants;

  /**
   * Delegate interface for requesting the system to display a pointer icon object.
   *
   * <p>Typically implemented by an {@link android.view.View}, such as a {@code FlutterView}.
   */
  public interface MouseCursorViewDelegate {
    /**
     * Gets a system pointer icon object for the given {@code type}.
     *
     * <p>If typeis not recognized, returns the default pointer icon.
     *
     * <p>This is typically implemented by calling {@link android.view.PointerIcon.getSystemIcon}
     * with the context associated with this view.
     */
    public PointerIcon getSystemPointerIcon(int type);

    /**
     * Request the pointer to display the specified icon object.
     *
     * <p>If the delegate is implemented by a {@link android.view.View}, then this method is
     * automatically implemented by View.
     */
    public void setPointerIcon(@NonNull PointerIcon icon);
  }
}
