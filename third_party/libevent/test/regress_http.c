/*
 * Copyright (c) 2003-2006 Niels Provos <provos@citi.umich.edu>
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

#ifdef WIN32
#include <winsock2.h>
#include <windows.h>
#endif

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <sys/types.h>
#include <sys/stat.h>
#ifdef HAVE_SYS_TIME_H
#include <sys/time.h>
#endif
#include <sys/queue.h>
#ifndef WIN32
#include <sys/socket.h>
#include <signal.h>
#include <unistd.h>
#include <netdb.h>
#endif
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>

#include "event.h"
#include "evhttp.h"
#include "log.h"
#include "http-internal.h"

extern int pair[];
extern int test_ok;

static struct evhttp *http;
/* set if a test needs to call loopexit on a base */
static struct event_base *base;

void http_suite(void);

void http_basic_cb(struct evhttp_request *req, void *arg);
static void http_chunked_cb(struct evhttp_request *req, void *arg);
void http_post_cb(struct evhttp_request *req, void *arg);
void http_dispatcher_cb(struct evhttp_request *req, void *arg);
static void http_large_delay_cb(struct evhttp_request *req, void *arg);

static struct evhttp *
http_setup(short *pport, struct event_base *base)
{
	int i;
	struct evhttp *myhttp;
	short port = -1;

	/* Try a few different ports */
	myhttp = evhttp_new(base);
	for (i = 0; i < 50; ++i) {
		if (evhttp_bind_socket(myhttp, "127.0.0.1", 8080 + i) != -1) {
			port = 8080 + i;
			break;
		}
	}

	if (port == -1)
		event_errx(1, "Could not start web server");

	/* Register a callback for certain types of requests */
	evhttp_set_cb(myhttp, "/test", http_basic_cb, NULL);
	evhttp_set_cb(myhttp, "/chunked", http_chunked_cb, NULL);
	evhttp_set_cb(myhttp, "/postit", http_post_cb, NULL);
	evhttp_set_cb(myhttp, "/largedelay", http_large_delay_cb, NULL);
	evhttp_set_cb(myhttp, "/", http_dispatcher_cb, NULL);

	*pport = port;
	return (myhttp);
}

#ifndef NI_MAXSERV
#define NI_MAXSERV 1024
#endif

static int
http_connect(const char *address, u_short port)
{
	/* Stupid code for connecting */
#ifdef WIN32
	struct hostent *he;
	struct sockaddr_in sin;
#else
	struct addrinfo ai, *aitop;
	char strport[NI_MAXSERV];
#endif
	struct sockaddr *sa;
	int slen;
	int fd;
	
#ifdef WIN32
	if (!(he = gethostbyname(address))) {
		event_warn("gethostbyname");
	}
	memcpy(&sin.sin_addr, he->h_addr_list[0], he->h_length);
	sin.sin_family = AF_INET;
	sin.sin_port = htons(port);
	slen = sizeof(struct sockaddr_in);
	sa = (struct sockaddr*)&sin;
#else
	memset(&ai, 0, sizeof (ai));
	ai.ai_family = AF_INET;
	ai.ai_socktype = SOCK_STREAM;
	snprintf(strport, sizeof (strport), "%d", port);
	if (getaddrinfo(address, strport, &ai, &aitop) != 0) {
		event_warn("getaddrinfo");
		return (-1);
	}
	sa = aitop->ai_addr;
	slen = aitop->ai_addrlen;
#endif
        
	fd = socket(AF_INET, SOCK_STREAM, 0);
	if (fd == -1)
		event_err(1, "socket failed");

	if (connect(fd, sa, slen) == -1)
		event_err(1, "connect failed");

#ifndef WIN32
	freeaddrinfo(aitop);
#endif

	return (fd);
}

static void
http_readcb(struct bufferevent *bev, void *arg)
{
	const char *what = "This is funny";

 	event_debug(("%s: %s\n", __func__, EVBUFFER_DATA(bev->input)));
	
	if (evbuffer_find(bev->input,
		(const unsigned char*) what, strlen(what)) != NULL) {
		struct evhttp_request *req = evhttp_request_new(NULL, NULL);
		enum message_read_status done;

		req->kind = EVHTTP_RESPONSE;
		done = evhttp_parse_firstline(req, bev->input);
		if (done != ALL_DATA_READ)
			goto out;

		done = evhttp_parse_headers(req, bev->input);
		if (done != ALL_DATA_READ)
			goto out;

		if (done == 1 &&
		    evhttp_find_header(req->input_headers,
			"Content-Type") != NULL)
			test_ok++;

	out:
		evhttp_request_free(req);
		bufferevent_disable(bev, EV_READ);
		if (base)
			event_base_loopexit(base, NULL);
		else
			event_loopexit(NULL);
	}
}

