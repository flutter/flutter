// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sprites/flutter_sprites.dart';

ImageMap _images;
SpriteSheet _sprites;

class FitnessDemo extends StatelessWidget {
  FitnessDemo({ Key key }) : super(key: key);

  static const String routeName = '/fitness';

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Fitness')
      ),
      body: new _FitnessDemoContents()
    );
  }
}

class _FitnessDemoContents extends StatefulWidget {
  _FitnessDemoContents({ Key key }) : super(key: key);

  @override
  _FitnessDemoContentsState createState() => new _FitnessDemoContentsState();
}

class _FitnessDemoContentsState extends State<_FitnessDemoContents> {

  Future<Null> _loadAssets(AssetBundle bundle) async {
    _images = new ImageMap(bundle);
    await _images.load(<String>[
      'packages/flutter_gallery_assets/fitness_demo/jumpingjack.png',
    ]);

    String json = await DefaultAssetBundle.of(context).loadString('packages/flutter_gallery_assets/fitness_demo/jumpingjack.json');
    _sprites = new SpriteSheet(_images['packages/flutter_gallery_assets/fitness_demo/jumpingjack.png'], json);
  }

  @override
  void initState() {
    super.initState();

    AssetBundle bundle = DefaultAssetBundle.of(context);
    _loadAssets(bundle).then((_) {
      setState(() {
        _assetsLoaded = true;
        workoutAnimation = new _WorkoutAnimationNode(
          onPerformedJumpingJack: () {
            setState(() {
              _count += 1;
            });
          },
          onSecondPassed: (int seconds) {
            setState(() {
              _time = seconds;
            });
          }
        );
      });
    });
  }

  bool _assetsLoaded = false;
  int _count = 0;
  int _time = 0;
  int get kcal => (_count * 0.2).toInt();

  _WorkoutAnimationNode workoutAnimation;

  @override
  Widget build(BuildContext context) {
    if (!_assetsLoaded)
      return new Container();

    Color buttonColor;
    String buttonText;
    VoidCallback onButtonPressed;

    if (workoutAnimation.workingOut) {
      buttonColor = Colors.red[500];
      buttonText = "STOP WORKOUT";
      onButtonPressed = endWorkout;
    } else {
      buttonColor = Theme.of(context).primaryColor;
      buttonText = "START WORKOUT";
      onButtonPressed = startWorkout;
    }

    return new Material(
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          new Flexible(
            child: new Container(
              decoration: new BoxDecoration(backgroundColor: Colors.grey[800]),
              child: new SpriteWidget(workoutAnimation, SpriteBoxTransformMode.scaleToFit)
            )
          ),
          new Padding(
            padding: new EdgeInsets.only(top: 20.0),
            child: new Text('JUMPING JACKS', style: Theme.of(context).textTheme.title)
          ),
          new Padding(
            padding: new EdgeInsets.only(top: 20.0, bottom: 20.0),
            child: new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _createInfoPanelCell(Icons.accessibility, '$_count', 'COUNT'),
                _createInfoPanelCell(Icons.timer, _formatSeconds(_time), 'TIME'),
                _createInfoPanelCell(Icons.flash_on, '$kcal', 'KCAL')
              ]
            )
          ),
          new Padding(
            padding: new EdgeInsets.only(bottom: 16.0),
            child: new SizedBox(
              width: 300.0,
              height: 72.0,
              child: new RaisedButton (
                onPressed: onButtonPressed,
                color: buttonColor,
                child: new Text(
                  buttonText,
                  style: new TextStyle(color: Colors.white, fontSize: 20.0)
                )
              )
            )
          )
        ]
      )
    );
  }

  Widget _createInfoPanelCell(IconData icon, String value, String description) {
    Color color;
    if (workoutAnimation.workingOut)
      color = Colors.black87;
    else
      color = Theme.of(context).disabledColor;

    return new Container(
      width: 100.0,
      child: new Center(
        child: new Column(
          children: <Widget>[
            new Icon(icon, size: 48.0, color: color),
            new Text(value, style: new TextStyle(fontSize: 24.0, color: color)),
            new Text(description, style: new TextStyle(color: color))
          ]
        )
      )
    );
  }

  String _formatSeconds(int seconds) {
    int minutes = seconds ~/ 60;
    String secondsStr = "${seconds % 60}".padLeft(2, "0");
    return "$minutes:$secondsStr";
  }

  void startWorkout() {
    setState(() {
      _count = 0;
      _time = 0;
      workoutAnimation.start();
    });
  }

  void endWorkout() {
    setState(() {
      workoutAnimation.stop();

      if (_count >= 3) {
        showDialog(
          context: context,
          child: new Stack(children: <Widget>[
            new _Fireworks(),
            new Dialog(
              title: new Text('Awesome workout'),
              content: new Text('You have completed $_count jumping jacks. Good going!'),
              actions: <Widget>[
                new FlatButton(
                  child: new Text('SWEET'),
                  onPressed: () { Navigator.pop(context); }
                )
              ]
            )
          ])
        );
      }
    });
  }
}

