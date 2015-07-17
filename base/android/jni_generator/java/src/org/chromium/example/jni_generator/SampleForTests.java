// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.example.jni_generator;

import android.graphics.Rect;

import org.chromium.base.CalledByNative;
import org.chromium.base.JNINamespace;
import org.chromium.base.NativeClassQualifiedName;
import org.chromium.base.annotations.AccessedByNative;
import org.chromium.base.annotations.CalledByNativeUnchecked;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

// This class serves as a reference test for the bindings generator, and as example documentation
// for how to use the jni generator.
// The C++ counter-part is sample_for_tests.cc.
// jni_generator.gyp has a jni_generator_tests target that will:
//   * Generate a header file for the JNI bindings based on this file.
//   * Compile sample_for_tests.cc using the generated header file.
//   * link a native executable to prove the generated header + cc file are self-contained.
// All comments are informational only, and are ignored by the jni generator.
//
// Binding C/C++ with Java is not trivial, specially when ownership and object lifetime
// semantics needs to be managed across boundaries.
// Following a few guidelines will make the code simpler and less buggy:
//
// - Never write any JNI "by hand". Rely on the bindings generator to have a thin
// layer of type-safety.
//
// - Treat the types from the other side as "opaque" as possible. Do not inspect any
// object directly, but rather, rely on well-defined getters / setters.
//
// - Minimize the surface API between the two sides, and rather than calling multiple
// functions across boundaries, call only one (and then, internally in the other side,
// call as many little functions as required).
//
// - If a Java object "owns" a native object, stash the pointer in a "long mNativeClassName".
// Note that it needs to have a "destruction path", i.e., it must eventually call a method
// to delete the native object (for example, the java object has a "close()" method that
// in turn deletes the native object). Avoid relying on finalizers: those run in a different
// thread and makes the native lifetime management more difficult.
//
// - For native object "owning" java objects:
//   - If there's a strong 1:1 to relationship between native and java, the best way is to
//   stash the java object into a base::android::ScopedJavaGlobalRef. This will ensure the
//   java object can be GC'd once the native object is destroyed but note that this global strong
//   ref implies a new GC root, so be sure it will not leak and it must never rely on being
//   triggered (transitively) from a java side GC.
//   - In all other cases, the native side should keep a JavaObjectWeakGlobalRef, and check whether
//   that reference is still valid before de-referencing it. Note that you will need another
//   java-side object to be holding a strong reference to this java object while it is in use, to
//   avoid unpredictable GC of the object before native side has finished with it.
//
// - The best way to pass "compound" datatypes across in either direction is to create an inner
// class with PODs and a factory function. If possible, make it immutable (i.e., mark all the
// fields as "final"). See examples with "InnerStructB" below.
//
// - It's simpler to create thin wrappers with a well defined JNI interface than to
// expose a lot of internal details. This is specially significant for system classes where it's
// simpler to wrap factory methods and a few getters / setters than expose the entire class.
//
// - Use static factory functions annotated with @CalledByNative rather than calling the
// constructors directly.
//
// - Iterate over containers where they are originally owned, then create inner structs or
// directly call methods on the other side. It's much simpler than trying to amalgamate
// java and stl containers.
//
// An important note about qualified class name resolution:
// The generator doesn't compile the class and have little context about the
// classes being passed through the JNI layers. It adds a few simple rules:
//
// - all classes are either explicitly imported, or they are assumed to be in
// the same package.
//
// - Inner class needs to be done through an import and usage of the
// outer class, so that the generator knows how to qualify it:
// import foo.bar.Zoo;
// void call(Zoo.Inner);
//
// - implicitly imported classes aren't supported, so in order to pass
// things like Runnable, please import java.lang.Runnable;
//
// This JNINamespace annotation indicates that all native methods should be
// generated inside this namespace, including the native class that this
// object binds to.
@JNINamespace("base::android")
class SampleForTests {
    // Classes can store their C++ pointer counter part as an int that is normally initialized by
    // calling out a nativeInit() function. Replace "CPPClass" with your particular class name!
    long mNativeCPPObject;

