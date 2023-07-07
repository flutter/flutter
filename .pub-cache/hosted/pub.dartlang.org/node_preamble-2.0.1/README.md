node_preamble.dart
===

A simple package for a better dart2js preamble for running on node.js. This
package exists for ease of use if incorporating into your build system.

This preamble is suggested for use over d8.js, and provides many improvements
and bug fixes, as it uses node.js's timer functions and event loop over the
custom one implemented in d8.js.

The JavaScript file can be found at lib/preamble.js.

You can also get the preamble via Dart, like in the following example.

```
import "package:node_preamble/preamble.dart" as preamble;

main() {
  print(preamble.getPreamble());
}
```

Credit goes to the Dart team for creating Dart, dart2js, and the original
preamble which this is derived from.

## Contributing

The only file that we directly modify is `preamble.js`. After that, to reflect your changes in
both `preamble.dart` and `preamble.min.js`, run `npm install && npm run minify`

### Testing

`node_preamble` tries to support the following platforms. Before a `pub` release, the following environments should be manually tested with a sample `dart2js` output:

- `node`
- Webpack (easy way is with `create-react-app`)
- Electron Fiddle (w/ and w/o node integration)
