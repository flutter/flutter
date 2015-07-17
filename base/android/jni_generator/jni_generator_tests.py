#!/usr/bin/env python
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Tests for jni_generator.py.

This test suite contains various tests for the JNI generator.
It exercises the low-level parser all the way up to the
code generator and ensures the output matches a golden
file.
"""

import difflib
import inspect
import optparse
import os
import sys
import unittest
import jni_generator
from jni_generator import CalledByNative, JniParams, NativeMethod, Param


SCRIPT_NAME = 'base/android/jni_generator/jni_generator.py'
INCLUDES = (
    'base/android/jni_generator/jni_generator_helper.h'
)

# Set this environment variable in order to regenerate the golden text
# files.
REBASELINE_ENV = 'REBASELINE'

class TestOptions(object):
  """The mock options object which is passed to the jni_generator.py script."""

  def __init__(self):
    self.namespace = None
    self.script_name = SCRIPT_NAME
    self.includes = INCLUDES
    self.pure_native_methods = False
    self.ptr_type = 'long'
    self.jni_init_native_name = None
    self.eager_called_by_natives = False
    self.cpp = 'cpp'
    self.javap = 'javap'
    self.native_exports = False
    self.native_exports_optional = False

class TestGenerator(unittest.TestCase):
  def assertObjEquals(self, first, second):
    dict_first = first.__dict__
    dict_second = second.__dict__
    self.assertEquals(dict_first.keys(), dict_second.keys())
    for key, value in dict_first.iteritems():
      if (type(value) is list and len(value) and
          isinstance(type(value[0]), object)):
        self.assertListEquals(value, second.__getattribute__(key))
      else:
        actual = second.__getattribute__(key)
        self.assertEquals(value, actual,
                          'Key ' + key + ': ' + str(value) + '!=' + str(actual))

  def assertListEquals(self, first, second):
    self.assertEquals(len(first), len(second))
    for i in xrange(len(first)):
      if isinstance(first[i], object):
        self.assertObjEquals(first[i], second[i])
      else:
        self.assertEquals(first[i], second[i])

  def assertTextEquals(self, golden_text, generated_text):
    if not self.compareText(golden_text, generated_text):
      self.fail('Golden text mismatch.')

  def compareText(self, golden_text, generated_text):
    def FilterText(text):
      return [
          l.strip() for l in text.split('\n')
          if not l.startswith('// Copyright')
      ]
    stripped_golden = FilterText(golden_text)
    stripped_generated = FilterText(generated_text)
    if stripped_golden == stripped_generated:
      return True
    print self.id()
    for line in difflib.context_diff(stripped_golden, stripped_generated):
      print line
    print '\n\nGenerated'
    print '=' * 80
    print generated_text
    print '=' * 80
    print 'Run with:'
    print 'REBASELINE=1', sys.argv[0]
    print 'to regenerate the data files.'

  def _ReadGoldenFile(self, golden_file):
    if not os.path.exists(golden_file):
      return None
    with file(golden_file, 'r') as f:
      return f.read()

  def assertGoldenTextEquals(self, generated_text):
    script_dir = os.path.dirname(sys.argv[0])
    # This is the caller test method.
    caller = inspect.stack()[1][3]
    self.assertTrue(caller.startswith('test'),
                    'assertGoldenTextEquals can only be called from a '
                    'test* method, not %s' % caller)
    golden_file = os.path.join(script_dir, caller + '.golden')
    golden_text = self._ReadGoldenFile(golden_file)
    if os.environ.get(REBASELINE_ENV):
      if golden_text != generated_text:
        with file(golden_file, 'w') as f:
          f.write(generated_text)
      return
    self.assertTextEquals(golden_text, generated_text)

  def testInspectCaller(self):
    def willRaise():
      # This function can only be called from a test* method.
      self.assertGoldenTextEquals('')
    self.assertRaises(AssertionError, willRaise)

  def testNatives(self):
    test_data = """"
    interface OnFrameAvailableListener {}
    private native int nativeInit();
    private native void nativeDestroy(int nativeChromeBrowserProvider);
    private native long nativeAddBookmark(
            int nativeChromeBrowserProvider,
            String url, String title, boolean isFolder, long parentId);
    private static native String nativeGetDomainAndRegistry(String url);
    private static native void nativeCreateHistoricalTabFromState(
            byte[] state, int tab_index);
    private native byte[] nativeGetStateAsByteArray(View view);
    private static native String[] nativeGetAutofillProfileGUIDs();
    private native void nativeSetRecognitionResults(
            int sessionId, String[] results);
    private native long nativeAddBookmarkFromAPI(
            int nativeChromeBrowserProvider,
            String url, Long created, Boolean isBookmark,
            Long date, byte[] favicon, String title, Integer visits);
    native int nativeFindAll(String find);
    private static native OnFrameAvailableListener nativeGetInnerClass();
    private native Bitmap nativeQueryBitmap(
            int nativeChromeBrowserProvider,
            String[] projection, String selection,
            String[] selectionArgs, String sortOrder);
    private native void nativeGotOrientation(
            int nativeDataFetcherImplAndroid,
            double alpha, double beta, double gamma);
    """
    jni_generator.JniParams.SetFullyQualifiedClass(
        'org/chromium/example/jni_generator/SampleForTests')
    jni_generator.JniParams.ExtractImportsAndInnerClasses(test_data)
    natives = jni_generator.ExtractNatives(test_data, 'int')
    golden_natives = [
        NativeMethod(return_type='int', static=False,
                     name='Init',
                     params=[],
                     java_class_name=None,
                     type='function'),
        NativeMethod(return_type='void', static=False, name='Destroy',
                     params=[Param(datatype='int',
                                   name='nativeChromeBrowserProvider')],
                     java_class_name=None,
                     type='method',
                     p0_type='ChromeBrowserProvider'),
        NativeMethod(return_type='long', static=False, name='AddBookmark',
                     params=[Param(datatype='int',
                                   name='nativeChromeBrowserProvider'),
                             Param(datatype='String',
                                   name='url'),
                             Param(datatype='String',
                                   name='title'),
                             Param(datatype='boolean',
                                   name='isFolder'),
                             Param(datatype='long',
                                   name='parentId')],
                     java_class_name=None,
                     type='method',
                     p0_type='ChromeBrowserProvider'),
        NativeMethod(return_type='String', static=True,
                     name='GetDomainAndRegistry',
                     params=[Param(datatype='String',
                                   name='url')],
                     java_class_name=None,
                     type='function'),
        NativeMethod(return_type='void', static=True,
                     name='CreateHistoricalTabFromState',
                     params=[Param(datatype='byte[]',
                                   name='state'),
                             Param(datatype='int',
                                   name='tab_index')],
                     java_class_name=None,
                     type='function'),
        NativeMethod(return_type='byte[]', static=False,
                     name='GetStateAsByteArray',
                     params=[Param(datatype='View', name='view')],
                     java_class_name=None,
                     type='function'),
        NativeMethod(return_type='String[]', static=True,
                     name='GetAutofillProfileGUIDs', params=[],
                     java_class_name=None,
                     type='function'),
        NativeMethod(return_type='void', static=False,
                     name='SetRecognitionResults',
                     params=[Param(datatype='int', name='sessionId'),
                             Param(datatype='String[]', name='results')],
                     java_class_name=None,
                     type='function'),
        NativeMethod(return_type='long', static=False,
                     name='AddBookmarkFromAPI',
                     params=[Param(datatype='int',
                                   name='nativeChromeBrowserProvider'),
                             Param(datatype='String',
                                   name='url'),
                             Param(datatype='Long',
                                   name='created'),
                             Param(datatype='Boolean',
                                   name='isBookmark'),
                             Param(datatype='Long',
                                   name='date'),
                             Param(datatype='byte[]',
                                   name='favicon'),
                             Param(datatype='String',
                                   name='title'),
                             Param(datatype='Integer',
                                   name='visits')],
                     java_class_name=None,
                     type='method',
                     p0_type='ChromeBrowserProvider'),
        NativeMethod(return_type='int', static=False,
                     name='FindAll',
                     params=[Param(datatype='String',
                                   name='find')],
                     java_class_name=None,
                     type='function'),
        NativeMethod(return_type='OnFrameAvailableListener', static=True,
                     name='GetInnerClass',
                     params=[],
                     java_class_name=None,
                     type='function'),
        NativeMethod(return_type='Bitmap',
                     static=False,
                     name='QueryBitmap',
                     params=[Param(datatype='int',
                                   name='nativeChromeBrowserProvider'),
                             Param(datatype='String[]',
                                   name='projection'),
                             Param(datatype='String',
                                   name='selection'),
                             Param(datatype='String[]',
                                   name='selectionArgs'),
                             Param(datatype='String',
                                   name='sortOrder'),
                            ],
                     java_class_name=None,
                     type='method',
                     p0_type='ChromeBrowserProvider'),
        NativeMethod(return_type='void', static=False,
                     name='GotOrientation',
                     params=[Param(datatype='int',
                                   name='nativeDataFetcherImplAndroid'),
                             Param(datatype='double',
                                   name='alpha'),
                             Param(datatype='double',
                                   name='beta'),
                             Param(datatype='double',
                                   name='gamma'),
                            ],
                     java_class_name=None,
                     type='method',
                     p0_type='content::DataFetcherImplAndroid'),
    ]
    self.assertListEquals(golden_natives, natives)
    h = jni_generator.InlHeaderFileGenerator('', 'org/chromium/TestJni',
                                             natives, [], [], TestOptions())
    self.assertGoldenTextEquals(h.GetContent())

  def testInnerClassNatives(self):
    test_data = """
    class MyInnerClass {
      @NativeCall("MyInnerClass")
      private native int nativeInit();
    }
    """
    natives = jni_generator.ExtractNatives(test_data, 'int')
    golden_natives = [
        NativeMethod(return_type='int', static=False,
                     name='Init', params=[],
                     java_class_name='MyInnerClass',
                     type='function')
    ]
    self.assertListEquals(golden_natives, natives)
    h = jni_generator.InlHeaderFileGenerator('', 'org/chromium/TestJni',
                                             natives, [], [], TestOptions())
    self.assertGoldenTextEquals(h.GetContent())

  def testInnerClassNativesMultiple(self):
    test_data = """
    class MyInnerClass {
      @NativeCall("MyInnerClass")
      private native int nativeInit();
    }
    class MyOtherInnerClass {
      @NativeCall("MyOtherInnerClass")
      private native int nativeInit();
    }
    """
    natives = jni_generator.ExtractNatives(test_data, 'int')
    golden_natives = [
        NativeMethod(return_type='int', static=False,
                     name='Init', params=[],
                     java_class_name='MyInnerClass',
                     type='function'),
        NativeMethod(return_type='int', static=False,
                     name='Init', params=[],
                     java_class_name='MyOtherInnerClass',
                     type='function')
    ]
    self.assertListEquals(golden_natives, natives)
    h = jni_generator.InlHeaderFileGenerator('', 'org/chromium/TestJni',
                                             natives, [], [], TestOptions())
    self.assertGoldenTextEquals(h.GetContent())

  def testInnerClassNativesBothInnerAndOuter(self):
    test_data = """
    class MyOuterClass {
      private native int nativeInit();
      class MyOtherInnerClass {
        @NativeCall("MyOtherInnerClass")
        private native int nativeInit();
      }
    }
    """
    natives = jni_generator.ExtractNatives(test_data, 'int')
    golden_natives = [
        NativeMethod(return_type='int', static=False,
                     name='Init', params=[],
                     java_class_name=None,
                     type='function'),
        NativeMethod(return_type='int', static=False,
                     name='Init', params=[],
                     java_class_name='MyOtherInnerClass',
                     type='function')
    ]
    self.assertListEquals(golden_natives, natives)
    h = jni_generator.InlHeaderFileGenerator('', 'org/chromium/TestJni',
                                             natives, [], [], TestOptions())
    self.assertGoldenTextEquals(h.GetContent())

  def testCalledByNatives(self):
    test_data = """"
    import android.graphics.Bitmap;
    import android.view.View;
    import java.io.InputStream;
    import java.util.List;

    class InnerClass {}

    @CalledByNative
    InnerClass showConfirmInfoBar(int nativeInfoBar,
            String buttonOk, String buttonCancel, String title, Bitmap icon) {
        InfoBar infobar = new ConfirmInfoBar(nativeInfoBar, mContext,
                                             buttonOk, buttonCancel,
                                             title, icon);
        return infobar;
    }
    @CalledByNative
    InnerClass showAutoLoginInfoBar(int nativeInfoBar,
            String realm, String account, String args) {
        AutoLoginInfoBar infobar = new AutoLoginInfoBar(nativeInfoBar, mContext,
                realm, account, args);
        if (infobar.displayedAccountCount() == 0)
            infobar = null;
        return infobar;
    }
    @CalledByNative("InfoBar")
    void dismiss();
    @SuppressWarnings("unused")
    @CalledByNative
    private static boolean shouldShowAutoLogin(View view,
            String realm, String account, String args) {
        AccountManagerContainer accountManagerContainer =
            new AccountManagerContainer((Activity)contentView.getContext(),
            realm, account, args);
        String[] logins = accountManagerContainer.getAccountLogins(null);
        return logins.length != 0;
    }
    @CalledByNative
    static InputStream openUrl(String url) {
        return null;
    }
    @CalledByNative
    private void activateHardwareAcceleration(final boolean activated,
            final int iPid, final int iType,
            final int iPrimaryID, final int iSecondaryID) {
      if (!activated) {
          return
      }
    }
    @CalledByNativeUnchecked
    private void uncheckedCall(int iParam);

    @CalledByNative
    public byte[] returnByteArray();

    @CalledByNative
    public boolean[] returnBooleanArray();

    @CalledByNative
    public char[] returnCharArray();

    @CalledByNative
    public short[] returnShortArray();

    @CalledByNative
    public int[] returnIntArray();

    @CalledByNative
    public long[] returnLongArray();

    @CalledByNative
    public double[] returnDoubleArray();

    @CalledByNative
    public Object[] returnObjectArray();

    @CalledByNative
    public byte[][] returnArrayOfByteArray();

    @CalledByNative
    public Bitmap.CompressFormat getCompressFormat();

    @CalledByNative
    public List<Bitmap.CompressFormat> getCompressFormatList();
    """
    jni_generator.JniParams.SetFullyQualifiedClass('org/chromium/Foo')
    jni_generator.JniParams.ExtractImportsAndInnerClasses(test_data)
    called_by_natives = jni_generator.ExtractCalledByNatives(test_data)
    golden_called_by_natives = [
        CalledByNative(
            return_type='InnerClass',
            system_class=False,
            static=False,
            name='showConfirmInfoBar',
            method_id_var_name='showConfirmInfoBar',
            java_class_name='',
            params=[Param(datatype='int', name='nativeInfoBar'),
                    Param(datatype='String', name='buttonOk'),
                    Param(datatype='String', name='buttonCancel'),
                    Param(datatype='String', name='title'),
                    Param(datatype='Bitmap', name='icon')],
            env_call=('Object', ''),
            unchecked=False,
        ),
        CalledByNative(
            return_type='InnerClass',
            system_class=False,
            static=False,
            name='showAutoLoginInfoBar',
            method_id_var_name='showAutoLoginInfoBar',
            java_class_name='',
            params=[Param(datatype='int', name='nativeInfoBar'),
                    Param(datatype='String', name='realm'),
                    Param(datatype='String', name='account'),
                    Param(datatype='String', name='args')],
            env_call=('Object', ''),
            unchecked=False,
        ),
        CalledByNative(
            return_type='void',
            system_class=False,
            static=False,
            name='dismiss',
            method_id_var_name='dismiss',
            java_class_name='InfoBar',
            params=[],
            env_call=('Void', ''),
            unchecked=False,
        ),
        CalledByNative(
            return_type='boolean',
            system_class=False,
            static=True,
            name='shouldShowAutoLogin',
            method_id_var_name='shouldShowAutoLogin',
            java_class_name='',
            params=[Param(datatype='View', name='view'),
                    Param(datatype='String', name='realm'),
                    Param(datatype='String', name='account'),
                    Param(datatype='String', name='args')],
            env_call=('Boolean', ''),
            unchecked=False,
        ),
        CalledByNative(
            return_type='InputStream',
            system_class=False,
            static=True,
            name='openUrl',
            method_id_var_name='openUrl',
            java_class_name='',
            params=[Param(datatype='String', name='url')],
            env_call=('Object', ''),
            unchecked=False,
        ),
        CalledByNative(
            return_type='void',
            system_class=False,
            static=False,
            name='activateHardwareAcceleration',
            method_id_var_name='activateHardwareAcceleration',
            java_class_name='',
            params=[Param(datatype='boolean', name='activated'),
                    Param(datatype='int', name='iPid'),
                    Param(datatype='int', name='iType'),
                    Param(datatype='int', name='iPrimaryID'),
                    Param(datatype='int', name='iSecondaryID'),
                   ],
            env_call=('Void', ''),
            unchecked=False,
        ),
        CalledByNative(
            return_type='void',
            system_class=False,
            static=False,
            name='uncheckedCall',
            method_id_var_name='uncheckedCall',
            java_class_name='',
            params=[Param(datatype='int', name='iParam')],
            env_call=('Void', ''),
            unchecked=True,
        ),
        CalledByNative(
            return_type='byte[]',
            system_class=False,
            static=False,
            name='returnByteArray',
            method_id_var_name='returnByteArray',
            java_class_name='',
            params=[],
            env_call=('Void', ''),
            unchecked=False,
        ),
        CalledByNative(
            return_type='boolean[]',
            system_class=False,
            static=False,
            name='returnBooleanArray',
            method_id_var_name='returnBooleanArray',
            java_class_name='',
            params=[],
            env_call=('Void', ''),
            unchecked=False,
        ),
        CalledByNative(
            return_type='char[]',
            system_class=False,
            static=False,
            name='returnCharArray',
            method_id_var_name='returnCharArray',
            java_class_name='',
            params=[],
            env_call=('Void', ''),
            unchecked=False,
        ),
        CalledByNative(
            return_type='short[]',
            system_class=False,
            static=False,
            name='returnShortArray',
            method_id_var_name='returnShortArray',
            java_class_name='',
            params=[],
            env_call=('Void', ''),
            unchecked=False,
        ),
        CalledByNative(
            return_type='int[]',
            system_class=False,
            static=False,
            name='returnIntArray',
            method_id_var_name='returnIntArray',
            java_class_name='',
            params=[],
            env_call=('Void', ''),
            unchecked=False,
        ),
        CalledByNative(
            return_type='long[]',
            system_class=False,
            static=False,
            name='returnLongArray',
            method_id_var_name='returnLongArray',
            java_class_name='',
            params=[],
            env_call=('Void', ''),
            unchecked=False,
        ),
        CalledByNative(
            return_type='double[]',
            system_class=False,
            static=False,
            name='returnDoubleArray',
            method_id_var_name='returnDoubleArray',
            java_class_name='',
            params=[],
            env_call=('Void', ''),
            unchecked=False,
        ),
        CalledByNative(
            return_type='Object[]',
            system_class=False,
            static=False,
            name='returnObjectArray',
            method_id_var_name='returnObjectArray',
            java_class_name='',
            params=[],
            env_call=('Void', ''),
            unchecked=False,
        ),
        CalledByNative(
            return_type='byte[][]',
            system_class=False,
            static=False,
            name='returnArrayOfByteArray',
            method_id_var_name='returnArrayOfByteArray',
            java_class_name='',
            params=[],
            env_call=('Void', ''),
            unchecked=False,
        ),
        CalledByNative(
            return_type='Bitmap.CompressFormat',
            system_class=False,
            static=False,
            name='getCompressFormat',
            method_id_var_name='getCompressFormat',
            java_class_name='',
            params=[],
            env_call=('Void', ''),
            unchecked=False,
        ),
        CalledByNative(
            return_type='List<Bitmap.CompressFormat>',
            system_class=False,
            static=False,
            name='getCompressFormatList',
            method_id_var_name='getCompressFormatList',
            java_class_name='',
            params=[],
            env_call=('Void', ''),
            unchecked=False,
        ),
    ]
    self.assertListEquals(golden_called_by_natives, called_by_natives)
    h = jni_generator.InlHeaderFileGenerator('', 'org/chromium/TestJni',
                                             [], called_by_natives, [],
                                             TestOptions())
    self.assertGoldenTextEquals(h.GetContent())

  def testCalledByNativeParseError(self):
    try:
      jni_generator.ExtractCalledByNatives("""
