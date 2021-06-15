#!/usr/bin/python
import sys
import time
import os
import string
import StringIO
sys.path.insert(0, "python")
import libxml2

# Memory debug specific
libxml2.debugMemory(1)
debug = 0
verbose = 0
quiet = 1

#
# the testsuite description
#
CONF=os.path.join(os.path.dirname(__file__), "test/xsdtest/xsdtestsuite.xml")
LOG="check-xsddata-test-suite.log"

log = open(LOG, "w")
nb_schemas_tests = 0
nb_schemas_success = 0
nb_schemas_failed = 0
nb_instances_tests = 0
nb_instances_success = 0
nb_instances_failed = 0

libxml2.lineNumbersDefault(1)
#
# Error and warnng callbacks
#
def callback(ctx, str):
    global log
    log.write("%s%s" % (ctx, str))

libxml2.registerErrorHandler(callback, "")

#
# Resolver callback
#
resources = {}
def resolver(URL, ID, ctxt):
    global resources

    if resources.has_key(URL):
        return(StringIO.StringIO(resources[URL]))
    log.write("Resolver failure: asked %s\n" % (URL))
    log.write("resources: %s\n" % (resources))
    return None

#
# handle a valid instance
#
def handle_valid(node, schema):
    global log
    global nb_instances_success
    global nb_instances_failed

    instance = node.prop("dtd")
    if instance == None:
        instance = ""
    child = node.children
    while child != None:
        if child.type != 'text':
	    instance = instance + child.serialize()
	child = child.next

    mem = libxml2.debugMemory(1);
    try:
	doc = libxml2.parseDoc(instance)
    except:
        doc = None

    if doc == None:
        log.write("\nFailed to parse correct instance:\n-----\n")
	log.write(instance)
        log.write("\n-----\n")
	nb_instances_failed = nb_instances_failed + 1
	return

    if debug:
        print "instance line %d" % (node.lineNo())
       
    try:
        ctxt = schema.relaxNGNewValidCtxt()
	ret = doc.relaxNGValidateDoc(ctxt)
	del ctxt
    except:
        ret = -1

    doc.freeDoc()
    if mem != libxml2.debugMemory(1):
	print "validating instance %d line %d leaks" % (
		  nb_instances_tests, node.lineNo())

    if ret != 0:
        log.write("\nFailed to validate correct instance:\n-----\n")
	log.write(instance)
        log.write("\n-----\n")
	nb_instances_failed = nb_instances_failed + 1
    else:
	nb_instances_success = nb_instances_success + 1

#
# handle an invalid instance
#
def handle_invalid(node, schema):
    global log
    global nb_instances_success
    global nb_instances_failed

    instance = node.prop("dtd")
    if instance == None:
        instance = ""
    child = node.children
    while child != None:
        if child.type != 'text':
	    instance = instance + child.serialize()
	child = child.next

#    mem = libxml2.debugMemory(1);

    try:
	doc = libxml2.parseDoc(instance)
    except:
        doc = None

    if doc == None:
        log.write("\nStrange: failed to parse incorrect instance:\n-----\n")
	log.write(instance)
        log.write("\n-----\n")
	return

    if debug:
        print "instance line %d" % (node.lineNo())
       
    try:
        ctxt = schema.relaxNGNewValidCtxt()
	ret = doc.relaxNGValidateDoc(ctxt)
	del ctxt

    except:
        ret = -1

    doc.freeDoc()
#    if mem != libxml2.debugMemory(1):
#	print "validating instance %d line %d leaks" % (
#		  nb_instances_tests, node.lineNo())
    
    if ret == 0:
        log.write("\nFailed to detect validation problem in instance:\n-----\n")
	log.write(instance)
        log.write("\n-----\n")
	nb_instances_failed = nb_instances_failed + 1
    else:
	nb_instances_success = nb_instances_success + 1

#
# handle an incorrect test
#
def handle_correct(node):
    global log
    global nb_schemas_success
    global nb_schemas_failed

    schema = ""
    child = node.children
    while child != None:
        if child.type != 'text':
	    schema = schema + child.serialize()
	child = child.next

    try:
	rngp = libxml2.relaxNGNewMemParserCtxt(schema, len(schema))
	rngs = rngp.relaxNGParse()
    except:
        rngs = None
    if rngs == None:
        log.write("\nFailed to compile correct schema:\n-----\n")
	log.write(schema)
        log.write("\n-----\n")
	nb_schemas_failed = nb_schemas_failed + 1
    else:
	nb_schemas_success = nb_schemas_success + 1
    return rngs
        
def handle_incorrect(node):
    global log
    global nb_schemas_success
    global nb_schemas_failed

    schema = ""
    child = node.children
    while child != None:
        if child.type != 'text':
	    schema = schema + child.serialize()
	child = child.next

    try:
	rngp = libxml2.relaxNGNewMemParserCtxt(schema, len(schema))
	rngs = rngp.relaxNGParse()
    except:
        rngs = None
    if rngs != None:
        log.write("\nFailed to detect schema error in:\n-----\n")
	log.write(schema)
        log.write("\n-----\n")
	nb_schemas_failed = nb_schemas_failed + 1
    else:
#	log.write("\nSuccess detecting schema error in:\n-----\n")
#	log.write(schema)
#	log.write("\n-----\n")
	nb_schemas_success = nb_schemas_success + 1
    return None

#
# resource handling: keep a dictionary of URL->string mappings
#
def handle_resource(node, dir):
    global resources

    try:
	name = node.prop('name')
    except:
        name = None

    if name == None or name == '':
        log.write("resource has no name")
	return;
        
    if dir != None:
