// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=false*/

// @dart=2.6

/*class: Sink:Object,Sink<T*>*/
/*cfe|cfe:builder.member: Sink.toString:String* Function()**/
/*cfe|cfe:builder.member: Sink.runtimeType:Type**/
/*cfe|cfe:builder.member: Sink._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Sink._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: Sink.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: Sink._identityHashCode:int**/
/*cfe|cfe:builder.member: Sink.hashCode:int**/
/*cfe|cfe:builder.member: Sink._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Sink._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Sink.==:bool* Function(dynamic)**/
abstract class Sink<T> {
  /*member: Sink.close:void Function()**/
  void close();
}

/*class: EventSink:EventSink<T*>,Object,Sink<T*>*/
/*cfe|cfe:builder.member: EventSink.toString:String* Function()**/
/*cfe|cfe:builder.member: EventSink.runtimeType:Type**/
/*cfe|cfe:builder.member: EventSink._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: EventSink._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: EventSink.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: EventSink._identityHashCode:int**/
/*cfe|cfe:builder.member: EventSink.hashCode:int**/
/*cfe|cfe:builder.member: EventSink._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: EventSink._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: EventSink.==:bool* Function(dynamic)**/
abstract class EventSink<T> implements Sink<T> {
  /*member: EventSink.close:void Function()**/
  void close();
}

/*class: StreamConsumer:Object,StreamConsumer<S*>*/
/*cfe|cfe:builder.member: StreamConsumer.toString:String* Function()**/
/*cfe|cfe:builder.member: StreamConsumer.runtimeType:Type**/
/*cfe|cfe:builder.member: StreamConsumer._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: StreamConsumer._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: StreamConsumer.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: StreamConsumer._identityHashCode:int**/
/*cfe|cfe:builder.member: StreamConsumer.hashCode:int**/
/*cfe|cfe:builder.member: StreamConsumer._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: StreamConsumer._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: StreamConsumer.==:bool* Function(dynamic)**/
abstract class StreamConsumer<S> {
  /*member: StreamConsumer.close:Future<dynamic>* Function()**/
  Future close();
}

/*class: StreamSink:EventSink<S*>,Object,Sink<S*>,StreamConsumer<S*>,StreamSink<S*>*/
/*cfe|cfe:builder.member: StreamSink.toString:String* Function()**/
/*cfe|cfe:builder.member: StreamSink.runtimeType:Type**/
/*cfe|cfe:builder.member: StreamSink._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: StreamSink._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: StreamSink.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: StreamSink._identityHashCode:int**/
/*cfe|cfe:builder.member: StreamSink.hashCode:int**/
/*cfe|cfe:builder.member: StreamSink._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: StreamSink._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: StreamSink.==:bool* Function(dynamic)**/
abstract class StreamSink<S> implements EventSink<S>, StreamConsumer<S> {
  /*member: StreamSink.close:Future<dynamic>* Function()**/
  Future close();
}
