// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.system.impl;

import org.chromium.base.CalledByNative;
import org.chromium.base.JNINamespace;
import org.chromium.mojo.system.AsyncWaiter;
import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.DataPipe;
import org.chromium.mojo.system.DataPipe.ConsumerHandle;
import org.chromium.mojo.system.DataPipe.ProducerHandle;
import org.chromium.mojo.system.Handle;
import org.chromium.mojo.system.MessagePipeHandle;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojo.system.MojoResult;
import org.chromium.mojo.system.Pair;
import org.chromium.mojo.system.ResultAnd;
import org.chromium.mojo.system.RunLoop;
import org.chromium.mojo.system.SharedBufferHandle;
import org.chromium.mojo.system.SharedBufferHandle.DuplicateOptions;
import org.chromium.mojo.system.SharedBufferHandle.MapFlags;
import org.chromium.mojo.system.UntypedHandle;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * Implementation of {@link Core}.
 */
@JNINamespace("mojo::android")
public class CoreImpl implements Core, AsyncWaiter {
    /**
     * Discard flag for the |MojoReadData| operation.
     */
    private static final int MOJO_READ_DATA_FLAG_DISCARD = 1 << 1;

    /**
     * the size of a handle, in bytes.
     */
    private static final int HANDLE_SIZE = 4;

    /**
     * the size of a flag, in bytes.
     */
    private static final int FLAG_SIZE = 4;

    /**
     * The mojo handle for an invalid handle.
     */
    public static final int INVALID_HANDLE = 0;

    private static class LazyHolder { private static final Core INSTANCE = new CoreImpl(); }

    /**
     * The run loop for the current thread.
     */
    private final ThreadLocal<BaseRunLoop> mCurrentRunLoop = new ThreadLocal<BaseRunLoop>();

    /**
     * The offset needed to get an aligned buffer.
     */
    private final int mByteBufferOffset;

    /**
     * @return the instance.
     */
    public static Core getInstance() {
        return LazyHolder.INSTANCE;
    }

    private CoreImpl() {
        // Fix for the ART runtime, before:
        // https://android.googlesource.com/platform/libcore/+/fb6c80875a8a8d0a9628562f89c250b6a962e824%5E!/
        // This assumes consistent allocation.
        mByteBufferOffset = nativeGetNativeBufferOffset(ByteBuffer.allocateDirect(8), 8);
    }

    /**
     * @see Core#getTimeTicksNow()
     */
    @Override
    public long getTimeTicksNow() {
        return nativeGetTimeTicksNow();
    }

    /**
     * @see Core#waitMany(List, long)
     */
    @Override
    public WaitManyResult waitMany(List<Pair<Handle, HandleSignals>> handles, long deadline) {
        // Allocate a direct buffer to allow native code not to reach back to java. The buffer
        // layout will be:
        // input: The array of handles (int, 4 bytes each)
        // input: The array of signals (int, 4 bytes each)
        // space for output: The array of handle states (2 ints, 8 bytes each)
        // Space for output: The result index (int, 4 bytes)
        // The handles and signals will be filled before calling the native method. When the native
        // method returns, the handle states and the index will have been set.
        ByteBuffer buffer = allocateDirectBuffer(handles.size() * 16 + 4);
        int index = 0;
        for (Pair<Handle, HandleSignals> handle : handles) {
            buffer.putInt(HANDLE_SIZE * index, getMojoHandle(handle.first));
            buffer.putInt(
                    HANDLE_SIZE * handles.size() + FLAG_SIZE * index, handle.second.getFlags());
            index++;
        }
        int code = nativeWaitMany(buffer, deadline);
        WaitManyResult result = new WaitManyResult();
        result.setMojoResult(filterMojoResultForWait(code));
        result.setHandleIndex(buffer.getInt(handles.size() * 16));
        if (result.getMojoResult() != MojoResult.INVALID_ARGUMENT
                && result.getMojoResult() != MojoResult.RESOURCE_EXHAUSTED) {
            HandleSignalsState[] states = new HandleSignalsState[handles.size()];
            for (int i = 0; i < handles.size(); ++i) {
                states[i] = new HandleSignalsState(
                        new HandleSignals(buffer.getInt(8 * (handles.size() + i))),
                        new HandleSignals(buffer.getInt(8 * (handles.size() + i) + 4)));
            }
            result.setSignalStates(Arrays.asList(states));
        }
        return result;
    }

