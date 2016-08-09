// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.bindings;

import android.test.suitebuilder.annotation.SmallTest;

import junit.framework.TestCase;

import java.nio.charset.Charset;

/**
 * Testing {@link BindingsHelper}.
 */
public class BindingsHelperTest extends TestCase {

    /**
     * Testing {@link BindingsHelper#utf8StringSizeInBytes(String)}.
     */
    @SmallTest
    public void testUTF8StringLength() {
        String[] stringsToTest = {
            "",
            "a",
            "hello world",
            "éléphant",
            "𠜎𠜱𠝹𠱓𠱸𠲖𠳏𠳕",
            "你午饭想吃什么",
            "你午饭想吃什么\0éléphant",
        };
        for (String s : stringsToTest) {
            assertEquals(s.getBytes(Charset.forName("utf8")).length,
                    BindingsHelper.utf8StringSizeInBytes(s));
        }
        assertEquals(1, BindingsHelper.utf8StringSizeInBytes("\0"));
        String s = new StringBuilder().appendCodePoint(0x0).appendCodePoint(0x80).
                appendCodePoint(0x800).appendCodePoint(0x10000).toString();
        assertEquals(10, BindingsHelper.utf8StringSizeInBytes(s));
        assertEquals(10, s.getBytes(Charset.forName("utf8")).length);
    }

    /**
     * Testing {@link BindingsHelper#align(int)}.
     */
    @SmallTest
    public void testAlign() {
        for (int i = 0; i < 3 * BindingsHelper.ALIGNMENT; ++i) {
            int j = BindingsHelper.align(i);
            assertTrue(j >= i);
            assertTrue(j % BindingsHelper.ALIGNMENT == 0);
            assertTrue(j - i < BindingsHelper.ALIGNMENT);
        }
    }
}
