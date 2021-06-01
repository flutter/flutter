package io.flutter.plugin.common;

import static org.junit.Assert.assertNull;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class BinaryCodecTest {
  @Test
  public void decodeNull() {
    assertNull(BinaryCodec.INSTANCE.decodeMessage(null));
  }
}
