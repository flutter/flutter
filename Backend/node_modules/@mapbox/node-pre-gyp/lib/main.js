'use strict';

/**
 * Set the title.
 */

process.title = 'node-pre-gyp';

const node_pre_gyp = require('../');
const log = require('npmlog');

/**
 * Process and execute the selected commands.
 */

const prog = new node_pre_gyp.Run({ argv: process.argv });
let completed = false;

if (prog.todo.length === 0) {
  if (~process.argv.indexOf('-v') || ~process.argv.indexOf('--version')) {
    console.log('v%s', prog.version);
    process.exit(0);
  } else if (~process.argv.indexOf('-h') || ~process.argv.indexOf('--help')) {
    console.log('%s', prog.usage());
    process.exit(0);
  }
  console.log('%s', prog.usage());
  process.exit(1);
}

// if --no-color is passed
if (prog.opts && Object.hasOwnProperty.call(prog, 'color') && !prog.opts.color) {
  log.disableColor();
}

log.info('it worked if it ends with', 'ok');
log.verbose('cli', process.argv);
log.info('using', process.title + '@%s', prog.version);
log.info('using', 'node@%s | %s | %s', process.versions.node, process.platform, process.arch);


/**
 * Change dir if -C/--directory was passed.
 */

const dir = prog.opts.directory;
if (dir) {
  const fs = require('fs');
  try {
    const stat = fs.statSync(dir);
    if (stat.isDirectory()) {
      log.info('chdir', dir);
      process.chdir(dir);
    } else {
      log.warn('chdir', dir + ' is not a directory');
    }
  } catch (e) {
    if (e.code === 'ENOENT') {
      log.warn('chdir', dir + ' is not a directory');
    } else {
      log.warn('chdir', 'error during chdir() "%s"', e.message);
    }
  }
}

function run() {
  const command = prog.todo.shift();
  if (!command) {
    // done!
    completed = true;
    log.info('ok');
    return;
  }

  // set binary.host when appropriate. host determines the s3 target bucket.
  const target = prog.setBinaryHostProperty(command.name);
  if (target && ['install', 'publish', 'unpublish', 'info'].indexOf(command.name) >= 0) {
    log.info('using binary.host: ' + prog.package_json.binary.host);
  }

  prog.commands[command.name](command.args, function(err) {
    if (err) {
      log.error(command.name + ' error');
      log.error('stack', err.stack);
      errorMessage();
      log.error('not ok');
      console.log(err.message);
      return process.exit(1);
    }
    const args_array = [].slice.call(arguments, 1);
    if (args_array.length) {
      console.log.apply(console, args_array);
    }
    // now run the next command in the queue
    process.nextTick(run);
  });
}

process.on('exit', (code) => {
  if (!completed && !code) {
    log.error('Completion callback never invoked!');
    errorMessage();
    process.exit(6);
  }
});

process.on('uncaughtException', (err) => {
  log.error('UNCAUGHT EXCEPTION');
  log.error('stack', err.stack);
  errorMessage();
  process.exit(7);
});

function errorMessage() {
  // copied from npm's lib/util/error-handler.js
  const os = require('os');
  log.error('System', os.type() + ' ' + os.release());
  log.error('command', process.argv.map(JSON.stringify).join(' '));
  log.error('cwd', process.cwd());
  log.error('node -v', process.version);
  log.error(process.title + ' -v', 'v' + prog.package.version);
}

// start running the given commands!
run();
