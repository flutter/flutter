#!/bin/sh

setup () {
	 EVENT_NOKQUEUE=yes; export EVENT_NOKQUEUE
	 EVENT_NODEVPOLL=yes; export EVENT_NODEVPOLL
	 EVENT_NOPOLL=yes; export EVENT_NOPOLL
	 EVENT_NOSELECT=yes; export EVENT_NOSELECT
	 EVENT_NOEPOLL=yes; export EVENT_NOEPOLL
	 EVENT_NOEVPORT=yes; export EVENT_NOEVPORT
}

test () {
	if ./test-init 2>/dev/null ;
	then
	        true
	else
		echo Skipping test
		return
	fi	

echo -n " test-eof: "
if ./test-eof >/dev/null ; 
then 
	echo OKAY ; 
else 
	echo FAILED ; 
fi
echo -n " test-weof: "
if ./test-weof >/dev/null ; 
then 
	echo OKAY ; 
else 
	echo FAILED ; 
fi
echo -n " test-time: "
if ./test-time >/dev/null ; 
then 
	echo OKAY ; 
else 
	echo FAILED ; 
fi
echo -n " regress: "
if ./regress >/dev/null ; 
then 
	echo OKAY ; 
else 
	echo FAILED ; 
fi
}

echo "Running tests:"

# Need to do this by hand?
setup
unset EVENT_NOKQUEUE
export EVENT_NOKQUEUE
echo "KQUEUE"
test

setup
unset EVENT_NODEVPOLL
export EVENT_NODEVPOLL
echo "DEVPOLL"
test

setup
unset EVENT_NOPOLL
export EVENT_NOPOLL
echo "POLL"
test

setup
unset EVENT_NOSELECT
export EVENT_NOSELECT
echo "SELECT"
test

setup
unset EVENT_NOEPOLL
export EVENT_NOEPOLL
echo "EPOLL"
test

setup
unset EVENT_NOEVPORT
export EVENT_NOEVPORT
echo "EVPORT"
test



