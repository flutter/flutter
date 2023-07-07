// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.googlesignin;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.res.Resources;
import com.google.android.gms.auth.api.signin.GoogleSignInAccount;
import com.google.android.gms.auth.api.signin.GoogleSignInClient;
import com.google.android.gms.auth.api.signin.GoogleSignInOptions;
import com.google.android.gms.common.api.ApiException;
import com.google.android.gms.common.api.CommonStatusCodes;
import com.google.android.gms.common.api.Scope;
import com.google.android.gms.common.api.Status;
import com.google.android.gms.tasks.Task;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import org.junit.After;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.mockito.Spy;

public class GoogleSignInTest {
  @Mock Context mockContext;
  @Mock Resources mockResources;
  @Mock Activity mockActivity;
  @Mock BinaryMessenger mockMessenger;
  @Spy MethodChannel.Result result;
  @Mock GoogleSignInWrapper mockGoogleSignIn;
  @Mock GoogleSignInAccount account;
  @Mock GoogleSignInClient mockClient;
  @Mock Task<GoogleSignInAccount> mockSignInTask;

  @SuppressWarnings("deprecation")
  @Mock
  PluginRegistry.Registrar mockRegistrar;

  private GoogleSignInPlugin plugin;
  private AutoCloseable mockCloseable;

  @Before
  public void setUp() {
    mockCloseable = MockitoAnnotations.openMocks(this);
    when(mockRegistrar.messenger()).thenReturn(mockMessenger);
    when(mockRegistrar.context()).thenReturn(mockContext);
    when(mockRegistrar.activity()).thenReturn(mockActivity);
    when(mockContext.getResources()).thenReturn(mockResources);
    plugin = new GoogleSignInPlugin();
    plugin.initInstance(mockRegistrar.messenger(), mockRegistrar.context(), mockGoogleSignIn);
    plugin.setUpRegistrar(mockRegistrar);
  }

  @After
  public void tearDown() throws Exception {
    mockCloseable.close();
  }

  @Test
  public void requestScopes_ResultErrorIfAccountIsNull() {
    HashMap<String, List<String>> arguments = new HashMap<>();
    arguments.put("scopes", Collections.singletonList("requestedScope"));
    MethodCall methodCall = new MethodCall("requestScopes", arguments);
    when(mockGoogleSignIn.getLastSignedInAccount(mockContext)).thenReturn(null);
    plugin.onMethodCall(methodCall, result);
    verify(result).error("sign_in_required", "No account to grant scopes.", null);
  }

  @Test
  public void requestScopes_ResultTrueIfAlreadyGranted() {
    HashMap<String, List<String>> arguments = new HashMap<>();
    arguments.put("scopes", Collections.singletonList("requestedScope"));

    MethodCall methodCall = new MethodCall("requestScopes", arguments);
    Scope requestedScope = new Scope("requestedScope");
    when(mockGoogleSignIn.getLastSignedInAccount(mockContext)).thenReturn(account);
    when(account.getGrantedScopes()).thenReturn(Collections.singleton(requestedScope));
    when(mockGoogleSignIn.hasPermissions(account, requestedScope)).thenReturn(true);

    plugin.onMethodCall(methodCall, result);
    verify(result).success(true);
  }

  @Test
  public void requestScopes_RequestsPermissionIfNotGranted() {
    HashMap<String, List<String>> arguments = new HashMap<>();
    arguments.put("scopes", Collections.singletonList("requestedScope"));
    MethodCall methodCall = new MethodCall("requestScopes", arguments);
    Scope requestedScope = new Scope("requestedScope");

    when(mockGoogleSignIn.getLastSignedInAccount(mockContext)).thenReturn(account);
    when(account.getGrantedScopes()).thenReturn(Collections.singleton(requestedScope));
    when(mockGoogleSignIn.hasPermissions(account, requestedScope)).thenReturn(false);

    plugin.onMethodCall(methodCall, result);

    verify(mockGoogleSignIn)
        .requestPermissions(mockActivity, 53295, account, new Scope[] {requestedScope});
  }

