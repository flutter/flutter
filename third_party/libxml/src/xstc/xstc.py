#!/usr/bin/env python

#
# This is the MS subset of the W3C test suite for XML Schemas.
# This file is generated from the MS W3c test suite description file.
#

import sys, os
import exceptions, optparse
import libxml2

opa = optparse.OptionParser()

opa.add_option("-b", "--base", action="store", type="string", dest="baseDir",
			   default="",
			   help="""The base directory; i.e. the parent folder of the
			   "nisttest", "suntest" and "msxsdtest" directories.""")

opa.add_option("-o", "--out", action="store", type="string", dest="logFile",
			   default="test.log",
			   help="The filepath of the log file to be created")

opa.add_option("--log", action="store_true", dest="enableLog",
			   default=False,
			   help="Create the log file")

opa.add_option("--no-test-out", action="store_true", dest="disableTestStdOut",
			   default=False,
			   help="Don't output test results")

opa.add_option("-s", "--silent", action="store_true", dest="silent", default=False,
			   help="Disables display of all tests")

opa.add_option("-v", "--verbose", action="store_true", dest="verbose",
			   default=False,
			   help="Displays all tests (only if --silent is not set)")

opa.add_option("-x", "--max", type="int", dest="maxTestCount",
			   default="-1",
			   help="The maximum number of tests to be run")

opa.add_option("-t", "--test", type="string", dest="singleTest",
			   default=None,
			   help="Runs the specified test only")
			   
opa.add_option("--tsw", "--test-starts-with", type="string", dest="testStartsWith",
			   default=None,
			   help="Runs the specified test(s), starting with the given string")

opa.add_option("--rieo", "--report-internal-errors-only", action="store_true",
			   dest="reportInternalErrOnly", default=False,
			   help="Display erroneous tests of type 'internal' only")

opa.add_option("--rueo", "--report-unimplemented-errors-only", action="store_true",
			   dest="reportUnimplErrOnly", default=False,
			   help="Display erroneous tests of type 'unimplemented' only")

opa.add_option("--rmleo", "--report-mem-leak-errors-only", action="store_true",
			   dest="reportMemLeakErrOnly", default=False,
			   help="Display erroneous tests of type 'memory leak' only")

opa.add_option("-c", "--combines", type="string", dest="combines",
			   default=None,
			   help="Combines to be run (all if omitted)")
			   
opa.add_option("--csw", "--csw", type="string", dest="combineStartsWith",
			   default=None,
			   help="Combines to be run (all if omitted)")			   

opa.add_option("--rc", "--report-combines", action="store_true",
			   dest="reportCombines", default=False,
			   help="Display combine reports")

opa.add_option("--rec", "--report-err-combines", action="store_true",
			   dest="reportErrCombines", default=False,
			   help="Display erroneous combine reports only")

opa.add_option("--debug", action="store_true",
			   dest="debugEnabled", default=False,
			   help="Displays debug messages")

opa.add_option("--info", action="store_true",
			   dest="info", default=False,
			   help="Displays info on the suite only. Does not run any test.")
opa.add_option("--sax", action="store_true",
			   dest="validationSAX", default=False,
			   help="Use SAX2-driven validation.")
opa.add_option("--tn", action="store_true",
			   dest="displayTestName", default=False,
			   help="Display the test name in every case.")

(options, args) = opa.parse_args()

if options.combines is not None:
	options.combines = options.combines.split()

################################################
# The vars below are not intended to be changed.
#

msgSchemaNotValidButShould =  "The schema should be valid."
msgSchemaValidButShouldNot = "The schema should be invalid."
msgInstanceNotValidButShould = "The instance should be valid."
msgInstanceValidButShouldNot = "The instance should be invalid."
vendorNIST = "NIST"
vendorNIST_2 = "NIST-2"
vendorSUN  = "SUN"
vendorMS   = "MS"

###################
# Helper functions.
#
vendor = None

