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

var LOUPE_MAGNIFICATION_FACTOR = 10;

function Loupe()
{
    this._node = $('loupe');
    this._currentCornerX = -1;
    this._currentCornerY = -1;

    var self = this;

    function handleOutputClick(event) { self._handleOutputClick(event); }
    $('expected-image').addEventListener('click', handleOutputClick);
    $('actual-image').addEventListener('click', handleOutputClick);
    $('diff-canvas').addEventListener('click', handleOutputClick);

    function handleLoupeClick(event) { self._handleLoupeClick(event); }
    $('expected-loupe').addEventListener('click', handleLoupeClick);
    $('actual-loupe').addEventListener('click', handleLoupeClick);
    $('diff-loupe').addEventListener('click', handleLoupeClick);

    function hide(event) { self.hide(); }
    $('loupe-close').addEventListener('click', hide);
}

Loupe.prototype._handleOutputClick = function(event)
{
    // The -1 compensates for the border around the image/canvas.
    this._showFor(event.offsetX - 1, event.offsetY - 1);
};

Loupe.prototype._handleLoupeClick = function(event)
{
    var deltaX = Math.floor(event.offsetX/LOUPE_MAGNIFICATION_FACTOR);
    var deltaY = Math.floor(event.offsetY/LOUPE_MAGNIFICATION_FACTOR);

    this._showFor(
        this._currentCornerX + deltaX, this._currentCornerY + deltaY);
}

Loupe.prototype.hide = function()
{
    this._node.style.display = 'none';
};

Loupe.prototype._showFor = function(x, y)
{
    this._fillFromImage(x, y, 'expected', $('expected-image'));
    this._fillFromImage(x, y, 'actual', $('actual-image'));
    this._fillFromCanvas(x, y, 'diff', $('diff-canvas'));

    this._node.style.display = '';
};

Loupe.prototype._fillFromImage = function(x, y, type, sourceImage)
{
    var tempCanvas = document.createElement('canvas');
    tempCanvas.width = sourceImage.width;
    tempCanvas.height = sourceImage.height;
    var tempContext = tempCanvas.getContext('2d');

    tempContext.drawImage(sourceImage, 0, 0);

    this._fillFromCanvas(x, y, type, tempCanvas);
};

Loupe.prototype._fillFromCanvas = function(x, y, type, canvas)
{
    var context = canvas.getContext('2d');
    var sourceImageData =
        context.getImageData(0, 0, canvas.width, canvas.height);

    var targetCanvas = $(type + '-loupe');
    var targetContext = targetCanvas.getContext('2d');
    targetContext.fillStyle = 'rgba(255, 255, 255, 1)';
    targetContext.fillRect(0, 0, targetCanvas.width, targetCanvas.height);

    var sourceXOffset = (targetCanvas.width/LOUPE_MAGNIFICATION_FACTOR - 1)/2;
    var sourceYOffset = (targetCanvas.height/LOUPE_MAGNIFICATION_FACTOR - 1)/2;

    function readPixelComponent(x, y, component) {
        var offset = (y * sourceImageData.width + x) * 4 + component;
        return sourceImageData.data[offset];
    }

    for (var i = -sourceXOffset; i <= sourceXOffset; i++) {
        for (var j = -sourceYOffset; j <= sourceYOffset; j++) {
            var sourceX = x + i;
            var sourceY = y + j;

            var sourceR = readPixelComponent(sourceX, sourceY, 0);
            var sourceG = readPixelComponent(sourceX, sourceY, 1);
            var sourceB = readPixelComponent(sourceX, sourceY, 2);
            var sourceA = readPixelComponent(sourceX, sourceY, 3)/255;
            sourceA = Math.round(sourceA * 10)/10;

            var targetX = (i + sourceXOffset) * LOUPE_MAGNIFICATION_FACTOR;
            var targetY = (j + sourceYOffset) * LOUPE_MAGNIFICATION_FACTOR;
            var colorString =
                sourceR + ', ' + sourceG + ', ' + sourceB + ', ' + sourceA;
            targetContext.fillStyle = 'rgba(' + colorString + ')';
            targetContext.fillRect(
                targetX, targetY,
                LOUPE_MAGNIFICATION_FACTOR, LOUPE_MAGNIFICATION_FACTOR);

            if (i == 0 && j == 0) {
                $('loupe-coordinate').textContent = sourceX + ', ' + sourceY;
                $(type + '-loupe-color').textContent = colorString;
            }
        }
    }

    this._currentCornerX = x - sourceXOffset;
    this._currentCornerY = y - sourceYOffset;
};
