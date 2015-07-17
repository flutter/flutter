// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base.library_loader;

import android.os.Bundle;
import android.os.Parcel;

import org.chromium.base.CalledByNative;
import org.chromium.base.Log;
import org.chromium.base.SysUtils;
import org.chromium.base.ThreadUtils;

import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

import javax.annotation.Nullable;

/*
 * For more, see Technical note, Security considerations, and the explanation
 * of how this class is supposed to be used in Linker.java.
 */

/**
 * Provides a concrete implementation of the Chromium Linker.
 *
 * This Linker implementation uses the crazy linker to map and then run Chrome
 * for Android.
 *
 * For more on the operations performed by the Linker, see {@link Linker}.
 */
class LegacyLinker extends Linker {
    // Log tag for this class.
    private static final String TAG = "cr.library_loader";

    // Name of the library that contains our JNI code.
    private static final String LINKER_JNI_LIBRARY = "chromium_android_linker";

    // Becomes true after linker initialization.
    private boolean mInitialized = false;

    // Set to true to indicate that the system supports safe sharing of RELRO sections.
    private boolean mRelroSharingSupported = false;

    // Set to true if this runs in the browser process. Disabled by initServiceProcess().
    // TODO(petrcermak): This flag can be incorrectly set to false (even though this might run in
    // the browser process) on low-memory devices.
    private boolean mInBrowserProcess = true;

    // Becomes true to indicate this process needs to wait for a shared RELRO in
    // finishLibraryLoad().
    private boolean mWaitForSharedRelros = false;

    // Becomes true when initialization determines that the browser process can use the
    // shared RELRO.
    private boolean mBrowserUsesSharedRelro = false;

    // The map of all RELRO sections either created or used in this process.
    private Bundle mSharedRelros = null;

    // Current common random base load address.
    private long mBaseLoadAddress = 0;

    // Current fixed-location load address for the next library called by loadLibrary().
    private long mCurrentLoadAddress = 0;

    // Becomes true once prepareLibraryLoad() has been called.
    private boolean mPrepareLibraryLoadCalled = false;

    // The map of libraries that are currently loaded in this process.
    protected HashMap<String, LibInfo> mLoadedLibraries = null;

    // Used internally to initialize the linker's static data. Assume lock is held.
    private void ensureInitializedLocked() {
        assert Thread.holdsLock(mLock);

        if (mInitialized) {
            return;
        }

        mRelroSharingSupported = false;
        if (NativeLibraries.sUseLinker) {
            if (DEBUG) {
                Log.i(TAG, "Loading lib" + LINKER_JNI_LIBRARY + ".so");
            }
            try {
                System.loadLibrary(LINKER_JNI_LIBRARY);
            } catch (UnsatisfiedLinkError  e) {
                // In a component build, the ".cr" suffix is added to each library name.
                Log.w(TAG, "Couldn't load lib" + LINKER_JNI_LIBRARY + ".so, "
                        + "trying lib" + LINKER_JNI_LIBRARY + ".cr.so");
                System.loadLibrary(LINKER_JNI_LIBRARY + ".cr");
            }
            mRelroSharingSupported = nativeCanUseSharedRelro();
            if (!mRelroSharingSupported) {
                Log.w(TAG, "This system cannot safely share RELRO sections");
            } else {
                if (DEBUG) {
                    Log.i(TAG, "This system supports safe shared RELRO sections");
                }
            }

            if (mMemoryDeviceConfig == MEMORY_DEVICE_CONFIG_INIT) {
                if (SysUtils.isLowEndDevice()) {
                    mMemoryDeviceConfig = MEMORY_DEVICE_CONFIG_LOW;
                } else {
                    mMemoryDeviceConfig = MEMORY_DEVICE_CONFIG_NORMAL;
                }
            }

            switch (BROWSER_SHARED_RELRO_CONFIG) {
                case BROWSER_SHARED_RELRO_CONFIG_NEVER:
                    mBrowserUsesSharedRelro = false;
                    break;
                case BROWSER_SHARED_RELRO_CONFIG_LOW_RAM_ONLY:
                    if (mMemoryDeviceConfig == MEMORY_DEVICE_CONFIG_LOW) {
                        mBrowserUsesSharedRelro = true;
                        Log.w(TAG, "Low-memory device: shared RELROs used in all processes");
                    } else {
                        mBrowserUsesSharedRelro = false;
                    }
                    break;
                case BROWSER_SHARED_RELRO_CONFIG_ALWAYS:
                    Log.w(TAG, "Beware: shared RELROs used in all processes!");
                    mBrowserUsesSharedRelro = true;
                    break;
                default:
                    assert false : "Unreached";
                    break;
            }
        } else {
            if (DEBUG) {
                Log.i(TAG, "Linker disabled");
            }
        }

        if (!mRelroSharingSupported) {
            // Sanity.
            mBrowserUsesSharedRelro = false;
            mWaitForSharedRelros = false;
        }

        mInitialized = true;
    }