static void
http_writecb(struct bufferevent *bev, void *arg)
{
	if (EVBUFFER_LENGTH(bev->output) == 0) {
		/* enable reading of the reply */
		bufferevent_enable(bev, EV_READ);
		test_ok++;
	}
}

static void
http_errorcb(struct bufferevent *bev, short what, void *arg)
{
	test_ok = -2;
	event_loopexit(NULL);
}

void
http_basic_cb(struct evhttp_request *req, void *arg)
{
	struct evbuffer *evb = evbuffer_new();
	int empty = evhttp_find_header(req->input_headers, "Empty") != NULL;
	event_debug(("%s: called\n", __func__));
	evbuffer_add_printf(evb, "This is funny");
	
	/* For multi-line headers test */
	{
		const char *multi =
		    evhttp_find_header(req->input_headers,"X-multi");
		if (multi) {
			if (strcmp("END", multi + strlen(multi) - 3) == 0)
				test_ok++;
			if (evhttp_find_header(req->input_headers, "X-Last"))
				test_ok++;
		}
	}

	/* injecting a bad content-length */
	if (evhttp_find_header(req->input_headers, "X-Negative"))
		evhttp_add_header(req->output_headers,
		    "Content-Length", "-100");

	/* allow sending of an empty reply */
	evhttp_send_reply(req, HTTP_OK, "Everything is fine",
	    !empty ? evb : NULL);

	evbuffer_free(evb);
}

static char const* const CHUNKS[] = {
	"This is funny",
	"but not hilarious.",
	"bwv 1052"
};

struct chunk_req_state {
	struct evhttp_request *req;
	int i;
};

static void
http_chunked_trickle_cb(int fd, short events, void *arg)
{
	struct evbuffer *evb = evbuffer_new();
	struct chunk_req_state *state = arg;
	struct timeval when = { 0, 0 };

	evbuffer_add_printf(evb, "%s", CHUNKS[state->i]);
	evhttp_send_reply_chunk(state->req, evb);
	evbuffer_free(evb);

	if (++state->i < sizeof(CHUNKS)/sizeof(CHUNKS[0])) {
		event_once(-1, EV_TIMEOUT,
		    http_chunked_trickle_cb, state, &when);
	} else {
		evhttp_send_reply_end(state->req);
		free(state);
	}
}

static void
http_chunked_cb(struct evhttp_request *req, void *arg)
{
	struct timeval when = { 0, 0 };
	struct chunk_req_state *state = malloc(sizeof(struct chunk_req_state));
	event_debug(("%s: called\n", __func__));

	memset(state, 0, sizeof(struct chunk_req_state));
	state->req = req;

	/* generate a chunked reply */
	evhttp_send_reply_start(req, HTTP_OK, "Everything is fine");

	/* but trickle it across several iterations to ensure we're not
	 * assuming it comes all at once */
	event_once(-1, EV_TIMEOUT, http_chunked_trickle_cb, state, &when);
}

static void
http_complete_write(int fd, short what, void *arg)
{
	struct bufferevent *bev = arg;
	const char *http_request = "host\r\n"
	    "Connection: close\r\n"
	    "\r\n";
	bufferevent_write(bev, http_request, strlen(http_request));
}

static void
http_basic_test(void)
{
	struct timeval tv;
	struct bufferevent *bev;
	int fd;
	const char *http_request;
	short port = -1;

	test_ok = 0;
	fprintf(stdout, "Testing Basic HTTP Server: ");

	http = http_setup(&port, NULL);

	/* bind to a second socket */
	if (evhttp_bind_socket(http, "127.0.0.1", port + 1) == -1) {
		fprintf(stdout, "FAILED (bind)\n");
		exit(1);
	}
	
	fd = http_connect("127.0.0.1", port);

	/* Stupid thing to send a request */
	bev = bufferevent_new(fd, http_readcb, http_writecb,
	    http_errorcb, NULL);

	/* first half of the http request */
	http_request =
	    "GET /test HTTP/1.1\r\n"
	    "Host: some";

	bufferevent_write(bev, http_request, strlen(http_request));
	timerclear(&tv);
	tv.tv_usec = 10000;
	event_once(-1, EV_TIMEOUT, http_complete_write, bev, &tv);
	
	event_dispatch();

	if (test_ok != 3) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	/* connect to the second port */
	bufferevent_free(bev);
	EVUTIL_CLOSESOCKET(fd);

	fd = http_connect("127.0.0.1", port + 1);

	/* Stupid thing to send a request */
	bev = bufferevent_new(fd, http_readcb, http_writecb,
	    http_errorcb, NULL);

	http_request =
	    "GET /test HTTP/1.1\r\n"
	    "Host: somehost\r\n"
	    "Connection: close\r\n"
	    "\r\n";

	bufferevent_write(bev, http_request, strlen(http_request));
	
	event_dispatch();

	bufferevent_free(bev);
	EVUTIL_CLOSESOCKET(fd);

	evhttp_free(http);
	
	if (test_ok != 5) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	fprintf(stdout, "OK\n");
}