def handleError(test, msg):
	global options
	if not options.silent:
		test.addLibLog("'%s'   LIB: %s" % (test.name, msg))
	if msg.find("Unimplemented") > -1:
		test.failUnimplemented()
	elif msg.find("Internal") > -1:
		test.failInternal()
		
	
def fixFileNames(fileName):
	if (fileName is None) or (fileName == ""):
		return ""
	dirs = fileName.split("/")
	if dirs[1] != "Tests":
		fileName = os.path.join(".", "Tests")
		for dir in dirs[1:]:
			fileName = os.path.join(fileName, dir)	
	return fileName

class XSTCTestGroup:
	def __init__(self, name, schemaFileName, descr):
		global vendor, vendorNIST_2
		self.name = name
		self.descr = descr
		self.mainSchema = True
		self.schemaFileName = fixFileNames(schemaFileName)
		self.schemaParsed = False
		self.schemaTried = False

	def setSchema(self, schemaFileName, parsed):
		if not self.mainSchema:			
			return
		self.mainSchema = False
		self.schemaParsed = parsed
		self.schemaTried = True

class XSTCTestCase:

		   # <!-- groupName, Name, Accepted, File, Val, Descr
	def __init__(self, isSchema, groupName, name, accepted, file, val, descr):
		global options
		#
		# Constructor.
		#
		self.testRunner = None
		self.isSchema = isSchema
		self.groupName = groupName
		self.name = name
		self.accepted = accepted		
		self.fileName = fixFileNames(file)
		self.val = val
		self.descr = descr
		self.failed = False
		self.combineName = None

		self.log = []
		self.libLog = []
		self.initialMemUsed = 0
		self.memLeak = 0
		self.excepted = False
		self.bad = False
		self.unimplemented = False
		self.internalErr = False
		self.noSchemaErr = False
		self.failed = False
		#
		# Init the log.
		#
		if not options.silent:
			if self.descr is not None:
				self.log.append("'%s'   descr: %s\n" % (self.name, self.descr))		
			self.log.append("'%s'   exp validity: %d\n" % (self.name, self.val))

	def initTest(self, runner):
		global vendorNIST, vendorSUN, vendorMS, vendorNIST_2, options, vendor
		#
		# Get the test-group.
		#
		self.runner = runner
		self.group = runner.getGroup(self.groupName)				
		if vendor == vendorMS or vendor == vendorSUN:
			#
			# Use the last given directory for the combine name.
			#
			dirs = self.fileName.split("/")
			self.combineName = dirs[len(dirs) -2]					
		elif vendor == vendorNIST:
			#
			# NIST files are named in the following form:
			# "NISTSchema-short-pattern-1.xsd"
			#						
			tokens = self.name.split("-")
			self.combineName = tokens[1]
		elif vendor == vendorNIST_2:
			#
			# Group-names have the form: "atomic-normalizedString-length-1"
			#
			tokens = self.groupName.split("-")
			self.combineName = "%s-%s" % (tokens[0], tokens[1])
		else:
			self.combineName = "unkown"
			raise Exception("Could not compute the combine name of a test.")
		if (not options.silent) and (self.group.descr is not None):
			self.log.append("'%s'   group-descr: %s\n" % (self.name, self.group.descr))
		

	def addLibLog(self, msg):		
		"""This one is intended to be used by the error handler
		function"""
		global options		
		if not options.silent:
			self.libLog.append(msg)

	def fail(self, msg):
		global options
		self.failed = True
		if not options.silent:
			self.log.append("'%s' ( FAILED: %s\n" % (self.name, msg))

	def failNoSchema(self):
		global options
		self.failed = True
		self.noSchemaErr = True
		if not options.silent:
			self.log.append("'%s' X NO-SCHEMA\n" % (self.name))

	def failInternal(self):
		global options
		self.failed = True
		self.internalErr = True
		if not options.silent:
			self.log.append("'%s' * INTERNAL\n" % self.name)

	def failUnimplemented(self):
		global options
		self.failed = True
		self.unimplemented = True
		if not options.silent:
			self.log.append("'%s' ? UNIMPLEMENTED\n" % self.name)

	def failCritical(self, msg):
		global options
		self.failed = True
		self.bad = True
		if not options.silent:
			self.log.append("'%s' ! BAD: %s\n" % (self.name, msg))

	def failExcept(self, e):
		global options
		self.failed = True
		self.excepted = True
		if not options.silent:
			self.log.append("'%s' # EXCEPTION: %s\n" % (self.name, e.__str__()))

	def setUp(self):
		#
		# Set up Libxml2.
		#
		self.initialMemUsed = libxml2.debugMemory(1)
		libxml2.initParser()
		libxml2.lineNumbersDefault(1)
		libxml2.registerErrorHandler(handleError, self)

	def tearDown(self):
		libxml2.schemaCleanupTypes()
		libxml2.cleanupParser()
		self.memLeak = libxml2.debugMemory(1) - self.initialMemUsed

	def isIOError(self, file, docType):
		err = None
		try:
			err = libxml2.lastError()
		except:
			# Suppress exceptions.
			pass
		if (err is None):
			return False
		if err.domain() == libxml2.XML_FROM_IO:
			self.failCritical("failed to access the %s resource '%s'\n" % (docType, file))

	def debugMsg(self, msg):
		global options
		if options.debugEnabled:
			sys.stdout.write("'%s'   DEBUG: %s\n" % (self.name, msg))

	def finalize(self):
		global options
		"""Adds additional info to the log."""
		#
		# Add libxml2 messages.
		#
		if not options.silent:
			self.log.extend(self.libLog)
			#
			# Add memory leaks.
			#
			if self.memLeak != 0:
				self.log.append("%s + memory leak: %d bytes\n" % (self.name, self.memLeak))

	def run(self):
		"""Runs a test."""
		global options

		##filePath = os.path.join(options.baseDir, self.fileName)
		# filePath = "%s/%s/%s/%s" % (options.baseDir, self.test_Folder, self.schema_Folder, self.schema_File)
		if options.displayTestName:
			sys.stdout.write("'%s'\n" % self.name)
		try:
			self.validate()
		except (Exception, libxml2.parserError, libxml2.treeError), e:
			self.failExcept(e)
			