    // You can define methods and attributes on the java class just like any other.
    // Methods without the @CalledByNative annotation won't be exposed to JNI.
    public SampleForTests() {
    }

    public void startExample() {
        // Calls C++ Init(...) method and holds a pointer to the C++ class.
        mNativeCPPObject = nativeInit("myParam");
    }

    public void doStuff() {
        // This will call CPPClass::Method() using nativePtr as a pointer to the object. This must
        // be done to:
        // * avoid leaks.
        // * using finalizers are not allowed to destroy the cpp class.
        nativeMethod(mNativeCPPObject);
    }

    public void finishExample() {
        // We're done, so let's destroy nativePtr object.
        nativeDestroy(mNativeCPPObject);
    }

    // ---------------------------------------------------------------------------------------------
    // The following methods demonstrate exporting Java methods for invocation from C++ code.
    // Java functions are mapping into C global functions by prefixing the method name with
    // "Java_<Class>_"
    // This is triggered by the @CalledByNative annotation; the methods may be named as you wish.

    // Exported to C++ as:
    // Java_Example_javaMethod(JNIEnv* env, jobject caller, jint foo, jint bar)
    // Typically the C++ code would have obtained the jobject via the Init() call described above.
    @CalledByNative
    public int javaMethod(int foo, int bar) {
        return 0;
    }

    // Exported to C++ as Java_Example_staticJavaMethod(JNIEnv* env)
    // Note no jobject argument, as it is static.
    @CalledByNative
    public static boolean staticJavaMethod() {
        return true;
    }

    // No prefix, so this method is package private. It will still be exported.
    @CalledByNative
    void packagePrivateJavaMethod() {
    }

    // Note the "Unchecked" suffix. By default, @CalledByNative will always generate bindings that
    // call CheckException(). With "@CalledByNativeUnchecked", the client C++ code is responsible to
    // call ClearException() and act as appropriate.
    // See more details at the "@CalledByNativeUnchecked" annotation.
    @CalledByNativeUnchecked
    void methodThatThrowsException() throws Exception {}

    // The generator is not confused by inline comments:
    // @CalledByNative void thisShouldNotAppearInTheOutput();
    // @CalledByNativeUnchecked public static void neitherShouldThis(int foo);

    /**
     * The generator is not confused by block comments:
     * @CalledByNative void thisShouldNotAppearInTheOutputEither();
     * @CalledByNativeUnchecked public static void andDefinitelyNotThis(int foo);
     */

    // String constants that look like comments don't confuse the generator:
    private String mArrgh = "*/*";

    // ---------------------------------------------------------------------------------------------
    // Java fields which are accessed from C++ code only must be annotated with @AccessedByNative to
    // prevent them being eliminated when unreferenced code is stripped.
    @AccessedByNative
    private int mJavaField;

    // ---------------------------------------------------------------------------------------------
    // The following methods demonstrate declaring methods to call into C++ from Java.
    // The generator detects the "native" and "static" keywords, the type and name of the first
    // parameter, and the "native" prefix to the function name to determine the C++ function
    // signatures. Besides these constraints the methods can be freely named.

    // This declares a C++ function which the application code must implement:
    // static jint Init(JNIEnv* env, jobject caller);
    // The jobject parameter refers back to this java side object instance.
    // The implementation must return the pointer to the C++ object cast to jint.
    // The caller of this method should store it, and supply it as a the nativeCPPClass param to
    // subsequent native method calls (see the methods below that take an "int native..." as first
    // param).
    private native long nativeInit(String param);

    // This defines a function binding to the associated C++ class member function. The name is
    // derived from |nativeDestroy| and |nativeCPPClass| to arrive at CPPClass::Destroy() (i.e.
    // native prefixes stripped).
    //
    // The |nativeCPPClass| is automatically cast to type CPPClass*, in order to obtain the object
    // on
    // which to invoke the member function. Replace "CPPClass" with your particular class name!
    private native void nativeDestroy(long nativeCPPClass);

