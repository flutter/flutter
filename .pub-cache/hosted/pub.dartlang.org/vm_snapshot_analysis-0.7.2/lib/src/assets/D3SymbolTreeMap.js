// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO:
// 1. Visibility functions: base on boxPadding.t, not 15
// 2. Track a maxDisplayDepth that is user-settable:
//    maxDepth == currentRoot.depth + maxDisplayDepth
function D3SymbolTreeMap(mapWidth, mapHeight, levelsToShow) {
  this._mapContainer = undefined;
  this._mapWidth = mapWidth;
  this._mapHeight = mapHeight;
  this.boxPadding = {'l': 5, 'r': 5, 't': 20, 'b': 5};
  this.infobox = undefined;
  this._maskContainer = undefined;
  this._highlightContainer = undefined;
  // Transition in this order:
  // 1. Exiting items go away.
  // 2. Updated items move.
  // 3. New items enter.
  this._exitDuration=500;
  this._updateDuration=500;
  this._enterDuration=500;
  this._firstTransition=true;
  this._layout = undefined;
  this._currentRoot = undefined;
  this._currentNodes = undefined;
  this._treeData = undefined;
  this._maxLevelsToShow = levelsToShow;
  this._currentMaxDepth = this._maxLevelsToShow;
}

/**
 * Make a number pretty, with comma separators.
 */
D3SymbolTreeMap._pretty = function(num) {
  var asString = String(num);
  var result = '';
  var counter = 0;
  for (var x = asString.length - 1; x >= 0; x--) {
    counter++;
    if (counter === 4) {
      result = ',' + result;
      counter = 1;
    }
    result = asString.charAt(x) + result;
  }
  return result;
}

/**
 * Express a number in terms of KiB, MiB, GiB, etc.
 * Note that these are powers of 2, not of 10.
 */
D3SymbolTreeMap._byteify = function(num) {
  var suffix;
  if (num >= 1024) {
    if (num >= 1024 * 1024 * 1024) {
      suffix = 'GiB';
      num = num / (1024 * 1024 * 1024);
    } else if (num >= 1024 * 1024) {
      suffix = 'MiB';
      num = num / (1024 * 1024);
    } else if (num >= 1024) {
      suffix = 'KiB'
      num = num / 1024;
    }
    return num.toFixed(2) + ' ' + suffix;
  }
  return num + ' B';
}

D3SymbolTreeMap._NM_SYMBOL_TYPE_DESCRIPTIONS = {
  // Definitions concisely derived from the nm 'man' page
  'A': 'Global absolute (A)',
  'B': 'Global uninitialized data (B)',
  'b': 'Local uninitialized data (b)',
  'C': 'Global uninitialized common (C)',
  'D': 'Global initialized data (D)',
  'd': 'Local initialized data (d)',
  'G': 'Global small initialized data (G)',
  'g': 'Local small initialized data (g)',
  'i': 'Indirect function (i)',
  'N': 'Debugging (N)',
  'p': 'Stack unwind (p)',
  'R': 'Global read-only data (R)',
  'r': 'Local read-only data (r)',
  'S': 'Global small uninitialized data (S)',
  's': 'Local small uninitialized data (s)',
  'T': 'Global code (T)',
  't': 'Local code (t)',
  'U': 'Undefined (U)',
  'u': 'Unique (u)',
  'V': 'Global weak object (V)',
  'v': 'Local weak object (v)',
  'W': 'Global weak symbol (W)',
  'w': 'Local weak symbol (w)',
  '@': 'Vtable entry (@)', // non-standard, hack.
  '-': 'STABS debugging (-)',
  '?': 'Unrecognized (?)',
};
D3SymbolTreeMap._NM_SYMBOL_TYPES = '';
for (var symbol_type in D3SymbolTreeMap._NM_SYMBOL_TYPE_DESCRIPTIONS) {
  D3SymbolTreeMap._NM_SYMBOL_TYPES += symbol_type;
}

/**
 * Given a symbol type code, look up and return a human-readable description
 * of that symbol type. If the symbol type does not match one of the known
 * types, the unrecognized description (corresponding to symbol type '?') is
 * returned instead of null or undefined.
 */
D3SymbolTreeMap._getSymbolDescription = function(type) {
  var result = D3SymbolTreeMap._NM_SYMBOL_TYPE_DESCRIPTIONS[type];
  if (result === undefined) {
    result = D3SymbolTreeMap._NM_SYMBOL_TYPE_DESCRIPTIONS['?'];
  }
  return result;
}