    /**
     * @see Core#wait(Handle, HandleSignals, long)
     */
    @Override
    public WaitResult wait(Handle handle, HandleSignals signals, long deadline) {
        // Allocate a direct buffer to allow native code not to reach back to java. Buffer will
        // contain spaces to write the handle state.
        ByteBuffer buffer = allocateDirectBuffer(8);
        WaitResult result = new WaitResult();
        result.setMojoResult(filterMojoResultForWait(
                nativeWait(buffer, getMojoHandle(handle), signals.getFlags(), deadline)));
        HandleSignalsState signalsState = new HandleSignalsState(
                new HandleSignals(buffer.getInt(0)), new HandleSignals(buffer.getInt(4)));
        result.setHandleSignalsState(signalsState);
        return result;
    }

    /**
     * @see Core#createMessagePipe(MessagePipeHandle.CreateOptions)
     */
    @Override
    public Pair<MessagePipeHandle, MessagePipeHandle> createMessagePipe(
            MessagePipeHandle.CreateOptions options) {
        ByteBuffer optionsBuffer = null;
        if (options != null) {
            optionsBuffer = allocateDirectBuffer(8);
            optionsBuffer.putInt(0, 8);
            optionsBuffer.putInt(4, options.getFlags().getFlags());
        }
        ResultAnd<IntegerPair> result = nativeCreateMessagePipe(optionsBuffer);
        if (result.getMojoResult() != MojoResult.OK) {
            throw new MojoException(result.getMojoResult());
        }
        return Pair.<MessagePipeHandle, MessagePipeHandle>create(
                new MessagePipeHandleImpl(this, result.getValue().first),
                new MessagePipeHandleImpl(this, result.getValue().second));
    }

    /**
     * @see Core#createDataPipe(DataPipe.CreateOptions)
     */
    @Override
    public Pair<ProducerHandle, ConsumerHandle> createDataPipe(DataPipe.CreateOptions options) {
        ByteBuffer optionsBuffer = null;
        if (options != null) {
            optionsBuffer = allocateDirectBuffer(16);
            optionsBuffer.putInt(0, 16);
            optionsBuffer.putInt(4, options.getFlags().getFlags());
            optionsBuffer.putInt(8, options.getElementNumBytes());
            optionsBuffer.putInt(12, options.getCapacityNumBytes());
        }
        ResultAnd<IntegerPair> result = nativeCreateDataPipe(optionsBuffer);
        if (result.getMojoResult() != MojoResult.OK) {
            throw new MojoException(result.getMojoResult());
        }
        return Pair.<ProducerHandle, ConsumerHandle>create(
                new DataPipeProducerHandleImpl(this, result.getValue().first),
                new DataPipeConsumerHandleImpl(this, result.getValue().second));
    }

    /**
     * @see Core#createSharedBuffer(SharedBufferHandle.CreateOptions, long)
     */
    @Override
    public SharedBufferHandle createSharedBuffer(
            SharedBufferHandle.CreateOptions options, long numBytes) {
        ByteBuffer optionsBuffer = null;
        if (options != null) {
            optionsBuffer = allocateDirectBuffer(8);
            optionsBuffer.putInt(0, 8);
            optionsBuffer.putInt(4, options.getFlags().getFlags());
        }
        ResultAnd<Integer> result = nativeCreateSharedBuffer(optionsBuffer, numBytes);
        if (result.getMojoResult() != MojoResult.OK) {
            throw new MojoException(result.getMojoResult());
        }
        return new SharedBufferHandleImpl(this, result.getValue());
    }

    /**
     * @see org.chromium.mojo.system.Core#acquireNativeHandle(int)
     */
    @Override
    public UntypedHandle acquireNativeHandle(int handle) {
        return new UntypedHandleImpl(this, handle);
    }

