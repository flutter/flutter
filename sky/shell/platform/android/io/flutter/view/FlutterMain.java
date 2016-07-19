// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.content.Context;
import android.util.Log;
import android.content.res.AssetManager;
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
import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONTokener;

import org.chromium.base.JNINamespace;
import org.chromium.base.PathUtils;
import org.chromium.base.library_loader.LibraryLoader;
import org.chromium.base.library_loader.LibraryProcessType;
import org.chromium.base.library_loader.ProcessInitException;
import org.chromium.mojo.bindings.Interface.Binding;
import org.chromium.mojo.sensors.SensorServiceImpl;
import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.impl.CoreImpl;
import org.chromium.mojo.system.MessagePipeHandle;
import org.chromium.mojom.activity.Activity;
import org.chromium.mojom.editing.Clipboard;
import org.chromium.mojom.flutter.platform.HapticFeedback;
import org.chromium.mojom.flutter.platform.PathProvider;
import org.chromium.mojom.flutter.platform.SystemChrome;
import org.chromium.mojom.flutter.platform.SystemSound;
import org.chromium.mojom.flutter.platform.UrlLauncher;
import org.chromium.mojom.media.MediaService;
import org.chromium.mojom.mojo.NetworkService;
import org.chromium.mojom.sensors.SensorService;
import org.chromium.mojom.vsync.VSyncProvider;
import org.domokit.activity.ActivityImpl;
import org.domokit.editing.ClipboardImpl;
import org.domokit.media.MediaServiceImpl;
import org.domokit.oknet.NetworkServiceImpl;
import org.domokit.platform.HapticFeedbackImpl;
import org.domokit.platform.PathProviderImpl;
import org.domokit.platform.SystemChromeImpl;
import org.domokit.platform.SystemSoundImpl;
import org.domokit.platform.UrlLauncherImpl;
import org.domokit.vsync.VSyncProviderImpl;

/**
 * A class to intialize the Flutter engine.
 **/
@JNINamespace("sky::shell")
public class FlutterMain {
    private static final String TAG = "FlutterMain";

    // Resource names that can be used for the the FLX application bundle.
    public static final String[] APP_BUNDLE_RESOURCES = {
        "app.flx", "app_profile.flx", "app_release.flx"
    };

    // Resource names used for components of the precompiled snapshot.
    private static final String AOT_INSTR = "snapshot_aot_instr";
    private static final String AOT_ISOLATE = "snapshot_aot_isolate";
    private static final String AOT_RODATA = "snapshot_aot_rodata";
    private static final String AOT_VM_ISOLATE = "snapshot_aot_vmisolate";
    private static final String[] AOT_RESOURCES = {
        AOT_INSTR, AOT_ISOLATE, AOT_RODATA, AOT_VM_ISOLATE
    };

    private static final String MANIFEST = "flutter.yaml";
    private static final String SERVICES = "services.json";
    private static final String PRIVATE_DATA_DIRECTORY_SUFFIX = "sky_shell";

    private static final List<String> SKY_RESOURCES = new ArrayList<String>();
    static {
        Collections.addAll(SKY_RESOURCES, "icudtl.dat", MANIFEST);
        Collections.addAll(SKY_RESOURCES, APP_BUNDLE_RESOURCES);
        Collections.addAll(SKY_RESOURCES, AOT_RESOURCES);
    }

    private static boolean sInitialized = false;
    private static ResourceExtractor sResourceExtractor;
    private static boolean sIsPrecompiled;

