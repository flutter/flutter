// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base.library_loader;

import android.os.Bundle;
import android.os.Parcel;
import android.os.ParcelFileDescriptor;
import android.os.Parcelable;

import org.chromium.base.Log;
import org.chromium.base.annotations.AccessedByNative;

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
public abstract class Linker {
    // Log tag for this class.
    private static final String TAG = "cr.library_loader";

    // Set to true to enable debug logs.
    protected static final boolean DEBUG = false;

    // Used to pass the shared RELRO Bundle through Binder.
    public static final String EXTRA_LINKER_SHARED_RELROS =
            "org.chromium.base.android.linker.shared_relros";

    // Guards all access to the linker.
    protected final Object mLock = new Object();

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
    protected int mMemoryDeviceConfig = MEMORY_DEVICE_CONFIG_INIT;

    // Singleton.
    private static Linker sSingleton = null;
    private static Object sSingletonLock = new Object();

    // Protected singleton constructor.
    protected Linker() { }

    // Get singleton instance.
    public static final Linker getInstance() {
        synchronized (sSingletonLock) {
            if (sSingleton == null) {
                // TODO(simonb): Extend later to return either a LegacyLinker
                // or a ModernLinker instance.
                sSingleton = new LegacyLinker();
            }
            return sSingleton;
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
    String mTestRunnerClassName = null;

    /**
     * Set the TestRunner by its class name. It will be instantiated at
     * runtime after all libraries are loaded.
     * @param testRunnerClassName null or a String for the class name of the
     * TestRunner to use.
     */
    public void setTestRunnerClassName(String testRunnerClassName) {
        if (DEBUG) {
            Log.i(TAG, "setTestRunnerByClassName(" + testRunnerClassName + ") called");
        }
        if (!NativeLibraries.sEnableLinkerTests) {
            // Ignore this in production code to prevent malevolent runtime injection.
            return;
        }

        synchronized (mLock) {
            assert mTestRunnerClassName == null;
            mTestRunnerClassName = testRunnerClassName;
        }
    }

    /**
     * Call this to retrieve the name of the current TestRunner class name
     * if any. This can be useful to pass it from the browser process to
     * child ones.
     * @return null or a String holding the name of the class implementing
     * the TestRunner set by calling setTestRunnerClassName() previously.
     */
    public String getTestRunnerClassName() {
        synchronized (mLock) {
            return mTestRunnerClassName;
        }
    }

    /**
     * Call this method before any other Linker method to force a specific
     * memory device configuration. Should only be used for testing.
     * @param memoryDeviceConfig either MEMORY_DEVICE_CONFIG_LOW or MEMORY_DEVICE_CONFIG_NORMAL.
     */
    public void setMemoryDeviceConfig(int memoryDeviceConfig) {
        if (DEBUG) {
            Log.i(TAG, "setMemoryDeviceConfig(" + memoryDeviceConfig + ") called");
        }
        // Sanity check. This method should only be called during tests.
        assert NativeLibraries.sEnableLinkerTests;
        synchronized (mLock) {
            assert mMemoryDeviceConfig == MEMORY_DEVICE_CONFIG_INIT;
            assert memoryDeviceConfig == MEMORY_DEVICE_CONFIG_LOW
                   || memoryDeviceConfig == MEMORY_DEVICE_CONFIG_NORMAL;
            if (DEBUG) {
                if (memoryDeviceConfig == MEMORY_DEVICE_CONFIG_LOW) {
                    Log.i(TAG, "Simulating a low-memory device");
                } else {
                    Log.i(TAG, "Simulating a regular-memory device");
                }
            }
            mMemoryDeviceConfig = memoryDeviceConfig;
        }
    }

    /**
     * Call this method to determine if this chromium project must
     * use this linker. If not, System.loadLibrary() should be used to load
     * libraries instead.
     */
    public abstract boolean isUsed();

    /**
     * Call this method to determine if the linker will try to use shared RELROs
     * for the browser process.
     */
    public abstract boolean isUsingBrowserSharedRelros();

    /**
     * Call this method to determine if the chromium project must load
     * the library directly from the zip file.
     */
    public abstract boolean isInZipFile();

    /**
     * Call this method just before loading any native shared libraries in this process.
     */
    public abstract void prepareLibraryLoad();

    /**
     * Call this method just after loading all native shared libraries in this process.
     * Note that when in a service process, this will block until the RELRO bundle is
     * received, i.e. when another thread calls useSharedRelros().
     */
    public abstract void finishLibraryLoad();

    /**
     * Call this to send a Bundle containing the shared RELRO sections to be
     * used in this process. If initServiceProcess() was previously called,
     * finishLibraryLoad() will not exit until this method is called in another
     * thread with a non-null value.
     * @param bundle The Bundle instance containing a map of shared RELRO sections
     * to use in this process.
     */
    public abstract void useSharedRelros(Bundle bundle);

    /**
     * Call this to retrieve the shared RELRO sections created in this process,
     * after loading all libraries.
     * @return a new Bundle instance, or null if RELRO sharing is disabled on
     * this system, or if initServiceProcess() was called previously.
     */
    public abstract Bundle getSharedRelros();


    /**
     * Call this method before loading any libraries to indicate that this
     * process shall neither create or reuse shared RELRO sections.
     */
    public abstract void disableSharedRelros();

    /**
     * Call this method before loading any libraries to indicate that this
     * process is ready to reuse shared RELRO sections from another one.
     * Typically used when starting service processes.
     * @param baseLoadAddress the base library load address to use.
     */
    public abstract void initServiceProcess(long baseLoadAddress);

    /**
     * Retrieve the base load address of all shared RELRO sections.
     * This also enforces the creation of shared RELRO sections in
     * prepareLibraryLoad(), which can later be retrieved with getSharedRelros().
     * @return a common, random base load address, or 0 if RELRO sharing is
     * disabled.
     */
    public abstract long getBaseLoadAddress();

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
    public abstract void loadLibrary(@Nullable String zipFilePath, String libFilePath);

    /**
     * Determine whether a library is the linker library. Also deal with the
     * component build that adds a .cr suffix to the name.
     */
    public abstract boolean isChromiumLinkerLibrary(String library);

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
                    if (DEBUG) {
                        Log.e(TAG, "Failed to close fd: " + mRelroFd);
                    }
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
    protected Bundle createBundleFromLibInfoMap(HashMap<String, LibInfo> map) {
        Bundle bundle = new Bundle(map.size());
        for (Map.Entry<String, LibInfo> entry : map.entrySet()) {
            bundle.putParcelable(entry.getKey(), entry.getValue());
        }

        return bundle;
    }

    // Create a new LibInfo map from a Bundle.
    protected HashMap<String, LibInfo> createLibInfoMapFromBundle(Bundle bundle) {
        HashMap<String, LibInfo> map = new HashMap<String, LibInfo>();
        for (String library : bundle.keySet()) {
            LibInfo libInfo = bundle.getParcelable(library);
            map.put(library, libInfo);
        }
        return map;
    }

    // Call the close() method on all values of a LibInfo map.
    protected void closeLibInfoMap(HashMap<String, LibInfo> map) {
        for (Map.Entry<String, LibInfo> entry : map.entrySet()) {
            entry.getValue().close();
        }
    }
}