static struct evhttp_connection *delayed_client;

static void
http_delay_reply(int fd, short what, void *arg)
{
	struct evhttp_request *req = arg;

	evhttp_send_reply(req, HTTP_OK, "Everything is fine", NULL);

	++test_ok;
}

static void
http_large_delay_cb(struct evhttp_request *req, void *arg)
{
	struct timeval tv;
	timerclear(&tv);
	tv.tv_sec = 3;

	event_once(-1, EV_TIMEOUT, http_delay_reply, req, &tv);

	/* here we close the client connection which will cause an EOF */
	evhttp_connection_fail(delayed_client, EVCON_HTTP_EOF);
}

void http_request_done(struct evhttp_request *, void *);
void http_request_empty_done(struct evhttp_request *, void *);

static void
http_connection_test(int persistent)
{
	short port = -1;
	struct evhttp_connection *evcon = NULL;
	struct evhttp_request *req = NULL;
	
	test_ok = 0;
	fprintf(stdout, "Testing Request Connection Pipeline %s: ",
	    persistent ? "(persistent)" : "");

	http = http_setup(&port, NULL);

	evcon = evhttp_connection_new("127.0.0.1", port);
	if (evcon == NULL) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	/*
	 * At this point, we want to schedule a request to the HTTP
	 * server using our make request method.
	 */

	req = evhttp_request_new(http_request_done, NULL);

	/* Add the information that we care about */
	evhttp_add_header(req->output_headers, "Host", "somehost");

	/* We give ownership of the request to the connection */
	if (evhttp_make_request(evcon, req, EVHTTP_REQ_GET, "/test") == -1) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	event_dispatch();

	if (test_ok != 1) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	/* try to make another request over the same connection */
	test_ok = 0;
	
	req = evhttp_request_new(http_request_done, NULL);

	/* Add the information that we care about */
	evhttp_add_header(req->output_headers, "Host", "somehost");

	/* 
	 * if our connections are not supposed to be persistent; request
	 * a close from the server.
	 */
	if (!persistent)
		evhttp_add_header(req->output_headers, "Connection", "close");

	/* We give ownership of the request to the connection */
	if (evhttp_make_request(evcon, req, EVHTTP_REQ_GET, "/test") == -1) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	event_dispatch();

	/* make another request: request empty reply */
	test_ok = 0;
	
	req = evhttp_request_new(http_request_empty_done, NULL);

	/* Add the information that we care about */
	evhttp_add_header(req->output_headers, "Empty", "itis");

	/* We give ownership of the request to the connection */
	if (evhttp_make_request(evcon, req, EVHTTP_REQ_GET, "/test") == -1) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	event_dispatch();

	if (test_ok != 1) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	evhttp_connection_free(evcon);
	evhttp_free(http);
	
	fprintf(stdout, "OK\n");
}

void
http_request_done(struct evhttp_request *req, void *arg)
{
	const char *what = "This is funny";

	if (req->response_code != HTTP_OK) {
		fprintf(stderr, "FAILED\n");
		exit(1);
	}

	if (evhttp_find_header(req->input_headers, "Content-Type") == NULL) {
		fprintf(stderr, "FAILED\n");
		exit(1);
	}

	if (EVBUFFER_LENGTH(req->input_buffer) != strlen(what)) {
		fprintf(stderr, "FAILED\n");
		exit(1);
	}
	
	if (memcmp(EVBUFFER_DATA(req->input_buffer), what, strlen(what)) != 0) {
		fprintf(stderr, "FAILED\n");
		exit(1);
	}

	test_ok = 1;
	event_loopexit(NULL);
}

/* test date header and content length */

void
http_request_empty_done(struct evhttp_request *req, void *arg)
{
	if (req->response_code != HTTP_OK) {
		fprintf(stderr, "FAILED\n");
		exit(1);
	}

	if (evhttp_find_header(req->input_headers, "Date") == NULL) {
		fprintf(stderr, "FAILED\n");
		exit(1);
	}

	
	if (evhttp_find_header(req->input_headers, "Content-Length") == NULL) {
		fprintf(stderr, "FAILED\n");
		exit(1);
	}

	if (strcmp(evhttp_find_header(req->input_headers, "Content-Length"),
		"0")) {
		fprintf(stderr, "FAILED\n");
		exit(1);
	}

	if (EVBUFFER_LENGTH(req->input_buffer) != 0) {
		fprintf(stderr, "FAILED\n");
		exit(1);
	}

	test_ok = 1;
	event_loopexit(NULL);
}