    /**
     * Starts initialization of the native system.
     **/
    public static void startInitialization(Context applicationContext) {
        long initStartTimestampMillis = SystemClock.uptimeMillis();
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
     **/
    public static void ensureInitializationComplete(Context applicationContext, String[] args) {
        if (sInitialized) {
            return;
        }
        try {
            sResourceExtractor.waitForCompletion();

            String[] shellArgs = (args != null) ? Arrays.copyOf(args, args.length + 1) : new String[1];
            if (sIsPrecompiled) {
                shellArgs[shellArgs.length - 1] =
                    "--aot-snapshot-path=" + PathUtils.getDataDirectory(applicationContext);
            } else {
                shellArgs[shellArgs.length - 1] =
                    "--cache-dir-path=" + PathUtils.getCacheDirectory(applicationContext);
            }

            nativeInit(applicationContext, shellArgs);

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
        parseServicesConfig(applicationContext, registry);

        registry.register(Activity.MANAGER.getName(), new ServiceFactory() {
            @Override
            public Binding connectToService(FlutterView view, Core core, MessagePipeHandle pipe) {
                return Activity.MANAGER.bind(new ActivityImpl(), pipe);
            }
        });

        registry.register(Clipboard.MANAGER.getName(), new ServiceFactory() {
            @Override
            public Binding connectToService(FlutterView view, Core core, MessagePipeHandle pipe) {
                return Clipboard.MANAGER.bind(new ClipboardImpl(view.getContext()), pipe);
            }
        });

        registry.register(MediaService.MANAGER.getName(), new ServiceFactory() {
            @Override
            public Binding connectToService(FlutterView view, Core core, MessagePipeHandle pipe) {
                return MediaService.MANAGER.bind(new MediaServiceImpl(view.getContext(), core), pipe);
            }
        });

        registry.register(NetworkService.MANAGER.getName(), new ServiceFactory() {
            @Override
            public Binding connectToService(FlutterView view, Core core, MessagePipeHandle pipe) {
                return NetworkService.MANAGER.bind(new NetworkServiceImpl(view.getContext(), core), pipe);
            }
        });

        registry.register(SensorService.MANAGER.getName(), new ServiceFactory() {
            @Override
            public Binding connectToService(FlutterView view, Core core, MessagePipeHandle pipe) {
                return SensorService.MANAGER.bind(new SensorServiceImpl(view.getContext()), pipe);
            }
        });

        registry.register(VSyncProvider.MANAGER.getName(), new ServiceFactory() {
            @Override
            public Binding connectToService(FlutterView view, Core core, MessagePipeHandle pipe) {
                return VSyncProvider.MANAGER.bind(new VSyncProviderImpl(pipe), pipe);
            }
        });

        registry.register(HapticFeedback.MANAGER.getName(), new ServiceFactory() {
            @Override
            public Binding connectToService(FlutterView view, Core core, MessagePipeHandle pipe) {
                return HapticFeedback.MANAGER.bind(new HapticFeedbackImpl((android.app.Activity) view.getContext()), pipe);
            }
        });

        registry.register(PathProvider.MANAGER.getName(), new ServiceFactory() {
            @Override
            public Binding connectToService(FlutterView view, Core core, MessagePipeHandle pipe) {
                return PathProvider.MANAGER.bind(new PathProviderImpl(view.getContext()), pipe);
            }
        });

        registry.register(SystemChrome.MANAGER.getName(), new ServiceFactory() {
            @Override
            public Binding connectToService(FlutterView view, Core core, MessagePipeHandle pipe) {
                SystemChromeImpl chrome = new SystemChromeImpl((android.app.Activity) view.getContext());
                view.addActivityLifecycleListener(chrome);
                return SystemChrome.MANAGER.bind(chrome, pipe);
            }
        });

        registry.register(SystemSound.MANAGER.getName(), new ServiceFactory() {
            @Override
            public Binding connectToService(FlutterView view, Core core, MessagePipeHandle pipe) {
                return SystemSound.MANAGER.bind(new SystemSoundImpl((android.app.Activity) view.getContext()), pipe);
            }
        });

        registry.register(UrlLauncher.MANAGER.getName(), new ServiceFactory() {
            @Override
            public Binding connectToService(FlutterView view, Core core, MessagePipeHandle pipe) {
                return UrlLauncher.MANAGER.bind(new UrlLauncherImpl((android.app.Activity) view.getContext()), pipe);
            }
        });
    }

    /**
     * Parses the auto-generated services.json file, which contains additional services to register.
     */
    private static void parseServicesConfig(Context applicationContext, ServiceRegistry registry) {
        final AssetManager manager = applicationContext.getResources().getAssets();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(manager.open(SERVICES)))) {
            StringBuffer json = new StringBuffer();
            while (true) {
              String line = reader.readLine();
              if (line == null)
                  break;
              json.append(line);
            }

            JSONObject object = (JSONObject) new JSONTokener(json.toString()).nextValue();
            JSONArray services = object.getJSONArray("services");
            for (int i = 0; i < services.length(); ++i) {
                JSONObject service = services.getJSONObject(i);
                String serviceName = service.getString("name");
                String className = service.getString("class");
                registerService(registry, serviceName, className);
            }
        } catch (FileNotFoundException e) {
            // Not all apps will have a services.json file.
            return;
        } catch (Exception e) {
            Log.e(TAG, "Failure parsing service configuration file", e);
            return;
        }
    }

    /**
     * Registers a third-party service.
     */
    private static void registerService(ServiceRegistry registry, final String serviceName, final String className) {
        registry.register(serviceName, new ServiceFactory() {
            @Override
            public Binding connectToService(FlutterView view, Core core, MessagePipeHandle pipe) {
                try {
                    return (Binding) Class.forName(className)
                        .getMethod("connectToService", FlutterView.class, Core.class, MessagePipeHandle.class)
                        .invoke(null, view, core, pipe);
                } catch(Exception e) {
                    Log.e(TAG, "Failed to register service '" + serviceName + "'", e);
                    throw new RuntimeException(e);
                }
            }
        });
    }

    private static void initJavaUtils(Context applicationContext) {
        PathUtils.setPrivateDataDirectorySuffix(PRIVATE_DATA_DIRECTORY_SUFFIX,
                                                applicationContext);
    }

    private static void initResources(Context applicationContext) {
        Context context = applicationContext;
        new ResourceCleaner(context).start();
        sResourceExtractor = new ResourceExtractor(context);
        sResourceExtractor.addResources(SKY_RESOURCES);
        sResourceExtractor.start();
    }

    private static void initNative(Context applicationContext) {
        try {
            LibraryLoader.get(LibraryProcessType.PROCESS_BROWSER).ensureInitialized(applicationContext);
        } catch (ProcessInitException e) {
            Log.e(TAG, "Unable to load Sky Engine binary.", e);
            throw new RuntimeException(e);
        }
    }

    private static void initAot(Context applicationContext) {
        AssetManager manager = applicationContext.getResources().getAssets();
        try {
            HashSet<String> assets = new HashSet<String>();
            Collections.addAll(assets, manager.list(""));
            sIsPrecompiled = assets.containsAll(Arrays.asList(AOT_RESOURCES));
        } catch (IOException e) {
            Log.e(TAG, "Unable to access Flutter resources", e);
            throw new RuntimeException(e);
        }
    }

    public static boolean isRunningPrecompiledCode() {
        return sIsPrecompiled;
    }

    public static String findAppBundlePath(Context applicationContext) {
        String dataDirectory = PathUtils.getDataDirectory(applicationContext);
        for (String appBundleResource : APP_BUNDLE_RESOURCES) {
            File appBundle = new File(dataDirectory, appBundleResource);
            if (appBundle.exists())
                return appBundle.getPath();
        }
        return null;
    }
}
