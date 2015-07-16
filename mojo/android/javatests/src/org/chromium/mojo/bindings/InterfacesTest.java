// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.bindings;

import android.test.suitebuilder.annotation.SmallTest;

import org.chromium.mojo.MojoTestCase;
import org.chromium.mojo.bindings.BindingsTestUtils.CapturingErrorHandler;
import org.chromium.mojo.bindings.test.mojom.imported.ImportedInterface;
import org.chromium.mojo.bindings.test.mojom.sample.Factory;
import org.chromium.mojo.bindings.test.mojom.sample.NamedObject;
import org.chromium.mojo.bindings.test.mojom.sample.NamedObject.GetNameResponse;
import org.chromium.mojo.bindings.test.mojom.sample.Request;
import org.chromium.mojo.bindings.test.mojom.sample.Response;
import org.chromium.mojo.system.DataPipe.ConsumerHandle;
import org.chromium.mojo.system.MessagePipeHandle;
import org.chromium.mojo.system.Pair;
import org.chromium.mojo.system.impl.CoreImpl;

import java.io.Closeable;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Tests for interfaces / proxies / stubs generated for sample_factory.mojom.
 */
public class InterfacesTest extends MojoTestCase {

    private static final String OBJECT_NAME = "hello world";

    private final List<Closeable> mCloseablesToClose = new ArrayList<Closeable>();

    /**
     * Basic implementation of {@link NamedObject}.
     */
    public static class MockNamedObjectImpl extends CapturingErrorHandler implements NamedObject {

        private String mName = "";

        /**
         * @see org.chromium.mojo.bindings.Interface#close()
         */
        @Override
        public void close() {
        }

        @Override
        public void setName(String name) {
            mName = name;
        }

        @Override
        public void getName(GetNameResponse callback) {
            callback.call(mName);
        }

        public String getNameSynchronously() {
            return mName;
        }
    }

    /**
     * Implementation of {@link GetNameResponse} keeping track of usage.
     */
    public static class RecordingGetNameResponse implements GetNameResponse {
        private String mName;
        private boolean mCalled;

        public RecordingGetNameResponse() {
            reset();
        }

        @Override
        public void call(String name) {
            mName = name;
            mCalled = true;
        }

        public String getName() {
            return mName;
        }

        public boolean wasCalled() {
            return mCalled;
        }

        public void reset() {
            mName = null;
            mCalled = false;
        }
    }

    /**
     * Basic implementation of {@link Factory}.
     */
    public class MockFactoryImpl extends CapturingErrorHandler implements Factory {

        private boolean mClosed = false;

        public boolean isClosed() {
            return mClosed;
        }

        /**
         * @see org.chromium.mojo.bindings.Interface#close()
         */
        @Override
        public void close() {
            mClosed = true;
        }

        @Override
        public void doStuff(Request request, MessagePipeHandle pipe, DoStuffResponse callback) {
            if (pipe != null) {
                pipe.close();
            }
            Response response = new Response();
            response.x = 42;
            callback.call(response, "Hello");
        }

        @Override
        public void doStuff2(ConsumerHandle pipe, DoStuff2Response callback) {
            callback.call("World");
        }

        @Override
        public void createNamedObject(InterfaceRequest<NamedObject> obj) {
            NamedObject.MANAGER.bind(new MockNamedObjectImpl(), obj);
        }

        @Override
        public void requestImportedInterface(InterfaceRequest<ImportedInterface> obj,
                RequestImportedInterfaceResponse callback) {
            throw new UnsupportedOperationException("Not implemented.");
        }

        @Override
        public void takeImportedInterface(ImportedInterface obj,
                TakeImportedInterfaceResponse callback) {
            throw new UnsupportedOperationException("Not implemented.");
        }
    }

    /**
     * Implementation of DoStuffResponse that keeps track of if the response is called.
     */
    public class DoStuffResponseImpl implements Factory.DoStuffResponse {
        private boolean mResponseCalled = false;

        public boolean wasResponseCalled() {
            return mResponseCalled;
        }

        @Override
        public void call(Response response, String string) {
            mResponseCalled = true;
        }
    }

