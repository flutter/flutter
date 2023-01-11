/**
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 * @format
 */

'use strict';

import type {PlatformConfig} from '../AnimatedPlatformConfig';
import type AnimatedInterpolation from '../nodes/AnimatedInterpolation';
import type AnimatedValue from '../nodes/AnimatedValue';
import type AnimatedValueXY from '../nodes/AnimatedValueXY';
import type {AnimationConfig, EndCallback} from './Animation';

import NativeAnimatedHelper from '../NativeAnimatedHelper';
import AnimatedColor from '../nodes/AnimatedColor';
import * as SpringConfig from '../SpringConfig';
import Animation from './Animation';
import invariant from 'invariant';

export type SpringAnimationConfig = {
  ...AnimationConfig,
  toValue:
    | number
    | AnimatedValue
    | {
        x: number,
        y: number,
        ...
      }
    | AnimatedValueXY
    | {
        r: number,
        g: number,
        b: number,
        a: number,
        ...
      }
    | AnimatedColor
    | AnimatedInterpolation<number>,
  overshootClamping?: boolean,
  restDisplacementThreshold?: number,
  restSpeedThreshold?: number,
  velocity?:
    | number
    | {
        x: number,
        y: number,
        ...
      },
  bounciness?: number,
  speed?: number,
  tension?: number,
  friction?: number,
  stiffness?: number,
  damping?: number,
  mass?: number,
  delay?: number,
};

export type SpringAnimationConfigSingle = {
  ...AnimationConfig,
  toValue: number,
  overshootClamping?: boolean,
  restDisplacementThreshold?: number,
  restSpeedThreshold?: number,
  velocity?: number,
  bounciness?: number,
  speed?: number,
  tension?: number,
  friction?: number,
  stiffness?: number,
  damping?: number,
  mass?: number,
  delay?: number,
};

export default class SpringAnimation extends Animation {
  _overshootClamping: boolean;
  _restDisplacementThreshold: number;
  _restSpeedThreshold: number;
  _lastVelocity: number;
  _startPosition: number;
  _lastPosition: number;
  _fromValue: number;
  _toValue: number;
  _stiffness: number;
  _damping: number;
  _mass: number;
  _initialVelocity: number;
  _delay: number;
  _timeout: any;
  _startTime: number;
  _lastTime: number;
  _frameTime: number;
  _onUpdate: (value: number) => void;
  _animationFrame: any;
  _useNativeDriver: boolean;
  _platformConfig: ?PlatformConfig;

  constructor(config: SpringAnimationConfigSingle) {
    super();

    this._overshootClamping = config.overshootClamping ?? false;
    this._restDisplacementThreshold = config.restDisplacementThreshold ?? 0.001;
    this._restSpeedThreshold = config.restSpeedThreshold ?? 0.001;
    this._initialVelocity = config.velocity ?? 0;
    this._lastVelocity = config.velocity ?? 0;
    this._toValue = config.toValue;
    this._delay = config.delay ?? 0;
    this._useNativeDriver = NativeAnimatedHelper.shouldUseNativeDriver(config);
    this._platformConfig = config.platformConfig;
    this.__isInteraction = config.isInteraction ?? !this._useNativeDriver;
    this.__iterations = config.iterations ?? 1;

    if (
      config.stiffness !== undefined ||
      config.damping !== undefined ||
      config.mass !== undefined
    ) {
      invariant(
        config.bounciness === undefined &&
          config.speed === undefined &&
          config.tension === undefined &&
          config.friction === undefined,
        'You can define one of bounciness/speed, tension/friction, or stiffness/damping/mass, but not more than one',
      );
      this._stiffness = config.stiffness ?? 100;
      this._damping = config.damping ?? 10;
      this._mass = config.mass ?? 1;
    } else if (config.bounciness !== undefined || config.speed !== undefined) {
      // Convert the origami bounciness/speed values to stiffness/damping
      // We assume mass is 1.
      invariant(
        config.tension === undefined &&
          config.friction === undefined &&
          config.stiffness === undefined &&
          config.damping === undefined &&
          config.mass === undefined,
        'You can define one of bounciness/speed, tension/friction, or stiffness/damping/mass, but not more than one',
      );
      const springConfig = SpringConfig.fromBouncinessAndSpeed(
        config.bounciness ?? 8,
        config.speed ?? 12,
      );
      this._stiffness = springConfig.stiffness;
      this._damping = springConfig.damping;
      this._mass = 1;
    } else {
      // Convert the origami tension/friction values to stiffness/damping
      // We assume mass is 1.
      const springConfig = SpringConfig.fromOrigamiTensionAndFriction(
        config.tension ?? 40,
        config.friction ?? 7,
      );
      this._stiffness = springConfig.stiffness;
      this._damping = springConfig.damping;
      this._mass = 1;
    }

    invariant(this._stiffness > 0, 'Stiffness value must be greater than 0');
    invariant(this._damping > 0, 'Damping value must be greater than 0');
    invariant(this._mass > 0, 'Mass value must be greater than 0');
  }

