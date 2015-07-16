// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

import android.test.InstrumentationTestCase;
import android.test.suitebuilder.annotation.SmallTest;

import org.chromium.base.test.util.Feature;

public class CommandLineTest extends InstrumentationTestCase {
    // A reference command line. Note that switch2 is [brea\d], switch3 is [and "butter"],
    // and switch4 is [a "quoted" 'food'!]
    static final String INIT_SWITCHES[] = { "init_command", "--SWITCH", "Arg",
        "--switch2=brea\\d", "--switch3=and \"butter\"",
        "--switch4=a \"quoted\" 'food'!",
        "--", "--actually_an_arg" };

    // The same command line, but in quoted string format.
    static final char INIT_SWITCHES_BUFFER[] =
        ("init_command --SWITCH Arg --switch2=brea\\d --switch3=\"and \\\"butt\"er\\\"   "
        + "--switch4='a \"quoted\" \\'food\\'!' "
        + "-- --actually_an_arg").toCharArray();

    static final String CL_ADDED_SWITCH = "zappo-dappo-doggy-trainer";
    static final String CL_ADDED_SWITCH_2 = "username";
    static final String CL_ADDED_VALUE_2 = "bozo";

    @Override
    public void setUp() throws Exception {
        CommandLine.reset();
    }

    void checkInitSwitches() {
        CommandLine cl = CommandLine.getInstance();
        assertFalse(cl.hasSwitch("init_command"));
        assertFalse(cl.hasSwitch("switch"));
        assertTrue(cl.hasSwitch("SWITCH"));
        assertFalse(cl.hasSwitch("--SWITCH"));
        assertFalse(cl.hasSwitch("Arg"));
        assertFalse(cl.hasSwitch("actually_an_arg"));
        assertEquals("brea\\d", cl.getSwitchValue("switch2"));
        assertEquals("and \"butter\"", cl.getSwitchValue("switch3"));
        assertEquals("a \"quoted\" 'food'!", cl.getSwitchValue("switch4"));
        assertNull(cl.getSwitchValue("SWITCH"));
        assertNull(cl.getSwitchValue("non-existant"));
    }

    void checkSettingThenGetting() {
        CommandLine cl = CommandLine.getInstance();

        // Add a plain switch.
        assertFalse(cl.hasSwitch(CL_ADDED_SWITCH));
        cl.appendSwitch(CL_ADDED_SWITCH);
        assertTrue(cl.hasSwitch(CL_ADDED_SWITCH));

        // Add a switch paired with a value.
        assertFalse(cl.hasSwitch(CL_ADDED_SWITCH_2));
        assertNull(cl.getSwitchValue(CL_ADDED_SWITCH_2));
        cl.appendSwitchWithValue(CL_ADDED_SWITCH_2, CL_ADDED_VALUE_2);
        assertTrue(CL_ADDED_VALUE_2.equals(cl.getSwitchValue(CL_ADDED_SWITCH_2)));

        // Append a few new things.
        final String switchesAndArgs[] = { "dummy", "--superfast", "--speed=turbo" };
        assertFalse(cl.hasSwitch("dummy"));
        assertFalse(cl.hasSwitch("superfast"));
        assertNull(cl.getSwitchValue("speed"));
        cl.appendSwitchesAndArguments(switchesAndArgs);
        assertFalse(cl.hasSwitch("dummy"));
        assertFalse(cl.hasSwitch("command"));
        assertTrue(cl.hasSwitch("superfast"));
        assertTrue("turbo".equals(cl.getSwitchValue("speed")));
    }

    void checkTokenizer(String[] expected, String toParse) {
        String[] actual = CommandLine.tokenizeQuotedAruments(toParse.toCharArray());
        assertEquals(expected.length, actual.length);
        for (int i = 0; i < expected.length; ++i) {
            assertEquals("comparing element " + i, expected[i], actual[i]);
        }
    }

    @SmallTest
    @Feature({"Android-AppBase"})
    public void testJavaInitialization() {
        CommandLine.init(INIT_SWITCHES);
        checkInitSwitches();
        checkSettingThenGetting();
    }

    @SmallTest
    @Feature({"Android-AppBase"})
    public void testBufferInitialization() {
        CommandLine.init(CommandLine.tokenizeQuotedAruments(INIT_SWITCHES_BUFFER));
        checkInitSwitches();
        checkSettingThenGetting();
    }

    @SmallTest
    @Feature({"Android-AppBase"})
    public void testArgumentTokenizer() {
        String toParse = " a\"\\bc de\\\"f g\"\\h ij    k\" \"lm";
        String[] expected = { "a\\bc de\"f g\\h",
                              "ij",
                              "k lm" };
        checkTokenizer(expected, toParse);

        toParse = "";
        expected = new String[0];
        checkTokenizer(expected, toParse);

        toParse = " \t\n";
        checkTokenizer(expected, toParse);

        toParse = " \"a'b\" 'c\"d' \"e\\\"f\" 'g\\'h' \"i\\'j\" 'k\\\"l'"
                + " m\"n\\'o\"p q'r\\\"s't";
        expected = new String[] { "a'b",
                                  "c\"d",
                                  "e\"f",
                                  "g'h",
                                  "i\\'j",
                                  "k\\\"l",
                                  "mn\\'op",
                                  "qr\\\"st"};
        checkTokenizer(expected, toParse);
    }
}
