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

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class IntentUtilsTest {
  private Activity mockActivity;
  private PackageManager mockPackageManager;
  private ActivityInfo mockActivityInfo;

  @Before
  public void setUp() throws Exception {
    mockActivity = mock(Activity.class);
    mockPackageManager = mock(PackageManager.class);
    mockActivityInfo = new ActivityInfo();
    
    when(mockActivity.getPackageManager()).thenReturn(mockPackageManager);
    when(mockActivity.getComponentName()).thenReturn(new ComponentName("com.test", "TestActivity"));
    when(mockPackageManager.getActivityInfo(any(ComponentName.class), anyInt())).thenReturn(mockActivityInfo);
    when(mockActivity.getPackageName()).thenReturn("com.test");
  }

  @Test
  public void testIsIntentValidForDeeplinking_returnsFalseForMissingData() {
    Intent intent = new Intent(Intent.ACTION_VIEW);
    assertFalse(IntentUtils.isIntentValidForDeeplinking(intent, mockActivity));
  }

  @Test
  public void testIsIntentValidForDeeplinking_returnsFalseForNonActionView() {
    Intent intent = new Intent("com.custom.ACTION").setData(Uri.parse("http://test.com"));
    assertFalse(IntentUtils.isIntentValidForDeeplinking(intent, mockActivity));
  }

  @Test
  public void testIsIntentValidForDeeplinking_returnsFalseForNullAction() {
    Intent intent = new Intent().setData(Uri.parse("http://test.com"));
    intent.setAction(null);
    assertFalse(IntentUtils.isIntentValidForDeeplinking(intent, mockActivity));
  }

  @Test
  public void testIsIntentValidForDeeplinking_returnsTrueWhenMatchesManifest() {
    Intent intent = new Intent(Intent.ACTION_VIEW).setData(Uri.parse("http://test.com"));
    
    ResolveInfo mockResolveInfo = new ResolveInfo();
    mockResolveInfo.activityInfo = new ActivityInfo();
    mockResolveInfo.activityInfo.name = mockActivity.getClass().getName();
    
    List<ResolveInfo> resolveInfos = new ArrayList<>();
    resolveInfos.add(mockResolveInfo);
    
    when(mockPackageManager.queryIntentActivities(any(Intent.class), anyInt())).thenReturn(resolveInfos);
    
    assertTrue(IntentUtils.isIntentValidForDeeplinking(intent, mockActivity));
  }

  @Test
  public void testIsIntentValidForDeeplinking_returnsTrueForActivityAlias() {
    Intent intent = new Intent(Intent.ACTION_VIEW).setData(Uri.parse("http://test.com"));
    
    ResolveInfo mockResolveInfo = new ResolveInfo();
    mockResolveInfo.activityInfo = new ActivityInfo();
    mockResolveInfo.activityInfo.name = "com.test.SomeAlias";
    mockResolveInfo.activityInfo.targetActivity = mockActivity.getClass().getName();
    
    List<ResolveInfo> resolveInfos = new ArrayList<>();
    resolveInfos.add(mockResolveInfo);
    
    when(mockPackageManager.queryIntentActivities(any(Intent.class), anyInt())).thenReturn(resolveInfos);
    
    assertTrue(IntentUtils.isIntentValidForDeeplinking(intent, mockActivity));
  }

  @Test
  public void testIsIntentValidForDeeplinking_handlesType() {
    Intent intent = new Intent(Intent.ACTION_VIEW).setDataAndType(Uri.parse("content://test"), "text/plain");
    
    ResolveInfo mockResolveInfo = new ResolveInfo();
    mockResolveInfo.activityInfo = new ActivityInfo();
    mockResolveInfo.activityInfo.name = mockActivity.getClass().getName();
    
    List<ResolveInfo> resolveInfos = new ArrayList<>();
    resolveInfos.add(mockResolveInfo);
    
    // queryIntentActivities should be called with an intent that has the type
    when(mockPackageManager.queryIntentActivities(any(Intent.class), anyInt())).thenAnswer(invocation -> {
        Intent argIntent = invocation.getArgument(0);
        if ("text/plain".equals(argIntent.getType())) {
            return resolveInfos;
        }
        return new ArrayList<ResolveInfo>();
    });
    
    assertTrue(IntentUtils.isIntentValidForDeeplinking(intent, mockActivity));
  }
}
