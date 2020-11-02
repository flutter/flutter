package com.example.integration_test_example;

import androidx.test.rule.ActivityTestRule;
import dev.flutter.plugins.integration_test.FlutterTestRunner;
import io.flutter.embedding.android.FlutterActivity;
import org.junit.Rule;
import org.junit.runner.RunWith;

@RunWith(FlutterTestRunner.class)
public class FlutterActivityTest {
  @Rule
  public ActivityTestRule<FlutterActivity> rule =
      new ActivityTestRule<>(FlutterActivity.class, true, false);
}