  __getNativeAnimationConfig(): {|
    damping: number,
    initialVelocity: number,
    iterations: number,
    mass: number,
    platformConfig: ?PlatformConfig,
    overshootClamping: boolean,
    restDisplacementThreshold: number,
    restSpeedThreshold: number,
    stiffness: number,
    toValue: any,
    type: $TEMPORARY$string<'spring'>,
  |} {
    return {
      type: 'spring',
      overshootClamping: this._overshootClamping,
      restDisplacementThreshold: this._restDisplacementThreshold,
      restSpeedThreshold: this._restSpeedThreshold,
      stiffness: this._stiffness,
      damping: this._damping,
      mass: this._mass,
      initialVelocity: this._initialVelocity ?? this._lastVelocity,
      toValue: this._toValue,
      iterations: this.__iterations,
      platformConfig: this._platformConfig,
    };
  }

  start(
    fromValue: number,
    onUpdate: (value: number) => void,
    onEnd: ?EndCallback,
    previousAnimation: ?Animation,
    animatedValue: AnimatedValue,
  ): void {
    this.__active = true;
    this._startPosition = fromValue;
    this._lastPosition = this._startPosition;

    this._onUpdate = onUpdate;
    this.__onEnd = onEnd;
    this._lastTime = Date.now();
    this._frameTime = 0.0;

    if (previousAnimation instanceof SpringAnimation) {
      const internalState = previousAnimation.getInternalState();
      this._lastPosition = internalState.lastPosition;
      this._lastVelocity = internalState.lastVelocity;
      // Set the initial velocity to the last velocity
      this._initialVelocity = this._lastVelocity;
      this._lastTime = internalState.lastTime;
    }

    const start = () => {
      if (this._useNativeDriver) {
        this.__startNativeAnimation(animatedValue);
      } else {
        this.onUpdate();
      }
    };

    //  If this._delay is more than 0, we start after the timeout.
    if (this._delay) {
      this._timeout = setTimeout(start, this._delay);
    } else {
      start();
    }
  }

  getInternalState(): Object {
    return {
      lastPosition: this._lastPosition,
      lastVelocity: this._lastVelocity,
      lastTime: this._lastTime,
    };
  }

