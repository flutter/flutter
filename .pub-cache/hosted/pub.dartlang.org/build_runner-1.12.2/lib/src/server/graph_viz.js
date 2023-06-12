window.$build = {}
window.$build.initializeGraph = function (scope) {
    scope.options = {
        layout: {
            hierarchical: { enabled: true }
        },
        physics: { enabled: true },
        configure: {
            showButton: false
        },
        edges: {
            arrows: {
                to: {
                    enabled: true
                }
            }
        }
    };
    scope.graphContainer = document.getElementById('graph');
    scope.network = new vis.Network(
        scope.graphContainer, { nodes: [], edges: [] }, scope.options);
    scope.network.on('doubleClick', function (event) {
        if (event.nodes.length >= 1) {
            var nodeId = event.nodes[0];
            scope.onFocus(nodeId);
            return null;
        }
    });

    return function (onFocus) {
      scope.onFocus = onFocus;
    };
}(window.$build);
window.$build.setData = function (scope) {
    return function (data) {
        scope.network.setData(data);
    }
}(window.$build);
