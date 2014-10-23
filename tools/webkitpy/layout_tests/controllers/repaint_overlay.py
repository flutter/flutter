# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import re


def result_contains_repaint_rects(text):
    return isinstance(text, str) and (
        re.search('"repaintRects": \[$', text, re.MULTILINE) != None or
        text.find('Minimum repaint:') != -1)


def extract_layer_tree(input_str):
    if not isinstance(input_str, str):
        return '{}'

    if input_str[0:2] == '{\n':
        start = 0
    else:
        start = input_str.find('\n{\n')
        if start == -1:
            return '{}'

    end = input_str.find('\n}\n', start)
    if end == -1:
        return '{}'

    # FIXME: There may be multiple layer trees in the result.
    return input_str[start:end + 3]


def generate_repaint_overlay_html(test_name, actual_text, expected_text):
    if not result_contains_repaint_rects(actual_text) and not result_contains_repaint_rects(expected_text):
        return ''

    expected_layer_tree = extract_layer_tree(expected_text)
    actual_layer_tree = extract_layer_tree(actual_text)

    minimum_repaint = '[]'
    minimum_repaint_match = re.search('Minimum repaint:\n(\[.*\n\])', actual_text, re.DOTALL)
    if minimum_repaint_match:
        minimum_repaint = minimum_repaint_match.group(1)

    return """<!DOCTYPE HTML>
<html>
<head>
<title>%(title)s</title>
<style>
    body {
        margin: 0;
        padding: 0;
    }
    iframe {
      position: absolute;
      top: 80px;
      left: 0;
      border: 0;
      z-index: -1;
    }
    canvas {
      position: absolute;
      top: 80px;
      left: 0;
      z-index: 1;
    }
    #actual, #minimum-repaint {
      display: none;
    }
</style>
</head>
<body>
<a href="http://crbug.com/381221">Known issues</a><br>
<label><input id="show-test" type="checkbox" checked onchange="toggle_test(this.checked)">Show test</label>
<label title="See fast/repaint/resources/text-based-repaint.js for how this works">
    <input id="show-minimum-repaint" type="checkbox" onchange="toggle_minimum_repaint(this.checked)">Minimum repaint
</label>
<label><input id="use-solid-colors" type="checkbox" onchange="toggle_solid_color(this.checked)">Use solid colors</label>
<br>
<button title="See fast/repaint/resources/text-based-repaint.js for how this works" onclick="highlight_under_repaint()">
    Highlight under-repaint
</button>
<br>
<span id='type'>Expected Invalidations</span>
<div id=overlay>
    <canvas id='minimum-repaint' width='2000' height='2000'></canvas>
    <canvas id='expected' width='2000' height='2000'></canvas>
    <canvas id='actual' width='2000' height='2000'></canvas>
</div>
<script>
var overlay_opacity = 0.25;

function toggle_test(show_test) {
    iframe.style.display = show_test ? 'block' : 'none';
}

function toggle_minimum_repaint(show_minimum_repaint) {
    document.getElementById('minimum-repaint').style.display = show_minimum_repaint ? 'block' : 'none';
}

function toggle_solid_color(use_solid_color) {
    overlay_opacity = use_solid_color ? 1 : 0.25;
    draw_repaint_rects();
    draw_minimum_repaint();
}

function highlight_under_repaint() {
    document.getElementById('show-test').checked = false;
    toggle_test(false);
    document.getElementById('show-minimum-repaint').checked = true;
    toggle_minimum_repaint(true);
    document.getElementById('use-solid-colors').checked = true;
    toggle_solid_color(true);
}

var expected = %(expected)s;
var actual = %(actual)s;
var minimum_repaint = %(minimum_repaint)s;

function rectsEqual(rect1, rect2) {
    return rect1[0] == rect2[0] && rect1[1] == rect2[1] && rect1[2] == rect2[2] && rect1[3] == rect2[3];
}

function draw_rects(context, rects) {
    for (var i = 0; i < rects.length; ++i) {
        var rect = rects[i];
        context.fillRect(rect[0], rect[1], rect[2], rect[3]);
    }
}

function draw_layer_rects(context, result) {
    context.save();
    if (result.position)
        context.translate(result.position[0], result.position[1]);
    var t = result.transform;
    if (t) {
        var origin = result.transformOrigin || [result.bounds[0] / 2, result.bounds[1] / 2];
        context.translate(origin[0], origin[1]);
        context.transform(t[0][0], t[0][1], t[1][0], t[1][1], t[3][0], t[3][1]);
        context.translate(-origin[0], -origin[1]);
    }
    if (result.repaintRects)
        draw_rects(context, result.repaintRects);
    if (result.children) {
        for (var i = 0; i < result.children.length; ++i)
            draw_layer_rects(context, result.children[i]);
    }
    context.restore();
}

var expected_canvas = document.getElementById('expected');
var actual_canvas = document.getElementById('actual');
var minimum_repaint_canvas = document.getElementById('minimum-repaint');

function draw_repaint_rects() {
    var expected_ctx = expected_canvas.getContext("2d");
    expected_ctx.clearRect(0, 0, 2000, 2000);
    expected_ctx.fillStyle = 'rgba(255, 0, 0, ' + overlay_opacity + ')';
    draw_layer_rects(expected_ctx, expected);

    var actual_ctx = actual_canvas.getContext("2d");
    actual_ctx.clearRect(0, 0, 2000, 2000);
    actual_ctx.fillStyle = 'rgba(0, 255, 0, ' + overlay_opacity + ')';
    draw_layer_rects(actual_ctx, actual);
}

function draw_minimum_repaint() {
    var context = minimum_repaint_canvas.getContext("2d");
    context.fillStyle = 'rgba(0, 0, 0, 1)';
    draw_rects(context, minimum_repaint);
}

draw_repaint_rects();
draw_minimum_repaint();

var path = decodeURIComponent(location.search).substr(1);
var iframe = document.createElement('iframe');
iframe.id = 'test-frame';
iframe.width = 800;
iframe.height = 600;
iframe.src = path;

var overlay = document.getElementById('overlay');
overlay.appendChild(iframe);

var type = document.getElementById('type');
var expected_showing = true;
function flip() {
    if (expected_showing) {
        type.textContent = 'Actual Invalidations';
        expected_canvas.style.display = 'none';
        actual_canvas.style.display = 'block';
    } else {
        type.textContent = 'Expected Invalidations';
        actual_canvas.style.display = 'none';
        expected_canvas.style.display = 'block';
    }
    expected_showing = !expected_showing
}
setInterval(flip, 3000);
</script>
</body>
</html>
""" % {
        'title': test_name,
        'expected': expected_layer_tree,
        'actual': actual_layer_tree,
        'minimum_repaint': minimum_repaint,
    }
