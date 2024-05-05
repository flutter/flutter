'use strict'
const { Minipass } = require('minipass')
const normPath = require('./normalize-windows-path.js')

const SLURP = Symbol('slurp')
module.exports = class ReadEntry extends Minipass {
  constructor (header, ex, gex) {
    super()
    // read entries always start life paused.  this is to avoid the
    // situation where Minipass's auto-ending empty streams results
    // in an entry ending before we're ready for it.
    this.pause()
    this.extended = ex
    this.globalExtended = gex
    this.header = header
    this.startBlockSize = 512 * Math.ceil(header.size / 512)
    this.blockRemain = this.startBlockSize
    this.remain = header.size
    this.type = header.type
    this.meta = false
    this.ignore = false
    switch (this.type) {
      case 'File':
      case 'OldFile':
      case 'Link':
      case 'SymbolicLink':
      case 'CharacterDevice':
      case 'BlockDevice':
      case 'Directory':
      case 'FIFO':
      case 'ContiguousFile':
      case 'GNUDumpDir':
        break

      case 'NextFileHasLongLinkpath':
      case 'NextFileHasLongPath':
      case 'OldGnuLongPath':
      case 'GlobalExtendedHeader':
      case 'ExtendedHeader':
      case 'OldExtendedHeader':
        this.meta = true
        break

      // NOTE: gnutar and bsdtar treat unrecognized types as 'File'
      // it may be worth doing the same, but with a warning.
      default:
        this.ignore = true
    }

    this.path = normPath(header.path)
    this.mode = header.mode
    if (this.mode) {
      this.mode = this.mode & 0o7777
    }
    this.uid = header.uid
    this.gid = header.gid
    this.uname = header.uname
    this.gname = header.gname
    this.size = header.size
    this.mtime = header.mtime
    this.atime = header.atime
    this.ctime = header.ctime
    this.linkpath = normPath(header.linkpath)
    this.uname = header.uname
    this.gname = header.gname

    if (ex) {
      this[SLURP](ex)
    }
    if (gex) {
      this[SLURP](gex, true)
    }
  }

  write (data) {
    const writeLen = data.length
    if (writeLen > this.blockRemain) {
      throw new Error('writing more to entry than is appropriate')
    }

    const r = this.remain
    const br = this.blockRemain
    this.remain = Math.max(0, r - writeLen)
    this.blockRemain = Math.max(0, br - writeLen)
    if (this.ignore) {
      return true
    }

    if (r >= writeLen) {
      return super.write(data)
    }

    // r < writeLen
    return super.write(data.slice(0, r))
  }

  [SLURP] (ex, global) {
    for (const k in ex) {
      // we slurp in everything except for the path attribute in
      // a global extended header, because that's weird.
      if (ex[k] !== null && ex[k] !== undefined &&
          !(global && k === 'path')) {
        this[k] = k === 'path' || k === 'linkpath' ? normPath(ex[k]) : ex[k]
      }
    }
  }
}