    /**
     * @see MojoTestCase#tearDown()
     */
    @Override
    protected void tearDown() throws Exception {
        // Close the elements in the reverse order they were added. This is needed because it is an
        // error to close the handle of a proxy without closing the proxy first.
        Collections.reverse(mCloseablesToClose);
        for (Closeable c : mCloseablesToClose) {
            c.close();
        }
        super.tearDown();
    }

    /**
     * Check that the given proxy receives the calls. If |impl| is not null, also check that the
     * calls are forwared to |impl|.
     */
    private void checkProxy(NamedObject.Proxy proxy, MockNamedObjectImpl impl) {
        RecordingGetNameResponse callback = new RecordingGetNameResponse();
        CapturingErrorHandler errorHandler = new CapturingErrorHandler();
        proxy.getProxyHandler().setErrorHandler(errorHandler);

        if (impl != null) {
            assertNull(impl.getLastMojoException());
            assertEquals("", impl.getNameSynchronously());
        }

        proxy.getName(callback);
        runLoopUntilIdle();

        assertNull(errorHandler.getLastMojoException());
        assertTrue(callback.wasCalled());
        assertEquals("", callback.getName());

        callback.reset();
        proxy.setName(OBJECT_NAME);
        runLoopUntilIdle();

        assertNull(errorHandler.getLastMojoException());
        if (impl != null) {
            assertNull(impl.getLastMojoException());
            assertEquals(OBJECT_NAME, impl.getNameSynchronously());
        }

        proxy.getName(callback);
        runLoopUntilIdle();

        assertNull(errorHandler.getLastMojoException());
        assertTrue(callback.wasCalled());
        assertEquals(OBJECT_NAME, callback.getName());
    }

    @SmallTest
    public void testName() {
        assertEquals("sample::NamedObject", NamedObject.MANAGER.getName());
    }

    @SmallTest
    public void testProxyAndStub() {
        MockNamedObjectImpl impl = new MockNamedObjectImpl();
        NamedObject.Proxy proxy =
                NamedObject.MANAGER.buildProxy(null, NamedObject.MANAGER.buildStub(null, impl));

        checkProxy(proxy, impl);
    }

    @SmallTest
    public void testProxyAndStubOverPipe() {
        MockNamedObjectImpl impl = new MockNamedObjectImpl();
        NamedObject.Proxy proxy =
                BindingsTestUtils.newProxyOverPipe(NamedObject.MANAGER, impl, mCloseablesToClose);

        checkProxy(proxy, impl);
    }

    @SmallTest
    public void testFactoryOverPipe() {
        Factory.Proxy proxy = BindingsTestUtils.newProxyOverPipe(
                Factory.MANAGER, new MockFactoryImpl(), mCloseablesToClose);
        Pair<NamedObject.Proxy, InterfaceRequest<NamedObject>> request =
                NamedObject.MANAGER.getInterfaceRequest(CoreImpl.getInstance());
        mCloseablesToClose.add(request.first);
        proxy.createNamedObject(request.second);

        checkProxy(request.first, null);
    }

    @SmallTest
    public void testInterfaceClosing() {
        MockFactoryImpl impl = new MockFactoryImpl();
        Factory.Proxy proxy =
                BindingsTestUtils.newProxyOverPipe(Factory.MANAGER, impl, mCloseablesToClose);

        assertFalse(impl.isClosed());

        proxy.close();
        runLoopUntilIdle();

        assertTrue(impl.isClosed());
    }

    @SmallTest
    public void testResponse() {
        MockFactoryImpl impl = new MockFactoryImpl();
        Factory.Proxy proxy =
                BindingsTestUtils.newProxyOverPipe(Factory.MANAGER, impl, mCloseablesToClose);
        Request request = new Request();
        request.x = 42;
        Pair<MessagePipeHandle, MessagePipeHandle> handles =
                CoreImpl.getInstance().createMessagePipe(null);
        DoStuffResponseImpl response = new DoStuffResponseImpl();
        proxy.doStuff(request, handles.first, response);

        assertFalse(response.wasResponseCalled());

        runLoopUntilIdle();

        assertTrue(response.wasResponseCalled());
    }
}
