// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_ANDROID_JNI_GENERATOR_SAMPLE_FOR_TESTS_H_
#define BASE_ANDROID_JNI_GENERATOR_SAMPLE_FOR_TESTS_H_

#include <jni.h>
#include <map>
#include <string>

#include "base/android/jni_android.h"
#include "base/basictypes.h"

namespace base {
namespace android {

// This file is used to:
// - document the best practices and guidelines on JNI usage.
// - ensure sample_for_tests_jni.h compiles and the functions declared in it
// as expected.
//
// Methods are called directly from Java (except RegisterJNI). More
// documentation in SampleForTests.java
//
// For C++ to access Java methods:
// - GYP Build must be configured to generate bindings:
//  # ...
//  'targets': [
//    {
//      # An example target that will rely on JNI:
//      'target_name': 'foo',
//      'type': '<(component)',
//      # ... normal sources, defines, deps.
//      #     For each jni generated .java -> .h header file in foo_jni_headers
//      #     target there will be a single .cc file here that includes it.
//      #
//      # Add deps for JNI:
//      'conditions': [
//        ['OS == "android"', {
//          'dependencies': [
//            'foo_java',
//            'foo_jni_headers',
//          ],
//        }],
//      ],
//    },
//  ],
//  # ...
//  # Create targets for JNI:
//  'conditions': [
//    ['OS == "android"', {
//      'targets': [
//        {
//          'target_name': 'foo_jni_headers',
//          'type': 'none',
//          'sources': [
//            'java/src/org/chromium/example/jni_generator/SampleForTests.java',
//          ],
//          'variables': {
//            'jni_gen_package': 'foo',
//          },
//          'includes': [ '../../../build/jni_generator.gypi' ],
//        },
//        {
//          'target_name': 'foo_java',
//          'type': 'none',
//          'dependencies': [
//            '../../../base/base.gyp:base',
//          ],
//          'variables': {
//            'java_in_dir': 'java',
//          },
//          'includes': [ '../../../build/java.gypi' ],
//        },
//      ],
//    }],
//  ],
//
// - GN Build must be configured to generate bindings:
//  # Add import at top of file:
//  if (is_android) {
//    import("//build/config/android/rules.gni")  # For generate_jni().
//  }
//  # ...
//  # An example target that will rely on JNI:
//  component("foo") {
//    # ... normal sources, defines, deps.
//    #     For each jni generated .java -> .h header file in jni_headers
//    #     target there will be a single .cc file here that includes it.
//    #
//    # Add a dep for JNI:
//    if (is_android) {
//      deps += [ ":foo_jni" ]
//    }
//  }
//  # ...
//  # Create target for JNI:
//  if (is_android) {
//    generate_jni("jni_headers") {
//      sources = [
//        "java/src/org/chromium/example/jni_generator/SampleForTests.java",
//      ]
//      jni_package = "foo"
//    }
//    android_library("java") {
//      java_files = [
//        "java/src/org/chromium/example/jni_generator/SampleForTests.java",
//        "java/src/org/chromium/example/jni_generator/NonJniFile.java",
//      ]
//    }
//  }
//
// For C++ methods to be exposed to Java:
// - The generated RegisterNativesImpl method must be called, this is typically
//   done by having a static RegisterJNI method in the C++ class.
// - The RegisterJNI method is added to a module's collection of register
//   methods, such as: example_jni_registrar.h/cc files which call
//   base::android::RegisterNativeMethods.
//   An example_jni_registstrar.cc:
//
//     namespace {
//     const base::android::RegistrationMethod kRegisteredMethods[] = {
//         // Initial string is for debugging only.
//         { "ExampleName", base::ExampleNameAndroid::RegisterJNI },
//         { "ExampleName2", base::ExampleName2Android::RegisterJNI },
//     };
//     }  // namespace
//
//     bool RegisterModuleNameJni(JNIEnv* env) {
//       return RegisterNativeMethods(env, kRegisteredMethods,
//                                    arraysize(kRegisteredMethods));
//     }
//
//  - Each module's RegisterModuleNameJni must be called by a larger module,
//    or application during startup.
//
class CPPClass {
 public:
  CPPClass();
  ~CPPClass();

  // Register C++ methods exposed to Java using JNI.
  static bool RegisterJNI(JNIEnv* env);

  // Java @CalledByNative methods implicitly available to C++ via the _jni.h
  // file included in the .cc file.

  class InnerClass {
   public:
    jdouble MethodOtherP0(JNIEnv* env, jobject caller);
  };

  void Destroy(JNIEnv* env, jobject caller);

  jint Method(JNIEnv* env, jobject caller);

  void AddStructB(JNIEnv* env, jobject caller, jobject structb);

  void IterateAndDoSomethingWithStructB(JNIEnv* env, jobject caller);

  base::android::ScopedJavaLocalRef<jstring> ReturnAString(
      JNIEnv* env, jobject caller);

 private:
  std::map<long, std::string> map_;

  DISALLOW_COPY_AND_ASSIGN(CPPClass);
};

}  // namespace android
}  // namespace base

#endif  // BASE_ANDROID_JNI_GENERATOR_SAMPLE_FOR_TESTS_H_