    /**
     * Call this method to determine if this chromium project must
     * use this linker. If not, System.loadLibrary() should be used to load
     * libraries instead.
     */
    @Override
    public boolean isUsed() {
        // Only GYP targets that are APKs and have the 'use_chromium_linker' variable
        // defined as 1 will use this linker. For all others (the default), the
        // auto-generated NativeLibraries.sUseLinker variable will be false.
        if (!NativeLibraries.sUseLinker) return false;

        synchronized (mLock) {
            ensureInitializedLocked();
            // At the moment, there is also no point in using this linker if the
            // system does not support RELRO sharing safely.
            return mRelroSharingSupported;
        }
    }

    /**
     * Call this method to determine if the linker will try to use shared RELROs
     * for the browser process.
     */
    @Override
    public boolean isUsingBrowserSharedRelros() {
        synchronized (mLock) {
            ensureInitializedLocked();
            return mBrowserUsesSharedRelro;
        }
    }

    /**
     * Call this method to determine if the chromium project must load
     * the library directly from the zip file.
     */
    @Override
    public boolean isInZipFile() {
        return NativeLibraries.sUseLibraryInZipFile;
    }

    /**
     * Call this method just before loading any native shared libraries in this process.
     */
    @Override
    public void prepareLibraryLoad() {
        if (DEBUG) {
            Log.i(TAG, "prepareLibraryLoad() called");
        }
        synchronized (mLock) {
            mPrepareLibraryLoadCalled = true;

            if (mInBrowserProcess) {
                // Force generation of random base load address, as well
                // as creation of shared RELRO sections in this process.
                setupBaseLoadAddressLocked();
            }
        }
    }

    /**
     * Call this method just after loading all native shared libraries in this process.
     * Note that when in a service process, this will block until the RELRO bundle is
     * received, i.e. when another thread calls useSharedRelros().
     */
    @Override
    public void finishLibraryLoad() {
        if (DEBUG) {
            Log.i(TAG, "finishLibraryLoad() called");
        }
        synchronized (mLock) {
            if (DEBUG) {
                Log.i(TAG, String.format(
                        Locale.US,
                        "mInBrowserProcess=%s mBrowserUsesSharedRelro=%s mWaitForSharedRelros=%s",
                        mInBrowserProcess ? "true" : "false",
                        mBrowserUsesSharedRelro ? "true" : "false",
                        mWaitForSharedRelros ? "true" : "false"));
            }

            if (mLoadedLibraries == null) {
                if (DEBUG) {
                    Log.i(TAG, "No libraries loaded");
                }
            } else {
                if (mInBrowserProcess) {
                    // Create new Bundle containing RELRO section information
                    // for all loaded libraries. Make it available to getSharedRelros().
                    mSharedRelros = createBundleFromLibInfoMap(mLoadedLibraries);
                    if (DEBUG) {
                        Log.i(TAG, "Shared RELRO created");
                        dumpBundle(mSharedRelros);
                    }

                    if (mBrowserUsesSharedRelro) {
                        useSharedRelrosLocked(mSharedRelros);
                    }
                }

                if (mWaitForSharedRelros) {
                    assert !mInBrowserProcess;

                    // Wait until the shared relro bundle is received from useSharedRelros().
                    while (mSharedRelros == null) {
                        try {
                            mLock.wait();
                        } catch (InterruptedException ie) {
                            // no-op
                        }
                    }
                    useSharedRelrosLocked(mSharedRelros);
                    // Clear the Bundle to ensure its file descriptor references can't be reused.
                    mSharedRelros.clear();
                    mSharedRelros = null;
                }
            }

            if (NativeLibraries.sEnableLinkerTests && mTestRunnerClassName != null) {
                // The TestRunner implementation must be instantiated _after_
                // all libraries are loaded to ensure that its native methods
                // are properly registered.
                if (DEBUG) {
                    Log.i(TAG, "Instantiating " + mTestRunnerClassName);
                }
                TestRunner testRunner = null;
                try {
                    testRunner = (TestRunner)
                            Class.forName(mTestRunnerClassName).newInstance();
                } catch (Exception e) {
                    Log.e(TAG, "Could not extract test runner class name", e);
                    testRunner = null;
                }
                if (testRunner != null) {
                    if (!testRunner.runChecks(mMemoryDeviceConfig, mInBrowserProcess)) {
                        Log.wtf(TAG, "Linker runtime tests failed in this process!!");
                        assert false;
                    } else {
                        Log.i(TAG, "All linker tests passed!");
                    }
                }
            }
        }
        if (DEBUG) {
            Log.i(TAG, "finishLibraryLoad() exiting");
        }
    }

