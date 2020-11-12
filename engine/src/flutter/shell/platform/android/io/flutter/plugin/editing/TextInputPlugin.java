// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.editing;

import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.Rect;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.text.Editable;
import android.text.InputType;
import android.util.SparseArray;
import android.view.View;
import android.view.ViewStructure;
import android.view.WindowInsets;
import android.view.autofill.AutofillId;
import android.view.autofill.AutofillManager;
import android.view.autofill.AutofillValue;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputConnection;
import android.view.inputmethod.InputMethodManager;
import android.view.inputmethod.InputMethodSubtype;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import io.flutter.Log;
import io.flutter.embedding.android.AndroidKeyProcessor;
import io.flutter.embedding.engine.systemchannels.TextInputChannel;
import io.flutter.embedding.engine.systemchannels.TextInputChannel.TextEditState;
import io.flutter.plugin.platform.PlatformViewsController;
import java.util.HashMap;

/** Android implementation of the text input plugin. */
public class TextInputPlugin implements ListenableEditingState.EditingStateWatcher {
  private static final String TAG = "TextInputPlugin";

  @NonNull private final View mView;
  @NonNull private final InputMethodManager mImm;
  @NonNull private final AutofillManager afm;
  @NonNull private final TextInputChannel textInputChannel;
  @NonNull private InputTarget inputTarget = new InputTarget(InputTarget.Type.NO_TARGET, 0);
  @Nullable private TextInputChannel.Configuration configuration;
  @Nullable private SparseArray<TextInputChannel.Configuration> mAutofillConfigurations;
  @Nullable private ListenableEditingState mEditable;
  private boolean mRestartInputPending;
  @Nullable private InputConnection lastInputConnection;
  @NonNull private PlatformViewsController platformViewsController;
  @Nullable private Rect lastClientRect;
  private final boolean restartAlwaysRequired;
  private ImeSyncDeferringInsetsCallback imeSyncCallback;
  private AndroidKeyProcessor keyProcessor;

  // Initialize the "last seen" text editing values to a non-null value.
  private TextEditState mLastKnownFrameworkTextEditingState;

  // When true following calls to createInputConnection will return the cached lastInputConnection
  // if the input
  // target is a platform view. See the comments on lockPlatformViewInputConnection for more
  // details.
  private boolean isInputConnectionLocked;

  @SuppressLint("NewApi")
  public TextInputPlugin(
      View view,
      @NonNull TextInputChannel textInputChannel,
      @NonNull PlatformViewsController platformViewsController) {
    mView = view;
    mImm = (InputMethodManager) view.getContext().getSystemService(Context.INPUT_METHOD_SERVICE);
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      afm = view.getContext().getSystemService(AutofillManager.class);
    } else {
      afm = null;
    }