def parseSchema(fileName):
	schema = None
	ctxt = libxml2.schemaNewParserCtxt(fileName)
	try:
		try:
			schema = ctxt.schemaParse()
		except:
			pass
	finally:		
		del ctxt
		return schema
				

class XSTCSchemaTest(XSTCTestCase):

	def __init__(self, groupName, name, accepted, file, val, descr):
		XSTCTestCase.__init__(self, 1, groupName, name, accepted, file, val, descr)

	def validate(self):
		global msgSchemaNotValidButShould, msgSchemaValidButShouldNot
		schema = None
		filePath = self.fileName
		# os.path.join(options.baseDir, self.fileName)
		valid = 0
		try:
			#
			# Parse the schema.
			#
			self.debugMsg("loading schema: %s" % filePath)
			schema = parseSchema(filePath)
			self.debugMsg("after loading schema")						
			if schema is None:
				self.debugMsg("schema is None")
				self.debugMsg("checking for IO errors...")
				if self.isIOError(file, "schema"):
					return
			self.debugMsg("checking schema result")
			if (schema is None and self.val) or (schema is not None and self.val == 0):
				self.debugMsg("schema result is BAD")
				if (schema == None):
					self.fail(msgSchemaNotValidButShould)
				else:
					self.fail(msgSchemaValidButShouldNot)
			else:
				self.debugMsg("schema result is OK")
		finally:
			self.group.setSchema(self.fileName, schema is not None)
			del schema

