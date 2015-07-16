// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * JNIAdditionalImport is used by the JNI generator to qualify inner types used on JNI methods. Must
 * be used when an inner class is used from a class within the same package. Example:
 *
 * <pre>
 * @JNIAdditionImport(Foo.class)
 * public class Bar {
 *     @CalledByNative static void doSomethingWithInner(Foo.Inner inner) {
 *     ...
 *     }
 * }
 * <pre>
 * <p>
 * Notes:
 * 1) Foo must be in the same package as Bar
 * 2) For classes in different packages, they should be imported as:
 *    import other.package.Foo;
 *    and this annotation should not be used.
 */
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.CLASS)
public @interface JNIAdditionalImport {
    Class<?>[] value();
}