    // Sets up syncing ime insets with the framework, allowing
    // the Flutter view to grow and shrink to accomodate Android
    // controlled keyboard animations.
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
      int mask = 0;
      if ((View.SYSTEM_UI_FLAG_HIDE_NAVIGATION & mView.getWindowSystemUiVisibility()) == 0) {
        mask = mask | WindowInsets.Type.navigationBars();
      }
      if ((View.SYSTEM_UI_FLAG_FULLSCREEN & mView.getWindowSystemUiVisibility()) == 0) {
        mask = mask | WindowInsets.Type.statusBars();
      }
      imeSyncCallback =
          new ImeSyncDeferringInsetsCallback(
              view,
              mask, // Overlay, insets that should be merged with the deferred insets
              WindowInsets.Type.ime() // Deferred, insets that will animate
              );
      imeSyncCallback.install();
    }

    this.textInputChannel = textInputChannel;
    textInputChannel.setTextInputMethodHandler(
        new TextInputChannel.TextInputMethodHandler() {
          @Override
          public void show() {
            showTextInput(mView);
          }

          @Override
          public void hide() {
            hideTextInput(mView);
          }

          @Override
          public void requestAutofill() {
            notifyViewEntered();
          }

          @Override
          public void finishAutofillContext(boolean shouldSave) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O || afm == null) {
              return;
            }
            if (shouldSave) {
              afm.commit();
            } else {
              afm.cancel();
            }
          }

          @Override
          public void setClient(
              int textInputClientId, TextInputChannel.Configuration configuration) {
            setTextInputClient(textInputClientId, configuration);
          }

          @Override
          public void setPlatformViewClient(int platformViewId) {
            setPlatformViewTextInputClient(platformViewId);
          }

          @Override
          public void setEditingState(TextInputChannel.TextEditState editingState) {
            setTextInputEditingState(mView, editingState);
          }

          @Override
          public void setEditableSizeAndTransform(double width, double height, double[] transform) {
            saveEditableSizeAndTransform(width, height, transform);
          }

          @Override
          public void clearClient() {
            clearTextInputClient();
          }

          @Override
          public void sendAppPrivateCommand(String action, Bundle data) {
            sendTextInputAppPrivateCommand(action, data);
          }
        });

    textInputChannel.requestExistingInputState();

    this.platformViewsController = platformViewsController;
    this.platformViewsController.attachTextInputPlugin(this);
    restartAlwaysRequired = isRestartAlwaysRequired();
  }

  @NonNull
  public InputMethodManager getInputMethodManager() {
    return mImm;
  }

  @VisibleForTesting
  Editable getEditable() {
    return mEditable;
  }

  @VisibleForTesting
  ImeSyncDeferringInsetsCallback getImeSyncCallback() {
    return imeSyncCallback;
  }

  @NonNull
  public AndroidKeyProcessor getKeyEventProcessor() {
    return keyProcessor;
  }

  public void setKeyEventProcessor(AndroidKeyProcessor processor) {
    keyProcessor = processor;
  }

  /**
   * Use the current platform view input connection until unlockPlatformViewInputConnection is
   * called.
   *
   * <p>The current input connection instance is cached and any following call to @{link
   * createInputConnection} returns the cached connection until unlockPlatformViewInputConnection is
   * called.
   *
   * <p>This is a no-op if the current input target isn't a platform view.
   *
   * <p>This is used to preserve an input connection when moving a platform view from one virtual
   * display to another.
   */
  public void lockPlatformViewInputConnection() {
    if (inputTarget.type == InputTarget.Type.PLATFORM_VIEW) {
      isInputConnectionLocked = true;
    }
  }

  /**
   * Unlocks the input connection.
   *
   * <p>See also: @{link lockPlatformViewInputConnection}.
   */
  public void unlockPlatformViewInputConnection() {
    isInputConnectionLocked = false;
  }

  /**
   * Detaches the text input plugin from the platform views controller.
   *
   * <p>The TextInputPlugin instance should not be used after calling this.
   */
  @SuppressLint("NewApi")
  public void destroy() {
    platformViewsController.detachTextInputPlugin();
    textInputChannel.setTextInputMethodHandler(null);
    notifyViewExited();
    if (mEditable != null) {
      mEditable.removeEditingStateListener(this);
    }
    if (imeSyncCallback != null) {
      imeSyncCallback.remove();
    }
  }

  private static int inputTypeFromTextInputType(
      TextInputChannel.InputType type,
      boolean obscureText,
      boolean autocorrect,
      boolean enableSuggestions,
      TextInputChannel.TextCapitalization textCapitalization) {
    if (type.type == TextInputChannel.TextInputType.DATETIME) {
      return InputType.TYPE_CLASS_DATETIME;
    } else if (type.type == TextInputChannel.TextInputType.NUMBER) {
      int textType = InputType.TYPE_CLASS_NUMBER;
      if (type.isSigned) {
        textType |= InputType.TYPE_NUMBER_FLAG_SIGNED;
      }
      if (type.isDecimal) {
        textType |= InputType.TYPE_NUMBER_FLAG_DECIMAL;
      }
      return textType;
    } else if (type.type == TextInputChannel.TextInputType.PHONE) {
      return InputType.TYPE_CLASS_PHONE;
    }

    int textType = InputType.TYPE_CLASS_TEXT;
    if (type.type == TextInputChannel.TextInputType.MULTILINE) {
      textType |= InputType.TYPE_TEXT_FLAG_MULTI_LINE;
    } else if (type.type == TextInputChannel.TextInputType.EMAIL_ADDRESS) {
      textType |= InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS;
    } else if (type.type == TextInputChannel.TextInputType.URL) {
      textType |= InputType.TYPE_TEXT_VARIATION_URI;
    } else if (type.type == TextInputChannel.TextInputType.VISIBLE_PASSWORD) {
      textType |= InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD;
    } else if (type.type == TextInputChannel.TextInputType.NAME) {
      textType |= InputType.TYPE_TEXT_VARIATION_PERSON_NAME;
    } else if (type.type == TextInputChannel.TextInputType.POSTAL_ADDRESS) {
      textType |= InputType.TYPE_TEXT_VARIATION_POSTAL_ADDRESS;
    }

    if (obscureText) {
      // Note: both required. Some devices ignore TYPE_TEXT_FLAG_NO_SUGGESTIONS.
      textType |= InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS;
      textType |= InputType.TYPE_TEXT_VARIATION_PASSWORD;
    } else {
      if (autocorrect) textType |= InputType.TYPE_TEXT_FLAG_AUTO_CORRECT;
      if (!enableSuggestions) textType |= InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS;
    }

    if (textCapitalization == TextInputChannel.TextCapitalization.CHARACTERS) {
      textType |= InputType.TYPE_TEXT_FLAG_CAP_CHARACTERS;
    } else if (textCapitalization == TextInputChannel.TextCapitalization.WORDS) {
      textType |= InputType.TYPE_TEXT_FLAG_CAP_WORDS;
    } else if (textCapitalization == TextInputChannel.TextCapitalization.SENTENCES) {
      textType |= InputType.TYPE_TEXT_FLAG_CAP_SENTENCES;
    }

    return textType;
  }

  public InputConnection createInputConnection(View view, EditorInfo outAttrs) {
    if (inputTarget.type == InputTarget.Type.NO_TARGET) {
      lastInputConnection = null;
      return null;
    }

    if (inputTarget.type == InputTarget.Type.PLATFORM_VIEW) {
      if (isInputConnectionLocked) {
        return lastInputConnection;
      }
      lastInputConnection =
          platformViewsController
              .getPlatformViewById(inputTarget.id)
              .onCreateInputConnection(outAttrs);
      return lastInputConnection;
    }

    outAttrs.inputType =
        inputTypeFromTextInputType(
            configuration.inputType,
            configuration.obscureText,
            configuration.autocorrect,
            configuration.enableSuggestions,
            configuration.textCapitalization);
    outAttrs.imeOptions = EditorInfo.IME_FLAG_NO_FULLSCREEN;
    int enterAction;
    if (configuration.inputAction == null) {
      // If an explicit input action isn't set, then default to none for multi-line fields
      // and done for single line fields.
      enterAction =
          (InputType.TYPE_TEXT_FLAG_MULTI_LINE & outAttrs.inputType) != 0
              ? EditorInfo.IME_ACTION_NONE
              : EditorInfo.IME_ACTION_DONE;
    } else {
      enterAction = configuration.inputAction;
    }
    if (configuration.actionLabel != null) {
      outAttrs.actionLabel = configuration.actionLabel;
      outAttrs.actionId = enterAction;
    }
    outAttrs.imeOptions |= enterAction;

    InputConnectionAdaptor connection =
        new InputConnectionAdaptor(
            view, inputTarget.id, textInputChannel, keyProcessor, mEditable, outAttrs);
    outAttrs.initialSelStart = mEditable.getSelectionStart();
    outAttrs.initialSelEnd = mEditable.getSelectionEnd();

    lastInputConnection = connection;
    return lastInputConnection;
  }

  @Nullable
  public InputConnection getLastInputConnection() {
    return lastInputConnection;
  }

  /**
   * Clears a platform view text input client if it is the current input target.
   *
   * <p>This is called when a platform view is disposed to make sure we're not hanging to a stale
   * input connection.
   */
  public void clearPlatformViewClient(int platformViewId) {
    if (inputTarget.type == InputTarget.Type.PLATFORM_VIEW && inputTarget.id == platformViewId) {
      inputTarget = new InputTarget(InputTarget.Type.NO_TARGET, 0);
      hideTextInput(mView);
      mImm.restartInput(mView);
      mRestartInputPending = false;
    }
  }

  public void sendTextInputAppPrivateCommand(String action, Bundle data) {
    mImm.sendAppPrivateCommand(mView, action, data);
  }

  private void showTextInput(View view) {
    view.requestFocus();
    mImm.showSoftInput(view, 0);
  }

  private void hideTextInput(View view) {
    notifyViewExited();
    // Note: a race condition may lead to us hiding the keyboard here just after a platform view has
    // shown it.
    // This can only potentially happen when switching focus from a Flutter text field to a platform
    // view's text
    // field(by text field here I mean anything that keeps the keyboard open).
    // See: https://github.com/flutter/flutter/issues/34169
    mImm.hideSoftInputFromWindow(view.getApplicationWindowToken(), 0);
  }

  @VisibleForTesting
  void setTextInputClient(int client, TextInputChannel.Configuration configuration) {
    // Call notifyViewExited on the previous field.
    notifyViewExited();
    inputTarget = new InputTarget(InputTarget.Type.FRAMEWORK_CLIENT, client);

    if (mEditable != null) {
      mEditable.removeEditingStateListener(this);
    }
    mEditable =
        new ListenableEditingState(
            configuration.autofill != null ? configuration.autofill.editState : null, mView);
    this.configuration = configuration;
    updateAutofillConfigurationIfNeeded(configuration);

    // setTextInputClient will be followed by a call to setTextInputEditingState.
    // Do a restartInput at that time.
    mRestartInputPending = true;
    unlockPlatformViewInputConnection();
    lastClientRect = null;
    mEditable.addEditingStateListener(this);
  }

  private void setPlatformViewTextInputClient(int platformViewId) {
    // We need to make sure that the Flutter view is focused so that no imm operations get short
    // circuited.
    // Not asking for focus here specifically manifested in a but on API 28 devices where the
    // platform view's
    // request to show a keyboard was ignored.
    mView.requestFocus();
    inputTarget = new InputTarget(InputTarget.Type.PLATFORM_VIEW, platformViewId);
    mImm.restartInput(mView);
    mRestartInputPending = false;
  }

  @VisibleForTesting
  void setTextInputEditingState(View view, TextInputChannel.TextEditState state) {
    mLastKnownFrameworkTextEditingState = state;
    mEditable.setEditingState(state);

    // Restart if there is a pending restart or the device requires a force restart
    // (see isRestartAlwaysRequired). Restarting will also update the selection.
    if (restartAlwaysRequired || mRestartInputPending) {
      mImm.restartInput(view);
      mRestartInputPending = false;
    }
  }

  private interface MinMax {
    void inspect(double x, double y);
  }

  private void saveEditableSizeAndTransform(double width, double height, double[] matrix) {
    final double[] minMax = new double[4]; // minX, maxX, minY, maxY.
    final boolean isAffine = matrix[3] == 0 && matrix[7] == 0 && matrix[15] == 1;
    minMax[0] = minMax[1] = matrix[12] / matrix[15]; // minX and maxX.
    minMax[2] = minMax[3] = matrix[13] / matrix[15]; // minY and maxY.

    final MinMax finder =
        new MinMax() {
          @Override
          public void inspect(double x, double y) {
            final double w = isAffine ? 1 : 1 / (matrix[3] * x + matrix[7] * y + matrix[15]);
            final double tx = (matrix[0] * x + matrix[4] * y + matrix[12]) * w;
            final double ty = (matrix[1] * x + matrix[5] * y + matrix[13]) * w;

            if (tx < minMax[0]) {
              minMax[0] = tx;
            } else if (tx > minMax[1]) {
              minMax[1] = tx;
            }

            if (ty < minMax[2]) {
              minMax[2] = ty;
            } else if (ty > minMax[3]) {
              minMax[3] = ty;
            }
          }
        };

    finder.inspect(width, 0);
    finder.inspect(width, height);
    finder.inspect(0, height);
    final Float density = mView.getContext().getResources().getDisplayMetrics().density;
    lastClientRect =
        new Rect(
            (int) (minMax[0] * density),
            (int) (minMax[2] * density),
            (int) Math.ceil(minMax[1] * density),
            (int) Math.ceil(minMax[3] * density));
  }

  // Samsung's Korean keyboard has a bug where it always attempts to combine characters based on
  // its internal state, ignoring if and when the cursor is moved programmatically. The same bug
  // also causes non-korean keyboards to occasionally duplicate text when tapping in the middle
  // of existing text to edit it.
  //
  // Fully restarting the IMM works around this because it flushes the keyboard's internal state
  // and stops it from trying to incorrectly combine characters. However this also has some
  // negative performance implications, so we don't want to apply this workaround in every case.
  @SuppressLint("NewApi") // New API guard is inline, the linter can't see it.
  @SuppressWarnings("deprecation")
  private boolean isRestartAlwaysRequired() {
    InputMethodSubtype subtype = mImm.getCurrentInputMethodSubtype();
    // Impacted devices all shipped with Android Lollipop or newer.
    if (subtype == null
        || Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP
        || !Build.MANUFACTURER.equals("samsung")) {
      return false;
    }
    String keyboardName =
        Settings.Secure.getString(
            mView.getContext().getContentResolver(), Settings.Secure.DEFAULT_INPUT_METHOD);
    // The Samsung keyboard is called "com.sec.android.inputmethod/.SamsungKeypad" but look
    // for "Samsung" just in case Samsung changes the name of the keyboard.
    return keyboardName.contains("Samsung");
  }

  @VisibleForTesting
  void clearTextInputClient() {
    if (inputTarget.type == InputTarget.Type.PLATFORM_VIEW) {
      // Focus changes in the framework tree have no guarantees on the order focus nodes are
      // notified. A node
      // that lost focus may be notified before or after a node that gained focus.
      // When moving the focus from a Flutter text field to an AndroidView, it is possible that the
      // Flutter text
      // field's focus node will be notified that it lost focus after the AndroidView was notified
      // that it gained
      // focus. When this happens the text field will send a clearTextInput command which we ignore.
      // By doing this we prevent the framework from clearing a platform view input client (the only
      // way to do so
      // is to set a new framework text client). I don't see an obvious use case for "clearing" a
      // platform view's
      // text input client, and it may be error prone as we don't know how the platform view manages
      // the input
      // connection and we probably shouldn't interfere.
      // If we ever want to allow the framework to clear a platform view text client we should
      // probably consider
      // changing the focus manager such that focus nodes that lost focus are notified before focus
      // nodes that
      // gained focus as part of the same focus event.
      return;
    }
    mEditable.removeEditingStateListener(this);
    notifyViewExited();
    updateAutofillConfigurationIfNeeded(null);
    inputTarget = new InputTarget(InputTarget.Type.NO_TARGET, 0);
    unlockPlatformViewInputConnection();
    lastClientRect = null;
  }

  private static class InputTarget {
    enum Type {
      NO_TARGET,
      // InputConnection is managed by the TextInputPlugin, and events are forwarded to the Flutter
      // framework.
      FRAMEWORK_CLIENT,
      // InputConnection is managed by an embedded platform view.
      PLATFORM_VIEW
    }

    public InputTarget(@NonNull Type type, int id) {
      this.type = type;
      this.id = id;
    }

    @NonNull Type type;
    // The ID of the input target.
    //
    // For framework clients this is the framework input connection client ID.
    // For platform views this is the platform view's ID.
    int id;
  }

  // -------- Start: ListenableEditingState watcher implementation -------

  @Override
  public void didChangeEditingState(
      boolean textChanged, boolean selectionChanged, boolean composingRegionChanged) {
    if (textChanged) {
      // Notify the autofill manager of the value change.
      notifyValueChanged(mEditable.toString());
    }

    final int selectionStart = mEditable.getSelectionStart();
    final int selectionEnd = mEditable.getSelectionEnd();
    final int composingStart = mEditable.getComposingStart();
    final int composingEnd = mEditable.getComposingEnd();
    // Framework needs to sent value first.
    final boolean skipFrameworkUpdate =
        mLastKnownFrameworkTextEditingState == null
            || (mEditable.toString().equals(mLastKnownFrameworkTextEditingState.text)
                && selectionStart == mLastKnownFrameworkTextEditingState.selectionStart
                && selectionEnd == mLastKnownFrameworkTextEditingState.selectionEnd
                && composingStart == mLastKnownFrameworkTextEditingState.composingStart
                && composingEnd == mLastKnownFrameworkTextEditingState.composingEnd);
    // Skip if we're currently setting
    if (!skipFrameworkUpdate) {
      Log.v(TAG, "send EditingState to flutter: " + mEditable.toString());
      textInputChannel.updateEditingState(
          inputTarget.id,
          mEditable.toString(),
          selectionStart,
          selectionEnd,
          composingStart,
          composingEnd);
      mLastKnownFrameworkTextEditingState =
          new TextEditState(
              mEditable.toString(), selectionStart, selectionEnd, composingStart, composingEnd);
    }
  }

  // -------- End: ListenableEditingState watcher implementation -------

  // -------- Start: Autofill -------
  // ### Setup and provide the initial text values and hints.
  //
  // The TextInputConfiguration used to setup the current client is also used for populating
  // "AutofillVirtualStructure" when requested by the autofill manager (AFM), See
  // #onProvideAutofillVirtualStructure.
  //
  // ### Keep the AFM updated
  //
  // The autofill session connected to The AFM keeps a copy of the current state for each reported
  // field in "AutofillVirtualStructure" (instead of holding a reference to those fields), so the
  // AFM needs to be notified when text changes if the client was part of the
  // "AutofillVirtualStructure" previously reported to the AFM. This step is essential for
  // triggering autofill save. This is done in #didChangeEditingState by calling
  // #notifyValueChanged.
  //
  // Additionally when the text input plugin receives a new TextInputConfiguration,
  // AutofillManager#notifyValueChanged will be called on all the autofillable fields contained in
  // the TextInputConfiguration, in case some of them are tracked by the session and their values
  // have changed. However if the value of an unfocused EditableText is changed in the framework,
  // such change will not be sent to the text input plugin until the next TextInput.attach call.
  private boolean needsAutofill() {
    return mAutofillConfigurations != null;
  }

  private void notifyViewEntered() {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O || afm == null || !needsAutofill()) {
      return;
    }

    final String triggerIdentifier = configuration.autofill.uniqueIdentifier;
    final int[] offset = new int[2];
    mView.getLocationOnScreen(offset);
    Rect rect = new Rect(lastClientRect);
    rect.offset(offset[0], offset[1]);
    afm.notifyViewEntered(mView, triggerIdentifier.hashCode(), rect);
  }

  private void notifyViewExited() {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O
        || afm == null
        || configuration == null
        || configuration.autofill == null
        || !needsAutofill()) {
      return;
    }

    final String triggerIdentifier = configuration.autofill.uniqueIdentifier;
    afm.notifyViewExited(mView, triggerIdentifier.hashCode());
  }

  private void notifyValueChanged(String newValue) {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O || afm == null || !needsAutofill()) {
      return;
    }

    final String triggerIdentifier = configuration.autofill.uniqueIdentifier;
    afm.notifyValueChanged(mView, triggerIdentifier.hashCode(), AutofillValue.forText(newValue));
  }

  private void updateAutofillConfigurationIfNeeded(TextInputChannel.Configuration configuration) {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
      return;
    }

    if (configuration == null || configuration.autofill == null) {
      // Disables autofill if the configuration doesn't have an autofill field.
      mAutofillConfigurations = null;
      return;
    }

    final TextInputChannel.Configuration[] configurations = configuration.fields;
    mAutofillConfigurations = new SparseArray<>();

    if (configurations == null) {
      mAutofillConfigurations.put(
          configuration.autofill.uniqueIdentifier.hashCode(), configuration);
    } else {
      for (TextInputChannel.Configuration config : configurations) {
        TextInputChannel.Configuration.Autofill autofill = config.autofill;
        if (autofill != null) {
          mAutofillConfigurations.put(autofill.uniqueIdentifier.hashCode(), config);
          afm.notifyValueChanged(
              mView,
              autofill.uniqueIdentifier.hashCode(),
              AutofillValue.forText(autofill.editState.text));
        }
      }
    }
  }

  public void onProvideAutofillVirtualStructure(ViewStructure structure, int flags) {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O || !needsAutofill()) {
      return;
    }

    final String triggerIdentifier = configuration.autofill.uniqueIdentifier;
    final AutofillId parentId = structure.getAutofillId();
    for (int i = 0; i < mAutofillConfigurations.size(); i++) {
      final int autofillId = mAutofillConfigurations.keyAt(i);
      final TextInputChannel.Configuration config = mAutofillConfigurations.valueAt(i);
      final TextInputChannel.Configuration.Autofill autofill = config.autofill;
      if (autofill == null) {
        continue;
      }

      structure.addChildCount(1);
      final ViewStructure child = structure.newChild(i);
      child.setAutofillId(parentId, autofillId);
      child.setAutofillHints(autofill.hints);
      child.setAutofillType(View.AUTOFILL_TYPE_TEXT);
      child.setVisibility(View.VISIBLE);

      // For some autofill services, only visible input fields are eligible for autofill.
      // Reports the real size of the child if it's the current client, or 1x1 if we don't
      // know the real dimensions of the child.
      if (triggerIdentifier.hashCode() == autofillId && lastClientRect != null) {
        child.setDimens(
            lastClientRect.left,
            lastClientRect.top,
            0,
            0,
            lastClientRect.width(),
            lastClientRect.height());
        child.setAutofillValue(AutofillValue.forText(mEditable));
      } else {
        child.setDimens(0, 0, 0, 0, 1, 1);
        child.setAutofillValue(AutofillValue.forText(autofill.editState.text));
      }
    }
  }

  public void autofill(SparseArray<AutofillValue> values) {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
      return;
    }

    final TextInputChannel.Configuration.Autofill currentAutofill = configuration.autofill;
    if (currentAutofill == null) {
      return;
    }

    final HashMap<String, TextInputChannel.TextEditState> editingValues = new HashMap<>();
    for (int i = 0; i < values.size(); i++) {
      int virtualId = values.keyAt(i);

      final TextInputChannel.Configuration config = mAutofillConfigurations.get(virtualId);
      if (config == null || config.autofill == null) {
        continue;
      }

      final TextInputChannel.Configuration.Autofill autofill = config.autofill;
      final String value = values.valueAt(i).getTextValue().toString();
      final TextInputChannel.TextEditState newState =
          new TextInputChannel.TextEditState(value, value.length(), value.length(), -1, -1);

      // The value of the currently focused text field needs to be updated.
      if (autofill.uniqueIdentifier.equals(currentAutofill.uniqueIdentifier)) {
        setTextInputEditingState(mView, newState);
      }
      editingValues.put(autofill.uniqueIdentifier, newState);
    }

    textInputChannel.updateEditingStateWithTag(inputTarget.id, editingValues);
  }
  // -------- End: Autofill -------
}
