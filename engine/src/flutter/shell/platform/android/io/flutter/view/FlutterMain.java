// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.content.Context;
import android.content.pm.PackageManager;
import android.content.res.AssetManager;
import android.os.Bundle;
import android.os.Looper;
import android.os.SystemClock;
import android.util.Log;
import io.flutter.util.PathUtils;

import java.io.File;
import java.io.IOException;
import java.util.*;

/**
 * A class to intialize the Flutter engine.
 */
public class FlutterMain {
    private static final String TAG = "FlutterMain";

    // Must match values in sky::shell::switches
    private static final String AOT_SHARED_LIBRARY_PATH = "aot-shared-library-path";
    private static final String AOT_SNAPSHOT_PATH_KEY = "aot-snapshot-path";
    private static final String AOT_VM_SNAPSHOT_DATA_KEY = "vm-snapshot-data";
    private static final String AOT_VM_SNAPSHOT_INSTR_KEY = "vm-snapshot-instr";
    private static final String AOT_ISOLATE_SNAPSHOT_DATA_KEY = "isolate-snapshot-data";
    private static final String AOT_ISOLATE_SNAPSHOT_INSTR_KEY = "isolate-snapshot-instr";
    private static final String FLX_KEY = "flx";
    private static final String SNAPSHOT_BLOB_KEY = "snapshot-blob";
    private static final String FLUTTER_ASSETS_DIR_KEY = "flutter-assets-dir";

    // XML Attribute keys supported in AndroidManifest.xml
    public static final String PUBLIC_AOT_AOT_SHARED_LIBRARY_PATH =
        FlutterMain.class.getName() + '.' + AOT_SHARED_LIBRARY_PATH;
    public static final String PUBLIC_AOT_VM_SNAPSHOT_DATA_KEY =
        FlutterMain.class.getName() + '.' + AOT_VM_SNAPSHOT_DATA_KEY;
    public static final String PUBLIC_AOT_VM_SNAPSHOT_INSTR_KEY =
        FlutterMain.class.getName() + '.' + AOT_VM_SNAPSHOT_INSTR_KEY;
    public static final String PUBLIC_AOT_ISOLATE_SNAPSHOT_DATA_KEY =
        FlutterMain.class.getName() + '.' + AOT_ISOLATE_SNAPSHOT_DATA_KEY;
    public static final String PUBLIC_AOT_ISOLATE_SNAPSHOT_INSTR_KEY =
        FlutterMain.class.getName() + '.' + AOT_ISOLATE_SNAPSHOT_INSTR_KEY;
    public static final String PUBLIC_FLX_KEY =
        FlutterMain.class.getName() + '.' + FLX_KEY;
    public static final String PUBLIC_SNAPSHOT_BLOB_KEY =
        FlutterMain.class.getName() + '.' + SNAPSHOT_BLOB_KEY;
    public static final String PUBLIC_FLUTTER_ASSETS_DIR_KEY =
        FlutterMain.class.getName() + '.' + FLUTTER_ASSETS_DIR_KEY;

    // Resource names used for components of the precompiled snapshot.
    private static final String DEFAULT_AOT_SHARED_LIBRARY_PATH= "app.so";
    private static final String DEFAULT_AOT_VM_SNAPSHOT_DATA = "vm_snapshot_data";
    private static final String DEFAULT_AOT_VM_SNAPSHOT_INSTR = "vm_snapshot_instr";
    private static final String DEFAULT_AOT_ISOLATE_SNAPSHOT_DATA = "isolate_snapshot_data";
    private static final String DEFAULT_AOT_ISOLATE_SNAPSHOT_INSTR = "isolate_snapshot_instr";
    private static final String DEFAULT_FLX = "app.flx";
    private static final String DEFAULT_SNAPSHOT_BLOB = "snapshot_blob.bin";
    private static final String DEFAULT_KERNEL_BLOB = "kernel_blob.bin";
    private static final String DEFAULT_PLATFORM_DILL = "platform_strong.dill";
    private static final String DEFAULT_FLUTTER_ASSETS_DIR = "flutter_assets";

    // Assets that are shared among all Flutter apps within an APK.
    private static final String SHARED_ASSET_DIR = "flutter_shared";
    private static final String SHARED_ASSET_ICU_DATA = "icudtl.dat";

