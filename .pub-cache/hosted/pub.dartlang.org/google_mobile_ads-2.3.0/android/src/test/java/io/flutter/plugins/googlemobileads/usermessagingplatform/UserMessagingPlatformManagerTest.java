// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package io.flutter.plugins.googlemobileads.usermessagingplatform;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

import android.app.Activity;
import android.content.Context;
import androidx.test.core.app.ApplicationProvider;
import com.google.android.ump.ConsentForm;
import com.google.android.ump.ConsentForm.OnConsentFormDismissedListener;
import com.google.android.ump.ConsentInformation;
import com.google.android.ump.ConsentInformation.ConsentStatus;
import com.google.android.ump.ConsentInformation.OnConsentInfoUpdateFailureListener;
import com.google.android.ump.ConsentInformation.OnConsentInfoUpdateSuccessListener;
import com.google.android.ump.ConsentRequestParameters;
import com.google.android.ump.FormError;
import com.google.android.ump.UserMessagingPlatform;
import com.google.android.ump.UserMessagingPlatform.OnConsentFormLoadFailureListener;
import com.google.android.ump.UserMessagingPlatform.OnConsentFormLoadSuccessListener;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel.Result;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.MockedStatic;
import org.mockito.Mockito;
import org.robolectric.RobolectricTestRunner;

/** Tests for {@link UserMessagingPlatformManager}. */
@RunWith(RobolectricTestRunner.class)
public class UserMessagingPlatformManagerTest {

  private Context context;
  private BinaryMessenger mockMessenger;
  private UserMessagingPlatformManager manager;
  private UserMessagingCodec userMessagingCodec;
  private Activity activity;

  private MockedStatic<UserMessagingPlatform> mockedUmp;
  private ConsentInformation mockConsentInformation;

  @Before
  public void setup() {
    userMessagingCodec = mock(UserMessagingCodec.class);
    context = ApplicationProvider.getApplicationContext();
    mockMessenger = mock(BinaryMessenger.class);
    manager = new UserMessagingPlatformManager(mockMessenger, context, userMessagingCodec);
    activity = mock(Activity.class);
    mockConsentInformation = mock(ConsentInformation.class);
    mockedUmp = Mockito.mockStatic(UserMessagingPlatform.class);
    mockedUmp
        .when(
            () -> {
              UserMessagingPlatform.getConsentInformation(any());
            })
        .thenReturn(mockConsentInformation);
  }

  @After
  public void tearDown() {
    mockedUmp.close();
  }

  @Test
  public void testConsentInformation_reset() {
    Map<String, Object> args = Collections.emptyMap();
    MethodCall methodCall = new MethodCall("ConsentInformation#reset", args);
    Result result = mock(Result.class);

    manager.onMethodCall(methodCall, result);

    verify(mockConsentInformation).reset();
    verify(result).success(isNull());
  }

  @Test
  public void testConsentInformation_getConsentStatus() {
    doReturn(ConsentStatus.REQUIRED).when(mockConsentInformation).getConsentStatus();
    Map<String, Object> args = Collections.emptyMap();
    MethodCall methodCall = new MethodCall("ConsentInformation#getConsentStatus", args);
    Result result = mock(Result.class);

    manager.onMethodCall(methodCall, result);

    verify(result).success(eq(ConsentStatus.REQUIRED));
  }

  @Test
  public void testConsentInformation_requestConsentInfoUpdate_activityNotSet() {
    manager.setActivity(null);
    MethodCall methodCall = new MethodCall("ConsentInformation#requestConsentInfoUpdate", null);
    Result result = mock(Result.class);

    manager.onMethodCall(methodCall, result);

    verify(result)
        .error(
            eq("0"),
            eq(
                "ConsentInformation#requestConsentInfoUpdate called before plugin has been "
                    + "registered to an activity."),
            isNull());
  }