typedef void _SecondPassedCallback(int seconds);

class _WorkoutAnimationNode extends NodeWithSize {
  _WorkoutAnimationNode({
    this.onPerformedJumpingJack,
    this.onSecondPassed
  }) : super(const Size(1024.0, 1024.0)) {
    reset();

    _progress = new _ProgressCircle(const Size(800.0, 800.0));
    _progress.pivot = const Point(0.5, 0.5);
    _progress.position = const Point(512.0, 512.0);
    addChild(_progress);

    _jumpingJack = new _JumpingJack((){
      onPerformedJumpingJack();
    });
    _jumpingJack.scale = 0.5;
    _jumpingJack.position = const Point(512.0, 550.0);
    addChild(_jumpingJack);
  }

  final VoidCallback onPerformedJumpingJack;
  final _SecondPassedCallback onSecondPassed;

  int seconds;

  bool workingOut;

  static const int _kTargetMillis = 1000 * 30;
  int _startTimeMillis;
  _ProgressCircle _progress;
  _JumpingJack _jumpingJack;

  void reset() {
    seconds = 0;
    workingOut = false;
  }

  void start() {
    reset();
    _startTimeMillis = new DateTime.now().millisecondsSinceEpoch;
    workingOut = true;
    _jumpingJack.animateJumping();
  }

  void stop() {
    workingOut = false;
    _jumpingJack.neutralPose();
  }

  @override
  void update(double dt) {
    if (workingOut) {
      int millis = new DateTime.now().millisecondsSinceEpoch - _startTimeMillis;
      int newSeconds = (millis) ~/ 1000;
      if (newSeconds != seconds) {
        seconds = newSeconds;
        onSecondPassed(seconds);
      }

      _progress.value = millis / _kTargetMillis;
    } else {
      _progress.value = 0.0;
    }
  }
}

class _ProgressCircle extends NodeWithSize {
  _ProgressCircle(Size size, [this.value = 0.0]) : super(size);

  static const double _kTwoPI = math.PI * 2.0;
  static const double _kEpsilon = .0000001;
  static const double _kSweep = _kTwoPI - _kEpsilon;

  double value;

  @override
  void paint(Canvas canvas) {
    applyTransformForPivot(canvas);

    Paint circlePaint = new Paint()
      ..color = Colors.white30
      ..strokeWidth = 24.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(
      new Point(size.width / 2.0, size.height / 2.0),
      size.width / 2.0,
      circlePaint
    );

    Paint pathPaint = new Paint()
      ..color = Colors.purple[500]
      ..strokeWidth = 25.0
      ..style = PaintingStyle.stroke;

    double angle = value.clamp(0.0, 1.0) * _kSweep;
    Path path = new Path()
      ..arcTo(Point.origin & size, -math.PI / 2.0, angle, false);
    canvas.drawPath(path, pathPaint);
  }
}