    /**
     * @see Core#getDefaultAsyncWaiter()
     */
    @Override
    public AsyncWaiter getDefaultAsyncWaiter() {
        return this;
    }

    /**
     * @see Core#createDefaultRunLoop()
     */
    @Override
    public RunLoop createDefaultRunLoop() {
        if (mCurrentRunLoop.get() != null) {
            throw new MojoException(MojoResult.FAILED_PRECONDITION);
        }
        BaseRunLoop runLoop = new BaseRunLoop(this);
        mCurrentRunLoop.set(runLoop);
        return runLoop;
    }

    /**
     * @see Core#getCurrentRunLoop()
     */
    @Override
    public RunLoop getCurrentRunLoop() {
        return mCurrentRunLoop.get();
    }

    /**
     * Remove the current run loop.
     */
    void clearCurrentRunLoop() {
        mCurrentRunLoop.remove();
    }

    /**
     * @see AsyncWaiter#asyncWait(Handle, Core.HandleSignals, long, Callback)
     */
    @Override
    public Cancellable asyncWait(
            Handle handle, HandleSignals signals, long deadline, Callback callback) {
        return nativeAsyncWait(getMojoHandle(handle), signals.getFlags(), deadline, callback);
    }

    int closeWithResult(int mojoHandle) {
        return nativeClose(mojoHandle);
    }

    void close(int mojoHandle) {
        int mojoResult = nativeClose(mojoHandle);
        if (mojoResult != MojoResult.OK) {
            throw new MojoException(mojoResult);
        }
    }

    /**
     * @see MessagePipeHandle#writeMessage(ByteBuffer, List, MessagePipeHandle.WriteFlags)
     */
    void writeMessage(MessagePipeHandleImpl pipeHandle, ByteBuffer bytes,
            List<? extends Handle> handles, MessagePipeHandle.WriteFlags flags) {
        if (bytes != null && !bytes.isDirect()) {
            throw new IllegalArgumentException("ByteBuffer must be direct.");
        }
        ByteBuffer handlesBuffer = null;
        if (handles != null && !handles.isEmpty()) {
            handlesBuffer = allocateDirectBuffer(handles.size() * HANDLE_SIZE);
            for (Handle handle : handles) {
                handlesBuffer.putInt(getMojoHandle(handle));
            }
            handlesBuffer.position(0);
        }
        int mojoResult = nativeWriteMessage(pipeHandle.getMojoHandle(), bytes,
                bytes == null ? 0 : bytes.limit(), handlesBuffer, flags.getFlags());
        if (mojoResult != MojoResult.OK) {
            throw new MojoException(mojoResult);
        }
        // Success means the handles have been invalidated.
        if (handles != null) {
            for (Handle handle : handles) {
                if (handle.isValid()) {
                    ((HandleBase) handle).invalidateHandle();
                }
            }
        }
    }

    /**
     * @see MessagePipeHandle#readMessage(ByteBuffer, int, MessagePipeHandle.ReadFlags)
     */
    ResultAnd<MessagePipeHandle.ReadMessageResult> readMessage(MessagePipeHandleImpl handle,
            ByteBuffer bytes, int maxNumberOfHandles, MessagePipeHandle.ReadFlags flags) {
        if (bytes != null && !bytes.isDirect()) {
            throw new IllegalArgumentException("ByteBuffer must be direct.");
        }
        ByteBuffer handlesBuffer = null;
        if (maxNumberOfHandles > 0) {
            handlesBuffer = allocateDirectBuffer(maxNumberOfHandles * HANDLE_SIZE);
        }
        ResultAnd<MessagePipeHandle.ReadMessageResult> result =
                nativeReadMessage(handle.getMojoHandle(), bytes, handlesBuffer, flags.getFlags());
        if (result.getMojoResult() != MojoResult.OK
                && result.getMojoResult() != MojoResult.RESOURCE_EXHAUSTED
                && result.getMojoResult() != MojoResult.SHOULD_WAIT) {
            throw new MojoException(result.getMojoResult());
        }

        if (result.getMojoResult() == MojoResult.OK) {
            MessagePipeHandle.ReadMessageResult readResult = result.getValue();
            if (bytes != null) {
                bytes.position(0);
                bytes.limit(readResult.getMessageSize());
            }

            List<UntypedHandle> handles =
                    new ArrayList<UntypedHandle>(readResult.getHandlesCount());
            for (int i = 0; i < readResult.getHandlesCount(); ++i) {
                int mojoHandle = handlesBuffer.getInt(HANDLE_SIZE * i);
                handles.add(new UntypedHandleImpl(this, mojoHandle));
            }
            readResult.setHandles(handles);
        }
        return result;
    }