/*
 * HTTP DISPATCHER test
 */

void
http_dispatcher_cb(struct evhttp_request *req, void *arg)
{

	struct evbuffer *evb = evbuffer_new();
	event_debug(("%s: called\n", __func__));
	evbuffer_add_printf(evb, "DISPATCHER_TEST");

	evhttp_send_reply(req, HTTP_OK, "Everything is fine", evb);

	evbuffer_free(evb);
}

static void
http_dispatcher_test_done(struct evhttp_request *req, void *arg)
{
	const char *what = "DISPATCHER_TEST";

	if (req->response_code != HTTP_OK) {
		fprintf(stderr, "FAILED\n");
		exit(1);
	}

	if (evhttp_find_header(req->input_headers, "Content-Type") == NULL) {
		fprintf(stderr, "FAILED (content type)\n");
		exit(1);
	}

	if (EVBUFFER_LENGTH(req->input_buffer) != strlen(what)) {
		fprintf(stderr, "FAILED (length %zu vs %zu)\n",
		    EVBUFFER_LENGTH(req->input_buffer), strlen(what));
		exit(1);
	}
	
	if (memcmp(EVBUFFER_DATA(req->input_buffer), what, strlen(what)) != 0) {
		fprintf(stderr, "FAILED (data)\n");
		exit(1);
	}

	test_ok = 1;
	event_loopexit(NULL);
}

static void
http_dispatcher_test(void)
{
	short port = -1;
	struct evhttp_connection *evcon = NULL;
	struct evhttp_request *req = NULL;

	test_ok = 0;
	fprintf(stdout, "Testing HTTP Dispatcher: ");

	http = http_setup(&port, NULL);

	evcon = evhttp_connection_new("127.0.0.1", port);
	if (evcon == NULL) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	/* also bind to local host */
	evhttp_connection_set_local_address(evcon, "127.0.0.1");

	/*
	 * At this point, we want to schedule an HTTP GET request
	 * server using our make request method.
	 */

	req = evhttp_request_new(http_dispatcher_test_done, NULL);
	if (req == NULL) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	/* Add the information that we care about */
	evhttp_add_header(req->output_headers, "Host", "somehost");
	
	if (evhttp_make_request(evcon, req, EVHTTP_REQ_GET, "/?arg=val") == -1) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	event_dispatch();

	evhttp_connection_free(evcon);
	evhttp_free(http);
	
	if (test_ok != 1) {
		fprintf(stdout, "FAILED: %d\n", test_ok);
		exit(1);
	}
	
	fprintf(stdout, "OK\n");
}

/*
 * HTTP POST test.
 */

void http_postrequest_done(struct evhttp_request *, void *);

#define POST_DATA "Okay.  Not really printf"

static void
http_post_test(void)
{
	short port = -1;
	struct evhttp_connection *evcon = NULL;
	struct evhttp_request *req = NULL;

	test_ok = 0;
	fprintf(stdout, "Testing HTTP POST Request: ");

	http = http_setup(&port, NULL);

	evcon = evhttp_connection_new("127.0.0.1", port);
	if (evcon == NULL) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	/*
	 * At this point, we want to schedule an HTTP POST request
	 * server using our make request method.
	 */

	req = evhttp_request_new(http_postrequest_done, NULL);
	if (req == NULL) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	/* Add the information that we care about */
	evhttp_add_header(req->output_headers, "Host", "somehost");
	evbuffer_add_printf(req->output_buffer, POST_DATA);
	
	if (evhttp_make_request(evcon, req, EVHTTP_REQ_POST, "/postit") == -1) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	event_dispatch();

	evhttp_connection_free(evcon);
	evhttp_free(http);
	
	if (test_ok != 1) {
		fprintf(stdout, "FAILED: %d\n", test_ok);
		exit(1);
	}
	
	fprintf(stdout, "OK\n");
}

void
http_post_cb(struct evhttp_request *req, void *arg)
{
	struct evbuffer *evb;
	event_debug(("%s: called\n", __func__));

	/* Yes, we are expecting a post request */
	if (req->type != EVHTTP_REQ_POST) {
		fprintf(stdout, "FAILED (post type)\n");
		exit(1);
	}

	if (EVBUFFER_LENGTH(req->input_buffer) != strlen(POST_DATA)) {
		fprintf(stdout, "FAILED (length: %zu vs %zu)\n",
		    EVBUFFER_LENGTH(req->input_buffer), strlen(POST_DATA));
		exit(1);
	}

	if (memcmp(EVBUFFER_DATA(req->input_buffer), POST_DATA,
		strlen(POST_DATA))) {
		fprintf(stdout, "FAILED (data)\n");
		fprintf(stdout, "Got :%s\n", EVBUFFER_DATA(req->input_buffer));
		fprintf(stdout, "Want:%s\n", POST_DATA);
		exit(1);
	}
	
	evb = evbuffer_new();
	evbuffer_add_printf(evb, "This is funny");

	evhttp_send_reply(req, HTTP_OK, "Everything is fine", evb);

	evbuffer_free(evb);
}

