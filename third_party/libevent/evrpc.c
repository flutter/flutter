/*
 * Copyright (c) 2000-2004 Niels Provos <provos@citi.umich.edu>
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
#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#ifdef WIN32
#define WIN32_LEAN_AND_MEAN
#include <winsock2.h>
#include <windows.h>
#undef WIN32_LEAN_AND_MEAN
#endif

#include <sys/types.h>
#ifndef WIN32
#include <sys/socket.h>
#endif
#ifdef HAVE_SYS_TIME_H
#include <sys/time.h>
#endif
#include <sys/queue.h>
#include <stdio.h>
#include <stdlib.h>
#ifndef WIN32
#include <unistd.h>
#endif
#include <errno.h>
#include <signal.h>
#include <string.h>
#include <assert.h>

#include "event.h"
#include "evrpc.h"
#include "evrpc-internal.h"
#include "evhttp.h"
#include "evutil.h"
#include "log.h"

struct evrpc_base *
evrpc_init(struct evhttp *http_server)
{
	struct evrpc_base* base = calloc(1, sizeof(struct evrpc_base));
	if (base == NULL)
		return (NULL);

	/* we rely on the tagging sub system */
	evtag_init();

	TAILQ_INIT(&base->registered_rpcs);
	TAILQ_INIT(&base->input_hooks);
	TAILQ_INIT(&base->output_hooks);
	base->http_server = http_server;

	return (base);
}

void
evrpc_free(struct evrpc_base *base)
{
	struct evrpc *rpc;
	struct evrpc_hook *hook;

	while ((rpc = TAILQ_FIRST(&base->registered_rpcs)) != NULL) {
		assert(evrpc_unregister_rpc(base, rpc->uri));
	}
	while ((hook = TAILQ_FIRST(&base->input_hooks)) != NULL) {
		assert(evrpc_remove_hook(base, EVRPC_INPUT, hook));
	}
	while ((hook = TAILQ_FIRST(&base->output_hooks)) != NULL) {
		assert(evrpc_remove_hook(base, EVRPC_OUTPUT, hook));
	}
	free(base);
}

void *
evrpc_add_hook(void *vbase,
    enum EVRPC_HOOK_TYPE hook_type,
    int (*cb)(struct evhttp_request *, struct evbuffer *, void *),
    void *cb_arg)
{
	struct _evrpc_hooks *base = vbase;
	struct evrpc_hook_list *head = NULL;
	struct evrpc_hook *hook = NULL;
	switch (hook_type) {
	case EVRPC_INPUT:
		head = &base->in_hooks;
		break;
	case EVRPC_OUTPUT:
		head = &base->out_hooks;
		break;
	default:
		assert(hook_type == EVRPC_INPUT || hook_type == EVRPC_OUTPUT);
	}

	hook = calloc(1, sizeof(struct evrpc_hook));
	assert(hook != NULL);
	
	hook->process = cb;
	hook->process_arg = cb_arg;
	TAILQ_INSERT_TAIL(head, hook, next);

	return (hook);
}

static int
evrpc_remove_hook_internal(struct evrpc_hook_list *head, void *handle)
{
	struct evrpc_hook *hook = NULL;
	TAILQ_FOREACH(hook, head, next) {
		if (hook == handle) {
			TAILQ_REMOVE(head, hook, next);
			free(hook);
			return (1);
		}
	}

	return (0);
}

/*
 * remove the hook specified by the handle
 */

int
evrpc_remove_hook(void *vbase, enum EVRPC_HOOK_TYPE hook_type, void *handle)
{
	struct _evrpc_hooks *base = vbase;
	struct evrpc_hook_list *head = NULL;
	switch (hook_type) {
	case EVRPC_INPUT:
		head = &base->in_hooks;
		break;
	case EVRPC_OUTPUT:
		head = &base->out_hooks;
		break;
	default:
		assert(hook_type == EVRPC_INPUT || hook_type == EVRPC_OUTPUT);
	}

	return (evrpc_remove_hook_internal(head, handle));
}

static int
evrpc_process_hooks(struct evrpc_hook_list *head,
    struct evhttp_request *req, struct evbuffer *evbuf)
{
	struct evrpc_hook *hook;
	TAILQ_FOREACH(hook, head, next) {
		if (hook->process(req, evbuf, hook->process_arg) == -1)
			return (-1);
	}

	return (0);
}

static void evrpc_pool_schedule(struct evrpc_pool *pool);
static void evrpc_request_cb(struct evhttp_request *, void *);
void evrpc_request_done(struct evrpc_req_generic*);

/*
 * Registers a new RPC with the HTTP server.   The evrpc object is expected
 * to have been filled in via the EVRPC_REGISTER_OBJECT macro which in turn
 * calls this function.
 */

