package io.flutter.embedding.android;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

import android.annotation.TargetApi;
import android.graphics.SurfaceTexture;
import android.view.Surface;
import android.view.TextureView;
import androidx.test.core.app.ApplicationProvider;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(AndroidJUnit4.class)
@TargetApi(30)
public class FlutterTextureViewTest {
  @Test
  public void surfaceTextureListenerReleasesRenderer() {
    final FlutterTextureView textureView =
        new FlutterTextureView(ApplicationProvider.getApplicationContext());
    final Surface mockRenderSurface = mock(Surface.class);

    textureView.setRenderSurface(mockRenderSurface);

    final TextureView.SurfaceTextureListener listener = textureView.getSurfaceTextureListener();
    listener.onSurfaceTextureDestroyed(mock(SurfaceTexture.class));

    verify(mockRenderSurface).release();
  }
}