    /**
     * @see ConsumerHandle#discardData(int, DataPipe.ReadFlags)
     */
    int discardData(DataPipeConsumerHandleImpl handle, int numBytes, DataPipe.ReadFlags flags) {
        ResultAnd<Integer> result = nativeReadData(handle.getMojoHandle(), null, numBytes,
                flags.getFlags() | MOJO_READ_DATA_FLAG_DISCARD);
        if (result.getMojoResult() != MojoResult.OK) {
            throw new MojoException(result.getMojoResult());
        }
        return result.getValue();
    }

    /**
     * @see ConsumerHandle#readData(ByteBuffer, DataPipe.ReadFlags)
     */
    ResultAnd<Integer> readData(
            DataPipeConsumerHandleImpl handle, ByteBuffer elements, DataPipe.ReadFlags flags) {
        if (elements != null && !elements.isDirect()) {
            throw new IllegalArgumentException("ByteBuffer must be direct.");
        }
        ResultAnd<Integer> result = nativeReadData(handle.getMojoHandle(), elements,
                elements == null ? 0 : elements.capacity(), flags.getFlags());
        if (result.getMojoResult() != MojoResult.OK
                && result.getMojoResult() != MojoResult.SHOULD_WAIT) {
            throw new MojoException(result.getMojoResult());
        }
        if (result.getMojoResult() == MojoResult.OK) {
            if (elements != null) {
                elements.limit(result.getValue());
            }
        }
        return result;
    }

    /**
     * @see ConsumerHandle#beginReadData(int, DataPipe.ReadFlags)
     */
    ByteBuffer beginReadData(
            DataPipeConsumerHandleImpl handle, int numBytes, DataPipe.ReadFlags flags) {
        ResultAnd<ByteBuffer> result =
                nativeBeginReadData(handle.getMojoHandle(), numBytes, flags.getFlags());
        if (result.getMojoResult() != MojoResult.OK) {
            throw new MojoException(result.getMojoResult());
        }
        return result.getValue().asReadOnlyBuffer();
    }

    /**
     * @see ConsumerHandle#endReadData(int)
     */
    void endReadData(DataPipeConsumerHandleImpl handle, int numBytesRead) {
        int result = nativeEndReadData(handle.getMojoHandle(), numBytesRead);
        if (result != MojoResult.OK) {
            throw new MojoException(result);
        }
    }

    /**
     * @see ProducerHandle#writeData(ByteBuffer, DataPipe.WriteFlags)
     */
    ResultAnd<Integer> writeData(
            DataPipeProducerHandleImpl handle, ByteBuffer elements, DataPipe.WriteFlags flags) {
        if (!elements.isDirect()) {
            throw new IllegalArgumentException("ByteBuffer must be direct.");
        }
        return nativeWriteData(
                handle.getMojoHandle(), elements, elements.limit(), flags.getFlags());
    }

    /**
     * @see ProducerHandle#beginWriteData(int, DataPipe.WriteFlags)
     */
    ByteBuffer beginWriteData(
            DataPipeProducerHandleImpl handle, int numBytes, DataPipe.WriteFlags flags) {
        ResultAnd<ByteBuffer> result =
                nativeBeginWriteData(handle.getMojoHandle(), numBytes, flags.getFlags());
        if (result.getMojoResult() != MojoResult.OK) {
            throw new MojoException(result.getMojoResult());
        }
        return result.getValue();
    }

