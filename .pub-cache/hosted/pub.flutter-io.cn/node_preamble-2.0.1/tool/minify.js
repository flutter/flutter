const fs = require("fs");
const path = require("path");

const Terser = require("terser");

const LIB_DIR = path.join(__dirname, "..", "lib");

const PATH = path.join(LIB_DIR, "preamble.js");

const MIN_PATH = path.join(LIB_DIR, "preamble.min.js");
const DART_PATH = path.join(LIB_DIR, "preamble.dart");

const preamble = fs.readFileSync(PATH).toString();

const { code: minified, error } = Terser.minify(preamble, {
  // Needed for Webpack require override.
  compress: {
    conditionals: false
  }
});

if (error) {
  throw error;
}

fs.writeFileSync(MIN_PATH, minified);

fs.writeFileSync(DART_PATH, `library node_preamble;

final _minified = r\"""${minified}\""";

final _normal = r\"""
${preamble}\""";

/// Returns the text of the preamble.
///
/// If [minified] is true, returns the minified version rather than the
/// human-readable version.
String getPreamble({bool minified: false, List<String> additionalGlobals: const []}) =>
    (minified ? _minified : _normal) +
    (additionalGlobals.map((global) => "self.\$global=\$global;").join());
`);
