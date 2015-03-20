// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library geocoder.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;
import 'package:mojo/services/location/public/interfaces/location.mojom.dart' as location_mojom;


class LocationType extends bindings.Struct {
  static const int kStructSize = 8;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  static final ROOFTOP = "ROOFTOP";
  static final RANGE_INTERPOLATED = "RANGE_INTERPOLATED";
  static final GEOMETRIC_CENTER = "GEOMETRIC_CENTER";
  static final APPROXIMATE = "APPROXIMATE";

  LocationType() : super(kStructSize);

  static LocationType deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static LocationType decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    LocationType result = new LocationType();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    encoder.getStructEncoderAtOffset(kDefaultStructInfo);
  }

  String toString() {
    return "LocationType("")";
  }
}

class Bounds extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  location_mojom.Location northeast = null;
  location_mojom.Location southwest = null;

  Bounds() : super(kStructSize);

  static Bounds deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static Bounds decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    Bounds result = new Bounds();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.northeast = location_mojom.Location.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, false);
      result.southwest = location_mojom.Location.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(northeast, 8, false);
    
    encoder0.encodeStruct(southwest, 16, false);
  }

  String toString() {
    return "Bounds("
           "northeast: $northeast" ", "
           "southwest: $southwest" ")";
  }
}

class ComponentRestrictions extends bindings.Struct {
  static const int kStructSize = 48;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  String administrativeArea = null;
  String country = null;
  String locality = null;
  String postalCode = null;
  String route = null;

  ComponentRestrictions() : super(kStructSize);

  static ComponentRestrictions deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ComponentRestrictions decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ComponentRestrictions result = new ComponentRestrictions();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.administrativeArea = decoder0.decodeString(8, true);
    }
    {
      
      result.country = decoder0.decodeString(16, true);
    }
    {
      
      result.locality = decoder0.decodeString(24, true);
    }
    {
      
      result.postalCode = decoder0.decodeString(32, true);
    }
    {
      
      result.route = decoder0.decodeString(40, true);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeString(administrativeArea, 8, true);
    
    encoder0.encodeString(country, 16, true);
    
    encoder0.encodeString(locality, 24, true);
    
    encoder0.encodeString(postalCode, 32, true);
    
    encoder0.encodeString(route, 40, true);
  }

  String toString() {
    return "ComponentRestrictions("
           "administrativeArea: $administrativeArea" ", "
           "country: $country" ", "
           "locality: $locality" ", "
           "postalCode: $postalCode" ", "
           "route: $route" ")";
  }
}

class Options extends bindings.Struct {
  static const int kStructSize = 32;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  ComponentRestrictions restrictions = null;
  location_mojom.Location location = null;
  String region = null;

  Options() : super(kStructSize);

  static Options deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static Options decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    Options result = new Options();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, true);
      result.restrictions = ComponentRestrictions.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, true);
      result.location = location_mojom.Location.decode(decoder1);
    }
    {
      
      result.region = decoder0.decodeString(24, true);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(restrictions, 8, true);
    
    encoder0.encodeStruct(location, 16, true);
    
    encoder0.encodeString(region, 24, true);
  }

  String toString() {
    return "Options("
           "restrictions: $restrictions" ", "
           "location: $location" ", "
           "region: $region" ")";
  }
}

class Geometry extends bindings.Struct {
  static const int kStructSize = 40;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  location_mojom.Location location = null;
  LocationType locationType = null;
  Bounds viewport = null;
  Bounds bounds = null;

  Geometry() : super(kStructSize);

  static Geometry deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static Geometry decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    Geometry result = new Geometry();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.location = location_mojom.Location.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, false);
      result.locationType = LocationType.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(24, false);
      result.viewport = Bounds.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(32, true);
      result.bounds = Bounds.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(location, 8, false);
    
    encoder0.encodeStruct(locationType, 16, false);
    
    encoder0.encodeStruct(viewport, 24, false);
    
    encoder0.encodeStruct(bounds, 32, true);
  }

  String toString() {
    return "Geometry("
           "location: $location" ", "
           "locationType: $locationType" ", "
           "viewport: $viewport" ", "
           "bounds: $bounds" ")";
  }
}

class Result extends bindings.Struct {
  static const int kStructSize = 40;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  bool partialMatch = false;
  Geometry geometry = null;
  String formattedAddress = null;
  List<String> types = null;

  Result() : super(kStructSize);

