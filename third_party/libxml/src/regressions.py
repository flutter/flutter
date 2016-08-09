#!/usr/bin/python -u
import glob, os, string, sys, thread, time
# import difflib
import libxml2

###
#
# This is a "Work in Progress" attempt at a python script to run the
# various regression tests.  The rationale for this is that it should be
# possible to run this on most major platforms, including those (such as
# Windows) which don't support gnu Make.
#
# The script is driven by a parameter file which defines the various tests
# to be run, together with the unique settings for each of these tests.  A
# script for Linux is included (regressions.xml), with comments indicating
# the significance of the various parameters.  To run the tests under Windows,
# edit regressions.xml and remove the comment around the default parameter
# "<execpath>" (i.e. make it point to the location of the binary executables).
#
# Note that this current version requires the Python bindings for libxml2 to
# have been previously installed and accessible
#
# See Copyright for the status of this software.
# William Brack (wbrack@mmm.com.hk)
#
###
defaultParams = {}	# will be used as a dictionary to hold the parsed params

# This routine is used for comparing the expected stdout / stdin with the results.
# The expected data has already been read in; the result is a file descriptor.
# Within the two sets of data, lines may begin with a path string.  If so, the
# code "relativises" it by removing the path component.  The first argument is a
# list already read in by a separate thread; the second is a file descriptor.
# The two 'base' arguments are to let me "relativise" the results files, allowing
# the script to be run from any directory.
def compFiles(res, expected, base1, base2):
    l1 = len(base1)
    exp = expected.readlines()
    expected.close()
    # the "relativisation" is done here
    for i in range(len(res)):
        j = string.find(res[i],base1)
        if (j == 0) or ((j == 2) and (res[i][0:2] == './')):
            col = string.find(res[i],':')
            if col > 0:
                start = string.rfind(res[i][:col], '/')
                if start > 0:
                    res[i] = res[i][start+1:]

    for i in range(len(exp)):
        j = string.find(exp[i],base2)
        if (j == 0) or ((j == 2) and (exp[i][0:2] == './')):
            col = string.find(exp[i],':')
            if col > 0:
                start = string.rfind(exp[i][:col], '/')
                if start > 0:
                    exp[i] = exp[i][start+1:]

    ret = 0
    # ideally we would like to use difflib functions here to do a
    # nice comparison of the two sets.  Unfortunately, during testing
    # (using python 2.3.3 and 2.3.4) the following code went into
    # a dead loop under windows.  I'll pursue this later.
#    diff = difflib.ndiff(res, exp)
#    diff = list(diff)
#    for line in diff:
#        if line[:2] != '  ':
#            print string.strip(line)
#            ret = -1

    # the following simple compare is fine for when the two data sets
    # (actual result vs. expected result) are equal, which should be true for
    # us.  Unfortunately, if the test fails it's not nice at all.
    rl = len(res)
    el = len(exp)
    if el != rl:
        print 'Length of expected is %d, result is %d' % (el, rl)
	ret = -1
    for i in range(min(el, rl)):
        if string.strip(res[i]) != string.strip(exp[i]):
            print '+:%s-:%s' % (res[i], exp[i])
            ret = -1
    if el > rl:
        for i in range(rl, el):
            print '-:%s' % exp[i]
            ret = -1
    elif rl > el:
        for i in range (el, rl):
            print '+:%s' % res[i]
            ret = -1
    return ret

# Separate threads to handle stdout and stderr are created to run this function
def readPfile(file, list, flag):
    data = file.readlines()	# no call by reference, so I cheat
    for l in data:
        list.append(l)
    file.close()
    flag.append('ok')

# This routine runs the test program (e.g. xmllint)
def runOneTest(testDescription, filename, inbase, errbase):
    if 'execpath' in testDescription:
        dir = testDescription['execpath'] + '/'
    else:
        dir = ''
    cmd = os.path.abspath(dir + testDescription['testprog'])
    if 'flag' in testDescription:
        for f in string.split(testDescription['flag']):
            cmd += ' ' + f
    if 'stdin' not in testDescription:
        cmd += ' ' + inbase + filename
    if 'extarg' in testDescription:
        cmd += ' ' + testDescription['extarg']

    noResult = 0
    expout = None
    if 'resext' in testDescription:
        if testDescription['resext'] == 'None':
            noResult = 1
        else:
            ext = '.' + testDescription['resext']
    else:
        ext = ''
    if not noResult:
        try:
            fname = errbase + filename + ext
            expout = open(fname, 'rt')
        except:
            print "Can't open result file %s - bypassing test" % fname
            return

    noErrors = 0
    if 'reserrext' in testDescription:
        if testDescription['reserrext'] == 'None':
            noErrors = 1
        else:
            if len(testDescription['reserrext'])>0:
                ext = '.' + testDescription['reserrext']
            else:
                ext = ''
    else:
        ext = ''
    if not noErrors:
        try:
            fname = errbase + filename + ext
            experr = open(fname, 'rt')
        except:
            experr = None
    else:
        experr = None

    pin, pout, perr = os.popen3(cmd)
    if 'stdin' in testDescription:
        infile = open(inbase + filename, 'rt')
        pin.writelines(infile.readlines())
        infile.close()
        pin.close()

    # popen is great fun, but can lead to the old "deadly embrace", because
    # synchronizing the writing (by the task being run) of stdout and stderr
    # with respect to the reading (by this task) is basically impossible.  I
    # tried several ways to cheat, but the only way I have found which works
    # is to do a *very* elementary multi-threading approach.  We can only hope
    # that Python threads are implemented on the target system (it's okay for
    # Linux and Windows)

    th1Flag = []	# flags to show when threads finish
    th2Flag = []
    outfile = []	# lists to contain the pipe data
    errfile = []
    th1 = thread.start_new_thread(readPfile, (pout, outfile, th1Flag))
    th2 = thread.start_new_thread(readPfile, (perr, errfile, th2Flag))
    while (len(th1Flag)==0) or (len(th2Flag)==0):
        time.sleep(0.001)
    if not noResult:
        ret = compFiles(outfile, expout, inbase, 'test/')
        if ret != 0:
            print 'trouble with %s' % cmd
    else:
        if len(outfile) != 0:
            for l in outfile:
                print l
            print 'trouble with %s' % cmd
    if experr != None:
        ret = compFiles(errfile, experr, inbase, 'test/')
        if ret != 0:
            print 'trouble with %s' % cmd
    else:
        if not noErrors:
            if len(errfile) != 0:
                for l in errfile:
                    print l
                print 'trouble with %s' % cmd

    if 'stdin' not in testDescription:
        pin.close()

