package io.flutter.embedding.android;

import android.content.res.Resources;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.graphics.drawable.Drawable;
import org.robolectric.annotation.Implements;
import org.robolectric.annotation.RealObject;
import org.robolectric.shadow.api.Shadow;

@Implements(Resources.class)
public class SplashShadowResources {
  @RealObject private Resources resources;

  public static final int SPLASH_DRAWABLE_ID = 191919;
  public static final int THEMED_SPLASH_DRAWABLE_ID = 212121;

  // All other getDrawable() calls, call this method internally.
  public Drawable getDrawableForDensity(int id, int density, Resources.Theme theme)
      throws Exception {
    if (id == SPLASH_DRAWABLE_ID) {
      return new ColorDrawable(Color.BLUE);
    }

    if (id == THEMED_SPLASH_DRAWABLE_ID) {
      // We pretend the drawable contains theme references. It can't be parsed without the app
      // theme.
      if (theme == null) {
        throw new Resources.NotFoundException(
            "Cannot parse drawable due to missing theme references.");
      }
      return new ColorDrawable(Color.GRAY);
    }

    return Shadow.directlyOn(resources, Resources.class).getDrawableForDensity(id, density, theme);
  }
}
