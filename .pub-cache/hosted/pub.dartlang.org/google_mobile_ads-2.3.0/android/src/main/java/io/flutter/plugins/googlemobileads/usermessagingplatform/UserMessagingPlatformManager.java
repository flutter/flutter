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

import android.app.Activity;
import android.content.Context;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import com.google.android.ump.ConsentForm;
import com.google.android.ump.ConsentForm.OnConsentFormDismissedListener;
import com.google.android.ump.ConsentInformation;
import com.google.android.ump.ConsentInformation.OnConsentInfoUpdateFailureListener;
import com.google.android.ump.ConsentInformation.OnConsentInfoUpdateSuccessListener;
import com.google.android.ump.ConsentRequestParameters;
import com.google.android.ump.FormError;
import com.google.android.ump.UserMessagingPlatform;
import com.google.android.ump.UserMessagingPlatform.OnConsentFormLoadFailureListener;
import com.google.android.ump.UserMessagingPlatform.OnConsentFormLoadSuccessListener;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.StandardMethodCodec;

/** Manages platform code for UMP SDK. */
public class UserMessagingPlatformManager implements MethodCallHandler {

  private static final String METHOD_CHANNEL_NAME = "plugins.flutter.io/google_mobile_ads/ump";
  /** Use 0 for error code internal to the Flutter plugin. */
  private static final String INTERNAL_ERROR_CODE = "0";

  private final UserMessagingCodec userMessagingCodec;
  private final MethodChannel methodChannel;
  private final Context context;
  @Nullable private ConsentInformation consentInformation;

  @Nullable private Activity activity;

  public UserMessagingPlatformManager(BinaryMessenger binaryMessenger, Context context) {
    userMessagingCodec = new UserMessagingCodec();
    methodChannel =
        new MethodChannel(
            binaryMessenger, METHOD_CHANNEL_NAME, new StandardMethodCodec(userMessagingCodec));
    methodChannel.setMethodCallHandler(this);
    this.context = context;
  }

  @VisibleForTesting
  UserMessagingPlatformManager(
      BinaryMessenger binaryMessenger, Context context, UserMessagingCodec userMessagingCodec) {
    this.userMessagingCodec = userMessagingCodec;
    methodChannel =
        new MethodChannel(
            binaryMessenger, METHOD_CHANNEL_NAME, new StandardMethodCodec(userMessagingCodec));
    methodChannel.setMethodCallHandler(this);
    this.context = context;
  }

  public void setActivity(@Nullable Activity activity) {
    this.activity = activity;
  }

  private ConsentInformation getConsentInformation() {
    if (consentInformation != null) {
      return consentInformation;
    }

    consentInformation = UserMessagingPlatform.getConsentInformation(context);
    return consentInformation;
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull final Result result) {
    switch (call.method) {
      case "ConsentInformation#reset":
        {
          getConsentInformation().reset();
          result.success(null);
          break;
        }
      case "ConsentInformation#getConsentStatus":
        {
          result.success(getConsentInformation().getConsentStatus());
          break;
        }
      case "ConsentInformation#requestConsentInfoUpdate":
        {
          if (activity == null) {
            result.error(
                INTERNAL_ERROR_CODE,
                "ConsentInformation#requestConsentInfoUpdate called before plugin has been registered to an activity.",
                null);
            break;
          }
          ConsentRequestParametersWrapper requestParamsWrapper = call.argument("params");
          ConsentRequestParameters consentRequestParameters =
              (requestParamsWrapper == null)
                  ? new ConsentRequestParameters.Builder().build()
                  : requestParamsWrapper.getAsConsentRequestParameters(activity);
          getConsentInformation()
              .requestConsentInfoUpdate(
                  activity,
                  consentRequestParameters,
                  new OnConsentInfoUpdateSuccessListener() {
                    @Override
                    public void onConsentInfoUpdateSuccess() {
                      result.success(null);
                    }
                  },
                  new OnConsentInfoUpdateFailureListener() {
                    @Override
                    public void onConsentInfoUpdateFailure(FormError error) {
                      result.error(
                          Integer.toString(error.getErrorCode()), error.getMessage(), null);
                    }
                  });
          break;
        }
      case "UserMessagingPlatform#loadConsentForm":
        UserMessagingPlatform.loadConsentForm(
            context,
            new OnConsentFormLoadSuccessListener() {
              @Override
              public void onConsentFormLoadSuccess(ConsentForm consentForm) {
                userMessagingCodec.trackConsentForm(consentForm);
                result.success(consentForm);
              }
            },
            new OnConsentFormLoadFailureListener() {
              @Override
              public void onConsentFormLoadFailure(FormError formError) {
                result.error(
                    Integer.toString(formError.getErrorCode()), formError.getMessage(), null);
              }
            });
        break;
      case "ConsentInformation#isConsentFormAvailable":
        {
          result.success(getConsentInformation().isConsentFormAvailable());
          break;
        }
      case "ConsentForm#show":
        {
          ConsentForm consentForm = call.argument("consentForm");
          if (consentForm == null) {
            result.error(INTERNAL_ERROR_CODE, "ConsentForm#show", null);
          } else {
            consentForm.show(
                activity,
                new OnConsentFormDismissedListener() {
                  @Override
                  public void onConsentFormDismissed(@Nullable FormError formError) {
                    if (formError != null) {
                      result.error(
                          Integer.toString(formError.getErrorCode()), formError.getMessage(), null);
                    } else {
                      result.success(null);
                    }
                  }
                });
          }
          break;
        }
      case "ConsentForm#dispose":
        {
          ConsentForm consentForm = call.argument("consentForm");
          if (consentForm == null) {
            Log.w(INTERNAL_ERROR_CODE, "Called dispose on ad that has been freed");
          } else {
            userMessagingCodec.disposeConsentForm(consentForm);
          }
          result.success(null);
          break;
        }
      default:
        result.notImplemented();
    }
  }
}
