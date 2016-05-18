# Flutter Sprites
Flutter Sprites is a toolkit for building complex, high performance animations and 2D games with Flutter. Your sprite render tree lives inside a SpriteWidget that mixes seamlessly with other Flutter and Material widgets. You can use Flutter Sprites to create anything from an animated icon to a full fledged game.

This guide assumes a basic knowledge of Flutter and Dart. You can find an example of Flutter Sprites in the Flutter Gallery in the Weather demo, or in the flutter/game repository on Github.

## Setting up a SpriteWidget
The first thing you need to do to use Flutter Sprites is to setup a SpriteWidget with a root node that is used to draw it's contents. Any sprite nodes that you add to the root node will be rendered by the SpriteWidget. Typically, your root node is part of your app's state. This is an example of how you can setup a custom stateful widget with Flutter Sprites:

    import 'package:flutter/material.dart';
    import 'package:flutter_sprites/flutter_sprites.dart';
    
    class MyWidget extends StatefulWidget {
      @override
      MyWidgetState createState() => new MyWidgetState();
    }
    
    class MyWidgetState extends State<MyWidget> {
      NodeWithSize rootNode;
      
      @override
      void initState() {
        super.initState();
        rootNode = new NodeWithSize(const Size(1024.0, 1024.0));
      }
      
      @override
      Widget build(BuildContext context) {
      	return new SpriteWidget(rootNode);
      }
    }

The root node that you provide the SpriteWidget is a NodeWithSize, the size of the root node defines the coordinate system used by the SpriteWidget. By default the SpriteWidget uses letterboxing to display its contents. This means that the size that you give the root node will determine how the SpriteWidget's contents will be scaled to fit. If it doesn't fit perfectly in the area of the widget, either its top and bottom or the left and right side will be trimmed. You can optionally pass in a parameter to the SpriteWidget for other scaling options depending on your needs.

## Adding objects to your node graph
Your SpriteWidget manages a node graph, the root node is the NodeWithSize that is passed in to the SpriteWidget when it's created. To render sprites, particles systems, or any other objects simply add them to the node graph.

Each node in the node graph has a transform. The transform is inherited by its children, this makes it possible to build more complex structures by grouping objects together as children to a node and then manipulating the parent node. For example the following code creates a car sprite with two wheels attached to it. The car is added to the root node.

    Sprite car = new Sprite.fromImage(carImage);
    Sprite frontWheel = new Sprite.fromImage(wheelImage);
    Sprite rearWheel = new Sprite.fromImage(wheelImage);
    
    frontWheel.position = const Point(100, 50);
    rearWheel.position = const Point(-100, 50);
    
    car.addChild(frontWheel);
    car.addChild(rearWheel);
    
    rootNode.addChild(car);
    
You can manipulate the transform by setting the position, rotation, scale, and skew properties.

## Sprites, textures, and sprite sheets
The most common node type is the Sprite node. A sprite simply draws an image to the screen. Sprites can be drawn from Image objects or Texture objects. A texture is a part of an Image. Using a SpriteSheet you can pack several texture elements within a single image. This saves space in the device's gpu memory and also make drawing faster. Currently Flutter Sprites supports sprite sheets in json format and produced with a tool such as TexturePacker. It's uncommon to manually edit the sprite sheet files. You can create a SpriteSheet with a definition in json and an image:

    SpriteSheet sprites = new SpriteSheet(myImage, jsonCode);
    Texture texture = sprites['texture.png'];

## The frame cycle
Each time a new frame is rendered to screen Flutter Sprites will perform a number of actions. Sometimes when creating more advanced interactive animations or games, the order in which these actions are performed may matter.

This is the order things will happen:

1. Handle input events
2. Run animation actions
3. Call update functions on nodes
4. Apply constraints 
5. Render the frame to screen

Read more about each of the different phases below.

## Handling user input
You can subclass any node type to handle touches. To receive touches, you need to set the userInteractionEnabled property to true and override the handleEvent method. If the node you are subclassing doesn't have a size, you will also need to override the isPointInside method.

    class EventHandlingNode extends NodeWithSize {
      EventHandlingNode(Size size) : super(size) {
        userInteractionEnabled = true;
      }
      
      @override handleEvent(SpriteBoxEvent event) {
        if (event.type == PointerDownEvent)
          ...
        else if (event.type == PointerMoveEvent)
          ...
        
        return true;
      }
    }