static char *
evrpc_construct_uri(const char *uri)
{
	char *constructed_uri;
	int constructed_uri_len;

	constructed_uri_len = strlen(EVRPC_URI_PREFIX) + strlen(uri) + 1;
	if ((constructed_uri = malloc(constructed_uri_len)) == NULL)
		event_err(1, "%s: failed to register rpc at %s",
		    __func__, uri);
	memcpy(constructed_uri, EVRPC_URI_PREFIX, strlen(EVRPC_URI_PREFIX));
	memcpy(constructed_uri + strlen(EVRPC_URI_PREFIX), uri, strlen(uri));
	constructed_uri[constructed_uri_len - 1] = '\0';

	return (constructed_uri);
}

int
evrpc_register_rpc(struct evrpc_base *base, struct evrpc *rpc,
    void (*cb)(struct evrpc_req_generic *, void *), void *cb_arg)
{
	char *constructed_uri = evrpc_construct_uri(rpc->uri);

	rpc->base = base;
	rpc->cb = cb;
	rpc->cb_arg = cb_arg;

	TAILQ_INSERT_TAIL(&base->registered_rpcs, rpc, next);

	evhttp_set_cb(base->http_server,
	    constructed_uri,
	    evrpc_request_cb,
	    rpc);
	
	free(constructed_uri);

	return (0);
}

int
evrpc_unregister_rpc(struct evrpc_base *base, const char *name)
{
	char *registered_uri = NULL;
	struct evrpc *rpc;

	/* find the right rpc; linear search might be slow */
	TAILQ_FOREACH(rpc, &base->registered_rpcs, next) {
		if (strcmp(rpc->uri, name) == 0)
			break;
	}
	if (rpc == NULL) {
		/* We did not find an RPC with this name */
		return (-1);
	}
	TAILQ_REMOVE(&base->registered_rpcs, rpc, next);
	
	free((char *)rpc->uri);
	free(rpc);

        registered_uri = evrpc_construct_uri(name);

	/* remove the http server callback */
	assert(evhttp_del_cb(base->http_server, registered_uri) == 0);

	free(registered_uri);
	return (0);
}

static void
evrpc_request_cb(struct evhttp_request *req, void *arg)
{
	struct evrpc *rpc = arg;
	struct evrpc_req_generic *rpc_state = NULL;

	/* let's verify the outside parameters */
	if (req->type != EVHTTP_REQ_POST ||
	    EVBUFFER_LENGTH(req->input_buffer) <= 0)
		goto error;

	/*
	 * we might want to allow hooks to suspend the processing,
	 * but at the moment, we assume that they just act as simple
	 * filters.
	 */
	if (evrpc_process_hooks(&rpc->base->input_hooks,
		req, req->input_buffer) == -1)
		goto error;

	rpc_state = calloc(1, sizeof(struct evrpc_req_generic));
	if (rpc_state == NULL)
		goto error;

	/* let's check that we can parse the request */
	rpc_state->request = rpc->request_new();
	if (rpc_state->request == NULL)
		goto error;

	rpc_state->rpc = rpc;

	if (rpc->request_unmarshal(
		    rpc_state->request, req->input_buffer) == -1) {
		/* we failed to parse the request; that's a bummer */
		goto error;
	}

	/* at this point, we have a well formed request, prepare the reply */

	rpc_state->reply = rpc->reply_new();
	if (rpc_state->reply == NULL)
		goto error;

	rpc_state->http_req = req;
	rpc_state->done = evrpc_request_done;

	/* give the rpc to the user; they can deal with it */
	rpc->cb(rpc_state, rpc->cb_arg);

	return;

error:
	evrpc_reqstate_free(rpc_state);
	evhttp_send_error(req, HTTP_SERVUNAVAIL, "Service Error");
	return;
}

void
evrpc_reqstate_free(struct evrpc_req_generic* rpc_state)
{
	/* clean up all memory */
	if (rpc_state != NULL) {
		struct evrpc *rpc = rpc_state->rpc;

		if (rpc_state->request != NULL)
			rpc->request_free(rpc_state->request);
		if (rpc_state->reply != NULL)
			rpc->reply_free(rpc_state->reply);
		free(rpc_state);
	}
}

