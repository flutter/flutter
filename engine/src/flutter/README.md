Sky
===

Sky is an experiment in building a UI framework for Mojo.  The approach we're
exploring is to create a layered framework based around a retained hierarchy of
semantic elements.  We're experimenting with different ideas and exploring
various approaches, many of which won't work and will need to be discarded, but,
if we're lucky, some of which might turn out to be useful.

Sky has three layers, each of which also adds progressively more opinion.  At
the lowest layer, Sky contains a rendering engine that parses markup, executes
script, and applies styling information.  Layered above the engine is a
collection of components that define the interactive behavior of a suite of
widgets, such as input fields, buttons, and menus.  Above the widget layer is a
theme layer that gives each widget a concrete visual and interactive design.

Elements
--------

The Sky engine contains [a handful of primitive elements](specs/markup.md) and the tools with which
to create custom elements.  The following elements are built into the engine:

 - ``script``: Executes script
 - ``style``: Defines style rules
 - ``import``: Loads a module
 - ``iframe``: Embeds another Mojo application
 - ``template``: Captures descendants for use as a template
 - ``content``: Visually projects descendents of the shadow host
 - ``shadow``: Visually projects older shadow roots of the shadow host
 - ``img``: Displays an image
 - ``a``: Links to another Mojo application
 - ``title``: Briefly describes the current application state to the user
 - ``t``: Preserve whitespace (by default, whitespace nodes are dropped)

### Additional Elements ###

In addition to the built-in elements, frameworks and applications can define
custom elements.  The Sky framework contains a number of general-purpose
elements, including ``input``, ``button``, ``menu``, ``toolbar``, ``video``, and
``dialog``.  However, developers are free to implement their own input fields,
buttons, menus, toolbars, videos, or dialogs with access to all the same engine
features as the frame because the framework does not occupy a privileged
position in Sky.

### Custom Layout ###

TODO: Describe the approach for customizing layout.

### Custom Painting ###

TODO: Describe the approach for customizing painting.

Modules
-------

Sky applications consist of a collection of modules.  Each module can describe
its dependencies, register custom elements, and export objects for use in other
modules.

Below is a sketch of a typical module.  The first ``import`` element imports the
Sky framework, which defines the ``sky-element`` element.  This module then uses
``sky-element`` to define another element, ``my-element``. The second ``import``
element imports another module and gives it the name ``foo`` within this module.
For example, the ``AnnualReport`` constructor uses the ``BalanceSheet`` class
exported by that module.

```html
SKY MODULE
<import src=”/sky/framework” />
<import src=”/another/module.sky” as=”foo” />
<sky-element name=”my-element”>
class extends SkyElement {
  constructor () {
    this.addEventListener('click', (event) => this.updateTime());
    this.shadowRoot.appendChild('Click to show the time');
  }
  updateTime() {
    this.shadowRoot.firstChild.replaceWith(new Date());
  }
}
</sky-element>
<script>
class AnnualReport {
  constructor(bar) {
    this.sheet = new foo.BalanceSheet(bar);
  }
  frobinate() {
    this.sheet.balance();
  }
}

function mult(x, y) {
  return x * y;
}

function multiplyByTwo(x) {
  return mult(x, 2);
}

module.exports = {
  AnnualReport: AnnualReport,
  multiplyByTwo: multiplyByTwo,
};
</script>
```

The script definitions are local to each module and cannot be referenced by
other modules unless exported.  For example, the ``mult`` function is private to
this module whereas the ``multiplyByTwo`` function can be used by other modules
because it is exported.  Similarly, this module exports the ``AnnualReport``
class.

Services
--------

Sky applications can access Mojo services and can provide services to other Mojo
applications.  For example, Sky applications can access the network using Mojo's
``network_service``.  Typically, however, Sky applications access services via
frameworks that provide idiomatic interfaces to the underlying Mojo services.
These idiomatic interfaces are layered on top of the underlying Mojo service,
and developers are free to use the underlying service directly.

As an example, the following is a sketch of a module that wraps Mojo's
``network_service`` in a simpler functional interface:

```html
SKY MODULE
<import src=”mojo://shell” as=”shell” />
<import src="/mojo/network/network_service.mojom.sky" as="net" />
<import src="/mojo/network/url_loader.mojom.sky" as="loader" />
<script>
module.exports = function fetch(url) {
  return new Promise(function(resolve, reject) {
    var networkService = shell.connectToService(
        "mojo://network_service", net.NetworkService);
    var request = new loader.URLRequest({
        url: url, method: "GET", auto_follow_redirects: true});
    var urlLoader = networkService.createURLLoader();
    urlLoader.start(request).then(function(response) {
      if (response.status_code == 200)
        resolve(response.body);
      else
        reject(response);
    });
  };
};
</script>
```

Notice that the ``shell`` module is built-in and provides access to the
underlying Mojo fabric but the ``net`` and ``loader`` modules run inside Sky and
encode and decode messages sent over Mojo pipes.

Specifications
--------------

We're documenting Sky with a [set of technical specifications](specs) that
define precisely the behavior of the engine.  Currently both the implementation
and the specification are in flux, but hopefully they'll converge over time.

Contributing
------------

Instructions for building and testing Sky are contained in [HACKING.md](HACKING.md). For
coordination, we use the ``#mojo`` IRC channel on
[Freenode](https://freenode.net/).
