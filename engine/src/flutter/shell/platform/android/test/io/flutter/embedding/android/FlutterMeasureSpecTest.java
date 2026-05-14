package io.flutter.embedding.android;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

import android.view.View;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.embedding.android.FlutterMeasureSpec.MeasureCallback;
import org.junit.Test;
import org.junit.runner.RunWith;

@RunWith(AndroidJUnit4.class)
public class FlutterMeasureSpecTest {

  @Test
  public void onMeasure_withUnspecifiedSpecs_defaultsTo1px() {
    int widthMeasureSpec = View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED);
    int heightMeasureSpec = View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED);
    MeasureCallback callback = mock(MeasureCallback.class);

    FlutterMeasureSpec.onMeasure(widthMeasureSpec, heightMeasureSpec, callback);

    verify(callback).onMeasure(1, 1);
  }

  @Test
  public void onMeasure_withExactSpecs_usesExactSizes() {
    int widthMeasureSpec = View.MeasureSpec.makeMeasureSpec(100, View.MeasureSpec.EXACTLY);
    int heightMeasureSpec = View.MeasureSpec.makeMeasureSpec(200, View.MeasureSpec.EXACTLY);
    MeasureCallback callback = mock(MeasureCallback.class);

    FlutterMeasureSpec.onMeasure(widthMeasureSpec, heightMeasureSpec, callback);

    verify(callback).onMeasure(100, 200);
  }

  @Test
  public void onMeasure_withAtMostSpecs_usesAtMostSizes() {
    int widthMeasureSpec = View.MeasureSpec.makeMeasureSpec(100, View.MeasureSpec.AT_MOST);
    int heightMeasureSpec = View.MeasureSpec.makeMeasureSpec(200, View.MeasureSpec.AT_MOST);
    MeasureCallback callback = mock(MeasureCallback.class);

    FlutterMeasureSpec.onMeasure(widthMeasureSpec, heightMeasureSpec, callback);

    verify(callback).onMeasure(100, 200);
  }

  @Test
  public void onMeasure_withMixedSpecs_usesCorrectSizes() {
    int widthMeasureSpec = View.MeasureSpec.makeMeasureSpec(100, View.MeasureSpec.EXACTLY);
    int heightMeasureSpec = View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED);
    MeasureCallback callback = mock(MeasureCallback.class);

    FlutterMeasureSpec.onMeasure(widthMeasureSpec, heightMeasureSpec, callback);

    verify(callback).onMeasure(100, 1);
  }
}