  @Test
  public void requestScopes_ReturnsFalseIfPermissionDenied() {
    HashMap<String, List<String>> arguments = new HashMap<>();
    arguments.put("scopes", Collections.singletonList("requestedScope"));
    MethodCall methodCall = new MethodCall("requestScopes", arguments);
    Scope requestedScope = new Scope("requestedScope");

    ArgumentCaptor<PluginRegistry.ActivityResultListener> captor =
        ArgumentCaptor.forClass(PluginRegistry.ActivityResultListener.class);
    verify(mockRegistrar).addActivityResultListener(captor.capture());
    PluginRegistry.ActivityResultListener listener = captor.getValue();

    when(mockGoogleSignIn.getLastSignedInAccount(mockContext)).thenReturn(account);
    when(account.getGrantedScopes()).thenReturn(Collections.singleton(requestedScope));
    when(mockGoogleSignIn.hasPermissions(account, requestedScope)).thenReturn(false);

    plugin.onMethodCall(methodCall, result);
    listener.onActivityResult(
        GoogleSignInPlugin.Delegate.REQUEST_CODE_REQUEST_SCOPE,
        Activity.RESULT_CANCELED,
        new Intent());

    verify(result).success(false);
  }

  @Test
  public void requestScopes_ReturnsTrueIfPermissionGranted() {
    HashMap<String, List<String>> arguments = new HashMap<>();
    arguments.put("scopes", Collections.singletonList("requestedScope"));
    MethodCall methodCall = new MethodCall("requestScopes", arguments);
    Scope requestedScope = new Scope("requestedScope");

    ArgumentCaptor<PluginRegistry.ActivityResultListener> captor =
        ArgumentCaptor.forClass(PluginRegistry.ActivityResultListener.class);
    verify(mockRegistrar).addActivityResultListener(captor.capture());
    PluginRegistry.ActivityResultListener listener = captor.getValue();

    when(mockGoogleSignIn.getLastSignedInAccount(mockContext)).thenReturn(account);
    when(account.getGrantedScopes()).thenReturn(Collections.singleton(requestedScope));
    when(mockGoogleSignIn.hasPermissions(account, requestedScope)).thenReturn(false);

    plugin.onMethodCall(methodCall, result);
    listener.onActivityResult(
        GoogleSignInPlugin.Delegate.REQUEST_CODE_REQUEST_SCOPE, Activity.RESULT_OK, new Intent());

    verify(result).success(true);
  }

  @Test
  public void requestScopes_mayBeCalledRepeatedly_ifAlreadyGranted() {
    HashMap<String, List<String>> arguments = new HashMap<>();
    arguments.put("scopes", Collections.singletonList("requestedScope"));
    MethodCall methodCall = new MethodCall("requestScopes", arguments);
    Scope requestedScope = new Scope("requestedScope");

    ArgumentCaptor<PluginRegistry.ActivityResultListener> captor =
        ArgumentCaptor.forClass(PluginRegistry.ActivityResultListener.class);
    verify(mockRegistrar).addActivityResultListener(captor.capture());
    PluginRegistry.ActivityResultListener listener = captor.getValue();

    when(mockGoogleSignIn.getLastSignedInAccount(mockContext)).thenReturn(account);
    when(account.getGrantedScopes()).thenReturn(Collections.singleton(requestedScope));
    when(mockGoogleSignIn.hasPermissions(account, requestedScope)).thenReturn(false);

    plugin.onMethodCall(methodCall, result);
    listener.onActivityResult(
        GoogleSignInPlugin.Delegate.REQUEST_CODE_REQUEST_SCOPE, Activity.RESULT_OK, new Intent());
    plugin.onMethodCall(methodCall, result);
    listener.onActivityResult(
        GoogleSignInPlugin.Delegate.REQUEST_CODE_REQUEST_SCOPE, Activity.RESULT_OK, new Intent());

    verify(result, times(2)).success(true);
  }

