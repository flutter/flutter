// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.bindings;

import android.test.suitebuilder.annotation.SmallTest;

import org.chromium.mojo.MojoTestCase;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojo.system.impl.CoreImpl;
import org.chromium.mojom.mojo.test.AnEnum;
import org.chromium.mojom.mojo.test.DummyStruct;
import org.chromium.mojom.mojo.test.HandleUnion;
import org.chromium.mojom.mojo.test.ObjectUnion;
import org.chromium.mojom.mojo.test.PodUnion;
import org.chromium.mojom.mojo.test.SmallCache;
import org.chromium.mojom.mojo.test.SmallObjStruct;
import org.chromium.mojom.mojo.test.SmallStruct;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

/**
 * Testing union generation. Generated classes are defined in
 * mojo/public/interfaces/bindings/tests/test_unions.mojom
 */
public class UnionTest extends MojoTestCase {
    private static class SmallCacheImpl implements SmallCache {
        private long mValue = 0;

        public long getValue() {
            return mValue;
        }

        /**
         * @see Interface#close()
         */
        @Override
        public void close() {}

        /**
         * @see ConnectionErrorHandler#onConnectionError(MojoException)
         */
        @Override
        public void onConnectionError(MojoException e) {}

        /**
         * @see SmallCache#setIntValue(long)
         */
        @Override
        public void setIntValue(long intValue) {
            mValue = intValue;
        }

        /**
         * @see SmallCache#getIntValue(SmallCache.GetIntValueResponse)
         */
        @Override
        public void getIntValue(GetIntValueResponse callback) {
            callback.call(mValue);
        }
    }

    @SmallTest
    public void testTagGeneration() {
        // Check that all tags are different.
        Set<Integer> tags = new HashSet<>();
        tags.add(PodUnion.Tag.FInt8);
        tags.add(PodUnion.Tag.FInt8Other);
        tags.add(PodUnion.Tag.FUint8);
        tags.add(PodUnion.Tag.FInt16);
        tags.add(PodUnion.Tag.FUint16);
        tags.add(PodUnion.Tag.FInt32);
        tags.add(PodUnion.Tag.FUint32);
        tags.add(PodUnion.Tag.FInt64);
        tags.add(PodUnion.Tag.FUint64);
        tags.add(PodUnion.Tag.FFloat);
        tags.add(PodUnion.Tag.FDouble);
        tags.add(PodUnion.Tag.FBool);
        tags.add(PodUnion.Tag.FEnum);
        assertEquals(13, tags.size());
    }

    @SmallTest
    public void testPlainOldDataGetterSetter() {
        PodUnion pod = new PodUnion();

        pod.setFInt8((byte) 10);
        assertEquals((byte) 10, pod.getFInt8());
        assertEquals(PodUnion.Tag.FInt8, pod.which());

        pod.setFUint8((byte) 11);
        assertEquals((byte) 11, pod.getFUint8());
        assertEquals(PodUnion.Tag.FUint8, pod.which());

        pod.setFInt16((short) 12);
        assertEquals((short) 12, pod.getFInt16());
        assertEquals(PodUnion.Tag.FInt16, pod.which());

        pod.setFUint16((short) 13);
        assertEquals((short) 13, pod.getFUint16());
        assertEquals(PodUnion.Tag.FUint16, pod.which());

        pod.setFInt32(14);
        assertEquals(14, pod.getFInt32());
        assertEquals(PodUnion.Tag.FInt32, pod.which());

        pod.setFUint32(15);
        assertEquals(15, pod.getFUint32());
        assertEquals(PodUnion.Tag.FUint32, pod.which());

        pod.setFInt64(16);
        assertEquals(16, pod.getFInt64());
        assertEquals(PodUnion.Tag.FInt64, pod.which());

        pod.setFUint64(17);
        assertEquals(17, pod.getFUint64());
        assertEquals(PodUnion.Tag.FUint64, pod.which());

        pod.setFFloat(1.5f);
        assertEquals(1.5f, pod.getFFloat());
        assertEquals(PodUnion.Tag.FFloat, pod.which());

        pod.setFDouble(1.9);
        assertEquals(1.9, pod.getFDouble());
        assertEquals(PodUnion.Tag.FDouble, pod.which());

        pod.setFBool(true);
        assertTrue(pod.getFBool());
        pod.setFBool(false);
        assertFalse(pod.getFBool());
        assertEquals(PodUnion.Tag.FBool, pod.which());

        pod.setFEnum(AnEnum.SECOND);
        assertEquals(AnEnum.SECOND, pod.getFEnum());
        assertEquals(PodUnion.Tag.FEnum, pod.which());
    }