# This routine is called by the parameter decoding routine whenever the end of a
# 'test' section is encountered.  Depending upon file globbing, a large number of
# individual tests may be run.
def runTest(description):
    testDescription = defaultParams.copy()		# set defaults
    testDescription.update(description)			# override with current ent
    if 'testname' in testDescription:
        print "## %s" % testDescription['testname']
    if not 'file' in testDescription:
        print "No file specified - can't run this test!"
        return
    # Set up the source and results directory paths from the decoded params
    dir = ''
    if 'srcdir' in testDescription:
        dir += testDescription['srcdir'] + '/'
    if 'srcsub' in testDescription:
        dir += testDescription['srcsub'] + '/'

    rdir = ''
    if 'resdir' in testDescription:
        rdir += testDescription['resdir'] + '/'
    if 'ressub' in testDescription:
        rdir += testDescription['ressub'] + '/'

    testFiles = glob.glob(os.path.abspath(dir + testDescription['file']))
    if testFiles == []:
        print "No files result from '%s'" % testDescription['file']
        return

    # Some test programs just don't work (yet).  For now we exclude them.
    count = 0
    excl = []
    if 'exclfile' in testDescription:
        for f in string.split(testDescription['exclfile']):
            glb = glob.glob(dir + f)
            for g in glb:
                excl.append(os.path.abspath(g))

    # Run the specified test program
    for f in testFiles:
        if not os.path.isdir(f):
            if f not in excl:
                count = count + 1
                runOneTest(testDescription, os.path.basename(f), dir, rdir)

#
# The following classes are used with the xmlreader interface to interpret the
# parameter file.  Once a test section has been identified, runTest is called
# with a dictionary containing the parsed results of the interpretation.
#

class testDefaults:
    curText = ''	# accumulates text content of parameter

    def addToDict(self, key):
        txt = string.strip(self.curText)
#        if txt == '':
#            return
        if key not in defaultParams:
            defaultParams[key] = txt
        else:
            defaultParams[key] += ' ' + txt
        
    def processNode(self, reader, curClass):
        if reader.Depth() == 2:
            if reader.NodeType() == 1:
                self.curText = ''	# clear the working variable
            elif reader.NodeType() == 15:
                if (reader.Name() != '#text') and (reader.Name() != '#comment'):
                    self.addToDict(reader.Name())
        elif reader.Depth() == 3:
            if reader.Name() == '#text':
                self.curText += reader.Value()

        elif reader.NodeType() == 15:	# end of element
            print "Defaults have been set to:"
            for k in defaultParams.keys():
                print "   %s : '%s'" % (k, defaultParams[k])
            curClass = rootClass()
        return curClass


class testClass:
    def __init__(self):
        self.testParams = {}	# start with an empty set of params
        self.curText = ''	# and empty text

    def addToDict(self, key):
        data = string.strip(self.curText)
        if key not in self.testParams:
            self.testParams[key] = data
        else:
            if self.testParams[key] != '':
                data = ' ' + data
            self.testParams[key] += data

    def processNode(self, reader, curClass):
        if reader.Depth() == 2:
            if reader.NodeType() == 1:
                self.curText = ''	# clear the working variable
                if reader.Name() not in self.testParams:
                    self.testParams[reader.Name()] = ''
            elif reader.NodeType() == 15:
                if (reader.Name() != '#text') and (reader.Name() != '#comment'):
                    self.addToDict(reader.Name())
        elif reader.Depth() == 3:
            if reader.Name() == '#text':
                self.curText += reader.Value()

        elif reader.NodeType() == 15:	# end of element
            runTest(self.testParams)
            curClass = rootClass()
        return curClass


class rootClass:
    def processNode(self, reader, curClass):
        if reader.Depth() == 0:
            return curClass
        if reader.Depth() != 1:
            print "Unexpected junk: Level %d, type %d, name %s" % (
                  reader.Depth(), reader.NodeType(), reader.Name())
            return curClass
        if reader.Name() == 'test':
            curClass = testClass()
            curClass.testParams = {}
        elif reader.Name() == 'defaults':
            curClass = testDefaults()
        return curClass

def streamFile(filename):
    try:
        reader = libxml2.newTextReaderFilename(filename)
    except:
        print "unable to open %s" % (filename)
        return

    curClass = rootClass()
    ret = reader.Read()
    while ret == 1:
        curClass = curClass.processNode(reader, curClass)
        ret = reader.Read()

    if ret != 0:
        print "%s : failed to parse" % (filename)

# OK, we're finished with all the routines.  Now for the main program:-
if len(sys.argv) != 2:
    print "Usage: maketest {filename}"
    sys.exit(-1)

streamFile(sys.argv[1])
