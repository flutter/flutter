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

var results;
var testsByFailureType = {};
var testsByDirectory = {};
var selectedTests = [];

function $(id)
{
    return document.getElementById(id);
}

function getSelectValue(id) 
{
    var select = $(id);
    if (select.selectedIndex == -1) {
        return null;
    } else {
        return select.options[select.selectedIndex].value;
    }
}

function loadText(url, callback)
{
    var xhr = new XMLHttpRequest();
    xhr.open('GET', url);
    xhr.addEventListener('load', function() { callback(xhr.responseText); });
    xhr.send();
}

function log(text, type)
{
    var node = $('log');
    
    if (type) {
        var typeNode = document.createElement('span');
        typeNode.textContent = type.text;
        typeNode.style.color = type.color;
        node.appendChild(typeNode);
    }

    node.appendChild(document.createTextNode(text + '\n'));
    node.scrollTop = node.scrollHeight;
}

log.WARNING = {text: 'Warning: ', color: '#aa3'};
log.SUCCESS = {text: 'Success: ', color: 'green'};
log.ERROR = {text: 'Error: ', color: 'red'};

function toggle(id)
{
    var element = $(id);
    var toggler = $('toggle-' + id);
    if (element.style.display == 'none') {
        element.style.display = '';
        toggler.className = 'link selected';
    } else {
        element.style.display = 'none';
        toggler.className = 'link';
    }
}

function getTracUrl(layoutTestPath)
{
  return 'http://trac.webkit.org/browser/trunk/tests/' + layoutTestPath;
}

function getSortedKeys(obj)
{
    var keys = [];
    for (var key in obj) {
        keys.push(key);
    }
    keys.sort();
    return keys;
}