// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.bindings;

import android.test.suitebuilder.annotation.SmallTest;
import android.util.Log;

import org.chromium.base.test.util.UrlUtils;
import org.chromium.mojo.HandleMock;
import org.chromium.mojo.MojoTestCase;
import org.chromium.mojo.bindings.test.mojom.mojo.ConformanceTestInterface;
import org.chromium.mojo.bindings.test.mojom.mojo.IntegrationTestInterface;
import org.chromium.mojo.bindings.test.mojom.mojo.IntegrationTestInterfaceTestHelper;
import org.chromium.mojo.system.Handle;

import java.io.File;
import java.io.FileFilter;
import java.io.FileNotFoundException;
import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

/**
 * Testing validation upon deserialization using the interfaces defined in the
 * mojo/public/interfaces/bindings/tests/validation_test_interfaces.mojom file.
 * <p>
 * One needs to pass '--test_data=bindings:{path to mojo/public/interfaces/bindings/tests/data}' to
 * the test_runner script for this test to find the validation data it needs.
 */
public class ValidationTest extends MojoTestCase {

    /**
     * The path where validation test data is.
     */
    private static final File VALIDATION_TEST_DATA_PATH =
            new File(UrlUtils.getTestFilePath("bindings/validation"));

    /**
     * The data needed for a validation test.
     */
    private static class TestData {
        public File dataFile;
        public ValidationTestUtil.Data inputData;
        public String expectedResult;
    }

    private static class DataFileFilter implements FileFilter {
        private final String mPrefix;

        public DataFileFilter(String prefix) {
            this.mPrefix = prefix;
        }

        @Override
        public boolean accept(File pathname) {
            // TODO(yzshen, qsr): skip some interface versioning tests.
            if (pathname.getName().startsWith("conformance_mthd13_good_2")) {
                return false;
            }
            return pathname.isFile() && pathname.getName().startsWith(mPrefix)
                    && pathname.getName().endsWith(".data");
        }
    }

    private static String getStringContent(File f) throws FileNotFoundException {
        try (Scanner scanner = new Scanner(f)) {
            scanner.useDelimiter("\\Z");
            StringBuilder result = new StringBuilder();
            while (scanner.hasNext()) {
                result.append(scanner.next());
            }
            return result.toString().trim();
        }
    }

    private static List<TestData> getTestData(String prefix)
            throws FileNotFoundException {
        List<TestData> results = new ArrayList<TestData>();

        // Do not fail if the test data is not present.
        if (!VALIDATION_TEST_DATA_PATH.isDirectory()) {
            Log.w("ValidationTest", "No test found.");
            return results;
        }

        for (File dataFile : VALIDATION_TEST_DATA_PATH.listFiles(new DataFileFilter(prefix))) {
            File resultFile = new File(dataFile.getParent(),
                    dataFile.getName().replaceFirst("\\.data$", ".expected"));
            TestData testData = new TestData();
            testData.dataFile = dataFile;
            testData.inputData = ValidationTestUtil.parseData(getStringContent(dataFile));
            testData.expectedResult = getStringContent(resultFile);
            results.add(testData);
        }
        return results;
    }

    /**
     * Runs all the test with the given prefix on the given {@link MessageReceiver}.
     */
    private static void runTest(String prefix, MessageReceiver messageReceiver)
            throws FileNotFoundException {
        List<TestData> testData = getTestData(prefix);
        for (TestData test : testData) {
            assertNull("Unable to read: " + test.dataFile.getName()
                    + ": " + test.inputData.getErrorMessage(),
                    test.inputData.getErrorMessage());
            List<Handle> handles = new ArrayList<Handle>();
            for (int i = 0; i < test.inputData.getHandlesCount(); ++i) {
                handles.add(new HandleMock());
            }
            Message message = new Message(test.inputData.getData(), handles);
            boolean passed = messageReceiver.accept(message);
            if (passed && !test.expectedResult.equals("PASS")) {
                fail("Input: " + test.dataFile.getName()
                        + ": The message should have been refused. Expected error: "
                        + test.expectedResult);
            }
            if (!passed && test.expectedResult.equals("PASS")) {
                fail("Input: " + test.dataFile.getName()
                        + ": The message should have been accepted.");
            }
        }
    }

    private static class RoutingMessageReceiver implements MessageReceiver {
        private final MessageReceiverWithResponder mRequest;
        private final MessageReceiver mResponse;

        private RoutingMessageReceiver(MessageReceiverWithResponder request,
                MessageReceiver response) {
            this.mRequest = request;
            this.mResponse = response;
        }

        /**
         * @see MessageReceiver#accept(Message)
         */
        @Override
        public boolean accept(Message message) {
            try {
                MessageHeader header = message.asServiceMessage().getHeader();
                if (header.hasFlag(MessageHeader.MESSAGE_IS_RESPONSE_FLAG)) {
                    return mResponse.accept(message);
                } else {
                    return mRequest.acceptWithResponder(message, new SinkMessageReceiver());
                }
            } catch (DeserializationException e) {
                return false;
            }
        }

        /**
         * @see MessageReceiver#close()
         */
        @Override
        public void close() {
        }

    }

    /**
     * A trivial message receiver that refuses all messages it receives.
     */
    private static class SinkMessageReceiver implements MessageReceiverWithResponder {

        @Override
        public boolean accept(Message message) {
            return true;
        }

        @Override
        public void close() {
        }

        @Override
        public boolean acceptWithResponder(Message message, MessageReceiver responder) {
            return true;
        }
    }

    /**
     * Testing the conformance suite.
     */
    @SmallTest
    public void testConformance() throws FileNotFoundException {
        runTest("conformance_", ConformanceTestInterface.MANAGER.buildStub(null,
                ConformanceTestInterface.MANAGER.buildProxy(null, new SinkMessageReceiver())));
    }

    /**
     * Testing the integration suite for message headers.
     */
    @SmallTest
    public void testIntegrationMessageHeader() throws FileNotFoundException {
        runTest("integration_msghdr_",
                new RoutingMessageReceiver(IntegrationTestInterface.MANAGER.buildStub(null,
                        IntegrationTestInterface.MANAGER.buildProxy(null,
                                new SinkMessageReceiver())),
                        IntegrationTestInterfaceTestHelper
                                .newIntegrationTestInterfaceMethodCallback()));
    }

    /**
     * Testing the integration suite for request messages.
     */
    @SmallTest
    public void testIntegrationRequestMessage() throws FileNotFoundException {
        runTest("integration_intf_rqst_",
                new RoutingMessageReceiver(IntegrationTestInterface.MANAGER.buildStub(null,
                        IntegrationTestInterface.MANAGER.buildProxy(null,
                                new SinkMessageReceiver())),
                        IntegrationTestInterfaceTestHelper
                                .newIntegrationTestInterfaceMethodCallback()));
    }

    /**
     * Testing the integration suite for response messages.
     */
    @SmallTest
    public void testIntegrationResponseMessage() throws FileNotFoundException {
        runTest("integration_intf_resp_",
                new RoutingMessageReceiver(IntegrationTestInterface.MANAGER.buildStub(null,
                        IntegrationTestInterface.MANAGER.buildProxy(null,
                                new SinkMessageReceiver())),
                        IntegrationTestInterfaceTestHelper
                                .newIntegrationTestInterfaceMethodCallback()));
    }
}
