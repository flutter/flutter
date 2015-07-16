// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base.library_loader;

import android.annotation.TargetApi;
import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.os.AsyncTask;
import android.os.Build;
import android.os.SystemClock;
import android.util.Log;

import org.chromium.base.CalledByNative;
import org.chromium.base.CommandLine;
import org.chromium.base.JNINamespace;
import org.chromium.base.PackageUtils;
import org.chromium.base.TraceEvent;
import org.chromium.base.VisibleForTesting;
import org.chromium.base.metrics.RecordHistogram;

import javax.annotation.Nullable;

/**
 * This class provides functionality to load and register the native libraries.
 * Callers are allowed to separate loading the libraries from initializing them.
 * This may be an advantage for Android Webview, where the libraries can be loaded
 * by the zygote process, but then needs per process initialization after the
 * application processes are forked from the zygote process.
 *
 * The libraries may be loaded and initialized from any thread. Synchronization
 * primitives are used to ensure that overlapping requests from different
 * threads are handled sequentially.
 *
 * See also base/android/library_loader/library_loader_hooks.cc, which contains
 * the native counterpart to this class.
 */
@JNINamespace("base::android")
public class LibraryLoader {
    private static final String TAG = "LibraryLoader";

    // Set to true to enable debug logs.
    private static final boolean DEBUG = false;

    // Guards all access to the libraries
    private static final Object sLock = new Object();

    // The singleton instance of LibraryLoader.
    private static volatile LibraryLoader sInstance;

    // One-way switch becomes true when the libraries are loaded.
    private boolean mLoaded;

    // One-way switch becomes true when the Java command line is switched to
    // native.
    private boolean mCommandLineSwitched;

    // One-way switch becomes true when the libraries are initialized (
    // by calling nativeLibraryLoaded, which forwards to LibraryLoaded(...) in
    // library_loader_hooks.cc).
    // Note that this member should remain a one-way switch, since it accessed from multiple
    // threads without a lock.
    private volatile boolean mInitialized;

    // One-way switches recording attempts to use Relro sharing in the browser.
    // The flags are used to report UMA stats later.
    private boolean mIsUsingBrowserSharedRelros;
    private boolean mLoadAtFixedAddressFailed;

    // One-way switch becomes true if the Chromium library was loaded from the
    // APK file directly.
    private boolean mLibraryWasLoadedFromApk;

    // One-way switch becomes false if the Chromium library should be loaded
    // directly from the APK file but it was compressed or not aligned.
    private boolean mLibraryIsMappableInApk = true;

    // The type of process the shared library is loaded in.
    // This member can be accessed from multiple threads simultaneously, so it have to be
    // final (like now) or be protected in some way (volatile of synchronized).
    private final int mLibraryProcessType;

    /**
     * @param libraryProcessType the process the shared library is loaded in. refer to
     *                           LibraryProcessType for possible values.
     * @return LibraryLoader if existing, otherwise create a new one.
     */
    public static LibraryLoader get(int libraryProcessType) throws ProcessInitException {
        synchronized (sLock) {
            if (sInstance != null) {
                if (sInstance.mLibraryProcessType == libraryProcessType) return sInstance;
                throw new ProcessInitException(
                        LoaderErrors.LOADER_ERROR_NATIVE_LIBRARY_LOAD_FAILED);
            }
            sInstance = new LibraryLoader(libraryProcessType);
            return sInstance;
        }
    }

    private LibraryLoader(int libraryProcessType) {
        mLibraryProcessType = libraryProcessType;
    }

    /**
     * The same as ensureInitialized(null, false), should only be called
     * by non-browser processes.
     *
     * @throws ProcessInitException
     */
    @VisibleForTesting
    public void ensureInitialized() throws ProcessInitException {
        ensureInitialized(null, false);
    }

    /**
     *  This method blocks until the library is fully loaded and initialized.
     *
     *  @param context The context in which the method is called, the caller
     *    may pass in a null context if it doesn't know in which context it
     *    is running.
     *
     *  @param shouldDeleteFallbackLibraries The flag tells whether the method
     *    should delete the fallback libraries or not.
     */
    public void ensureInitialized(
            Context context, boolean shouldDeleteFallbackLibraries)
            throws ProcessInitException {
        synchronized (sLock) {
            if (mInitialized) {
                // Already initialized, nothing to do.
                return;
            }
            loadAlreadyLocked(context, shouldDeleteFallbackLibraries);
            initializeAlreadyLocked();
        }
    }

    /**
     * Checks if library is fully loaded and initialized.
     */
    public static boolean isInitialized() {
        return sInstance != null && sInstance.mInitialized;
    }

