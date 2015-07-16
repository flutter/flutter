// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.services.android;

import android.content.Context;
import android.util.Log;

import dalvik.system.DexClassLoader;

import org.chromium.base.CalledByNative;
import org.chromium.base.JNINamespace;
import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.MessagePipeHandle;
import org.chromium.mojo.system.impl.CoreImpl;

import java.io.File;
import java.io.IOException;
import java.lang.reflect.Method;
import java.util.jar.JarFile;
import java.util.jar.Manifest;

/**
 * Content handler for Android Java code.
 */
@JNINamespace("services::android")
public class JavaHandler {
    private static final String TAG = "JavaHandler";

    /**
     * Extracts and runs the application libraries contained by the indicated archive.
     *
     * @param context the application context
     * @param archivePath the path of the archive containing the application to be run
     * @param cachePath the path to a directory that can be used to save cached data.
     * @param applicationRequestHandle handle to the shell to be passed to the native application.
     *            On the Java side this is opaque payload.
     */
    @CalledByNative
    private static boolean bootstrap(Context context, String archivePath,
            String cachePath, int applicationRequestHandle) {
        File application_java_library = new File(archivePath);

        String dexPath = application_java_library.getAbsolutePath();
        DexClassLoader bootstrapLoader = new DexClassLoader(dexPath,
                cachePath, null, JavaHandler.class.getClassLoader());

        // The starting Mojo class is a class implementing a static MojoMain method. Its name is
        // defined in the .jar manifest file, like a .jar defines a Main-Class attribute for the
        // starting point of a standalone java application.
        String mojoClass;
        try (JarFile jar = new JarFile(application_java_library)) {
            Manifest manifest = jar.getManifest();
            mojoClass = manifest.getMainAttributes().getValue("Mojo-Class");
        } catch (IOException e) {
            Log.e(TAG, "Unable to extract Manifest attributes", e);
            return false;
        }

        if (mojoClass == null) {
            Log.e(TAG, "Mojo-Class class not found");
            return false;
        }

        Core core = CoreImpl.getInstance();
        try (MessagePipeHandle handle = core.acquireNativeHandle(
                applicationRequestHandle).toMessagePipeHandle()) {
            Class<?> loadedClass = bootstrapLoader.loadClass(mojoClass);
            Method mojoMain =
                    loadedClass.getMethod("mojoMain", Context.class, Core.class,
                            MessagePipeHandle.class);
            nativePreInvokeEvent();
            mojoMain.invoke(null, context, core, handle);
        } catch (Throwable t) {
            Log.e(TAG, "Running MojoMain failed.", t);
            return false;
        }
        return true;
    }

    /**
     * Notify the native side before starting the handled application for tracing.
     */
    private static native void nativePreInvokeEvent();
}
