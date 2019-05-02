package io.flutter.androidembedding.single_activity;

import android.content.Context;
import android.graphics.PixelFormat;
import android.os.Bundle;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.google.android.material.bottomnavigation.BottomNavigationView;

import androidx.appcompat.widget.Toolbar;
import androidx.fragment.app.Fragment;
import androidx.appcompat.app.AppCompatActivity;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import io.flutter.androidembedding.R;
import io.flutter.embedding.android.FlutterFragment;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.engine.FlutterEngine;

public class TabbedActivity extends AppCompatActivity implements FlutterFragment.FlutterEngineProvider {
  private static final String TAG = "TabbedActivity";

  private static FlutterEngine staticEngine;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_tabbed);

    getWindow().setFormat(PixelFormat.TRANSPARENT);

    Toolbar toolbar = (Toolbar) findViewById(R.id.toolbar);
    setSupportActionBar(toolbar);

    BottomNavigationView bottomNav = findViewById(R.id.bottom_navigation);
    bottomNav.setOnNavigationItemSelectedListener(new BottomNavigationView.OnNavigationItemSelectedListener() {
      @Override
      public boolean onNavigationItemSelected(@NonNull MenuItem menuItem) {
        switch (menuItem.getItemId()) {
          case R.id.action_settings:
            showAndroidPage();
            return true;
          case R.id.action_flutter:
            showFlutterPage();
            return true;
        }
        return false;
      }
    });

    if (savedInstanceState == null) {
      getSupportFragmentManager()
          .beginTransaction()
          .add(R.id.container, PlaceholderFragment.newInstance(0))
          .commit();
    }
  }

  private void showAndroidPage() {
    Fragment fragment = getSupportFragmentManager().findFragmentById(R.id.container);
    if (fragment instanceof FlutterFragment) {
      FlutterFragment flutterFragment = (FlutterFragment) fragment;
//      flutterFragment.prepareForNavigation();
    }

    getSupportFragmentManager()
        .beginTransaction()
        .replace(R.id.container, PlaceholderFragment.newInstance(0))
        .commit();
  }

  private void showFlutterPage() {
    Log.d(TAG, "showFlutterPage()");
    Fragment fragment = getSupportFragmentManager().findFragmentById(R.id.container);
    if (fragment instanceof FlutterFragment) {
      FlutterFragment flutterFragment = (FlutterFragment) fragment;
//      flutterFragment.prepareForNavigation();

      getSupportFragmentManager()
          .beginTransaction()
          .remove(flutterFragment)
          .commit();
    } else {
      getSupportFragmentManager()
          .beginTransaction()
          .replace(R.id.container, new FlutterFragment.Builder().dartEntrypoint("fragmentFlutter").build())
          .commit();
    }
  }

  @Nullable
  @Override
  public FlutterEngine getFlutterEngine(@NonNull Context context) {
    if (staticEngine == null) {
      staticEngine = new FlutterEngine(context.getApplicationContext());
    }
    return staticEngine;
  }

  /**
   * A placeholder fragment containing a simple view.
   */
  public static class PlaceholderFragment extends Fragment {
    /**
     * The fragment argument representing the section number for this
     * fragment.
     */
    private static final String ARG_SECTION_NUMBER = "section_number";

    public PlaceholderFragment() {
    }

    /**
     * Returns a new instance of this fragment for the given section
     * number.
     */
    public static PlaceholderFragment newInstance(int sectionNumber) {
      PlaceholderFragment fragment = new PlaceholderFragment();
      Bundle args = new Bundle();
      args.putInt(ARG_SECTION_NUMBER, sectionNumber);
      fragment.setArguments(args);
      return fragment;
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
      View rootView = inflater.inflate(R.layout.fragment_tabbed, container, false);
      TextView textView = (TextView) rootView.findViewById(R.id.section_label);
      textView.setText(getString(R.string.section_format, getArguments().getInt(ARG_SECTION_NUMBER)));
      return rootView;
    }
  }
}
