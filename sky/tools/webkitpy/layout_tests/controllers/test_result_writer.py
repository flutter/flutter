# Copyright (C) 2011 Google Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#     * Neither the name of Google Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


import logging

from webkitpy.layout_tests.controllers import repaint_overlay
from webkitpy.layout_tests.models import test_failures


_log = logging.getLogger(__name__)


def write_test_result(filesystem, port, results_directory, test_name, driver_output,
                      expected_driver_output, failures):
    """Write the test result to the result output directory."""
    root_output_dir = results_directory
    writer = TestResultWriter(filesystem, port, root_output_dir, test_name)

    if driver_output.error:
        writer.write_stderr(driver_output.error)

    for failure in failures:
        # FIXME: Instead of this long 'if' block, each failure class might
        # have a responsibility for writing a test result.
        if isinstance(failure, (test_failures.FailureMissingResult,
                                test_failures.FailureTextMismatch,
                                test_failures.FailureTestHarnessAssertion)):
            writer.write_text_files(driver_output.text, expected_driver_output.text)
            writer.create_text_diff_and_write_result(driver_output.text, expected_driver_output.text)
        elif isinstance(failure, test_failures.FailureMissingImage):
            writer.write_image_files(driver_output.image, expected_image=None)
        elif isinstance(failure, test_failures.FailureMissingImageHash):
            writer.write_image_files(driver_output.image, expected_driver_output.image)
        elif isinstance(failure, test_failures.FailureImageHashMismatch):
            writer.write_image_files(driver_output.image, expected_driver_output.image)
            writer.write_image_diff_files(driver_output.image_diff)
        elif isinstance(failure, (test_failures.FailureAudioMismatch,
                                  test_failures.FailureMissingAudio)):
            writer.write_audio_files(driver_output.audio, expected_driver_output.audio)
        elif isinstance(failure, test_failures.FailureCrash):
            crashed_driver_output = expected_driver_output if failure.is_reftest else driver_output
            writer.write_crash_log(crashed_driver_output.crash_log)
        elif isinstance(failure, test_failures.FailureLeak):
            writer.write_leak_log(driver_output.leak_log)
        elif isinstance(failure, test_failures.FailureReftestMismatch):
            writer.write_image_files(driver_output.image, expected_driver_output.image)
            # FIXME: This work should be done earlier in the pipeline (e.g., when we compare images for non-ref tests).
            # FIXME: We should always have 2 images here.
            if driver_output.image and expected_driver_output.image:
                diff_image, err_str = port.diff_image(expected_driver_output.image, driver_output.image)
                if diff_image:
                    writer.write_image_diff_files(diff_image)
                else:
                    _log.warn('ref test mismatch did not produce an image diff.')
            writer.write_image_files(driver_output.image, expected_image=None)
            if filesystem.exists(failure.reference_filename):
                writer.write_reftest(failure.reference_filename)
            else:
                _log.warn("reference %s was not found" % failure.reference_filename)
        elif isinstance(failure, test_failures.FailureReftestMismatchDidNotOccur):
            writer.write_image_files(driver_output.image, expected_image=None)
            if filesystem.exists(failure.reference_filename):
                writer.write_reftest(failure.reference_filename)
            else:
                _log.warn("reference %s was not found" % failure.reference_filename)
        else:
            assert isinstance(failure, (test_failures.FailureTimeout, test_failures.FailureReftestNoImagesGenerated))

        writer.create_repaint_overlay_result(driver_output.text, expected_driver_output.text)