    private static String fromFlutterAssets(String filePath) {
        return sFlutterAssetsDir + File.separator + filePath;
    }

    // Mutable because default values can be overridden via config properties
    private static String sAotSharedLibraryPath = DEFAULT_AOT_SHARED_LIBRARY_PATH;
    private static String sAotVmSnapshotData = DEFAULT_AOT_VM_SNAPSHOT_DATA;
    private static String sAotVmSnapshotInstr = DEFAULT_AOT_VM_SNAPSHOT_INSTR;
    private static String sAotIsolateSnapshotData = DEFAULT_AOT_ISOLATE_SNAPSHOT_DATA;
    private static String sAotIsolateSnapshotInstr = DEFAULT_AOT_ISOLATE_SNAPSHOT_INSTR;
    private static String sFlx = DEFAULT_FLX;
    private static String sSnapshotBlob = DEFAULT_SNAPSHOT_BLOB;
    private static String sFlutterAssetsDir = DEFAULT_FLUTTER_ASSETS_DIR;

    private static boolean sInitialized = false;
    private static ResourceExtractor sResourceExtractor;
    private static boolean sIsPrecompiledAsBlobs;
    private static boolean sIsPrecompiledAsSharedLibrary;
    private static Settings sSettings;
    private static String sIcuDataPath;

    private static final class ImmutableSetBuilder<T> {
        static <T> ImmutableSetBuilder<T> newInstance() {
            return new ImmutableSetBuilder<>();
        }

        HashSet<T> set = new HashSet<>();

        private ImmutableSetBuilder() {}

        ImmutableSetBuilder<T> add(T element) {
            set.add(element);
            return this;
        }

        @SafeVarargs
        final ImmutableSetBuilder<T> add(T... elements) {
            for (T element : elements) {
                set.add(element);
            }
            return this;
        }

        Set<T> build() {
            return Collections.unmodifiableSet(set);
        }
    }

    public static class Settings {
        private String logTag;

        public String getLogTag() {
            return logTag;
        }

        /**
         * Set the tag associated with Flutter app log messages.
         * @param tag Log tag.
         */
        public void setLogTag(String tag) {
            logTag = tag;
        }
    }

    /**
     * Starts initialization of the native system.
     * @param applicationContext The Android application context.
     */
    public static void startInitialization(Context applicationContext) {
        startInitialization(applicationContext, new Settings());
    }

    /**
     * Starts initialization of the native system.
     * @param applicationContext The Android application context.
     * @param settings Configuration settings.
     */
    public static void startInitialization(Context applicationContext, Settings settings) {
        if (Looper.myLooper() != Looper.getMainLooper()) {
          throw new IllegalStateException("startInitialization must be called on the main thread");
        }
        // Do not run startInitialization more than once.
        if (sSettings != null) {
          return;
        }

        sSettings = settings;

        long initStartTimestampMillis = SystemClock.uptimeMillis();
        initConfig(applicationContext);
        initAot(applicationContext);
        initResources(applicationContext);
        System.loadLibrary("flutter");

        // We record the initialization time using SystemClock because at the start of the
        // initialization we have not yet loaded the native library to call into dart_tools_api.h.
        // To get Timeline timestamp of the start of initialization we simply subtract the delta
        // from the Timeline timestamp at the current moment (the assumption is that the overhead
        // of the JNI call is negligible).
        long initTimeMillis = SystemClock.uptimeMillis() - initStartTimestampMillis;
        nativeRecordStartTimestamp(initTimeMillis);
    }

