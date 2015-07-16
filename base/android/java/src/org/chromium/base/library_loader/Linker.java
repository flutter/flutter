// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base.library_loader;

import android.os.Bundle;
import android.os.Parcel;
import android.os.ParcelFileDescriptor;
import android.os.Parcelable;
import android.util.Log;

import org.chromium.base.CalledByNative;
import org.chromium.base.SysUtils;
import org.chromium.base.ThreadUtils;
import org.chromium.base.annotations.AccessedByNative;

import java.io.FileNotFoundException;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

import javax.annotation.Nullable;

/*
 * Technical note:
 *
 * The point of this class is to provide an alternative to System.loadLibrary()
 * to load native shared libraries. One specific feature that it supports is the
 * ability to save RAM by sharing the ELF RELRO sections between renderer
 * processes.
 *
 * When two processes load the same native library at the _same_ memory address,
 * the content of their RELRO section (which includes C++ vtables or any
 * constants that contain pointers) will be largely identical [1].
 *
 * By default, the RELRO section is backed by private RAM in each process,
 * which is still significant on mobile (e.g. 1.28 MB / process on Chrome 30 for
 * Android).
 *
 * However, it is possible to save RAM by creating a shared memory region,
 * copy the RELRO content into it, then have each process swap its private,
 * regular RELRO, with a shared, read-only, mapping of the shared one.
 *
 * This trick saves 98% of the RELRO section size per extra process, after the
 * first one. On the other hand, this requires careful communication between
 * the process where the shared RELRO is created and the one(s) where it is used.
 *
 * Note that swapping the regular RELRO with the shared one is not an atomic
 * operation. Care must be taken that no other thread tries to run native code
 * that accesses it during it. In practice, this means the swap must happen
 * before library native code is executed.
 *
 * [1] The exceptions are pointers to external, randomized, symbols, like
 * those from some system libraries, but these are very few in practice.
 */

/*
 * Security considerations:
 *
 * - Whether the browser process loads its native libraries at the same
 *   addresses as the service ones (to save RAM by sharing the RELRO too)
 *   depends on the configuration variable BROWSER_SHARED_RELRO_CONFIG below.
 *
 *   Not using fixed library addresses in the browser process is preferred
 *   for regular devices since it maintains the efficacy of ASLR as an
 *   exploit mitigation across the render <-> browser privilege boundary.
 *
 * - The shared RELRO memory region is always forced read-only after creation,
 *   which means it is impossible for a compromised service process to map
 *   it read-write (e.g. by calling mmap() or mprotect()) and modify its
 *   content, altering values seen in other service processes.
 *
 * - Unfortunately, certain Android systems use an old, buggy kernel, that
 *   doesn't check Ashmem region permissions correctly. See CVE-2011-1149
 *   for details. This linker probes the system on startup and will completely
 *   disable shared RELROs if it detects the problem. For the record, this is
 *   common for Android emulator system images (which are still based on 2.6.29)
 *
 * - Once the RELRO ashmem region is mapped into a service process' address
 *   space, the corresponding file descriptor is immediately closed. The
 *   file descriptor is kept opened in the browser process, because a copy needs
 *   to be sent to each new potential service process.
 *
 * - The common library load addresses are randomized for each instance of
 *   the program on the device. See computeRandomBaseLoadAddress() for more
 *   details on how this is computed.
 *
 * - When loading several libraries in service processes, a simple incremental
 *   approach from the original random base load address is used. This is
 *   sufficient to deal correctly with component builds (which can use dozens
 *   of shared libraries), while regular builds always embed a single shared
 *   library per APK.
 */