void
evrpc_request_done(struct evrpc_req_generic* rpc_state)
{
	struct evhttp_request *req = rpc_state->http_req;
	struct evrpc *rpc = rpc_state->rpc;
	struct evbuffer* data = NULL;

	if (rpc->reply_complete(rpc_state->reply) == -1) {
		/* the reply was not completely filled in.  error out */
		goto error;
	}

	if ((data = evbuffer_new()) == NULL) {
		/* out of memory */
		goto error;
	}

	/* serialize the reply */
	rpc->reply_marshal(data, rpc_state->reply);

	/* do hook based tweaks to the request */
	if (evrpc_process_hooks(&rpc->base->output_hooks,
		req, data) == -1)
		goto error;

	/* on success, we are going to transmit marshaled binary data */
	if (evhttp_find_header(req->output_headers, "Content-Type") == NULL) {
		evhttp_add_header(req->output_headers,
		    "Content-Type", "application/octet-stream");
	}

	evhttp_send_reply(req, HTTP_OK, "OK", data);

	evbuffer_free(data);

	evrpc_reqstate_free(rpc_state);

	return;

error:
	if (data != NULL)
		evbuffer_free(data);
	evrpc_reqstate_free(rpc_state);
	evhttp_send_error(req, HTTP_SERVUNAVAIL, "Service Error");
	return;
}

/* Client implementation of RPC site */

static int evrpc_schedule_request(struct evhttp_connection *connection,
    struct evrpc_request_wrapper *ctx);

struct evrpc_pool *
evrpc_pool_new(struct event_base *base)
{
	struct evrpc_pool *pool = calloc(1, sizeof(struct evrpc_pool));
	if (pool == NULL)
		return (NULL);

	TAILQ_INIT(&pool->connections);
	TAILQ_INIT(&pool->requests);

	TAILQ_INIT(&pool->input_hooks);
	TAILQ_INIT(&pool->output_hooks);

	pool->base = base;
	pool->timeout = -1;

	return (pool);
}

static void
evrpc_request_wrapper_free(struct evrpc_request_wrapper *request)
{
	free(request->name);
	free(request);
}

void
evrpc_pool_free(struct evrpc_pool *pool)
{
	struct evhttp_connection *connection;
	struct evrpc_request_wrapper *request;
	struct evrpc_hook *hook;

	while ((request = TAILQ_FIRST(&pool->requests)) != NULL) {
		TAILQ_REMOVE(&pool->requests, request, next);
		/* if this gets more complicated we need our own function */
		evrpc_request_wrapper_free(request);
	}

	while ((connection = TAILQ_FIRST(&pool->connections)) != NULL) {
		TAILQ_REMOVE(&pool->connections, connection, next);
		evhttp_connection_free(connection);
	}

	while ((hook = TAILQ_FIRST(&pool->input_hooks)) != NULL) {
		assert(evrpc_remove_hook(pool, EVRPC_INPUT, hook));
	}

	while ((hook = TAILQ_FIRST(&pool->output_hooks)) != NULL) {
		assert(evrpc_remove_hook(pool, EVRPC_OUTPUT, hook));
	}

	free(pool);
}

/*
 * Add a connection to the RPC pool.   A request scheduled on the pool
 * may use any available connection.
 */

void
evrpc_pool_add_connection(struct evrpc_pool *pool,
    struct evhttp_connection *connection) {
	assert(connection->http_server == NULL);
	TAILQ_INSERT_TAIL(&pool->connections, connection, next);

	/*
	 * associate an event base with this connection
	 */
	if (pool->base != NULL)
		evhttp_connection_set_base(connection, pool->base);

	/* 
	 * unless a timeout was specifically set for a connection,
	 * the connection inherits the timeout from the pool.
	 */
	if (connection->timeout == -1)
		connection->timeout = pool->timeout;

	/* 
	 * if we have any requests pending, schedule them with the new
	 * connections.
	 */

	if (TAILQ_FIRST(&pool->requests) != NULL) {
		struct evrpc_request_wrapper *request = 
		    TAILQ_FIRST(&pool->requests);
		TAILQ_REMOVE(&pool->requests, request, next);
		evrpc_schedule_request(connection, request);
	}
}

void
evrpc_pool_set_timeout(struct evrpc_pool *pool, int timeout_in_secs)
{
	struct evhttp_connection *evcon;
	TAILQ_FOREACH(evcon, &pool->connections, next) {
		evcon->timeout = timeout_in_secs;
	}
	pool->timeout = timeout_in_secs;
}


static void evrpc_reply_done(struct evhttp_request *, void *);
static void evrpc_request_timeout(int, short, void *);

/*
 * Finds a connection object associated with the pool that is currently
 * idle and can be used to make a request.
 */
static struct evhttp_connection *
evrpc_pool_find_connection(struct evrpc_pool *pool)
{
	struct evhttp_connection *connection;
	TAILQ_FOREACH(connection, &pool->connections, next) {
		if (TAILQ_FIRST(&connection->requests) == NULL)
			return (connection);
	}

	return (NULL);
}

