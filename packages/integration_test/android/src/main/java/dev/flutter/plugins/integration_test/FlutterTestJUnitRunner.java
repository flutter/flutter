package dev.flutter.plugins.integration_test;

import static org.junit.Assume.*;

import android.app.Instrumentation;
import android.content.Intent;
import android.os.Bundle;
import androidx.test.platform.app.InstrumentationRegistry;
import androidx.test.runner.AndroidJUnitRunner;
import com.google.common.util.concurrent.SettableFuture;

import java.util.Map;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;


public class FlutterTestJUnitRunner extends AndroidJUnitRunner {
  private final SettableFuture<IntegrationTestPlugin> pluginSettable = SettableFuture.create();
  public final Future<IntegrationTestPlugin> plugin = pluginSettable;

  @Override
  protected boolean shouldWaitForActivitiesToComplete() {
      return false;
  }

  @Override
  public void onCreate(Bundle arguments) {
    super.onCreate(arguments);
  }

  @Override
  public void onDestroy() {
    super.onDestroy();
  }

  public void registerPlugin(IntegrationTestPlugin plugin) {
    pluginSettable.set(plugin);
  }

  public IntegrationTestPlugin getPlugin() {
    try {
        return this.plugin.get();
    } catch (ExecutionException | InterruptedException e) {
        System.out.println("JOHN failed to getPlugin e=" + e);
    }
    return null;
  }

  public String[] getDartTestList() {
    return getPlugin().getDartTestList();
  }

  public void startActivity(Class<?> activityClass) {
    // This code launches the app under test. It's based on ActivityTestRule#launchActivity.
    // It's simpler because we don't have the need for that much synchronization.
    // Currently, the only synchronization point we're interested in is when the app under test returns the list of tests.
    Instrumentation instrumentation = InstrumentationRegistry.getInstrumentation();
    Intent intent = new Intent(Intent.ACTION_MAIN);
    intent.setClassName(instrumentation.getTargetContext(), activityClass.getCanonicalName());
    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
    System.out.println("JOHN SPAWNING Activity=" + activityClass.getCanonicalName());
    instrumentation.getTargetContext().startActivity(intent);
  }  
}
