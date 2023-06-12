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

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.google.android.ump.ConsentForm;
import io.flutter.plugin.common.StandardMessageCodec;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/** Codec for UMP SDK. */
public class UserMessagingCodec extends StandardMessageCodec {

  private static final byte VALUE_CONSENT_REQUEST_PARAMETERS = (byte) 129;
  private static final byte VALUE_CONSENT_DEBUG_SETTINGS = (byte) 130;
  private static final byte VALUE_CONSENT_FORM = (byte) 131;

  private final Map<Integer, ConsentForm> consentFormMap;

  UserMessagingCodec() {
    consentFormMap = new HashMap<>();
  }

  @Override
  protected void writeValue(@NonNull ByteArrayOutputStream stream, @NonNull Object value) {
    if (value instanceof ConsentRequestParametersWrapper) {
      stream.write(VALUE_CONSENT_REQUEST_PARAMETERS);
      ConsentRequestParametersWrapper params = (ConsentRequestParametersWrapper) value;
      writeValue(stream, params.getTfuac());
      writeValue(stream, params.getDebugSettings());
    } else if (value instanceof ConsentDebugSettingsWrapper) {
      stream.write(VALUE_CONSENT_DEBUG_SETTINGS);
      ConsentDebugSettingsWrapper debugSettings = (ConsentDebugSettingsWrapper) value;
      writeValue(stream, debugSettings.getDebugGeography());
      writeValue(stream, debugSettings.getTestIdentifiers());
    } else if (value instanceof ConsentForm) {
      stream.write(VALUE_CONSENT_FORM);
      writeValue(stream, value.hashCode());
    } else {
      super.writeValue(stream, value);
    }
  }

  @Nullable
  private List<String> asList(@Nullable Object maybeList) {
    if (maybeList == null) {
      return null;
    }
    List<String> stringList = new ArrayList<>();
    if (maybeList instanceof List) {
      List<?> list = (List<?>) maybeList;
      for (Object obj : list) {
        if (obj instanceof String) {
          stringList.add((String) obj);
        }
      }
    }
    return stringList;
  }

  @Override
  protected Object readValueOfType(byte type, @NonNull ByteBuffer buffer) {
    switch (type) {
      case VALUE_CONSENT_REQUEST_PARAMETERS:
        {
          Boolean tfuac = (Boolean) readValueOfType(buffer.get(), buffer);
          ConsentDebugSettingsWrapper debugSettings =
              (ConsentDebugSettingsWrapper) readValueOfType(buffer.get(), buffer);
          return new ConsentRequestParametersWrapper(tfuac, debugSettings);
        }
      case VALUE_CONSENT_DEBUG_SETTINGS:
        {
          Integer debugGeoInt = (Integer) readValueOfType(buffer.get(), buffer);
          List<String> testIdentifiers = asList(readValueOfType(buffer.get(), buffer));
          return new ConsentDebugSettingsWrapper(debugGeoInt, testIdentifiers);
        }
      case VALUE_CONSENT_FORM:
        {
          Integer hash = (Integer) readValueOfType(buffer.get(), buffer);
          return consentFormMap.get(hash);
        }
      default:
        return super.readValueOfType(type, buffer);
    }
  }

  void trackConsentForm(ConsentForm form) {
    consentFormMap.put(form.hashCode(), form);
  }

  void disposeConsentForm(ConsentForm form) {
    consentFormMap.remove(form.hashCode());
  }
}