    /**
     * @see ProducerHandle#endWriteData(int)
     */
    void endWriteData(DataPipeProducerHandleImpl handle, int numBytesWritten) {
        int result = nativeEndWriteData(handle.getMojoHandle(), numBytesWritten);
        if (result != MojoResult.OK) {
            throw new MojoException(result);
        }
    }

    /**
     * @see SharedBufferHandle#duplicate(DuplicateOptions)
     */
    SharedBufferHandle duplicate(SharedBufferHandleImpl handle, DuplicateOptions options) {
        ByteBuffer optionsBuffer = null;
        if (options != null) {
            optionsBuffer = allocateDirectBuffer(8);
            optionsBuffer.putInt(0, 8);
            optionsBuffer.putInt(4, options.getFlags().getFlags());
        }
        ResultAnd<Integer> result = nativeDuplicate(handle.getMojoHandle(), optionsBuffer);
        if (result.getMojoResult() != MojoResult.OK) {
            throw new MojoException(result.getMojoResult());
        }
        return new SharedBufferHandleImpl(this, result.getValue());
    }

    /**
     * @see SharedBufferHandle#map(long, long, MapFlags)
     */
    ByteBuffer map(SharedBufferHandleImpl handle, long offset, long numBytes, MapFlags flags) {
        ResultAnd<ByteBuffer> result =
                nativeMap(handle.getMojoHandle(), offset, numBytes, flags.getFlags());
        if (result.getMojoResult() != MojoResult.OK) {
            throw new MojoException(result.getMojoResult());
        }
        return result.getValue();
    }

    /**
     * @see SharedBufferHandle#unmap(ByteBuffer)
     */
    void unmap(ByteBuffer buffer) {
        int result = nativeUnmap(buffer);
        if (result != MojoResult.OK) {
            throw new MojoException(result);
        }
    }

    /**
     * @return the mojo handle associated to the given handle, considering invalid handles.
     */
    private int getMojoHandle(Handle handle) {
        if (handle.isValid()) {
            return ((HandleBase) handle).getMojoHandle();
        }
        return 0;
    }

    private static boolean isUnrecoverableError(int code) {
        switch (code) {
            case MojoResult.OK:
            case MojoResult.DEADLINE_EXCEEDED:
            case MojoResult.CANCELLED:
            case MojoResult.FAILED_PRECONDITION:
                return false;
            default:
                return true;
        }
    }

    private static int filterMojoResultForWait(int code) {
        if (isUnrecoverableError(code)) {
            throw new MojoException(code);
        }
        return code;
    }

    private ByteBuffer allocateDirectBuffer(int capacity) {
        ByteBuffer buffer = ByteBuffer.allocateDirect(capacity + mByteBufferOffset);
        if (mByteBufferOffset != 0) {
            buffer.position(mByteBufferOffset);
            buffer = buffer.slice();
        }
        return buffer.order(ByteOrder.nativeOrder());
    }

    /**
     * Implementation of {@link org.chromium.mojo.system.AsyncWaiter.Cancellable}.
     */
    private class AsyncWaiterCancellableImpl implements AsyncWaiter.Cancellable {
        private final long mId;
        private final long mDataPtr;
        private boolean mActive = true;

        private AsyncWaiterCancellableImpl(long id, long dataPtr) {
            this.mId = id;
            this.mDataPtr = dataPtr;
        }

        /**
         * @see org.chromium.mojo.system.AsyncWaiter.Cancellable#cancel()
         */
        @Override
        public void cancel() {
            if (mActive) {
                mActive = false;
                nativeCancelAsyncWait(mId, mDataPtr);
            }
        }

        private boolean isActive() {
            return mActive;
        }

        private void deactivate() {
            mActive = false;
        }
    }

    @CalledByNative
    private AsyncWaiterCancellableImpl newAsyncWaiterCancellableImpl(long id, long dataPtr) {
        return new AsyncWaiterCancellableImpl(id, dataPtr);
    }