/**
 * Here's an explanation of how this class is supposed to be used:
 *
 *  - Native shared libraries should be loaded with Linker.loadLibrary(),
 *    instead of System.loadLibrary(). The two functions take the same parameter
 *    and should behave the same (at a high level).
 *
 *  - Before loading any library, prepareLibraryLoad() should be called.
 *
 *  - After loading all libraries, finishLibraryLoad() should be called, before
 *    running any native code from any of the libraries (except their static
 *    constructors, which can't be avoided).
 *
 *  - A service process shall call either initServiceProcess() or
 *    disableSharedRelros() early (i.e. before any loadLibrary() call).
 *    Otherwise, the linker considers that it is running inside the browser
 *    process. This is because various Chromium projects have vastly
 *    different initialization paths.
 *
 *    disableSharedRelros() completely disables shared RELROs, and loadLibrary()
 *    will behave exactly like System.loadLibrary().
 *
 *    initServiceProcess(baseLoadAddress) indicates that shared RELROs are to be
 *    used in this process.
 *
 *  - The browser is in charge of deciding where in memory each library should
 *    be loaded. This address must be passed to each service process (see
 *    ChromiumLinkerParams.java in content for a helper class to do so).
 *
 *  - The browser will also generate shared RELROs for each library it loads.
 *    More specifically, by default when in the browser process, the linker
 *    will:
 *
 *       - Load libraries randomly (just like System.loadLibrary()).
 *       - Compute the fixed address to be used to load the same library
 *         in service processes.
 *       - Create a shared memory region populated with the RELRO region
 *         content pre-relocated for the specific fixed address above.
 *
 *    Note that these shared RELRO regions cannot be used inside the browser
 *    process. They are also never mapped into it.
 *
 *    This behaviour is altered by the BROWSER_SHARED_RELRO_CONFIG configuration
 *    variable below, which may force the browser to load the libraries at
 *    fixed addresses too.
 *
 *  - Once all libraries are loaded in the browser process, one can call
 *    getSharedRelros() which returns a Bundle instance containing a map that
 *    links each loaded library to its shared RELRO region.
 *
 *    This Bundle must be passed to each service process, for example through
 *    a Binder call (note that the Bundle includes file descriptors and cannot
 *    be added as an Intent extra).
 *
 *  - In a service process, finishLibraryLoad() will block until the RELRO
 *    section Bundle is received. This is typically done by calling
 *    useSharedRelros() from another thread.
 *
 *    This method also ensures the process uses the shared RELROs.
 */
public class Linker {

    // Log tag for this class. This must match the name of the linker's native library.
    private static final String TAG = "chromium_android_linker";

    // Set to true to enable debug logs.
    private static final boolean DEBUG = false;

    // Constants used to control the behaviour of the browser process with
    // regards to the shared RELRO section.
    //   NEVER        -> The browser never uses it itself.
    //   LOW_RAM_ONLY -> It is only used on devices with low RAM.
    //   ALWAYS       -> It is always used.
    // NOTE: These names are known and expected by the Linker test scripts.
    public static final int BROWSER_SHARED_RELRO_CONFIG_NEVER = 0;
    public static final int BROWSER_SHARED_RELRO_CONFIG_LOW_RAM_ONLY = 1;
    public static final int BROWSER_SHARED_RELRO_CONFIG_ALWAYS = 2;

    // Configuration variable used to control how the browser process uses the
    // shared RELRO. Only change this while debugging linker-related issues.
    // NOTE: This variable's name is known and expected by the Linker test scripts.
    public static final int BROWSER_SHARED_RELRO_CONFIG =
            BROWSER_SHARED_RELRO_CONFIG_LOW_RAM_ONLY;

    // Constants used to control the value of sMemoryDeviceConfig.
    //   INIT         -> Value is undetermined (will check at runtime).
    //   LOW          -> This is a low-memory device.
    //   NORMAL       -> This is not a low-memory device.
    public static final int MEMORY_DEVICE_CONFIG_INIT = 0;
    public static final int MEMORY_DEVICE_CONFIG_LOW = 1;
    public static final int MEMORY_DEVICE_CONFIG_NORMAL = 2;

    // Indicates if this is a low-memory device or not. The default is to
    // determine this by probing the system at runtime, but this can be forced
    // for testing by calling setMemoryDeviceConfig().
    private static int sMemoryDeviceConfig = MEMORY_DEVICE_CONFIG_INIT;

    // Becomes true after linker initialization.
    private static boolean sInitialized = false;

    // Set to true to indicate that the system supports safe sharing of RELRO sections.
    private static boolean sRelroSharingSupported = false;

    // Set to true if this runs in the browser process. Disabled by initServiceProcess().
    // TODO(petrcermak): This flag can be incorrectly set to false (even though this might run in
    // the browser process) on low-memory devices.
    private static boolean sInBrowserProcess = true;

