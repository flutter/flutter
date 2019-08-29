package io.flutter.embedding.engine.systemchannels;

import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.view.inputmethod.EditorInfo;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.Arrays;
import java.util.HashMap;

import io.flutter.Log;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.JSONMethodCodec;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * {@link TextInputChannel} is a platform channel between Android and Flutter that is used to
 * communicate information about the user's text input.
 * <p>
 * When the user presses an action button like "done" or "next", that action is sent from Android
 * to Flutter through this {@link TextInputChannel}.
 * <p>
 * When an input system in the Flutter app wants to show the keyboard, or hide it, or configure
 * editing state, etc. a message is sent from Flutter to Android through this {@link TextInputChannel}.
 * <p>
 * {@link TextInputChannel} comes with a default {@link io.flutter.plugin.common.MethodChannel.MethodCallHandler}
 * that parses incoming messages from Flutter. Register a {@link TextInputMethodHandler} to respond
 * to standard Flutter text input messages.
 */
public class TextInputChannel {
  private static final String TAG = "TextInputChannel";

  @NonNull
  public final MethodChannel channel;
  @Nullable
  private TextInputMethodHandler textInputMethodHandler;

  private final MethodChannel.MethodCallHandler parsingMethodHandler = new MethodChannel.MethodCallHandler() {
    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
      if (textInputMethodHandler == null) {
        // If no explicit TextInputMethodHandler has been registered then we don't
        // need to forward this call to an API. Return.
        return;
      }

      String method = call.method;
      Object args = call.arguments;
      Log.v(TAG, "Received '" + method + "' message.");
      switch (method) {
        case "TextInput.show":
          textInputMethodHandler.show();
          result.success(null);
          break;
        case "TextInput.hide":
          textInputMethodHandler.hide();
          result.success(null);
          break;
        case "TextInput.setClient":
          try {
            final JSONArray argumentList = (JSONArray) args;
            final int textInputClientId = argumentList.getInt(0);
            final JSONObject jsonConfiguration = argumentList.getJSONObject(1);
            textInputMethodHandler.setClient(textInputClientId, Configuration.fromJson(jsonConfiguration));
            result.success(null);
          } catch (JSONException | NoSuchFieldException exception) {
            // JSONException: missing keys or bad value types.
            // NoSuchFieldException: one or more values were invalid.
            result.error("error", exception.getMessage(), null);
          }
          break;
        case "TextInput.setPlatformViewClient":
          final int id = (int) args;
          textInputMethodHandler.setPlatformViewClient(id);
          break;
        case "TextInput.setEditingState":
          try {
            final JSONObject editingState = (JSONObject) args;
            textInputMethodHandler.setEditingState(TextEditState.fromJson(editingState));
            result.success(null);
          } catch (JSONException exception) {
            result.error("error", exception.getMessage(), null);
          }
          break;
        case "TextInput.clearClient":
          textInputMethodHandler.clearClient();
          result.success(null);
          break;
        default:
          result.notImplemented();
          break;
      }
    }
  };

  /**
   * Constructs a {@code TextInputChannel} that connects Android to the Dart code
   * running in {@code dartExecutor}.
   *
   * The given {@code dartExecutor} is permitted to be idle or executing code.
   *
   * See {@link DartExecutor}.
   */
  public TextInputChannel(@NonNull DartExecutor dartExecutor) {
    this.channel = new MethodChannel(dartExecutor, "flutter/textinput", JSONMethodCodec.INSTANCE);
    channel.setMethodCallHandler(parsingMethodHandler);
  }

  /**
   * Instructs Flutter to update its text input editing state to reflect the given configuration.
   */
  public void updateEditingState(int inputClientId, String text, int selectionStart, int selectionEnd, int composingStart, int composingEnd) {
    Log.v(TAG, "Sending message to update editing state: \n"
      + "Text: " + text + "\n"
      + "Selection start: " + selectionStart + "\n"
      + "Selection end: " + selectionEnd + "\n"
      + "Composing start: " + composingStart + "\n"
      + "Composing end: " + composingEnd);

    HashMap<Object, Object> state = new HashMap<>();
    state.put("text", text);
    state.put("selectionBase", selectionStart);
    state.put("selectionExtent", selectionEnd);
    state.put("composingBase", composingStart);
    state.put("composingExtent", composingEnd);

    channel.invokeMethod(
        "TextInputClient.updateEditingState",
        Arrays.asList(inputClientId, state)
    );
  }

  /**
   * Instructs Flutter to execute a "newline" action.
   */
  public void newline(int inputClientId) {
    Log.v(TAG, "Sending 'newline' message.");
    channel.invokeMethod(
        "TextInputClient.performAction",
        Arrays.asList(inputClientId, "TextInputAction.newline")
    );
  }

  /**
   * Instructs Flutter to execute a "go" action.
   */
  public void go(int inputClientId) {
    Log.v(TAG, "Sending 'go' message.");
    channel.invokeMethod(
        "TextInputClient.performAction",
        Arrays.asList(inputClientId, "TextInputAction.go")
    );
  }

  /**
   * Instructs Flutter to execute a "search" action.
   */
  public void search(int inputClientId) {
    Log.v(TAG, "Sending 'search' message.");
    channel.invokeMethod(
        "TextInputClient.performAction",
        Arrays.asList(inputClientId, "TextInputAction.search")
    );
  }

  /**
   * Instructs Flutter to execute a "send" action.
   */
  public void send(int inputClientId) {
    Log.v(TAG, "Sending 'send' message.");
    channel.invokeMethod(
        "TextInputClient.performAction",
        Arrays.asList(inputClientId, "TextInputAction.send")
    );
  }

  /**
   * Instructs Flutter to execute a "done" action.
   */
  public void done(int inputClientId) {
    Log.v(TAG, "Sending 'done' message.");
    channel.invokeMethod(
        "TextInputClient.performAction",
        Arrays.asList(inputClientId, "TextInputAction.done")
    );
  }

  /**
   * Instructs Flutter to execute a "next" action.
   */
  public void next(int inputClientId) {
    Log.v(TAG, "Sending 'next' message.");
    channel.invokeMethod(
        "TextInputClient.performAction",
        Arrays.asList(inputClientId, "TextInputAction.next")
    );
  }

  /**
   * Instructs Flutter to execute a "previous" action.
   */
  public void previous(int inputClientId) {
    Log.v(TAG, "Sending 'previous' message.");
    channel.invokeMethod(
        "TextInputClient.performAction",
        Arrays.asList(inputClientId, "TextInputAction.previous")
    );
  }

  /**
   * Instructs Flutter to execute an "unspecified" action.
   */
  public void unspecifiedAction(int inputClientId) {
    Log.v(TAG, "Sending 'unspecified' message.");
    channel.invokeMethod(
        "TextInputClient.performAction",
        Arrays.asList(inputClientId, "TextInputAction.unspecified")
    );
  }

  /**
   * Sets the {@link TextInputMethodHandler} which receives all events and requests
   * that are parsed from the underlying platform channel.
   */
  public void setTextInputMethodHandler(@Nullable TextInputMethodHandler textInputMethodHandler) {
    this.textInputMethodHandler = textInputMethodHandler;
  }

  public interface TextInputMethodHandler {
    // TODO(mattcarroll): javadoc
    void show();

    // TODO(mattcarroll): javadoc
    void hide();

    // TODO(mattcarroll): javadoc
    void setClient(int textInputClientId, @NonNull Configuration configuration);

    /**
     * Sets a platform view as the text input client.
     *
     * Subsequent calls to createInputConnection will be delegated to the platform view until a
     * different client is set.
     *
     * @param id the ID of the platform view to be set as a text input client.
     */
    void setPlatformViewClient(int id);

    // TODO(mattcarroll): javadoc
    void setEditingState(@NonNull TextEditState editingState);

    // TODO(mattcarroll): javadoc
    void clearClient();
  }

  /**
   * A text editing configuration.
   */
  public static class Configuration {
    public static Configuration fromJson(@NonNull JSONObject json) throws JSONException, NoSuchFieldException {
      final String inputActionName = json.getString("inputAction");
      if (inputActionName == null) {
        throw new JSONException("Configuration JSON missing 'inputAction' property.");
      }

      final Integer inputAction = inputActionFromTextInputAction(inputActionName);
      return new Configuration(
          json.optBoolean("obscureText"),
          json.optBoolean("autocorrect", true),
          TextCapitalization.fromValue(json.getString("textCapitalization")),
          InputType.fromJson(json.getJSONObject("inputType")),
          inputAction,
          json.isNull("actionLabel") ? null : json.getString("actionLabel")
      );
    }

    @NonNull
    private static Integer inputActionFromTextInputAction(@NonNull String inputAction) {
      switch (inputAction) {
        case "TextInputAction.newline":
          return EditorInfo.IME_ACTION_NONE;
        case "TextInputAction.none":
          return EditorInfo.IME_ACTION_NONE;
        case "TextInputAction.unspecified":
          return EditorInfo.IME_ACTION_UNSPECIFIED;
        case "TextInputAction.done":
          return EditorInfo.IME_ACTION_DONE;
        case "TextInputAction.go":
          return EditorInfo.IME_ACTION_GO;
        case "TextInputAction.search":
          return EditorInfo.IME_ACTION_SEARCH;
        case "TextInputAction.send":
          return EditorInfo.IME_ACTION_SEND;
        case "TextInputAction.next":
          return EditorInfo.IME_ACTION_NEXT;
        case "TextInputAction.previous":
          return EditorInfo.IME_ACTION_PREVIOUS;
        default:
          // Present default key if bad input type is given.
          return EditorInfo.IME_ACTION_UNSPECIFIED;
      }
    }

    public final boolean obscureText;
    public final boolean autocorrect;
    @NonNull
    public final TextCapitalization textCapitalization;
    @NonNull
    public final InputType inputType;
    @Nullable
    public final Integer inputAction;
    @Nullable
    public final String actionLabel;

    public Configuration(
        boolean obscureText,
        boolean autocorrect,
        @NonNull TextCapitalization textCapitalization,
        @NonNull InputType inputType,
        @Nullable Integer inputAction,
        @Nullable String actionLabel
    ) {
      this.obscureText = obscureText;
      this.autocorrect = autocorrect;
      this.textCapitalization = textCapitalization;
      this.inputType = inputType;
      this.inputAction = inputAction;
      this.actionLabel = actionLabel;
    }
  }

  /**
   * A text input type.
   *
   * If the {@link #type} is {@link TextInputType#NUMBER}, this {@code InputType} also
   * reports whether that number {@link #isSigned} and {@link #isDecimal}.
   */
  public static class InputType {
    @NonNull
    public static InputType fromJson(@NonNull JSONObject json) throws JSONException, NoSuchFieldException {
      return new InputType(
          TextInputType.fromValue(json.getString("name")),
          json.optBoolean("signed", false),
          json.optBoolean("decimal", false)
      );
    }

    @NonNull
    public final TextInputType type;
    public final boolean isSigned;
    public final boolean isDecimal;

    public InputType(@NonNull TextInputType type, boolean isSigned, boolean isDecimal) {
      this.type = type;
      this.isSigned = isSigned;
      this.isDecimal = isDecimal;
    }
  }

  /**
   * Types of text input.
   */
  public enum TextInputType {
    TEXT("TextInputType.text"),
    DATETIME("TextInputType.datetime"),
    NUMBER("TextInputType.number"),
    PHONE("TextInputType.phone"),
    MULTILINE("TextInputType.multiline"),
    EMAIL_ADDRESS("TextInputType.emailAddress"),
    URL("TextInputType.url"),
    VISIBLE_PASSWORD("TextInputType.visiblePassword");

    static TextInputType fromValue(@NonNull String encodedName) throws NoSuchFieldException {
      for (TextInputType textInputType : TextInputType.values()) {
        if (textInputType.encodedName.equals(encodedName)) {
          return textInputType;
        }
      }
      throw new NoSuchFieldException("No such TextInputType: " + encodedName);
    }

    @NonNull
    private final String encodedName;

    TextInputType(@NonNull String encodedName) {
      this.encodedName = encodedName;
    }
  }

  /**
   * Text capitalization schemes.
   */
  public enum TextCapitalization {
    CHARACTERS("TextCapitalization.characters"),
    WORDS("TextCapitalization.words"),
    SENTENCES("TextCapitalization.sentences"),
    NONE("TextCapitalization.none");

    static TextCapitalization fromValue(@NonNull String encodedName) throws NoSuchFieldException {
      for (TextCapitalization textCapitalization : TextCapitalization.values()) {
        if (textCapitalization.encodedName.equals(encodedName)) {
          return textCapitalization;
        }
      }
      throw new NoSuchFieldException("No such TextCapitalization: " + encodedName);
    }

    @NonNull
    private final String encodedName;

    TextCapitalization(@NonNull String encodedName) {
      this.encodedName = encodedName;
    }
  }

  /**
   * State of an on-going text editing session.
   */
  public static class TextEditState {
    public static TextEditState fromJson(@NonNull JSONObject textEditState) throws JSONException {
      return new TextEditState(
          textEditState.getString("text"),
          textEditState.getInt("selectionBase"),
          textEditState.getInt("selectionExtent")
      );
    }

    @NonNull
    public final String text;
    public final int selectionStart;
    public final int selectionEnd;

    public TextEditState(@NonNull String text, int selectionStart, int selectionEnd) {
      this.text = text;
      this.selectionStart = selectionStart;
      this.selectionEnd = selectionEnd;
    }
  }
}