  @Test
  public void requestScopes_mayBeCalledRepeatedly_ifNotSignedIn() {
    HashMap<String, List<String>> arguments = new HashMap<>();
    arguments.put("scopes", Collections.singletonList("requestedScope"));
    MethodCall methodCall = new MethodCall("requestScopes", arguments);
    Scope requestedScope = new Scope("requestedScope");

    ArgumentCaptor<PluginRegistry.ActivityResultListener> captor =
        ArgumentCaptor.forClass(PluginRegistry.ActivityResultListener.class);
    verify(mockRegistrar).addActivityResultListener(captor.capture());
    PluginRegistry.ActivityResultListener listener = captor.getValue();

    when(mockGoogleSignIn.getLastSignedInAccount(mockContext)).thenReturn(null);

    plugin.onMethodCall(methodCall, result);
    listener.onActivityResult(
        GoogleSignInPlugin.Delegate.REQUEST_CODE_REQUEST_SCOPE, Activity.RESULT_OK, new Intent());
    plugin.onMethodCall(methodCall, result);
    listener.onActivityResult(
        GoogleSignInPlugin.Delegate.REQUEST_CODE_REQUEST_SCOPE, Activity.RESULT_OK, new Intent());

    verify(result, times(2)).error("sign_in_required", "No account to grant scopes.", null);
  }

  @Test(expected = IllegalStateException.class)
  public void signInThrowsWithoutActivity() {
    final GoogleSignInPlugin plugin = new GoogleSignInPlugin();
    plugin.initInstance(
        mock(BinaryMessenger.class), mock(Context.class), mock(GoogleSignInWrapper.class));

    plugin.onMethodCall(new MethodCall("signIn", null), null);
  }

  @Test
  public void signInSilentlyThatImmediatelyCompletesWithoutResultFinishesWithError()
      throws ApiException {
    final String clientId = "fakeClientId";
    MethodCall methodCall = buildInitMethodCall(clientId, null);
    initAndAssertServerClientId(methodCall, clientId);

    ApiException exception =
        new ApiException(new Status(CommonStatusCodes.SIGN_IN_REQUIRED, "Error text"));
    when(mockClient.silentSignIn()).thenReturn(mockSignInTask);
    when(mockSignInTask.isComplete()).thenReturn(true);
    when(mockSignInTask.getResult(ApiException.class)).thenThrow(exception);

    plugin.onMethodCall(new MethodCall("signInSilently", null), result);
    verify(result)
        .error(
            "sign_in_required",
            "com.google.android.gms.common.api.ApiException: 4: Error text",
            null);
  }

  @Test
  public void init_LoadsServerClientIdFromResources() {
    final String packageName = "fakePackageName";
    final String serverClientId = "fakeServerClientId";
    final int resourceId = 1;
    MethodCall methodCall = buildInitMethodCall(null, null);
    when(mockContext.getPackageName()).thenReturn(packageName);
    when(mockResources.getIdentifier("default_web_client_id", "string", packageName))
        .thenReturn(resourceId);
    when(mockContext.getString(resourceId)).thenReturn(serverClientId);
    initAndAssertServerClientId(methodCall, serverClientId);
  }

  @Test
  public void init_InterpretsClientIdAsServerClientId() {
    final String clientId = "fakeClientId";
    MethodCall methodCall = buildInitMethodCall(clientId, null);
    initAndAssertServerClientId(methodCall, clientId);
  }

  @Test
  public void init_ForwardsServerClientId() {
    final String serverClientId = "fakeServerClientId";
    MethodCall methodCall = buildInitMethodCall(null, serverClientId);
    initAndAssertServerClientId(methodCall, serverClientId);
  }

  @Test
  public void init_IgnoresClientIdIfServerClientIdIsProvided() {
    final String clientId = "fakeClientId";
    final String serverClientId = "fakeServerClientId";
    MethodCall methodCall = buildInitMethodCall(clientId, serverClientId);
    initAndAssertServerClientId(methodCall, serverClientId);
  }

  @Test
  public void init_PassesForceCodeForRefreshTokenFalseWithServerClientIdParameter() {
    MethodCall methodCall = buildInitMethodCall("fakeClientId", "fakeServerClientId", false);

    initAndAssertForceCodeForRefreshToken(methodCall, false);
  }

