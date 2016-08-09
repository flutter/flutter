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
#ifndef _EVHTTP_H_
#define _EVHTTP_H_

#include "event.h"

#ifdef __cplusplus
extern "C" {
#endif

#ifdef WIN32
#define WIN32_LEAN_AND_MEAN
#include <winsock2.h>
#include <windows.h>
#undef WIN32_LEAN_AND_MEAN
#endif

/** @file evhttp.h
 *
 * Basic support for HTTP serving.
 *
 * As libevent is a library for dealing with event notification and most
 * interesting applications are networked today, I have often found the
 * need to write HTTP code.  The following prototypes and definitions provide
 * an application with a minimal interface for making HTTP requests and for
 * creating a very simple HTTP server.
 */

/* Response codes */
#define HTTP_OK			200
#define HTTP_NOCONTENT		204
#define HTTP_MOVEPERM		301
#define HTTP_MOVETEMP		302
#define HTTP_NOTMODIFIED	304
#define HTTP_BADREQUEST		400
#define HTTP_NOTFOUND		404
#define HTTP_SERVUNAVAIL	503

struct evhttp;
struct evhttp_request;
struct evkeyvalq;

/** Create a new HTTP server
 *
 * @param base (optional) the event base to receive the HTTP events
 * @return a pointer to a newly initialized evhttp server structure
 */
struct evhttp *evhttp_new(struct event_base *base);

/**
 * Binds an HTTP server on the specified address and port.
 *
 * Can be called multiple times to bind the same http server
 * to multiple different ports.
 *
 * @param http a pointer to an evhttp object
 * @param address a string containing the IP address to listen(2) on
 * @param port the port number to listen on
 * @return a newly allocated evhttp struct
 * @see evhttp_free()
 */
int evhttp_bind_socket(struct evhttp *http, const char *address, u_short port);

/**
 * Makes an HTTP server accept connections on the specified socket
 *
 * This may be useful to create a socket and then fork multiple instances
 * of an http server, or when a socket has been communicated via file
 * descriptor passing in situations where an http servers does not have
 * permissions to bind to a low-numbered port.
 *
 * Can be called multiple times to have the http server listen to
 * multiple different sockets.
 *
 * @param http a pointer to an evhttp object
 * @param fd a socket fd that is ready for accepting connections
 * @return 0 on success, -1 on failure.
 * @see evhttp_free(), evhttp_bind_socket()
 */
int evhttp_accept_socket(struct evhttp *http, int fd);

/**
 * Free the previously created HTTP server.
 *
 * Works only if no requests are currently being served.
 *
 * @param http the evhttp server object to be freed
 * @see evhttp_start()
 */
void evhttp_free(struct evhttp* http);

/** Set a callback for a specified URI */
void evhttp_set_cb(struct evhttp *, const char *,
    void (*)(struct evhttp_request *, void *), void *);

/** Removes the callback for a specified URI */
int evhttp_del_cb(struct evhttp *, const char *);

/** Set a callback for all requests that are not caught by specific callbacks
 */
void evhttp_set_gencb(struct evhttp *,
    void (*)(struct evhttp_request *, void *), void *);

/**
 * Set the timeout for an HTTP request.
 *
 * @param http an evhttp object
 * @param timeout_in_secs the timeout, in seconds
 */
void evhttp_set_timeout(struct evhttp *, int timeout_in_secs);

/* Request/Response functionality */

/**
 * Send an HTML error message to the client.
 *
 * @param req a request object
 * @param error the HTTP error code
 * @param reason a brief explanation of the error
 */
void evhttp_send_error(struct evhttp_request *req, int error,
    const char *reason);

/**
 * Send an HTML reply to the client.
 *
 * @param req a request object
 * @param code the HTTP response code to send
 * @param reason a brief message to send with the response code
 * @param databuf the body of the response
 */
void evhttp_send_reply(struct evhttp_request *req, int code,
    const char *reason, struct evbuffer *databuf);

/* Low-level response interface, for streaming/chunked replies */
void evhttp_send_reply_start(struct evhttp_request *, int, const char *);
void evhttp_send_reply_chunk(struct evhttp_request *, struct evbuffer *);
void evhttp_send_reply_end(struct evhttp_request *);

/**
 * Start an HTTP server on the specified address and port
 *
 * DEPRECATED: it does not allow an event base to be specified
 *
 * @param address the address to which the HTTP server should be bound
 * @param port the port number on which the HTTP server should listen
 * @return an struct evhttp object
 */
struct evhttp *evhttp_start(const char *address, u_short port);

/*
 * Interfaces for making requests
 */
enum evhttp_cmd_type { EVHTTP_REQ_GET, EVHTTP_REQ_POST, EVHTTP_REQ_HEAD };

enum evhttp_request_kind { EVHTTP_REQUEST, EVHTTP_RESPONSE };

/**
 * the request structure that a server receives.
 * WARNING: expect this structure to change.  I will try to provide
 * reasonable accessors.
 */
struct evhttp_request {
#if defined(TAILQ_ENTRY)
	TAILQ_ENTRY(evhttp_request) next;
#else
struct {
	struct evhttp_request *tqe_next;
	struct evhttp_request **tqe_prev;
}       next;
#endif

	/* the connection object that this request belongs to */
	struct evhttp_connection *evcon;
	int flags;
#define EVHTTP_REQ_OWN_CONNECTION	0x0001
#define EVHTTP_PROXY_REQUEST		0x0002

	struct evkeyvalq *input_headers;
	struct evkeyvalq *output_headers;

	/* address of the remote host and the port connection came from */
	char *remote_host;
	u_short remote_port;

	enum evhttp_request_kind kind;
	enum evhttp_cmd_type type;

	char *uri;			/* uri after HTTP request was parsed */

	char major;			/* HTTP Major number */
	char minor;			/* HTTP Minor number */

	int response_code;		/* HTTP Response code */
	char *response_code_line;	/* Readable response */

	struct evbuffer *input_buffer;	/* read data */
	ev_int64_t ntoread;
	int chunked;

	struct evbuffer *output_buffer;	/* outgoing post or data */

	/* Callback */
	void (*cb)(struct evhttp_request *, void *);
	void *cb_arg;

	/*
	 * Chunked data callback - call for each completed chunk if
	 * specified.  If not specified, all the data is delivered via
	 * the regular callback.
	 */
	void (*chunk_cb)(struct evhttp_request *, void *);
};

/**
 * Creates a new request object that needs to be filled in with the request
 * parameters.  The callback is executed when the request completed or an
 * error occurred.
 */
struct evhttp_request *evhttp_request_new(
	void (*cb)(struct evhttp_request *, void *), void *arg);

/** enable delivery of chunks to requestor */
void evhttp_request_set_chunked_cb(struct evhttp_request *,
    void (*cb)(struct evhttp_request *, void *));

/** Frees the request object and removes associated events. */
void evhttp_request_free(struct evhttp_request *req);

/**
 * A connection object that can be used to for making HTTP requests.  The
 * connection object tries to establish the connection when it is given an
 * http request object.
 */
struct evhttp_connection *evhttp_connection_new(
	const char *address, unsigned short port);

/** Frees an http connection */
void evhttp_connection_free(struct evhttp_connection *evcon);

/** sets the ip address from which http connections are made */
void evhttp_connection_set_local_address(struct evhttp_connection *evcon,
    const char *address);

/** sets the local port from which http connections are made */
void evhttp_connection_set_local_port(struct evhttp_connection *evcon,
    unsigned short port);

/** Sets the timeout for events related to this connection */
void evhttp_connection_set_timeout(struct evhttp_connection *evcon,
    int timeout_in_secs);

/** Sets the retry limit for this connection - -1 repeats indefnitely */
void evhttp_connection_set_retries(struct evhttp_connection *evcon,
    int retry_max);

/** Set a callback for connection close. */
void evhttp_connection_set_closecb(struct evhttp_connection *evcon,
    void (*)(struct evhttp_connection *, void *), void *);

/**
 * Associates an event base with the connection - can only be called
 * on a freshly created connection object that has not been used yet.
 */
void evhttp_connection_set_base(struct evhttp_connection *evcon,
    struct event_base *base);

/** Get the remote address and port associated with this connection. */
void evhttp_connection_get_peer(struct evhttp_connection *evcon,
    char **address, u_short *port);

/** The connection gets ownership of the request */
int evhttp_make_request(struct evhttp_connection *evcon,
    struct evhttp_request *req,
    enum evhttp_cmd_type type, const char *uri);

const char *evhttp_request_uri(struct evhttp_request *req);

/* Interfaces for dealing with HTTP headers */

const char *evhttp_find_header(const struct evkeyvalq *, const char *);
int evhttp_remove_header(struct evkeyvalq *, const char *);
int evhttp_add_header(struct evkeyvalq *, const char *, const char *);
void evhttp_clear_headers(struct evkeyvalq *);

/* Miscellaneous utility functions */


/**
  Helper function to encode a URI.

  The returned string must be freed by the caller.

  @param uri an unencoded URI
  @return a newly allocated URI-encoded string
 */
char *evhttp_encode_uri(const char *uri);


/**
  Helper function to decode a URI.

  The returned string must be freed by the caller.

  @param uri an encoded URI
  @return a newly allocated unencoded URI
 */
char *evhttp_decode_uri(const char *uri);


/**
 * Helper function to parse out arguments in a query.
 *
 * Parsing a uri like
 *
 *    http://foo.com/?q=test&s=some+thing
 *
 * will result in two entries in the key value queue.

 * The first entry is: key="q", value="test"
 * The second entry is: key="s", value="some thing"
 *
 * @param uri the request URI
 * @param headers the head of the evkeyval queue
 */
void evhttp_parse_query(const char *uri, struct evkeyvalq *headers);


/**
 * Escape HTML character entities in a string.
 *
 * Replaces <, >, ", ' and & with &lt;, &gt;, &quot;,
 * &#039; and &amp; correspondingly.
 *
 * The returned string needs to be freed by the caller.
 *
 * @param html an unescaped HTML string
 * @return an escaped HTML string
 */
char *evhttp_htmlescape(const char *html);

#ifdef __cplusplus
}
#endif

#endif /* _EVHTTP_H_ */
