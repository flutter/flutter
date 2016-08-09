// Copyright (c) 2005, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// ---
// Author: Craig Silverstein
//
// This is an internal header file used by profiler.cc.  It defines
// the single (inline) function GetPC.  GetPC is used in a signal
// handler to figure out the instruction that was being executed when
// the signal-handler was triggered.
//
// To get this, we use the ucontext_t argument to the signal-handler
// callback, which holds the full context of what was going on when
// the signal triggered.  How to get from a ucontext_t to a Program
// Counter is OS-dependent.

#ifndef BASE_GETPC_H_
#define BASE_GETPC_H_

#include "config.h"

// On many linux systems, we may need _GNU_SOURCE to get access to
// the defined constants that define the register we want to see (eg
// REG_EIP).  Note this #define must come first!
#define _GNU_SOURCE 1
// If #define _GNU_SOURCE causes problems, this might work instead.
// It will cause problems for FreeBSD though!, because it turns off
// the needed __BSD_VISIBLE.
//#define _XOPEN_SOURCE 500

#include <string.h>         // for memcmp
#if defined(HAVE_SYS_UCONTEXT_H)
#include <sys/ucontext.h>
#elif defined(HAVE_UCONTEXT_H)
#include <ucontext.h>       // for ucontext_t (and also mcontext_t)
#elif defined(HAVE_CYGWIN_SIGNAL_H)
#include <cygwin/signal.h>
typedef ucontext ucontext_t;
#endif


// Take the example where function Foo() calls function Bar().  For
// many architectures, Bar() is responsible for setting up and tearing
// down its own stack frame.  In that case, it's possible for the
// interrupt to happen when execution is in Bar(), but the stack frame
// is not properly set up (either before it's done being set up, or
// after it's been torn down but before Bar() returns).  In those
// cases, the stack trace cannot see the caller function anymore.
//
// GetPC can try to identify this situation, on architectures where it
// might occur, and unwind the current function call in that case to
// avoid false edges in the profile graph (that is, edges that appear
// to show a call skipping over a function).  To do this, we hard-code
// in the asm instructions we might see when setting up or tearing
// down a stack frame.
//
// This is difficult to get right: the instructions depend on the
// processor, the compiler ABI, and even the optimization level.  This
// is a best effort patch -- if we fail to detect such a situation, or
// mess up the PC, nothing happens; the returned PC is not used for
// any further processing.
struct CallUnrollInfo {
  // Offset from (e)ip register where this instruction sequence
  // should be matched. Interpreted as bytes. Offset 0 is the next
  // instruction to execute. Be extra careful with negative offsets in
  // architectures of variable instruction length (like x86) - it is
  // not that easy as taking an offset to step one instruction back!
  int pc_offset;
  // The actual instruction bytes. Feel free to make it larger if you
  // need a longer sequence.
  char ins[16];
  // How many bytes to match from ins array?
  int ins_size;
  // The offset from the stack pointer (e)sp where to look for the
  // call return address. Interpreted as bytes.
  int return_sp_offset;
};


// The dereferences needed to get the PC from a struct ucontext were
// determined at configure time, and stored in the macro
// PC_FROM_UCONTEXT in config.h.  The only thing we need to do here,
// then, is to do the magic call-unrolling for systems that support it.

// -- Special case 1: linux x86, for which we have CallUnrollInfo
#if defined(__linux) && defined(__i386) && defined(__GNUC__)
static const CallUnrollInfo callunrollinfo[] = {
  // Entry to a function:  push %ebp;  mov  %esp,%ebp
  // Top-of-stack contains the caller IP.
  { 0,
    {0x55, 0x89, 0xe5}, 3,
    0
  },
  // Entry to a function, second instruction:  push %ebp;  mov  %esp,%ebp
  // Top-of-stack contains the old frame, caller IP is +4.
  { -1,
    {0x55, 0x89, 0xe5}, 3,
    4
  },
  // Return from a function: RET.
  // Top-of-stack contains the caller IP.
  { 0,
    {0xc3}, 1,
    0
  }
};

inline void* GetPC(const ucontext_t& signal_ucontext) {
  // See comment above struct CallUnrollInfo.  Only try instruction
  // flow matching if both eip and esp looks reasonable.
  const int eip = signal_ucontext.uc_mcontext.gregs[REG_EIP];
  const int esp = signal_ucontext.uc_mcontext.gregs[REG_ESP];
  if ((eip & 0xffff0000) != 0 && (~eip & 0xffff0000) != 0 &&
      (esp & 0xffff0000) != 0) {
    char* eip_char = reinterpret_cast<char*>(eip);
    for (int i = 0; i < sizeof(callunrollinfo)/sizeof(*callunrollinfo); ++i) {
      if (!memcmp(eip_char + callunrollinfo[i].pc_offset,
                  callunrollinfo[i].ins, callunrollinfo[i].ins_size)) {
        // We have a match.
        void **retaddr = (void**)(esp + callunrollinfo[i].return_sp_offset);
        return *retaddr;
      }
    }
  }
  return (void*)eip;
}

// Special case #2: Windows, which has to do something totally different.
#elif defined(_WIN32) || defined(__CYGWIN__) || defined(__CYGWIN32__) || defined(__MINGW32__)
// If this is ever implemented, probably the way to do it is to have
// profiler.cc use a high-precision timer via timeSetEvent:
//    http://msdn2.microsoft.com/en-us/library/ms712713.aspx
// We'd use it in mode TIME_CALLBACK_FUNCTION/TIME_PERIODIC.
// The callback function would be something like prof_handler, but
// alas the arguments are different: no ucontext_t!  I don't know
// how we'd get the PC (using StackWalk64?)
//    http://msdn2.microsoft.com/en-us/library/ms680650.aspx

#include "base/logging.h"   // for RAW_LOG
#ifndef HAVE_CYGWIN_SIGNAL_H
typedef int ucontext_t;
#endif

inline void* GetPC(const struct ucontext_t& signal_ucontext) {
  RAW_LOG(ERROR, "GetPC is not yet implemented on Windows\n");
  return NULL;
}

// Normal cases.  If this doesn't compile, it's probably because
// PC_FROM_UCONTEXT is the empty string.  You need to figure out
// the right value for your system, and add it to the list in
// configure.ac (or set it manually in your config.h).
#else
inline void* GetPC(const ucontext_t& signal_ucontext) {
  return (void*)signal_ucontext.PC_FROM_UCONTEXT;   // defined in config.h
}

#endif

#endif  // BASE_GETPC_H_