class TestResultWriter(object):
    """A class which handles all writing operations to the result directory."""

    # Filename pieces when writing failures to the test results directory.
    FILENAME_SUFFIX_ACTUAL = "-actual"
    FILENAME_SUFFIX_EXPECTED = "-expected"
    FILENAME_SUFFIX_DIFF = "-diff"
    FILENAME_SUFFIX_STDERR = "-stderr"
    FILENAME_SUFFIX_CRASH_LOG = "-crash-log"
    FILENAME_SUFFIX_SAMPLE = "-sample"
    FILENAME_SUFFIX_LEAK_LOG = "-leak-log"
    FILENAME_SUFFIX_WDIFF = "-wdiff.html"
    FILENAME_SUFFIX_PRETTY_PATCH = "-pretty-diff.html"
    FILENAME_SUFFIX_IMAGE_DIFF = "-diff.png"
    FILENAME_SUFFIX_IMAGE_DIFFS_HTML = "-diffs.html"
    FILENAME_SUFFIX_OVERLAY = "-overlay.html"

    def __init__(self, filesystem, port, root_output_dir, test_name):
        self._filesystem = filesystem
        self._port = port
        self._root_output_dir = root_output_dir
        self._test_name = test_name

    def _make_output_directory(self):
        """Creates the output directory (if needed) for a given test filename."""
        fs = self._filesystem
        output_filename = fs.join(self._root_output_dir, self._test_name)
        fs.maybe_make_directory(fs.dirname(output_filename))

    def output_filename(self, modifier):
        """Returns a filename inside the output dir that contains modifier.

        For example, if test name is "fast/dom/foo.html" and modifier is "-expected.txt",
        the return value is "/<path-to-root-output-dir>/fast/dom/foo-expected.txt".

        Args:
          modifier: a string to replace the extension of filename with

        Return:
          The absolute path to the output filename
        """
        fs = self._filesystem
        output_filename = fs.join(self._root_output_dir, self._test_name)
        return fs.splitext(output_filename)[0] + modifier

    def _write_file(self, path, contents):
        if contents is not None:
            self._make_output_directory()
            self._filesystem.write_binary_file(path, contents)

    def _output_testname(self, modifier):
        fs = self._filesystem
        return fs.splitext(fs.basename(self._test_name))[0] + modifier

    def write_output_files(self, file_type, output, expected):
        """Writes the test output, the expected output in the results directory.

        The full output filename of the actual, for example, will be
          <filename>-actual<file_type>
        For instance,
          my_test-actual.txt

        Args:
          file_type: A string describing the test output file type, e.g. ".txt"
          output: A string containing the test output
          expected: A string containing the expected test output
        """
        actual_filename = self.output_filename(self.FILENAME_SUFFIX_ACTUAL + file_type)
        expected_filename = self.output_filename(self.FILENAME_SUFFIX_EXPECTED + file_type)

        self._write_file(actual_filename, output)
        self._write_file(expected_filename, expected)

    def write_stderr(self, error):
        filename = self.output_filename(self.FILENAME_SUFFIX_STDERR + ".txt")
        self._write_file(filename, error)

    def write_crash_log(self, crash_log):
        filename = self.output_filename(self.FILENAME_SUFFIX_CRASH_LOG + ".txt")
        self._write_file(filename, crash_log.encode('utf8', 'replace'))

    def write_leak_log(self, leak_log):
        filename = self.output_filename(self.FILENAME_SUFFIX_LEAK_LOG + ".txt")
        self._write_file(filename, leak_log)

    def copy_sample_file(self, sample_file):
        filename = self.output_filename(self.FILENAME_SUFFIX_SAMPLE + ".txt")
        self._filesystem.copyfile(sample_file, filename)

    def write_text_files(self, actual_text, expected_text):
        self.write_output_files(".txt", actual_text, expected_text)

    def create_text_diff_and_write_result(self, actual_text, expected_text):
        # FIXME: This function is actually doing the diffs as well as writing results.
        # It might be better to extract code which does 'diff' and make it a separate function.
        if not actual_text or not expected_text:
            return

        file_type = '.txt'
        actual_filename = self.output_filename(self.FILENAME_SUFFIX_ACTUAL + file_type)
        expected_filename = self.output_filename(self.FILENAME_SUFFIX_EXPECTED + file_type)
        # We treat diff output as binary. Diff output may contain multiple files
        # in conflicting encodings.
        diff = self._port.diff_text(expected_text, actual_text, expected_filename, actual_filename)
        diff_filename = self.output_filename(self.FILENAME_SUFFIX_DIFF + file_type)
        self._write_file(diff_filename, diff)

        # Shell out to wdiff to get colored inline diffs.
        if self._port.wdiff_available():
            wdiff = self._port.wdiff_text(expected_filename, actual_filename)
            wdiff_filename = self.output_filename(self.FILENAME_SUFFIX_WDIFF)
            self._write_file(wdiff_filename, wdiff)

        # Use WebKit's PrettyPatch.rb to get an HTML diff.
        if self._port.pretty_patch_available():
            pretty_patch = self._port.pretty_patch_text(diff_filename)
            pretty_patch_filename = self.output_filename(self.FILENAME_SUFFIX_PRETTY_PATCH)
            self._write_file(pretty_patch_filename, pretty_patch)

    def create_repaint_overlay_result(self, actual_text, expected_text):
        html = repaint_overlay.generate_repaint_overlay_html(self._test_name, actual_text, expected_text)
        if html:
            overlay_filename = self.output_filename(self.FILENAME_SUFFIX_OVERLAY)
            self._write_file(overlay_filename, html)

    def write_audio_files(self, actual_audio, expected_audio):
        self.write_output_files('.wav', actual_audio, expected_audio)

    def write_image_files(self, actual_image, expected_image):
        self.write_output_files('.png', actual_image, expected_image)

    def write_image_diff_files(self, image_diff):
        diff_filename = self.output_filename(self.FILENAME_SUFFIX_IMAGE_DIFF)
        self._write_file(diff_filename, image_diff)

        diffs_html_filename = self.output_filename(self.FILENAME_SUFFIX_IMAGE_DIFFS_HTML)
        # FIXME: old-run-webkit-tests shows the diff percentage as the text contents of the "diff" link.
        # FIXME: old-run-webkit-tests include a link to the test file.
        html = """<!DOCTYPE HTML>
<html>
<head>
<title>%(title)s</title>
<style>.label{font-weight:bold}</style>
</head>
<body>
Difference between images: <a href="%(diff_filename)s">diff</a><br>
<div class=imageText></div>
<div class=imageContainer data-prefix="%(prefix)s">Loading...</div>
<script>
(function() {
    var preloadedImageCount = 0;
    function preloadComplete() {
        ++preloadedImageCount;
        if (preloadedImageCount < 2)
            return;
        toggleImages();
        setInterval(toggleImages, 2000)
    }

    function preloadImage(url) {
        image = new Image();
        image.addEventListener('load', preloadComplete);
        image.src = url;
        return image;
    }

    function toggleImages() {
        if (text.textContent == 'Expected Image') {
            text.textContent = 'Actual Image';
            container.replaceChild(actualImage, container.firstChild);
        } else {
            text.textContent = 'Expected Image';
            container.replaceChild(expectedImage, container.firstChild);
        }
    }

    var text = document.querySelector('.imageText');
    var container = document.querySelector('.imageContainer');
    var actualImage = preloadImage(container.getAttribute('data-prefix') + '-actual.png');
    var expectedImage = preloadImage(container.getAttribute('data-prefix') + '-expected.png');
})();
</script>
</body>
</html>
""" % {
            'title': self._test_name,
            'diff_filename': self._output_testname(self.FILENAME_SUFFIX_IMAGE_DIFF),
            'prefix': self._output_testname(''),
        }
        self._write_file(diffs_html_filename, html)

    def write_reftest(self, src_filepath):
        fs = self._filesystem
        dst_dir = fs.dirname(fs.join(self._root_output_dir, self._test_name))
        dst_filepath = fs.join(dst_dir, fs.basename(src_filepath))
        self._write_file(dst_filepath, fs.read_binary_file(src_filepath))
