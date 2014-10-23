// Disable compositor hit testing
document.addEventListener('touchstart', function() {});

window.addEventListener('load', function() {
  // Create any shadow DOM nodes requested by the test.
  var shadowTrees = document.querySelectorAll('[make-shadow-dom]');
  if (shadowTrees.length > 0 && !HTMLElement.prototype.createShadowRoot) {
    document.body.innerHTML = 'ERROR: Shadow DOM not supported!';
    return;
  }
  for (var i = 0; i < shadowTrees.length; i++) {
    var tree = shadowTrees[i];
    var host = tree.previousElementSibling;
    if (!host.hasAttribute('shadow-host')) {
      document.body.innerHTML = 'ERROR: make-shadow-dom node must follow a shadow-host node';
      return;
    }
    tree.parentElement.removeChild(tree);
    var shadowRoot = host.createShadowRoot();
    shadowRoot.appendChild(tree);
  }
});

/*
 * Visualization of hit test locations for manual testing.
 * To be invoked manually (so it doesn't intefere with testing).
 */
function addMarker(x, y)
{
    const kMarkerSize = 6;
    var marker = document.createElement('div');
    marker.className = 'marker';
    marker.style.top = (y - kMarkerSize/2) + 'px';
    marker.style.left = (x - kMarkerSize/2) + 'px';
    document.body.appendChild(marker);
}

function addMarkers()
{
  var tests = document.querySelectorAll('[expected-action]');
  for (var i = 0; i < tests.length; i++) {
    var r = tests[i].getClientRects()[0];
    addMarker(r.left, r.top);
    addMarker(r.right - 1, r.bottom - 1);
    addMarker(r.left + r.width / 2, r.top + r.height / 2);
  }
}
