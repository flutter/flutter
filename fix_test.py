import re

with open('packages/flutter_tools/lib/src/commands/test.dart', 'r') as f:
    text = f.read()

# Replacement 1
text = re.sub(
    r"<<<<<<< HEAD\s+fs\.directory\(fs\.path\.join\('build', 'unit_test_assets'\)\),\s*=======\s+globals\.fs\.directory\(\s*globals\.fs\.path\.join\(getBuildDirectory\(globals\.config, globals\.fs\), 'unit_test_assets'\),\s*\),\s*>>>>>>> upstream/master",
    r"fs.directory(\n          fs.path.join(getBuildDirectory(_toolContext.config, fs), 'unit_test_assets'),\n        ),",
    text
)

# Replacement 2
text = re.sub(
    r"<<<<<<< HEAD\s+final File cachedFlavorFile = fs\.file\(fs\.path\.join\('build', 'test_cache', 'flavor\.txt'\)\);\s*=======\s+final File cachedFlavorFile = globals\.fs\.file\(\s*globals\.fs\.path\.join\(\s*getBuildDirectory\(globals\.config, globals\.fs\),\s*'test_cache',\s*'flavor\.txt',\s*\),\s*\);\s*>>>>>>> upstream/master",
    r"final File cachedFlavorFile = fs.file(\n        fs.path.join(\n          getBuildDirectory(_toolContext.config, fs),\n          'test_cache',\n          'flavor.txt',\n        ),\n      );",
    text
)

# Replacement 3
text = re.sub(
    r"<<<<<<< HEAD\s+final File manifest = fs\.file\(fs\.path\.join\('build', 'unit_test_assets', 'AssetManifest\.bin'\)\);\s*=======\s+final File manifest = globals\.fs\.file\(\s*globals\.fs\.path\.join\(\s*getBuildDirectory\(globals\.config, globals\.fs\),\s*'unit_test_assets',\s*'AssetManifest\.bin',\s*\),\s*\);\s*>>>>>>> upstream/master",
    r"final File manifest = fs.file(\n      fs.path.join(\n        getBuildDirectory(_toolContext.config, fs),\n        'unit_test_assets',\n        'AssetManifest.bin',\n      ),\n    );",
    text
)

# And another flavor file conflict
text = re.sub(
    r"<<<<<<< HEAD\s+final File cachedFlavorFile = fs\.file\(fs\.path\.join\('build', 'test_cache', 'flavor\.txt'\)\);\s*=======\s+final File cachedFlavorFile = globals\.fs\.file\(\s*globals\.fs\.path\.join\(\s*getBuildDirectory\(globals\.config, globals\.fs\),\s*'test_cache',\s*'flavor\.txt',\s*\),\s*\);\s*>>>>>>> upstream/master",
    r"final File cachedFlavorFile = fs.file(\n      fs.path.join(\n        getBuildDirectory(_toolContext.config, fs),\n        'test_cache',\n        'flavor.txt',\n      ),\n    );",
    text
)

with open('packages/flutter_tools/lib/src/commands/test.dart', 'w') as f:
    f.write(text)
