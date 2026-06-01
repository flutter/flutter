/*
 * Copyright (c) 2003, 2016, Oracle and/or its affiliates. All rights reserved.
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
 * Java Debug Wire Protocol Transport Service Provider Interface.
 */

#ifndef JDWPTRANSPORT_H
#define JDWPTRANSPORT_H

#include "jni.h"

enum {
    JDWPTRANSPORT_VERSION_1_0 = 0x00010000
};

#ifdef __cplusplus
extern "C" {
#endif

struct jdwpTransportNativeInterface_;

struct _jdwpTransportEnv;

#ifdef __cplusplus
typedef _jdwpTransportEnv jdwpTransportEnv;
#else
typedef const struct jdwpTransportNativeInterface_ *jdwpTransportEnv;
#endif /* __cplusplus */

/*
 * Errors. Universal errors with JVMTI/JVMDI equivalents keep the
 * values the same.
 */
typedef enum {
    JDWPTRANSPORT_ERROR_NONE = 0,
    JDWPTRANSPORT_ERROR_ILLEGAL_ARGUMENT = 103,
    JDWPTRANSPORT_ERROR_OUT_OF_MEMORY = 110,
    JDWPTRANSPORT_ERROR_INTERNAL = 113,
    JDWPTRANSPORT_ERROR_ILLEGAL_STATE = 201,
    JDWPTRANSPORT_ERROR_IO_ERROR = 202,
    JDWPTRANSPORT_ERROR_TIMEOUT = 203,
    JDWPTRANSPORT_ERROR_MSG_NOT_AVAILABLE = 204
} jdwpTransportError;


/*
 * Structure to define capabilities
 */
typedef struct {
    unsigned int can_timeout_attach     :1;
    unsigned int can_timeout_accept     :1;
    unsigned int can_timeout_handshake  :1;
    unsigned int reserved3              :1;
    unsigned int reserved4              :1;
    unsigned int reserved5              :1;
    unsigned int reserved6              :1;
    unsigned int reserved7              :1;
    unsigned int reserved8              :1;
    unsigned int reserved9              :1;
    unsigned int reserved10             :1;
    unsigned int reserved11             :1;
    unsigned int reserved12             :1;
    unsigned int reserved13             :1;
    unsigned int reserved14             :1;
    unsigned int reserved15             :1;
} JDWPTransportCapabilities;


/*
 * Structures to define packet layout.
 *
 * See: http://java.sun.com/j2se/1.5/docs/guide/jpda/jdwp-spec.html
 */

enum {
    /*
     * If additional flags are added that apply to jdwpCmdPacket,
     * then debugLoop.c: reader() will need to be updated to
     * accept more than JDWPTRANSPORT_FLAGS_NONE.
     */
    JDWPTRANSPORT_FLAGS_NONE     = 0x0,
    JDWPTRANSPORT_FLAGS_REPLY    = 0x80
};

typedef struct {
    jint len;
    jint id;
    jbyte flags;
    jbyte cmdSet;
    jbyte cmd;
    jbyte *data;
} jdwpCmdPacket;

typedef struct {
    jint len;
    jint id;
    jbyte flags;
    jshort errorCode;
    jbyte *data;
} jdwpReplyPacket;

typedef struct {
    union {
        jdwpCmdPacket cmd;
        jdwpReplyPacket reply;
    } type;
} jdwpPacket;

/*
 * JDWP functions called by the transport.
 */
typedef struct jdwpTransportCallback {
    void *(*alloc)(jint numBytes);   /* Call this for all allocations */
    void (*free)(void *buffer);      /* Call this for all deallocations */
} jdwpTransportCallback;

typedef jint (JNICALL *jdwpTransport_OnLoad_t)(JavaVM *jvm,
                                               jdwpTransportCallback *callback,
                                               jint version,
                                               jdwpTransportEnv** env);



/* Function Interface */

struct jdwpTransportNativeInterface_ {
    /*  1 :  RESERVED */
    void *reserved1;

    /*  2 : Get Capabilities */
    jdwpTransportError (JNICALL *GetCapabilities)(jdwpTransportEnv* env,
         JDWPTransportCapabilities *capabilities_ptr);

    /*  3 : Attach */
    jdwpTransportError (JNICALL *Attach)(jdwpTransportEnv* env,
        const char* address,
        jlong attach_timeout,
        jlong handshake_timeout);

    /*  4: StartListening */
    jdwpTransportError (JNICALL *StartListening)(jdwpTransportEnv* env,
        const char* address,
        char** actual_address);

    /*  5: StopListening */
    jdwpTransportError (JNICALL *StopListening)(jdwpTransportEnv* env);

    /*  6: Accept */
    jdwpTransportError (JNICALL *Accept)(jdwpTransportEnv* env,
        jlong accept_timeout,
        jlong handshake_timeout);

    /*  7: IsOpen */
    jboolean (JNICALL *IsOpen)(jdwpTransportEnv* env);

    /*  8: Close */
    jdwpTransportError (JNICALL *Close)(jdwpTransportEnv* env);

    /*  9: ReadPacket */
    jdwpTransportError (JNICALL *ReadPacket)(jdwpTransportEnv* env,
        jdwpPacket *pkt);

    /*  10: Write Packet */
    jdwpTransportError (JNICALL *WritePacket)(jdwpTransportEnv* env,
        const jdwpPacket* pkt);

    /*  11:  GetLastError */
    jdwpTransportError (JNICALL *GetLastError)(jdwpTransportEnv* env,
        char** error);

};


/*
 * Use inlined functions so that C++ code can use syntax such as
 *      env->Attach("mymachine:5000", 10*1000, 0);
 *
 * rather than using C's :-
 *
 *      (*env)->Attach(env, "mymachine:5000", 10*1000, 0);
 */
struct _jdwpTransportEnv {
    const struct jdwpTransportNativeInterface_ *functions;
#ifdef __cplusplus

    jdwpTransportError GetCapabilities(JDWPTransportCapabilities *capabilities_ptr) {
        return functions->GetCapabilities(this, capabilities_ptr);
    }

    jdwpTransportError Attach(const char* address, jlong attach_timeout,
                jlong handshake_timeout) {
        return functions->Attach(this, address, attach_timeout, handshake_timeout);
    }

    jdwpTransportError StartListening(const char* address,
                char** actual_address) {
        return functions->StartListening(this, address, actual_address);
    }

    jdwpTransportError StopListening(void) {
        return functions->StopListening(this);
    }

    jdwpTransportError Accept(jlong accept_timeout, jlong handshake_timeout) {
        return functions->Accept(this, accept_timeout, handshake_timeout);
    }

    jboolean IsOpen(void) {
        return functions->IsOpen(this);
    }

    jdwpTransportError Close(void) {
        return functions->Close(this);
    }

    jdwpTransportError ReadPacket(jdwpPacket *pkt) {
        return functions->ReadPacket(this, pkt);
    }

    jdwpTransportError WritePacket(const jdwpPacket* pkt) {
        return functions->WritePacket(this, pkt);
    }

    jdwpTransportError GetLastError(char** error) {
        return functions->GetLastError(this, error);
    }


#endif /* __cplusplus */
};

#ifdef __cplusplus
} /* extern "C" */
#endif /* __cplusplus */

#endif /* JDWPTRANSPORT_H */