class _JumpingJack extends Node {
  _JumpingJack(VoidCallback onPerformedJumpingJack) {
    left = new _JumpingJackSide(false, onPerformedJumpingJack);
    right = new _JumpingJackSide(true, null);
    addChild(left);
    addChild(right);
  }

  void animateJumping() {
    left.animateJumping();
    right.animateJumping();
  }

  void neutralPose() {
    left.neutralPosition(true);
    right.neutralPosition(true);
  }

  _JumpingJackSide left;
  _JumpingJackSide right;
}

class _JumpingJackSide extends Node {
  _JumpingJackSide(bool right, this.onPerformedJumpingJack) {
    // Torso and head
    torso = _createPart('torso.png', const Point(512.0, 512.0));
    addChild(torso);

    head = _createPart('head.png', const Point(512.0, 160.0));
    torso.addChild(head);

    if (right) {
      torso.opacity = 0.0;
      head.opacity = 0.0;
      torso.scaleX = -1.0;
    }

    // Left side movable parts
    upperArm = _createPart('upper-arm.png', const Point(445.0, 220.0));
    torso.addChild(upperArm);
    lowerArm = _createPart('lower-arm.png', const Point(306.0, 200.0));
    upperArm.addChild(lowerArm);
    hand = _createPart('hand.png', const Point(215.0, 127.0));
    lowerArm.addChild(hand);
    upperLeg = _createPart('upper-leg.png', const Point(467.0, 492.0));
    torso.addChild(upperLeg);
    lowerLeg = _createPart('lower-leg.png', const Point(404.0, 660.0));
    upperLeg.addChild(lowerLeg);
    foot = _createPart('foot.png', const Point(380.0, 835.0));
    lowerLeg.addChild(foot);

    torso.setPivotAndPosition(Point.origin);

    neutralPosition(false);
  }

  _JumpingJackPart torso;
  _JumpingJackPart head;
  _JumpingJackPart upperArm;
  _JumpingJackPart lowerArm;
  _JumpingJackPart hand;
  _JumpingJackPart lowerLeg;
  _JumpingJackPart upperLeg;
  _JumpingJackPart foot;

  final VoidCallback onPerformedJumpingJack;

  _JumpingJackPart _createPart(String textureName, Point pivotPosition) {
    return new _JumpingJackPart(_sprites[textureName], pivotPosition);
  }

  void animateJumping() {
    actions.stopAll();
    actions.run(new ActionSequence(<Action>[
      _createPoseAction(null, 0, 0.5),
      new ActionCallFunction(_animateJumpingLoop)
    ]));
  }

  void _animateJumpingLoop() {
    actions.run(new ActionRepeatForever(
      new ActionSequence(<Action>[
        _createPoseAction(0, 1, 0.30),
        _createPoseAction(1, 2, 0.30),
        _createPoseAction(2, 1, 0.30),
        _createPoseAction(1, 0, 0.30),
        new ActionCallFunction(() {
          if (onPerformedJumpingJack != null)
            onPerformedJumpingJack();
        })
      ])
    ));
  }

  void neutralPosition(bool animate) {
    actions.stopAll();
    if (animate) {
      actions.run(_createPoseAction(null, 1, 0.5));
    } else {
      List<double> d = _dataForPose(1);
      upperArm.rotation = d[0];
      lowerArm.rotation = d[1];
      hand.rotation = d[2];
      upperLeg.rotation = d[3];
      lowerLeg.rotation = d[4];
      foot.rotation = d[5];
      torso.position = new Point(0.0, d[6]);
    }
  }

  ActionInterval _createPoseAction(int startPose, int endPose, double duration) {
    List<double> d0 = _dataForPose(startPose);
    List<double> d1 = _dataForPose(endPose);

    List<ActionTween> tweens = <ActionTween>[
      _tweenRotation(upperArm, d0[0], d1[0], duration),
      _tweenRotation(lowerArm, d0[1], d1[1], duration),
      _tweenRotation(hand, d0[2], d1[2], duration),
      _tweenRotation(upperLeg, d0[3], d1[3], duration),
      _tweenRotation(lowerLeg, d0[4], d1[4], duration),
      _tweenRotation(foot, d0[5], d1[5], duration),
      new ActionTween(
        (Point a) => torso.position = a,
        new Point(0.0, d0[6]),
        new Point(0.0, d1[6]),
        duration
      )
    ];

    return new ActionGroup(tweens);
  }