    /**
     * The same as loadNow(null, false), should only be called by
     * non-browser process.
     *
     * @throws ProcessInitException
     */
    public void loadNow() throws ProcessInitException {
        loadNow(null, false);
    }

    /**
     * Loads the library and blocks until the load completes. The caller is responsible
     * for subsequently calling ensureInitialized().
     * May be called on any thread, but should only be called once. Note the thread
     * this is called on will be the thread that runs the native code's static initializers.
     * See the comment in doInBackground() for more considerations on this.
     *
     * @param context The context the code is running, or null if it doesn't have one.
     * @param shouldDeleteFallbackLibraries The flag tells whether the method
     *   should delete the old fallback libraries or not.
     *
     * @throws ProcessInitException if the native library failed to load.
     */
    public void loadNow(Context context, boolean shouldDeleteFallbackLibraries)
            throws ProcessInitException {
        synchronized (sLock) {
            loadAlreadyLocked(context, shouldDeleteFallbackLibraries);
        }
    }

    /**
     * initializes the library here and now: must be called on the thread that the
     * native will call its "main" thread. The library must have previously been
     * loaded with loadNow.
     */
    public void initialize() throws ProcessInitException {
        synchronized (sLock) {
            initializeAlreadyLocked();
        }
    }

    /** Prefetches the native libraries in a background thread.
     *
     * Launches an AsyncTask that, through a short-lived forked process, reads a
     * part of each page of the native library.  This is done to warm up the
     * page cache, turning hard page faults into soft ones.
     *
     * This is done this way, as testing shows that fadvise(FADV_WILLNEED) is
     * detrimental to the startup time.
     *
     * @param context the application context.
     */
    public void asyncPrefetchLibrariesToMemory(final Context context) {
        new AsyncTask<Void, Void, Void>() {
            @Override
            protected Void doInBackground(Void... params) {
                TraceEvent.begin("LibraryLoader.asyncPrefetchLibrariesToMemory");
                boolean success = nativeForkAndPrefetchNativeLibrary();
                if (!success) {
                    Log.w(TAG, "Forking a process to prefetch the native library failed.");
                }
                RecordHistogram.recordBooleanHistogram("LibraryLoader.PrefetchStatus", success);
                TraceEvent.end("LibraryLoader.asyncPrefetchLibrariesToMemory");
                return null;
            }
        }.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR);
    }

    // Invoke System.loadLibrary(...), triggering JNI_OnLoad in native code
    private void loadAlreadyLocked(
            Context context, boolean shouldDeleteFallbackLibraries)
            throws ProcessInitException {
        try {
            if (!mLoaded) {
                assert !mInitialized;

                long startTime = SystemClock.uptimeMillis();
                boolean useChromiumLinker = Linker.isUsed();
                boolean fallbackWasUsed = false;

                if (useChromiumLinker) {
                    // Determine the APK file path.
                    String apkFilePath = null;
                    if (context != null) {
                        apkFilePath = getLibraryApkPath(context);
                    } else {
                        Log.w(TAG, "could not check load from APK support due to null context");
                    }

                    // Load libraries using the Chromium linker.
                    Linker.prepareLibraryLoad();

                    for (String library : NativeLibraries.LIBRARIES) {
                        // Don't self-load the linker. This is because the build system is
                        // not clever enough to understand that all the libraries packaged
                        // in the final .apk don't need to be explicitly loaded.
                        if (Linker.isChromiumLinkerLibrary(library)) {
                            if (DEBUG) Log.i(TAG, "ignoring self-linker load");
                            continue;
                        }

                        // Determine where the library should be loaded from.
                        String zipFilePath = null;
                        String libFilePath = System.mapLibraryName(library);
                        if (apkFilePath != null && Linker.isInZipFile()) {
                            // The library is in the APK file.
                            if (!Linker.checkLibraryIsMappableInApk(apkFilePath, libFilePath)) {
                                mLibraryIsMappableInApk = false;
                            }
                            if (mLibraryIsMappableInApk) {
                                // Load directly from the APK.
                                zipFilePath = apkFilePath;
                                Log.i(TAG, "Loading " + library + " directly from within "
                                        + apkFilePath);
                            } else {
                                // Unpack library fallback.
                                Log.i(TAG, "Loading " + library
                                        + " using unpack library fallback from within "
                                        + apkFilePath);
                                libFilePath = LibraryLoaderHelper.buildFallbackLibrary(
                                        context, library);
                                fallbackWasUsed = true;
                                Log.i(TAG, "Built fallback library " + libFilePath);
                            }
                        } else {
                            // The library is in its own file.
                            Log.i(TAG, "Loading " + library);
                        }

                        // Load the library.
                        boolean isLoaded = false;
                        if (Linker.isUsingBrowserSharedRelros()) {
                            mIsUsingBrowserSharedRelros = true;
                            try {
                                loadLibrary(zipFilePath, libFilePath);
                                isLoaded = true;
                            } catch (UnsatisfiedLinkError e) {
                                Log.w(TAG, "Failed to load native library with shared RELRO, "
                                        + "retrying without");
                                Linker.disableSharedRelros();
                                mLoadAtFixedAddressFailed = true;
                            }
                        }
                        if (!isLoaded) {
                            loadLibrary(zipFilePath, libFilePath);
                        }
                    }

                    Linker.finishLibraryLoad();
                } else {
                    // Load libraries using the system linker.
                    for (String library : NativeLibraries.LIBRARIES) {
                        System.loadLibrary(library);
                    }
                }

                if (!fallbackWasUsed && context != null
                        && shouldDeleteFallbackLibraries) {
                    LibraryLoaderHelper.deleteLibrariesAsynchronously(
                            context, LibraryLoaderHelper.LOAD_FROM_APK_FALLBACK_DIR);
                }

                long stopTime = SystemClock.uptimeMillis();
                Log.i(TAG, String.format("Time to load native libraries: %d ms (timestamps %d-%d)",
                        stopTime - startTime,
                        startTime % 10000,
                        stopTime % 10000));

                mLoaded = true;
            }
        } catch (UnsatisfiedLinkError e) {
            throw new ProcessInitException(LoaderErrors.LOADER_ERROR_NATIVE_LIBRARY_LOAD_FAILED, e);
        }
        // Check that the version of the library we have loaded matches the version we expect
        Log.i(TAG, String.format(
                "Expected native library version number \"%s\","
                        + "actual native library version number \"%s\"",
                NativeLibraries.sVersionNumber,
                nativeGetVersionNumber()));
        if (!NativeLibraries.sVersionNumber.equals(nativeGetVersionNumber())) {
            throw new ProcessInitException(LoaderErrors.LOADER_ERROR_NATIVE_LIBRARY_WRONG_VERSION);
        }
    }

    // Returns whether the given split name is that of the ABI split.
    private static boolean isAbiSplit(String splitName) {
        // The split name for the ABI split is manually set in the build rules.
        return splitName.startsWith("abi_");
    }

    // Returns the path to the .apk that holds the native libraries.
    // This is either the main .apk, or the abi split apk.
    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    private static String getLibraryApkPath(Context context) {
        ApplicationInfo appInfo = context.getApplicationInfo();
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            return appInfo.sourceDir;
        }
        PackageInfo packageInfo = PackageUtils.getOwnPackageInfo(context);
        if (packageInfo.splitNames != null) {
            for (int i = 0; i < packageInfo.splitNames.length; ++i) {
                if (isAbiSplit(packageInfo.splitNames[i])) {
                    return appInfo.splitSourceDirs[i];
                }
            }
        }
        return appInfo.sourceDir;
    }

    // Load a native shared library with the Chromium linker. If the zip file
    // path is not null, the library is loaded directly from the zip file.
    private void loadLibrary(@Nullable String zipFilePath, String libFilePath) {
        Linker.loadLibrary(zipFilePath, libFilePath);
        if (zipFilePath != null) {
            mLibraryWasLoadedFromApk = true;
        }
    }

    // The WebView requires the Command Line to be switched over before
    // initialization is done. This is okay in the WebView's case since the
    // JNI is already loaded by this point.
    public void switchCommandLineForWebView() {
        synchronized (sLock) {
            ensureCommandLineSwitchedAlreadyLocked();
        }
    }

    // Switch the CommandLine over from Java to native if it hasn't already been done.
    // This must happen after the code is loaded and after JNI is ready (since after the
    // switch the Java CommandLine will delegate all calls the native CommandLine).
    private void ensureCommandLineSwitchedAlreadyLocked() {
        assert mLoaded;
        if (mCommandLineSwitched) {
            return;
        }
        nativeInitCommandLine(CommandLine.getJavaSwitchesOrNull());
        CommandLine.enableNativeProxy();
        mCommandLineSwitched = true;
    }

    // Invoke base::android::LibraryLoaded in library_loader_hooks.cc
    private void initializeAlreadyLocked() throws ProcessInitException {
        if (mInitialized) {
            return;
        }

        // Setup the native command line if necessary.
        if (!mCommandLineSwitched) {
            nativeInitCommandLine(CommandLine.getJavaSwitchesOrNull());
        }

        if (!nativeLibraryLoaded()) {
            Log.e(TAG, "error calling nativeLibraryLoaded");
            throw new ProcessInitException(LoaderErrors.LOADER_ERROR_FAILED_TO_REGISTER_JNI);
        }

        // The Chrome JNI is registered by now so we can switch the Java
        // command line over to delegating to native if it's necessary.
        if (!mCommandLineSwitched) {
            CommandLine.enableNativeProxy();
            mCommandLineSwitched = true;
        }

        // From now on, keep tracing in sync with native.
        TraceEvent.registerNativeEnabledObserver();

        // From this point on, native code is ready to use and checkIsReady()
        // shouldn't complain from now on (and in fact, it's used by the
        // following calls).
        // Note that this flag can be accessed asynchronously, so any initialization
        // must be performed before.
        mInitialized = true;
    }

    // Called after all native initializations are complete.
    public void onNativeInitializationComplete(Context context) {
        recordBrowserProcessHistogram(context);
    }

    // Record Chromium linker histogram state for the main browser process. Called from
    // onNativeInitializationComplete().
    private void recordBrowserProcessHistogram(Context context) {
        if (Linker.isUsed()) {
            nativeRecordChromiumAndroidLinkerBrowserHistogram(mIsUsingBrowserSharedRelros,
                                                              mLoadAtFixedAddressFailed,
                                                              getLibraryLoadFromApkStatus(context));
        }
    }

    // Returns the device's status for loading a library directly from the APK file.
    // This method can only be called when the Chromium linker is used.
    private int getLibraryLoadFromApkStatus(Context context) {
        assert Linker.isUsed();

        if (mLibraryWasLoadedFromApk) {
            return LibraryLoadFromApkStatusCodes.SUCCESSFUL;
        }

        if (!mLibraryIsMappableInApk) {
            return LibraryLoadFromApkStatusCodes.USED_UNPACK_LIBRARY_FALLBACK;
        }

        // There were no libraries to be loaded directly from the APK file.
        return LibraryLoadFromApkStatusCodes.UNKNOWN;
    }

    // Register pending Chromium linker histogram state for renderer processes. This cannot be
    // recorded as a histogram immediately because histograms and IPC are not ready at the
    // time it are captured. This function stores a pending value, so that a later call to
    // RecordChromiumAndroidLinkerRendererHistogram() will record it correctly.
    public void registerRendererProcessHistogram(boolean requestedSharedRelro,
                                                 boolean loadAtFixedAddressFailed) {
        if (Linker.isUsed()) {
            nativeRegisterChromiumAndroidLinkerRendererHistogram(requestedSharedRelro,
                                                                 loadAtFixedAddressFailed);
        }
    }

    /**
     * @return the process the shared library is loaded in, see the LibraryProcessType
     *         for possible values.
     */
    @CalledByNative
    public static int getLibraryProcessType() {
        if (sInstance == null) return LibraryProcessType.PROCESS_UNINITIALIZED;
        return sInstance.mLibraryProcessType;
    }

    private native void nativeInitCommandLine(String[] initCommandLine);

    // Only methods needed before or during normal JNI registration are during System.OnLoad.
    // nativeLibraryLoaded is then called to register everything else.  This process is called
    // "initialization".  This method will be mapped (by generated code) to the LibraryLoaded
    // definition in base/android/library_loader/library_loader_hooks.cc.
    //
    // Return true on success and false on failure.
    private native boolean nativeLibraryLoaded();

    // Method called to record statistics about the Chromium linker operation for the main
    // browser process. Indicates whether the linker attempted relro sharing for the browser,
    // and if it did, whether the library failed to load at a fixed address. Also records
    // support for loading a library directly from the APK file.
    private native void nativeRecordChromiumAndroidLinkerBrowserHistogram(
            boolean isUsingBrowserSharedRelros,
            boolean loadAtFixedAddressFailed,
            int libraryLoadFromApkStatus);

    // Method called to register (for later recording) statistics about the Chromium linker
    // operation for a renderer process. Indicates whether the linker attempted relro sharing,
    // and if it did, whether the library failed to load at a fixed address.
    private native void nativeRegisterChromiumAndroidLinkerRendererHistogram(
            boolean requestedSharedRelro,
            boolean loadAtFixedAddressFailed);

    // Get the version of the native library. This is needed so that we can check we
    // have the right version before initializing the (rest of the) JNI.
    private native String nativeGetVersionNumber();

    // Finds the ranges corresponding to the native library pages, forks a new
    // process to prefetch these pages and waits for it. The new process then
    // terminates. This is blocking.
    private static native boolean nativeForkAndPrefetchNativeLibrary();
}