    /**
     * Blocks until initialization of the native system has completed.
     * @param applicationContext The Android application context.
     * @param args Flags sent to the Flutter runtime.
     */
    public static void ensureInitializationComplete(Context applicationContext, String[] args) {
        if (Looper.myLooper() != Looper.getMainLooper()) {
          throw new IllegalStateException("ensureInitializationComplete must be called on the main thread");
        }
        if (sSettings == null) {
          throw new IllegalStateException("ensureInitializationComplete must be called after startInitialization");
        }
        if (sInitialized) {
            return;
        }
        try {
            sResourceExtractor.waitForCompletion();

            List<String> shellArgs = new ArrayList<>();
            shellArgs.add("--icu-data-file-path=" + sIcuDataPath);
            if (args != null) {
                Collections.addAll(shellArgs, args);
            }
            if (sIsPrecompiledAsSharedLibrary) {
                shellArgs.add("--" + AOT_SHARED_LIBRARY_PATH + "=" +
                    new File(PathUtils.getDataDirectory(applicationContext), sAotSharedLibraryPath));
            } else {
                if (sIsPrecompiledAsBlobs) {
                    shellArgs.add("--" + AOT_SNAPSHOT_PATH_KEY + "=" +
                        PathUtils.getDataDirectory(applicationContext));
                } else {
                    shellArgs.add("--cache-dir-path=" +
                        PathUtils.getCacheDirectory(applicationContext));

                    shellArgs.add("--" + AOT_SNAPSHOT_PATH_KEY + "=" +
                        PathUtils.getDataDirectory(applicationContext) + "/" + sFlutterAssetsDir);
                }
                shellArgs.add("--" + AOT_VM_SNAPSHOT_DATA_KEY + "=" + sAotVmSnapshotData);
                shellArgs.add("--" + AOT_VM_SNAPSHOT_INSTR_KEY + "=" + sAotVmSnapshotInstr);
                shellArgs.add("--" + AOT_ISOLATE_SNAPSHOT_DATA_KEY + "=" + sAotIsolateSnapshotData);
                shellArgs.add("--" + AOT_ISOLATE_SNAPSHOT_INSTR_KEY + "=" + sAotIsolateSnapshotInstr);
            }

            if (sSettings.getLogTag() != null) {
                shellArgs.add("--log-tag=" + sSettings.getLogTag());
            }

            String appBundlePath = findAppBundlePath(applicationContext);
            String appStoragePath = PathUtils.getFilesDir(applicationContext);
            nativeInit(applicationContext, shellArgs.toArray(new String[0]),
                appBundlePath, appStoragePath);

            sInitialized = true;
        } catch (Exception e) {
            Log.e(TAG, "Flutter initialization failed.", e);
            throw new RuntimeException(e);
        }
    }

    private static native void nativeInit(Context context, String[] args, String bundlePath, String appStoragePath);
    private static native void nativeRecordStartTimestamp(long initTimeMillis);

    /**
     * Initialize our Flutter config values by obtaining them from the
     * manifest XML file, falling back to default values.
     */
    private static void initConfig(Context applicationContext) {
        try {
            Bundle metadata = applicationContext.getPackageManager().getApplicationInfo(
                applicationContext.getPackageName(), PackageManager.GET_META_DATA).metaData;
            if (metadata != null) {
                sAotSharedLibraryPath = metadata.getString(PUBLIC_AOT_AOT_SHARED_LIBRARY_PATH, DEFAULT_AOT_SHARED_LIBRARY_PATH);
                sAotVmSnapshotData = metadata.getString(PUBLIC_AOT_VM_SNAPSHOT_DATA_KEY, DEFAULT_AOT_VM_SNAPSHOT_DATA);
                sAotVmSnapshotInstr = metadata.getString(PUBLIC_AOT_VM_SNAPSHOT_INSTR_KEY, DEFAULT_AOT_VM_SNAPSHOT_INSTR);
                sAotIsolateSnapshotData = metadata.getString(PUBLIC_AOT_ISOLATE_SNAPSHOT_DATA_KEY, DEFAULT_AOT_ISOLATE_SNAPSHOT_DATA);
                sAotIsolateSnapshotInstr = metadata.getString(PUBLIC_AOT_ISOLATE_SNAPSHOT_INSTR_KEY, DEFAULT_AOT_ISOLATE_SNAPSHOT_INSTR);
                sFlx = metadata.getString(PUBLIC_FLX_KEY, DEFAULT_FLX);
                sSnapshotBlob = metadata.getString(PUBLIC_SNAPSHOT_BLOB_KEY, DEFAULT_SNAPSHOT_BLOB);
                sFlutterAssetsDir = metadata.getString(PUBLIC_FLUTTER_ASSETS_DIR_KEY, DEFAULT_FLUTTER_ASSETS_DIR);
            }
        } catch (PackageManager.NameNotFoundException e) {
            throw new RuntimeException(e);
        }
    }

