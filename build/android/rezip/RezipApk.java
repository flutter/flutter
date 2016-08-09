// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Enumeration;
import java.util.List;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;
import java.util.jar.JarOutputStream;
import java.util.regex.Pattern;
import java.util.zip.CRC32;

/**
 * Command line tool used to build APKs which support loading the native code library
 * directly from the APK file. To construct the APK we rename the native library by
 * adding the prefix "crazy." to the filename. This is done to prevent the Android
 * Package Manager from extracting the library. The native code must be page aligned
 * and uncompressed. The page alignment is implemented by adding a zero filled file
 * in front of the the native code library. This tool is designed so that running
 * SignApk and/or zipalign on the resulting APK does not break the page alignment.
 * This is achieved by outputing the filenames in the same canonical order used
 * by SignApk and adding the same alignment fields added by zipalign.
 */
class RezipApk {
    // Alignment to use for non-compressed files (must match zipalign).
    private static final int ALIGNMENT = 4;

    // Alignment to use for non-compressed *.so files
    private static final int LIBRARY_ALIGNMENT = 4096;

    // Files matching this pattern are not copied to the output when adding alignment.
    // When reordering and verifying the APK they are copied to the end of the file.
    private static Pattern sMetaFilePattern =
            Pattern.compile("^(META-INF/((.*)[.](SF|RSA|DSA)|com/android/otacert))|("
                    + Pattern.quote(JarFile.MANIFEST_NAME) + ")$");

    // Pattern for matching a shared library in the APK
    private static Pattern sLibraryPattern = Pattern.compile("^lib/[^/]*/lib.*[.]so$");
    // Pattern for match the crazy linker in the APK
    private static Pattern sCrazyLinkerPattern =
            Pattern.compile("^lib/[^/]*/libchromium_android_linker.so$");
    // Pattern for matching a crazy loaded shared library in the APK
    private static Pattern sCrazyLibraryPattern = Pattern.compile("^lib/[^/]*/crazy.lib.*[.]so$");

    private static boolean isLibraryFilename(String filename) {
        return sLibraryPattern.matcher(filename).matches()
                && !sCrazyLinkerPattern.matcher(filename).matches();
    }

    private static boolean isCrazyLibraryFilename(String filename) {
        return sCrazyLibraryPattern.matcher(filename).matches();
    }

    private static String renameLibraryForCrazyLinker(String filename) {
        int lastSlash = filename.lastIndexOf('/');
        // We rename the library, so that the Android Package Manager
        // no longer extracts the library.
        return filename.substring(0, lastSlash + 1) + "crazy." + filename.substring(lastSlash + 1);
    }

    /**
     * Wraps another output stream, counting the number of bytes written.
     */
    private static class CountingOutputStream extends OutputStream {
        private long mCount = 0;
        private OutputStream mOut;

        public CountingOutputStream(OutputStream out) {
            this.mOut = out;
        }

        /** Returns the number of bytes written. */
        public long getCount() {
            return mCount;
        }

        @Override public void write(byte[] b, int off, int len) throws IOException {
            mOut.write(b, off, len);
            mCount += len;
        }

        @Override public void write(int b) throws IOException {
            mOut.write(b);
            mCount++;
        }

        @Override public void close() throws IOException {
            mOut.close();
        }

        @Override public void flush() throws IOException {
            mOut.flush();
        }
    }

    private static String outputName(JarEntry entry, boolean rename) {
        String inName = entry.getName();
        if (rename && entry.getSize() > 0 && isLibraryFilename(inName)) {
            return renameLibraryForCrazyLinker(inName);
        }
        return inName;
    }

    /**
     * Comparator used to sort jar entries from the input file.
     * Sorting is done based on the output filename (which maybe renamed).
     * Filenames are in natural string order, except that filenames matching
     * the meta-file pattern are always after other files. This is so the manifest
     * and signature are at the end of the file after any alignment file.
     */
    private static class EntryComparator implements Comparator<JarEntry> {
        private boolean mRename;

        public EntryComparator(boolean rename) {
            mRename = rename;
        }

