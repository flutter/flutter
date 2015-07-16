// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.system;

import java.nio.ByteBuffer;

/**
 * Interface for data pipes. A data pipe is a unidirectional communication channel for unframed
 * data. Data is unframed, but must come as (multiples of) discrete elements, of the size given at
 * creation time.
 */
public interface DataPipe {

    /**
     * Flags for the data pipe creation operation.
     */
    public static class CreateFlags extends Flags<CreateFlags> {
        private static final int FLAG_NONE = 0;

        /**
         * Immutable flag with not bit set.
         */
        public static final CreateFlags NONE = CreateFlags.none().immutable();

        /**
         * Dedicated constructor.
         *
         * @param flags initial value of the flags.
         */
        protected CreateFlags(int flags) {
            super(flags);
        }

        /**
         * @return flags with no bit set.
         */
        public static CreateFlags none() {
            return new CreateFlags(FLAG_NONE);
        }

    }

    /**
     * Used to specify creation parameters for a data pipe to |Core.createDataPipe()|.
     */
    public static class CreateOptions {

        /**
         * Used to specify different modes of operation, see |DataPipe.CreateFlags|.
         */
        private CreateFlags mFlags = CreateFlags.none();
        /**
         * The size of an element, in bytes. All transactions and buffers will consist of an
         * integral number of elements. Must be nonzero.
         */
        private int mElementNumBytes;
        /**
         * The capacity of the data pipe, in number of bytes; must be a multiple of
         * |element_num_bytes|. The data pipe will always be able to queue AT LEAST this much data.
         * Set to zero to opt for a system-dependent automatically-calculated capacity (which will
         * always be at least one element).
         */
        private int mCapacityNumBytes;

        /**
         * @return the flags
         */
        public CreateFlags getFlags() {
            return mFlags;
        }

        /**
         * @return the elementNumBytes
         */
        public int getElementNumBytes() {
            return mElementNumBytes;
        }

        /**
         * @param elementNumBytes the elementNumBytes to set
         */
        public void setElementNumBytes(int elementNumBytes) {
            mElementNumBytes = elementNumBytes;
        }

        /**
         * @return the capacityNumBytes
         */
        public int getCapacityNumBytes() {
            return mCapacityNumBytes;
        }

        /**
         * @param capacityNumBytes the capacityNumBytes to set
         */
        public void setCapacityNumBytes(int capacityNumBytes) {
            mCapacityNumBytes = capacityNumBytes;
        }

    }

    /**
     * Flags for the write operations on MessagePipeHandle .
     */
    public static class WriteFlags extends Flags<WriteFlags> {
        private static final int FLAG_NONE = 0;
        private static final int FLAG_ALL_OR_NONE = 1 << 0;

        /**
         * Immutable flag with not bit set.
         */
        public static final WriteFlags NONE = WriteFlags.none().immutable();

        /**
         * Dedicated constructor.
         *
         * @param flags initial value of the flags.
         */
        private WriteFlags(int flags) {
            super(flags);
        }

        /**
         * Change the all-or-none bit of those flags. If set, write either all the elements
         * requested or none of them.
         *
         * @param allOrNone the new value of all-or-none bit.
         * @return this.
         */
        public WriteFlags setAllOrNone(boolean allOrNone) {
            return setFlag(FLAG_ALL_OR_NONE, allOrNone);
        }

        /**
         * @return a flag with no bit set.
         */
        public static WriteFlags none() {
            return new WriteFlags(FLAG_NONE);
        }
    }

    /**
     * Flags for the read operations on MessagePipeHandle.
     */
    public static class ReadFlags extends Flags<ReadFlags> {
        private static final int FLAG_NONE = 0;
        private static final int FLAG_ALL_OR_NONE = 1 << 0;
        private static final int FLAG_QUERY = 1 << 2;
        private static final int FLAG_PEEK = 1 << 3;

        /**
         * Immutable flag with not bit set.
         */
        public static final ReadFlags NONE = ReadFlags.none().immutable();

        /**
         * Dedicated constructor.
         *
         * @param flags initial value of the flag.
         */
        private ReadFlags(int flags) {
            super(flags);
        }

        /**
         * Change the all-or-none bit of this flag. If set, read (or discard) either the requested
         * number of elements or none.
         *
         * @param allOrNone the new value of the all-or-none bit.
         * @return this.
         */
        public ReadFlags setAllOrNone(boolean allOrNone) {
            return setFlag(FLAG_ALL_OR_NONE, allOrNone);
        }

        /**
         * Change the query bit of this flag. If set query the number of elements available to read.
         * Mutually exclusive with |discard| and |allOrNone| is ignored if this flag is set.
         *
         * @param query the new value of the query bit.
         * @return this.
         */
        public ReadFlags query(boolean query) {
            return setFlag(FLAG_QUERY, query);
        }

        /**
         * Change the peek bit of this flag. If set, read the requested number of elements, and
         * leave those elements in the pipe. A later read will return the same data.
         * Mutually exclusive with |discard| and |query|.
         *
         * @param peek the new value of the peek bit.
         * @return this.
         */
        public ReadFlags peek(boolean peek) {
            return setFlag(FLAG_PEEK, peek);
        }

        /**
         * @return a flag with no bit set.
         */
        public static ReadFlags none() {
            return new ReadFlags(FLAG_NONE);
        }

    }