    private static void initResources(Context applicationContext) {
        Context context = applicationContext;
        new ResourceCleaner(context).start();

        sResourceExtractor = new ResourceExtractor(context);

        // Search for the icudtl.dat file at the old and new locations.
        // TODO(jsimmons): remove the old location when all tools have been updated.
        Set<String> sharedAssets = listAssets(applicationContext, SHARED_ASSET_DIR);
        String icuAssetPath;
        if (sharedAssets.contains(SHARED_ASSET_ICU_DATA)) {
          icuAssetPath = SHARED_ASSET_DIR + File.separator + SHARED_ASSET_ICU_DATA;
        } else {
          icuAssetPath = SHARED_ASSET_ICU_DATA;
        }
        sResourceExtractor.addResource(icuAssetPath);
        sIcuDataPath = PathUtils.getDataDirectory(applicationContext) + File.separator + icuAssetPath;

        sResourceExtractor
            .addResource(fromFlutterAssets(sFlx))
            .addResource(fromFlutterAssets(sSnapshotBlob))
            .addResource(fromFlutterAssets(sAotVmSnapshotData))
            .addResource(fromFlutterAssets(sAotVmSnapshotInstr))
            .addResource(fromFlutterAssets(sAotIsolateSnapshotData))
            .addResource(fromFlutterAssets(sAotIsolateSnapshotInstr))
            .addResource(fromFlutterAssets(DEFAULT_KERNEL_BLOB))
            .addResource(fromFlutterAssets(DEFAULT_PLATFORM_DILL));
        if (sIsPrecompiledAsSharedLibrary) {
          sResourceExtractor
            .addResource(sAotSharedLibraryPath);
        } else {
          sResourceExtractor
            .addResource(sAotVmSnapshotData)
            .addResource(sAotVmSnapshotInstr)
            .addResource(sAotIsolateSnapshotData)
            .addResource(sAotIsolateSnapshotInstr)
            .addResource(sSnapshotBlob);
        }
        sResourceExtractor.start();
    }

    /**
     * Returns a list of the file names at the root of the application's asset
     * path.
     */
    private static Set<String> listAssets(Context applicationContext, String path) {
        AssetManager manager = applicationContext.getResources().getAssets();
        try {
            return ImmutableSetBuilder.<String>newInstance()
                .add(manager.list(path))
                .build();
        } catch (IOException e) {
            Log.e(TAG, "Unable to list assets", e);
            throw new RuntimeException(e);
        }
    }

    private static void initAot(Context applicationContext) {
        Set<String> assets = listAssets(applicationContext, "");
        sIsPrecompiledAsBlobs = assets.containsAll(Arrays.asList(
            sAotVmSnapshotData,
            sAotVmSnapshotInstr,
            sAotIsolateSnapshotData,
            sAotIsolateSnapshotInstr
        ));
        sIsPrecompiledAsSharedLibrary = assets.contains(sAotSharedLibraryPath);
        if (sIsPrecompiledAsBlobs && sIsPrecompiledAsSharedLibrary) {
          throw new RuntimeException(
              "Found precompiled app as shared library and as Dart VM snapshots.");
        }
    }

    public static boolean isRunningPrecompiledCode() {
        return sIsPrecompiledAsBlobs || sIsPrecompiledAsSharedLibrary;
    }

    public static String findAppBundlePath(Context applicationContext) {
        String dataDirectory = PathUtils.getDataDirectory(applicationContext);
        File appBundle = new File(dataDirectory, sFlutterAssetsDir);
        return appBundle.exists() ? appBundle.getPath() : null;
    }

    /**
     * Returns the file name for the given asset.
     * The returned file name can be used to access the asset in the APK
     * through the {@link AssetManager} API.
     *
     * @param asset the name of the asset. The name can be hierarchical
     * @return      the filename to be used with {@link AssetManager}
     */
    public static String getLookupKeyForAsset(String asset) {
        return fromFlutterAssets(asset);
    }

    /**
     * Returns the file name for the given asset which originates from the
     * specified packageName. The returned file name can be used to access
     * the asset in the APK through the {@link AssetManager} API.
     *
     * @param asset       the name of the asset. The name can be hierarchical
     * @param packageName the name of the package from which the asset originates
     * @return            the file name to be used with {@link AssetManager}
     */
    public static String getLookupKeyForAsset(String asset, String packageName) {
        return getLookupKeyForAsset(
            "packages" + File.separator + packageName + File.separator + asset);
    }
}
