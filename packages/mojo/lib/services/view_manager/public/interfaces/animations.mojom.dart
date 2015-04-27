// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library animations.mojom;

import 'dart:async';

import 'package:mojo/public/dart/bindings.dart' as bindings;
import 'package:mojo/public/dart/core.dart' as core;
import 'package:mojo/services/geometry/public/interfaces/geometry.mojom.dart' as geometry_mojom;

final int AnimationTweenType_LINEAR = 0;
final int AnimationTweenType_EASE_IN = AnimationTweenType_LINEAR + 1;
final int AnimationTweenType_EASE_OUT = AnimationTweenType_EASE_IN + 1;
final int AnimationTweenType_EASE_IN_OUT = AnimationTweenType_EASE_OUT + 1;

final int AnimationProperty_NONE = 0;
final int AnimationProperty_OPACITY = AnimationProperty_NONE + 1;
final int AnimationProperty_TRANSFORM = AnimationProperty_OPACITY + 1;


class AnimationValue extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  double floatValue = 0.0;
  geometry_mojom.Transform transform = null;

  AnimationValue() : super(kVersions.last.size);

  static AnimationValue deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static AnimationValue decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    AnimationValue result = new AnimationValue();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.floatValue = decoder0.decodeFloat(8);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(16, false);
      result.transform = geometry_mojom.Transform.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeFloat(floatValue, 8);
    
    encoder0.encodeStruct(transform, 16, false);
  }

  String toString() {
    return "AnimationValue("
           "floatValue: $floatValue" ", "
           "transform: $transform" ")";
  }
}

class AnimationElement extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(40, 0)
  ];
  int property = 0;
  int tweenType = 0;
  int duration = 0;
  AnimationValue startValue = null;
  AnimationValue targetValue = null;

  AnimationElement() : super(kVersions.last.size);

  static AnimationElement deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static AnimationElement decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    AnimationElement result = new AnimationElement();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.property = decoder0.decodeInt32(8);
    }
    if (mainDataHeader.version >= 0) {
      
      result.tweenType = decoder0.decodeInt32(12);
    }
    if (mainDataHeader.version >= 0) {
      
      result.duration = decoder0.decodeInt64(16);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(24, true);
      result.startValue = AnimationValue.decode(decoder1);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(32, true);
      result.targetValue = AnimationValue.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(property, 8);
    
    encoder0.encodeInt32(tweenType, 12);
    
    encoder0.encodeInt64(duration, 16);
    
    encoder0.encodeStruct(startValue, 24, true);
    
    encoder0.encodeStruct(targetValue, 32, true);
  }

  String toString() {
    return "AnimationElement("
           "property: $property" ", "
           "tweenType: $tweenType" ", "
           "duration: $duration" ", "
           "startValue: $startValue" ", "
           "targetValue: $targetValue" ")";
  }
}

class AnimationSequence extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  int cycleCount = 0;
  List<AnimationElement> elements = null;

  AnimationSequence() : super(kVersions.last.size);

  static AnimationSequence deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static AnimationSequence decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    AnimationSequence result = new AnimationSequence();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.cycleCount = decoder0.decodeUint32(8);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(16, false);
      {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.elements = new List<AnimationElement>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          var decoder2 = decoder1.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          result.elements[i1] = AnimationElement.decode(decoder2);
        }
      }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeUint32(cycleCount, 8);
    
    if (elements == null) {
      encoder0.encodeNullPointer(16, false);
    } else {
      var encoder1 = encoder0.encodePointerArray(elements.length, 16, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < elements.length; ++i0) {
        
        encoder1.encodeStruct(elements[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
      }
    }
  }

  String toString() {
    return "AnimationSequence("
           "cycleCount: $cycleCount" ", "
           "elements: $elements" ")";
  }
}

class AnimationGroup extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  int viewId = 0;
  List<AnimationSequence> sequences = null;

  AnimationGroup() : super(kVersions.last.size);

  static AnimationGroup deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static AnimationGroup decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    AnimationGroup result = new AnimationGroup();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.viewId = decoder0.decodeUint32(8);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(16, false);
      {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.sequences = new List<AnimationSequence>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          var decoder2 = decoder1.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          result.sequences[i1] = AnimationSequence.decode(decoder2);
        }
      }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeUint32(viewId, 8);
    
    if (sequences == null) {
      encoder0.encodeNullPointer(16, false);
    } else {
      var encoder1 = encoder0.encodePointerArray(sequences.length, 16, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < sequences.length; ++i0) {
        
        encoder1.encodeStruct(sequences[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
      }
    }
  }

  String toString() {
    return "AnimationGroup("
           "viewId: $viewId" ", "
           "sequences: $sequences" ")";
  }
}

