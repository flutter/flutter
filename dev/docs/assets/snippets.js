/**
 * Scripting for handling custom code snippets
 */

const shortSnippet = 'shortSnippet';
const longSnippet = 'longSnippet';
var visibleSnippet = shortSnippet;

/**
 * Shows the requested snippet. Values for "name" can be "shortSnippet" or
 * "longSnippet".
 */
function showSnippet(name) {
  if (visibleSnippet == name) return;
  if (visibleSnippet != null) {
    var shown = document.getElementById(visibleSnippet);
    var attribute = document.createAttribute('hidden');
    if (shown != null) {
      shown.setAttributeNode(attribute);
    }
    var button = document.getElementById(visibleSnippet + 'Button');
    if (button != null) {
      button.removeAttribute('selected');
    }
  }
  if (name == null || name == '') {
    visibleSnippet = null;
    return;
  }
  var newlyVisible = document.getElementById(name);
  if (newlyVisible != null) {
    visibleSnippet = name;
    newlyVisible.removeAttribute('hidden');
  } else {
    visibleSnippet = null;
  }
  var button = document.getElementById(name + 'Button');
  var selectedAttribute = document.createAttribute('selected');
  if (button != null) {
    button.setAttributeNode(selectedAttribute);
  }
}

// Finds a sibling to given element with the given id.
function findSiblingWithId(element, id) {
  var siblings = element.parentNode.children;
  var siblingWithId = null;
  for (var i = siblings.length; i--;) {
    if (siblings[i] == element) continue;
    if (siblings[i].id == id) {
      siblingWithId = siblings[i];
      break;
    }
  }
  return siblingWithId;
};

// Returns true if the browser supports the "copy" command.
function supportsCopying() {
  return !!document.queryCommandSupported &&
      !!document.queryCommandSupported('copy');
}

// Copies the text inside the currently visible snippet to the clipboard, or the
// given element, if any.
function copyTextToClipboard(element) {
  if (element == null) {
    var elementSelector = '#' + visibleSnippet + ' .language-dart';
    element = document.querySelector(elementSelector);
    if (element == null) {
      console.log(
          'copyTextToClipboard: Unable to find element for "' +
          elementSelector + '"');
      return;
    }
  }
  if (!supportsCopying()) {
    alert('Unable to copy to clipboard (not supported by browser)');
    return;
  }

  if (element.hasAttribute('contenteditable')) {
    element.focus();
  }

  var selection = window.getSelection();
  var range = document.createRange();

  range.selectNodeContents(element);
  selection.removeAllRanges();
  selection.addRange(range);
  document.execCommand('copy');
}