    // This declares a C++ function which the application code must implement:
    // static jdouble GetDoubleFunction(JNIEnv* env, jobject caller);
    // The jobject parameter refers back to this java side object instance.
    private native double nativeGetDoubleFunction();

    // Similar to nativeGetDoubleFunction(), but here the C++ side will receive a jclass rather than
    // jobject param, as the function is declared static.
    private static native float nativeGetFloatFunction();

    // This function takes a non-POD datatype. We have a list mapping them to their full classpath
    // in jni_generator.py JavaParamToJni. If you require a new datatype, make sure you add to that
    // function.
    private native void nativeSetNonPODDatatype(Rect rect);

    // This declares a C++ function which the application code must implement:
    // static ScopedJavaLocalRef<jobject> GetNonPODDatatype(JNIEnv* env, jobject caller);
    // The jobject parameter refers back to this java side object instance.
    // Note that it returns a ScopedJavaLocalRef<jobject> so that you don' have to worry about
    // deleting the JNI local reference. This is similar with Strings and arrays.
    private native Object nativeGetNonPODDatatype();

    // Similar to nativeDestroy above, this will cast nativeCPPClass into pointer of CPPClass type
    // and call its Method member function. Replace "CPPClass" with your particular class name!
    private native int nativeMethod(long nativeCPPClass);

    // Similar to nativeMethod above, but here the C++ fully qualified class name is taken from the
    // annotation rather than parameter name, which can thus be chosen freely.
    @NativeClassQualifiedName("CPPClass::InnerClass")
    private native double nativeMethodOtherP0(long nativePtr);

    // This "struct" will be created by the native side using |createInnerStructA|,
    // and used by the java-side somehow.
    // Note that |@CalledByNative| has to contain the inner class name.
    static class InnerStructA {
        private final long mLong;
        private final int mInt;
        private final String mString;

        private InnerStructA(long l, int i, String s) {
            mLong = l;
            mInt = i;
            mString = s;
        }

        @CalledByNative("InnerStructA")
        private static InnerStructA create(long l, int i, String s) {
            return new InnerStructA(l, i, s);
        }
    }

    private List<InnerStructA> mListInnerStructA = new ArrayList<InnerStructA>();

    @CalledByNative
    private void addStructA(InnerStructA a) {
        // Called by the native side to append another element.
        mListInnerStructA.add(a);
    }

    @CalledByNative
    private void iterateAndDoSomething() {
        Iterator<InnerStructA> it = mListInnerStructA.iterator();
        while (it.hasNext()) {
            InnerStructA element = it.next();
            // Now, do something with element.
        }
        // Done, clear the list.
        mListInnerStructA.clear();
    }

    // This "struct" will be created by the java side passed to native, which
    // will use its getters.
    // Note that |@CalledByNative| has to contain the inner class name.
    static class InnerStructB {
        private final long mKey;
        private final String mValue;

        private InnerStructB(long k, String v) {
            mKey = k;
            mValue = v;
        }

        @CalledByNative("InnerStructB")
        private long getKey() {
            return mKey;
        }

        @CalledByNative("InnerStructB")
        private String getValue() {
            return mValue;
        }
    }

    List<InnerStructB> mListInnerStructB = new ArrayList<InnerStructB>();

    void iterateAndDoSomethingWithMap() {
        Iterator<InnerStructB> it = mListInnerStructB.iterator();
        while (it.hasNext()) {
            InnerStructB element = it.next();
            // Now, do something with element.
            nativeAddStructB(mNativeCPPObject, element);
        }
        nativeIterateAndDoSomethingWithStructB(mNativeCPPObject);
    }

    native void nativeAddStructB(long nativeCPPClass, InnerStructB b);
    native void nativeIterateAndDoSomethingWithStructB(long nativeCPPClass);
    native String nativeReturnAString(long nativeCPPClass);
}
