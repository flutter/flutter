/*
 * Copyright (c) 2010, Oracle and/or its affiliates. All rights reserved.
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
 *
 * This code is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 only, as
 * published by the Free Software Foundation.  Oracle designates this
 * particular file as subject to the "Classpath" exception as provided
 * by Oracle in the LICENSE file that accompanied this code.
 *
 * This code is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * version 2 for more details (a copy is included in the LICENSE file that
 * accompanied this code).
 *
 * You should have received a copy of the GNU General Public License version
 * 2 along with this work; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * Please contact Oracle, 500 Oracle Parkway, Redwood Shores, CA 94065 USA
 * or visit www.oracle.com if you need additional information or have any
 * questions.
 */

/*
 * This header file defines the data structures sent by the VM
 * through the JVMTI CompiledMethodLoad callback function via the
 * "void * compile_info" parameter. The memory pointed to by the
 * compile_info parameter may not be referenced after returning from
 * the CompiledMethodLoad callback. These are VM implementation
 * specific data structures that may evolve in future releases. A
 * JVMTI agent should interpret a non-NULL compile_info as a pointer
 * to a region of memory containing a list of records. In a typical
 * usage scenario, a JVMTI agent would cast each record to a
 * jvmtiCompiledMethodLoadRecordHeader, a struct that represents
 * arbitrary information. This struct contains a kind field to indicate
 * the kind of information being passed, and a pointer to the next
 * record. If the kind field indicates inlining information, then the
 * agent would cast the record to a jvmtiCompiledMethodLoadInlineRecord.
 * This record contains an array of PCStackInfo structs, which indicate
 * for every pc address what are the methods on the invocation stack.
 * The "methods" and "bcis" fields in each PCStackInfo struct specify a
 * 1-1 mapping between these inlined methods and their bytecode indices.
 * This can be used to derive the proper source lines of the inlined
 * methods.
 */

#ifndef _JVMTI_CMLR_H_
#define _JVMTI_CMLR_H_

enum {
    JVMTI_CMLR_MAJOR_VERSION_1 = 0x00000001,
    JVMTI_CMLR_MINOR_VERSION_0 = 0x00000000,

    JVMTI_CMLR_MAJOR_VERSION   = 0x00000001,
    JVMTI_CMLR_MINOR_VERSION   = 0x00000000

    /*
     * This comment is for the "JDK import from HotSpot" sanity check:
     * version: 1.0.0
     */
};

typedef enum {
    JVMTI_CMLR_DUMMY       = 1,
    JVMTI_CMLR_INLINE_INFO = 2
} jvmtiCMLRKind;

/*
 * Record that represents arbitrary information passed through JVMTI
 * CompiledMethodLoadEvent void pointer.
 */
typedef struct _jvmtiCompiledMethodLoadRecordHeader {
  jvmtiCMLRKind kind;     /* id for the kind of info passed in the record */
  jint majorinfoversion;  /* major and minor info version values. Init'ed */
  jint minorinfoversion;  /* to current version value in jvmtiExport.cpp. */

  struct _jvmtiCompiledMethodLoadRecordHeader* next;
} jvmtiCompiledMethodLoadRecordHeader;

/*
 * Record that gives information about the methods on the compile-time
 * stack at a specific pc address of a compiled method. Each element in
 * the methods array maps to same element in the bcis array.
 */
typedef struct _PCStackInfo {
  void* pc;             /* the pc address for this compiled method */
  jint numstackframes;  /* number of methods on the stack */
  jmethodID* methods;   /* array of numstackframes method ids */
  jint* bcis;           /* array of numstackframes bytecode indices */
} PCStackInfo;

/*
 * Record that contains inlining information for each pc address of
 * an nmethod.
 */
typedef struct _jvmtiCompiledMethodLoadInlineRecord {
  jvmtiCompiledMethodLoadRecordHeader header;  /* common header for casting */
  jint numpcs;          /* number of pc descriptors in this nmethod */
  PCStackInfo* pcinfo;  /* array of numpcs pc descriptors */
} jvmtiCompiledMethodLoadInlineRecord;

/*
 * Dummy record used to test that we can pass records with different
 * information through the void pointer provided that they can be cast
 * to a jvmtiCompiledMethodLoadRecordHeader.
 */

typedef struct _jvmtiCompiledMethodLoadDummyRecord {
  jvmtiCompiledMethodLoadRecordHeader header;  /* common header for casting */
  char message[50];
} jvmtiCompiledMethodLoadDummyRecord;

#endif