    @SmallTest
    public void testEquals() {
        PodUnion pod1 = new PodUnion();
        PodUnion pod2 = new PodUnion();

        pod1.setFInt8((byte) 10);
        pod2.setFInt8((byte) 10);
        assertEquals(pod1, pod2);

        pod2.setFInt8((byte) 11);
        assertFalse(pod1.equals(pod2));

        pod2.setFInt8Other((byte) 10);
        assertFalse(pod1.equals(pod2));
    }

    @SmallTest
    public void testPodSerialization() {
        PodUnion pod1 = new PodUnion();
        pod1.setFInt8((byte) 10);

        PodUnion pod2 = PodUnion.deserialize(pod1.serialize(CoreImpl.getInstance()));

        assertEquals(pod1, pod2);
    }

    @SmallTest
    public void testUnknownSerialization() {
        PodUnion pod1 = new PodUnion();

        PodUnion pod2 = PodUnion.deserialize(pod1.serialize(CoreImpl.getInstance()));

        assertTrue(pod2.isUnknown());
    }

    @SmallTest
    public void testEnumSerialization() {
        PodUnion pod1 = new PodUnion();
        pod1.setFEnum(AnEnum.SECOND);

        PodUnion pod2 = PodUnion.deserialize(pod1.serialize(CoreImpl.getInstance()));

        assertEquals(pod1, pod2);
    }

    @SmallTest
    public void testStringGetterSetter() {
        ObjectUnion ou = new ObjectUnion();
        ou.setFString("hello world");

        assertEquals("hello world", ou.getFString());
        assertEquals(ObjectUnion.Tag.FString, ou.which());
    }

    @SmallTest
    public void testStringEquals() {
        ObjectUnion ou1 = new ObjectUnion();
        ObjectUnion ou2 = new ObjectUnion();

        ou1.setFString("hello world");
        ou2.setFString("hello world");
        assertEquals(ou1, ou2);

        ou2.setFString("hello universe");
        assertFalse(ou1.equals(ou2));
    }

    @SmallTest
    public void testStringSerialization() {
        ObjectUnion ou1 = new ObjectUnion();
        ou1.setFString("hello world");

        ObjectUnion ou2 = ObjectUnion.deserialize(ou1.serialize(CoreImpl.getInstance()));

        assertEquals(ou1, ou2);
    }

    @SmallTest
    public void testPodUnionInArraySerialization() {
        SmallStruct ss1 = new SmallStruct();
        ss1.podUnionArray = new PodUnion[2];

        ss1.podUnionArray[0] = new PodUnion();
        ss1.podUnionArray[0].setFInt8((byte) 10);

        ss1.podUnionArray[1] = new PodUnion();
        ss1.podUnionArray[1].setFInt16((short) 12);

        SmallStruct ss2 = SmallStruct.deserialize(ss1.serialize(null));

        assertEquals(ss1, ss2);
        assertTrue(java.util.Arrays.deepEquals(ss1.podUnionArray, ss2.podUnionArray));
    }

    @SmallTest
    public void testPodUnionInArraySerializationWithNull() {
        SmallStruct ss1 = new SmallStruct();
        ss1.nullablePodUnionArray = new PodUnion[2];

        ss1.nullablePodUnionArray[0] = new PodUnion();
        ss1.nullablePodUnionArray[0].setFInt8((byte) 10);

        ss1.nullablePodUnionArray[1] = null;

        SmallStruct ss2 = SmallStruct.deserialize(ss1.serialize(null));

        assertEquals(ss1, ss2);
        assertTrue(
                java.util.Arrays.deepEquals(ss1.nullablePodUnionArray, ss2.nullablePodUnionArray));
    }

