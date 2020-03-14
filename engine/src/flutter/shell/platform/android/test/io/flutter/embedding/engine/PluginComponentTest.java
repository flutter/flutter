package test.io.flutter.embedding.engine;

import static junit.framework.TestCase.assertEquals;
import static org.mockito.Matchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.loader.FlutterLoader;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.invocation.InvocationOnMock;
import org.mockito.stubbing.Answer;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class PluginComponentTest {
  @Test
  public void pluginsCanAccessFlutterAssetPaths() {
    // Setup test.
    FlutterJNI flutterJNI = mock(FlutterJNI.class);
    when(flutterJNI.isAttached()).thenReturn(true);

    // FlutterLoader is the object to which the PluginRegistry defers for obtaining
    // the path to a Flutter asset. Ideally in this component test we would use a
    // real FlutterLoader and directly verify the relationship between FlutterAssets
    // and FlutterLoader. However, a real FlutterLoader cannot be used in a JVM test
    // because it would attempt to load native libraries. Therefore, we create a fake
    // FlutterLoader, but then we defer the corresponding asset lookup methods to the
    // real FlutterLoader singleton. This test ends up verifying that when FlutterAssets
    // is queried for an asset path, it returns the real expected path based on real
    // FlutterLoader behavior.
    FlutterLoader flutterLoader = mock(FlutterLoader.class);
    when(flutterLoader.getLookupKeyForAsset(any(String.class)))
        .thenAnswer(
            new Answer<String>() {
              @Override
              public String answer(InvocationOnMock invocation) throws Throwable {
                // Defer to a real FlutterLoader to return the asset path.
                String fileNameOrSubpath = (String) invocation.getArguments()[0];
                return FlutterLoader.getInstance().getLookupKeyForAsset(fileNameOrSubpath);
              }
            });
    when(flutterLoader.getLookupKeyForAsset(any(String.class), any(String.class)))
        .thenAnswer(
            new Answer<String>() {
              @Override
              public String answer(InvocationOnMock invocation) throws Throwable {
                // Defer to a real FlutterLoader to return the asset path.
                String fileNameOrSubpath = (String) invocation.getArguments()[0];
                String packageName = (String) invocation.getArguments()[1];
                return FlutterLoader.getInstance()
                    .getLookupKeyForAsset(fileNameOrSubpath, packageName);
              }
            });

    // Execute behavior under test.
    FlutterEngine flutterEngine =
        new FlutterEngine(RuntimeEnvironment.application, flutterLoader, flutterJNI);

    // As soon as our plugin is registered it will look up asset paths and store them
    // for our verification.
    PluginThatAccessesAssets plugin = new PluginThatAccessesAssets();
    flutterEngine.getPlugins().add(plugin);

    // Verify results.
    assertEquals("flutter_assets/fake_asset.jpg", plugin.getAssetPathBasedOnName());
    assertEquals(
        "flutter_assets/packages/fakepackage/fake_asset.jpg",
        plugin.getAssetPathBasedOnNameAndPackage());
    assertEquals("flutter_assets/some/path/fake_asset.jpg", plugin.getAssetPathBasedOnSubpath());
    assertEquals(
        "flutter_assets/packages/fakepackage/some/path/fake_asset.jpg",
        plugin.getAssetPathBasedOnSubpathAndPackage());
  }

  private static class PluginThatAccessesAssets implements FlutterPlugin {
    private String assetPathBasedOnName;
    private String assetPathBasedOnNameAndPackage;
    private String assetPathBasedOnSubpath;
    private String assetPathBasedOnSubpathAndPackage;

    public String getAssetPathBasedOnName() {
      return assetPathBasedOnName;
    }

    public String getAssetPathBasedOnNameAndPackage() {
      return assetPathBasedOnNameAndPackage;
    }

    public String getAssetPathBasedOnSubpath() {
      return assetPathBasedOnSubpath;
    }

    public String getAssetPathBasedOnSubpathAndPackage() {
      return assetPathBasedOnSubpathAndPackage;
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
      assetPathBasedOnName = binding.getFlutterAssets().getAssetFilePathByName("fake_asset.jpg");

      assetPathBasedOnNameAndPackage =
          binding.getFlutterAssets().getAssetFilePathByName("fake_asset.jpg", "fakepackage");

      assetPathBasedOnSubpath =
          binding.getFlutterAssets().getAssetFilePathByName("some/path/fake_asset.jpg");

      assetPathBasedOnSubpathAndPackage =
          binding
              .getFlutterAssets()
              .getAssetFilePathByName("some/path/fake_asset.jpg", "fakepackage");
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {}
  }
}