void
http_postrequest_done(struct evhttp_request *req, void *arg)
{
	const char *what = "This is funny";

	if (req == NULL) {
		fprintf(stderr, "FAILED (timeout)\n");
		exit(1);
	}

	if (req->response_code != HTTP_OK) {
	
		fprintf(stderr, "FAILED (response code)\n");
		exit(1);
	}

	if (evhttp_find_header(req->input_headers, "Content-Type") == NULL) {
		fprintf(stderr, "FAILED (content type)\n");
		exit(1);
	}

	if (EVBUFFER_LENGTH(req->input_buffer) != strlen(what)) {
		fprintf(stderr, "FAILED (length %zu vs %zu)\n",
		    EVBUFFER_LENGTH(req->input_buffer), strlen(what));
		exit(1);
	}
	
	if (memcmp(EVBUFFER_DATA(req->input_buffer), what, strlen(what)) != 0) {
		fprintf(stderr, "FAILED (data)\n");
		exit(1);
	}

	test_ok = 1;
	event_loopexit(NULL);
}

static void
http_failure_readcb(struct bufferevent *bev, void *arg)
{
	const char *what = "400 Bad Request";
	if (evbuffer_find(bev->input, (const unsigned char*) what, strlen(what)) != NULL) {
		test_ok = 2;
		bufferevent_disable(bev, EV_READ);
		event_loopexit(NULL);
	}
}

/*
 * Testing that the HTTP server can deal with a malformed request.
 */
static void
http_failure_test(void)
{
	struct bufferevent *bev;
	int fd;
	const char *http_request;
	short port = -1;

	test_ok = 0;
	fprintf(stdout, "Testing Bad HTTP Request: ");

	http = http_setup(&port, NULL);
	
	fd = http_connect("127.0.0.1", port);

	/* Stupid thing to send a request */
	bev = bufferevent_new(fd, http_failure_readcb, http_writecb,
	    http_errorcb, NULL);

	http_request = "illegal request\r\n";

	bufferevent_write(bev, http_request, strlen(http_request));
	
	event_dispatch();

	bufferevent_free(bev);
	EVUTIL_CLOSESOCKET(fd);

	evhttp_free(http);
	
	if (test_ok != 2) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}
	
	fprintf(stdout, "OK\n");
}

static void
close_detect_done(struct evhttp_request *req, void *arg)
{
	struct timeval tv;
	if (req == NULL || req->response_code != HTTP_OK) {
	
		fprintf(stderr, "FAILED\n");
		exit(1);
	}

	test_ok = 1;

	timerclear(&tv);
	tv.tv_sec = 3;   /* longer than the http time out */

	event_loopexit(&tv);
}

static void
close_detect_launch(int fd, short what, void *arg)
{
	struct evhttp_connection *evcon = arg;
	struct evhttp_request *req;

	req = evhttp_request_new(close_detect_done, NULL);

	/* Add the information that we care about */
	evhttp_add_header(req->output_headers, "Host", "somehost");

	/* We give ownership of the request to the connection */
	if (evhttp_make_request(evcon, req, EVHTTP_REQ_GET, "/test") == -1) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}
}

static void
close_detect_cb(struct evhttp_request *req, void *arg)
{
	struct evhttp_connection *evcon = arg;
	struct timeval tv;

	if (req != NULL && req->response_code != HTTP_OK) {
	
		fprintf(stderr, "FAILED\n");
		exit(1);
	}

	timerclear(&tv);
	tv.tv_sec = 3;   /* longer than the http time out */

	/* launch a new request on the persistent connection in 6 seconds */
	event_once(-1, EV_TIMEOUT, close_detect_launch, evcon, &tv);
}


