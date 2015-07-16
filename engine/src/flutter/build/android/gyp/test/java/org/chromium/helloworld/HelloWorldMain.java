// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.helloworld;

public class HelloWorldMain {
    public static void main(String[] args) {
        if (args.length > 0) {
            System.exit(Integer.parseInt(args[0]));
        }
        HelloWorldPrinter.print();
    }
}