        @Override
        public int compare(JarEntry j1, JarEntry j2) {
            String o1 = outputName(j1, mRename);
            String o2 = outputName(j2, mRename);
            boolean o1Matches = sMetaFilePattern.matcher(o1).matches();
            boolean o2Matches = sMetaFilePattern.matcher(o2).matches();
            if (o1Matches != o2Matches) {
                return o1Matches ? 1 : -1;
            } else {
                return o1.compareTo(o2);
            }
        }
    }

    // Build an ordered list of jar entries. The jar entries from the input are
    // sorted based on the output filenames (which maybe renamed). If |omitMetaFiles|
    // is true do not include the jar entries for the META-INF files.
    // Entries are ordered in the deterministic order used by SignApk.
    private static List<JarEntry> getOutputFileOrderEntries(
            JarFile jar, boolean omitMetaFiles, boolean rename) {
        List<JarEntry> entries = new ArrayList<JarEntry>();
        for (Enumeration<JarEntry> e = jar.entries(); e.hasMoreElements(); ) {
            JarEntry entry = e.nextElement();
            if (entry.isDirectory()) {
                continue;
            }
            if (omitMetaFiles && sMetaFilePattern.matcher(entry.getName()).matches()) {
                continue;
            }
            entries.add(entry);
        }

        // We sort the input entries by name. When present META-INF files
        // are sorted to the end.
        Collections.sort(entries, new EntryComparator(rename));
        return entries;
    }

    /**
     * Add a zero filled alignment file at this point in the zip file,
     * The added file will be added before |name| and after |prevName|.
     * The size of the alignment file is such that the location of the
     * file |name| will be on a LIBRARY_ALIGNMENT boundary.
     *
     * Note this arrangement is devised so that running SignApk and/or zipalign on the resulting
     * file will not alter the alignment.
     *
     * @param offset number of bytes into the output file at this point.
     * @param timestamp time in millis since the epoch to include in the header.
     * @param name the name of the library filename.
     * @param prevName the name of the previous file in the archive (or null).
     * @param out jar output stream to write the alignment file to.
     *
     * @throws IOException if the output file can not be written.
     */
    private static void addAlignmentFile(
            long offset, long timestamp, String name, String prevName,
            JarOutputStream out) throws IOException {

        // Compute the start and alignment of the library, as if it was next.
        int headerSize = JarFile.LOCHDR + name.length();
        long libOffset = offset + headerSize;
        int libNeeded = LIBRARY_ALIGNMENT - (int) (libOffset % LIBRARY_ALIGNMENT);
        if (libNeeded == LIBRARY_ALIGNMENT) {
            // Already aligned, no need to added alignment file.
            return;
        }

        // Check that there is not another file between the library and the
        // alignment file.
        String alignName = name.substring(0, name.length() - 2) + "align";
        if (prevName != null && prevName.compareTo(alignName) >= 0) {
            throw new UnsupportedOperationException(
                "Unable to insert alignment file, because there is "
                + "another file in front of the file to be aligned. "
                + "Other file: " + prevName + " Alignment file: " + alignName
                + " file: " + name);
        }

        // Compute the size of the alignment file header.
        headerSize = JarFile.LOCHDR + alignName.length();
        // We are going to add an alignment file of type STORED. This file
        // will itself induce a zipalign alignment adjustment.
        int extraNeeded =
                (ALIGNMENT - (int) ((offset + headerSize) % ALIGNMENT)) % ALIGNMENT;
        headerSize += extraNeeded;

        if (libNeeded < headerSize + 1) {
            // The header was bigger than the alignment that we need, add another page.
            libNeeded += LIBRARY_ALIGNMENT;
        }
        // Compute the size of the alignment file.
        libNeeded -= headerSize;

        // Build the header for the alignment file.
        byte[] zeroBuffer = new byte[libNeeded];
        JarEntry alignEntry = new JarEntry(alignName);
        alignEntry.setMethod(JarEntry.STORED);
        alignEntry.setSize(libNeeded);
        alignEntry.setTime(timestamp);
        CRC32 crc = new CRC32();
        crc.update(zeroBuffer);
        alignEntry.setCrc(crc.getValue());

        if (extraNeeded != 0) {
            alignEntry.setExtra(new byte[extraNeeded]);
        }

        // Output the alignment file.
        out.putNextEntry(alignEntry);
        out.write(zeroBuffer);
        out.closeEntry();
        out.flush();
    }