    @SmallTest
    public void testSerializationUnionOfPods() {
        SmallStruct ss1 = new SmallStruct();
        ss1.podUnion = new PodUnion();
        ss1.podUnion.setFInt32(10);

        SmallStruct ss2 = SmallStruct.deserialize(ss1.serialize(null));

        assertEquals(ss1, ss2);
        assertEquals(ss1.podUnion, ss2.podUnion);
    }

    @SmallTest
    public void testSerializationUnionOfObjects() {
        SmallObjStruct sos1 = new SmallObjStruct();
        sos1.objUnion = new ObjectUnion();
        sos1.objUnion.setFString("hello world");

        SmallObjStruct sos2 = SmallObjStruct.deserialize(sos1.serialize(null));

        assertEquals(sos1, sos2);
        assertEquals(sos1.objUnion, sos2.objUnion);
    }

    @SmallTest
    public void testSerializationPodUnionInMap() {
        SmallStruct ss1 = new SmallStruct();
        ss1.podUnionMap = new HashMap<>();
        ss1.podUnionMap.put("one", new PodUnion());
        ss1.podUnionMap.get("one").setFInt8((byte) 8);
        ss1.podUnionMap.put("two", new PodUnion());
        ss1.podUnionMap.get("two").setFInt16((short) 16);

        SmallStruct ss2 = SmallStruct.deserialize(ss1.serialize(null));

        assertEquals(ss1, ss2);
        assertEquals(ss1.podUnionMap, ss2.podUnionMap);
    }

    @SmallTest
    public void testSerializationPodUnionInMapWithNull() {
        SmallStruct ss1 = new SmallStruct();
        ss1.nullablePodUnionMap = new HashMap<>();
        ss1.nullablePodUnionMap.put("one", new PodUnion());
        ss1.nullablePodUnionMap.get("one").setFInt8((byte) 8);
        ss1.nullablePodUnionMap.put("two", null);

        SmallStruct ss2 = SmallStruct.deserialize(ss1.serialize(null));

        assertEquals(ss1, ss2);
        assertEquals(ss1.nullablePodUnionMap, ss2.nullablePodUnionMap);
    }

    @SmallTest
    public void testStructInUnionSerialization() {
        DummyStruct ds = new DummyStruct();
        ds.fInt8 = 8;

        ObjectUnion os1 = new ObjectUnion();
        os1.setFDummy(ds);

        ObjectUnion os2 = ObjectUnion.deserialize(os1.serialize(null));

        assertEquals(os1, os2);
    }

    @SmallTest
    public void testArrayInUnionSerialization() {
        byte[] array = new byte[2];
        array[0] = 8;
        array[1] = 9;

        ObjectUnion os1 = new ObjectUnion();
        os1.setFArrayInt8(array);

        ObjectUnion os2 = ObjectUnion.deserialize(os1.serialize(null));

        assertEquals(os1, os2);
    }

    @SmallTest
    public void testMapInUnionSerialization() {
        Map<String, Byte> map = new HashMap<>();
        map.put("one", (byte) 1);
        map.put("two", (byte) 2);

        ObjectUnion os1 = new ObjectUnion();
        os1.setFMapInt8(map);

        ObjectUnion os2 = ObjectUnion.deserialize(os1.serialize(null));

        assertEquals(os1, os2);
    }

    @SmallTest
    public void testUnionInUnionSerialization() {
        PodUnion pod = new PodUnion();
        pod.setFInt8((byte) 10);

        ObjectUnion os1 = new ObjectUnion();
        os1.setFPodUnion(pod);

        ObjectUnion os2 = ObjectUnion.deserialize(os1.serialize(null));

        assertEquals(os1, os2);
    }

    @SmallTest
    public void testInterfaceInUnionSerialization() {
        SmallCacheImpl sc = new SmallCacheImpl();
        HandleUnion hu1 = new HandleUnion();
        hu1.setFSmallCache(sc);

        HandleUnion hu2 = HandleUnion.deserialize(hu1.serialize(CoreImpl.getInstance()));

        hu2.getFSmallCache().setIntValue(10);
        runLoopUntilIdle();
        assertEquals(10L, sc.getValue());

        // Cleanup
        hu2.getFSmallCache().close();
        runLoopUntilIdle();
    }
}