// Qualitative 12-value pastel Brewer palette.
D3SymbolTreeMap._colorArray = [
  'rgb(141,211,199)',
  'rgb(255,255,179)',
  'rgb(190,186,218)',
  'rgb(251,128,114)',
  'rgb(128,177,211)',
  'rgb(253,180,98)',
  'rgb(179,222,105)',
  'rgb(252,205,229)',
  'rgb(217,217,217)',
  'rgb(188,128,189)',
  'rgb(204,235,197)',
  'rgb(255,237,111)'];

D3SymbolTreeMap._initColorMap = function() {
  var map = {};
  var numColors = D3SymbolTreeMap._colorArray.length;
  var count = 0;
  for (var key in D3SymbolTreeMap._NM_SYMBOL_TYPE_DESCRIPTIONS) {
    var index = count++ % numColors;
    map[key] = d3.rgb(D3SymbolTreeMap._colorArray[index]);
  }
  D3SymbolTreeMap._colorMap = map;
}
D3SymbolTreeMap._initColorMap();

D3SymbolTreeMap.getColorForType = function(type) {
  var result = D3SymbolTreeMap._colorMap[type];
  if (result === undefined) return d3.rgb('rgb(255,255,255)');
  return result;
}

D3SymbolTreeMap.prototype.init = function() {
  this.infobox = this._createInfoBox();
  this._mapContainer = d3.select('body').append('div')
      .style('position', 'relative')
      .style('width', this._mapWidth)
      .style('height', this._mapHeight)
      .style('padding', 0)
      .style('margin', 0)
      .style('box-shadow', '5px 5px 5px #888');
  this._layout = this._createTreeMapLayout();
  this._setData(tree_data); // TODO: Don't use global 'tree_data'
}

/**
 * Sets the data displayed by the treemap and layint out the map.
 */
D3SymbolTreeMap.prototype._setData = function(data) {
  this._treeData = data;
  console.time('_crunchStats');
  this._crunchStats(data);
  console.timeEnd('_crunchStats');
  this._currentRoot = this._treeData;
  this._currentNodes = this._layout.nodes(this._currentRoot);
  this._currentMaxDepth = this._maxLevelsToShow;
  this._doLayout();
}

/**
 * Recursively traverses the entire tree starting from the specified node,
 * computing statistics and recording metadata as it goes. Call this method
 * only once per imported tree.
 */
D3SymbolTreeMap.prototype._crunchStats = function(node) {
  var stack = [];
  stack.idCounter = 0;
  this._crunchStatsHelper(stack, node);
}

/**
 * Invoke the specified visitor function on all data elements currently shown
 * in the treemap including any and all of their children, starting at the
 * currently-displayed root and descending recursively. The function will be
 * passed the datum element representing each node. No traversal guarantees
 * are made.
 */
D3SymbolTreeMap.prototype.visitFromDisplayedRoot = function(visitor) {
  this._visit(this._currentRoot, visitor);
}

/**
 * Helper function for visit functions.
 */
D3SymbolTreeMap.prototype._visit = function(datum, visitor) {
  visitor.call(this, datum);
  if (datum.children) for (var i = 0; i < datum.children.length; i++) {
    this._visit(datum.children[i], visitor);
  }
}

D3SymbolTreeMap.prototype._crunchStatsHelper = function(stack, node) {
  // Only overwrite the node ID if it isn't already set.
  // This allows stats to be crunched multiple times on subsets of data
  // without breaking the data-to-ID bindings. New nodes get new IDs.
  if (node.id === undefined) node.id = stack.idCounter++;
  if (node.children === undefined) {
    // Leaf node (symbol); accumulate stats.
    for (var i = 0; i < stack.length; i++) {
      var ancestor = stack[i];
      if (!ancestor.symbol_stats) ancestor.symbol_stats = {};
      if (ancestor.symbol_stats[node.t] === undefined) {
        // New symbol type we haven't seen before, just record.
        ancestor.symbol_stats[node.t] = {'count': 1,
                                         'size': node.value};
      } else {
        // Existing symbol type, increment.
        ancestor.symbol_stats[node.t].count++;
        ancestor.symbol_stats[node.t].size += node.value;
      }
    }
  } else for (var i = 0; i < node.children.length; i++) {
    stack.push(node);
    this._crunchStatsHelper(stack, node.children[i]);
    stack.pop();
  }
}

D3SymbolTreeMap.prototype._createTreeMapLayout = function() {
  var result = d3.layout.treemap()
      .padding([this.boxPadding.t, this.boxPadding.r,
                this.boxPadding.b, this.boxPadding.l])
      .size([this._mapWidth, this._mapHeight]);
  return result;
}

