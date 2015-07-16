// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base.library_loader;

/**
 * The exception that is thrown when the intialization of a process was failed.
 */
public class ProcessInitException extends Exception {
    private int mErrorCode = LoaderErrors.LOADER_ERROR_NORMAL_COMPLETION;

    /**
     * @param errorCode This will be one of the LoaderErrors error codes.
     */
    public ProcessInitException(int errorCode) {
        mErrorCode = errorCode;
    }

    /**
     * @param errorCode This will be one of the LoaderErrors error codes.
     * @param throwable The wrapped throwable obj.
     */
    public ProcessInitException(int errorCode, Throwable throwable) {
        super(null, throwable);
        mErrorCode = errorCode;
    }

    /**
     * Return the error code.
     */
    public int getErrorCode() {
        return mErrorCode;
    }
}
