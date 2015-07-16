// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.bindings;

import android.test.suitebuilder.annotation.SmallTest;

import junit.framework.TestCase;

import org.chromium.mojo.HandleMock;
import org.chromium.mojo.bindings.test.mojom.mojo.Struct1;
import org.chromium.mojo.bindings.test.mojom.mojo.Struct2;
import org.chromium.mojo.bindings.test.mojom.mojo.Struct3;
import org.chromium.mojo.bindings.test.mojom.mojo.Struct4;
import org.chromium.mojo.bindings.test.mojom.mojo.Struct5;
import org.chromium.mojo.bindings.test.mojom.mojo.Struct6;
import org.chromium.mojo.bindings.test.mojom.mojo.StructOfNullables;

/**
 * Tests for the serialization logic of the generated structs, using structs defined in
 * mojo/public/interfaces/bindings/tests/serialization_test_structs.mojom .
 */
public class SerializationTest extends TestCase {

    private static void assertThrowsSerializationException(Struct struct) {
        try {
            struct.serialize(null);
            fail("Serialization of invalid struct should have thrown an exception.");
        } catch (SerializationException ex) {
            // Expected.
        }
    }

    /**
     * Verifies that serializing a struct with an invalid handle of a non-nullable type throws an
     * exception.
     */
    @SmallTest
    public void testHandle() {
        Struct2 struct = new Struct2();
        assertFalse(struct.hdl.isValid());
        assertThrowsSerializationException(struct);

        // Make the struct valid and verify that it serializes without an exception.
        struct.hdl = new HandleMock();
        struct.serialize(null);
    }

    /**
     * Verifies that serializing a struct with a null struct pointer throws an exception.
     */
    @SmallTest
    public void testStructPointer() {
        Struct3 struct = new Struct3();
        assertNull(struct.struct1);
        assertThrowsSerializationException(struct);

        // Make the struct valid and verify that it serializes without an exception.
        struct.struct1 = new Struct1();
        struct.serialize(null);
    }

    /**
     * Verifies that serializing a struct with an array of structs throws an exception when the
     * struct is invalid.
     */
    @SmallTest
    public void testStructArray() {
        Struct4 struct = new Struct4();
        assertNull(struct.data);
        assertThrowsSerializationException(struct);

        // Create the (1-element) array but have the element null.
        struct.data = new Struct1[1];
        assertThrowsSerializationException(struct);

        // Create the array element, struct should serialize now.
        struct.data[0] = new Struct1();
        struct.serialize(null);
    }

    /**
     * Verifies that serializing a struct with a fixed-size array of incorrect length throws an
     * exception.
     */
    @SmallTest
    public void testFixedSizeArray() {
        Struct5 struct = new Struct5();
        assertNull(struct.pair);
        assertThrowsSerializationException(struct);

        // Create the (1-element) array, 2-element array is required.
        struct.pair = new Struct1[1];
        struct.pair[0] = new Struct1();
        assertThrowsSerializationException(struct);

        // Create the array of a correct size, struct should serialize now.
        struct.pair = new Struct1[2];
        struct.pair[0] = new Struct1();
        struct.pair[1] = new Struct1();
        struct.serialize(null);
    }

    /**
     * Verifies that serializing a struct with a null string throws an exception.
     */
    @SmallTest
    public void testString() {
        Struct6 struct = new Struct6();
        assertNull(struct.str);
        assertThrowsSerializationException(struct);

        // Make the struct valid and verify that it serializes without an exception.
        struct.str = "";
        struct.serialize(null);
    }

    /**
     * Verifies that a struct with an invalid nullable handle, null nullable struct pointer and null
     * nullable string serializes without an exception.
     */
    @SmallTest
    public void testNullableFields() {
        StructOfNullables struct = new StructOfNullables();
        assertFalse(struct.hdl.isValid());
        assertNull(struct.struct1);
        assertNull(struct.str);
        struct.serialize(null);
    }
}