D3SymbolTreeMap.prototype.resize = function(width, height) {
  this._mapWidth = width;
  this._mapHeight = height;
  this._mapContainer.style('width', width).style('height', height);
  this._layout.size([this._mapWidth, this._mapHeight]);
  this._currentNodes = this._layout.nodes(this._currentRoot);
  this._doLayout();
}

D3SymbolTreeMap.prototype._zoomDatum = function(datum) {
  if (this._currentRoot === datum) return; // already here
  this._hideHighlight(datum);
  this._hideInfoBox(datum);
  this._currentRoot = datum;
  this._currentNodes = this._layout.nodes(this._currentRoot);
  this._currentMaxDepth = this._currentRoot.depth + this._maxLevelsToShow;
  console.log('zooming into datum ' + this._currentRoot.n);
  this._doLayout();
}

D3SymbolTreeMap.prototype.setMaxLevels = function(levelsToShow) {
  this._maxLevelsToShow = levelsToShow;
  this._currentNodes = this._layout.nodes(this._currentRoot);
  this._currentMaxDepth = this._currentRoot.depth + this._maxLevelsToShow;
  console.log('setting max levels to show: ' + this._maxLevelsToShow);
  this._doLayout();
}

/**
 * Clone the specified tree, returning an independent copy of the data.
 * Only the original attributes expected to exist prior to invoking
 * _crunchStatsHelper are retained, with the exception of the 'id' attribute
 * (which must be retained for proper transitions).
 * If the optional filter parameter is provided, it will be called with 'this'
 * set to this treemap instance and passed the 'datum' object as an argument.
 * When specified, the copy will retain only the data for which the filter
 * function returns true.
 */
D3SymbolTreeMap.prototype._clone = function(datum, filter) {
  var trackingStats = false;
  if (this.__cloneState === undefined) {
    console.time('_clone');
    trackingStats = true;
    this.__cloneState = {'accepted': 0, 'rejected': 0,
                         'forced': 0, 'pruned': 0};
  }

  // Must go depth-first. All parents of children that are accepted by the
  // filter must be preserved!
  var copy = {'n': datum.n, 'k': datum.k};
  var childAccepted = false;
  if (datum.children !== undefined) {
    for (var i = 0; i < datum.children.length; i++) {
      var copiedChild = this._clone(datum.children[i], filter);
      if (copiedChild !== undefined) {
        childAccepted = true; // parent must also be accepted.
        if (copy.children === undefined) copy.children = [];
        copy.children.push(copiedChild);
      }
    }
  }

  // Ignore nodes that don't match the filter, when present.
  var accept = false;
  if (childAccepted) {
    // Parent of an accepted child must also be accepted.
    this.__cloneState.forced++;
    accept = true;
  } else if (filter !== undefined && filter.call(this, datum) !== true) {
    this.__cloneState.rejected++;
  } else if (datum.children === undefined) {
    // Accept leaf nodes that passed the filter
    this.__cloneState.accepted++;
    accept = true;
  } else {
    // Non-leaf node. If no children are accepted, prune it.
    this.__cloneState.pruned++;
  }

  if (accept) {
    if (datum.id !== undefined) copy.id = datum.id;
    if (datum.lastPathElement !== undefined) {
      copy.lastPathElement = datum.lastPathElement;
    }
    if (datum.t !== undefined) copy.t = datum.t;
    if (datum.value !== undefined && datum.children === undefined) {
      copy.value = datum.value;
    }
  } else {
    // Discard the copy we were going to return
    copy = undefined;
  }

  if (trackingStats === true) {
    // We are the fist call in the recursive chain.
    console.timeEnd('_clone');
    var totalAccepted = this.__cloneState.accepted +
                        this.__cloneState.forced;
    console.log(
        totalAccepted + ' nodes retained (' +
        this.__cloneState.forced + ' forced by accepted children, ' +
        this.__cloneState.accepted + ' accepted on their own merits), ' +
        this.__cloneState.rejected + ' nodes (and their children) ' +
                                     'filtered out,' +
        this.__cloneState.pruned + ' nodes pruned because because no ' +
                                   'children remained.');
    delete this.__cloneState;
  }
  return copy;
}

D3SymbolTreeMap.prototype.filter = function(filter) {
  // Ensure we have a copy of the original root.
  if (this._backupTree === undefined) this._backupTree = this._treeData;
  this._mapContainer.selectAll('div').remove();
  this._setData(this._clone(this._backupTree, filter));
}

D3SymbolTreeMap.prototype._doLayout = function() {
  console.time('_doLayout');
  this._handleInodes();
  this._handleLeaves();
  this._firstTransition = false;
  console.timeEnd('_doLayout');
}

D3SymbolTreeMap.prototype._highlightElement = function(datum, selection) {
  this._showHighlight(datum, selection);
}

