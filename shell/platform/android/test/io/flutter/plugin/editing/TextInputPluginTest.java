package io.flutter.plugin.editing;

import android.content.Context;
import android.content.res.AssetManager;
import android.provider.Settings;
import android.util.SparseIntArray;
import android.view.View;
import android.view.inputmethod.InputMethodManager;
import android.view.inputmethod.InputMethodSubtype;

import java.nio.ByteBuffer;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;
import org.robolectric.annotation.Implementation;
import org.robolectric.annotation.Implements;
import org.robolectric.shadow.api.Shadow;
import org.robolectric.shadows.ShadowBuild;
import org.robolectric.shadows.ShadowInputMethodManager;

import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.systemchannels.TextInputChannel;
import io.flutter.plugin.common.JSONMethodCodec;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.platform.PlatformViewsController;

import static org.junit.Assert.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

@Config(manifest = Config.NONE, shadows = TextInputPluginTest.TestImm.class, sdk = 27)
@RunWith(RobolectricTestRunner.class)
public class TextInputPluginTest {
    @Test
    public void textInputPlugin_RequestsReattachOnCreation() {
        // Initialize a general TextInputPlugin.
        InputMethodSubtype inputMethodSubtype = mock(InputMethodSubtype.class);
        TestImm testImm = Shadow.extract(RuntimeEnvironment.application.getSystemService(Context.INPUT_METHOD_SERVICE));
        testImm.setCurrentInputMethodSubtype(inputMethodSubtype);
        View testView = new View(RuntimeEnvironment.application);

        FlutterJNI mockFlutterJni = mock(FlutterJNI.class);
        DartExecutor dartExecutor = spy(new DartExecutor(mockFlutterJni, mock(AssetManager.class)));
        TextInputPlugin textInputPlugin = new TextInputPlugin(testView, dartExecutor, mock(PlatformViewsController.class));

        ByteBuffer message = JSONMethodCodec.INSTANCE.encodeMethodCall(new MethodCall("TextInputClient.requestExistingInputState", null));
        verify(dartExecutor, times(1)).send("flutter/textinput", message, null);
    }

    @Test
    public void setTextInputEditingState_doesNotRestartWhenTextIsIdentical() {
        // Initialize a general TextInputPlugin.
        InputMethodSubtype inputMethodSubtype = mock(InputMethodSubtype.class);
        TestImm testImm = Shadow.extract(RuntimeEnvironment.application.getSystemService(Context.INPUT_METHOD_SERVICE));
        testImm.setCurrentInputMethodSubtype(inputMethodSubtype);
        View testView = new View(RuntimeEnvironment.application);
        TextInputPlugin textInputPlugin = new TextInputPlugin(testView, mock(DartExecutor.class), mock(PlatformViewsController.class));
        textInputPlugin.setTextInputClient(0, new TextInputChannel.Configuration(false, false, true, TextInputChannel.TextCapitalization.NONE, null, null, null));
        // There's a pending restart since we initialized the text input client. Flush that now.
        textInputPlugin.setTextInputEditingState(testView, new TextInputChannel.TextEditState("", 0, 0));

        // Move the cursor.
        assertEquals(1, testImm.getRestartCount(testView));
        textInputPlugin.setTextInputEditingState(testView, new TextInputChannel.TextEditState("", 0, 0));

        // Verify that we haven't restarted the input.
        assertEquals(1, testImm.getRestartCount(testView));
    }

    // See https://github.com/flutter/flutter/issues/29341 and https://github.com/flutter/flutter/issues/31512
    // All modern Samsung keybords are affected including non-korean languages and thus
    // need the restart.
    @Test
    public void setTextInputEditingState_alwaysRestartsOnAffectedDevices2() {
        // Initialize a TextInputPlugin that needs to be always restarted.
        ShadowBuild.setManufacturer("samsung");
        InputMethodSubtype inputMethodSubtype = new InputMethodSubtype(0, 0, /*locale=*/"en", "", "", false, false);
        Settings.Secure.putString(RuntimeEnvironment.application.getContentResolver(), Settings.Secure.DEFAULT_INPUT_METHOD, "com.sec.android.inputmethod/.SamsungKeypad");
        TestImm testImm = Shadow.extract(RuntimeEnvironment.application.getSystemService(Context.INPUT_METHOD_SERVICE));
        testImm.setCurrentInputMethodSubtype(inputMethodSubtype);
        View testView = new View(RuntimeEnvironment.application);
        TextInputPlugin textInputPlugin = new TextInputPlugin(testView, mock(DartExecutor.class), mock(PlatformViewsController.class));
        textInputPlugin.setTextInputClient(0, new TextInputChannel.Configuration(false, false, true, TextInputChannel.TextCapitalization.NONE, null, null, null));
        // There's a pending restart since we initialized the text input client. Flush that now.
        textInputPlugin.setTextInputEditingState(testView, new TextInputChannel.TextEditState("", 0, 0));

        // Move the cursor.
        assertEquals(1, testImm.getRestartCount(testView));
        textInputPlugin.setTextInputEditingState(testView, new TextInputChannel.TextEditState("", 0, 0));

        // Verify that we've restarted the input.
        assertEquals(2, testImm.getRestartCount(testView));
    }