@CalledByNative
public static int foo(); // This one is fine

@CalledByNative
scooby doo
""")
      self.fail('Expected a ParseError')
    except jni_generator.ParseError, e:
      self.assertEquals(('@CalledByNative', 'scooby doo'), e.context_lines)

  def testFullyQualifiedClassName(self):
    contents = """
// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.content.browser;

import org.chromium.base.BuildInfo;
"""
    self.assertEquals('org/chromium/content/browser/Foo',
                      jni_generator.ExtractFullyQualifiedJavaClassName(
                          'org/chromium/content/browser/Foo.java', contents))
    self.assertEquals('org/chromium/content/browser/Foo',
                      jni_generator.ExtractFullyQualifiedJavaClassName(
                          'frameworks/Foo.java', contents))
    self.assertRaises(SyntaxError,
                      jni_generator.ExtractFullyQualifiedJavaClassName,
                      'com/foo/Bar', 'no PACKAGE line')

  def testMethodNameMangling(self):
    self.assertEquals('closeV',
        jni_generator.GetMangledMethodName('close', [], 'void'))
    self.assertEquals('readI_AB_I_I',
        jni_generator.GetMangledMethodName('read',
            [Param(name='p1',
                   datatype='byte[]'),
             Param(name='p2',
                   datatype='int'),
             Param(name='p3',
                   datatype='int'),],
             'int'))
    self.assertEquals('openJIIS_JLS',
        jni_generator.GetMangledMethodName('open',
            [Param(name='p1',
                   datatype='java/lang/String'),],
             'java/io/InputStream'))

  def testFromJavaPGenerics(self):
    contents = """
