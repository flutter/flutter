// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.tools.findbugs.plugin;

import org.apache.bcel.classfile.Code;

import edu.umd.cs.findbugs.BugInstance;
import edu.umd.cs.findbugs.BugReporter;
import edu.umd.cs.findbugs.bcel.OpcodeStackDetector;

/**
 * This class detects the synchronized method.
 */
public class SynchronizedMethodDetector extends OpcodeStackDetector {
    private BugReporter mBugReporter;

    public SynchronizedMethodDetector(BugReporter bugReporter) {
        this.mBugReporter = bugReporter;
    }

    @Override
    public void visit(Code code) {
        if (getMethod().isSynchronized()) {
            mBugReporter.reportBug(new BugInstance(this, "CHROMIUM_SYNCHRONIZED_METHOD",
                                                   NORMAL_PRIORITY)
                    .addClassAndMethod(this)
                    .addSourceLine(this));
        }
        super.visit(code);
    }

    @Override
    public void sawOpcode(int arg0) {
    }
}