    // Becomes true to indicate this process needs to wait for a shared RELRO in
    // finishLibraryLoad().
    private static boolean sWaitForSharedRelros = false;

    // Becomes true when initialization determines that the browser process can use the
    // shared RELRO.
    private static boolean sBrowserUsesSharedRelro = false;

    // The map of all RELRO sections either created or used in this process.
    private static Bundle sSharedRelros = null;

    // Current common random base load address.
    private static long sBaseLoadAddress = 0;

    // Current fixed-location load address for the next library called by loadLibrary().
    private static long sCurrentLoadAddress = 0;

    // Becomes true once prepareLibraryLoad() has been called.
    private static boolean sPrepareLibraryLoadCalled = false;

    // Used internally to initialize the linker's static data. Assume lock is held.
    private static void ensureInitializedLocked() {
        assert Thread.holdsLock(Linker.class);

        if (!sInitialized) {
            sRelroSharingSupported = false;
            if (NativeLibraries.sUseLinker) {
                if (DEBUG) Log.i(TAG, "Loading lib" + TAG + ".so");
                try {
                    System.loadLibrary(TAG);
                } catch (UnsatisfiedLinkError  e) {
                    // In a component build, the ".cr" suffix is added to each library name.
                    Log.w(TAG, "Couldn't load lib" + TAG + ".so, trying lib" + TAG + ".cr.so");
                    System.loadLibrary(TAG + ".cr");
                }
                sRelroSharingSupported = nativeCanUseSharedRelro();
                if (!sRelroSharingSupported) {
                    Log.w(TAG, "This system cannot safely share RELRO sections");
                } else {
                    if (DEBUG) Log.i(TAG, "This system supports safe shared RELRO sections");
                }

                if (sMemoryDeviceConfig == MEMORY_DEVICE_CONFIG_INIT) {
                    sMemoryDeviceConfig = SysUtils.isLowEndDevice()
                            ? MEMORY_DEVICE_CONFIG_LOW : MEMORY_DEVICE_CONFIG_NORMAL;
                }

                switch (BROWSER_SHARED_RELRO_CONFIG) {
                    case BROWSER_SHARED_RELRO_CONFIG_NEVER:
                        sBrowserUsesSharedRelro = false;
                        break;
                    case BROWSER_SHARED_RELRO_CONFIG_LOW_RAM_ONLY:
                        sBrowserUsesSharedRelro =
                                (sMemoryDeviceConfig == MEMORY_DEVICE_CONFIG_LOW);
                        if (sBrowserUsesSharedRelro) {
                            Log.w(TAG, "Low-memory device: shared RELROs used in all processes");
                        }
                        break;
                    case BROWSER_SHARED_RELRO_CONFIG_ALWAYS:
                        Log.w(TAG, "Beware: shared RELROs used in all processes!");
                        sBrowserUsesSharedRelro = true;
                        break;
                    default:
                        assert false : "Unreached";
                        break;
                }
            } else {
                if (DEBUG) Log.i(TAG, "Linker disabled");
            }

            if (!sRelroSharingSupported) {
                // Sanity.
                sBrowserUsesSharedRelro = false;
                sWaitForSharedRelros = false;
            }

            sInitialized = true;
        }
    }

    /**
     * A public interface used to run runtime linker tests after loading
     * libraries. Should only be used to implement the linker unit tests,
     * which is controlled by the value of NativeLibraries.sEnableLinkerTests
     * configured at build time.
     */
    public interface TestRunner {
        /**
         * Run runtime checks and return true if they all pass.
         * @param memoryDeviceConfig The current memory device configuration.
         * @param inBrowserProcess true iff this is the browser process.
         */
        public boolean runChecks(int memoryDeviceConfig, boolean inBrowserProcess);
    }

    // The name of a class that implements TestRunner.
    static String sTestRunnerClassName = null;

    /**
     * Set the TestRunner by its class name. It will be instantiated at
     * runtime after all libraries are loaded.
     * @param testRunnerClassName null or a String for the class name of the
     * TestRunner to use.
     */
    public static void setTestRunnerClassName(String testRunnerClassName) {
        if (DEBUG) Log.i(TAG, "setTestRunnerByClassName(" + testRunnerClassName + ") called");

        if (!NativeLibraries.sEnableLinkerTests) {
            // Ignore this in production code to prevent malvolent runtime injection.
            return;
        }

        synchronized (Linker.class) {
            assert sTestRunnerClassName == null;
            sTestRunnerClassName = testRunnerClassName;
        }
    }

