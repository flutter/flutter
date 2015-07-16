# -*- coding: utf-8 -*-

"""unittest-xml-reporting is a PyUnit-based TestRunner that can export test
results to XML files that can be consumed by a wide range of tools, such as
build systems, IDEs and Continuous Integration servers.

This module provides the XMLTestRunner class, which is heavily based on the
default TextTestRunner. This makes the XMLTestRunner very simple to use.

The script below, adapted from the unittest documentation, shows how to use
XMLTestRunner in a very simple way. In fact, the only difference between this
script and the original one is the last line:

import random
import unittest
import xmlrunner

class TestSequenceFunctions(unittest.TestCase):
    def setUp(self):
        self.seq = range(10)

    def test_shuffle(self):
        # make sure the shuffled sequence does not lose any elements
        random.shuffle(self.seq)
        self.seq.sort()
        self.assertEqual(self.seq, range(10))

    def test_choice(self):
        element = random.choice(self.seq)
        self.assert_(element in self.seq)

    def test_sample(self):
        self.assertRaises(ValueError, random.sample, self.seq, 20)
        for element in random.sample(self.seq, 5):
            self.assert_(element in self.seq)

if __name__ == '__main__':
    unittest.main(testRunner=xmlrunner.XMLTestRunner(output='test-reports'))
"""

import os
import sys
import time
from unittest import TestResult, _TextTestResult, TextTestRunner
from cStringIO import StringIO
import xml.dom.minidom


class XMLDocument(xml.dom.minidom.Document):
    def createCDATAOrText(self, data):
        if ']]>' in data:
            return self.createTextNode(data)
        return self.createCDATASection(data)


class _TestInfo(object):
    """This class is used to keep useful information about the execution of a
    test method.
    """

    # Possible test outcomes
    (SUCCESS, FAILURE, ERROR) = range(3)

    def __init__(self, test_result, test_method, outcome=SUCCESS, err=None):
        "Create a new instance of _TestInfo."
        self.test_result = test_result
        self.test_method = test_method
        self.outcome = outcome
        self.err = err
        self.stdout = test_result.stdout and test_result.stdout.getvalue().strip() or ''
        self.stderr = test_result.stdout and test_result.stderr.getvalue().strip() or ''

    def get_elapsed_time(self):
        """Return the time that shows how long the test method took to
        execute.
        """
        return self.test_result.stop_time - self.test_result.start_time

    def get_description(self):
        "Return a text representation of the test method."
        return self.test_result.getDescription(self.test_method)

    def get_error_info(self):
        """Return a text representation of an exception thrown by a test
        method.
        """
        if not self.err:
            return ''
        if sys.version_info < (2,4):
            return self.test_result._exc_info_to_string(self.err)
        else:
            return self.test_result._exc_info_to_string(
                self.err, self.test_method)


