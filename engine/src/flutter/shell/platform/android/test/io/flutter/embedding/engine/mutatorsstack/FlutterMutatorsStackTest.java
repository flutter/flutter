package io.flutter.embedding.engine.mutatorsstack;

import static org.junit.Assert.assertEquals;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class FlutterMutatorsStackTest {

  @Test
  public void pushOpacity() {
    final FlutterMutatorsStack mutatorsStack = new FlutterMutatorsStack();
    mutatorsStack.pushOpacity(.5f);

    assertEquals(mutatorsStack.getMutators().size(), 1);
    assertEquals(
        mutatorsStack.getMutators().get(0).getType(),
        FlutterMutatorsStack.FlutterMutatorType.OPACITY);
    assertEquals(mutatorsStack.getMutators().get(0).getOpacity(), .5f, 0f);
  }

  @Test
  public void defaultOpacity() {
    final FlutterMutatorsStack mutatorsStack = new FlutterMutatorsStack();

    assertEquals(1f, mutatorsStack.getFinalOpacity(), 0f);
  }

  @Test
  public void layeredOpacity() {
    final FlutterMutatorsStack mutatorsStack = new FlutterMutatorsStack();
    mutatorsStack.pushOpacity(.5f);
    mutatorsStack.pushOpacity(.6f);
    mutatorsStack.pushOpacity(1f);

    assertEquals(.3f, mutatorsStack.getFinalOpacity(), 1 / 255);
  }
}
