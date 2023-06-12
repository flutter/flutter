(function () {
  var _buildUpdatesProtocol = '$buildUpdates';

  var ws = new WebSocket('ws://' + location.host, [_buildUpdatesProtocol]);
  ws.onmessage = function (event) {
    location.reload();
  };
})();