static void
http_close_detection(int with_delay)
{
	short port = -1;
	struct evhttp_connection *evcon = NULL;
	struct evhttp_request *req = NULL;
	
	test_ok = 0;
	fprintf(stdout, "Testing Connection Close Detection%s: ",
		with_delay ? " (with delay)" : "");

	http = http_setup(&port, NULL);

	/* 2 second timeout */
	evhttp_set_timeout(http, 2);

	evcon = evhttp_connection_new("127.0.0.1", port);
	if (evcon == NULL) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	delayed_client = evcon;

	/*
	 * At this point, we want to schedule a request to the HTTP
	 * server using our make request method.
	 */

	req = evhttp_request_new(close_detect_cb, evcon);

	/* Add the information that we care about */
	evhttp_add_header(req->output_headers, "Host", "somehost");

	/* We give ownership of the request to the connection */
	if (evhttp_make_request(evcon,
	    req, EVHTTP_REQ_GET, with_delay ? "/largedelay" : "/test") == -1) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	event_dispatch();

	if (test_ok != 1) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	/* at this point, the http server should have no connection */
	if (TAILQ_FIRST(&http->connections) != NULL) {
		fprintf(stdout, "FAILED (left connections)\n");
		exit(1);
	}

	evhttp_connection_free(evcon);
	evhttp_free(http);
	
	fprintf(stdout, "OK\n");
}

static void
http_highport_test(void)
{
	int i = -1;
	struct evhttp *myhttp = NULL;
 
	fprintf(stdout, "Testing HTTP Server with high port: ");

	/* Try a few different ports */
	for (i = 0; i < 50; ++i) {
		myhttp = evhttp_start("127.0.0.1", 65535 - i);
		if (myhttp != NULL) {
			fprintf(stdout, "OK\n");
			evhttp_free(myhttp);
			return;
		}
	}

	fprintf(stdout, "FAILED\n");
	exit(1);
}

static void
http_bad_header_test(void)
{
	struct evkeyvalq headers;

	fprintf(stdout, "Testing HTTP Header filtering: ");

	TAILQ_INIT(&headers);

	if (evhttp_add_header(&headers, "One", "Two") != 0)
		goto fail;
	
	if (evhttp_add_header(&headers, "One\r", "Two") != -1)
		goto fail;
	if (evhttp_add_header(&headers, "One", "Two") != 0)
		goto fail;
	if (evhttp_add_header(&headers, "One", "Two\r\n Three") != 0)
		goto fail;
	if (evhttp_add_header(&headers, "One\r", "Two") != -1)
		goto fail;
	if (evhttp_add_header(&headers, "One\n", "Two") != -1)
		goto fail;
	if (evhttp_add_header(&headers, "One", "Two\r") != -1)
		goto fail;
	if (evhttp_add_header(&headers, "One", "Two\n") != -1)
		goto fail;

	evhttp_clear_headers(&headers);

	fprintf(stdout, "OK\n");
	return;
fail:
	fprintf(stdout, "FAILED\n");
	exit(1);
}

static int validate_header(
	const struct evkeyvalq* headers,
	const char *key, const char *value) 
{
	const char *real_val = evhttp_find_header(headers, key);
	if (real_val == NULL)
		return (-1);
	if (strcmp(real_val, value) != 0)
		return (-1);
	return (0);
}

static void
http_parse_query_test(void)
{
	struct evkeyvalq headers;

	fprintf(stdout, "Testing HTTP query parsing: ");

	TAILQ_INIT(&headers);
	
	evhttp_parse_query("http://www.test.com/?q=test", &headers);
	if (validate_header(&headers, "q", "test") != 0)
		goto fail;
	evhttp_clear_headers(&headers);

	evhttp_parse_query("http://www.test.com/?q=test&foo=bar", &headers);
	if (validate_header(&headers, "q", "test") != 0)
		goto fail;
	if (validate_header(&headers, "foo", "bar") != 0)
		goto fail;
	evhttp_clear_headers(&headers);

	evhttp_parse_query("http://www.test.com/?q=test+foo", &headers);
	if (validate_header(&headers, "q", "test foo") != 0)
		goto fail;
	evhttp_clear_headers(&headers);

	evhttp_parse_query("http://www.test.com/?q=test%0Afoo", &headers);
	if (validate_header(&headers, "q", "test\nfoo") != 0)
		goto fail;
	evhttp_clear_headers(&headers);

	evhttp_parse_query("http://www.test.com/?q=test%0Dfoo", &headers);
	if (validate_header(&headers, "q", "test\rfoo") != 0)
		goto fail;
	evhttp_clear_headers(&headers);

	fprintf(stdout, "OK\n");
	return;
fail:
	fprintf(stdout, "FAILED\n");
	exit(1);
}

static void
http_base_test(void)
{
	struct bufferevent *bev;
	int fd;
	const char *http_request;
	short port = -1;

	test_ok = 0;
	fprintf(stdout, "Testing HTTP Server Event Base: ");

	base = event_init();

	/* 
	 * create another bogus base - which is being used by all subsequen
	 * tests - yuck!
	 */
	event_init();

	http = http_setup(&port, base);
	
	fd = http_connect("127.0.0.1", port);

	/* Stupid thing to send a request */
	bev = bufferevent_new(fd, http_readcb, http_writecb,
	    http_errorcb, NULL);
	bufferevent_base_set(base, bev);

	http_request =
	    "GET /test HTTP/1.1\r\n"
	    "Host: somehost\r\n"
	    "Connection: close\r\n"
	    "\r\n";

	bufferevent_write(bev, http_request, strlen(http_request));
	
	event_base_dispatch(base);

	bufferevent_free(bev);
	EVUTIL_CLOSESOCKET(fd);

	evhttp_free(http);

	event_base_free(base);
	base = NULL;
	
	if (test_ok != 2) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}
	
	fprintf(stdout, "OK\n");
}