  @Test
  public void testConsentInformation_requestConsentInfoUpdate_success() {
    manager.setActivity(activity);
    ConsentRequestParametersWrapper paramsWrapper = mock(ConsentRequestParametersWrapper.class);
    ConsentRequestParameters params = mock(ConsentRequestParameters.class);
    doReturn(params).when(paramsWrapper).getAsConsentRequestParameters(any());
    Map<String, Object> args = new HashMap<>();
    args.put("params", paramsWrapper);
    MethodCall methodCall = new MethodCall("ConsentInformation#requestConsentInfoUpdate", args);
    Result result = mock(Result.class);

    manager.onMethodCall(methodCall, result);

    ArgumentCaptor<OnConsentInfoUpdateSuccessListener> successCaptor =
        ArgumentCaptor.forClass(OnConsentInfoUpdateSuccessListener.class);
    ArgumentCaptor<OnConsentInfoUpdateFailureListener> errorCaptor =
        ArgumentCaptor.forClass(OnConsentInfoUpdateFailureListener.class);
    verify(mockConsentInformation)
        .requestConsentInfoUpdate(
            eq(activity), eq(params), successCaptor.capture(), errorCaptor.capture());

    successCaptor.getValue().onConsentInfoUpdateSuccess();
    verify(result).success(isNull());

    FormError formError = mock(FormError.class);
    doReturn(1).when(formError).getErrorCode();
    doReturn("message").when(formError).getMessage();
    errorCaptor.getValue().onConsentInfoUpdateFailure(formError);
    verify(result).error(eq("1"), eq("message"), isNull());
  }

  @Test
  public void testConsentInformation_isConsentFormAvailable() {
    doReturn(false).when(mockConsentInformation).isConsentFormAvailable();
    Map<String, Object> args =
        Collections.singletonMap("consentInformation", mockConsentInformation);
    MethodCall methodCall = new MethodCall("ConsentInformation#isConsentFormAvailable", args);
    Result result = mock(Result.class);

    manager.onMethodCall(methodCall, result);

    verify(result).success(eq(false));
  }

  @Test
  public void testUserMessagingPlatform_loadConsentFormAndDispose() {
    MethodCall methodCall = new MethodCall("UserMessagingPlatform#loadConsentForm", null);
    Result result = mock(Result.class);

    manager.onMethodCall(methodCall, result);

    ArgumentCaptor<OnConsentFormLoadSuccessListener> successCaptor =
        ArgumentCaptor.forClass(OnConsentFormLoadSuccessListener.class);
    ArgumentCaptor<OnConsentFormLoadFailureListener> errorCaptor =
        ArgumentCaptor.forClass(OnConsentFormLoadFailureListener.class);
    mockedUmp.verify(
        () ->
            UserMessagingPlatform.loadConsentForm(
                eq(context), successCaptor.capture(), errorCaptor.capture()));

    ConsentForm consentForm = mock(ConsentForm.class);
    successCaptor.getValue().onConsentFormLoadSuccess(consentForm);

    verify(result).success(eq(consentForm));
    verify(userMessagingCodec).trackConsentForm(consentForm);

    FormError formError = mock(FormError.class);
    errorCaptor.getValue().onConsentFormLoadFailure(formError);

    // Dispose
    Map<String, Object> args = Collections.singletonMap("consentForm", consentForm);
    methodCall = new MethodCall("ConsentForm#dispose", args);
    manager.onMethodCall(methodCall, result);

    verify(userMessagingCodec).disposeConsentForm(consentForm);
    verify(result).success(null);
  }

  @Test
  public void testConsentForm_show() {
    manager.setActivity(activity);
    ConsentForm consentForm = mock(ConsentForm.class);
    Map<String, Object> args = Collections.singletonMap("consentForm", consentForm);
    MethodCall methodCall = new MethodCall("ConsentForm#show", args);
    Result result = mock(Result.class);

    manager.onMethodCall(methodCall, result);

    ArgumentCaptor<OnConsentFormDismissedListener> listenerCaptor =
        ArgumentCaptor.forClass(OnConsentFormDismissedListener.class);
    verify(consentForm).show(eq(activity), listenerCaptor.capture());

    listenerCaptor.getValue().onConsentFormDismissed(null);
    verify(result).success(isNull());

    FormError formError = mock(FormError.class);
    doReturn(1).when(formError).getErrorCode();
    doReturn("message").when(formError).getMessage();
    listenerCaptor.getValue().onConsentFormDismissed(formError);
    verify(result).error(eq("1"), eq("message"), isNull());
  }

  @Test
  public void testConsentForm_show_errorNoConsentForm() {
    MethodCall methodCall = new MethodCall("ConsentForm#show", null);
    Result result = mock(Result.class);
    manager.onMethodCall(methodCall, result);
    verify(result).error(eq("0"), eq("ConsentForm#show"), isNull());
  }
}