/*
 * We assume that the ctx is no longer queued on the pool.
 */
static int
evrpc_schedule_request(struct evhttp_connection *connection,
    struct evrpc_request_wrapper *ctx)
{
	struct evhttp_request *req = NULL;
	struct evrpc_pool *pool = ctx->pool;
	struct evrpc_status status;
	char *uri = NULL;
	int res = 0;

	if ((req = evhttp_request_new(evrpc_reply_done, ctx)) == NULL)
		goto error;

	/* serialize the request data into the output buffer */
	ctx->request_marshal(req->output_buffer, ctx->request);

	uri = evrpc_construct_uri(ctx->name);
	if (uri == NULL)
		goto error;

	/* we need to know the connection that we might have to abort */
	ctx->evcon = connection;

	/* apply hooks to the outgoing request */
	if (evrpc_process_hooks(&pool->output_hooks,
		req, req->output_buffer) == -1)
		goto error;

	if (pool->timeout > 0) {
		/* 
		 * a timeout after which the whole rpc is going to be aborted.
		 */
		struct timeval tv;
		evutil_timerclear(&tv);
		tv.tv_sec = pool->timeout;
		evtimer_add(&ctx->ev_timeout, &tv);
	}

	/* start the request over the connection */
	res = evhttp_make_request(connection, req, EVHTTP_REQ_POST, uri);
	free(uri);

	if (res == -1)
		goto error;

	return (0);

error:
	memset(&status, 0, sizeof(status));
	status.error = EVRPC_STATUS_ERR_UNSTARTED;
	(*ctx->cb)(&status, ctx->request, ctx->reply, ctx->cb_arg);
	evrpc_request_wrapper_free(ctx);
	return (-1);
}

int
evrpc_make_request(struct evrpc_request_wrapper *ctx)
{
	struct evrpc_pool *pool = ctx->pool;

	/* initialize the event structure for this rpc */
	evtimer_set(&ctx->ev_timeout, evrpc_request_timeout, ctx);
	if (pool->base != NULL)
		event_base_set(pool->base, &ctx->ev_timeout);

	/* we better have some available connections on the pool */
	assert(TAILQ_FIRST(&pool->connections) != NULL);

	/* 
	 * if no connection is available, we queue the request on the pool,
	 * the next time a connection is empty, the rpc will be send on that.
	 */
	TAILQ_INSERT_TAIL(&pool->requests, ctx, next);

	evrpc_pool_schedule(pool);

	return (0);
}

static void
evrpc_reply_done(struct evhttp_request *req, void *arg)
{
	struct evrpc_request_wrapper *ctx = arg;
	struct evrpc_pool *pool = ctx->pool;
	struct evrpc_status status;
	int res = -1;
	
	/* cancel any timeout we might have scheduled */
	event_del(&ctx->ev_timeout);

	memset(&status, 0, sizeof(status));
	status.http_req = req;

	/* we need to get the reply now */
	if (req != NULL) {
		/* apply hooks to the incoming request */
		if (evrpc_process_hooks(&pool->input_hooks,
			req, req->input_buffer) == -1) {
			status.error = EVRPC_STATUS_ERR_HOOKABORTED;
			res = -1;
		} else {
			res = ctx->reply_unmarshal(ctx->reply,
			    req->input_buffer);
			if (res == -1) {
				status.error = EVRPC_STATUS_ERR_BADPAYLOAD;
			}
		}
	} else {
		status.error = EVRPC_STATUS_ERR_TIMEOUT;
	}

	if (res == -1) {
		/* clear everything that we might have written previously */
		ctx->reply_clear(ctx->reply);
	}

	(*ctx->cb)(&status, ctx->request, ctx->reply, ctx->cb_arg);
	
	evrpc_request_wrapper_free(ctx);

	/* the http layer owns the request structure */

	/* see if we can schedule another request */
	evrpc_pool_schedule(pool);
}

static void
evrpc_pool_schedule(struct evrpc_pool *pool)
{
	struct evrpc_request_wrapper *ctx = TAILQ_FIRST(&pool->requests);
	struct evhttp_connection *evcon;

	/* if no requests are pending, we have no work */
	if (ctx == NULL)
		return;

	if ((evcon = evrpc_pool_find_connection(pool)) != NULL) {
		TAILQ_REMOVE(&pool->requests, ctx, next);
		evrpc_schedule_request(evcon, ctx);
	}
}

static void
evrpc_request_timeout(int fd, short what, void *arg)
{
	struct evrpc_request_wrapper *ctx = arg;
	struct evhttp_connection *evcon = ctx->evcon;
	assert(evcon != NULL);

	evhttp_connection_fail(evcon, EVCON_HTTP_TIMEOUT);
}