D3SymbolTreeMap.prototype._unhighlightElement = function(datum, selection) {
  this._hideHighlight(datum, selection);
}

D3SymbolTreeMap.prototype._handleInodes = function() {
  console.time('_handleInodes');
  var thisTreeMap = this;
  var inodes = this._currentNodes.filter(function(datum){
    return (datum.depth <= thisTreeMap._currentMaxDepth) &&
            datum.children !== undefined;
  });
  var cellsEnter = this._mapContainer.selectAll('div.inode')
      .data(inodes, function(datum) { return datum.id; })
      .enter()
      .append('div').attr('class', 'inode').attr('id', function(datum){
          return 'node-' + datum.id;});


  // Define enter/update/exit for inodes
  cellsEnter
      .append('div')
      .attr('class', 'rect inode_rect_entering')
      .style('z-index', function(datum) { return datum.id * 2; })
      .style('position', 'absolute')
      .style('left', function(datum) { return datum.x; })
      .style('top', function(datum){ return datum.y; })
      .style('width', function(datum){ return datum.dx; })
      .style('height', function(datum){ return datum.dy; })
      .style('opacity', '0')
      .style('border', '1px solid black')
      .style('background-image', function(datum) {
        return thisTreeMap._makeSymbolBucketBackgroundImage.call(
               thisTreeMap, datum);
      })
      .style('background-color', function(datum) {
        if (datum.t === undefined) return 'rgb(220,220,220)';
        return D3SymbolTreeMap.getColorForType(datum.t).toString();
      })
      .on('mouseover', function(datum){
        thisTreeMap._highlightElement.call(
            thisTreeMap, datum, d3.select(this));
        thisTreeMap._showInfoBox.call(thisTreeMap, datum);
      })
      .on('mouseout', function(datum){
        thisTreeMap._unhighlightElement.call(
            thisTreeMap, datum, d3.select(this));
        thisTreeMap._hideInfoBox.call(thisTreeMap, datum);
      })
      .on('mousemove', function(){
          thisTreeMap._moveInfoBox.call(thisTreeMap, event);
      })
      .on('dblclick', function(datum){
        if (datum !== thisTreeMap._currentRoot) {
          // Zoom into the selection
          thisTreeMap._zoomDatum(datum);
        } else if (datum.parent) {
          console.log('event.shiftKey=' + event.shiftKey);
          if (event.shiftKey === true) {
            // Back to root
            thisTreeMap._zoomDatum(thisTreeMap._treeData);
          } else {
            // Zoom out of the selection
            thisTreeMap._zoomDatum(datum.parent);
          }
        }
      });
  cellsEnter
      .append('div')
      .attr('class', 'label inode_label_entering')
      .style('z-index', function(datum) { return (datum.id * 2) + 1; })
      .style('position', 'absolute')
      .style('left', function(datum){ return datum.x; })
      .style('top', function(datum){ return datum.y; })
      .style('width', function(datum) { return datum.dx; })
      .style('height', function(datum) { return thisTreeMap.boxPadding.t; })
      .style('opacity', '0')
      .style('pointer-events', 'none')
      .style('-webkit-user-select', 'none')
      .style('overflow', 'hidden') // required for ellipsis
      .style('white-space', 'nowrap') // required for ellipsis
      .style('text-overflow', 'ellipsis')
      .style('text-align', 'center')
      .style('vertical-align', 'top')
      .style('visibility', function(datum) {
        return (datum.dx < 15 || datum.dy < 15) ? 'hidden' : 'visible';
      })
      .text(function(datum) {
        var sizeish = ' [' + D3SymbolTreeMap._byteify(datum.value) + ']'
        var text;
        if (datum.k === 'b') { // bucket
          if (datum === thisTreeMap._currentRoot) {
            text = thisTreeMap.pathFor(datum) + ': '
                + D3SymbolTreeMap._getSymbolDescription(datum.t)
          } else {
            text = D3SymbolTreeMap._getSymbolDescription(datum.t);
          }
        } else if (datum === thisTreeMap._currentRoot) {
          // The top-most level should always show the complete path
          text = thisTreeMap.pathFor(datum);
        } else {
          // Anything that isn't a bucket or a leaf (symbol) or the
          // current root should just show its name.
          text = datum.n;
        }
        return text + sizeish;
      }
  );

  // Complicated transition logic:
  // For nodes that are entering, we want to fade them in in-place AFTER
  // any adjusting nodes have resized and moved around. That way, new nodes
  // seamlessly appear in the right spot after their containers have resized
  // and moved around.
  // To do this we do some trickery:
  // 1. Define a '_entering' class on the entering elements
  // 2. Use this to select only the entering elements and apply the opacity
  //    transition.
  // 3. Use the same transition to drop the '_entering' suffix, so that they
  //    will correctly update in later zoom/resize/whatever operations.
  // 4. The update transition is achieved by selecting the elements without
  //    the '_entering_' suffix and applying movement and resizing transition
  //    effects.
  this._mapContainer.selectAll('div.inode_rect_entering').transition()
      .duration(thisTreeMap._enterDuration).delay(
          this._firstTransition ? 0 : thisTreeMap._exitDuration +
              thisTreeMap._updateDuration)
      .attr('class', 'rect inode_rect')
      .style('opacity', '1')
  this._mapContainer.selectAll('div.inode_label_entering').transition()
      .duration(thisTreeMap._enterDuration).delay(
          this._firstTransition ? 0 : thisTreeMap._exitDuration +
              thisTreeMap._updateDuration)
      .attr('class', 'label inode_label')
      .style('opacity', '1')
  this._mapContainer.selectAll('div.inode_rect').transition()
      .duration(thisTreeMap._updateDuration).delay(thisTreeMap._exitDuration)
      .style('opacity', '1')
      .style('background-image', function(datum) {
        return thisTreeMap._makeSymbolBucketBackgroundImage.call(
            thisTreeMap, datum);
      })
      .style('left', function(datum) { return datum.x; })
      .style('top', function(datum){ return datum.y; })
      .style('width', function(datum){ return datum.dx; })
      .style('height', function(datum){ return datum.dy; });
  this._mapContainer.selectAll('div.inode_label').transition()
      .duration(thisTreeMap._updateDuration).delay(thisTreeMap._exitDuration)
      .style('opacity', '1')
      .style('visibility', function(datum) {
        return (datum.dx < 15 || datum.dy < 15) ? 'hidden' : 'visible';
      })
      .style('left', function(datum){ return datum.x; })
      .style('top', function(datum){ return datum.y; })
      .style('width', function(datum) { return datum.dx; })
      .style('height', function(datum) { return thisTreeMap.boxPadding.t; })
      .text(function(datum) {
        var sizeish = ' [' + D3SymbolTreeMap._byteify(datum.value) + ']'
        var text;
        if (datum.k === 'b') {
          if (datum === thisTreeMap._currentRoot) {
            text = thisTreeMap.pathFor(datum) + ': ' +
                D3SymbolTreeMap._getSymbolDescription(datum.t)
          } else {
            text = D3SymbolTreeMap._getSymbolDescription(datum.t);
          }
        } else if (datum === thisTreeMap._currentRoot) {
          // The top-most level should always show the complete path
          text = thisTreeMap.pathFor(datum);
        } else {
          // Anything that isn't a bucket or a leaf (symbol) or the
          // current root should just show its name.
          text = datum.n;
        }
        return text + sizeish;
      });
  var exit = this._mapContainer.selectAll('div.inode')
      .data(inodes, function(datum) { return 'inode-' + datum.id; })
      .exit();
  exit.selectAll('div.inode_rect').transition().duration(
      thisTreeMap._exitDuration).style('opacity', 0);
  exit.selectAll('div.inode_label').transition().duration(
      thisTreeMap._exitDuration).style('opacity', 0);
  exit.transition().delay(thisTreeMap._exitDuration + 1).remove();

  console.log(inodes.length + ' inodes layed out.');
  console.timeEnd('_handleInodes');
}

