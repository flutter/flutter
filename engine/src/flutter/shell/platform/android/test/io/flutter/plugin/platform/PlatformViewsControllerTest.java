package io.flutter.plugin.platform;

import static org.mockito.Matchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

import android.view.View;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class PlatformViewsControllerTest {
  @Test
  public void itNotifiesVirtualDisplayControllersOfViewAttachmentAndDetachment() {
    // Setup test structure.
    // Create a fake View that represents the View that renders a Flutter UI.
    View fakeFlutterView = new View(RuntimeEnvironment.systemContext);

    // Create fake VirtualDisplayControllers. This requires internal knowledge of
    // PlatformViewsController. We know that all PlatformViewsController does is
    // forward view attachment/detachment calls to it's VirtualDisplayControllers.
    //
    // TODO(mattcarroll): once PlatformViewsController is refactored into testable
    // pieces, remove this test and avoid verifying private behavior.
    VirtualDisplayController fakeVdController1 = mock(VirtualDisplayController.class);
    VirtualDisplayController fakeVdController2 = mock(VirtualDisplayController.class);

    // Create the PlatformViewsController that is under test.
    PlatformViewsController platformViewsController = new PlatformViewsController();

    // Manually inject fake VirtualDisplayControllers into the PlatformViewsController.
    platformViewsController.vdControllers.put(0, fakeVdController1);
    platformViewsController.vdControllers.put(1, fakeVdController1);

    // Execute test & verify results.
    // Attach PlatformViewsController to the fake Flutter View.
    platformViewsController.attachToView(fakeFlutterView);

    // Verify that all virtual display controllers were notified of View attachment.
    verify(fakeVdController1, times(1)).onFlutterViewAttached(eq(fakeFlutterView));
    verify(fakeVdController1, never()).onFlutterViewDetached();
    verify(fakeVdController2, times(1)).onFlutterViewAttached(eq(fakeFlutterView));
    verify(fakeVdController2, never()).onFlutterViewDetached();

    // Detach PlatformViewsController from the fake Flutter View.
    platformViewsController.detachFromView();

    // Verify that all virtual display controllers were notified of the View detachment.
    verify(fakeVdController1, times(1)).onFlutterViewAttached(eq(fakeFlutterView));
    verify(fakeVdController1, times(1)).onFlutterViewDetached();
    verify(fakeVdController2, times(1)).onFlutterViewAttached(eq(fakeFlutterView));
    verify(fakeVdController2, times(1)).onFlutterViewDetached();
  }

  @Test
  public void itCancelsOldPresentationOnResize() {
    // Setup test structure.
    // Create a fake View that represents the View that renders a Flutter UI.
    View fakeFlutterView = new View(RuntimeEnvironment.systemContext);

    // Create fake VirtualDisplayControllers. This requires internal knowledge of
    // PlatformViewsController. We know that all PlatformViewsController does is
    // forward view attachment/detachment calls to it's VirtualDisplayControllers.
    //
    // TODO(mattcarroll): once PlatformViewsController is refactored into testable
    // pieces, remove this test and avoid verifying private behavior.
    VirtualDisplayController fakeVdController1 = mock(VirtualDisplayController.class);

    SingleViewPresentation presentation = fakeVdController1.presentation;

    fakeVdController1.resize(10, 10, null);

    assertEquals(fakeVdController1.presentation != presentation, true);
    assertEquals(presentation.isShowing(), false);
  }
}
