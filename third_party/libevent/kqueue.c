/*	$OpenBSD: kqueue.c,v 1.5 2002/07/10 14:41:31 art Exp $	*/

/*
 * Copyright 2000-2002 Niels Provos <provos@citi.umich.edu>
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

#define _GNU_SOURCE 1

#include <sys/types.h>
#ifdef HAVE_SYS_TIME_H
#include <sys/time.h>
#else
#include <sys/_libevent_time.h>
#endif
#include <sys/queue.h>
#include <sys/event.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <assert.h>
#ifdef HAVE_INTTYPES_H
#include <inttypes.h>
#endif

/* Some platforms apparently define the udata field of struct kevent as
 * intptr_t, whereas others define it as void*.  There doesn't seem to be an
 * easy way to tell them apart via autoconf, so we need to use OS macros. */
#if defined(HAVE_INTTYPES_H) && !defined(__OpenBSD__) && !defined(__FreeBSD__) && !defined(__darwin__) && !defined(__APPLE__)
#define PTR_TO_UDATA(x)	((intptr_t)(x))
#else
#define PTR_TO_UDATA(x)	(x)
#endif

#include "event.h"
#include "event-internal.h"
#include "log.h"

#define EVLIST_X_KQINKERNEL	0x1000

#define NEVENT		64

struct kqop {
	struct kevent *changes;
	int nchanges;
	struct kevent *events;
	struct event_list evsigevents[NSIG];
	int nevents;
	int kq;
	pid_t pid;
};

static void *kq_init	(struct event_base *);
static int kq_add	(void *, struct event *);
static int kq_del	(void *, struct event *);
static int kq_dispatch	(struct event_base *, void *, struct timeval *);
static int kq_insert	(struct kqop *, struct kevent *);
static void kq_dealloc (struct event_base *, void *);

const struct eventop kqops = {
	"kqueue",
	kq_init,
	kq_add,
	kq_del,
	kq_dispatch,
	kq_dealloc,
	1 /* need reinit */
};

static void *
kq_init(struct event_base *base)
{
	int i, kq;
	struct kqop *kqueueop;

	/* Disable kqueue when this environment variable is set */
	if (evutil_getenv("EVENT_NOKQUEUE"))
		return (NULL);

	if (!(kqueueop = calloc(1, sizeof(struct kqop))))
		return (NULL);

	/* Initalize the kernel queue */
	
	if ((kq = kqueue()) == -1) {
		event_warn("kqueue");
		free (kqueueop);
		return (NULL);
	}

	kqueueop->kq = kq;

	kqueueop->pid = getpid();

	/* Initalize fields */
	kqueueop->changes = malloc(NEVENT * sizeof(struct kevent));
	if (kqueueop->changes == NULL) {
		free (kqueueop);
		return (NULL);
	}
	kqueueop->events = malloc(NEVENT * sizeof(struct kevent));
	if (kqueueop->events == NULL) {
		free (kqueueop->changes);
		free (kqueueop);
		return (NULL);
	}
	kqueueop->nevents = NEVENT;

	/* we need to keep track of multiple events per signal */
	for (i = 0; i < NSIG; ++i) {
		TAILQ_INIT(&kqueueop->evsigevents[i]);
	}

	/* Check for Mac OS X kqueue bug. */
	kqueueop->changes[0].ident = -1;
	kqueueop->changes[0].filter = EVFILT_READ;
	kqueueop->changes[0].flags = EV_ADD;
	/* 
	 * If kqueue works, then kevent will succeed, and it will
	 * stick an error in events[0].  If kqueue is broken, then
	 * kevent will fail.
	 */
	if (kevent(kq,
		kqueueop->changes, 1, kqueueop->events, NEVENT, NULL) != 1 ||
	    kqueueop->events[0].ident != -1 ||
	    kqueueop->events[0].flags != EV_ERROR) {
		event_warn("%s: detected broken kqueue; not using.", __func__);
		free(kqueueop->changes);
		free(kqueueop->events);
		free(kqueueop);
		close(kq);
		return (NULL);
	}

	return (kqueueop);
}