D3SymbolTreeMap.prototype._handleLeaves = function() {
  console.time('_handleLeaves');
  var color_fn = d3.scale.category10();
  var thisTreeMap = this;
  var leaves = this._currentNodes.filter(function(datum){
    return (datum.depth <= thisTreeMap._currentMaxDepth) &&
        datum.children === undefined; });
  var cellsEnter = this._mapContainer.selectAll('div.leaf')
      .data(leaves, function(datum) { return datum.id; })
      .enter()
      .append('div').attr('class', 'leaf').attr('id', function(datum){
        return 'node-' + datum.id;
      });

  // Define enter/update/exit for leaves
  cellsEnter
      .append('div')
      .attr('class', 'rect leaf_rect_entering')
      .style('z-index', function(datum) { return datum.id * 2; })
      .style('position', 'absolute')
      .style('left', function(datum){ return datum.x; })
      .style('top', function(datum){ return datum.y; })
      .style('width', function(datum){ return datum.dx; })
      .style('height', function(datum){ return datum.dy; })
      .style('opacity', '0')
      .style('background-color', function(datum) {
        if (datum.t === undefined) return 'rgb(220,220,220)';
        return D3SymbolTreeMap.getColorForType(datum.t)
            .darker(0.3).toString();
      })
      .style('border', '1px solid black')
      .on('mouseover', function(datum){
        thisTreeMap._highlightElement.call(
            thisTreeMap, datum, d3.select(this));
        thisTreeMap._showInfoBox.call(thisTreeMap, datum);
      })
      .on('mouseout', function(datum){
        thisTreeMap._unhighlightElement.call(
            thisTreeMap, datum, d3.select(this));
        thisTreeMap._hideInfoBox.call(thisTreeMap, datum);
      })
      .on('mousemove', function(){ thisTreeMap._moveInfoBox.call(
        thisTreeMap, event);
      });
  cellsEnter
      .append('div')
      .attr('class', 'label leaf_label_entering')
      .style('z-index', function(datum) { return (datum.id * 2) + 1; })
      .style('position', 'absolute')
      .style('left', function(datum){ return datum.x; })
      .style('top', function(datum){ return datum.y; })
      .style('width', function(datum) { return datum.dx; })
      .style('height', function(datum) { return datum.dy; })
      .style('opacity', '0')
      .style('pointer-events', 'none')
      .style('-webkit-user-select', 'none')
      .style('overflow', 'hidden') // required for ellipsis
      .style('white-space', 'nowrap') // required for ellipsis
      .style('text-overflow', 'ellipsis')
      .style('text-align', 'center')
      .style('vertical-align', 'middle')
      .style('visibility', function(datum) {
        return (datum.dx < 15 || datum.dy < 15) ? 'hidden' : 'visible';
      })
      .text(function(datum) { return datum.n; });

  // Complicated transition logic: See note in _handleInodes()
  this._mapContainer.selectAll('div.leaf_rect_entering').transition()
      .duration(thisTreeMap._enterDuration).delay(
          this._firstTransition ? 0 : thisTreeMap._exitDuration +
              thisTreeMap._updateDuration)
      .attr('class', 'rect leaf_rect')
      .style('opacity', '1')
  this._mapContainer.selectAll('div.leaf_label_entering').transition()
      .duration(thisTreeMap._enterDuration).delay(
          this._firstTransition ? 0 : thisTreeMap._exitDuration +
              thisTreeMap._updateDuration)
      .attr('class', 'label leaf_label')
      .style('opacity', '1')
  this._mapContainer.selectAll('div.leaf_rect').transition()
      .duration(thisTreeMap._updateDuration).delay(thisTreeMap._exitDuration)
      .style('opacity', '1')
      .style('left', function(datum){ return datum.x; })
      .style('top', function(datum){ return datum.y; })
      .style('width', function(datum){ return datum.dx; })
      .style('height', function(datum){ return datum.dy; });
  this._mapContainer.selectAll('div.leaf_label').transition()
      .duration(thisTreeMap._updateDuration).delay(thisTreeMap._exitDuration)
      .style('opacity', '1')
      .style('visibility', function(datum) {
          return (datum.dx < 15 || datum.dy < 15) ? 'hidden' : 'visible';
      })
      .style('left', function(datum){ return datum.x; })
      .style('top', function(datum){ return datum.y; })
      .style('width', function(datum) { return datum.dx; })
      .style('height', function(datum) { return datum.dy; });
  var exit = this._mapContainer.selectAll('div.leaf')
      .data(leaves, function(datum) { return 'leaf-' + datum.id; })
      .exit();
  exit.selectAll('div.leaf_rect').transition()
      .duration(thisTreeMap._exitDuration)
      .style('opacity', 0);
  exit.selectAll('div.leaf_label').transition()
      .duration(thisTreeMap._exitDuration)
      .style('opacity', 0);
  exit.transition().delay(thisTreeMap._exitDuration + 1).remove();

  console.log(leaves.length + ' leaves layed out.');
  console.timeEnd('_handleLeaves');
}

