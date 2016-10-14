// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.content.Context;
import android.util.Log;
import android.content.pm.PackageManager;
import android.content.res.AssetManager;
import android.os.Bundle;
import android.os.SystemClock;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.InputStreamReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONTokener;

import org.chromium.base.JNINamespace;
import org.chromium.base.PathUtils;
import org.chromium.base.library_loader.LibraryLoader;
import org.chromium.base.library_loader.LibraryProcessType;
import org.chromium.base.library_loader.ProcessInitException;
import org.chromium.mojo.bindings.Interface.Binding;
import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.impl.CoreImpl;
import org.chromium.mojo.system.MessagePipeHandle;
import org.chromium.mojom.editing.Clipboard;
import org.chromium.mojom.vsync.VSyncProvider;
import org.domokit.editing.ClipboardImpl;
import org.domokit.vsync.VSyncProviderImpl;

/**
 * A class to intialize the Flutter engine.
 */
@JNINamespace("shell")
public class FlutterMain {
    private static final String TAG = "FlutterMain";

    // Must match values in sky::shell::switches
    private static final String AOT_SNAPSHOT_PATH_KEY = "aot-snapshot-path";
    private static final String AOT_ISOLATE_KEY = "isolate-snapshot";
    private static final String AOT_VM_ISOLATE_KEY = "vm-isolate-snapshot";
    private static final String AOT_INSTRUCTIONS_KEY = "instructions-blob";
    private static final String AOT_RODATA_KEY = "rodata-blob";
    private static final String FLX_KEY = "flx";

    // XML Attribute keys supported in AndroidManifest.xml
    public static final String PUBLIC_AOT_ISOLATE_KEY =
        FlutterMain.class.getName() + '.' + AOT_ISOLATE_KEY;
    public static final String PUBLIC_AOT_VM_ISOLATE_KEY =
        FlutterMain.class.getName() + '.' + AOT_VM_ISOLATE_KEY;
    public static final String PUBLIC_AOT_INSTRUCTIONS_KEY =
        FlutterMain.class.getName() + '.' + AOT_INSTRUCTIONS_KEY;
    public static final String PUBLIC_AOT_RODATA_KEY =
        FlutterMain.class.getName() + '.' + AOT_RODATA_KEY;
    public static final String PUBLIC_FLX_KEY =
        FlutterMain.class.getName() + '.' + FLX_KEY;

    // Resource names used for components of the precompiled snapshot.
    private static final String DEFAULT_AOT_ISOLATE = "snapshot_aot_isolate";
    private static final String DEFAULT_AOT_VM_ISOLATE = "snapshot_aot_vmisolate";
    private static final String DEFAULT_AOT_INSTRUCTIONS = "snapshot_aot_instr";
    private static final String DEFAULT_AOT_RODATA = "snapshot_aot_rodata";
    private static final String DEFAULT_FLX = "app.flx";

    private static final String MANIFEST = "flutter.yaml";
    private static final String PRIVATE_DATA_DIRECTORY_SUFFIX = "sky_shell";

    private static final Set<String> SKY_RESOURCES = ImmutableSetBuilder.<String>newInstance()
        .add("icudtl.dat")
        .add(MANIFEST)
        .build();

    // Mutable because default values can be overridden via config properties
    private static String sAotIsolate = DEFAULT_AOT_ISOLATE;
    private static String sAotVmIsolate = DEFAULT_AOT_VM_ISOLATE;
    private static String sAotInstructions = DEFAULT_AOT_INSTRUCTIONS;
    private static String sAotRodata = DEFAULT_AOT_RODATA;
    private static String sFlx = DEFAULT_FLX;

    private static boolean sInitialized = false;
    private static ResourceExtractor sResourceExtractor;
    private static boolean sIsPrecompiled;

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

    /**
     * Starts initialization of the native system.
     */
    public static void startInitialization(Context applicationContext) {
        long initStartTimestampMillis = SystemClock.uptimeMillis();
        initConfig(applicationContext);
        initJavaUtils(applicationContext);
        initResources(applicationContext);
        initNative(applicationContext);
        initAot(applicationContext);

        // We record the initialization time using SystemClock because at the start of the
        // initialization we have not yet loaded the native library to call into dart_tools_api.h.
        // To get Timeline timestamp of the start of initialization we simply subtract the delta
        // from the Timeline timestamp at the current moment (the assumption is that the overhead
        // of the JNI call is negligible).
        long initTimeMillis = SystemClock.uptimeMillis() - initStartTimestampMillis;
        nativeRecordStartTimestamp(initTimeMillis);

        onServiceRegistryAvailable(applicationContext, ServiceRegistry.SHARED);
    }