    /**
     * Handle for the producer part of a data pipe.
     */
    public static interface ProducerHandle extends Handle {

        /**
         * @see org.chromium.mojo.system.Handle#pass()
         */
        @Override
        public ProducerHandle pass();

        /**
         * Writes the given data to the data pipe producer. |elements| points to data; the buffer
         * must be a direct ByteBuffer and the limit should be a multiple of the data pipe's element
         * size. If |allOrNone| is set in |flags|, either all the data will be written or none is.
         * <p>
         * On success, returns the amount of data that was actually written.
         * <p>
         * Note: If the data pipe has the "may discard" option flag (specified on creation), this
         * will discard as much data as required to write the given data, starting with the earliest
         * written data that has not been consumed. However, even with "may discard", if the buffer
         * limit is greater than the data pipe's capacity (and |allOrNone| is not set), this will
         * write the maximum amount possible (namely, the data pipe's capacity) and return that
         * amount. It will *not* discard data from |elements|.
         *
         * @return number of written bytes.
         */
        public ResultAnd<Integer> writeData(ByteBuffer elements, WriteFlags flags);

        /**
         * Begins a two-phase write to the data pipe producer . On success, returns a |ByteBuffer|
         * to which the caller can write. If flags has |allOrNone| set, then the buffer capacity
         * will be at least as large as |numBytes|, which must also be a multiple of the element
         * size (if |allOrNone| is not set, |numBytes| is ignored and the caller must check the
         * capacity of the buffer).
         * <p>
         * During a two-phase write, this handle is *not* writable. E.g., if another thread tries to
         * write to it, it will throw a |MojoException| with code |MojoResult.BUSY|; that thread can
         * then wait for this handle to become writable again.
         * <p>
         * Once the caller has finished writing data to the buffer, it should call |endWriteData()|
         * to specify the amount written and to complete the two-phase write.
         * <p>
         * Note: If the data pipe has the "may discard" option flag (specified on creation) and
         * |flags| has |allOrNone| set, this may discard some data.
         *
         * @return The buffer to write to.
         */
        public ByteBuffer beginWriteData(int numBytes, WriteFlags flags);

        /**
         * Ends a two-phase write to the data pipe producer that was begun by a call to
         * |beginWriteData()| on the same handle. |numBytesWritten| should indicate the amount of
         * data actually written; it must be less than or equal to the capacity of the buffer
         * returned by |beginWriteData()| and must be a multiple of the element size. The buffer
         * returned from |beginWriteData()| must have been filled with exactly |numBytesWritten|
         * bytes of data.
         * <p>
         * On failure, the two-phase write (if any) is ended (so the handle may become writable
         * again, if there's space available) but no data written to the buffer is "put into" the
         * data pipe.
         */
        public void endWriteData(int numBytesWritten);
    }

    /**
     * Handle for the consumer part of a data pipe.
     */
    public static interface ConsumerHandle extends Handle {
        /**
         * @see org.chromium.mojo.system.Handle#pass()
         */
        @Override
        public ConsumerHandle pass();

       /**
         * Discards data on the data pie consumer. This method discards up to |numBytes| (which
         * again be a multiple of the element size) bytes of data, returning the amount actually
         * discarded. if |flags| has |allOrNone|, it will either discard exactly |numBytes| bytes of
         * data or none. In this case, |query| must not be set.
         */
        public int discardData(int numBytes, ReadFlags flags);

        /**
         * Reads data from the data pipe consumer. May also be used to query the amount of data
         * available. If |flags| has not |query| set, this tries to read up to |elements| capacity
         * (which must be a multiple of the data pipe's element size) bytes of data to |elements|
         * and returns the amount actually read. |elements| must be a direct ByteBuffer. If flags
         * has |allOrNone| set, it will either read exactly |elements| capacity bytes of data or
         * none.
         * <p>
         * If flags has |query| set, it queries the amount of data available, returning the number
         * of bytes available. In this case |allOrNone| is ignored, as are |elements|.
         */
        public ResultAnd<Integer> readData(ByteBuffer elements, ReadFlags flags);

        /**
         * Begins a two-phase read from the data pipe consumer. On success, returns a |ByteBuffer|
         * from which the caller can read up to its limit bytes of data. If flags has |allOrNone|
         * set, then the limit will be at least as large as |numBytes|, which must also be a
         * multiple of the element size (if |allOrNone| is not set, |numBytes| is ignored). |flags|
         * must not have |query| set.
         * <p>
         * During a two-phase read, this handle is *not* readable. E.g., if another thread tries to
         * read from it, it will throw a |MojoException| with code |MojoResult.BUSY|; that thread
         * can then wait for this handle to become readable again.
         * <p>
         * Once the caller has finished reading data from the buffer, it should call |endReadData()|
         * to specify the amount read and to complete the two-phase read.
         */
        public ByteBuffer beginReadData(int numBytes, ReadFlags flags);

        /**
         * Ends a two-phase read from the data pipe consumer that was begun by a call to
         * |beginReadData()| on the same handle. |numBytesRead| should indicate the amount of data
         * actually read; it must be less than or equal to the limit of the buffer returned by
         * |beginReadData()| and must be a multiple of the element size.
         * <p>
         * On failure, the two-phase read (if any) is ended (so the handle may become readable
         * again) but no data is "removed" from the data pipe.
         */
        public void endReadData(int numBytesRead);
    }

}
