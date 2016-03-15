// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.sky.shell;

import android.content.Context;
import android.util.Log;
import android.content.res.AssetManager;
import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.InputStreamReader;
import java.io.IOException;
import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONTokener;

import org.chromium.base.JNINamespace;
import org.chromium.base.PathUtils;
import org.chromium.base.library_loader.LibraryLoader;
import org.chromium.base.library_loader.LibraryProcessType;
import org.chromium.base.library_loader.ProcessInitException;
import org.chromium.mojo.sensors.SensorServiceImpl;
import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.impl.CoreImpl;
import org.chromium.mojo.system.MessagePipeHandle;
import org.chromium.mojom.activity.Activity;
import org.chromium.mojom.activity.PathService;
import org.chromium.mojom.flutter.platform.HapticFeedback;
import org.chromium.mojom.flutter.platform.PathProvider;
import org.chromium.mojom.flutter.platform.SystemChrome;
import org.chromium.mojom.flutter.platform.SystemSound;
import org.chromium.mojom.media.MediaService;
import org.chromium.mojom.mojo.NetworkService;
import org.chromium.mojom.sensors.SensorService;
import org.chromium.mojom.vsync.VSyncProvider;
import org.domokit.activity.ActivityImpl;
import org.domokit.activity.PathServiceImpl;
import org.domokit.media.MediaServiceImpl;
import org.domokit.oknet.NetworkServiceImpl;
import org.domokit.platform.HapticFeedbackImpl;
import org.domokit.platform.PathProviderImpl;
import org.domokit.platform.SystemChromeImpl;
import org.domokit.platform.SystemSoundImpl;
import org.domokit.vsync.VSyncProviderImpl;


/**
 * A class to intialize the native code.
 **/
@JNINamespace("sky::shell")
public class SkyMain {
    private static final String TAG = "SkyMain";

    public static final String APP_BUNDLE = "app.flx";
    private static final String MANIFEST = "flutter.yaml";
    private static final String SERVICES = "services.json";

    private static final String PRIVATE_DATA_DIRECTORY_SUFFIX = "sky_shell";
    private static final String[] SKY_RESOURCES = {"icudtl.dat", APP_BUNDLE, MANIFEST};

    /**
     * A guard flag for calling nativeInit() only once.
     **/
    private static boolean sInitialized = false;

    private static ResourceExtractor sResourceExtractor;

    /**
     * Starts initialization of the native system.
     **/
    public static void startInit(Context applicationContext) {
        initJavaUtils(applicationContext);
        initResources(applicationContext);
        initNative(applicationContext);
        onServiceRegistryAvailable(applicationContext, ServiceRegistry.SHARED);
    }

    /**
     * Blocks until initialization of the native system has completed.
     **/
    public static void ensureInitialized(Context applicationContext, String[] args) {
        if (sInitialized) {
            return;
        }
        try {
            sResourceExtractor.waitForCompletion();
            nativeInit(applicationContext, args);
            // Create the mojo run loop.
            CoreImpl.getInstance().createDefaultRunLoop();
            sInitialized = true;
        } catch (Exception e) {
            Log.e(TAG, "SkyMain initialization failed.", e);
            throw new RuntimeException(e);
        }
    }

    private static native void nativeInit(Context context, String[] args);

    private static void onServiceRegistryAvailable(final Context applicationContext, ServiceRegistry registry) {
        parseServicesConfig(applicationContext, registry);

        registry.register(Activity.MANAGER.getName(), new ServiceFactory() {
            @Override
            public void connectToService(Context context, Core core, MessagePipeHandle pipe) {
                Activity.MANAGER.bind(new ActivityImpl(), pipe);
            }
        });

        registry.register(PathService.MANAGER.getName(), new ServiceFactory() {
            @Override
            public void connectToService(Context context, Core core, MessagePipeHandle pipe) {
                PathService.MANAGER.bind(new PathServiceImpl(applicationContext), pipe);
            }
        });

        registry.register(MediaService.MANAGER.getName(), new ServiceFactory() {
            @Override
            public void connectToService(Context context, Core core, MessagePipeHandle pipe) {
                MediaService.MANAGER.bind(new MediaServiceImpl(context, core), pipe);
            }
        });

        registry.register(NetworkService.MANAGER.getName(), new ServiceFactory() {
            @Override
            public void connectToService(Context context, Core core, MessagePipeHandle pipe) {
                NetworkService.MANAGER.bind(new NetworkServiceImpl(context, core), pipe);
            }
        });

        registry.register(SensorService.MANAGER.getName(), new ServiceFactory() {
            @Override
            public void connectToService(Context context, Core core, MessagePipeHandle pipe) {
                SensorService.MANAGER.bind(new SensorServiceImpl(context), pipe);
            }
        });

        registry.register(VSyncProvider.MANAGER.getName(), new ServiceFactory() {
            @Override
            public void connectToService(Context context, Core core, MessagePipeHandle pipe) {
                VSyncProvider.MANAGER.bind(new VSyncProviderImpl(pipe), pipe);
            }
        });

        registry.register(HapticFeedback.MANAGER.getName(), new ServiceFactory() {
            @Override
            public void connectToService(Context context, Core core, MessagePipeHandle pipe) {
                HapticFeedback.MANAGER.bind(new HapticFeedbackImpl(), pipe);
            }
        });

        registry.register(PathProvider.MANAGER.getName(), new ServiceFactory() {
            @Override
            public void connectToService(Context context, Core core, MessagePipeHandle pipe) {
                PathProvider.MANAGER.bind(new PathProviderImpl(context), pipe);
            }
        });

        registry.register(SystemChrome.MANAGER.getName(), new ServiceFactory() {
            @Override
            public void connectToService(Context context, Core core, MessagePipeHandle pipe) {
                SystemChrome.MANAGER.bind(new SystemChromeImpl(), pipe);
            }
        });

        registry.register(SystemSound.MANAGER.getName(), new ServiceFactory() {
            @Override
            public void connectToService(Context context, Core core, MessagePipeHandle pipe) {
                SystemSound.MANAGER.bind(new SystemSoundImpl(), pipe);
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
            public void connectToService(Context context, Core core, MessagePipeHandle pipe) {
                try {
                    Class.forName(className)
                        .getMethod("connectToService", Context.class, Core.class, MessagePipeHandle.class)
                        .invoke(null, context, core, pipe);
                } catch(Exception e) {
                    Log.e(TAG, "Failed to register service '" + serviceName + "'", e);
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
}