    /**
     * Blocks until initialization of the native system has completed.
     */
    public static void ensureInitializationComplete(Context applicationContext, String[] args) {
        if (sInitialized) {
            return;
        }
        try {
            sResourceExtractor.waitForCompletion();

            List<String> shellArgs = new ArrayList<>();
            if (args != null) {
                Collections.addAll(shellArgs, args);
            }
            if (sIsPrecompiled) {
                shellArgs.add("--" + AOT_SNAPSHOT_PATH_KEY + "=" +
                    PathUtils.getDataDirectory(applicationContext));
                shellArgs.add("--" + AOT_ISOLATE_KEY + "=" + sAotIsolate);
                shellArgs.add("--" + AOT_VM_ISOLATE_KEY + "=" + sAotVmIsolate);
                shellArgs.add("--" + AOT_INSTRUCTIONS_KEY + "=" + sAotInstructions);
                shellArgs.add("--" + AOT_RODATA_KEY + "=" + sAotRodata);
            } else {
                shellArgs.add("--cache-dir-path=" +
                    PathUtils.getCacheDirectory(applicationContext));
            }

            nativeInit(applicationContext, shellArgs.toArray(new String[0]));

            // Create the mojo run loop.
            CoreImpl.getInstance().createDefaultRunLoop();
            sInitialized = true;
        } catch (Exception e) {
            Log.e(TAG, "Flutter initialization failed.", e);
            throw new RuntimeException(e);
        }
    }

    private static native void nativeInit(Context context, String[] args);
    private static native void nativeRecordStartTimestamp(long initTimeMillis);

    private static void onServiceRegistryAvailable(final Context applicationContext, ServiceRegistry registry) {
        registry.register(Clipboard.MANAGER.getName(), new ServiceFactory() {
            @Override
            public Binding connectToService(FlutterView view, Core core, MessagePipeHandle pipe) {
                return Clipboard.MANAGER.bind(new ClipboardImpl(view.getContext()), pipe);
            }
        });

        registry.register(VSyncProvider.MANAGER.getName(), new ServiceFactory() {
            @Override
            public Binding connectToService(FlutterView view, Core core, MessagePipeHandle pipe) {
                return VSyncProvider.MANAGER.bind(new VSyncProviderImpl(pipe), pipe);
            }
        });
    }

    /**
     * Initialize our Flutter config values by obtaining them from the
     * manifest XML file, falling back to default values.
     */
    private static void initConfig(Context applicationContext) {
        try {
            Bundle metadata = applicationContext.getPackageManager().getApplicationInfo(
                applicationContext.getPackageName(), PackageManager.GET_META_DATA).metaData;
            if (metadata != null) {
                sAotIsolate = metadata.getString(PUBLIC_AOT_ISOLATE_KEY, DEFAULT_AOT_ISOLATE);
                sAotVmIsolate = metadata.getString(PUBLIC_AOT_VM_ISOLATE_KEY,
                    DEFAULT_AOT_VM_ISOLATE);
                sAotInstructions = metadata.getString(PUBLIC_AOT_INSTRUCTIONS_KEY,
                    DEFAULT_AOT_INSTRUCTIONS);
                sAotRodata = metadata.getString(PUBLIC_AOT_RODATA_KEY, DEFAULT_AOT_RODATA);
                sFlx = metadata.getString(PUBLIC_FLX_KEY, DEFAULT_FLX);
            }
        } catch (PackageManager.NameNotFoundException e) {
            throw new RuntimeException(e);
        }
    }

    private static void initJavaUtils(Context applicationContext) {
        PathUtils.setPrivateDataDirectorySuffix(PRIVATE_DATA_DIRECTORY_SUFFIX,
            applicationContext);
    }

    private static void initResources(Context applicationContext) {
        Context context = applicationContext;
        new ResourceCleaner(context).start();
        sResourceExtractor = new ResourceExtractor(context)
            .addResources(SKY_RESOURCES)
            .addResource(sAotIsolate)
            .addResource(sAotVmIsolate)
            .addResource(sAotInstructions)
            .addResource(sAotRodata)
            .addResource(sFlx)
            .start();
    }

    private static void initNative(Context applicationContext) {
        try {
            LibraryLoader.get(LibraryProcessType.PROCESS_BROWSER)
                .ensureInitialized(applicationContext);
        } catch (ProcessInitException e) {
            Log.e(TAG, "Unable to load Sky Engine binary.", e);
            throw new RuntimeException(e);
        }
    }

    /**
     * Returns a list of the file names at the root of the application's asset
     * path.
     */
    private static Set<String> listRootAssets(Context applicationContext) {
        AssetManager manager = applicationContext.getResources().getAssets();
        try {
            return ImmutableSetBuilder.<String>newInstance()
                .add(manager.list(""))
                .build();
        } catch (IOException e) {
            Log.e(TAG, "Unable to list assets", e);
            throw new RuntimeException(e);
        }
    }

    private static void initAot(Context applicationContext) {
        Set<String> assets = listRootAssets(applicationContext);
        sIsPrecompiled = assets.containsAll(Arrays.asList(
            sAotIsolate,
            sAotVmIsolate,
            sAotInstructions,
            sAotRodata
        ));
    }

    public static boolean isRunningPrecompiledCode() {
        return sIsPrecompiled;
    }

    public static String findAppBundlePath(Context applicationContext) {
        String dataDirectory = PathUtils.getDataDirectory(applicationContext);
        File appBundle = new File(dataDirectory, sFlx);
        return appBundle.exists() ? appBundle.getPath() : null;
    }
}