    @CalledByNative
    private void onAsyncWaitResult(
            int mojoResult, AsyncWaiter.Callback callback, AsyncWaiterCancellableImpl cancellable) {
        if (!cancellable.isActive()) {
            // If cancellable is not active, the user cancelled the wait.
            return;
        }
        cancellable.deactivate();
        if (isUnrecoverableError(mojoResult)) {
            callback.onError(new MojoException(mojoResult));
            return;
        }
        callback.onResult(mojoResult);
    }

    @CalledByNative
    private static ResultAnd<ByteBuffer> newResultAndBuffer(int mojoResult, ByteBuffer buffer) {
        return new ResultAnd<>(mojoResult, buffer);
    }

    /**
     * Trivial alias for Pair<Integer, Integer>. This is needed because our jni generator is unable
     * to handle class that contains space.
     */
    private static final class IntegerPair extends Pair<Integer, Integer> {
        public IntegerPair(Integer first, Integer second) {
            super(first, second);
        }
    }

    @CalledByNative
    private static ResultAnd<MessagePipeHandle.ReadMessageResult> newReadMessageResult(
            int mojoResult, int messageSize, int handlesCount) {
        MessagePipeHandle.ReadMessageResult result = new MessagePipeHandle.ReadMessageResult();
        result.setMessageSize(messageSize);
        result.setHandlesCount(handlesCount);
        return new ResultAnd<>(mojoResult, result);
    }

    @CalledByNative
    private static ResultAnd<Integer> newResultAndInteger(int mojoResult, int numBytesRead) {
        return new ResultAnd<>(mojoResult, numBytesRead);
    }

    @CalledByNative
    private static ResultAnd<IntegerPair> newNativeCreationResult(
            int mojoResult, int mojoHandle1, int mojoHandle2) {
        return new ResultAnd<>(mojoResult, new IntegerPair(mojoHandle1, mojoHandle2));
    }

    private native long nativeGetTimeTicksNow();

    private native int nativeWaitMany(ByteBuffer buffer, long deadline);

    private native ResultAnd<IntegerPair> nativeCreateMessagePipe(ByteBuffer optionsBuffer);

    private native ResultAnd<IntegerPair> nativeCreateDataPipe(ByteBuffer optionsBuffer);

    private native ResultAnd<Integer> nativeCreateSharedBuffer(
            ByteBuffer optionsBuffer, long numBytes);

    private native int nativeClose(int mojoHandle);

    private native int nativeWait(ByteBuffer buffer, int mojoHandle, int signals, long deadline);

    private native int nativeWriteMessage(
            int mojoHandle, ByteBuffer bytes, int numBytes, ByteBuffer handlesBuffer, int flags);

    private native ResultAnd<MessagePipeHandle.ReadMessageResult> nativeReadMessage(
            int mojoHandle, ByteBuffer bytes, ByteBuffer handlesBuffer, int flags);

    private native ResultAnd<Integer> nativeReadData(
            int mojoHandle, ByteBuffer elements, int elementsSize, int flags);

    private native ResultAnd<ByteBuffer> nativeBeginReadData(
            int mojoHandle, int numBytes, int flags);

    private native int nativeEndReadData(int mojoHandle, int numBytesRead);

    private native ResultAnd<Integer> nativeWriteData(
            int mojoHandle, ByteBuffer elements, int limit, int flags);

    private native ResultAnd<ByteBuffer> nativeBeginWriteData(
            int mojoHandle, int numBytes, int flags);

    private native int nativeEndWriteData(int mojoHandle, int numBytesWritten);

    private native ResultAnd<Integer> nativeDuplicate(int mojoHandle, ByteBuffer optionsBuffer);

    private native ResultAnd<ByteBuffer> nativeMap(
            int mojoHandle, long offset, long numBytes, int flags);

    private native int nativeUnmap(ByteBuffer buffer);

    private native AsyncWaiterCancellableImpl nativeAsyncWait(
            int mojoHandle, int signals, long deadline, AsyncWaiter.Callback callback);

    private native void nativeCancelAsyncWait(long mId, long dataPtr);

    private native int nativeGetNativeBufferOffset(ByteBuffer buffer, int alignment);
}
