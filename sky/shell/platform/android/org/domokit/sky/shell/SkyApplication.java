// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.sky.shell;

import android.content.Context;
import android.content.res.AssetManager;
import android.util.Log;
import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.InputStreamReader;
import java.io.IOException;
import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONTokener;

import org.chromium.base.BaseChromiumApplication;
import org.chromium.base.library_loader.LibraryLoader;
import org.chromium.base.library_loader.LibraryProcessType;
import org.chromium.base.library_loader.ProcessInitException;
import org.chromium.base.PathUtils;
import org.chromium.mojo.sensors.SensorServiceImpl;
import org.chromium.mojo.system.Core;
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
 * Sky implementation of {@link android.app.Application}, managing application-level global
 * state and initializations.
 */
public class SkyApplication extends BaseChromiumApplication {
    static final String APP_BUNDLE = "app.flx";
    static final String MANIFEST = "flutter.yaml";
    static final String SERVICES = "services.json";

    private static final String TAG = "SkyApplication";
    private static final String PRIVATE_DATA_DIRECTORY_SUFFIX = "sky_shell";
    private static final String[] SKY_RESOURCES = {"icudtl.dat", APP_BUNDLE, MANIFEST};

    private ResourceExtractor mResourceExtractor;

    public ResourceExtractor getResourceExtractor() {
        return mResourceExtractor;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        initJavaUtils();
        initResources();
        initNative();
        UpdateService.init(getApplicationContext());
        onServiceRegistryAvailable(ServiceRegistry.SHARED);
    }

    /**
      * Override this function to add more resources for extraction.
      */
    protected void onBeforeResourceExtraction(ResourceExtractor extractor) {
        extractor.addResources(SKY_RESOURCES);
    }

    /**
      * Override this function to register more services.
      */
    protected void onServiceRegistryAvailable(ServiceRegistry registry) {
        parseServicesConfig(registry);

        registry.register(Activity.MANAGER.getName(), new ServiceFactory() {
            @Override
            public void connectToService(Context context, Core core, MessagePipeHandle pipe) {
                Activity.MANAGER.bind(new ActivityImpl(), pipe);
            }
        });

        registry.register(org.chromium.mojom.updater.UpdateService.MANAGER.getName(),
                          new ServiceFactory() {
            @Override
            public void connectToService(Context context, Core core, MessagePipeHandle pipe) {
                org.chromium.mojom.updater.UpdateService.MANAGER.bind(
                    new UpdateService.MojoService(), pipe);
            }
        });

        registry.register(PathService.MANAGER.getName(), new ServiceFactory() {
            @Override
            public void connectToService(Context context, Core core, MessagePipeHandle pipe) {
                PathService.MANAGER.bind(new PathServiceImpl(getApplicationContext()), pipe);
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
    private void parseServicesConfig(ServiceRegistry registry) {
        final AssetManager manager = getResources().getAssets();
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
    private void registerService(ServiceRegistry registry, final String serviceName, final String className) {
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

    private void initJavaUtils() {
        PathUtils.setPrivateDataDirectorySuffix(PRIVATE_DATA_DIRECTORY_SUFFIX,
                                                getApplicationContext());
    }

    private void initResources() {
        Context context = getApplicationContext();
        new ResourceCleaner(context).start();
        mResourceExtractor = new ResourceExtractor(context);
        onBeforeResourceExtraction(mResourceExtractor);
        mResourceExtractor.start();
    }

    private void initNative() {
        try {
            LibraryLoader.get(LibraryProcessType.PROCESS_BROWSER).ensureInitialized(this);
        } catch (ProcessInitException e) {
            Log.e(TAG, "Unable to load Sky Engine binary.", e);
            throw new RuntimeException(e);
        }
    }
}
