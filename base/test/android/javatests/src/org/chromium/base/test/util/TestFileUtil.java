// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base.test.util;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.Reader;
import java.io.Writer;
import java.util.Arrays;

/**
 * Utility class for dealing with files for test.
 */
public class TestFileUtil {
    public static void createNewHtmlFile(String name, String title, String body)
            throws IOException {
        File file = new File(name);
        if (!file.createNewFile()) {
            throw new IOException("File \"" + name + "\" already exists");
        }

        Writer writer = null;
        try {
            writer = new OutputStreamWriter(new FileOutputStream(file), "UTF-8");
            writer.write("<html><meta charset=\"UTF-8\" />"
                    + "     <head><title>" + title + "</title></head>"
                    + "     <body>"
                    + (body != null ? body : "")
                    + "     </body>"
                    + "   </html>");
        } finally {
            if (writer != null) {
                writer.close();
            }
        }
    }

    public static void deleteFile(String name) {
        File file = new File(name);
        boolean deleted = file.delete();
        assert (deleted || !file.exists());
    }

    /**
     * @param fileName the file to read in.
     * @param sizeLimit cap on the file size: will throw an exception if exceeded
     * @return Array of chars read from the file
     * @throws FileNotFoundException file does not exceed
     * @throws IOException error encountered accessing the file
     */
    public static char[] readUtf8File(String fileName, int sizeLimit) throws
            FileNotFoundException, IOException {
        Reader reader = null;
        try {
            File f = new File(fileName);
            if (f.length() > sizeLimit) {
                throw new IOException("File " + fileName + " length " + f.length()
                        + " exceeds limit " + sizeLimit);
            }
            char[] buffer = new char[(int) f.length()];
            reader = new InputStreamReader(new FileInputStream(f), "UTF-8");
            int charsRead = reader.read(buffer);
            // Debug check that we've exhausted the input stream (will fail e.g. if the
            // file grew after we inspected its length).
            assert !reader.ready();
            return charsRead < buffer.length ? Arrays.copyOfRange(buffer, 0, charsRead) : buffer;
        } finally {
            if (reader != null) reader.close();
        }
    }
}