    // Make a JarEntry for the output file which corresponds to the input
    // file. The output file will be called |name|. The output file will always
    // be uncompressed (STORED). If the input is not STORED it is necessary to inflate
    // it to compute the CRC and size of the output entry.
    private static JarEntry makeStoredEntry(String name, JarEntry inEntry, JarFile in)
            throws IOException {
        JarEntry outEntry = new JarEntry(name);
        outEntry.setMethod(JarEntry.STORED);

        if (inEntry.getMethod() == JarEntry.STORED) {
            outEntry.setCrc(inEntry.getCrc());
            outEntry.setSize(inEntry.getSize());
        } else {
            // We are inflating the file. We need to compute the CRC and size.
            byte[] buffer = new byte[4096];
            CRC32 crc = new CRC32();
            int size = 0;
            int num;
            InputStream data = in.getInputStream(inEntry);
            while ((num = data.read(buffer)) > 0) {
                crc.update(buffer, 0, num);
                size += num;
            }
            data.close();
            outEntry.setCrc(crc.getValue());
            outEntry.setSize(size);
        }
        return outEntry;
    }

    /**
     * Copy the contents of the input APK file to the output APK file. If |rename| is
     * true then non-empty libraries (*.so) in the input will be renamed by prefixing
     * "crazy.". This is done to prevent the Android Package Manager extracting the
     * library. Note the crazy linker itself is not renamed, for bootstrapping reasons.
     * Empty libraries are not renamed (they are in the APK to workaround a bug where
     * the Android Package Manager fails to delete old versions when upgrading).
     * There must be exactly one "crazy" library in the output stream. The "crazy"
     * library will be uncompressed and page aligned in the output stream. Page
     * alignment is implemented by adding a zero filled file, regular alignment is
     * implemented by adding a zero filled extra field to the zip file header. If
     * |addAlignment| is true a page alignment file is added, otherwise the "crazy"
     * library must already be page aligned. Care is taken so that the output is generated
     * in the same way as SignApk. This is important so that running SignApk and
     * zipalign on the output does not break the page alignment. The archive may not
     * contain a "*.apk" as SignApk has special nested signing logic that we do not
     * support.
     *
     * @param in The input APK File.
     * @param out The output APK stream.
     * @param countOut Counting output stream (to measure the current offset).
     * @param addAlignment Whether to add the alignment file or just check.
     * @param rename Whether to rename libraries to be "crazy".
     *
     * @throws IOException if the output file can not be written.
     */
    private static void rezip(
            JarFile in, JarOutputStream out, CountingOutputStream countOut,
            boolean addAlignment, boolean rename) throws IOException {

        List<JarEntry> entries = getOutputFileOrderEntries(in, addAlignment, rename);
        long timestamp = System.currentTimeMillis();
        byte[] buffer = new byte[4096];
        boolean firstEntry = true;
        String prevName = null;
        int numCrazy = 0;
        for (JarEntry inEntry : entries) {
            // Rename files, if specied.
            String name = outputName(inEntry, rename);
            if (name.endsWith(".apk")) {
                throw new UnsupportedOperationException(
                        "Nested APKs are not supported: " + name);
            }

            // Build the header.
            JarEntry outEntry = null;
            boolean isCrazy = isCrazyLibraryFilename(name);
            if (isCrazy) {
                // "crazy" libraries are alway output uncompressed (STORED).
                outEntry = makeStoredEntry(name, inEntry, in);
                numCrazy++;
                if (numCrazy > 1) {
                    throw new UnsupportedOperationException(
                            "Found more than one library\n"
                            + "Multiple libraries are not supported for APKs that use "
                            + "'load_library_from_zip'.\n"
                            + "See crbug/388223.\n"
                            + "Note, check that your build is clean.\n"
                            + "An unclean build can incorrectly incorporate old "
                            + "libraries in the APK.");
                }
            } else if (inEntry.getMethod() == JarEntry.STORED) {
                // Preserve the STORED method of the input entry.
                outEntry = new JarEntry(inEntry);
                outEntry.setExtra(null);
            } else {
                // Create a new entry so that the compressed len is recomputed.
                outEntry = new JarEntry(name);
            }
            outEntry.setTime(timestamp);

            // Compute and add alignment
            long offset = countOut.getCount();
            if (firstEntry) {
                // The first entry in a jar file has an extra field of
                // four bytes that you can't get rid of; any extra
                // data you specify in the JarEntry is appended to
                // these forced four bytes.  This is JAR_MAGIC in
                // JarOutputStream; the bytes are 0xfeca0000.
                firstEntry = false;
                offset += 4;
            }
            if (outEntry.getMethod() == JarEntry.STORED) {
                if (isCrazy) {
                    if (addAlignment) {
                        addAlignmentFile(offset, timestamp, name, prevName, out);
                    }
                    // We check that we did indeed get to a page boundary.
                    offset = countOut.getCount() + JarFile.LOCHDR + name.length();
                    if ((offset % LIBRARY_ALIGNMENT) != 0) {
                        throw new AssertionError(
                                "Library was not page aligned when verifying page alignment. "
                                + "Library name: " + name + " Expected alignment: "
                                + LIBRARY_ALIGNMENT + "Offset: " + offset + " Error: "
                                + (offset % LIBRARY_ALIGNMENT));
                    }
                } else {
                    // This is equivalent to zipalign.
                    offset += JarFile.LOCHDR + name.length();
                    int needed = (ALIGNMENT - (int) (offset % ALIGNMENT)) % ALIGNMENT;
                    if (needed != 0) {
                        outEntry.setExtra(new byte[needed]);
                    }
                }
            }
            out.putNextEntry(outEntry);

            // Copy the data from the input to the output
            int num;
            InputStream data = in.getInputStream(inEntry);
            while ((num = data.read(buffer)) > 0) {
                out.write(buffer, 0, num);
            }
            data.close();
            out.closeEntry();
            out.flush();
            prevName = name;
        }
        if (numCrazy == 0) {
            throw new AssertionError("There was no crazy library in the archive");
        }
    }