    /**
     * Call this to send a Bundle containing the shared RELRO sections to be
     * used in this process. If initServiceProcess() was previously called,
     * finishLibraryLoad() will not exit until this method is called in another
     * thread with a non-null value.
     * @param bundle The Bundle instance containing a map of shared RELRO sections
     * to use in this process.
     */
    @Override
    public void useSharedRelros(Bundle bundle) {
        // Ensure the bundle uses the application's class loader, not the framework
        // one which doesn't know anything about LibInfo.
        // Also, hold a fresh copy of it so the caller can't recycle it.
        Bundle clonedBundle = null;
        if (bundle != null) {
            bundle.setClassLoader(LibInfo.class.getClassLoader());
            clonedBundle = new Bundle(LibInfo.class.getClassLoader());
            Parcel parcel = Parcel.obtain();
            bundle.writeToParcel(parcel, 0);
            parcel.setDataPosition(0);
            clonedBundle.readFromParcel(parcel);
            parcel.recycle();
        }
        if (DEBUG) {
            Log.i(TAG, "useSharedRelros() called with " + bundle
                    + ", cloned " + clonedBundle);
        }
        synchronized (mLock) {
            // Note that in certain cases, this can be called before
            // initServiceProcess() in service processes.
            mSharedRelros = clonedBundle;
            // Tell any listener blocked in finishLibraryLoad() about it.
            mLock.notifyAll();
        }
    }

    /**
     * Call this to retrieve the shared RELRO sections created in this process,
     * after loading all libraries.
     * @return a new Bundle instance, or null if RELRO sharing is disabled on
     * this system, or if initServiceProcess() was called previously.
     */
    @Override
    public Bundle getSharedRelros() {
        if (DEBUG) {
            Log.i(TAG, "getSharedRelros() called");
        }
        synchronized (mLock) {
            if (!mInBrowserProcess) {
                if (DEBUG) {
                    Log.i(TAG, "... returning null Bundle");
                }
                return null;
            }

            // Return the Bundle created in finishLibraryLoad().
            if (DEBUG) {
                Log.i(TAG, "... returning " + mSharedRelros);
            }
            return mSharedRelros;
        }
    }

    /**
     * Call this method before loading any libraries to indicate that this
     * process shall neither create or reuse shared RELRO sections.
     */
    @Override
    public void disableSharedRelros() {
        if (DEBUG) {
            Log.i(TAG, "disableSharedRelros() called");
        }
        synchronized (mLock) {
            mInBrowserProcess = false;
            mWaitForSharedRelros = false;
            mBrowserUsesSharedRelro = false;
        }
    }

    /**
     * Call this method before loading any libraries to indicate that this
     * process is ready to reuse shared RELRO sections from another one.
     * Typically used when starting service processes.
     * @param baseLoadAddress the base library load address to use.
     */
    @Override
    public void initServiceProcess(long baseLoadAddress) {
        if (DEBUG) {
            Log.i(TAG, String.format(
                    Locale.US, "initServiceProcess(0x%x) called",
                    baseLoadAddress));
        }
        synchronized (mLock) {
            ensureInitializedLocked();
            mInBrowserProcess = false;
            mBrowserUsesSharedRelro = false;
            if (mRelroSharingSupported) {
                mWaitForSharedRelros = true;
                mBaseLoadAddress = baseLoadAddress;
                mCurrentLoadAddress = baseLoadAddress;
            }
        }
    }