D3SymbolTreeMap.prototype._makeSymbolBucketBackgroundImage = function(datum) {
  if (!(datum.t === undefined && datum.depth == this._currentMaxDepth)) {
    return 'none';
  }
  var text = '';
  var lastStop = 0;
  for (var x = 0; x < D3SymbolTreeMap._NM_SYMBOL_TYPES.length; x++) {
    symbol_type = D3SymbolTreeMap._NM_SYMBOL_TYPES.charAt(x);
    var stats = datum.symbol_stats[symbol_type];
    if (stats !== undefined) {
      if (text.length !== 0) {
        text += ', ';
      }
      var percent = 100 * (stats.size / datum.value);
      var nowStop = lastStop + percent;
      var tempcolor = D3SymbolTreeMap.getColorForType(symbol_type);
      var color = d3.rgb(tempcolor).toString();
      text += color + ' ' + lastStop + '%, ' + color + ' ' +
          nowStop + '%';
      lastStop = nowStop;
    }
  }
  return 'linear-gradient(' + (datum.dx > datum.dy ? 'to right' :
                               'to bottom') + ', ' + text + ')';
}

D3SymbolTreeMap.prototype.pathFor = function(datum) {
  if (datum.__path) return datum.__path;
  parts=[];
  node = datum;
  while (node) {
    if (node.k === 'p') { // path node
      if(node.n !== '/') parts.unshift(node.n);
    }
    node = node.parent;
  }
  datum.__path = '/' + parts.join('/');
  return datum.__path;
}