    @Test
    public void setTextInputEditingState_doesNotRestartOnUnaffectedDevices() {
        // Initialize a TextInputPlugin that needs to be always restarted.
        ShadowBuild.setManufacturer("samsung");
        InputMethodSubtype inputMethodSubtype = new InputMethodSubtype(0, 0, /*locale=*/"en", "", "", false, false);
        Settings.Secure.putString(RuntimeEnvironment.application.getContentResolver(), Settings.Secure.DEFAULT_INPUT_METHOD, "com.fake.test.blah/.NotTheRightKeyboard");
        TestImm testImm = Shadow.extract(RuntimeEnvironment.application.getSystemService(Context.INPUT_METHOD_SERVICE));
        testImm.setCurrentInputMethodSubtype(inputMethodSubtype);
        View testView = new View(RuntimeEnvironment.application);
        TextInputPlugin textInputPlugin = new TextInputPlugin(testView, mock(DartExecutor.class), mock(PlatformViewsController.class));
        textInputPlugin.setTextInputClient(0, new TextInputChannel.Configuration(false, false, true, TextInputChannel.TextCapitalization.NONE, null, null, null));
        // There's a pending restart since we initialized the text input client. Flush that now.
        textInputPlugin.setTextInputEditingState(testView, new TextInputChannel.TextEditState("", 0, 0));

        // Move the cursor.
        assertEquals(1, testImm.getRestartCount(testView));
        textInputPlugin.setTextInputEditingState(testView, new TextInputChannel.TextEditState("", 0, 0));

        // Verify that we've restarted the input.
        assertEquals(1, testImm.getRestartCount(testView));
    }

    @Test
    public void setTextInputEditingState_nullInputMethodSubtype() {
        TestImm testImm = Shadow.extract(RuntimeEnvironment.application.getSystemService(Context.INPUT_METHOD_SERVICE));
        testImm.setCurrentInputMethodSubtype(null);

        View testView = new View(RuntimeEnvironment.application);
        TextInputPlugin textInputPlugin = new TextInputPlugin(testView, mock(DartExecutor.class), mock(PlatformViewsController.class));
        textInputPlugin.setTextInputClient(0, new TextInputChannel.Configuration(false, false, true, TextInputChannel.TextCapitalization.NONE, null, null, null));
        // There's a pending restart since we initialized the text input client. Flush that now.
        textInputPlugin.setTextInputEditingState(testView, new TextInputChannel.TextEditState("", 0, 0));
        assertEquals(1, testImm.getRestartCount(testView));
    }

    @Implements(InputMethodManager.class)
    public static class TestImm extends ShadowInputMethodManager {
        private InputMethodSubtype currentInputMethodSubtype;
        private SparseIntArray restartCounter = new SparseIntArray();

        public TestImm() {
        }

        @Implementation
        public InputMethodSubtype getCurrentInputMethodSubtype() {
            return currentInputMethodSubtype;
        }

        @Implementation
        public void restartInput(View view) {
            int count = restartCounter.get(view.hashCode(), /*defaultValue=*/0) + 1;
            restartCounter.put(view.hashCode(), count);
        }

        public void setCurrentInputMethodSubtype(InputMethodSubtype inputMethodSubtype) {
            this.currentInputMethodSubtype = inputMethodSubtype;
        }

        public int getRestartCount(View view) {
            return restartCounter.get(view.hashCode(), /*defaultValue=*/0);
        }
    }
}