    /**
     * Retrieve the base load address of all shared RELRO sections.
     * This also enforces the creation of shared RELRO sections in
     * prepareLibraryLoad(), which can later be retrieved with getSharedRelros().
     * @return a common, random base load address, or 0 if RELRO sharing is
     * disabled.
     */
    @Override
    public long getBaseLoadAddress() {
        synchronized (mLock) {
            ensureInitializedLocked();
            if (!mInBrowserProcess) {
                Log.w(TAG, "Shared RELRO sections are disabled in this process!");
                return 0;
            }

            setupBaseLoadAddressLocked();
            if (DEBUG) {
                Log.i(TAG, String.format(
                        Locale.US, "getBaseLoadAddress() returns 0x%x",
                        mBaseLoadAddress));
            }
            return mBaseLoadAddress;
        }
    }

    // Used internally to lazily setup the common random base load address.
    private void setupBaseLoadAddressLocked() {
        assert Thread.holdsLock(mLock);
        if (mBaseLoadAddress == 0) {
            long address = computeRandomBaseLoadAddress();
            mBaseLoadAddress = address;
            mCurrentLoadAddress = address;
            if (address == 0) {
                // If the computed address is 0, there are issues with finding enough
                // free address space, so disable RELRO shared / fixed load addresses.
                Log.w(TAG, "Disabling shared RELROs due address space pressure");
                mBrowserUsesSharedRelro = false;
                mWaitForSharedRelros = false;
            }
        }
    }


    /**
     * Compute a random base load address at which to place loaded libraries.
     * @return new base load address, or 0 if the system does not support
     * RELRO sharing.
     */
    private long computeRandomBaseLoadAddress() {
        // nativeGetRandomBaseLoadAddress() returns an address at which it has previously
        // successfully mapped an area of the given size, on the basis that we will be
        // able, with high probability, to map our library into it.
        //
        // One issue with this is that we do not yet know the size of the library that
        // we will load is. So here we pass a value that we expect will always be larger
        // than that needed. If it is smaller the library mapping may still succeed. The
        // other issue is that although highly unlikely, there is no guarantee that
        // something else does not map into the area we are going to use between here and
        // when we try to map into it.
        //
        // The above notes mean that all of this is probablistic. It is however okay to do
        // because if, worst case and unlikely, we get unlucky in our choice of address,
        // the back-out and retry without the shared RELRO in the ChildProcessService will
        // keep things running.
        final long maxExpectedBytes = 192 * 1024 * 1024;
        final long address = nativeGetRandomBaseLoadAddress(maxExpectedBytes);
        if (DEBUG) {
            Log.i(TAG, String.format(
                    Locale.US, "Random native base load address: 0x%x",
                    address));
        }
        return address;
    }

    // Used for debugging only.
    private void dumpBundle(Bundle bundle) {
        if (DEBUG) {
            Log.i(TAG, "Bundle has " + bundle.size() + " items: " + bundle);
        }
    }

    /**
     * Use the shared RELRO section from a Bundle received form another process.
     * Call this after calling setBaseLoadAddress() then loading all libraries
     * with loadLibrary().
     * @param bundle Bundle instance generated with createSharedRelroBundle() in
     * another process.
     */
    private void useSharedRelrosLocked(Bundle bundle) {
        assert Thread.holdsLock(mLock);

        if (DEBUG) {
            Log.i(TAG, "Linker.useSharedRelrosLocked() called");
        }

        if (bundle == null) {
            if (DEBUG) {
                Log.i(TAG, "null bundle!");
            }
            return;
        }

        if (!mRelroSharingSupported) {
            if (DEBUG) {
                Log.i(TAG, "System does not support RELRO sharing");
            }
            return;
        }

        if (mLoadedLibraries == null) {
            if (DEBUG) {
                Log.i(TAG, "No libraries loaded!");
            }
            return;
        }

        if (DEBUG) {
            dumpBundle(bundle);
        }
        HashMap<String, LibInfo> relroMap = createLibInfoMapFromBundle(bundle);

        // Apply the RELRO section to all libraries that were already loaded.
        for (Map.Entry<String, LibInfo> entry : relroMap.entrySet()) {
            String libName = entry.getKey();
            LibInfo libInfo = entry.getValue();
            if (!nativeUseSharedRelro(libName, libInfo)) {
                Log.w(TAG, "Could not use shared RELRO section for " + libName);
            } else {
                if (DEBUG) {
                    Log.i(TAG, "Using shared RELRO section for " + libName);
                }
            }
        }

        // In service processes, close all file descriptors from the map now.
        if (!mInBrowserProcess) closeLibInfoMap(relroMap);

        if (DEBUG) {
            Log.i(TAG, "Linker.useSharedRelrosLocked() exiting");
        }
    }