If you want your node to receive multiple touches, set the handleMultiplePointers property to true. Each touch down or dragged touch will generate a separate call to the handleEvent method, you can distinguish each touch by its pointer property.

## Animating using actions
Flutter Sprites provides easy to use functions for animating nodes through actions. You can combine simple action blocks to create more complex animations.

### Tweens
Tweens are the simplest building block for creating an animation. It will interpolate a value or property over a specified time period. You provide the ActionTween class with a setter function, its start and end value, and the duration for the tween.

After creating a tween, execute it by running it through a node's action manager.

	Node myNode = new Node();

    ActionTween myTween = new ActionTween(
      (Point a) => myNode.position = a,
      Point.origin,
      const Point(100.0, 0.0),
      1.0
    );
    
    myNode.actions.run(myTween);

You can animate values of different types, such as floats, points, rectangles, and even colors. You can also optionally provide the ActionTween class with an easing function.

### Sequences
When you need to play two or more actions in a sequence, use the ActionSequence class:

    ActionSequence sequence = new ActionSequence([
      firstAction,
      middleAction,
      lastAction
    ]);
    
### Groups
Use ActionGroup to play actions in parallel:

    ActionGroup group = new ActionGroup([
      action0,
      action1
    ]);
    
### Repeat
You can loop any action, either a fixed number of times, or until the end of times:

    ActionRepeat repeat = new ActionRepeat(loopedAction, 5);
    
    ActionRepeatForever longLoop = new ActionRepeatForever(loopedAction);
    
### Composition
It's possible to create more complex actions by composing them in any way:

    ActionSequence complexAction = new ActionSequence([
      new ActionRepeat(myLoop, 2),
      new ActionGroup([
      	action0,
      	action1
      ])
    ]);
    
## Handle update events
Each frame, update events are sent to each node in the current node tree. Override the update method to manually do animations or to perform game logic.

    MyNode extends Node {
      @override
      update(double dt) {
        // Move the node at a constant speed
      	position += new Offset(dt * 1.0, 0.0);
      }
    }

## Defining constraints
Constraints are used to constrain properties of nodes. They can be used to position nodes relative other nodes, or adjust the rotation or scale. You can apply more than one constraint to a single node.

For example, you can use a constraint to make a node follow another node at a specific distance with a specified dampening. The dampening will smoothen out the following node's movement.

    followingNode.constraints = [
      new ConstraintPositionToNode(
        targetNode,
        offset: const Offset(0.0, 100.0),
        dampening: 0.5
      )
    ];

Constraints are applied at the end of the frame cycle. If you need them to be applied at any other time, you can directly call the applyConstraints method of a Node object.

## Perform custom drawing
Flutter Sprites provides a default set of drawing primitives, but there are cases where you may want to perform custom drawing. To do this you will need to subclass either the Node or NodeWithSize class and override the paint method:

    class RedCircle extends Node {
      RedCircle(this.radius);
  
      double radius;
  
      @override
      void paint(Canvas canvas) {
        canvas.drawCircle(
          Point.origin,
          radius,
          new Paint()..color = const Color(0xffff0000)
        );
      }
    }
    
If you are overriding a NodeWithSize you may want to call applyTransformForPivot before starting drawing to account for the node's pivot point. After the call the coordinate system is setup so you can perform drawing starting at origo to the size of the node.

    @override
    void paint(Canvas canvas) {
      applyTransformForPivot(canvas);
      
      canvas.drawRect(
        new Rect.fromLTWH(0.0, 0.0, size.width, size.height),
        myPaint
      );
    }

## Add effects using particle systems
Particle systems are great for creating effects such as rain, smoke, or fire. It's easy to setup a particle system, but there are very many properties that can be tweaked. The best way of to get a feel for how they work is to simply play around with the them.

This is an example of how a particle system can be created, configured, and added to the scene:

    ParticleSystem particles = new ParticleSystem(
      particleTexture,
      posVar: const Point(100, 100.0),
      startSize: 1.0,
      startSizeVar: 0.5,
      endSize: 2.0,
      endSizeVar: 1.0,
      life: 1.5 * distance,
      lifeVar: 1.0 * distance
    );
    
    rootNode.addChild(particles);