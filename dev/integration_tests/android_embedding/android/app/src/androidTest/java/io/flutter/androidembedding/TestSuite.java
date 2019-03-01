package io.flutter.androidembedding;

import org.junit.Rule;
import org.junit.Test;
import org.junit.runner.RunWith;

import androidx.test.filters.LargeTest;
import androidx.test.rule.ActivityTestRule;
import androidx.test.runner.AndroidJUnit4;

import static androidx.test.espresso.Espresso.onView;
import static androidx.test.espresso.assertion.ViewAssertions.matches;
import static androidx.test.espresso.matcher.ViewMatchers.isDisplayed;
import static androidx.test.espresso.matcher.ViewMatchers.withId;

@RunWith(AndroidJUnit4.class)
@LargeTest
public class TestSuite {

  @Rule
  public ActivityTestRule<MainActivity> activityRule = new ActivityTestRule<>(MainActivity.class);

  @Test
  public void launchApp() {
    onView(withId(R.id.button_fullscreen)).check(matches(isDisplayed()));
  }

}