    private static void usage() {
        System.err.println("Usage: prealignapk (addalignment|reorder) input.apk output.apk");
        System.err.println("\"crazy\" libraries are always inflated in the output");
        System.err.println(
                "  renamealign  - rename libraries with \"crazy.\" prefix and add alignment file");
        System.err.println("  align        - add alignment file");
        System.err.println("  reorder      - re-creates canonical ordering and checks alignment");
        System.exit(2);
    }

    public static void main(String[] args) throws IOException {
        if (args.length != 3) usage();

        boolean addAlignment = false;
        boolean rename = false;
        if (args[0].equals("renamealign")) {
            // Normal case. Before signing we rename the library and add an alignment file.
            addAlignment = true;
            rename = true;
        } else if (args[0].equals("align")) {
            // LGPL compliance case. Before signing, we add an alignment file to a
            // reconstructed APK which already contains the "crazy" library.
            addAlignment = true;
            rename = false;
        } else if (args[0].equals("reorder")) {
            // Normal case. After jarsigning we write the file in the canonical order and check.
            addAlignment = false;
        } else {
            usage();
        }

        String inputFilename = args[1];
        String outputFilename = args[2];

        JarFile inputJar = null;
        FileOutputStream outputFile = null;

        try {
            inputJar = new JarFile(new File(inputFilename), true);
            outputFile = new FileOutputStream(outputFilename);

            CountingOutputStream outCount = new CountingOutputStream(outputFile);
            JarOutputStream outputJar = new JarOutputStream(outCount);

            // Match the compression level used by SignApk.
            outputJar.setLevel(9);

            rezip(inputJar, outputJar, outCount, addAlignment, rename);
            outputJar.close();
        } finally {
            if (inputJar != null) inputJar.close();
            if (outputFile != null) outputFile.close();
        }
    }
}