D3SymbolTreeMap.prototype._createHighlight = function(datum, selection) {
  var x = parseInt(selection.style('left'));
  var y = parseInt(selection.style('top'));
  var w = parseInt(selection.style('width'));
  var h = parseInt(selection.style('height'));
  datum.highlight = this._mapContainer.append('div')
      .attr('id', 'h-' + datum.id)
      .attr('class', 'highlight')
      .style('pointer-events', 'none')
      .style('-webkit-user-select', 'none')
      .style('z-index', '999999')
      .style('position', 'absolute')
      .style('top', y-2)
      .style('left', x-2)
      .style('width', w+4)
      .style('height', h+4)
      .style('margin', 0)
      .style('padding', 0)
      .style('border', '4px outset rgba(250,40,200,0.9)')
      .style('box-sizing', 'border-box')
      .style('opacity', 0.0);
}

D3SymbolTreeMap.prototype._showHighlight = function(datum, selection) {
  if (datum === this._currentRoot) return;
  if (datum.highlight === undefined) {
    this._createHighlight(datum, selection);
  }
  datum.highlight.transition().duration(200).style('opacity', 1.0);
}

D3SymbolTreeMap.prototype._hideHighlight = function(datum, selection) {
  if (datum.highlight === undefined) return;
  datum.highlight.transition().duration(750)
      .style('opacity', 0)
      .each('end', function(){
        if (datum.highlight) datum.highlight.remove();
        delete datum.highlight;
      });
}

D3SymbolTreeMap.prototype._createInfoBox = function() {
  return d3.select('body')
      .append('div')
      .attr('id', 'infobox')
      .style('z-index', '2147483647') // (2^31) - 1: Hopefully safe :)
      .style('position', 'absolute')
      .style('visibility', 'hidden')
      .style('background-color', 'rgba(255,255,255, 0.9)')
      .style('border', '1px solid black')
      .style('padding', '10px')
      .style('-webkit-user-select', 'none')
      .style('box-shadow', '3px 3px rgba(70,70,70,0.5)')
      .style('border-radius', '10px')
      .style('white-space', 'nowrap');
}

D3SymbolTreeMap.prototype._showInfoBox = function(datum) {
  this.infobox.text('');
  var numSymbols = 0;
  var sizeish = D3SymbolTreeMap._pretty(datum.value) + ' bytes (' +
      D3SymbolTreeMap._byteify(datum.value) + ')';
  if (datum.k === 'p' || datum.k === 'b') { // path or bucket
    if (datum.symbol_stats) { // can be empty if filters are applied
      for (var x = 0; x < D3SymbolTreeMap._NM_SYMBOL_TYPES.length; x++) {
        symbol_type = D3SymbolTreeMap._NM_SYMBOL_TYPES.charAt(x);
        var stats = datum.symbol_stats[symbol_type];
        if (stats !== undefined) numSymbols += stats.count;
      }
    }
  } else if (datum.k === 's') { // symbol
    numSymbols = 1;
  }

  if (datum.k === 'p' && !datum.lastPathElement) {
    this.infobox.append('div').text('Directory: ' + this.pathFor(datum))
    this.infobox.append('div').text('Size: ' + sizeish);
  } else {
    if (datum.k === 'p') { // path
      this.infobox.append('div').text('File: ' + this.pathFor(datum))
      this.infobox.append('div').text('Size: ' + sizeish);
    } else if (datum.k === 'b') { // bucket
      this.infobox.append('div').text('Symbol Bucket: ' +
          D3SymbolTreeMap._getSymbolDescription(datum.t));
      this.infobox.append('div').text('Count: ' + numSymbols);
      this.infobox.append('div').text('Size: ' + sizeish);
      this.infobox.append('div').text('Location: ' + this.pathFor(datum))
    } else if (datum.k === 's') { // symbol
      this.infobox.append('div').text('Symbol: ' + datum.n);
      this.infobox.append('div').text('Type: ' +
          D3SymbolTreeMap._getSymbolDescription(datum.t));
      this.infobox.append('div').text('Size: ' + sizeish);
      this.infobox.append('div').text('Location: ' + this.pathFor(datum))
    }
  }
  if (datum.k === 'p') {
    this.infobox.append('div')
        .text('Number of symbols: ' + D3SymbolTreeMap._pretty(numSymbols));
    if (datum.symbol_stats) { // can be empty if filters are applied
      var table = this.infobox.append('table')
          .attr('border', 1).append('tbody');
      var header = table.append('tr');
      header.append('th').text('Type');
      header.append('th').text('Count');
      header.append('th')
          .style('white-space', 'nowrap')
          .text('Total Size (Bytes)');
      for (var x = 0; x < D3SymbolTreeMap._NM_SYMBOL_TYPES.length; x++) {
        symbol_type = D3SymbolTreeMap._NM_SYMBOL_TYPES.charAt(x);
        var stats = datum.symbol_stats[symbol_type];
        if (stats !== undefined) {
          var tr = table.append('tr');
          tr.append('td')
              .style('white-space', 'nowrap')
              .text(D3SymbolTreeMap._getSymbolDescription(
                  symbol_type));
          tr.append('td').text(D3SymbolTreeMap._pretty(stats.count));
          tr.append('td').text(D3SymbolTreeMap._pretty(stats.size));
        }
      }
    }
  }
  this.infobox.style('visibility', 'visible');
}