  /**
   * This spring model is based off of a damped harmonic oscillator
   * (https://en.wikipedia.org/wiki/Harmonic_oscillator#Damped_harmonic_oscillator).
   *
   * We use the closed form of the second order differential equation:
   *
   * x'' + (2ζ⍵_0)x' + ⍵^2x = 0
   *
   * where
   *    ⍵_0 = √(k / m) (undamped angular frequency of the oscillator),
   *    ζ = c / 2√mk (damping ratio),
   *    c = damping constant
   *    k = stiffness
   *    m = mass
   *
   * The derivation of the closed form is described in detail here:
   * http://planetmath.org/sites/default/files/texpdf/39745.pdf
   *
   * This algorithm happens to match the algorithm used by CASpringAnimation,
   * a QuartzCore (iOS) API that creates spring animations.
   */
  onUpdate(): void {
    // If for some reason we lost a lot of frames (e.g. process large payload or
    // stopped in the debugger), we only advance by 4 frames worth of
    // computation and will continue on the next frame. It's better to have it
    // running at faster speed than jumping to the end.
    const MAX_STEPS = 64;
    let now = Date.now();
    if (now > this._lastTime + MAX_STEPS) {
      now = this._lastTime + MAX_STEPS;
    }

    const deltaTime = (now - this._lastTime) / 1000;
    this._frameTime += deltaTime;

    const c: number = this._damping;
    const m: number = this._mass;
    const k: number = this._stiffness;
    const v0: number = -this._initialVelocity;

    const zeta = c / (2 * Math.sqrt(k * m)); // damping ratio
    const omega0 = Math.sqrt(k / m); // undamped angular frequency of the oscillator (rad/ms)
    const omega1 = omega0 * Math.sqrt(1.0 - zeta * zeta); // exponential decay
    const x0 = this._toValue - this._startPosition; // calculate the oscillation from x0 = 1 to x = 0

    let position = 0.0;
    let velocity = 0.0;
    const t = this._frameTime;
    if (zeta < 1) {
      // Under damped
      const envelope = Math.exp(-zeta * omega0 * t);
      position =
        this._toValue -
        envelope *
          (((v0 + zeta * omega0 * x0) / omega1) * Math.sin(omega1 * t) +
            x0 * Math.cos(omega1 * t));
      // This looks crazy -- it's actually just the derivative of the
      // oscillation function
      velocity =
        zeta *
          omega0 *
          envelope *
          ((Math.sin(omega1 * t) * (v0 + zeta * omega0 * x0)) / omega1 +
            x0 * Math.cos(omega1 * t)) -
        envelope *
          (Math.cos(omega1 * t) * (v0 + zeta * omega0 * x0) -
            omega1 * x0 * Math.sin(omega1 * t));
    } else {
      // Critically damped
      const envelope = Math.exp(-omega0 * t);
      position = this._toValue - envelope * (x0 + (v0 + omega0 * x0) * t);
      velocity =
        envelope * (v0 * (t * omega0 - 1) + t * x0 * (omega0 * omega0));
    }

    this._lastTime = now;
    this._lastPosition = position;
    this._lastVelocity = velocity;

    this._onUpdate(position);
    if (!this.__active) {
      // a listener might have stopped us in _onUpdate
      return;
    }

    // Conditions for stopping the spring animation
    let isOvershooting = false;
    if (this._overshootClamping && this._stiffness !== 0) {
      if (this._startPosition < this._toValue) {
        isOvershooting = position > this._toValue;
      } else {
        isOvershooting = position < this._toValue;
      }
    }
    const isVelocity = Math.abs(velocity) <= this._restSpeedThreshold;
    let isDisplacement = true;
    if (this._stiffness !== 0) {
      isDisplacement =
        Math.abs(this._toValue - position) <= this._restDisplacementThreshold;
    }

    if (isOvershooting || (isVelocity && isDisplacement)) {
      if (this._stiffness !== 0) {
        // Ensure that we end up with a round value
        this._lastPosition = this._toValue;
        this._lastVelocity = 0;
        this._onUpdate(this._toValue);
      }

      this.__debouncedOnEnd({finished: true});
      return;
    }
    // $FlowFixMe[method-unbinding] added when improving typing for this parameters
    this._animationFrame = requestAnimationFrame(this.onUpdate.bind(this));
  }

  stop(): void {
    super.stop();
    this.__active = false;
    clearTimeout(this._timeout);
    global.cancelAnimationFrame(this._animationFrame);
    this.__debouncedOnEnd({finished: false});
  }
}
