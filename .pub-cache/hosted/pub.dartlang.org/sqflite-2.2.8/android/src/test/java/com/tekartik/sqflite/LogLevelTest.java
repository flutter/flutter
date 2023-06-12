package com.tekartik.sqflite;

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

/**
 * Constants between dart & Java world
 */

public class LogLevelTest {


    @Test
    public void hasSqlLogLevel() {
        assertTrue(LogLevel.hasSqlLevel(1));
        assertFalse(LogLevel.hasSqlLevel(0));
    }
}
