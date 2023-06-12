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

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;
import static org.mockito.Mockito.mock;

import com.google.android.ump.ConsentForm;
import java.nio.ByteBuffer;
import java.util.Collections;
import java.util.List;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;

/** Tests for {@link UserMessagingCodec}. */
@RunWith(RobolectricTestRunner.class)
public class UserMessagingCodecTest {

  private UserMessagingCodec codec;

  @Before
  public void setup() {
    codec = new UserMessagingCodec();
  }

  @Test
  public void testConsentRequestParameters_null() {
    ConsentRequestParametersWrapper params = new ConsentRequestParametersWrapper(null, null);
    final ByteBuffer message = codec.encodeMessage(params);
    ConsentRequestParametersWrapper decoded =
        (ConsentRequestParametersWrapper) codec.decodeMessage((ByteBuffer) message.position(0));
    assertEquals(params, decoded);
  }

  @Test
  public void testConsentRequestParameters_tfuacNull_debugSettingsDefined() {
    ConsentDebugSettingsWrapper debugSettings = new ConsentDebugSettingsWrapper(null, null);
    ConsentRequestParametersWrapper params =
        new ConsentRequestParametersWrapper(null, debugSettings);
    final ByteBuffer message = codec.encodeMessage(params);
    ConsentRequestParametersWrapper decoded =
        (ConsentRequestParametersWrapper) codec.decodeMessage((ByteBuffer) message.position(0));
    assertEquals(params, decoded);
  }

  @Test
  public void testConsentRequestParameters_tfuacDefined_debugSettingsNull() {
    ConsentRequestParametersWrapper params = new ConsentRequestParametersWrapper(true, null);
    final ByteBuffer message = codec.encodeMessage(params);
    ConsentRequestParametersWrapper decoded =
        (ConsentRequestParametersWrapper) codec.decodeMessage((ByteBuffer) message.position(0));
    assertEquals(params, decoded);
  }

  @Test
  public void testConsentRequestParameters_tfuacDefined_debugSettingsDefined() {
    ConsentDebugSettingsWrapper debugSettings = new ConsentDebugSettingsWrapper(null, null);
    ConsentRequestParametersWrapper params =
        new ConsentRequestParametersWrapper(true, debugSettings);
    final ByteBuffer message = codec.encodeMessage(params);
    ConsentRequestParametersWrapper decoded =
        (ConsentRequestParametersWrapper) codec.decodeMessage((ByteBuffer) message.position(0));
    assertEquals(params, decoded);
  }

  @Test
  public void testConsentDebugSettings_null() {
    ConsentDebugSettingsWrapper debugSettings = new ConsentDebugSettingsWrapper(null, null);
    final ByteBuffer message = codec.encodeMessage(debugSettings);
    ConsentDebugSettingsWrapper decoded =
        (ConsentDebugSettingsWrapper) codec.decodeMessage((ByteBuffer) message.position(0));
    assertEquals(debugSettings, decoded);
  }

  @Test
  public void testConsentDebugSettings_debugGeographyDefined_testIdsNull() {
    ConsentDebugSettingsWrapper debugSettings = new ConsentDebugSettingsWrapper(1, null);
    final ByteBuffer message = codec.encodeMessage(debugSettings);
    ConsentDebugSettingsWrapper decoded =
        (ConsentDebugSettingsWrapper) codec.decodeMessage((ByteBuffer) message.position(0));
    assertEquals(debugSettings, decoded);
  }

  @Test
  public void testConsentDebugSettings_debugGeographyNull_testIdsDefined() {
    List<String> testIds = Collections.singletonList("first");
    ConsentDebugSettingsWrapper debugSettings = new ConsentDebugSettingsWrapper(null, testIds);
    final ByteBuffer message = codec.encodeMessage(debugSettings);
    ConsentDebugSettingsWrapper decoded =
        (ConsentDebugSettingsWrapper) codec.decodeMessage((ByteBuffer) message.position(0));
    assertEquals(debugSettings, decoded);
  }

  @Test
  public void testConsentDebugSettings_debugGeographyDefined_testIdsDefined() {
    List<String> testIds = Collections.singletonList("first");
    ConsentDebugSettingsWrapper debugSettings = new ConsentDebugSettingsWrapper(4, testIds);
    final ByteBuffer message = codec.encodeMessage(debugSettings);
    ConsentDebugSettingsWrapper decoded =
        (ConsentDebugSettingsWrapper) codec.decodeMessage((ByteBuffer) message.position(0));
    assertEquals(debugSettings, decoded);
  }

  @Test
  public void testConsentForm() {
    ConsentForm form = mock(ConsentForm.class);
    codec.trackConsentForm(form);
    final ByteBuffer message = codec.encodeMessage(form);

    ConsentForm decoded = (ConsentForm) codec.decodeMessage((ByteBuffer) message.position(0));
    assertEquals(form, decoded);

    // Untrack consent form and verify that value is null
    codec.disposeConsentForm(form);
    decoded = (ConsentForm) codec.decodeMessage((ByteBuffer) message.position(0));
    assertNull(decoded);
  }
}