/*
 * the server is going to reply with chunked data.
 */

static void
http_chunked_readcb(struct bufferevent *bev, void *arg)
{
	/* nothing here */
}

static void
http_chunked_errorcb(struct bufferevent *bev, short what, void *arg)
{
	if (!test_ok)
		goto out;

	test_ok = -1;

	if ((what & EVBUFFER_EOF) != 0) {
		struct evhttp_request *req = evhttp_request_new(NULL, NULL);
		const char *header;
		enum message_read_status done;
		
		req->kind = EVHTTP_RESPONSE;
		done = evhttp_parse_firstline(req, EVBUFFER_INPUT(bev));
		if (done != ALL_DATA_READ)
			goto out;

		done = evhttp_parse_headers(req, EVBUFFER_INPUT(bev));
		if (done != ALL_DATA_READ)
			goto out;

		header = evhttp_find_header(req->input_headers, "Transfer-Encoding");
		if (header == NULL || strcmp(header, "chunked"))
			goto out;

		header = evhttp_find_header(req->input_headers, "Connection");
		if (header == NULL || strcmp(header, "close"))
			goto out;

		header = evbuffer_readline(EVBUFFER_INPUT(bev));
		if (header == NULL)
			goto out;
		/* 13 chars */
		if (strcmp(header, "d"))
			goto out;
		free((char*)header);

		if (strncmp((char *)EVBUFFER_DATA(EVBUFFER_INPUT(bev)),
			"This is funny", 13))
			goto out;

		evbuffer_drain(EVBUFFER_INPUT(bev), 13 + 2);

		header = evbuffer_readline(EVBUFFER_INPUT(bev));
		if (header == NULL)
			goto out;
		/* 18 chars */
		if (strcmp(header, "12"))
			goto out;
		free((char *)header);

		if (strncmp((char *)EVBUFFER_DATA(EVBUFFER_INPUT(bev)),
			"but not hilarious.", 18))
			goto out;

		evbuffer_drain(EVBUFFER_INPUT(bev), 18 + 2);

		header = evbuffer_readline(EVBUFFER_INPUT(bev));
		if (header == NULL)
			goto out;
		/* 8 chars */
		if (strcmp(header, "8"))
			goto out;
		free((char *)header);

		if (strncmp((char *)EVBUFFER_DATA(EVBUFFER_INPUT(bev)),
			"bwv 1052.", 8))
			goto out;

		evbuffer_drain(EVBUFFER_INPUT(bev), 8 + 2);

		header = evbuffer_readline(EVBUFFER_INPUT(bev));
		if (header == NULL)
			goto out;
		/* 0 chars */
		if (strcmp(header, "0"))
			goto out;
		free((char *)header);

		test_ok = 2;
	}

out:
	event_loopexit(NULL);
}

static void
http_chunked_writecb(struct bufferevent *bev, void *arg)
{
	if (EVBUFFER_LENGTH(EVBUFFER_OUTPUT(bev)) == 0) {
		/* enable reading of the reply */
		bufferevent_enable(bev, EV_READ);
		test_ok++;
	}
}

static void
http_chunked_request_done(struct evhttp_request *req, void *arg)
{
	if (req->response_code != HTTP_OK) {
		fprintf(stderr, "FAILED\n");
		exit(1);
	}

	if (evhttp_find_header(req->input_headers,
		"Transfer-Encoding") == NULL) {
		fprintf(stderr, "FAILED\n");
		exit(1);
	}

	if (EVBUFFER_LENGTH(req->input_buffer) != 13 + 18 + 8) {
		fprintf(stderr, "FAILED\n");
		exit(1);
	}

	if (strncmp((char *)EVBUFFER_DATA(req->input_buffer),
		"This is funnybut not hilarious.bwv 1052",
		13 + 18 + 8)) {
		fprintf(stderr, "FAILED\n");
		exit(1);
	}
	
	test_ok = 1;
	event_loopexit(NULL);
}

