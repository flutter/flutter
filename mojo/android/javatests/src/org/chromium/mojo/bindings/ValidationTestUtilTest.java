// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.bindings;

import android.test.suitebuilder.annotation.SmallTest;

import org.chromium.mojo.MojoTestCase;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;

/**
 * Testing {@link ValidationTestUtil}.
 */
public class ValidationTestUtilTest extends MojoTestCase {

    /**
     * Check that the input parser is correct on a given input.
     */
    public static void checkInputParser(
            String input, boolean isInputValid, ByteBuffer expectedData, int expectedHandlesCount) {
        ValidationTestUtil.Data data = ValidationTestUtil.parseData(input);
        if (isInputValid) {
            assertNull(data.getErrorMessage());
            assertEquals(expectedData, data.getData());
            assertEquals(expectedHandlesCount, data.getHandlesCount());
        } else {
            assertNotNull(data.getErrorMessage());
            assertNull(data.getData());
        }
    }

    /**
     * Testing {@link ValidationTestUtil#parseData(String)}.
     */
    @SmallTest
    public void testCorrectMessageParsing() {
        {
            // Test empty input.
            String input = "";
            ByteBuffer expected = ByteBuffer.allocateDirect(0);
            expected.order(ByteOrder.LITTLE_ENDIAN);

            checkInputParser(input, true, expected, 0);
        }
        {
            // Test input that only consists of comments and whitespaces.
            String input = "    \t  // hello world \n\r \t// the answer is 42   ";
            ByteBuffer expected = ByteBuffer.allocateDirect(0);
            expected.order(ByteOrder.nativeOrder());

            checkInputParser(input, true, expected, 0);
        }
        {
            String input = "[u1]0x10// hello world !! \n\r  \t [u2]65535 \n"
                    + "[u4]65536 [u8]0xFFFFFFFFFFFFFFFF 0 0Xff";
            ByteBuffer expected = ByteBuffer.allocateDirect(17);
            expected.order(ByteOrder.nativeOrder());
            expected.put((byte) 0x10);
            expected.putShort((short) 65535);
            expected.putInt(65536);
            expected.putLong(-1);
            expected.put((byte) 0);
            expected.put((byte) 0xff);
            expected.flip();

            checkInputParser(input, true, expected, 0);
        }
        {
            String input = "[s8]-0x800 [s1]-128\t[s2]+0 [s4]-40";
            ByteBuffer expected = ByteBuffer.allocateDirect(15);
            expected.order(ByteOrder.nativeOrder());
            expected.putLong(-0x800);
            expected.put((byte) -128);
            expected.putShort((short) 0);
            expected.putInt(-40);
            expected.flip();

            checkInputParser(input, true, expected, 0);
        }
        {
            String input = "[b]00001011 [b]10000000  // hello world\r [b]00000000";
            ByteBuffer expected = ByteBuffer.allocateDirect(3);
            expected.order(ByteOrder.nativeOrder());
            expected.put((byte) 11);
            expected.put((byte) 128);
            expected.put((byte) 0);
            expected.flip();

            checkInputParser(input, true, expected, 0);
        }
        {
            String input = "[f]+.3e9 [d]-10.03";
            ByteBuffer expected = ByteBuffer.allocateDirect(12);
            expected.order(ByteOrder.nativeOrder());
            expected.putFloat(+.3e9f);
            expected.putDouble(-10.03);
            expected.flip();

            checkInputParser(input, true, expected, 0);
        }
        {
            String input = "[dist4]foo 0 [dist8]bar 0 [anchr]foo [anchr]bar";
            ByteBuffer expected = ByteBuffer.allocateDirect(14);
            expected.order(ByteOrder.nativeOrder());
            expected.putInt(14);
            expected.put((byte) 0);
            expected.putLong(9);
            expected.put((byte) 0);
            expected.flip();

            checkInputParser(input, true, expected, 0);
        }
        {
            String input = "// This message has handles! \n[handles]50 [u8]2";
            ByteBuffer expected = ByteBuffer.allocateDirect(8);
            expected.order(ByteOrder.nativeOrder());
            expected.putLong(2);
            expected.flip();

            checkInputParser(input, true, expected, 50);
        }

        // Test some failure cases.
        {
            String error_inputs[] = {
                "/ hello world",
                "[u1]x",
                "[u2]-1000",
                "[u1]0x100",
                "[s2]-0x8001",
                "[b]1",
                "[b]1111111k",
                "[dist4]unmatched",
                "[anchr]hello [dist8]hello",
                "[dist4]a [dist4]a [anchr]a",
                "[dist4]a [anchr]a [dist4]a [anchr]a",
                "0 [handles]50"
            };

            for (String input : error_inputs) {
                ByteBuffer expected = ByteBuffer.allocateDirect(0);
                expected.order(ByteOrder.nativeOrder());
                checkInputParser(input, false, expected, 0);
            }
        }

    }
}