static int
kq_insert(struct kqop *kqop, struct kevent *kev)
{
	int nevents = kqop->nevents;

	if (kqop->nchanges == nevents) {
		struct kevent *newchange;
		struct kevent *newresult;

		nevents *= 2;

		newchange = realloc(kqop->changes,
				    nevents * sizeof(struct kevent));
		if (newchange == NULL) {
			event_warn("%s: malloc", __func__);
			return (-1);
		}
		kqop->changes = newchange;

		newresult = realloc(kqop->events,
				    nevents * sizeof(struct kevent));

		/*
		 * If we fail, we don't have to worry about freeing,
		 * the next realloc will pick it up.
		 */
		if (newresult == NULL) {
			event_warn("%s: malloc", __func__);
			return (-1);
		}
		kqop->events = newresult;

		kqop->nevents = nevents;
	}

	memcpy(&kqop->changes[kqop->nchanges++], kev, sizeof(struct kevent));

	event_debug(("%s: fd %d %s%s",
		__func__, (int)kev->ident, 
		kev->filter == EVFILT_READ ? "EVFILT_READ" : "EVFILT_WRITE",
		kev->flags == EV_DELETE ? " (del)" : ""));

	return (0);
}

static void
kq_sighandler(int sig)
{
	/* Do nothing here */
}

static int
kq_dispatch(struct event_base *base, void *arg, struct timeval *tv)
{
	struct kqop *kqop = arg;
	struct kevent *changes = kqop->changes;
	struct kevent *events = kqop->events;
	struct event *ev;
	struct timespec ts, *ts_p = NULL;
	int i, res;

	if (tv != NULL) {
		TIMEVAL_TO_TIMESPEC(tv, &ts);
		ts_p = &ts;
	}

	res = kevent(kqop->kq, changes, kqop->nchanges,
	    events, kqop->nevents, ts_p);
	kqop->nchanges = 0;
	if (res == -1) {
		if (errno != EINTR) {
                        event_warn("kevent");
			return (-1);
		}

		return (0);
	}

	event_debug(("%s: kevent reports %d", __func__, res));

	for (i = 0; i < res; i++) {
		int which = 0;

		if (events[i].flags & EV_ERROR) {
			/* 
			 * Error messages that can happen, when a delete fails.
			 *   EBADF happens when the file discriptor has been
			 *   closed,
			 *   ENOENT when the file discriptor was closed and
			 *   then reopened.
			 *   EINVAL for some reasons not understood; EINVAL
			 *   should not be returned ever; but FreeBSD does :-\
			 * An error is also indicated when a callback deletes
			 * an event we are still processing.  In that case
			 * the data field is set to ENOENT.
			 */
			if (events[i].data == EBADF ||
			    events[i].data == EINVAL ||
			    events[i].data == ENOENT)
				continue;
			errno = events[i].data;
			return (-1);
		}

		if (events[i].filter == EVFILT_READ) {
			which |= EV_READ;
		} else if (events[i].filter == EVFILT_WRITE) {
			which |= EV_WRITE;
		} else if (events[i].filter == EVFILT_SIGNAL) {
			which |= EV_SIGNAL;
		}

		if (!which)
			continue;

		if (events[i].filter == EVFILT_SIGNAL) {
			struct event_list *head =
			    (struct event_list *)events[i].udata;
			TAILQ_FOREACH(ev, head, ev_signal_next) {
				event_active(ev, which, events[i].data);
			}
		} else {
			ev = (struct event *)events[i].udata;

			if (!(ev->ev_events & EV_PERSIST))
				ev->ev_flags &= ~EVLIST_X_KQINKERNEL;

			event_active(ev, which, 1);
		}
	}

	return (0);
}


