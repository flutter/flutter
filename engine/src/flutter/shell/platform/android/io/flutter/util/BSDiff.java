// Copyright 2003-2005 Colin Percival. All rights reserved.
// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.util;

import java.io.*;
import java.util.zip.GZIPInputStream;

/**
 * This is a Java port of algorithm from Flutter framework bsdiff.dart.
 * Note that this port uses 32-bit ints, which limits data size to 2GB.
 **/
public abstract class BSDiff {
    public static byte[] bspatch(byte[] olddata, byte[] diffdata) throws IOException {
        InputStream in = new ByteArrayInputStream(diffdata, 0, diffdata.length);
        DataInputStream header = new DataInputStream(in);

        byte[] magic = new byte[8];
        header.read(magic);
        if (!new String(magic).equals("BZDIFF40")) {
            throw new IOException("Invalid magic");
        }

        int ctrllen = (int) header.readLong();
        int datalen = (int) header.readLong();
        int newsize = (int) header.readLong();
        header.close();

        in = new ByteArrayInputStream(diffdata, 0, diffdata.length);
        in.skip(32);
        DataInputStream cpf = new DataInputStream(new GZIPInputStream(in));

        in = new ByteArrayInputStream(diffdata, 0, diffdata.length);
        in.skip(32 + ctrllen);
        InputStream dpf = new GZIPInputStream(in);

        in = new ByteArrayInputStream(diffdata, 0, diffdata.length);
        in.skip(32 + ctrllen + datalen);
        InputStream epf = new GZIPInputStream(in);

        byte[] newdata = new byte[newsize];

	int oldpos = 0;
        int newpos = 0;

        while (newpos < newsize) {
            int[] ctrl = new int[3];
            for (int i = 0; i <= 2; i++) {
                ctrl[i] = (int) cpf.readLong();
            }
            if (newpos + ctrl[0] > newsize) {
                throw new IOException("Invalid ctrl[0]");
            }

            read(dpf, newdata, newpos, ctrl[0]);

            for (int i = 0; i < ctrl[0]; i++) {
                if ((oldpos + i >= 0) && (oldpos + i < olddata.length)) {
                    newdata[newpos + i] += olddata[oldpos + i];
                }
            }

            newpos += ctrl[0];
            oldpos += ctrl[0];

            if (newpos + ctrl[1] > newsize) {
                throw new IOException("Invalid ctrl[0]");
            }

            read(epf, newdata, newpos, ctrl[1]);

            newpos += ctrl[1];
            oldpos += ctrl[2];
        }

        cpf.close();
        dpf.close();
        epf.close();

        return newdata;
    }

    private static void read(InputStream in, byte[] buf, int off, int len) throws IOException {
        for (int i, n = 0; n < len; n += i) {
            if ((i = in.read(buf, off + n, len - n)) < 0) {
                throw new IOException("Unexpected EOF");
            }
        }
    }
}
