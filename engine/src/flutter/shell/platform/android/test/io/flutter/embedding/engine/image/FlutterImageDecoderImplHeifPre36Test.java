package io.flutter.embedding.engine.image;

import static org.junit.Assert.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.verify;

import android.graphics.Bitmap;
import android.media.ExifInterface;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import java.nio.ByteBuffer;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.MockitoAnnotations;
import org.robolectric.annotation.Config;

/** Unit tests for {@link FlutterImageDecoderImplHeifPre36}. */
@RunWith(AndroidJUnit4.class)
@Config(manifest = Config.NONE, sdk = 28)
public class FlutterImageDecoderImplHeifPre36Test {
  private FlutterImageDecoderImplHeifPre36 spiedDecoder;
  private Utils spiedUtils;

  @Before
  public void setUp() {
    MockitoAnnotations.openMocks(this);
    spiedUtils = spy(new Utils());
    // Spy the decoder to intercept the call to its super method.
    spiedDecoder = spy(new FlutterImageDecoderImplHeifPre36(spiedUtils));
  }

  @After
  public void tearDown() {
    // Reset the static spy instance to avoid side-effects in other tests.
  }

  @Test
  public void decodeImage_callsSuperAndThenApplyFlip() {
    // 1. Arrange
    final ByteBuffer mockBuffer = ByteBuffer.allocate(10);
    final Metadata testMetadata = new Metadata();
    testMetadata.orientation = ExifInterface.ORIENTATION_FLIP_HORIZONTAL;

    // Create a dummy bitmap that will be "returned" by the superclass.
    final Bitmap mockDecodedBitmap = Bitmap.createBitmap(100, 200, Bitmap.Config.ARGB_8888);

    // When spiedDecoder.decodeImage is called, it will try to call super.decodeImage.
    // We must stub this super call to return our mock bitmap.
    doReturn(mockDecodedBitmap)
        .when((FlutterImageDecoderImplDefault) spiedDecoder)
        .decodeImage(any(ByteBuffer.class), any(Metadata.class));

    // 2. Act
    spiedDecoder.decodeImage(mockBuffer, testMetadata);

    // 3. Assert
    // First, verify that the call to super.decodeImage happened correctly.
    ArgumentCaptor<Metadata> superMetadataCaptor = ArgumentCaptor.forClass(Metadata.class);
    verify((FlutterImageDecoderImplDefault) spiedDecoder)
        .decodeImage(eq(mockBuffer), superMetadataCaptor.capture());
    assertEquals(testMetadata, superMetadataCaptor.getValue());

    // Second, verify that the result from the super call was passed to applyFlipIfNeeded.
    ArgumentCaptor<Bitmap> flipBitmapCaptor = ArgumentCaptor.forClass(Bitmap.class);
    ArgumentCaptor<Integer> orientationCaptor = ArgumentCaptor.forClass(Integer.class);
    verify(spiedUtils).applyFlipIfNeeded(flipBitmapCaptor.capture(), orientationCaptor.capture());

    // Check that the bitmap passed to the flip utility is the one from the super call.
    assertEquals(mockDecodedBitmap, flipBitmapCaptor.getValue());
    // Check that the orientation passed to the flip utility is correct.
    assertEquals((Integer) testMetadata.orientation, orientationCaptor.getValue());
  }
}