static int
kq_add(void *arg, struct event *ev)
{
	struct kqop *kqop = arg;
	struct kevent kev;

	if (ev->ev_events & EV_SIGNAL) {
		int nsignal = EVENT_SIGNAL(ev);

		assert(nsignal >= 0 && nsignal < NSIG);
		if (TAILQ_EMPTY(&kqop->evsigevents[nsignal])) {
			struct timespec timeout = { 0, 0 };
			
			memset(&kev, 0, sizeof(kev));
			kev.ident = nsignal;
			kev.filter = EVFILT_SIGNAL;
			kev.flags = EV_ADD;
			kev.udata = PTR_TO_UDATA(&kqop->evsigevents[nsignal]);
			
			/* Be ready for the signal if it is sent any
			 * time between now and the next call to
			 * kq_dispatch. */
			if (kevent(kqop->kq, &kev, 1, NULL, 0, &timeout) == -1)
				return (-1);
			
			if (_evsignal_set_handler(ev->ev_base, nsignal,
				kq_sighandler) == -1)
				return (-1);
		}

		TAILQ_INSERT_TAIL(&kqop->evsigevents[nsignal], ev,
		    ev_signal_next);
		ev->ev_flags |= EVLIST_X_KQINKERNEL;
		return (0);
	}

	if (ev->ev_events & EV_READ) {
 		memset(&kev, 0, sizeof(kev));
		kev.ident = ev->ev_fd;
		kev.filter = EVFILT_READ;
#ifdef NOTE_EOF
		/* Make it behave like select() and poll() */
		kev.fflags = NOTE_EOF;
#endif
		kev.flags = EV_ADD;
		if (!(ev->ev_events & EV_PERSIST))
			kev.flags |= EV_ONESHOT;
		kev.udata = PTR_TO_UDATA(ev);
		
		if (kq_insert(kqop, &kev) == -1)
			return (-1);

		ev->ev_flags |= EVLIST_X_KQINKERNEL;
	}

	if (ev->ev_events & EV_WRITE) {
 		memset(&kev, 0, sizeof(kev));
		kev.ident = ev->ev_fd;
		kev.filter = EVFILT_WRITE;
		kev.flags = EV_ADD;
		if (!(ev->ev_events & EV_PERSIST))
			kev.flags |= EV_ONESHOT;
		kev.udata = PTR_TO_UDATA(ev);
		
		if (kq_insert(kqop, &kev) == -1)
			return (-1);

		ev->ev_flags |= EVLIST_X_KQINKERNEL;
	}

	return (0);
}

static int
kq_del(void *arg, struct event *ev)
{
	struct kqop *kqop = arg;
	struct kevent kev;

	if (!(ev->ev_flags & EVLIST_X_KQINKERNEL))
		return (0);

	if (ev->ev_events & EV_SIGNAL) {
		int nsignal = EVENT_SIGNAL(ev);
		struct timespec timeout = { 0, 0 };

		assert(nsignal >= 0 && nsignal < NSIG);
		TAILQ_REMOVE(&kqop->evsigevents[nsignal], ev, ev_signal_next);
		if (TAILQ_EMPTY(&kqop->evsigevents[nsignal])) {
			memset(&kev, 0, sizeof(kev));
			kev.ident = nsignal;
			kev.filter = EVFILT_SIGNAL;
			kev.flags = EV_DELETE;
		
			/* Because we insert signal events
			 * immediately, we need to delete them
			 * immediately, too */
			if (kevent(kqop->kq, &kev, 1, NULL, 0, &timeout) == -1)
				return (-1);

			if (_evsignal_restore_handler(ev->ev_base,
				nsignal) == -1)
				return (-1);
		}

		ev->ev_flags &= ~EVLIST_X_KQINKERNEL;
		return (0);
	}

	if (ev->ev_events & EV_READ) {
 		memset(&kev, 0, sizeof(kev));
		kev.ident = ev->ev_fd;
		kev.filter = EVFILT_READ;
		kev.flags = EV_DELETE;
		
		if (kq_insert(kqop, &kev) == -1)
			return (-1);

		ev->ev_flags &= ~EVLIST_X_KQINKERNEL;
	}

	if (ev->ev_events & EV_WRITE) {
 		memset(&kev, 0, sizeof(kev));
		kev.ident = ev->ev_fd;
		kev.filter = EVFILT_WRITE;
		kev.flags = EV_DELETE;
		
		if (kq_insert(kqop, &kev) == -1)
			return (-1);

		ev->ev_flags &= ~EVLIST_X_KQINKERNEL;
	}

	return (0);
}

static void
kq_dealloc(struct event_base *base, void *arg)
{
	struct kqop *kqop = arg;

	if (kqop->changes)
		free(kqop->changes);
	if (kqop->events)
		free(kqop->events);
	if (kqop->kq >= 0 && kqop->pid == getpid())
		close(kqop->kq);
	memset(kqop, 0, sizeof(struct kqop));
	free(kqop);
}