  ActionTween _tweenRotation(_JumpingJackPart part, double r0, double r1, double duration) {
    return new ActionTween(
      (double a) => part.rotation = a,
      r0,
      r1,
      duration
    );
  }

  List<double> _dataForPose(int pose) {
    if (pose == null)
      return _dataForCurrentPose();

    if (pose == 0) {
      return <double>[
        -80.0, // Upper arm rotation
        -30.0, // Lower arm rotation
        -10.0, // Hand rotation
        -15.0, // Upper leg rotation
        5.0,   // Lower leg rotation
        15.0,  // Foot rotation
        0.0    // Torso y offset
      ];
    } else if (pose == 1) {
      return <double>[
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        -70.0
      ];
    } else {
      return <double>[
        40.0,
        30.0,
        10.0,
        20.0,
        -20.0,
        15.0,
        40.0
      ];
    }
  }

  List<double> _dataForCurrentPose() {
    return <double>[
      upperArm.rotation,
      lowerArm.rotation,
      hand.rotation,
      upperLeg.rotation,
      lowerLeg.rotation,
      foot.rotation,
      torso.position.y
    ];
  }
}

class _JumpingJackPart extends Sprite {
  _JumpingJackPart(Texture texture, this.pivotPosition) : super(texture);
  final Point pivotPosition;

  void setPivotAndPosition(Point newPosition) {
    pivot = new Point(pivotPosition.x / 1024.0, pivotPosition.y / 1024.0);
    position = newPosition;

    for (Node child in children) {
      _JumpingJackPart subPart = child;
      subPart.setPivotAndPosition(
        new Point(
          subPart.pivotPosition.x - pivotPosition.x,
          subPart.pivotPosition.y - pivotPosition.y
        )
      );
    }
  }
}

class _Fireworks extends StatefulWidget {
  _Fireworks({ Key key }) : super(key: key);

  @override
  _FireworksState createState() => new _FireworksState();
}

class _FireworksState extends State<_Fireworks> {
  @override
  void initState() {
    super.initState();
    fireworks = new _FireworksNode();
  }

  _FireworksNode fireworks;

  @override
  Widget build(BuildContext context) {
    return new SpriteWidget(fireworks);
  }
}

class _FireworksNode extends NodeWithSize {
  _FireworksNode() : super(const Size(1024.0, 1024.0));
  double _countDown = 0.0;

  @override
  void update(double dt) {
    if (_countDown <= 0.0) {
      _addExplosion();
      _countDown = randomDouble();
    }

    _countDown -= dt;
  }

  Color _randomExplosionColor() {
    double rand = randomDouble();
    if (rand < 0.25)
      return Colors.pink[200];
    else if (rand < 0.5)
      return Colors.lightBlue[200];
    else if (rand < 0.75)
      return Colors.purple[200];
    else
      return Colors.cyan[200];
  }

  void _addExplosion() {
    Color startColor = _randomExplosionColor();
    Color endColor = startColor.withAlpha(0);

    ParticleSystem system = new ParticleSystem(
      _sprites['particle-0.png'],
      numParticlesToEmit: 100,
      emissionRate: 1000.0,
      rotateToMovement: true,
      startRotation: 90.0,
      endRotation: 90.0,
      speed: 100.0,
      speedVar: 50.0,
      startSize: 1.0,
      startSizeVar: 0.5,
      gravity: const Offset(0.0, 30.0),
      colorSequence: new ColorSequence.fromStartAndEndColor(startColor, endColor)
    );
    system.position = new Point(randomDouble() * 1024.0, randomDouble() * 1024.0);
    addChild(system);
  }
}

void main() {
  runApp(new MaterialApp(
    title: 'Fitness',
    home: new FitnessDemo()
  ));
}
