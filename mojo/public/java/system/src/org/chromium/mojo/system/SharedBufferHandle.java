// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.system;

import java.nio.ByteBuffer;

/**
 * A buffer that can be shared between applications.
 */
public interface SharedBufferHandle extends Handle {

    /**
     * Flags for the shared buffer creation operation.
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
     * Used to specify creation parameters for a shared buffer to |Core#createSharedBuffer()|.
     */
    public static class CreateOptions {
        private CreateFlags mFlags = CreateFlags.NONE;

        /**
         * @return the flags
         */
        public CreateFlags getFlags() {
            return mFlags;
        }

    }

    /**
     * Flags for the shared buffer duplication operation.
     */
    public static class DuplicateFlags extends Flags<DuplicateFlags> {
        private static final int FLAG_NONE = 0;

        /**
         * Immutable flag with not bit set.
         */
        public static final DuplicateFlags NONE = DuplicateFlags.none().immutable();

        /**
         * Dedicated constructor.
         *
         * @param flags initial value of the flags.
         */
        protected DuplicateFlags(int flags) {
            super(flags);
        }

        /**
         * @return flags with no bit set.
         */
        public static DuplicateFlags none() {
            return new DuplicateFlags(FLAG_NONE);
        }

    }

    /**
     * Used to specify parameters in duplicating access to a shared buffer to
     * |SharedBufferHandle#duplicate|
     */
    public static class DuplicateOptions {
        private DuplicateFlags mFlags = DuplicateFlags.NONE;

        /**
         * @return the flags
         */
        public DuplicateFlags getFlags() {
            return mFlags;
        }

    }

    /**
     * Flags for the shared buffer map operation.
     */
    public static class MapFlags extends Flags<MapFlags> {
        private static final int FLAG_NONE = 0;

        /**
         * Immutable flag with not bit set.
         */
        public static final MapFlags NONE = MapFlags.none().immutable();

        /**
         * Dedicated constructor.
         *
         * @param flags initial value of the flags.
         */
        protected MapFlags(int flags) {
            super(flags);
        }

        /**
         * @return flags with no bit set.
         */
        public static MapFlags none() {
            return new MapFlags(FLAG_NONE);
        }

    }

    /**
     * @see org.chromium.mojo.system.Handle#pass()
     */
    @Override
    public SharedBufferHandle pass();

    /**
     * Duplicates the handle. This creates another handle (returned on success), which can then be
     * sent to another application over a message pipe, while retaining access to this handle (and
     * any mappings that it may have).
     */
    public SharedBufferHandle duplicate(DuplicateOptions options);

    /**
     * Map the part (at offset |offset| of length |numBytes|) of the buffer given by this handle
     * into memory. |offset + numBytes| must be less than or equal to the size of the buffer. On
     * success, the returned buffer points to memory with the requested part of the buffer. A single
     * buffer handle may have multiple active mappings (possibly depending on the buffer type). The
     * permissions (e.g., writable or executable) of the returned memory may depend on the
     * properties of the buffer and properties attached to the buffer handle as well as |flags|.
     */
    public ByteBuffer map(long offset, long numBytes, MapFlags flags);

    /**
     * Unmap a buffer pointer that was mapped by |map()|.
     */
    public void unmap(ByteBuffer buffer);

}
