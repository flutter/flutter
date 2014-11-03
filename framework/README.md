SkyElement
===

SkyElement is the framework for creating...yup...Sky Elements. It take heavy
inspriation from [Polymer](www.polymer-project.org) and isn't very fully
featured...yet

Declaring an element
--------
```HTML
<import src="../path/to/sky-element.sky" as="SkyElement" />
<template>
  <my-other-element>Hello, {{ place }}</my-other-element>
</template>
<script>
// SkyElement takes a single object as it's only parameter
SkyElement({
  name: 'my-element', // required. The element's tag-name
  attached: function() {
    this.place = 'World';
  }, // optional
  detached: function() {}, // optional
  attributeChanged: function(attrName, newValue, oldValue) {} // optional
});
</script>
```

Note that an element's declared ShadowDOM is the previous `<template>`
element to the `<script>` element which defines the element.

Databinding
--------
SkyElement's databinding support is derived from Polymer's. At the moment,
there are some key differences:

There is not yet support for
 * Declarative event handlers
 * Inline expressions
 * Self-observation (e.g. `fooChanged()` gets invoked when `this.foo` is changed)
 * Computed properties (e.g. the computed block)
 * Conditional attributes (e.g. `<my-foo checked?="{{ val }}"`)

 Also, because there are so few built-in elements in Sky, the default behavior
 of HTMLElement with bindings is to assign to the property. e.g.

 ```HTML
 <my-foo bar="{{ bas }}">
 ```

 Will not `setAttribute` on the `my-foo`, instead it will assign to the `bar`
 property of `my-foo`. There are two exceptions to this: `class` & `style` --
 those still`setAttribute`.
