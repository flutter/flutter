// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.bindings;

import android.test.suitebuilder.annotation.SmallTest;

import org.chromium.mojo.MojoTestCase;
import org.chromium.mojo.bindings.test.mojom.test_structs.MultiVersionStruct;
import org.chromium.mojo.bindings.test.mojom.test_structs.MultiVersionStructV0;
import org.chromium.mojo.bindings.test.mojom.test_structs.MultiVersionStructV1;
import org.chromium.mojo.bindings.test.mojom.test_structs.MultiVersionStructV3;
import org.chromium.mojo.bindings.test.mojom.test_structs.MultiVersionStructV5;
import org.chromium.mojo.bindings.test.mojom.test_structs.MultiVersionStructV7;
import org.chromium.mojo.bindings.test.mojom.test_structs.Rect;
import org.chromium.mojo.system.impl.CoreImpl;

/**
 * Testing generated classes with the [MinVersion] annotation. Struct in this test are from:
 * mojo/public/interfaces/bindings/tests/rect.mojom and
 * mojo/public/interfaces/bindings/tests/test_structs.mojom
 */
public class BindingsVersioningTest extends MojoTestCase {
    private static Rect newRect(int factor) {
        Rect rect = new Rect();
        rect.x = factor;
        rect.y = 2 * factor;
        rect.width = 10 * factor;
        rect.height = 20 * factor;
        return rect;
    }

    private static MultiVersionStruct newStruct() {
        MultiVersionStruct struct = new MultiVersionStruct();
        struct.fInt32 = 123;
        struct.fRect = newRect(5);
        struct.fString = "hello";
        struct.fArray = new byte[] {10, 9, 8};
        struct.fBool = true;
        struct.fInt16 = 256;
        return struct;
    }

    /**
     * Testing serializing old struct version to newer one.
     */
    @SmallTest
    public void testOldToNew() {
        {
            MultiVersionStructV0 v0 = new MultiVersionStructV0();
            v0.fInt32 = 123;
            MultiVersionStruct expected = new MultiVersionStruct();
            expected.fInt32 = 123;

            MultiVersionStruct output = MultiVersionStruct.deserialize(v0.serialize(null));
            assertEquals(expected, output);
            assertEquals(0, v0.getVersion());
            assertEquals(0, output.getVersion());
        }

        {
            MultiVersionStructV1 v1 = new MultiVersionStructV1();
            v1.fInt32 = 123;
            v1.fRect = newRect(5);
            MultiVersionStruct expected = new MultiVersionStruct();
            expected.fInt32 = 123;
            expected.fRect = newRect(5);

            MultiVersionStruct output = MultiVersionStruct.deserialize(v1.serialize(null));
            assertEquals(expected, output);
            assertEquals(1, v1.getVersion());
            assertEquals(1, output.getVersion());
        }

        {
            MultiVersionStructV3 v3 = new MultiVersionStructV3();
            v3.fInt32 = 123;
            v3.fRect = newRect(5);
            v3.fString = "hello";
            MultiVersionStruct expected = new MultiVersionStruct();
            expected.fInt32 = 123;
            expected.fRect = newRect(5);
            expected.fString = "hello";

            MultiVersionStruct output = MultiVersionStruct.deserialize(v3.serialize(null));
            assertEquals(expected, output);
            assertEquals(3, v3.getVersion());
            assertEquals(3, output.getVersion());
        }

        {
            MultiVersionStructV5 v5 = new MultiVersionStructV5();
            v5.fInt32 = 123;
            v5.fRect = newRect(5);
            v5.fString = "hello";
            v5.fArray = new byte[] {10, 9, 8};
            MultiVersionStruct expected = new MultiVersionStruct();
            expected.fInt32 = 123;
            expected.fRect = newRect(5);
            expected.fString = "hello";
            expected.fArray = new byte[] {10, 9, 8};

            MultiVersionStruct output = MultiVersionStruct.deserialize(v5.serialize(null));
            assertEquals(expected, output);
            assertEquals(5, v5.getVersion());
            assertEquals(5, output.getVersion());
        }

        {
            int expectedHandle = 42;
            MultiVersionStructV7 v7 = new MultiVersionStructV7();
            v7.fInt32 = 123;
            v7.fRect = newRect(5);
            v7.fString = "hello";
            v7.fArray = new byte[] {10, 9, 8};
            v7.fMessagePipe = CoreImpl.getInstance()
                                      .acquireNativeHandle(expectedHandle)
                                      .toMessagePipeHandle();
            v7.fBool = true;
            MultiVersionStruct expected = new MultiVersionStruct();
            expected.fInt32 = 123;
            expected.fRect = newRect(5);
            expected.fString = "hello";
            expected.fArray = new byte[] {10, 9, 8};
            expected.fBool = true;

            MultiVersionStruct output = MultiVersionStruct.deserialize(v7.serialize(null));

            // Handles must be tested separately.
            assertEquals(expectedHandle, output.fMessagePipe.releaseNativeHandle());
            output.fMessagePipe = expected.fMessagePipe;

            assertEquals(expected, output);
            assertEquals(7, v7.getVersion());
            assertEquals(7, output.getVersion());
        }
    }

    /**
     * Testing serializing new struct version to older one.
     */
    @SmallTest
    public void testNewToOld() {
        MultiVersionStruct struct = newStruct();
        {
            MultiVersionStructV0 expected = new MultiVersionStructV0();
            expected.fInt32 = 123;

            MultiVersionStructV0 output = MultiVersionStructV0.deserialize(struct.serialize(null));
            assertEquals(expected, output);
            assertEquals(9, output.getVersion());
        }

        {
            MultiVersionStructV1 expected = new MultiVersionStructV1();
            expected.fInt32 = 123;
            expected.fRect = newRect(5);

            MultiVersionStructV1 output = MultiVersionStructV1.deserialize(struct.serialize(null));
            assertEquals(expected, output);
            assertEquals(9, output.getVersion());
        }

        {
            MultiVersionStructV3 expected = new MultiVersionStructV3();
            expected.fInt32 = 123;
            expected.fRect = newRect(5);
            expected.fString = "hello";

            MultiVersionStructV3 output = MultiVersionStructV3.deserialize(struct.serialize(null));
            assertEquals(expected, output);
            assertEquals(9, output.getVersion());
        }

        {
            MultiVersionStructV5 expected = new MultiVersionStructV5();
            expected.fInt32 = 123;
            expected.fRect = newRect(5);
            expected.fString = "hello";
            expected.fArray = new byte[] {10, 9, 8};

            MultiVersionStructV5 output = MultiVersionStructV5.deserialize(struct.serialize(null));
            assertEquals(expected, output);
            assertEquals(9, output.getVersion());
        }

        {
            int expectedHandle = 42;
            MultiVersionStructV7 expected = new MultiVersionStructV7();
            expected.fInt32 = 123;
            expected.fRect = newRect(5);
            expected.fString = "hello";
            expected.fArray = new byte[] {10, 9, 8};
            expected.fBool = true;

            MultiVersionStruct input = struct;
            input.fMessagePipe = CoreImpl.getInstance()
                                         .acquireNativeHandle(expectedHandle)
                                         .toMessagePipeHandle();

            MultiVersionStructV7 output = MultiVersionStructV7.deserialize(input.serialize(null));

            assertEquals(expectedHandle, output.fMessagePipe.releaseNativeHandle());
            output.fMessagePipe = expected.fMessagePipe;

            assertEquals(expected, output);
            assertEquals(9, output.getVersion());
        }
    }
}