  static Result deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static Result decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    Result result = new Result();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.partialMatch = decoder0.decodeBool(8, 0);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, false);
      result.geometry = Geometry.decode(decoder1);
    }
    {
      
      result.formattedAddress = decoder0.decodeString(24, false);
    }
    {
      
      var decoder1 = decoder0.decodePointer(32, false);
      {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.types = new List<String>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          result.types[i1] = decoder1.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeBool(partialMatch, 8, 0);
    
    encoder0.encodeStruct(geometry, 16, false);
    
    encoder0.encodeString(formattedAddress, 24, false);
    
    if (types == null) {
      encoder0.encodeNullPointer(32, false);
    } else {
      var encoder1 = encoder0.encodePointerArray(types.length, 32, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < types.length; ++i0) {
        
        encoder1.encodeString(types[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
      }
    }
  }

  String toString() {
    return "Result("
           "partialMatch: $partialMatch" ", "
           "geometry: $geometry" ", "
           "formattedAddress: $formattedAddress" ", "
           "types: $types" ")";
  }
}

class Status extends bindings.Struct {
  static const int kStructSize = 8;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  static final OK = "OK";
  static final ZERO_RESULTS = "ZERO_RESULTS";
  static final OVER_QUERY_LIMIT = "OVER_QUERY_LIMIT";
  static final REQUEST_DENIED = "REQUEST_DENIED";
  static final INVALID_REQUEST = "INVALID_REQUEST";

  Status() : super(kStructSize);

  static Status deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static Status decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    Status result = new Status();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    encoder.getStructEncoderAtOffset(kDefaultStructInfo);
  }

  String toString() {
    return "Status("")";
  }
}

class GeocoderAddressToLocationParams extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  String address = null;
  Options options = null;

  GeocoderAddressToLocationParams() : super(kStructSize);

  static GeocoderAddressToLocationParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static GeocoderAddressToLocationParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    GeocoderAddressToLocationParams result = new GeocoderAddressToLocationParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.address = decoder0.decodeString(8, false);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, true);
      result.options = Options.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeString(address, 8, false);
    
    encoder0.encodeStruct(options, 16, true);
  }

  String toString() {
    return "GeocoderAddressToLocationParams("
           "address: $address" ", "
           "options: $options" ")";
  }
}

class GeocoderAddressToLocationResponseParams extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  String status = null;
  List<Result> results = null;

  GeocoderAddressToLocationResponseParams() : super(kStructSize);

  static GeocoderAddressToLocationResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static GeocoderAddressToLocationResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    GeocoderAddressToLocationResponseParams result = new GeocoderAddressToLocationResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.status = decoder0.decodeString(8, false);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, true);
      if (decoder1 == null) {
        result.results = null;
      } else {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.results = new List<Result>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          var decoder2 = decoder1.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          result.results[i1] = Result.decode(decoder2);
        }
      }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeString(status, 8, false);
    
    if (results == null) {
      encoder0.encodeNullPointer(16, true);
    } else {
      var encoder1 = encoder0.encodePointerArray(results.length, 16, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < results.length; ++i0) {
        
        encoder1.encodeStruct(results[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
      }
    }
  }

  String toString() {
    return "GeocoderAddressToLocationResponseParams("
           "status: $status" ", "
           "results: $results" ")";
  }
}

class GeocoderLocationToAddressParams extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  location_mojom.Location location = null;
  Options options = null;

  GeocoderLocationToAddressParams() : super(kStructSize);

  static GeocoderLocationToAddressParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static GeocoderLocationToAddressParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    GeocoderLocationToAddressParams result = new GeocoderLocationToAddressParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.location = location_mojom.Location.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, true);
      result.options = Options.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(location, 8, false);
    
    encoder0.encodeStruct(options, 16, true);
  }

  String toString() {
    return "GeocoderLocationToAddressParams("
           "location: $location" ", "
           "options: $options" ")";
  }
}

class GeocoderLocationToAddressResponseParams extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  String status = null;
  List<Result> results = null;

  GeocoderLocationToAddressResponseParams() : super(kStructSize);

  static GeocoderLocationToAddressResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static GeocoderLocationToAddressResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    GeocoderLocationToAddressResponseParams result = new GeocoderLocationToAddressResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.status = decoder0.decodeString(8, false);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, true);
      if (decoder1 == null) {
        result.results = null;
      } else {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.results = new List<Result>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          var decoder2 = decoder1.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          result.results[i1] = Result.decode(decoder2);
        }
      }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeString(status, 8, false);
    
    if (results == null) {
      encoder0.encodeNullPointer(16, true);
    } else {
      var encoder1 = encoder0.encodePointerArray(results.length, 16, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < results.length; ++i0) {
        
        encoder1.encodeStruct(results[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
      }
    }
  }

  String toString() {
    return "GeocoderLocationToAddressResponseParams("
           "status: $status" ", "
           "results: $results" ")";
  }
}
const int kGeocoder_addressToLocation_name = 0;
const int kGeocoder_locationToAddress_name = 1;

