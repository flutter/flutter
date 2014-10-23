/*
 * Copyright (c) 2010 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

function RebaselineQueue()
{
    this._selectNode = $('queue-select');
    this._rebaselineButtonNode = $('rebaseline-queue');
    this._toggleNode = $('toggle-queue');
    this._removeSelectionButtonNode = $('remove-queue-selection');

    this._inProgressRebaselineCount = 0;

    var self = this;
    $('add-to-rebaseline-queue').addEventListener(
        'click', function() { self.addCurrentTest(); });
    this._selectNode.addEventListener('change', updateState);
    this._removeSelectionButtonNode.addEventListener(
        'click', function() { self._removeSelection(); });
    this._rebaselineButtonNode.addEventListener(
        'click', function() { self.rebaseline(); });
    this._toggleNode.addEventListener(
        'click', function() { toggle('queue'); });
}

RebaselineQueue.prototype.updateState = function()
{
    var testName = getSelectedTest();

    var state = results.tests[testName].state;
    $('add-to-rebaseline-queue').disabled = state != STATE_NEEDS_REBASELINE;

    var queueLength = this._selectNode.options.length;
    if (this._inProgressRebaselineCount > 0) {
      this._rebaselineButtonNode.disabled = true;
      this._rebaselineButtonNode.textContent =
          'Rebaseline in progress (' + this._inProgressRebaselineCount +
          ' tests left)';
    } else if (queueLength == 0) {
      this._rebaselineButtonNode.disabled = true;
      this._rebaselineButtonNode.textContent = 'Rebaseline queue';
      this._toggleNode.textContent = 'Queue';
    } else {
      this._rebaselineButtonNode.disabled = false;
      this._rebaselineButtonNode.textContent =
          'Rebaseline queue (' + queueLength + ' tests)';
      this._toggleNode.textContent = 'Queue (' + queueLength + ' tests)';
    }
    this._removeSelectionButtonNode.disabled =
        this._selectNode.selectedIndex == -1;
};

RebaselineQueue.prototype.addCurrentTest = function()
{
    var testName = getSelectedTest();
    var test = results.tests[testName];

    if (test.state != STATE_NEEDS_REBASELINE) {
        log('Cannot add test with state "' + test.state + '" to queue.',
            log.WARNING);
        return;
    }

    var queueOption = document.createElement('option');
    queueOption.value = testName;
    queueOption.textContent = testName;
    this._selectNode.appendChild(queueOption);
    test.state = STATE_IN_QUEUE;
    updateState();
};

RebaselineQueue.prototype.removeCurrentTest = function()
{
    this._removeTest(getSelectedTest());
};

RebaselineQueue.prototype._removeSelection = function()
{
    if (this._selectNode.selectedIndex == -1)
        return;

    this._removeTest(
        this._selectNode.options[this._selectNode.selectedIndex].value);
};

RebaselineQueue.prototype._removeTest = function(testName)
{
    var queueOption = this._selectNode.firstChild;

    while (queueOption && queueOption.value != testName) {
        queueOption = queueOption.nextSibling;
    }

    if (!queueOption)
        return;

    this._selectNode.removeChild(queueOption);
    var test = results.tests[testName];
    test.state = STATE_NEEDS_REBASELINE;
    updateState();
};

RebaselineQueue.prototype.rebaseline = function()
{
    var testNames = [];
    for (var queueOption = this._selectNode.firstChild;
         queueOption;
         queueOption = queueOption.nextSibling) {
        testNames.push(queueOption.value);
    }

    this._inProgressRebaselineCount = testNames.length;
    updateState();

    testNames.forEach(this._rebaselineTest, this);
};

RebaselineQueue.prototype._rebaselineTest = function(testName)
{
    var baselineTarget = getSelectValue('baseline-target');
    var baselineMoveTo = getSelectValue('baseline-move-to');

    var xhr = new XMLHttpRequest();
    xhr.open('POST',
        '/rebaseline?test=' + encodeURIComponent(testName) +
        '&baseline-target=' + encodeURIComponent(baselineTarget) +
        '&baseline-move-to=' + encodeURIComponent(baselineMoveTo));

    var self = this;
    function handleResponse(logType, newState) {
        log(xhr.responseText, logType);
        self._removeTest(testName);
        self._inProgressRebaselineCount--;
        results.tests[testName].state = newState;
        updateState();
        // If we're done with a set of rebaselines, regenerate the test menu
        // (which is grouped by state) since test states have changed.
        if (self._inProgressRebaselineCount == 0) {
            selectDirectory();
        }
    }

    function handleSuccess() {
        handleResponse(log.SUCCESS, STATE_REBASELINE_SUCCEEDED);
    }
    function handleFailure() {
        handleResponse(log.ERROR, STATE_REBASELINE_FAILED);
    }

    xhr.addEventListener('load', function() {
      if (xhr.status < 400) {
          handleSuccess();
      } else {
          handleFailure();
      }
    });
    xhr.addEventListener('error', handleFailure);

    xhr.send();
};