class XSTCInstanceTest(XSTCTestCase):

	def __init__(self, groupName, name, accepted, file, val, descr):
		XSTCTestCase.__init__(self, 0, groupName, name, accepted, file, val, descr)

	def validate(self):
		instance = None
		schema = None
		filePath = self.fileName
		# os.path.join(options.baseDir, self.fileName)

		if not self.group.schemaParsed and self.group.schemaTried:
			self.failNoSchema()
			return
					
		self.debugMsg("loading instance: %s" % filePath)
		parserCtxt = libxml2.newParserCtxt()
		if (parserCtxt is None):
			# TODO: Is this one necessary, or will an exception
			# be already raised?
			raise Exception("Could not create the instance parser context.")
		if not options.validationSAX:
			try:
				try:
					instance = parserCtxt.ctxtReadFile(filePath, None, libxml2.XML_PARSE_NOWARNING)
				except:
					# Suppress exceptions.
					pass
			finally:
				del parserCtxt
			self.debugMsg("after loading instance")
			if instance is None:
				self.debugMsg("instance is None")
				self.failCritical("Failed to parse the instance for unknown reasons.")
				return		
		try:
			#
			# Validate the instance.
			#
			self.debugMsg("loading schema: %s" % self.group.schemaFileName)
			schema = parseSchema(self.group.schemaFileName)
			try:
				validationCtxt = schema.schemaNewValidCtxt()
				#validationCtxt = libxml2.schemaNewValidCtxt(None)
				if (validationCtxt is None):
					self.failCritical("Could not create the validation context.")
					return
				try:
					self.debugMsg("validating instance")
					if options.validationSAX:
						instance_Err = validationCtxt.schemaValidateFile(filePath, 0)
					else:
						instance_Err = validationCtxt.schemaValidateDoc(instance)
					self.debugMsg("after instance validation")
					self.debugMsg("instance-err: %d" % instance_Err)
					if (instance_Err != 0 and self.val == 1) or (instance_Err == 0 and self.val == 0):
						self.debugMsg("instance result is BAD")
						if (instance_Err != 0):
							self.fail(msgInstanceNotValidButShould)
						else:
							self.fail(msgInstanceValidButShouldNot)

					else:
								self.debugMsg("instance result is OK")
				finally:
					del validationCtxt
			finally:
				del schema
		finally:
			if instance is not None:
				instance.freeDoc()


####################
# Test runner class.
#

