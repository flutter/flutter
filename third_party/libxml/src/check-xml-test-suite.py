#!/usr/bin/python
import sys
import time
import os
import string
sys.path.insert(0, "python")
import libxml2

test_nr = 0
test_succeed = 0
test_failed = 0
test_error = 0

#
# the testsuite description
#
CONF="xml-test-suite/xmlconf/xmlconf.xml"
LOG="check-xml-test-suite.log"

log = open(LOG, "w")

#
# Error and warning handlers
#
error_nr = 0
error_msg = ''
def errorHandler(ctx, str):
    global error_nr
    global error_msg

    error_nr = error_nr + 1
    if len(error_msg) < 300:
        if len(error_msg) == 0 or error_msg[-1] == '\n':
	    error_msg = error_msg + "   >>" + str
	else:
	    error_msg = error_msg + str

libxml2.registerErrorHandler(errorHandler, None)

#warning_nr = 0
#warning = ''
#def warningHandler(ctx, str):
#    global warning_nr
#    global warning
#
#    warning_nr = warning_nr + 1
#    warning = warning + str
#
#libxml2.registerWarningHandler(warningHandler, None)

#
# Used to load the XML testsuite description
#
def loadNoentDoc(filename):
    ctxt = libxml2.createFileParserCtxt(filename)
    if ctxt == None:
        return None
    ctxt.replaceEntities(1)
    ctxt.parseDocument()
    try:
	doc = ctxt.doc()
    except:
        doc = None
    if ctxt.wellFormed() != 1:
        doc.freeDoc()
	return None
    return doc

#
# The conformance testing routines
#

def testNotWf(filename, id):
    global error_nr
    global error_msg
    global log

    error_nr = 0
    error_msg = ''

    ctxt = libxml2.createFileParserCtxt(filename)
    if ctxt == None:
        return -1
    ret = ctxt.parseDocument()

    try:
	doc = ctxt.doc()
    except:
        doc = None
    if doc != None:
	doc.freeDoc()
    if ret == 0 or ctxt.wellFormed() != 0:
        print "%s: error: Well Formedness error not detected" % (id)
	log.write("%s: error: Well Formedness error not detected\n" % (id))
	return 0
    return 1

def testNotWfEnt(filename, id):
    global error_nr
    global error_msg
    global log

    error_nr = 0
    error_msg = ''

    ctxt = libxml2.createFileParserCtxt(filename)
    if ctxt == None:
        return -1
    ctxt.replaceEntities(1)
    ret = ctxt.parseDocument()

    try:
	doc = ctxt.doc()
    except:
        doc = None
    if doc != None:
	doc.freeDoc()
    if ret == 0 or ctxt.wellFormed() != 0:
        print "%s: error: Well Formedness error not detected" % (id)
	log.write("%s: error: Well Formedness error not detected\n" % (id))
	return 0
    return 1

def testNotWfEntDtd(filename, id):
    global error_nr
    global error_msg
    global log

    error_nr = 0
    error_msg = ''

    ctxt = libxml2.createFileParserCtxt(filename)
    if ctxt == None:
        return -1
    ctxt.replaceEntities(1)
    ctxt.loadSubset(1)
    ret = ctxt.parseDocument()

    try:
	doc = ctxt.doc()
    except:
        doc = None
    if doc != None:
	doc.freeDoc()
    if ret == 0 or ctxt.wellFormed() != 0:
        print "%s: error: Well Formedness error not detected" % (id)
	log.write("%s: error: Well Formedness error not detected\n" % (id))
	return 0
    return 1

def testWfEntDtd(filename, id):
    global error_nr
    global error_msg
    global log

    error_nr = 0
    error_msg = ''

    ctxt = libxml2.createFileParserCtxt(filename)
    if ctxt == None:
        return -1
    ctxt.replaceEntities(1)
    ctxt.loadSubset(1)
    ret = ctxt.parseDocument()

    try:
	doc = ctxt.doc()
    except:
        doc = None
    if doc == None or ret != 0 or ctxt.wellFormed() == 0:
        print "%s: error: wrongly failed to parse the document" % (id)
	log.write("%s: error: wrongly failed to parse the document\n" % (id))
	if doc != None:
	    doc.freeDoc()
	return 0
    if error_nr != 0:
        print "%s: warning: WF document generated an error msg" % (id)
	log.write("%s: error: WF document generated an error msg\n" % (id))
	doc.freeDoc()
	return 2
    doc.freeDoc()
    return 1

def testError(filename, id):
    global error_nr
    global error_msg
    global log

    error_nr = 0
    error_msg = ''

    ctxt = libxml2.createFileParserCtxt(filename)
    if ctxt == None:
        return -1
    ctxt.replaceEntities(1)
    ctxt.loadSubset(1)
    ret = ctxt.parseDocument()

    try:
	doc = ctxt.doc()
    except:
        doc = None
    if doc != None:
	doc.freeDoc()
    if ctxt.wellFormed() == 0:
        print "%s: warning: failed to parse the document but accepted" % (id)
	log.write("%s: warning: failed to parse the document but accepte\n" % (id))
	return 2
    if error_nr != 0:
        print "%s: warning: WF document generated an error msg" % (id)
	log.write("%s: error: WF document generated an error msg\n" % (id))
	return 2
    return 1