    /**
     * Load a native shared library with the Chromium linker. If the zip file
     * is not null, the shared library must be uncompressed and page aligned
     * inside the zipfile. Note the crazy linker treats libraries and files as
     * equivalent, so you can only open one library in a given zip file. The
     * library must not be the Chromium linker library.
     *
     * @param zipFilePath The path of the zip file containing the library (or null).
     * @param libFilePath The path of the library (possibly in the zip file).
     */
    @Override
    public void loadLibrary(@Nullable String zipFilePath, String libFilePath) {
        if (DEBUG) {
            Log.i(TAG, "loadLibrary: " + zipFilePath + ", " + libFilePath);
        }

        synchronized (mLock) {
            ensureInitializedLocked();

            // Security: Ensure prepareLibraryLoad() was called before.
            // In theory, this can be done lazily here, but it's more consistent
            // to use a pair of functions (i.e. prepareLibraryLoad() + finishLibraryLoad())
            // that wrap all calls to loadLibrary() in the library loader.
            assert mPrepareLibraryLoadCalled;

            if (mLoadedLibraries == null) {
                mLoadedLibraries = new HashMap<String, LibInfo>();
            }

            if (mLoadedLibraries.containsKey(libFilePath)) {
                if (DEBUG) {
                    Log.i(TAG, "Not loading " + libFilePath + " twice");
                }
                return;
            }

            LibInfo libInfo = new LibInfo();
            long loadAddress = 0;
            if ((mInBrowserProcess && mBrowserUsesSharedRelro) || mWaitForSharedRelros) {
                // Load the library at a fixed address.
                loadAddress = mCurrentLoadAddress;
            }

            String sharedRelRoName = libFilePath;
            if (zipFilePath != null) {
                if (!nativeLoadLibraryInZipFile(zipFilePath, libFilePath, loadAddress, libInfo)) {
                    String errorMessage = "Unable to load library: " + libFilePath
                                          + ", in: " + zipFilePath;
                    Log.e(TAG, errorMessage);
                    throw new UnsatisfiedLinkError(errorMessage);
                }
                sharedRelRoName = zipFilePath;
            } else {
                if (!nativeLoadLibrary(libFilePath, loadAddress, libInfo)) {
                    String errorMessage = "Unable to load library: " + libFilePath;
                    Log.e(TAG, errorMessage);
                    throw new UnsatisfiedLinkError(errorMessage);
                }
            }

            // Print the load address to the logcat when testing the linker. The format
            // of the string is expected by the Python test_runner script as one of:
            //    BROWSER_LIBRARY_ADDRESS: <library-name> <address>
            //    RENDERER_LIBRARY_ADDRESS: <library-name> <address>
            // Where <library-name> is the library name, and <address> is the hexadecimal load
            // address.
            if (NativeLibraries.sEnableLinkerTests) {
                Log.i(TAG, String.format(
                        Locale.US, "%s_LIBRARY_ADDRESS: %s %x",
                        mInBrowserProcess ? "BROWSER" : "RENDERER",
                        libFilePath,
                        libInfo.mLoadAddress));
            }

            if (mInBrowserProcess) {
                // Create a new shared RELRO section at the 'current' fixed load address.
                if (!nativeCreateSharedRelro(sharedRelRoName, mCurrentLoadAddress, libInfo)) {
                    Log.w(TAG, String.format(
                            Locale.US, "Could not create shared RELRO for %s at %x",
                            libFilePath,
                            mCurrentLoadAddress));
                } else {
                    if (DEBUG) {
                        Log.i(TAG, String.format(
                                Locale.US,
                                "Created shared RELRO for %s at %x: %s",
                                sharedRelRoName,
                                mCurrentLoadAddress,
                                libInfo.toString()));
                    }
                }
            }

            if (mCurrentLoadAddress != 0) {
                // Compute the next current load address. If mBaseLoadAddress
                // is not 0, this is an explicit library load address. Otherwise,
                // this is an explicit load address for relocated RELRO sections
                // only.
                mCurrentLoadAddress = libInfo.mLoadAddress + libInfo.mLoadSize;
            }

            mLoadedLibraries.put(sharedRelRoName, libInfo);
            if (DEBUG) {
                Log.i(TAG, "Library details " + libInfo.toString());
            }
        }
    }

