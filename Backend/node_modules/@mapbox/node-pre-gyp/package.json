{
  "name": "@mapbox/node-pre-gyp",
  "description": "Node.js native addon binary install tool",
  "version": "1.0.11",
  "keywords": [
    "native",
    "addon",
    "module",
    "c",
    "c++",
    "bindings",
    "binary"
  ],
  "license": "BSD-3-Clause",
  "author": "Dane Springmeyer <dane@mapbox.com>",
  "repository": {
    "type": "git",
    "url": "git://github.com/mapbox/node-pre-gyp.git"
  },
  "bin": "./bin/node-pre-gyp",
  "main": "./lib/node-pre-gyp.js",
  "dependencies": {
    "detect-libc": "^2.0.0",
    "https-proxy-agent": "^5.0.0",
    "make-dir": "^3.1.0",
    "node-fetch": "^2.6.7",
    "nopt": "^5.0.0",
    "npmlog": "^5.0.1",
    "rimraf": "^3.0.2",
    "semver": "^7.3.5",
    "tar": "^6.1.11"
  },
  "devDependencies": {
    "@mapbox/cloudfriend": "^5.1.0",
    "@mapbox/eslint-config-mapbox": "^3.0.0",
    "aws-sdk": "^2.1087.0",
    "codecov": "^3.8.3",
    "eslint": "^7.32.0",
    "eslint-plugin-node": "^11.1.0",
    "mock-aws-s3": "^4.0.2",
    "nock": "^12.0.3",
    "node-addon-api": "^4.3.0",
    "nyc": "^15.1.0",
    "tape": "^5.5.2",
    "tar-fs": "^2.1.1"
  },
  "nyc": {
    "all": true,
    "skip-full": false,
    "exclude": [
      "test/**"
    ]
  },
  "scripts": {
    "coverage": "nyc --all --include index.js --include lib/ npm test",
    "upload-coverage": "nyc report --reporter json && codecov --clear --flags=unit --file=./coverage/coverage-final.json",
    "lint": "eslint bin/node-pre-gyp lib/*js lib/util/*js test/*js scripts/*js",
    "fix": "npm run lint -- --fix",
    "update-crosswalk": "node scripts/abi_crosswalk.js",
    "test": "tape test/*test.js"
  }
}