public abstract class java.util.HashSet<T> extends java.util.AbstractSet<E>
      implements java.util.Set<E>, java.lang.Cloneable, java.io.Serializable {
    public void dummy();
  Signature: ()V
}
"""
    jni_from_javap = jni_generator.JNIFromJavaP(contents.split('\n'),
                                                TestOptions())
    self.assertEquals(1, len(jni_from_javap.called_by_natives))
    self.assertGoldenTextEquals(jni_from_javap.GetContent())

  def testSnippnetJavap6_7_8(self):
    content_javap6 = """
public class java.util.HashSet {
public boolean add(java.lang.Object);
 Signature: (Ljava/lang/Object;)Z
}
"""

    content_javap7 = """
public class java.util.HashSet {
public boolean add(E);
  Signature: (Ljava/lang/Object;)Z
}
"""

    content_javap8 = """
public class java.util.HashSet {
  public boolean add(E);
    descriptor: (Ljava/lang/Object;)Z
}
"""

    jni_from_javap6 = jni_generator.JNIFromJavaP(content_javap6.split('\n'),
                                                 TestOptions())
    jni_from_javap7 = jni_generator.JNIFromJavaP(content_javap7.split('\n'),
                                                 TestOptions())
    jni_from_javap8 = jni_generator.JNIFromJavaP(content_javap8.split('\n'),
                                                 TestOptions())
    self.assertTrue(jni_from_javap6.GetContent())
    self.assertTrue(jni_from_javap7.GetContent())
    self.assertTrue(jni_from_javap8.GetContent())
    # Ensure the javap7 is correctly parsed and uses the Signature field rather
    # than the "E" parameter.
    self.assertTextEquals(jni_from_javap6.GetContent(),
                          jni_from_javap7.GetContent())
    # Ensure the javap8 is correctly parsed and uses the descriptor field.
    self.assertTextEquals(jni_from_javap7.GetContent(),
                          jni_from_javap8.GetContent())

  def testFromJavaP(self):
    contents = self._ReadGoldenFile(os.path.join(os.path.dirname(sys.argv[0]),
        'testInputStream.javap'))
    jni_from_javap = jni_generator.JNIFromJavaP(contents.split('\n'),
                                                TestOptions())
    self.assertEquals(10, len(jni_from_javap.called_by_natives))
    self.assertGoldenTextEquals(jni_from_javap.GetContent())

  def testConstantsFromJavaP(self):
    for f in ['testMotionEvent.javap', 'testMotionEvent.javap7']:
      contents = self._ReadGoldenFile(os.path.join(os.path.dirname(sys.argv[0]),
          f))
      jni_from_javap = jni_generator.JNIFromJavaP(contents.split('\n'),
                                                  TestOptions())
      self.assertEquals(86, len(jni_from_javap.called_by_natives))
      self.assertGoldenTextEquals(jni_from_javap.GetContent())

  def testREForNatives(self):
    # We should not match "native SyncSetupFlow" inside the comment.
    test_data = """
    /**
     * Invoked when the setup process is complete so we can disconnect from the
     * native-side SyncSetupFlowHandler.
     */
    public void destroy() {
        Log.v(TAG, "Destroying native SyncSetupFlow");
        if (mNativeSyncSetupFlow != 0) {
            nativeSyncSetupEnded(mNativeSyncSetupFlow);
            mNativeSyncSetupFlow = 0;
        }
    }
    private native void nativeSyncSetupEnded(
        int nativeAndroidSyncSetupFlowHandler);
    """
    jni_from_java = jni_generator.JNIFromJavaSource(
        test_data, 'foo/bar', TestOptions())

  def testRaisesOnNonJNIMethod(self):
    test_data = """
    class MyInnerClass {
      private int Foo(int p0) {
      }
    }
    """
    self.assertRaises(SyntaxError,
                      jni_generator.JNIFromJavaSource,
                      test_data, 'foo/bar', TestOptions())

  def testJniSelfDocumentingExample(self):
    script_dir = os.path.dirname(sys.argv[0])
    content = file(os.path.join(script_dir,
        'java/src/org/chromium/example/jni_generator/SampleForTests.java')
        ).read()
    golden_file = os.path.join(script_dir, 'golden_sample_for_tests_jni.h')
    golden_content = file(golden_file).read()
    jni_from_java = jni_generator.JNIFromJavaSource(
        content, 'org/chromium/example/jni_generator/SampleForTests',
        TestOptions())
    generated_text = jni_from_java.GetContent()
    if not self.compareText(golden_content, generated_text):
      if os.environ.get(REBASELINE_ENV):
        with file(golden_file, 'w') as f:
          f.write(generated_text)
        return
      self.fail('testJniSelfDocumentingExample')

  def testNoWrappingPreprocessorLines(self):
    test_data = """
    package com.google.lookhowextremelylongiam.snarf.icankeepthisupallday;

    class ReallyLongClassNamesAreAllTheRage {
        private static native int nativeTest();
    }
    """
    jni_from_java = jni_generator.JNIFromJavaSource(
        test_data, ('com/google/lookhowextremelylongiam/snarf/'
                    'icankeepthisupallday/ReallyLongClassNamesAreAllTheRage'),
        TestOptions())
    jni_lines = jni_from_java.GetContent().split('\n')
    line = filter(lambda line: line.lstrip().startswith('#ifndef'),
                  jni_lines)[0]
    self.assertTrue(len(line) > 80,
                    ('Expected #ifndef line to be > 80 chars: ', line))

  def testJarJarRemapping(self):
    test_data = """
    package org.chromium.example.jni_generator;

    import org.chromium.example2.Test;

    import org.chromium.example3.PrefixFoo;
    import org.chromium.example3.Prefix;
    import org.chromium.example3.Bar$Inner;

    class Example {
      private static native void nativeTest(Test t);
      private static native void nativeTest2(PrefixFoo t);
      private static native void nativeTest3(Prefix t);
      private static native void nativeTest4(Bar$Inner t);
    }
    """
    jni_generator.JniParams.SetJarJarMappings(
        """rule org.chromium.example.** com.test.@1
        rule org.chromium.example2.** org.test2.@1
        rule org.chromium.example3.Prefix org.test3.Test
        rule org.chromium.example3.Bar$** org.test3.TestBar$@1""")
    jni_from_java = jni_generator.JNIFromJavaSource(
        test_data, 'org/chromium/example/jni_generator/Example', TestOptions())
    jni_generator.JniParams.SetJarJarMappings('')
    self.assertGoldenTextEquals(jni_from_java.GetContent())

  def testImports(self):
    import_header = """
// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.content.app;

import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.graphics.SurfaceTexture;
import android.os.Bundle;
import android.os.IBinder;
import android.os.ParcelFileDescriptor;
import android.os.Process;
import android.os.RemoteException;
import android.util.Log;
import android.view.Surface;

import java.util.ArrayList;

import org.chromium.base.CalledByNative;
import org.chromium.base.JNINamespace;
import org.chromium.content.app.ContentMain;
import org.chromium.content.browser.SandboxedProcessConnection;
import org.chromium.content.common.ISandboxedProcessCallback;
import org.chromium.content.common.ISandboxedProcessService;
import org.chromium.content.common.WillNotRaise.AnException;
import org.chromium.content.common.WillRaise.AnException;

import static org.chromium.Bar.Zoo;

class Foo {
  public static class BookmarkNode implements Parcelable {
  }
  public interface PasswordListObserver {
  }
}
    """
    jni_generator.JniParams.SetFullyQualifiedClass(
        'org/chromium/content/app/Foo')
    jni_generator.JniParams.ExtractImportsAndInnerClasses(import_header)
    self.assertTrue('Lorg/chromium/content/common/ISandboxedProcessService' in
                    jni_generator.JniParams._imports)
    self.assertTrue('Lorg/chromium/Bar/Zoo' in
                    jni_generator.JniParams._imports)
    self.assertTrue('Lorg/chromium/content/app/Foo$BookmarkNode' in
                    jni_generator.JniParams._inner_classes)
    self.assertTrue('Lorg/chromium/content/app/Foo$PasswordListObserver' in
                    jni_generator.JniParams._inner_classes)
    self.assertEquals('Lorg/chromium/content/app/ContentMain$Inner;',
                      jni_generator.JniParams.JavaToJni('ContentMain.Inner'))
    self.assertRaises(SyntaxError,
                      jni_generator.JniParams.JavaToJni,
                      'AnException')

  def testJniParamsJavaToJni(self):
    self.assertTextEquals('I', JniParams.JavaToJni('int'))
    self.assertTextEquals('[B', JniParams.JavaToJni('byte[]'))
    self.assertTextEquals(
        '[Ljava/nio/ByteBuffer;', JniParams.JavaToJni('java/nio/ByteBuffer[]'))

  def testNativesLong(self):
    test_options = TestOptions()
    test_options.ptr_type = 'long'
    test_data = """"
    private native void nativeDestroy(long nativeChromeBrowserProvider);
    """
    jni_generator.JniParams.ExtractImportsAndInnerClasses(test_data)
    natives = jni_generator.ExtractNatives(test_data, test_options.ptr_type)
    golden_natives = [
        NativeMethod(return_type='void', static=False, name='Destroy',
                     params=[Param(datatype='long',
                                   name='nativeChromeBrowserProvider')],
                     java_class_name=None,
                     type='method',
                     p0_type='ChromeBrowserProvider',
                     ptr_type=test_options.ptr_type),
    ]
    self.assertListEquals(golden_natives, natives)
    h = jni_generator.InlHeaderFileGenerator('', 'org/chromium/TestJni',
                                             natives, [], [], test_options)
    self.assertGoldenTextEquals(h.GetContent())

  def testPureNativeMethodsOption(self):
    test_data = """
    package org.chromium.example.jni_generator;

    /** The pointer to the native Test. */
    long nativeTest;

    class Test {
        private static native long nativeMethod(long nativeTest, int arg1);
    }
    """
    options = TestOptions()
    options.pure_native_methods = True
    jni_from_java = jni_generator.JNIFromJavaSource(
        test_data, 'org/chromium/example/jni_generator/Test', options)
    self.assertGoldenTextEquals(jni_from_java.GetContent())

  def testJNIInitNativeNameOption(self):
    test_data = """
    package org.chromium.example.jni_generator;

    /** The pointer to the native Test. */
    long nativeTest;

    class Test {
        private static native boolean nativeInitNativeClass();
        private static native int nativeMethod(long nativeTest, int arg1);
    }
    """
    options = TestOptions()
    options.jni_init_native_name = 'nativeInitNativeClass'
    jni_from_java = jni_generator.JNIFromJavaSource(
        test_data, 'org/chromium/example/jni_generator/Test', options)
    self.assertGoldenTextEquals(jni_from_java.GetContent())

  def testEagerCalledByNativesOption(self):
    test_data = """
    package org.chromium.example.jni_generator;

    /** The pointer to the native Test. */
    long nativeTest;

    class Test {
        private static native boolean nativeInitNativeClass();
        private static native int nativeMethod(long nativeTest, int arg1);
        @CalledByNative
        private void testMethodWithParam(int iParam);
        @CalledByNative
        private static int testStaticMethodWithParam(int iParam);
        @CalledByNative
        private static double testMethodWithNoParam();
        @CalledByNative
        private static String testStaticMethodWithNoParam();
    }
    """
    options = TestOptions()
    options.jni_init_native_name = 'nativeInitNativeClass'
    options.eager_called_by_natives = True
    jni_from_java = jni_generator.JNIFromJavaSource(
        test_data, 'org/chromium/example/jni_generator/Test', options)
    self.assertGoldenTextEquals(jni_from_java.GetContent())

  def runNativeExportsOption(self, optional):
    test_data = """
    package org.chromium.example.jni_generator;

    /** The pointer to the native Test. */
    long nativeTest;

    class Test {
        private static native boolean nativeInitNativeClass();
        private static native int nativeStaticMethod(long nativeTest, int arg1);
        private native int nativeMethod(long nativeTest, int arg1);
        @CalledByNative
        private void testMethodWithParam(int iParam);
        @CalledByNative
        private String testMethodWithParamAndReturn(int iParam);
        @CalledByNative
        private static int testStaticMethodWithParam(int iParam);
        @CalledByNative
        private static double testMethodWithNoParam();
        @CalledByNative
        private static String testStaticMethodWithNoParam();

        class MyInnerClass {
          @NativeCall("MyInnerClass")
          private native int nativeInit();
        }
        class MyOtherInnerClass {
          @NativeCall("MyOtherInnerClass")
          private native int nativeInit();
        }
    }
    """
    options = TestOptions()
    options.jni_init_native_name = 'nativeInitNativeClass'
    options.native_exports = True
    options.native_exports_optional = optional
    jni_from_java = jni_generator.JNIFromJavaSource(
        test_data, 'org/chromium/example/jni_generator/SampleForTests', options)
    return jni_from_java.GetContent()

  def testNativeExportsOption(self):
    content = self.runNativeExportsOption(False)
    self.assertGoldenTextEquals(content)

  def testNativeExportsOptionalOption(self):
    content = self.runNativeExportsOption(True)
    self.assertGoldenTextEquals(content)

  def testOuterInnerRaises(self):
    test_data = """
    package org.chromium.media;

    @CalledByNative
    static int getCaptureFormatWidth(VideoCapture.CaptureFormat format) {
        return format.getWidth();
    }
    """
    def willRaise():
      jni_generator.JNIFromJavaSource(
          test_data,
          'org/chromium/media/VideoCaptureFactory',
          TestOptions())
    self.assertRaises(SyntaxError, willRaise)

  def testSingleJNIAdditionalImport(self):
    test_data = """
    package org.chromium.foo;

    @JNIAdditionalImport(Bar.class)
    class Foo {

    @CalledByNative
    private static void calledByNative(Bar.Callback callback) {
    }

    private static native void nativeDoSomething(Bar.Callback callback);
    }
    """
    jni_from_java = jni_generator.JNIFromJavaSource(test_data,
                                                    'org/chromium/foo/Foo',
                                                    TestOptions())
    self.assertGoldenTextEquals(jni_from_java.GetContent())

  def testMultipleJNIAdditionalImport(self):
    test_data = """
    package org.chromium.foo;

    @JNIAdditionalImport({Bar1.class, Bar2.class})
    class Foo {

    @CalledByNative
    private static void calledByNative(Bar1.Callback callback1,
                                       Bar2.Callback callback2) {
    }

    private static native void nativeDoSomething(Bar1.Callback callback1,
                                                 Bar2.Callback callback2);
    }
    """
    jni_from_java = jni_generator.JNIFromJavaSource(test_data,
                                                    'org/chromium/foo/Foo',
                                                    TestOptions())
    self.assertGoldenTextEquals(jni_from_java.GetContent())


def TouchStamp(stamp_path):
  dir_name = os.path.dirname(stamp_path)
  if not os.path.isdir(dir_name):
    os.makedirs()

  with open(stamp_path, 'a'):
    os.utime(stamp_path, None)


def main(argv):
  parser = optparse.OptionParser()
  parser.add_option('--stamp', help='Path to touch on success.')
  options, _ = parser.parse_args(argv[1:])

  test_result = unittest.main(argv=argv[0:1], exit=False)

  if test_result.result.wasSuccessful() and options.stamp:
    TouchStamp(options.stamp)

  return not test_result.result.wasSuccessful()


if __name__ == '__main__':
  sys.exit(main(sys.argv))
