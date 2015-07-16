/*
 * Copyright (c) 2006 Niels Provos <provos@citi.umich.edu>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
#ifndef _EVRPC_INTERNAL_H_
#define _EVRPC_INTERNAL_H_

#include "http-internal.h"

struct evrpc;

#define EVRPC_URI_PREFIX "/.rpc."

struct evrpc_hook {
	TAILQ_ENTRY(evrpc_hook) (next);

	/* returns -1; if the rpc should be aborted, is allowed to rewrite */
	int (*process)(struct evhttp_request *, struct evbuffer *, void *);
	void *process_arg;
};

TAILQ_HEAD(evrpc_hook_list, evrpc_hook);

/*
 * this is shared between the base and the pool, so that we can reuse
 * the hook adding functions; we alias both evrpc_pool and evrpc_base
 * to this common structure.
 */
struct _evrpc_hooks {
	/* hooks for processing outbound and inbound rpcs */
	struct evrpc_hook_list in_hooks;
	struct evrpc_hook_list out_hooks;
};

#define input_hooks common.in_hooks
#define output_hooks common.out_hooks

struct evrpc_base {
	struct _evrpc_hooks common;

	/* the HTTP server under which we register our RPC calls */
	struct evhttp* http_server;

	/* a list of all RPCs registered with us */
	TAILQ_HEAD(evrpc_list, evrpc) registered_rpcs;
};

struct evrpc_req_generic;
void evrpc_reqstate_free(struct evrpc_req_generic* rpc_state);

/* A pool for holding evhttp_connection objects */
struct evrpc_pool {
	struct _evrpc_hooks common;

	struct event_base *base;

	struct evconq connections;

	int timeout;

	TAILQ_HEAD(evrpc_requestq, evrpc_request_wrapper) requests;
};


#endif /* _EVRPC_INTERNAL_H_ */
