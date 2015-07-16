/*
 * Copyright 2015 The Chromium Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE file.
 */

/*
 * In nacl_helper_nonsfi, socketpair() is unavailable. In libevent, it is used
 * to notify of a signal handler invocation, which is unused in
 * nacl_helper_nonsfi. Unfortunately, there is no macro to disable the feature,
 * so we stub out the signal module entirely.
 */


#include <signal.h>
#include <stdlib.h>
#include <sys/queue.h>

/* config.h must be included before any other libevent header is included. */
#include "config.h"

#include "third_party/libevent/event-internal.h"
#include "third_party/libevent/event.h"
#include "third_party/libevent/evsignal.h"


struct event_base *evsignal_base = 0;

int evsignal_init(struct event_base *base) {
  /* Do nothing, and return success. */
  return 0;
}

void evsignal_process(struct event_base *base) {
}

int evsignal_add(struct event *event) {
  /* Do nothing, and return an error. */
  return -1;
}

int evsignal_del(struct event *event) {
  /* Do nothing, and return an error. */
  return -1;
}

void evsignal_dealloc(struct event_base *base) {
}
