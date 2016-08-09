// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.testing.local;

import org.junit.Assert;
import org.junit.Test;
import org.junit.runner.Description;
import org.junit.runner.RunWith;
import org.junit.runner.manipulation.Filter;
import org.junit.runners.BlockJUnit4ClassRunner;

/**
 *  Unit tests for GtestFilter.
 */
@RunWith(BlockJUnit4ClassRunner.class)
public class GtestFilterTest {

    private class TestClass {}
    private class OtherTestClass {}

    @Test
    public void testDescription() {
        Filter filterUnderTest = new GtestFilter(TestClass.class.getName() + ".*");
        Assert.assertEquals("gtest-filter: " + TestClass.class.getName() + ".*",
                filterUnderTest.describe());
    }

    @Test
    public void testNoFilter() {
        Filter filterUnderTest = new GtestFilter("");
        Assert.assertTrue(filterUnderTest.shouldRun(
                Description.createTestDescription(TestClass.class, "testMethod")));
        Assert.assertTrue(filterUnderTest.shouldRun(
                Description.createTestDescription(TestClass.class, "otherTestMethod")));
        Assert.assertTrue(filterUnderTest.shouldRun(
                Description.createTestDescription(OtherTestClass.class, "testMethod")));
    }

    @Test
    public void testPositiveFilterExplicit() {
        Filter filterUnderTest = new GtestFilter(TestClass.class.getName() + ".testMethod");
        Assert.assertTrue(filterUnderTest.shouldRun(
                Description.createTestDescription(TestClass.class, "testMethod")));
        Assert.assertFalse(filterUnderTest.shouldRun(
                Description.createTestDescription(TestClass.class, "otherTestMethod")));
        Assert.assertFalse(filterUnderTest.shouldRun(
                Description.createTestDescription(OtherTestClass.class, "testMethod")));
    }

    @Test
    public void testPositiveFilterClassRegex() {
        Filter filterUnderTest = new GtestFilter(TestClass.class.getName() + ".*");
        Assert.assertTrue(filterUnderTest.shouldRun(
                Description.createTestDescription(TestClass.class, "testMethod")));
        Assert.assertTrue(filterUnderTest.shouldRun(
                Description.createTestDescription(TestClass.class, "otherTestMethod")));
        Assert.assertFalse(filterUnderTest.shouldRun(
                Description.createTestDescription(OtherTestClass.class, "testMethod")));
    }

    @Test
    public void testNegativeFilterExplicit() {
        Filter filterUnderTest = new GtestFilter("-" + TestClass.class.getName() + ".testMethod");
        Assert.assertFalse(filterUnderTest.shouldRun(
                Description.createTestDescription(TestClass.class, "testMethod")));
        Assert.assertTrue(filterUnderTest.shouldRun(
                Description.createTestDescription(TestClass.class, "otherTestMethod")));
        Assert.assertTrue(filterUnderTest.shouldRun(
                Description.createTestDescription(OtherTestClass.class, "testMethod")));
    }

    @Test
    public void testNegativeFilterClassRegex() {
        Filter filterUnderTest = new GtestFilter("-" + TestClass.class.getName() + ".*");
        Assert.assertFalse(filterUnderTest.shouldRun(
                Description.createTestDescription(TestClass.class, "testMethod")));
        Assert.assertFalse(filterUnderTest.shouldRun(
                Description.createTestDescription(TestClass.class, "otherTestMethod")));
        Assert.assertTrue(filterUnderTest.shouldRun(
                Description.createTestDescription(OtherTestClass.class, "testMethod")));
    }

    @Test
    public void testPositiveAndNegativeFilter() {
        Filter filterUnderTest = new GtestFilter(TestClass.class.getName() + ".*"
                + "-" + TestClass.class.getName() + ".testMethod");
        Assert.assertFalse(filterUnderTest.shouldRun(
                Description.createTestDescription(TestClass.class, "testMethod")));
        Assert.assertTrue(filterUnderTest.shouldRun(
                Description.createTestDescription(TestClass.class, "otherTestMethod")));
        Assert.assertFalse(filterUnderTest.shouldRun(
                Description.createTestDescription(OtherTestClass.class, "testMethod")));
    }

    @Test
    public void testMultiplePositiveFilters() {
        Filter filterUnderTest = new GtestFilter(
                TestClass.class.getName() + ".otherTestMethod:"
                + OtherTestClass.class.getName() + ".otherTestMethod");
        Assert.assertFalse(filterUnderTest.shouldRun(
                Description.createTestDescription(TestClass.class, "testMethod")));
        Assert.assertTrue(filterUnderTest.shouldRun(
                Description.createTestDescription(TestClass.class, "otherTestMethod")));
        Assert.assertFalse(filterUnderTest.shouldRun(
                Description.createTestDescription(OtherTestClass.class, "testMethod")));
        Assert.assertTrue(filterUnderTest.shouldRun(
                Description.createTestDescription(OtherTestClass.class, "otherTestMethod")));
    }

    @Test
    public void testMultipleFiltersPositiveAndNegative() {
        Filter filterUnderTest = new GtestFilter(TestClass.class.getName() + ".*:"
                + "-" + TestClass.class.getName() + ".testMethod");
        Assert.assertFalse(filterUnderTest.shouldRun(
                Description.createTestDescription(TestClass.class, "testMethod")));
        Assert.assertTrue(filterUnderTest.shouldRun(
                Description.createTestDescription(TestClass.class, "otherTestMethod")));
        Assert.assertFalse(filterUnderTest.shouldRun(
                Description.createTestDescription(OtherTestClass.class, "testMethod")));
    }
}