  @Test
  public void init_PassesForceCodeForRefreshTokenTrueWithServerClientIdParameter() {
    MethodCall methodCall = buildInitMethodCall("fakeClientId", "fakeServerClientId", true);

    initAndAssertForceCodeForRefreshToken(methodCall, true);
  }

  @Test
  public void init_PassesForceCodeForRefreshTokenFalseWithServerClientIdFromResources() {
    final String packageName = "fakePackageName";
    final String serverClientId = "fakeServerClientId";
    final int resourceId = 1;
    MethodCall methodCall = buildInitMethodCall(null, null, false);
    when(mockContext.getPackageName()).thenReturn(packageName);
    when(mockResources.getIdentifier("default_web_client_id", "string", packageName))
        .thenReturn(resourceId);
    when(mockContext.getString(resourceId)).thenReturn(serverClientId);

    initAndAssertForceCodeForRefreshToken(methodCall, false);
  }

  @Test
  public void init_PassesForceCodeForRefreshTokenTrueWithServerClientIdFromResources() {
    final String packageName = "fakePackageName";
    final String serverClientId = "fakeServerClientId";
    final int resourceId = 1;
    MethodCall methodCall = buildInitMethodCall(null, null, true);
    when(mockContext.getPackageName()).thenReturn(packageName);
    when(mockResources.getIdentifier("default_web_client_id", "string", packageName))
        .thenReturn(resourceId);
    when(mockContext.getString(resourceId)).thenReturn(serverClientId);

    initAndAssertForceCodeForRefreshToken(methodCall, true);
  }

  public void initAndAssertServerClientId(MethodCall methodCall, String serverClientId) {
    ArgumentCaptor<GoogleSignInOptions> optionsCaptor =
        ArgumentCaptor.forClass(GoogleSignInOptions.class);
    when(mockGoogleSignIn.getClient(any(Context.class), optionsCaptor.capture()))
        .thenReturn(mockClient);
    plugin.onMethodCall(methodCall, result);
    verify(result).success(null);
    Assert.assertEquals(serverClientId, optionsCaptor.getValue().getServerClientId());
  }

  public void initAndAssertForceCodeForRefreshToken(
      MethodCall methodCall, boolean forceCodeForRefreshToken) {
    ArgumentCaptor<GoogleSignInOptions> optionsCaptor =
        ArgumentCaptor.forClass(GoogleSignInOptions.class);
    when(mockGoogleSignIn.getClient(any(Context.class), optionsCaptor.capture()))
        .thenReturn(mockClient);
    plugin.onMethodCall(methodCall, result);
    verify(result).success(null);
    Assert.assertEquals(
        forceCodeForRefreshToken, optionsCaptor.getValue().isForceCodeForRefreshToken());
  }

  private static MethodCall buildInitMethodCall(String clientId, String serverClientId) {
    return buildInitMethodCall(
        "SignInOption.standard", Collections.<String>emptyList(), clientId, serverClientId, false);
  }

  private static MethodCall buildInitMethodCall(
      String clientId, String serverClientId, boolean forceCodeForRefreshToken) {
    return buildInitMethodCall(
        "SignInOption.standard",
        Collections.<String>emptyList(),
        clientId,
        serverClientId,
        forceCodeForRefreshToken);
  }

  private static MethodCall buildInitMethodCall(
      String signInOption,
      List<String> scopes,
      String clientId,
      String serverClientId,
      boolean forceCodeForRefreshToken) {
    HashMap<String, Object> arguments = new HashMap<>();
    arguments.put("signInOption", signInOption);
    arguments.put("scopes", scopes);
    if (clientId != null) {
      arguments.put("clientId", clientId);
    }
    if (serverClientId != null) {
      arguments.put("serverClientId", serverClientId);
    }
    arguments.put("forceCodeForRefreshToken", forceCodeForRefreshToken);
    return new MethodCall("init", arguments);
  }
}
