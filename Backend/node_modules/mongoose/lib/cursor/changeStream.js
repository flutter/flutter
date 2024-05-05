'use strict';

/*!
 * Module dependencies.
 */

const EventEmitter = require('events').EventEmitter;

/*!
 * ignore
 */

const driverChangeStreamEvents = ['close', 'change', 'end', 'error', 'resumeTokenChanged'];

/*!
 * ignore
 */

class ChangeStream extends EventEmitter {
  constructor(changeStreamThunk, pipeline, options) {
    super();

    this.driverChangeStream = null;
    this.closed = false;
    this.bindedEvents = false;
    this.pipeline = pipeline;
    this.options = options;

    if (options && options.hydrate && !options.model) {
      throw new Error(
        'Cannot create change stream with `hydrate: true` ' +
        'unless calling `Model.watch()`'
      );
    }

    // This wrapper is necessary because of buffering.
    changeStreamThunk((err, driverChangeStream) => {
      if (err != null) {
        this.emit('error', err);
        return;
      }

      this.driverChangeStream = driverChangeStream;
      this.emit('ready');
    });
  }

  _bindEvents() {
    if (this.bindedEvents) {
      return;
    }

    this.bindedEvents = true;

    if (this.driverChangeStream == null) {
      this.once('ready', () => {
        this.driverChangeStream.on('close', () => {
          this.closed = true;
        });

        driverChangeStreamEvents.forEach(ev => {
          this.driverChangeStream.on(ev, data => {
            if (data != null && data.fullDocument != null && this.options && this.options.hydrate) {
              data.fullDocument = this.options.model.hydrate(data.fullDocument);
            }
            this.emit(ev, data);
          });
        });
      });

      return;
    }

    this.driverChangeStream.on('close', () => {
      this.closed = true;
    });

    driverChangeStreamEvents.forEach(ev => {
      this.driverChangeStream.on(ev, data => {
        if (data != null && data.fullDocument != null && this.options && this.options.hydrate) {
          data.fullDocument = this.options.model.hydrate(data.fullDocument);
        }
        this.emit(ev, data);
      });
    });
  }

  hasNext(cb) {
    return this.driverChangeStream.hasNext(cb);
  }

  next(cb) {
    if (this.options && this.options.hydrate) {
      if (cb != null) {
        const originalCb = cb;
        cb = (err, data) => {
          if (err != null) {
            return originalCb(err);
          }
          if (data.fullDocument != null) {
            data.fullDocument = this.options.model.hydrate(data.fullDocument);
          }
          return originalCb(null, data);
        };
      }

      let maybePromise = this.driverChangeStream.next(cb);
      if (maybePromise && typeof maybePromise.then === 'function') {
        maybePromise = maybePromise.then(data => {
          if (data.fullDocument != null) {
            data.fullDocument = this.options.model.hydrate(data.fullDocument);
          }
          return data;
        });
      }
      return maybePromise;
    }

    return this.driverChangeStream.next(cb);
  }

  addListener(event, handler) {
    this._bindEvents();
    return super.addListener(event, handler);
  }

  on(event, handler) {
    this._bindEvents();
    return super.on(event, handler);
  }

  once(event, handler) {
    this._bindEvents();
    return super.once(event, handler);
  }

  _queue(cb) {
    this.once('ready', () => cb());
  }

  close() {
    this.closed = true;
    if (this.driverChangeStream) {
      this.driverChangeStream.close();
    }
  }
}

/*!
 * ignore
 */

module.exports = ChangeStream;