#        name = libxml2.buildURI(name, dir)
        name = dir + '/' + name

    res = ""
    child = node.children
    while child != None:
        if child.type != 'text':
	    res = res + child.serialize()
	child = child.next
    resources[name] = res

#
# dir handling: pseudo directory resources
#
def handle_dir(node, dir):
    try:
	name = node.prop('name')
    except:
        name = None

    if name == None or name == '':
        log.write("resource has no name")
	return;
        
    if dir != None:
#        name = libxml2.buildURI(name, dir)
        name = dir + '/' + name

    dirs = node.xpathEval('dir')
    for dir in dirs:
        handle_dir(dir, name)
    res = node.xpathEval('resource')
    for r in res:
        handle_resource(r, name)

#
# handle a testCase element
#
def handle_testCase(node):
    global nb_schemas_tests
    global nb_instances_tests
    global resources

    sections = node.xpathEval('string(section)')
    log.write("\n    ======== test %d line %d section %s ==========\n" % (

              nb_schemas_tests, node.lineNo(), sections))
    resources = {}
    if debug:
        print "test %d line %d" % (nb_schemas_tests, node.lineNo())

    dirs = node.xpathEval('dir')
    for dir in dirs:
        handle_dir(dir, None)
    res = node.xpathEval('resource')
    for r in res:
        handle_resource(r, None)

    tsts = node.xpathEval('incorrect')
    if tsts != []:
        if len(tsts) != 1:
	    print "warning test line %d has more than one <incorrect> example" %(node.lineNo())
	schema = handle_incorrect(tsts[0])
    else:
        tsts = node.xpathEval('correct')
	if tsts != []:
	    if len(tsts) != 1:
		print "warning test line %d has more than one <correct> example"% (node.lineNo())
	    schema = handle_correct(tsts[0])
	else:
	    print "warning <testCase> line %d has no <correct> nor <incorrect> child" % (node.lineNo())

    nb_schemas_tests = nb_schemas_tests + 1;
    
    valids = node.xpathEval('valid')
    invalids = node.xpathEval('invalid')
    nb_instances_tests = nb_instances_tests + len(valids) + len(invalids)
    if schema != None:
        for valid in valids:
	    handle_valid(valid, schema)
        for invalid in invalids:
	    handle_invalid(invalid, schema)


#
# handle a testSuite element
#
def handle_testSuite(node, level = 0):
    global nb_schemas_tests, nb_schemas_success, nb_schemas_failed
    global nb_instances_tests, nb_instances_success, nb_instances_failed
    if verbose and level >= 0:
	old_schemas_tests = nb_schemas_tests
	old_schemas_success = nb_schemas_success
	old_schemas_failed = nb_schemas_failed
	old_instances_tests = nb_instances_tests
	old_instances_success = nb_instances_success
	old_instances_failed = nb_instances_failed

    docs = node.xpathEval('documentation')
    authors = node.xpathEval('author')
    if docs != []:
        msg = ""
        for doc in docs:
	    msg = msg + doc.content + " "
	if authors != []:
	    msg = msg + "written by "
	    for author in authors:
	        msg = msg + author.content + " "
	if quiet == 0:
	    print msg
    sections = node.xpathEval('section')
    if verbose and sections != [] and level <= 0:
        msg = ""
        for section in sections:
	    msg = msg + section.content + " "
	if quiet == 0:
	    print "Tests for section %s" % (msg)
    for test in node.xpathEval('testCase'):
        handle_testCase(test)
    for test in node.xpathEval('testSuite'):
        handle_testSuite(test, level + 1)
	        

    if verbose and level >= 0 :
        if sections != []:
	    msg = ""
	    for section in sections:
		msg = msg + section.content + " "
	    print "Result of tests for section %s" % (msg)
	elif docs != []:
	    msg = ""
	    for doc in docs:
	        msg = msg + doc.content + " "
	    print "Result of tests for %s" % (msg)

        if nb_schemas_tests != old_schemas_tests:
	    print "found %d test schemas: %d success %d failures" % (
		  nb_schemas_tests - old_schemas_tests,
		  nb_schemas_success - old_schemas_success,
		  nb_schemas_failed - old_schemas_failed)
	if nb_instances_tests != old_instances_tests:
	    print "found %d test instances: %d success %d failures" % (
		  nb_instances_tests - old_instances_tests,
		  nb_instances_success - old_instances_success,
		  nb_instances_failed - old_instances_failed)
#
# Parse the conf file
#
libxml2.substituteEntitiesDefault(1);
testsuite = libxml2.parseFile(CONF)

#
# Error and warnng callbacks
#
def callback(ctx, str):
    global log
    log.write("%s%s" % (ctx, str))

libxml2.registerErrorHandler(callback, "")

libxml2.setEntityLoader(resolver)
root = testsuite.getRootElement()
if root.name != 'testSuite':
    print "%s doesn't start with a testSuite element, aborting" % (CONF)
    sys.exit(1)
if quiet == 0:
    print "Running Relax NG testsuite"
handle_testSuite(root)

if quiet == 0 or nb_schemas_failed != 0:
    print "\nTOTAL:\nfound %d test schemas: %d success %d failures" % (
      nb_schemas_tests, nb_schemas_success, nb_schemas_failed)
if quiet == 0 or nb_instances_failed != 0:
    print "found %d test instances: %d success %d failures" % (
      nb_instances_tests, nb_instances_success, nb_instances_failed)

testsuite.freeDoc()

# Memory debug specific
libxml2.relaxNGCleanupTypes()
libxml2.cleanupParser()
if libxml2.debugMemory(1) == 0:
    if quiet == 0:
	print "OK"
else:
    print "Memory leak %d bytes" % (libxml2.debugMemory(1))
    libxml2.dumpMemory()
