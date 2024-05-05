'use strict'
// wrapper around mkdirp for tar's needs.

// TODO: This should probably be a class, not functionally
// passing around state in a gazillion args.

const mkdirp = require('mkdirp')
const fs = require('fs')
const path = require('path')
const chownr = require('chownr')
const normPath = require('./normalize-windows-path.js')

class SymlinkError extends Error {
  constructor (symlink, path) {
    super('Cannot extract through symbolic link')
    this.path = path
    this.symlink = symlink
  }

  get name () {
    return 'SylinkError'
  }
}

class CwdError extends Error {
  constructor (path, code) {
    super(code + ': Cannot cd into \'' + path + '\'')
    this.path = path
    this.code = code
  }

  get name () {
    return 'CwdError'
  }
}

const cGet = (cache, key) => cache.get(normPath(key))
const cSet = (cache, key, val) => cache.set(normPath(key), val)

const checkCwd = (dir, cb) => {
  fs.stat(dir, (er, st) => {
    if (er || !st.isDirectory()) {
      er = new CwdError(dir, er && er.code || 'ENOTDIR')
    }
    cb(er)
  })
}

module.exports = (dir, opt, cb) => {
  dir = normPath(dir)

  // if there's any overlap between mask and mode,
  // then we'll need an explicit chmod
  const umask = opt.umask
  const mode = opt.mode | 0o0700
  const needChmod = (mode & umask) !== 0

  const uid = opt.uid
  const gid = opt.gid
  const doChown = typeof uid === 'number' &&
    typeof gid === 'number' &&
    (uid !== opt.processUid || gid !== opt.processGid)

  const preserve = opt.preserve
  const unlink = opt.unlink
  const cache = opt.cache
  const cwd = normPath(opt.cwd)

  const done = (er, created) => {
    if (er) {
      cb(er)
    } else {
      cSet(cache, dir, true)
      if (created && doChown) {
        chownr(created, uid, gid, er => done(er))
      } else if (needChmod) {
        fs.chmod(dir, mode, cb)
      } else {
        cb()
      }
    }
  }

  if (cache && cGet(cache, dir) === true) {
    return done()
  }

  if (dir === cwd) {
    return checkCwd(dir, done)
  }

  if (preserve) {
    return mkdirp(dir, { mode }).then(made => done(null, made), done)
  }

  const sub = normPath(path.relative(cwd, dir))
  const parts = sub.split('/')
  mkdir_(cwd, parts, mode, cache, unlink, cwd, null, done)
}

const mkdir_ = (base, parts, mode, cache, unlink, cwd, created, cb) => {
  if (!parts.length) {
    return cb(null, created)
  }
  const p = parts.shift()
  const part = normPath(path.resolve(base + '/' + p))
  if (cGet(cache, part)) {
    return mkdir_(part, parts, mode, cache, unlink, cwd, created, cb)
  }
  fs.mkdir(part, mode, onmkdir(part, parts, mode, cache, unlink, cwd, created, cb))
}

const onmkdir = (part, parts, mode, cache, unlink, cwd, created, cb) => er => {
  if (er) {
    fs.lstat(part, (statEr, st) => {
      if (statEr) {
        statEr.path = statEr.path && normPath(statEr.path)
        cb(statEr)
      } else if (st.isDirectory()) {
        mkdir_(part, parts, mode, cache, unlink, cwd, created, cb)
      } else if (unlink) {
        fs.unlink(part, er => {
          if (er) {
            return cb(er)
          }
          fs.mkdir(part, mode, onmkdir(part, parts, mode, cache, unlink, cwd, created, cb))
        })
      } else if (st.isSymbolicLink()) {
        return cb(new SymlinkError(part, part + '/' + parts.join('/')))
      } else {
        cb(er)
      }
    })
  } else {
    created = created || part
    mkdir_(part, parts, mode, cache, unlink, cwd, created, cb)
  }
}

const checkCwdSync = dir => {
  let ok = false
  let code = 'ENOTDIR'
  try {
    ok = fs.statSync(dir).isDirectory()
  } catch (er) {
    code = er.code
  } finally {
    if (!ok) {
      throw new CwdError(dir, code)
    }
  }
}

module.exports.sync = (dir, opt) => {
  dir = normPath(dir)
  // if there's any overlap between mask and mode,
  // then we'll need an explicit chmod
  const umask = opt.umask
  const mode = opt.mode | 0o0700
  const needChmod = (mode & umask) !== 0

  const uid = opt.uid
  const gid = opt.gid
  const doChown = typeof uid === 'number' &&
    typeof gid === 'number' &&
    (uid !== opt.processUid || gid !== opt.processGid)

  const preserve = opt.preserve
  const unlink = opt.unlink
  const cache = opt.cache
  const cwd = normPath(opt.cwd)

  const done = (created) => {
    cSet(cache, dir, true)
    if (created && doChown) {
      chownr.sync(created, uid, gid)
    }
    if (needChmod) {
      fs.chmodSync(dir, mode)
    }
  }

  if (cache && cGet(cache, dir) === true) {
    return done()
  }

  if (dir === cwd) {
    checkCwdSync(cwd)
    return done()
  }

  if (preserve) {
    return done(mkdirp.sync(dir, mode))
  }

  const sub = normPath(path.relative(cwd, dir))
  const parts = sub.split('/')
  let created = null
  for (let p = parts.shift(), part = cwd;
    p && (part += '/' + p);
    p = parts.shift()) {
    part = normPath(path.resolve(part))
    if (cGet(cache, part)) {
      continue
    }

    try {
      fs.mkdirSync(part, mode)
      created = created || part
      cSet(cache, part, true)
    } catch (er) {
      const st = fs.lstatSync(part)
      if (st.isDirectory()) {
        cSet(cache, part, true)
        continue
      } else if (unlink) {
        fs.unlinkSync(part)
        fs.mkdirSync(part, mode)
        created = created || part
        cSet(cache, part, true)
        continue
      } else if (st.isSymbolicLink()) {
        return new SymlinkError(part, part + '/' + parts.join('/'))
      }
    }
  }

  return done(created)
}