    /**
     * Determine whether a library is the linker library. Also deal with the
     * component build that adds a .cr suffix to the name.
     */
    @Override
    public boolean isChromiumLinkerLibrary(String library) {
        return library.equals(LINKER_JNI_LIBRARY)
               || library.equals(LINKER_JNI_LIBRARY + ".cr");
    }

    /**
     * Move activity from the native thread to the main UI thread.
     * Called from native code on its own thread.  Posts a callback from
     * the UI thread back to native code.
     *
     * @param opaque Opaque argument.
     */
    @CalledByNative
    public static void postCallbackOnMainThread(final long opaque) {
        ThreadUtils.postOnUiThread(new Runnable() {
            @Override
            public void run() {
                nativeRunCallbackOnUiThread(opaque);
            }
        });
    }

    /**
     * Native method to run callbacks on the main UI thread.
     * Supplied by the crazy linker and called by postCallbackOnMainThread.
     * @param opaque Opaque crazy linker arguments.
     */
    private static native void nativeRunCallbackOnUiThread(long opaque);

    /**
     * Native method used to load a library.
     * @param library Platform specific library name (e.g. libfoo.so)
     * @param loadAddress Explicit load address, or 0 for randomized one.
     * @param libInfo If not null, the mLoadAddress and mLoadSize fields
     * of this LibInfo instance will set on success.
     * @return true for success, false otherwise.
     */
    private static native boolean nativeLoadLibrary(String library,
                                                    long loadAddress,
                                                    LibInfo libInfo);

    /**
     * Native method used to load a library which is inside a zipfile.
     * @param zipfileName Filename of the zip file containing the library.
     * @param library Platform specific library name (e.g. libfoo.so)
     * @param loadAddress Explicit load address, or 0 for randomized one.
     * @param libInfo If not null, the mLoadAddress and mLoadSize fields
     * of this LibInfo instance will set on success.
     * @return true for success, false otherwise.
     */
    private static native boolean nativeLoadLibraryInZipFile(String zipfileName,
                                                             String libraryName,
                                                             long loadAddress,
                                                             LibInfo libInfo);

    /**
     * Native method used to create a shared RELRO section.
     * If the library was already loaded at the same address using
     * nativeLoadLibrary(), this creates the RELRO for it. Otherwise,
     * this loads a new temporary library at the specified address,
     * creates and extracts the RELRO section from it, then unloads it.
     * @param library Library name.
     * @param loadAddress load address, which can be different from the one
     * used to load the library in the current process!
     * @param libInfo libInfo instance. On success, the mRelroStart, mRelroSize
     * and mRelroFd will be set.
     * @return true on success, false otherwise.
     */
    private static native boolean nativeCreateSharedRelro(String library,
                                                          long loadAddress,
                                                          LibInfo libInfo);

    /**
     * Native method used to use a shared RELRO section.
     * @param library Library name.
     * @param libInfo A LibInfo instance containing valid RELRO information
     * @return true on success.
     */
    private static native boolean nativeUseSharedRelro(String library,
                                                       LibInfo libInfo);

    /**
     * Checks that the system supports shared RELROs. Old Android kernels
     * have a bug in the way they check Ashmem region protection flags, which
     * makes using shared RELROs unsafe. This method performs a simple runtime
     * check for this misfeature, even though nativeEnableSharedRelro() will
     * always fail if this returns false.
     */
    private static native boolean nativeCanUseSharedRelro();

    /**
     * Return a random address that should be free to be mapped with the given size.
     * Maps an area of size bytes, and if successful then unmaps it and returns
     * the address of the area allocated by the system (with ASLR). The idea is
     * that this area should remain free of other mappings until we map our library
     * into it.
     * @param sizeBytes Size of area in bytes to search for.
     * @return address to pass to future mmap, or 0 on error.
     */
    private static native long nativeGetRandomBaseLoadAddress(long sizeBytes);
}
