// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.tools.findbugs.plugin;

import org.apache.bcel.classfile.Code;

import edu.umd.cs.findbugs.BugInstance;
import edu.umd.cs.findbugs.BugReporter;
import edu.umd.cs.findbugs.bcel.OpcodeStackDetector;

/**
 * This class detects the synchronized(this).
 *
 * The pattern of byte code of synchronized(this) is
 * aload_0         # Load the 'this' pointer on top of stack
 * dup             # Duplicate the 'this' pointer
 * astore_x        # Store this for late use, it might be astore.
 * monitorenter
 */
public class SynchronizedThisDetector extends OpcodeStackDetector {
    private static final int PATTERN[] = {ALOAD_0, DUP, 0xff, 0xff, MONITORENTER};

    private int mStep = 0;
    private BugReporter mBugReporter;

    public SynchronizedThisDetector(BugReporter bugReporter) {
        mBugReporter = bugReporter;
    }

    @Override
    public void visit(Code code) {
        mStep = 0;
        super.visit(code);
    }

    @Override
    public void sawOpcode(int seen) {
        if (PATTERN[mStep] == seen) {
            mStep++;
            if (mStep == PATTERN.length) {
                mBugReporter.reportBug(new BugInstance(this, "CHROMIUM_SYNCHRONIZED_THIS",
                                                       NORMAL_PRIORITY)
                        .addClassAndMethod(this)
                        .addSourceLine(this));
                mStep = 0;
                return;
            }
        } else if (mStep == 2) {
            // This could be astore_x
            switch (seen) {
                case ASTORE_0:
                case ASTORE_1:
                case ASTORE_2:
                case ASTORE_3:
                    mStep += 2;
                    break;
                case ASTORE:
                    mStep++;
                    break;
                default:
                    mStep = 0;
                    break;
            }
        } else if (mStep == 3) {
            // Could be any byte following the ASTORE.
            mStep++;
        } else {
            mStep = 0;
        }
    }
}