D3SymbolTreeMap.prototype._hideInfoBox = function(datum) {
  this.infobox.style('visibility', 'hidden');
}

D3SymbolTreeMap.prototype._moveInfoBox = function(event) {
  var element = document.getElementById('infobox');
  var w = element.offsetWidth;
  var h = element.offsetHeight;
  var offsetLeft = 10;
  var offsetTop = 10;

  var rightLimit = window.innerWidth;
  var rightEdge = event.pageX + offsetLeft + w;
  if (rightEdge > rightLimit) {
    // Too close to screen edge, reflect around the cursor
    offsetLeft = -1 * (w + offsetLeft);
  }

  var bottomLimit = window.innerHeight;
  var bottomEdge = event.pageY + offsetTop + h;
  if (bottomEdge > bottomLimit) {
    // Too close ot screen edge, reflect around the cursor
    offsetTop = -1 * (h + offsetTop);
  }

  this.infobox.style('top', (event.pageY + offsetTop) + 'px')
      .style('left', (event.pageX + offsetLeft) + 'px');
}

D3SymbolTreeMap.prototype.biggestSymbols = function(maxRecords) {
  var result = undefined;
  var smallest = undefined;
  var sortFunction = function(a,b) {
    var result = b.value - a.value;
    if (result !== 0) return result; // sort by size
    var pathA = treemap.pathFor(a); // sort by path
    var pathB = treemap.pathFor(b);
    if (pathA > pathB) return 1;
    if (pathB > pathA) return -1;
    return a.n - b.n; // sort by symbol name
  };
  this.visitFromDisplayedRoot(function(datum) {
    if (datum.children) return; // ignore non-leaves
    if (!result) { // first element
      result = [datum];
      smallest = datum.value;
      return;
    }
    if (result.length < maxRecords) { // filling the array
      result.push(datum);
      return;
    }
    if (datum.value > smallest) { // array is already full
      result.push(datum);
      result.sort(sortFunction);
      result.pop(); // get rid of smallest element
      smallest = result[maxRecords - 1].value; // new threshold for entry
    }
  });
  result.sort(sortFunction);
  return result;
}

D3SymbolTreeMap.prototype.biggestPaths = function(maxRecords) {
  var result = undefined;
  var smallest = undefined;
  var sortFunction = function(a,b) {
    var result = b.value - a.value;
    if (result !== 0) return result; // sort by size
    var pathA = treemap.pathFor(a); // sort by path
    var pathB = treemap.pathFor(b);
    if (pathA > pathB) return 1;
    if (pathB > pathA) return -1;
    console.log('warning, multiple entries for the same path: ' + pathA);
    return 0; // should be impossible
  };
  this.visitFromDisplayedRoot(function(datum) {
    if (!datum.lastPathElement) return; // ignore non-files
    if (!result) { // first element
      result = [datum];
      smallest = datum.value;
      return;
    }
    if (result.length < maxRecords) { // filling the array
      result.push(datum);
      return;
    }
    if (datum.value > smallest) { // array is already full
      result.push(datum);
      result.sort(sortFunction);
      result.pop(); // get rid of smallest element
      smallest = result[maxRecords - 1].value; // new threshold for entry
    }
  });
  result.sort(sortFunction);
  return result;
}
