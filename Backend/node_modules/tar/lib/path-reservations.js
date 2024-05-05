// A path exclusive reservation system
// reserve([list, of, paths], fn)
// When the fn is first in line for all its paths, it
// is called with a cb that clears the reservation.
//
// Used by async unpack to avoid clobbering paths in use,
// while still allowing maximal safe parallelization.

const assert = require('assert')
const normalize = require('./normalize-unicode.js')
const stripSlashes = require('./strip-trailing-slashes.js')
const { join } = require('path')

const platform = process.env.TESTING_TAR_FAKE_PLATFORM || process.platform
const isWindows = platform === 'win32'

module.exports = () => {
  // path => [function or Set]
  // A Set object means a directory reservation
  // A fn is a direct reservation on that path
  const queues = new Map()

  // fn => {paths:[path,...], dirs:[path, ...]}
  const reservations = new Map()

  // return a set of parent dirs for a given path
  // '/a/b/c/d' -> ['/', '/a', '/a/b', '/a/b/c', '/a/b/c/d']
  const getDirs = path => {
    const dirs = path.split('/').slice(0, -1).reduce((set, path) => {
      if (set.length) {
        path = join(set[set.length - 1], path)
      }
      set.push(path || '/')
      return set
    }, [])
    return dirs
  }

  // functions currently running
  const running = new Set()

  // return the queues for each path the function cares about
  // fn => {paths, dirs}
  const getQueues = fn => {
    const res = reservations.get(fn)
    /* istanbul ignore if - unpossible */
    if (!res) {
      throw new Error('function does not have any path reservations')
    }
    return {
      paths: res.paths.map(path => queues.get(path)),
      dirs: [...res.dirs].map(path => queues.get(path)),
    }
  }

  // check if fn is first in line for all its paths, and is
  // included in the first set for all its dir queues
  const check = fn => {
    const { paths, dirs } = getQueues(fn)
    return paths.every(q => q[0] === fn) &&
      dirs.every(q => q[0] instanceof Set && q[0].has(fn))
  }

  // run the function if it's first in line and not already running
  const run = fn => {
    if (running.has(fn) || !check(fn)) {
      return false
    }
    running.add(fn)
    fn(() => clear(fn))
    return true
  }

  const clear = fn => {
    if (!running.has(fn)) {
      return false
    }

    const { paths, dirs } = reservations.get(fn)
    const next = new Set()

    paths.forEach(path => {
      const q = queues.get(path)
      assert.equal(q[0], fn)
      if (q.length === 1) {
        queues.delete(path)
      } else {
        q.shift()
        if (typeof q[0] === 'function') {
          next.add(q[0])
        } else {
          q[0].forEach(fn => next.add(fn))
        }
      }
    })

    dirs.forEach(dir => {
      const q = queues.get(dir)
      assert(q[0] instanceof Set)
      if (q[0].size === 1 && q.length === 1) {
        queues.delete(dir)
      } else if (q[0].size === 1) {
        q.shift()

        // must be a function or else the Set would've been reused
        next.add(q[0])
      } else {
        q[0].delete(fn)
      }
    })
    running.delete(fn)

    next.forEach(fn => run(fn))
    return true
  }

  const reserve = (paths, fn) => {
    // collide on matches across case and unicode normalization
    // On windows, thanks to the magic of 8.3 shortnames, it is fundamentally
    // impossible to determine whether two paths refer to the same thing on
    // disk, without asking the kernel for a shortname.
    // So, we just pretend that every path matches every other path here,
    // effectively removing all parallelization on windows.
    paths = isWindows ? ['win32 parallelization disabled'] : paths.map(p => {
      // don't need normPath, because we skip this entirely for windows
      return stripSlashes(join(normalize(p))).toLowerCase()
    })

    const dirs = new Set(
      paths.map(path => getDirs(path)).reduce((a, b) => a.concat(b))
    )
    reservations.set(fn, { dirs, paths })
    paths.forEach(path => {
      const q = queues.get(path)
      if (!q) {
        queues.set(path, [fn])
      } else {
        q.push(fn)
      }
    })
    dirs.forEach(dir => {
      const q = queues.get(dir)
      if (!q) {
        queues.set(dir, [new Set([fn])])
      } else if (q[q.length - 1] instanceof Set) {
        q[q.length - 1].add(fn)
      } else {
        q.push(new Set([fn]))
      }
    })

    return run(fn)
  }

  return { check, reserve }
}