    /**
     * Call this to retrieve the name of the current TestRunner class name
     * if any. This can be useful to pass it from the browser process to
     * child ones.
     * @return null or a String holding the name of the class implementing
     * the TestRunner set by calling setTestRunnerClassName() previously.
     */
    public static String getTestRunnerClassName() {
        synchronized (Linker.class) {
            return sTestRunnerClassName;
        }
    }

    /**
     * Call this method before any other Linker method to force a specific
     * memory device configuration. Should only be used for testing.
     * @param memoryDeviceConfig either MEMORY_DEVICE_CONFIG_LOW or MEMORY_DEVICE_CONFIG_NORMAL.
     */
    public static void setMemoryDeviceConfig(int memoryDeviceConfig) {
        if (DEBUG) Log.i(TAG, "setMemoryDeviceConfig(" + memoryDeviceConfig + ") called");
        // Sanity check. This method should only be called during tests.
        assert NativeLibraries.sEnableLinkerTests;
        synchronized (Linker.class) {
            assert sMemoryDeviceConfig == MEMORY_DEVICE_CONFIG_INIT;
            assert memoryDeviceConfig == MEMORY_DEVICE_CONFIG_LOW
                   || memoryDeviceConfig == MEMORY_DEVICE_CONFIG_NORMAL;
            if (DEBUG) {
                if (memoryDeviceConfig == MEMORY_DEVICE_CONFIG_LOW) {
                    Log.i(TAG, "Simulating a low-memory device");
                } else {
                    Log.i(TAG, "Simulating a regular-memory device");
                }
            }
            sMemoryDeviceConfig = memoryDeviceConfig;
        }
    }

    /**
     * Call this method to determine if this chromium project must
     * use this linker. If not, System.loadLibrary() should be used to load
     * libraries instead.
     */
    public static boolean isUsed() {
        // Only GYP targets that are APKs and have the 'use_chromium_linker' variable
        // defined as 1 will use this linker. For all others (the default), the
        // auto-generated NativeLibraries.sUseLinker variable will be false.
        if (!NativeLibraries.sUseLinker) return false;

        synchronized (Linker.class) {
            ensureInitializedLocked();
            // At the moment, there is also no point in using this linker if the
            // system does not support RELRO sharing safely.
            return sRelroSharingSupported;
        }
    }

    /**
     * Call this method to determine if the linker will try to use shared RELROs
     * for the browser process.
     */
    public static boolean isUsingBrowserSharedRelros() {
        synchronized (Linker.class) {
            ensureInitializedLocked();
            return sBrowserUsesSharedRelro;
        }
    }

    /**
     * Call this method to determine if the chromium project must load
     * the library directly from the zip file.
     */
    public static boolean isInZipFile() {
        return NativeLibraries.sUseLibraryInZipFile;
    }