class XSTCTestRunner:

	CNT_TOTAL = 0
	CNT_RAN = 1
	CNT_SUCCEEDED = 2
	CNT_FAILED = 3
	CNT_UNIMPLEMENTED = 4
	CNT_INTERNAL = 5
	CNT_BAD = 6
	CNT_EXCEPTED = 7
	CNT_MEMLEAK = 8
	CNT_NOSCHEMA = 9
	CNT_NOTACCEPTED = 10
	CNT_SCHEMA_TEST = 11

	def __init__(self):
		self.logFile = None
		self.counters = self.createCounters()
		self.testList = []
		self.combinesRan = {}
		self.groups = {}
		self.curGroup = None

	def createCounters(self):
		counters = {self.CNT_TOTAL:0, self.CNT_RAN:0, self.CNT_SUCCEEDED:0,
		self.CNT_FAILED:0, self.CNT_UNIMPLEMENTED:0, self.CNT_INTERNAL:0, self.CNT_BAD:0,
		self.CNT_EXCEPTED:0, self.CNT_MEMLEAK:0, self.CNT_NOSCHEMA:0, self.CNT_NOTACCEPTED:0,
		self.CNT_SCHEMA_TEST:0}

		return counters

	def addTest(self, test):
		self.testList.append(test)
		test.initTest(self)

	def getGroup(self, groupName):
		return self.groups[groupName]

	def addGroup(self, group):
		self.groups[group.name] = group

	def updateCounters(self, test, counters):
		if test.memLeak != 0:
			counters[self.CNT_MEMLEAK] += 1
		if not test.failed:
			counters[self.CNT_SUCCEEDED] +=1
		if test.failed:
			counters[self.CNT_FAILED] += 1
		if test.bad:
			counters[self.CNT_BAD] += 1
		if test.unimplemented:
			counters[self.CNT_UNIMPLEMENTED] += 1
		if test.internalErr:
			counters[self.CNT_INTERNAL] += 1
		if test.noSchemaErr:
			counters[self.CNT_NOSCHEMA] += 1
		if test.excepted:
			counters[self.CNT_EXCEPTED] += 1
		if not test.accepted:
			counters[self.CNT_NOTACCEPTED] += 1
		if test.isSchema:
			counters[self.CNT_SCHEMA_TEST] += 1
		return counters

	def displayResults(self, out, all, combName, counters):
		out.write("\n")
		if all:
			if options.combines is not None:
				out.write("combine(s): %s\n" % str(options.combines))
		elif combName is not None:
			out.write("combine : %s\n" % combName)
		out.write("  total           : %d\n" % counters[self.CNT_TOTAL])
		if all or options.combines is not None:
			out.write("  ran             : %d\n" % counters[self.CNT_RAN])
			out.write("    (schemata)    : %d\n" % counters[self.CNT_SCHEMA_TEST])
		# out.write("    succeeded       : %d\n" % counters[self.CNT_SUCCEEDED])
		out.write("  not accepted    : %d\n" % counters[self.CNT_NOTACCEPTED])
		if counters[self.CNT_FAILED] > 0:		    
			out.write("    failed                  : %d\n" % counters[self.CNT_FAILED])
			out.write("     -> internal            : %d\n" % counters[self.CNT_INTERNAL])
			out.write("     -> unimpl.             : %d\n" % counters[self.CNT_UNIMPLEMENTED])
			out.write("     -> skip-invalid-schema : %d\n" % counters[self.CNT_NOSCHEMA])
			out.write("     -> bad                 : %d\n" % counters[self.CNT_BAD])
			out.write("     -> exceptions          : %d\n" % counters[self.CNT_EXCEPTED])
			out.write("    memory leaks            : %d\n" % counters[self.CNT_MEMLEAK])

	def displayShortResults(self, out, all, combName, counters):
		out.write("Ran %d of %d tests (%d schemata):" % (counters[self.CNT_RAN],
				  counters[self.CNT_TOTAL], counters[self.CNT_SCHEMA_TEST]))
		# out.write("    succeeded       : %d\n" % counters[self.CNT_SUCCEEDED])
		if counters[self.CNT_NOTACCEPTED] > 0:
			out.write(" %d not accepted" % (counters[self.CNT_NOTACCEPTED]))
		if counters[self.CNT_FAILED] > 0 or counters[self.CNT_MEMLEAK] > 0:
			if counters[self.CNT_FAILED] > 0:
				out.write(" %d failed" % (counters[self.CNT_FAILED]))
				out.write(" (")
				if counters[self.CNT_INTERNAL] > 0:
					out.write(" %d internal" % (counters[self.CNT_INTERNAL]))
				if counters[self.CNT_UNIMPLEMENTED] > 0:
					out.write(" %d unimplemented" % (counters[self.CNT_UNIMPLEMENTED]))
				if counters[self.CNT_NOSCHEMA] > 0:
					out.write(" %d skip-invalid-schema" % (counters[self.CNT_NOSCHEMA]))
				if counters[self.CNT_BAD] > 0:
					out.write(" %d bad" % (counters[self.CNT_BAD]))
				if counters[self.CNT_EXCEPTED] > 0:
					out.write(" %d exception" % (counters[self.CNT_EXCEPTED]))
				out.write(" )")
			if counters[self.CNT_MEMLEAK] > 0:
				out.write(" %d leaks" % (counters[self.CNT_MEMLEAK]))			
			out.write("\n")
		else:
			out.write(" all passed\n")

	def reportCombine(self, combName):
		global options

		counters = self.createCounters()
		#
		# Compute evaluation counters.
		#
		for test in self.combinesRan[combName]:
			counters[self.CNT_TOTAL] += 1
			counters[self.CNT_RAN] += 1
			counters = self.updateCounters(test, counters)
		if options.reportErrCombines and (counters[self.CNT_FAILED] == 0) and (counters[self.CNT_MEMLEAK] == 0):
			pass
		else:
			if options.enableLog:
				self.displayResults(self.logFile, False, combName, counters)				
			self.displayResults(sys.stdout, False, combName, counters)

	def displayTestLog(self, test):
		sys.stdout.writelines(test.log)
		sys.stdout.write("~~~~~~~~~~\n")

	def reportTest(self, test):
		global options

		error = test.failed or test.memLeak != 0
		#
		# Only erroneous tests will be written to the log,
		# except @verbose is switched on.
		#
		if options.enableLog and (options.verbose or error):
			self.logFile.writelines(test.log)
			self.logFile.write("~~~~~~~~~~\n")
		#
		# if not @silent, only erroneous tests will be
		# written to stdout, except @verbose is switched on.
		#
		if not options.silent:
			if options.reportInternalErrOnly and test.internalErr:
				self.displayTestLog(test)
			if options.reportMemLeakErrOnly and test.memLeak != 0:
				self.displayTestLog(test)
			if options.reportUnimplErrOnly and test.unimplemented:
				self.displayTestLog(test)
			if (options.verbose or error) and (not options.reportInternalErrOnly) and (not options.reportMemLeakErrOnly) and (not options.reportUnimplErrOnly):
				self.displayTestLog(test)


	def addToCombines(self, test):
		found = False
		if self.combinesRan.has_key(test.combineName):
			self.combinesRan[test.combineName].append(test)
		else:
			self.combinesRan[test.combineName] = [test]

	def run(self):

		global options

		if options.info:
			for test in self.testList:
				self.addToCombines(test)
			sys.stdout.write("Combines: %d\n" % len(self.combinesRan))
			sys.stdout.write("%s\n" % self.combinesRan.keys())
			return

		if options.enableLog:
			self.logFile = open(options.logFile, "w")
		try:
			for test in self.testList:
				self.counters[self.CNT_TOTAL] += 1
				#
				# Filter tests.
				#
				if options.singleTest is not None and options.singleTest != "":
					if (test.name != options.singleTest):
						continue
				elif options.combines is not None:
					if not options.combines.__contains__(test.combineName):
						continue
				elif options.testStartsWith is not None:
					if not test.name.startswith(options.testStartsWith):
						continue
				elif options.combineStartsWith is not None:
					if not test.combineName.startswith(options.combineStartsWith):
						continue
				
				if options.maxTestCount != -1 and self.counters[self.CNT_RAN] >= options.maxTestCount:
					break
				self.counters[self.CNT_RAN] += 1
				#
				# Run the thing, dammit.
				#
				try:
					test.setUp()
					try:
						test.run()
					finally:
						test.tearDown()
				finally:
					#
					# Evaluate.
					#
					test.finalize()
					self.reportTest(test)
					if options.reportCombines or options.reportErrCombines:
						self.addToCombines(test)
					self.counters = self.updateCounters(test, self.counters)
		finally:
			if options.reportCombines or options.reportErrCombines:
				#
				# Build a report for every single combine.
				#
				# TODO: How to sort a dict?
				#
				self.combinesRan.keys().sort(None)
				for key in self.combinesRan.keys():
					self.reportCombine(key)

			#
			# Display the final report.
			#
			if options.silent:
				self.displayShortResults(sys.stdout, True, None, self.counters)
			else:
				sys.stdout.write("===========================\n")
				self.displayResults(sys.stdout, True, None, self.counters)
