// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.system;

/**
 * The different mojo result codes.
 */
public final class MojoResult {
    public static final int OK = 0;
    public static final int CANCELLED = 1;
    public static final int UNKNOWN = 2;
    public static final int INVALID_ARGUMENT = 3;
    public static final int DEADLINE_EXCEEDED = 4;
    public static final int NOT_FOUND = 5;
    public static final int ALREADY_EXISTS = 6;
    public static final int PERMISSION_DENIED = 7;
    public static final int RESOURCE_EXHAUSTED = 8;
    public static final int FAILED_PRECONDITION = 9;
    public static final int ABORTED = 10;
    public static final int OUT_OF_RANGE = 11;
    public static final int UNIMPLEMENTED = 12;
    public static final int INTERNAL = 13;
    public static final int UNAVAILABLE = 14;
    public static final int DATA_LOSS = 15;
    public static final int BUSY = 16;
    public static final int SHOULD_WAIT = 17;

    /**
     * never instantiate.
     */
    private MojoResult() {
    }

    /**
     * Describes the given result code.
     */
    public static String describe(int mCode) {
        switch (mCode) {
            case OK:
                return "OK";
            case CANCELLED:
                return "CANCELLED";
            case UNKNOWN:
                return "UNKNOWN";
            case INVALID_ARGUMENT:
                return "INVALID_ARGUMENT";
            case DEADLINE_EXCEEDED:
                return "DEADLINE_EXCEEDED";
            case NOT_FOUND:
                return "NOT_FOUND";
            case ALREADY_EXISTS:
                return "ALREADY_EXISTS";
            case PERMISSION_DENIED:
                return "PERMISSION_DENIED";
            case RESOURCE_EXHAUSTED:
                return "RESOURCE_EXHAUSTED";
            case FAILED_PRECONDITION:
                return "FAILED_PRECONDITION";
            case ABORTED:
                return "ABORTED";
            case OUT_OF_RANGE:
                return "OUT_OF_RANGE";
            case UNIMPLEMENTED:
                return "UNIMPLEMENTED";
            case INTERNAL:
                return "INTERNAL";
            case UNAVAILABLE:
                return "UNAVAILABLE";
            case DATA_LOSS:
                return "DATA_LOSS";
            case BUSY:
                return "BUSY";
            case SHOULD_WAIT:
                return "SHOULD_WAIT";
            default:
                return "UNKNOWN";
        }

    }
}