    /**
     * Call this method just before loading any native shared libraries in this process.
     */
    public static void prepareLibraryLoad() {
        if (DEBUG) Log.i(TAG, "prepareLibraryLoad() called");
        synchronized (Linker.class) {
            sPrepareLibraryLoadCalled = true;

            if (sInBrowserProcess) {
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
    public static void finishLibraryLoad() {
        if (DEBUG) Log.i(TAG, "finishLibraryLoad() called");
        synchronized (Linker.class) {
            if (DEBUG) Log.i(TAG, String.format(
                    Locale.US,
                    "sInBrowserProcess=%s sBrowserUsesSharedRelro=%s sWaitForSharedRelros=%s",
                    sInBrowserProcess ? "true" : "false",
                    sBrowserUsesSharedRelro ? "true" : "false",
                    sWaitForSharedRelros ? "true" : "false"));

            if (sLoadedLibraries == null) {
                if (DEBUG) Log.i(TAG, "No libraries loaded");
            } else {
                if (sInBrowserProcess) {
                    // Create new Bundle containing RELRO section information
                    // for all loaded libraries. Make it available to getSharedRelros().
                    sSharedRelros = createBundleFromLibInfoMap(sLoadedLibraries);
                    if (DEBUG) {
                        Log.i(TAG, "Shared RELRO created");
                        dumpBundle(sSharedRelros);
                    }

                    if (sBrowserUsesSharedRelro) {
                        useSharedRelrosLocked(sSharedRelros);
                    }
                }

                if (sWaitForSharedRelros) {
                    assert !sInBrowserProcess;

                    // Wait until the shared relro bundle is received from useSharedRelros().
                    while (sSharedRelros == null) {
                        try {
                            Linker.class.wait();
                        } catch (InterruptedException ie) {
                            // no-op
                        }
                    }
                    useSharedRelrosLocked(sSharedRelros);
                    // Clear the Bundle to ensure its file descriptor references can't be reused.
                    sSharedRelros.clear();
                    sSharedRelros = null;
                }
            }

            if (NativeLibraries.sEnableLinkerTests && sTestRunnerClassName != null) {
                // The TestRunner implementation must be instantiated _after_
                // all libraries are loaded to ensure that its native methods
                // are properly registered.
                if (DEBUG) Log.i(TAG, "Instantiating " + sTestRunnerClassName);
                TestRunner testRunner = null;
                try {
                    testRunner = (TestRunner)
                            Class.forName(sTestRunnerClassName).newInstance();
                } catch (Exception e) {
                    Log.e(TAG, "Could not extract test runner class name", e);
                    testRunner = null;
                }
                if (testRunner != null) {
                    if (!testRunner.runChecks(sMemoryDeviceConfig, sInBrowserProcess)) {
                        Log.wtf(TAG, "Linker runtime tests failed in this process!!");
                        assert false;
                    } else {
                        Log.i(TAG, "All linker tests passed!");
                    }
                }
            }
        }
        if (DEBUG) Log.i(TAG, "finishLibraryLoad() exiting");
    }

    /**
     * Call this to send a Bundle containing the shared RELRO sections to be
     * used in this process. If initServiceProcess() was previously called,
     * finishLibraryLoad() will not exit until this method is called in another
     * thread with a non-null value.
     * @param bundle The Bundle instance containing a map of shared RELRO sections
     * to use in this process.
     */
    public static void useSharedRelros(Bundle bundle) {
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
        synchronized (Linker.class) {
            // Note that in certain cases, this can be called before
            // initServiceProcess() in service processes.
            sSharedRelros = clonedBundle;
            // Tell any listener blocked in finishLibraryLoad() about it.
            Linker.class.notifyAll();
        }
    }

    /**
     * Call this to retrieve the shared RELRO sections created in this process,
     * after loading all libraries.
     * @return a new Bundle instance, or null if RELRO sharing is disabled on
     * this system, or if initServiceProcess() was called previously.
     */
    public static Bundle getSharedRelros() {
        if (DEBUG) Log.i(TAG, "getSharedRelros() called");
        synchronized (Linker.class) {
            if (!sInBrowserProcess) {
                if (DEBUG) Log.i(TAG, "... returning null Bundle");
                return null;
            }

            // Return the Bundle created in finishLibraryLoad().
            if (DEBUG) Log.i(TAG, "... returning " + sSharedRelros);
            return sSharedRelros;
        }
    }


    /**
     * Call this method before loading any libraries to indicate that this
     * process shall neither create or reuse shared RELRO sections.
     */
    public static void disableSharedRelros() {
        if (DEBUG) Log.i(TAG, "disableSharedRelros() called");
        synchronized (Linker.class) {
            sInBrowserProcess = false;
            sWaitForSharedRelros = false;
            sBrowserUsesSharedRelro = false;
        }
    }

    /**
     * Call this method before loading any libraries to indicate that this
     * process is ready to reuse shared RELRO sections from another one.
     * Typically used when starting service processes.
     * @param baseLoadAddress the base library load address to use.
     */
    public static void initServiceProcess(long baseLoadAddress) {
        if (DEBUG) {
            Log.i(TAG, String.format(
                    Locale.US, "initServiceProcess(0x%x) called", baseLoadAddress));
        }
        synchronized (Linker.class) {
            ensureInitializedLocked();
            sInBrowserProcess = false;
            sBrowserUsesSharedRelro = false;
            if (sRelroSharingSupported) {
                sWaitForSharedRelros = true;
                sBaseLoadAddress = baseLoadAddress;
                sCurrentLoadAddress = baseLoadAddress;
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
    public static long getBaseLoadAddress() {
        synchronized (Linker.class) {
            ensureInitializedLocked();
            if (!sInBrowserProcess) {
                Log.w(TAG, "Shared RELRO sections are disabled in this process!");
                return 0;
            }

            setupBaseLoadAddressLocked();
            if (DEBUG) Log.i(TAG, String.format(Locale.US, "getBaseLoadAddress() returns 0x%x",
                                                sBaseLoadAddress));
            return sBaseLoadAddress;
        }
    }

    // Used internally to lazily setup the common random base load address.
    private static void setupBaseLoadAddressLocked() {
        assert Thread.holdsLock(Linker.class);
        if (sBaseLoadAddress == 0) {
            long address = computeRandomBaseLoadAddress();
            sBaseLoadAddress = address;
            sCurrentLoadAddress = address;
            if (address == 0) {
                // If the computed address is 0, there are issues with finding enough
                // free address space, so disable RELRO shared / fixed load addresses.
                Log.w(TAG, "Disabling shared RELROs due address space pressure");
                sBrowserUsesSharedRelro = false;
                sWaitForSharedRelros = false;
            }
        }
    }


    /**
     * Compute a random base load address at which to place loaded libraries.
     * @return new base load address, or 0 if the system does not support
     * RELRO sharing.
     */
    private static long computeRandomBaseLoadAddress() {
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
            Log.i(TAG, String.format(Locale.US, "Random native base load address: 0x%x", address));
        }
        return address;
    }

    // Used for debugging only.
    private static void dumpBundle(Bundle bundle) {
        if (DEBUG) Log.i(TAG, "Bundle has " + bundle.size() + " items: " + bundle);
    }

    /**
     * Use the shared RELRO section from a Bundle received form another process.
     * Call this after calling setBaseLoadAddress() then loading all libraries
     * with loadLibrary().
     * @param bundle Bundle instance generated with createSharedRelroBundle() in
     * another process.
     */
    private static void useSharedRelrosLocked(Bundle bundle) {
        assert Thread.holdsLock(Linker.class);

        if (DEBUG) Log.i(TAG, "Linker.useSharedRelrosLocked() called");

        if (bundle == null) {
            if (DEBUG) Log.i(TAG, "null bundle!");
            return;
        }

        if (!sRelroSharingSupported) {
            if (DEBUG) Log.i(TAG, "System does not support RELRO sharing");
            return;
        }

        if (sLoadedLibraries == null) {
            if (DEBUG) Log.i(TAG, "No libraries loaded!");
            return;
        }

        if (DEBUG) dumpBundle(bundle);
        HashMap<String, LibInfo> relroMap = createLibInfoMapFromBundle(bundle);

        // Apply the RELRO section to all libraries that were already loaded.
        for (Map.Entry<String, LibInfo> entry : relroMap.entrySet()) {
            String libName = entry.getKey();
            LibInfo libInfo = entry.getValue();
            if (!nativeUseSharedRelro(libName, libInfo)) {
                Log.w(TAG, "Could not use shared RELRO section for " + libName);
            } else {
                if (DEBUG) Log.i(TAG, "Using shared RELRO section for " + libName);
            }
        }

        // In service processes, close all file descriptors from the map now.
        if (!sInBrowserProcess) closeLibInfoMap(relroMap);

        if (DEBUG) Log.i(TAG, "Linker.useSharedRelrosLocked() exiting");
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
    public static void loadLibrary(@Nullable String zipFilePath, String libFilePath) {
        if (DEBUG) Log.i(TAG, "loadLibrary: " + zipFilePath + ", " + libFilePath);

        synchronized (Linker.class) {
            ensureInitializedLocked();

            // Security: Ensure prepareLibraryLoad() was called before.
            // In theory, this can be done lazily here, but it's more consistent
            // to use a pair of functions (i.e. prepareLibraryLoad() + finishLibraryLoad())
            // that wrap all calls to loadLibrary() in the library loader.
            assert sPrepareLibraryLoadCalled;

            if (sLoadedLibraries == null) sLoadedLibraries = new HashMap<String, LibInfo>();

            if (sLoadedLibraries.containsKey(libFilePath)) {
                if (DEBUG) Log.i(TAG, "Not loading " + libFilePath + " twice");
                return;
            }

            LibInfo libInfo = new LibInfo();
            long loadAddress = 0;
            if ((sInBrowserProcess && sBrowserUsesSharedRelro) || sWaitForSharedRelros) {
                // Load the library at a fixed address.
                loadAddress = sCurrentLoadAddress;
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
                        Locale.US,
                        "%s_LIBRARY_ADDRESS: %s %x",
                        sInBrowserProcess ? "BROWSER" : "RENDERER",
                        libFilePath,
                        libInfo.mLoadAddress));
            }

            if (sInBrowserProcess) {
                // Create a new shared RELRO section at the 'current' fixed load address.
                if (!nativeCreateSharedRelro(sharedRelRoName, sCurrentLoadAddress, libInfo)) {
                    Log.w(TAG, String.format(Locale.US,
                            "Could not create shared RELRO for %s at %x", libFilePath,
                            sCurrentLoadAddress));
                } else {
                    if (DEBUG) Log.i(TAG,
                        String.format(
                            Locale.US,
                            "Created shared RELRO for %s at %x: %s",
                            sharedRelRoName,
                            sCurrentLoadAddress,
                            libInfo.toString()));
                }
            }

            if (sCurrentLoadAddress != 0) {
                // Compute the next current load address. If sBaseLoadAddress
                // is not 0, this is an explicit library load address. Otherwise,
                // this is an explicit load address for relocated RELRO sections
                // only.
                sCurrentLoadAddress = libInfo.mLoadAddress + libInfo.mLoadSize;
            }

            sLoadedLibraries.put(sharedRelRoName, libInfo);
            if (DEBUG) Log.i(TAG, "Library details " + libInfo.toString());
        }
    }

    /**
     * Determine whether a library is the linker library. Also deal with the
     * component build that adds a .cr suffix to the name.
     */
    public static boolean isChromiumLinkerLibrary(String library) {
        return library.equals(TAG) || library.equals(TAG + ".cr");
    }

    /**
     * Get the full library path in zip file (lib/<abi>/crazy.<lib_name>).
     *
     * @param library The library's base name.
     * @return the library path.
     */
    public static String getLibraryFilePathInZipFile(String library) throws FileNotFoundException {
        synchronized (Linker.class) {
            ensureInitializedLocked();

            String path = nativeGetLibraryFilePathInZipFile(library);
            if (path.equals("")) {
                throw new FileNotFoundException(
                        "Failed to retrieve path in zip file for library " + library);
            }
            return path;
        }
    }

    /**
     * Check whether a library is page aligned and uncompressed in the APK file.
     *
     * @param apkFile Filename of the APK.
     * @param library The library's base name.
     * @return true if page aligned and uncompressed.
     */
    public static boolean checkLibraryIsMappableInApk(String apkFile, String library) {
        synchronized (Linker.class) {
            ensureInitializedLocked();

            if (DEBUG) Log.i(TAG, "checkLibraryIsMappableInApk: " + apkFile + ", " + library);
            boolean aligned = nativeCheckLibraryIsMappableInApk(apkFile, library);
            if (DEBUG) Log.i(TAG, library + " is " + (aligned ? "" : "NOT ")
                    + "page aligned in " + apkFile);
            return aligned;
        }
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

    /**
      * Native method used to get the full library path in zip file
      * (lib/<abi>/crazy.<lib_name>).
      *
      * @param library The library's base name.
      * @return the library path (or empty string on failure).
      */
    private static native String nativeGetLibraryFilePathInZipFile(String library);

    /**
     * Native method which checks whether a library is page aligned and
     * uncompressed in the APK file.
     *
     * @param apkFile Filename of the APK.
     * @param library The library's base name.
     * @return true if page aligned and uncompressed.
     */
    private static native boolean nativeCheckLibraryIsMappableInApk(String apkFile, String library);

    /**
     * Record information for a given library.
     * IMPORTANT: Native code knows about this class's fields, so
     * don't change them without modifying the corresponding C++ sources.
     * Also, the LibInfo instance owns the ashmem file descriptor.
     */
    public static class LibInfo implements Parcelable {

        public LibInfo() {
            mLoadAddress = 0;
            mLoadSize = 0;
            mRelroStart = 0;
            mRelroSize = 0;
            mRelroFd = -1;
        }

        public void close() {
            if (mRelroFd >= 0) {
                try {
                    ParcelFileDescriptor.adoptFd(mRelroFd).close();
                } catch (java.io.IOException e) {
                    if (DEBUG) Log.e(TAG, "Failed to close fd: " + mRelroFd);
                }
                mRelroFd = -1;
            }
        }

        // from Parcelable
        public LibInfo(Parcel in) {
            mLoadAddress = in.readLong();
            mLoadSize = in.readLong();
            mRelroStart = in.readLong();
            mRelroSize = in.readLong();
            ParcelFileDescriptor fd = ParcelFileDescriptor.CREATOR.createFromParcel(in);
            // If CreateSharedRelro fails, the OS file descriptor will be -1 and |fd| will be null.
            mRelroFd = (fd == null) ? -1 : fd.detachFd();
        }

        // from Parcelable
        @Override
        public void writeToParcel(Parcel out, int flags) {
            if (mRelroFd >= 0) {
                out.writeLong(mLoadAddress);
                out.writeLong(mLoadSize);
                out.writeLong(mRelroStart);
                out.writeLong(mRelroSize);
                try {
                    ParcelFileDescriptor fd = ParcelFileDescriptor.fromFd(mRelroFd);
                    fd.writeToParcel(out, 0);
                    fd.close();
                } catch (java.io.IOException e) {
                    Log.e(TAG, "Cant' write LibInfo file descriptor to parcel", e);
                }
            }
        }

        // from Parcelable
        @Override
        public int describeContents() {
            return Parcelable.CONTENTS_FILE_DESCRIPTOR;
        }

        // from Parcelable
        public static final Parcelable.Creator<LibInfo> CREATOR =
                new Parcelable.Creator<LibInfo>() {
                    @Override
                    public LibInfo createFromParcel(Parcel in) {
                        return new LibInfo(in);
                    }

                    @Override
                    public LibInfo[] newArray(int size) {
                        return new LibInfo[size];
                    }
                };

        @Override
        public String toString() {
            return String.format(Locale.US,
                                 "[load=0x%x-0x%x relro=0x%x-0x%x fd=%d]",
                                 mLoadAddress,
                                 mLoadAddress + mLoadSize,
                                 mRelroStart,
                                 mRelroStart + mRelroSize,
                                 mRelroFd);
        }

        // IMPORTANT: Don't change these fields without modifying the
        // native code that accesses them directly!
        @AccessedByNative
        public long mLoadAddress; // page-aligned library load address.
        @AccessedByNative
        public long mLoadSize;    // page-aligned library load size.
        @AccessedByNative
        public long mRelroStart;  // page-aligned address in memory, or 0 if none.
        @AccessedByNative
        public long mRelroSize;   // page-aligned size in memory, or 0.
        @AccessedByNative
        public int  mRelroFd;     // ashmem file descriptor, or -1
    }

    // Create a Bundle from a map of LibInfo objects.
    private static Bundle createBundleFromLibInfoMap(HashMap<String, LibInfo> map) {
        Bundle bundle = new Bundle(map.size());
        for (Map.Entry<String, LibInfo> entry : map.entrySet()) {
            bundle.putParcelable(entry.getKey(), entry.getValue());
        }

        return bundle;
    }

    // Create a new LibInfo map from a Bundle.
    private static HashMap<String, LibInfo> createLibInfoMapFromBundle(Bundle bundle) {
        HashMap<String, LibInfo> map = new HashMap<String, LibInfo>();
        for (String library : bundle.keySet()) {
            LibInfo libInfo = bundle.getParcelable(library);
            map.put(library, libInfo);
        }
        return map;
    }

    // Call the close() method on all values of a LibInfo map.
    private static void closeLibInfoMap(HashMap<String, LibInfo> map) {
        for (Map.Entry<String, LibInfo> entry : map.entrySet()) {
            entry.getValue().close();
        }
    }

    // The map of libraries that are currently loaded in this process.
    private static HashMap<String, LibInfo> sLoadedLibraries = null;

    // Used to pass the shared RELRO Bundle through Binder.
    public static final String EXTRA_LINKER_SHARED_RELROS =
            "org.chromium.base.android.linker.shared_relros";
}
