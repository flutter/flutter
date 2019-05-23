// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.content.res.AssetManager;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.SystemClock;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
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

    // Must match values in sky::switches
    private static final String AOT_SHARED_LIBRARY_PATH = "aot-shared-library-path";
    private static final String AOT_SNAPSHOT_PATH_KEY = "aot-snapshot-path";
    private static final String AOT_VM_SNAPSHOT_DATA_KEY = "vm-snapshot-data";
    private static final String AOT_VM_SNAPSHOT_INSTR_KEY = "vm-snapshot-instr";
    private static final String AOT_ISOLATE_SNAPSHOT_DATA_KEY = "isolate-snapshot-data";
    private static final String AOT_ISOLATE_SNAPSHOT_INSTR_KEY = "isolate-snapshot-instr";
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
    public static final String PUBLIC_FLUTTER_ASSETS_DIR_KEY =
        FlutterMain.class.getName() + '.' + FLUTTER_ASSETS_DIR_KEY;

    // Resource names used for components of the precompiled snapshot.
    private static final String DEFAULT_AOT_SHARED_LIBRARY_PATH= "app.so";
    private static final String DEFAULT_AOT_VM_SNAPSHOT_DATA = "vm_snapshot_data";
    private static final String DEFAULT_AOT_VM_SNAPSHOT_INSTR = "vm_snapshot_instr";
    private static final String DEFAULT_AOT_ISOLATE_SNAPSHOT_DATA = "isolate_snapshot_data";
    private static final String DEFAULT_AOT_ISOLATE_SNAPSHOT_INSTR = "isolate_snapshot_instr";
    private static final String DEFAULT_LIBRARY = "libflutter.so";
    private static final String DEFAULT_KERNEL_BLOB = "kernel_blob.bin";
    private static final String DEFAULT_FLUTTER_ASSETS_DIR = "flutter_assets";

    @NonNull
    private static String fromFlutterAssets(@NonNull String filePath) {
        return sFlutterAssetsDir + File.separator + filePath;
    }

    // Mutable because default values can be overridden via config properties
    private static String sAotSharedLibraryPath = DEFAULT_AOT_SHARED_LIBRARY_PATH;
    private static String sAotVmSnapshotData = DEFAULT_AOT_VM_SNAPSHOT_DATA;
    private static String sAotVmSnapshotInstr = DEFAULT_AOT_VM_SNAPSHOT_INSTR;
    private static String sAotIsolateSnapshotData = DEFAULT_AOT_ISOLATE_SNAPSHOT_DATA;
    private static String sAotIsolateSnapshotInstr = DEFAULT_AOT_ISOLATE_SNAPSHOT_INSTR;
    private static String sFlutterAssetsDir = DEFAULT_FLUTTER_ASSETS_DIR;

    private static boolean sInitialized = false;
    private static boolean sIsPrecompiledAsBlobs = false;
    private static boolean sIsPrecompiledAsSharedLibrary = false;

    @Nullable
    private static ResourceExtractor sResourceExtractor;
    @Nullable
    private static Settings sSettings;
    @NonNull
    private static String sSnapshotPath;


    private static final class ImmutableSetBuilder<T> {
        static <T> ImmutableSetBuilder<T> newInstance() {
            return new ImmutableSetBuilder<>();
        }

        HashSet<T> set = new HashSet<>();

        private ImmutableSetBuilder() {}

        @NonNull
        ImmutableSetBuilder<T> add(@NonNull T element) {
            set.add(element);
            return this;
        }

        @SafeVarargs
        @NonNull
        final ImmutableSetBuilder<T> add(@NonNull T... elements) {
            for (T element : elements) {
                set.add(element);
            }
            return this;
        }

        @NonNull
        Set<T> build() {
            return Collections.unmodifiableSet(set);
        }
    }

    public static class Settings {
        private String logTag;

        @Nullable
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
    public static void startInitialization(@NonNull Context applicationContext) {
        startInitialization(applicationContext, new Settings());
    }

    /**
     * Starts initialization of the native system.
     * @param applicationContext The Android application context.
     * @param settings Configuration settings.
     */
    public static void startInitialization(@NonNull Context applicationContext, @NonNull Settings settings) {
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
    public static void ensureInitializationComplete(@NonNull Context applicationContext, @Nullable String[] args) {
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
            // There are resources to extract. For example, the AOT blobs from the `assets` directory.
            // `sResourceExtractor` is `null` if there isn't any AOT blob to extract.
            if (sResourceExtractor != null) {
                sResourceExtractor.waitForCompletion();
            }

            List<String> shellArgs = new ArrayList<>();
            shellArgs.add("--icu-symbol-prefix=_binary_icudtl_dat");

            ApplicationInfo applicationInfo = getApplicationInfo(applicationContext);
            shellArgs.add("--icu-native-lib-path=" + applicationInfo.nativeLibraryDir + File.separator + DEFAULT_LIBRARY);

            if (args != null) {
                Collections.addAll(shellArgs, args);
            }
            if (sIsPrecompiledAsSharedLibrary) {
                shellArgs.add("--" + AOT_SHARED_LIBRARY_PATH + "=" +
                    new File(sSnapshotPath, sAotSharedLibraryPath));
            } else {
                if (sIsPrecompiledAsBlobs) {
                    shellArgs.add("--" + AOT_SNAPSHOT_PATH_KEY + "=" + sSnapshotPath);
                } else {
                    shellArgs.add("--cache-dir-path=" + PathUtils.getCacheDirectory(applicationContext));
                    shellArgs.add("--" + AOT_SNAPSHOT_PATH_KEY + "=" + PathUtils.getDataDirectory(applicationContext) + "/" + sFlutterAssetsDir);
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
            String engineCachesPath = PathUtils.getCacheDirectory(applicationContext);
            nativeInit(applicationContext, shellArgs.toArray(new String[0]),
                appBundlePath, appStoragePath, engineCachesPath);

            sInitialized = true;
        } catch (Exception e) {
            Log.e(TAG, "Flutter initialization failed.", e);
            throw new RuntimeException(e);
        }
    }

    /**
     * Same as {@link #ensureInitializationComplete(Context, String[])} but waiting on a background
     * thread, then invoking {@code callback} on the {@code callbackHandler}.
     */
    public static void ensureInitializationCompleteAsync(
        @NonNull Context applicationContext,
        @Nullable String[] args,
        @NonNull Handler callbackHandler,
        @NonNull Runnable callback
    ) {
        if (Looper.myLooper() != Looper.getMainLooper()) {
            throw new IllegalStateException("ensureInitializationComplete must be called on the main thread");
        }
        if (sSettings == null) {
            throw new IllegalStateException("ensureInitializationComplete must be called after startInitialization");
        }
        if (sInitialized) {
            return;
        }
        new Thread(new Runnable() {
            @Override
            public void run() {
                if (sResourceExtractor != null) {
                    sResourceExtractor.waitForCompletion();
                }
                new Handler(Looper.getMainLooper()).post(new Runnable() {
                    @Override
                    public void run() {
                        ensureInitializationComplete(applicationContext.getApplicationContext(), args);
                        callbackHandler.post(callback);
                    }
                });
            }
        }).start();
    }

    private static native void nativeInit(Context context, String[] args, String bundlePath, String appStoragePath, String engineCachesPath);
    private static native void nativeRecordStartTimestamp(long initTimeMillis);

    @NonNull
    private static ApplicationInfo getApplicationInfo(@NonNull Context applicationContext) {
        try {
            return applicationContext
                .getPackageManager()
                .getApplicationInfo(applicationContext.getPackageName(), PackageManager.GET_META_DATA);
        } catch (PackageManager.NameNotFoundException e) {
            throw new RuntimeException(e);
        }
    }

    /**
     * Initialize our Flutter config values by obtaining them from the
     * manifest XML file, falling back to default values.
     */
    private static void initConfig(@NonNull Context applicationContext) {
        Bundle metadata = getApplicationInfo(applicationContext).metaData;

        // There isn't a `<meta-data>` tag as a direct child of `<application>` in
        // `AndroidManifest.xml`.
        if (metadata == null) {
            return;
        }

        sAotSharedLibraryPath = metadata.getString(PUBLIC_AOT_AOT_SHARED_LIBRARY_PATH, DEFAULT_AOT_SHARED_LIBRARY_PATH);
        sFlutterAssetsDir = metadata.getString(PUBLIC_FLUTTER_ASSETS_DIR_KEY, DEFAULT_FLUTTER_ASSETS_DIR);

        sAotVmSnapshotData = metadata.getString(PUBLIC_AOT_VM_SNAPSHOT_DATA_KEY, DEFAULT_AOT_VM_SNAPSHOT_DATA);
        sAotVmSnapshotInstr = metadata.getString(PUBLIC_AOT_VM_SNAPSHOT_INSTR_KEY, DEFAULT_AOT_VM_SNAPSHOT_INSTR);
        sAotIsolateSnapshotData = metadata.getString(PUBLIC_AOT_ISOLATE_SNAPSHOT_DATA_KEY, DEFAULT_AOT_ISOLATE_SNAPSHOT_DATA);
        sAotIsolateSnapshotInstr = metadata.getString(PUBLIC_AOT_ISOLATE_SNAPSHOT_INSTR_KEY, DEFAULT_AOT_ISOLATE_SNAPSHOT_INSTR);
    }

    /**
     * Extract the AOT blobs from the app's asset directory.
     * This is required by the Dart runtime, so it can read the blobs.
     */
    private static void initResources(@NonNull Context applicationContext) {
        // When the AOT blobs are contained in the native library directory,
        // we don't need to extract them manually because they are
        // extracted by the Android Package Manager automatically.
        if (!sSnapshotPath.equals(PathUtils.getDataDirectory(applicationContext))) {
            return;
        }

        new ResourceCleaner(applicationContext).start();

        final String dataDirPath = PathUtils.getDataDirectory(applicationContext);
        final String packageName = applicationContext.getPackageName();
        final PackageManager packageManager = applicationContext.getPackageManager();
        final AssetManager assetManager = applicationContext.getResources().getAssets();
        sResourceExtractor = new ResourceExtractor(dataDirPath, packageName, packageManager, assetManager);

        sResourceExtractor
            .addResource(fromFlutterAssets(sAotVmSnapshotData))
            .addResource(fromFlutterAssets(sAotVmSnapshotInstr))
            .addResource(fromFlutterAssets(sAotIsolateSnapshotData))
            .addResource(fromFlutterAssets(sAotIsolateSnapshotInstr))
            .addResource(fromFlutterAssets(DEFAULT_KERNEL_BLOB));

        if (sIsPrecompiledAsSharedLibrary) {
            sResourceExtractor
                .addResource(sAotSharedLibraryPath);
        } else {
            sResourceExtractor
                .addResource(sAotVmSnapshotData)
                .addResource(sAotVmSnapshotInstr)
                .addResource(sAotIsolateSnapshotData)
                .addResource(sAotIsolateSnapshotInstr);
        }
        sResourceExtractor.start();
    }

    /**
     * Returns a list of the file names at the root of the application's asset
     * path.
     */
    @NonNull
    private static Set<String> listAssets(@NonNull Context applicationContext, @NonNull String path) {
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

    /**
     * Returns a list of the file names at the root of the application's
     * native library directory.
     */
    @NonNull
    private static Set<String> listLibs(@NonNull Context applicationContext) {
        ApplicationInfo applicationInfo = getApplicationInfo(applicationContext);
        File[] files = new File(applicationInfo.nativeLibraryDir).listFiles();

        ImmutableSetBuilder<String> builder = ImmutableSetBuilder.newInstance();
        for (File file : files) {
            builder.add(file.getName());
        }
        return builder.build();
    }

    /**
     * Determines if the APK contains a shared library or AOT snapshots,
     * the file name of the snapshots and the directory where they are contained.
     *
     * <p>The snapshots can be contained in the app's assets or in the native library
     * directory. The default names are:
     *
     * <ul>
     * <li>`vm_snapshot_data`</li>
     * <li>`vm_snapshot_instr`</li>
     * <li>`isolate_snapshot_data`</li>
     * <li>`isolate_snapshot_instr`</li>
     * <li> Shared library: `app.so`</li>
     * </ul>
     *
     * <p>When the blobs are contained in the native library directory,
     * the format <b>`lib_%s.so`</b> is applied to the file name.
     *
     * <p>Note: The name of the files can be customized in the app's metadata, but the
     * format is preserved.
     *
     * <p>The AOT snapshots and the shared library cannot exist at the same time in the APK.
     */
    private static void initAot(@NonNull Context applicationContext) {
        Set<String> assets = listAssets(applicationContext, "");
        Set<String> libs = listLibs(applicationContext);

        String aotVmSnapshotDataLib = "lib_" + sAotVmSnapshotData + ".so";
        String aotVmSnapshotInstrLib = "lib_" + sAotVmSnapshotInstr + ".so";
        String aotIsolateSnapshotDataLib = "lib_" + sAotIsolateSnapshotData + ".so";
        String aotIsolateSnapshotInstrLib = "lib_" + sAotIsolateSnapshotInstr + ".so";
        String aotSharedLibraryLib = "lib_" + sAotSharedLibraryPath + ".so";

        boolean isPrecompiledBlobInLib = libs
            .containsAll(Arrays.asList(
                aotVmSnapshotDataLib,
                aotVmSnapshotInstrLib,
                aotIsolateSnapshotDataLib,
                aotIsolateSnapshotInstrLib
            ));

        if (isPrecompiledBlobInLib) {
            sIsPrecompiledAsBlobs = true;
            sAotVmSnapshotData = aotVmSnapshotDataLib;
            sAotVmSnapshotInstr = aotVmSnapshotInstrLib;
            sAotIsolateSnapshotData = aotIsolateSnapshotDataLib;
            sAotIsolateSnapshotInstr = aotIsolateSnapshotInstrLib;
        } else {
            sIsPrecompiledAsBlobs = assets.containsAll(Arrays.asList(
                sAotVmSnapshotData,
                sAotVmSnapshotInstr,
                sAotIsolateSnapshotData,
                sAotIsolateSnapshotInstr
            ));
        }
        boolean isSharedLibraryInLib = libs.contains(aotSharedLibraryLib);
        boolean isSharedLibraryInAssets = assets.contains(sAotSharedLibraryPath);

        if (isSharedLibraryInLib) {
            sAotSharedLibraryPath = aotSharedLibraryLib;
            sIsPrecompiledAsSharedLibrary = true;
        } else if (isSharedLibraryInAssets) {
            sIsPrecompiledAsSharedLibrary = true;
        }

        if (isSharedLibraryInLib || isPrecompiledBlobInLib) {
            sSnapshotPath = getApplicationInfo(applicationContext).nativeLibraryDir;
        } else {
            sSnapshotPath = PathUtils.getDataDirectory(applicationContext);
        }

        if (sIsPrecompiledAsBlobs && sIsPrecompiledAsSharedLibrary) {
            throw new RuntimeException(
                "Found precompiled app as shared library and as Dart VM snapshots.");
        }
    }

    public static boolean isRunningPrecompiledCode() {
        return sIsPrecompiledAsBlobs || sIsPrecompiledAsSharedLibrary;
    }

    @Nullable
    public static String findAppBundlePath(@NonNull Context applicationContext) {
        String dataDirectory = PathUtils.getDataDirectory(applicationContext);
        File appBundle = new File(dataDirectory, sFlutterAssetsDir);
        return appBundle.exists() ? appBundle.getPath() : null;
    }

    /**
     * Returns the file name for the given asset.
     * The returned file name can be used to access the asset in the APK
     * through the {@link android.content.res.AssetManager} API.
     *
     * @param asset the name of the asset. The name can be hierarchical
     * @return      the filename to be used with {@link android.content.res.AssetManager}
     */
    @NonNull
    public static String getLookupKeyForAsset(@NonNull String asset) {
        return fromFlutterAssets(asset);
    }

    /**
     * Returns the file name for the given asset which originates from the
     * specified packageName. The returned file name can be used to access
     * the asset in the APK through the {@link android.content.res.AssetManager} API.
     *
     * @param asset       the name of the asset. The name can be hierarchical
     * @param packageName the name of the package from which the asset originates
     * @return            the file name to be used with {@link android.content.res.AssetManager}
     */
    @NonNull
    public static String getLookupKeyForAsset(@NonNull String asset, @NonNull String packageName) {
        return getLookupKeyForAsset(
            "packages" + File.separator + packageName + File.separator + asset);
    }
}
