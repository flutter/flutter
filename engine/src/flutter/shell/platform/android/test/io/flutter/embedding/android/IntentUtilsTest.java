package io.flutter.embedding.android;

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.net.Uri;
import java.util.ArrayList;
import java.util.List;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@RunWith(RobolectricTestRunner.class)
public class IntentUtilsTest {
  private static final String APP_PACKAGE_NAME = "com.test";
  private Activity mockActivity;
  private PackageManager mockPackageManager;
  private ActivityInfo mockActivityInfo;

  @Before
  public void setUp() throws Exception {
    mockActivity = mock(Activity.class);
    mockPackageManager = mock(PackageManager.class);
    mockActivityInfo = new ActivityInfo();

    when(mockActivity.getPackageManager()).thenReturn(mockPackageManager);
    when(mockActivity.getComponentName())
        .thenReturn(new ComponentName(APP_PACKAGE_NAME, "TestActivity"));
    when(mockPackageManager.getActivityInfo(any(ComponentName.class), anyInt()))
        .thenReturn(mockActivityInfo);
    when(mockActivity.getPackageName()).thenReturn(APP_PACKAGE_NAME);
  }

  @Test
  public void isIntentValidForDeeplinking_returnsFalseForMissingData() {
    Intent intent = new Intent(Intent.ACTION_VIEW);
    assertFalse(IntentUtils.isIntentValidForDeeplinking(intent, mockActivity));
  }

  @Test
  public void isIntentValidForDeeplinking_returnsFalseForNonActionView() {
    Intent intent = new Intent("com.custom.ACTION").setData(Uri.parse("http://test.com"));
    assertFalse(IntentUtils.isIntentValidForDeeplinking(intent, mockActivity));
  }

  @Test
  public void isIntentValidForDeeplinking_returnsFalseForNullAction() {
    Intent intent = new Intent().setData(Uri.parse("http://test.com"));
    intent.setAction(null);
    assertFalse(IntentUtils.isIntentValidForDeeplinking(intent, mockActivity));
  }

  @Test
  public void isIntentValidForDeeplinking_returnsTrueWhenMatchesManifest() {
    Intent intent = new Intent(Intent.ACTION_VIEW).setData(Uri.parse("http://test.com"));

    ResolveInfo mockResolveInfo = new ResolveInfo();
    mockResolveInfo.activityInfo = new ActivityInfo();
    mockResolveInfo.activityInfo.name = mockActivity.getClass().getName();

    List<ResolveInfo> resolveInfos = new ArrayList<>();
    resolveInfos.add(mockResolveInfo);

    when(mockPackageManager.queryIntentActivities(any(Intent.class), anyInt()))
        .thenReturn(resolveInfos);

    assertTrue(IntentUtils.isIntentValidForDeeplinking(intent, mockActivity));
  }

  @Test
  public void isIntentValidForDeeplinking_returnsTrueForActivityAlias() {
    Intent intent = new Intent(Intent.ACTION_VIEW).setData(Uri.parse("http://test.com"));

    ResolveInfo mockResolveInfo = new ResolveInfo();
    mockResolveInfo.activityInfo = new ActivityInfo();
    mockResolveInfo.activityInfo.name = APP_PACKAGE_NAME + ".SomeAlias";
    mockResolveInfo.activityInfo.targetActivity = mockActivity.getClass().getName();

    List<ResolveInfo> resolveInfos = new ArrayList<>();
    resolveInfos.add(mockResolveInfo);

    when(mockPackageManager.queryIntentActivities(any(Intent.class), anyInt()))
        .thenReturn(resolveInfos);

    assertTrue(IntentUtils.isIntentValidForDeeplinking(intent, mockActivity));
  }

  @Test
  public void isIntentValidForDeeplinking_handlesType() {
    Intent intent =
        new Intent(Intent.ACTION_VIEW).setDataAndType(Uri.parse("content://test"), "text/plain");

    ResolveInfo mockResolveInfo = new ResolveInfo();
    mockResolveInfo.activityInfo = new ActivityInfo();
    mockResolveInfo.activityInfo.name = mockActivity.getClass().getName();

    List<ResolveInfo> resolveInfos = new ArrayList<>();
    resolveInfos.add(mockResolveInfo);

    // queryIntentActivities should be called with an Intent that has the type
    when(mockPackageManager.queryIntentActivities(any(Intent.class), anyInt()))
        .thenAnswer(
            invocation -> {
              Intent argIntent = invocation.getArgument(0);
              if ("text/plain".equals(argIntent.getType())) {
                return resolveInfos;
              }
              return new ArrayList<ResolveInfo>();
            });

    assertTrue(IntentUtils.isIntentValidForDeeplinking(intent, mockActivity));
  }

  @Test
  @Config(sdk = 33)
  public void checkIntentSource_returnsTrueForNonExportedActivity_legacy() {
    mockActivityInfo.exported = false;
    assertTrue(IntentUtils.checkIntentSource(mockActivity));
  }

  @Test
  @Config(sdk = 33)
  public void checkIntentSource_returnsFalseForExportedActivityWithoutCallingPackage_legacy() {
    mockActivityInfo.exported = true;
    when(mockActivity.getCallingPackage()).thenReturn(null);
    assertFalse(IntentUtils.checkIntentSource(mockActivity));
  }

  @Test
  @Config(sdk = 33)
  public void checkIntentSource_returnsTrueForExportedActivityWithMatchingCallingPackage_legacy() {
    mockActivityInfo.exported = true;
    when(mockActivity.getCallingPackage()).thenReturn(APP_PACKAGE_NAME);
    assertTrue(IntentUtils.checkIntentSource(mockActivity));
  }

  @Test
  @Config(sdk = 33)
  public void checkIntentSource_returnsFalseForExportedActivityWithMismatchCallingPackage_legacy() {
    mockActivityInfo.exported = true;
    when(mockActivity.getCallingPackage()).thenReturn("com.other");
    assertFalse(IntentUtils.checkIntentSource(mockActivity));
  }

  @Test
  @Config(sdk = 34)
  public void checkIntentSource_returnsTrueForExportedActivityWithMatchingUid_api34() {
    mockActivityInfo.exported = true;
    int myUid = android.os.Process.myUid();
    when(mockActivity.getLaunchedFromUid()).thenReturn(myUid);
    assertTrue(IntentUtils.checkIntentSource(mockActivity));
  }

  @Test
  @Config(sdk = 34)
  public void checkIntentSource_returnsFalseForExportedActivityWithMismatchUid_api34() {
    mockActivityInfo.exported = true;
    int myUid = android.os.Process.myUid();
    when(mockActivity.getLaunchedFromUid()).thenReturn(myUid + 1);
    assertFalse(IntentUtils.checkIntentSource(mockActivity));
  }
}