const String GeocoderName =
      'mojo::Geocoder';

abstract class Geocoder {
  Future<GeocoderAddressToLocationResponseParams> addressToLocation(String address,Options options,[Function responseFactory = null]);
  Future<GeocoderLocationToAddressResponseParams> locationToAddress(location_mojom.Location location,Options options,[Function responseFactory = null]);

}


class GeocoderProxyImpl extends bindings.Proxy {
  GeocoderProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  GeocoderProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  GeocoderProxyImpl.unbound() : super.unbound();

  static GeocoderProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new GeocoderProxyImpl.fromEndpoint(endpoint);

  String get name => GeocoderName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      case kGeocoder_addressToLocation_name:
        var r = GeocoderAddressToLocationResponseParams.deserialize(
            message.payload);
        if (!message.header.hasRequestId) {
          throw 'Expected a message with a valid request Id.';
        }
        Completer c = completerMap[message.header.requestId];
        if (c == null) {
          throw 'Message had unknown request Id: ${message.header.requestId}';
        }
        completerMap.remove(message.header.requestId);
        assert(!c.isCompleted);
        c.complete(r);
        break;
      case kGeocoder_locationToAddress_name:
        var r = GeocoderLocationToAddressResponseParams.deserialize(
            message.payload);
        if (!message.header.hasRequestId) {
          throw 'Expected a message with a valid request Id.';
        }
        Completer c = completerMap[message.header.requestId];
        if (c == null) {
          throw 'Message had unknown request Id: ${message.header.requestId}';
        }
        completerMap.remove(message.header.requestId);
        assert(!c.isCompleted);
        c.complete(r);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "GeocoderProxyImpl($superString)";
  }
}


class _GeocoderProxyCalls implements Geocoder {
  GeocoderProxyImpl _proxyImpl;

  _GeocoderProxyCalls(this._proxyImpl);
    Future<GeocoderAddressToLocationResponseParams> addressToLocation(String address,Options options,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new GeocoderAddressToLocationParams();
      params.address = address;
      params.options = options;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kGeocoder_addressToLocation_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<GeocoderLocationToAddressResponseParams> locationToAddress(location_mojom.Location location,Options options,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new GeocoderLocationToAddressParams();
      params.location = location;
      params.options = options;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kGeocoder_locationToAddress_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
}


class GeocoderProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  Geocoder ptr;
  final String name = GeocoderName;

  GeocoderProxy(GeocoderProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _GeocoderProxyCalls(proxyImpl);

  GeocoderProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new GeocoderProxyImpl.fromEndpoint(endpoint) {
    ptr = new _GeocoderProxyCalls(impl);
  }

  GeocoderProxy.fromHandle(core.MojoHandle handle) :
      impl = new GeocoderProxyImpl.fromHandle(handle) {
    ptr = new _GeocoderProxyCalls(impl);
  }

  GeocoderProxy.unbound() :
      impl = new GeocoderProxyImpl.unbound() {
    ptr = new _GeocoderProxyCalls(impl);
  }

  static GeocoderProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new GeocoderProxy.fromEndpoint(endpoint);

  Future close({bool nodefer: false}) => impl.close(nodefer: nodefer);

  String toString() {
    return "GeocoderProxy($impl)";
  }
}


class GeocoderStub extends bindings.Stub {
  Geocoder _impl = null;

  GeocoderStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  GeocoderStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  GeocoderStub.unbound() : super.unbound();

  static GeocoderStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new GeocoderStub.fromEndpoint(endpoint);

  static const String name = GeocoderName;


  GeocoderAddressToLocationResponseParams _GeocoderAddressToLocationResponseParamsFactory(String status, List<Result> results) {
    var result = new GeocoderAddressToLocationResponseParams();
    result.status = status;
    result.results = results;
    return result;
  }
  GeocoderLocationToAddressResponseParams _GeocoderLocationToAddressResponseParamsFactory(String status, List<Result> results) {
    var result = new GeocoderLocationToAddressResponseParams();
    result.status = status;
    result.results = results;
    return result;
  }

  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kGeocoder_addressToLocation_name:
        var params = GeocoderAddressToLocationParams.deserialize(
            message.payload);
        return _impl.addressToLocation(params.address,params.options,_GeocoderAddressToLocationResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kGeocoder_addressToLocation_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kGeocoder_locationToAddress_name:
        var params = GeocoderLocationToAddressParams.deserialize(
            message.payload);
        return _impl.locationToAddress(params.location,params.options,_GeocoderLocationToAddressResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kGeocoder_locationToAddress_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  Geocoder get impl => _impl;
      set impl(Geocoder d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "GeocoderStub($superString)";
  }
}


