package com.tekartik.sqflite;

import static org.junit.Assert.assertEquals;

import org.junit.Test;

/**
 * Constants between dart & Java world
 */

public class ConstantTest {

    @Test
    public void key() {
        assertEquals("com.tekartik.sqflite", Constant.PLUGIN_KEY);
    }
}
