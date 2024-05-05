{
  "name": "are-we-there-yet",
  "version": "2.0.0",
  "description": "Keep track of the overall completion of many disparate processes",
  "main": "lib/index.js",
  "scripts": {
    "test": "tap",
    "npmclilint": "npmcli-lint",
    "lint": "eslint '**/*.js'",
    "lintfix": "npm run lint -- --fix",
    "posttest": "npm run lint",
    "postsnap": "npm run lintfix --",
    "preversion": "npm test",
    "postversion": "npm publish",
    "prepublishOnly": "git push origin --follow-tags",
    "snap": "tap"
  },
  "repository": {
    "type": "git",
    "url": "https://github.com/npm/are-we-there-yet.git"
  },
  "author": "GitHub Inc.",
  "license": "ISC",
  "bugs": {
    "url": "https://github.com/npm/are-we-there-yet/issues"
  },
  "homepage": "https://github.com/npm/are-we-there-yet",
  "devDependencies": {
    "@npmcli/eslint-config": "^1.0.0",
    "@npmcli/template-oss": "^1.0.2",
    "eslint": "^7.32.0",
    "eslint-plugin-node": "^11.1.0",
    "tap": "^15.0.9"
  },
  "dependencies": {
    "delegates": "^1.0.0",
    "readable-stream": "^3.6.0"
  },
  "files": [
    "bin",
    "lib"
  ],
  "engines": {
    "node": ">=10"
  },
  "tap": {
    "branches": 68,
    "statements": 92,
    "functions": 86,
    "lines": 92
  },
  "templateVersion": "1.0.2"
}