static void
http_chunked_test(void)
{
	struct bufferevent *bev;
	int fd;
	const char *http_request;
	short port = -1;
	struct timeval tv_start, tv_end;
	struct evhttp_connection *evcon = NULL;
	struct evhttp_request *req = NULL;
	int i;

	test_ok = 0;
	fprintf(stdout, "Testing Chunked HTTP Reply: ");

	http = http_setup(&port, NULL);

	fd = http_connect("127.0.0.1", port);

	/* Stupid thing to send a request */
	bev = bufferevent_new(fd, 
	    http_chunked_readcb, http_chunked_writecb,
	    http_chunked_errorcb, NULL);

	http_request =
	    "GET /chunked HTTP/1.1\r\n"
	    "Host: somehost\r\n"
	    "Connection: close\r\n"
	    "\r\n";

	bufferevent_write(bev, http_request, strlen(http_request));

	evutil_gettimeofday(&tv_start, NULL);
	
	event_dispatch();

	evutil_gettimeofday(&tv_end, NULL);
	evutil_timersub(&tv_end, &tv_start, &tv_end);

	if (tv_end.tv_sec >= 1) {
		fprintf(stdout, "FAILED (time)\n");
		exit (1);
	}


	if (test_ok != 2) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	/* now try again with the regular connection object */
	evcon = evhttp_connection_new("127.0.0.1", port);
	if (evcon == NULL) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	/* make two requests to check the keepalive behavior */
	for (i = 0; i < 2; i++) {
		test_ok = 0;
		req = evhttp_request_new(http_chunked_request_done, NULL);

		/* Add the information that we care about */
		evhttp_add_header(req->output_headers, "Host", "somehost");

		/* We give ownership of the request to the connection */
		if (evhttp_make_request(evcon, req,
			EVHTTP_REQ_GET, "/chunked") == -1) {
			fprintf(stdout, "FAILED\n");
			exit(1);
		}

		event_dispatch();

		if (test_ok != 1) {
			fprintf(stdout, "FAILED\n");
			exit(1);
		}
	}

	evhttp_connection_free(evcon);
	evhttp_free(http);
	
	fprintf(stdout, "OK\n");
}

static void
http_multi_line_header_test(void)
{
	struct bufferevent *bev;
	int fd;
	const char *http_start_request;
	short port = -1;
	
	test_ok = 0;
	fprintf(stdout, "Testing HTTP Server with multi line: ");

	http = http_setup(&port, NULL);
	
	fd = http_connect("127.0.0.1", port);

	/* Stupid thing to send a request */
	bev = bufferevent_new(fd, http_readcb, http_writecb,
	    http_errorcb, NULL);

	http_start_request =
	    "GET /test HTTP/1.1\r\n"
	    "Host: somehost\r\n"
	    "Connection: close\r\n"
	    "X-Multi:  aaaaaaaa\r\n"
	    " a\r\n"
	    "\tEND\r\n"
	    "X-Last: last\r\n"
	    "\r\n";
		
	bufferevent_write(bev, http_start_request, strlen(http_start_request));

	event_dispatch();
	
	bufferevent_free(bev);
	EVUTIL_CLOSESOCKET(fd);

	evhttp_free(http);

	if (test_ok != 4) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}
	
	fprintf(stdout, "OK\n");
}

static void
http_request_bad(struct evhttp_request *req, void *arg)
{
	if (req != NULL) {
		fprintf(stderr, "FAILED\n");
		exit(1);
	}

	test_ok = 1;
	event_loopexit(NULL);
}

static void
http_negative_content_length_test(void)
{
	short port = -1;
	struct evhttp_connection *evcon = NULL;
	struct evhttp_request *req = NULL;
	
	test_ok = 0;
	fprintf(stdout, "Testing HTTP Negative Content Length: ");

	http = http_setup(&port, NULL);

	evcon = evhttp_connection_new("127.0.0.1", port);
	if (evcon == NULL) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	/*
	 * At this point, we want to schedule a request to the HTTP
	 * server using our make request method.
	 */

	req = evhttp_request_new(http_request_bad, NULL);

	/* Cause the response to have a negative content-length */
	evhttp_add_header(req->output_headers, "X-Negative", "makeitso");

	/* We give ownership of the request to the connection */
	if (evhttp_make_request(evcon, req, EVHTTP_REQ_GET, "/test") == -1) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	event_dispatch();

	evhttp_free(http);

	if (test_ok != 1) {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	fprintf(stdout, "OK\n");
}

void
http_suite(void)
{
	http_base_test();
	http_bad_header_test();
	http_parse_query_test();
	http_basic_test();
	http_connection_test(0 /* not-persistent */);
	http_connection_test(1 /* persistent */);
	http_close_detection(0 /* with delay */);
	http_close_detection(1 /* with delay */);
	http_post_test();
	http_failure_test();
	http_highport_test();
	http_dispatcher_test();

	http_multi_line_header_test();
	http_negative_content_length_test();

	http_chunked_test();
}