class _XMLTestResult(_TextTestResult):
    """A test result class that can express test results in a XML report.

    Used by XMLTestRunner.
    """
    def __init__(self, stream=sys.stderr, descriptions=1, verbosity=1, \
        elapsed_times=True):
        "Create a new instance of _XMLTestResult."
        _TextTestResult.__init__(self, stream, descriptions, verbosity)
        self.successes = []
        self.callback = None
        self.elapsed_times = elapsed_times
        self.output_patched = False

    def _prepare_callback(self, test_info, target_list, verbose_str,
        short_str):
        """Append a _TestInfo to the given target list and sets a callback
        method to be called by stopTest method.
        """
        target_list.append(test_info)
        def callback():
            """This callback prints the test method outcome to the stream,
            as well as the elapsed time.
            """

            # Ignore the elapsed times for a more reliable unit testing
            if not self.elapsed_times:
                self.start_time = self.stop_time = 0

            if self.showAll:
                self.stream.writeln('(%.3fs) %s' % \
                    (test_info.get_elapsed_time(), verbose_str))
            elif self.dots:
                self.stream.write(short_str)
        self.callback = callback

    def _patch_standard_output(self):
        """Replace the stdout and stderr streams with string-based streams
        in order to capture the tests' output.
        """
        if not self.output_patched:
            (self.old_stdout, self.old_stderr) = (sys.stdout, sys.stderr)
            self.output_patched = True
        (sys.stdout, sys.stderr) = (self.stdout, self.stderr) = \
            (StringIO(), StringIO())

    def _restore_standard_output(self):
        "Restore the stdout and stderr streams."
        (sys.stdout, sys.stderr) = (self.old_stdout, self.old_stderr)
        self.output_patched = False

    def startTest(self, test):
        "Called before execute each test method."
        self._patch_standard_output()
        self.start_time = time.time()
        TestResult.startTest(self, test)

        if self.showAll:
            self.stream.write('  ' + self.getDescription(test))
            self.stream.write(" ... ")

    def stopTest(self, test):
        "Called after execute each test method."
        self._restore_standard_output()
        _TextTestResult.stopTest(self, test)
        self.stop_time = time.time()

        if self.callback and callable(self.callback):
            self.callback()
            self.callback = None

    def addSuccess(self, test):
        "Called when a test executes successfully."
        self._prepare_callback(_TestInfo(self, test),
                               self.successes, 'OK', '.')

    def addFailure(self, test, err):
        "Called when a test method fails."
        self._prepare_callback(_TestInfo(self, test, _TestInfo.FAILURE, err),
                               self.failures, 'FAIL', 'F')

    def addError(self, test, err):
        "Called when a test method raises an error."
        self._prepare_callback(_TestInfo(self, test, _TestInfo.ERROR, err),
                               self.errors, 'ERROR', 'E')

    def printErrorList(self, flavour, errors):
        "Write some information about the FAIL or ERROR to the stream."
        for test_info in errors:
            if isinstance(test_info, tuple):
                test_info, exc_info = test_info
            self.stream.writeln(self.separator1)
            self.stream.writeln('%s [%.3fs]: %s' % (
                flavour, test_info.get_elapsed_time(),
                test_info.get_description()))
            self.stream.writeln(self.separator2)
            self.stream.writeln('%s' % test_info.get_error_info())

    def _get_info_by_testcase(self):
        """This method organizes test results by TestCase module. This
        information is used during the report generation, where a XML report
        will be generated for each TestCase.
        """
        tests_by_testcase = {}

        for tests in (self.successes, self.failures, self.errors):
            for test_info in tests:
                testcase = type(test_info.test_method)

                # Ignore module name if it is '__main__'
                module = testcase.__module__ + '.'
                if module == '__main__.':
                    module = ''
                testcase_name = module + testcase.__name__

                if testcase_name not in tests_by_testcase:
                    tests_by_testcase[testcase_name] = []
                tests_by_testcase[testcase_name].append(test_info)

        return tests_by_testcase

    def _report_testsuite(suite_name, tests, xml_document):
        "Appends the testsuite section to the XML document."
        testsuite = xml_document.createElement('testsuite')
        xml_document.appendChild(testsuite)

        testsuite.setAttribute('name', str(suite_name))
        testsuite.setAttribute('tests', str(len(tests)))

        testsuite.setAttribute('time', '%.3f' %
            sum([e.get_elapsed_time() for e in tests]))

        failures = len([1 for e in tests if e.outcome == _TestInfo.FAILURE])
        testsuite.setAttribute('failures', str(failures))

        errors = len([1 for e in tests if e.outcome == _TestInfo.ERROR])
        testsuite.setAttribute('errors', str(errors))

        return testsuite

    _report_testsuite = staticmethod(_report_testsuite)

    def _report_testcase(suite_name, test_result, xml_testsuite, xml_document):
        "Appends a testcase section to the XML document."
        testcase = xml_document.createElement('testcase')
        xml_testsuite.appendChild(testcase)

        testcase.setAttribute('classname', str(suite_name))
        testcase.setAttribute('name', test_result.test_method.shortDescription()
                              or getattr(test_result.test_method, '_testMethodName',
                                         str(test_result.test_method)))
        testcase.setAttribute('time', '%.3f' % test_result.get_elapsed_time())

        if (test_result.outcome != _TestInfo.SUCCESS):
            elem_name = ('failure', 'error')[test_result.outcome-1]
            failure = xml_document.createElement(elem_name)
            testcase.appendChild(failure)

            failure.setAttribute('type', str(test_result.err[0].__name__))
            failure.setAttribute('message', str(test_result.err[1]))

            error_info = test_result.get_error_info()
            failureText = xml_document.createCDATAOrText(error_info)
            failure.appendChild(failureText)

    _report_testcase = staticmethod(_report_testcase)

    def _report_output(test_runner, xml_testsuite, xml_document, stdout, stderr):
        "Appends the system-out and system-err sections to the XML document."
        systemout = xml_document.createElement('system-out')
        xml_testsuite.appendChild(systemout)

        systemout_text = xml_document.createCDATAOrText(stdout)
        systemout.appendChild(systemout_text)

        systemerr = xml_document.createElement('system-err')
        xml_testsuite.appendChild(systemerr)

        systemerr_text = xml_document.createCDATAOrText(stderr)
        systemerr.appendChild(systemerr_text)

    _report_output = staticmethod(_report_output)

    def generate_reports(self, test_runner):
        "Generates the XML reports to a given XMLTestRunner object."
        all_results = self._get_info_by_testcase()

        if type(test_runner.output) == str and not \
            os.path.exists(test_runner.output):
            os.makedirs(test_runner.output)

        for suite, tests in all_results.items():
            doc = XMLDocument()

            # Build the XML file
            testsuite = _XMLTestResult._report_testsuite(suite, tests, doc)
            stdout, stderr = [], []
            for test in tests:
                _XMLTestResult._report_testcase(suite, test, testsuite, doc)
                if test.stdout:
                    stdout.extend(['*****************', test.get_description(), test.stdout])
                if test.stderr:
                    stderr.extend(['*****************', test.get_description(), test.stderr])
            _XMLTestResult._report_output(test_runner, testsuite, doc,
                                          '\n'.join(stdout), '\n'.join(stderr))
            xml_content = doc.toprettyxml(indent='\t')

            if type(test_runner.output) is str:
                report_file = open('%s%sTEST-%s.xml' % \
                    (test_runner.output, os.sep, suite), 'w')
                try:
                    report_file.write(xml_content)
                finally:
                    report_file.close()
            else:
                # Assume that test_runner.output is a stream
                test_runner.output.write(xml_content)