def testInvalid(filename, id):
    global error_nr
    global error_msg
    global log

    error_nr = 0
    error_msg = ''

    ctxt = libxml2.createFileParserCtxt(filename)
    if ctxt == None:
        return -1
    ctxt.validate(1)
    ret = ctxt.parseDocument()

    try:
	doc = ctxt.doc()
    except:
        doc = None
    valid = ctxt.isValid()
    if doc == None:
        print "%s: error: wrongly failed to parse the document" % (id)
	log.write("%s: error: wrongly failed to parse the document\n" % (id))
	return 0
    if valid == 1:
        print "%s: error: Validity error not detected" % (id)
	log.write("%s: error: Validity error not detected\n" % (id))
	doc.freeDoc()
	return 0
    if error_nr == 0:
        print "%s: warning: Validity error not reported" % (id)
	log.write("%s: warning: Validity error not reported\n" % (id))
	doc.freeDoc()
	return 2
        
    doc.freeDoc()
    return 1

def testValid(filename, id):
    global error_nr
    global error_msg

    error_nr = 0
    error_msg = ''

    ctxt = libxml2.createFileParserCtxt(filename)
    if ctxt == None:
        return -1
    ctxt.validate(1)
    ctxt.parseDocument()

    try:
	doc = ctxt.doc()
    except:
        doc = None
    valid = ctxt.isValid()
    if doc == None:
        print "%s: error: wrongly failed to parse the document" % (id)
	log.write("%s: error: wrongly failed to parse the document\n" % (id))
	return 0
    if valid != 1:
        print "%s: error: Validity check failed" % (id)
	log.write("%s: error: Validity check failed\n" % (id))
	doc.freeDoc()
	return 0
    if error_nr != 0 or valid != 1:
        print "%s: warning: valid document reported an error" % (id)
	log.write("%s: warning: valid document reported an error\n" % (id))
	doc.freeDoc()
	return 2
    doc.freeDoc()
    return 1

def runTest(test):
    global test_nr
    global test_succeed
    global test_failed
    global error_msg
    global log

    uri = test.prop('URI')
    id = test.prop('ID')
    if uri == None:
        print "Test without ID:", uri
	return -1
    if id == None:
        print "Test without URI:", id
	return -1
    base = test.getBase(None)
    URI = libxml2.buildURI(uri, base)
    if os.access(URI, os.R_OK) == 0:
        print "Test %s missing: base %s uri %s" % (URI, base, uri)
	return -1
    type = test.prop('TYPE')
    if type == None:
        print "Test %s missing TYPE" % (id)
	return -1

    extra = None
    if type == "invalid":
        res = testInvalid(URI, id)
    elif type == "valid":
        res = testValid(URI, id)
    elif type == "not-wf":
        extra =  test.prop('ENTITIES')
	# print URI
	#if extra == None:
	#    res = testNotWfEntDtd(URI, id)
 	#elif extra == 'none':
	#    res = testNotWf(URI, id)
	#elif extra == 'general':
	#    res = testNotWfEnt(URI, id)
	#elif extra == 'both' or extra == 'parameter':
	res = testNotWfEntDtd(URI, id)
	#else:
	#    print "Unknow value %s for an ENTITIES test value" % (extra)
	#    return -1
    elif type == "error":
	res = testError(URI, id)
    else:
        # TODO skipped for now
	return -1

    test_nr = test_nr + 1
    if res > 0:
	test_succeed = test_succeed + 1
    elif res == 0:
	test_failed = test_failed + 1
    elif res < 0:
	test_error = test_error + 1

    # Log the ontext
    if res != 1:
	log.write("   File: %s\n" % (URI))
	content = string.strip(test.content)
	while content[-1] == '\n':
	    content = content[0:-1]
	if extra != None:
	    log.write("   %s:%s:%s\n" % (type, extra, content))
	else:
	    log.write("   %s:%s\n\n" % (type, content))
	if error_msg != '':
	    log.write("   ----\n%s   ----\n" % (error_msg))
	    error_msg = ''
	log.write("\n")

    return 0
	    

def runTestCases(case):
    profile = case.prop('PROFILE')
    if profile != None and \
       string.find(profile, "IBM XML Conformance Test Suite - Production") < 0:
	print "=>", profile
    test = case.children
    while test != None:
        if test.name == 'TEST':
	    runTest(test)
	if test.name == 'TESTCASES':
	    runTestCases(test)
        test = test.next
        
conf = loadNoentDoc(CONF)
if conf == None:
    print "Unable to load %s" % CONF
    sys.exit(1)

testsuite = conf.getRootElement()
if testsuite.name != 'TESTSUITE':
    print "Expecting TESTSUITE root element: aborting"
    sys.exit(1)

profile = testsuite.prop('PROFILE')
if profile != None:
    print profile

start = time.time()

case = testsuite.children
while case != None:
    if case.name == 'TESTCASES':
	old_test_nr = test_nr
	old_test_succeed = test_succeed
	old_test_failed = test_failed
	old_test_error = test_error
        runTestCases(case)
	print "   Ran %d tests: %d suceeded, %d failed and %d generated an error" % (
	       test_nr - old_test_nr, test_succeed - old_test_succeed,
	       test_failed - old_test_failed, test_error - old_test_error)
    case = case.next

conf.freeDoc()
log.close()

print "Ran %d tests: %d suceeded, %d failed and %d generated an error in %.2f s." % (
      test_nr, test_succeed, test_failed, test_error, time.time() - start)