class XMLTestRunner(TextTestRunner):
    """A test runner class that outputs the results in JUnit like XML files.
    """
    def __init__(self, output='.', stream=sys.stderr, descriptions=True, \
        verbose=False, elapsed_times=True):
        "Create a new instance of XMLTestRunner."
        verbosity = (1, 2)[verbose]
        TextTestRunner.__init__(self, stream, descriptions, verbosity)
        self.output = output
        self.elapsed_times = elapsed_times

    def _make_result(self):
        """Create the TestResult object which will be used to store
        information about the executed tests.
        """
        return _XMLTestResult(self.stream, self.descriptions, \
            self.verbosity, self.elapsed_times)

    def run(self, test):
        "Run the given test case or test suite."
        # Prepare the test execution
        result = self._make_result()

        # Print a nice header
        self.stream.writeln()
        self.stream.writeln('Running tests...')
        self.stream.writeln(result.separator2)

        # Execute tests
        start_time = time.time()
        test(result)
        stop_time = time.time()
        time_taken = stop_time - start_time

        # Print results
        result.printErrors()
        self.stream.writeln(result.separator2)
        run = result.testsRun
        self.stream.writeln("Ran %d test%s in %.3fs" %
            (run, run != 1 and "s" or "", time_taken))
        self.stream.writeln()

        # Error traces
        if not result.wasSuccessful():
            self.stream.write("FAILED (")
            failed, errored = (len(result.failures), len(result.errors))
            if failed:
                self.stream.write("failures=%d" % failed)
            if errored:
                if failed:
                    self.stream.write(", ")
                self.stream.write("errors=%d" % errored)
            self.stream.writeln(")")
        else:
            self.stream.writeln("OK")

        # Generate reports
        self.stream.writeln()
        self.stream.writeln('Generating XML reports...')
        result.generate_reports(self)

        return result
