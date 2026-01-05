part of 'generated.dart';

class UpdatePlayerJerseyNumberVariablesBuilder {
  UpdatePlayerJerseyNumberVariablesBuilder(this._dataConnect, {required  this.id,required  this.jerseyNumber,});
  String id;
  int jerseyNumber;

  final FirebaseDataConnect _dataConnect;
  Deserializer<UpdatePlayerJerseyNumberData> dataDeserializer = (dynamic json)  => UpdatePlayerJerseyNumberData.fromJson(jsonDecode(json));
  Serializer<UpdatePlayerJerseyNumberVariables> varsSerializer = (UpdatePlayerJerseyNumberVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdatePlayerJerseyNumberData, UpdatePlayerJerseyNumberVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdatePlayerJerseyNumberData, UpdatePlayerJerseyNumberVariables> ref() {
    final UpdatePlayerJerseyNumberVariables vars= UpdatePlayerJerseyNumberVariables(id: id,jerseyNumber: jerseyNumber,);
    return _dataConnect.mutation('UpdatePlayerJerseyNumber', dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdatePlayerJerseyNumberPlayerUpdate {

  UpdatePlayerJerseyNumberPlayerUpdate({
    required this.id,
  });
  UpdatePlayerJerseyNumberPlayerUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  final String id;
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdatePlayerJerseyNumberPlayerUpdate otherTyped = other as UpdatePlayerJerseyNumberPlayerUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['id'] = nativeToJson<String>(id);
    return json;
  }
}

@immutable
class UpdatePlayerJerseyNumberData {

  UpdatePlayerJerseyNumberData({
    this.player_update,
  });
  UpdatePlayerJerseyNumberData.fromJson(dynamic json):
  
  player_update = json['player_update'] == null ? null : UpdatePlayerJerseyNumberPlayerUpdate.fromJson(json['player_update']);
  final UpdatePlayerJerseyNumberPlayerUpdate? player_update;
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdatePlayerJerseyNumberData otherTyped = other as UpdatePlayerJerseyNumberData;
    return player_update == otherTyped.player_update;
    
  }
  @override
  int get hashCode => player_update.hashCode;
  

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (player_update != null) {
      json['player_update'] = player_update!.toJson();
    }
    return json;
  }
}

@immutable
class UpdatePlayerJerseyNumberVariables {

  UpdatePlayerJerseyNumberVariables({
    required this.id,
    required this.jerseyNumber,
  });
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdatePlayerJerseyNumberVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  jerseyNumber = nativeFromJson<int>(json['jerseyNumber']);
  final String id;
  final int jerseyNumber;
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdatePlayerJerseyNumberVariables otherTyped = other as UpdatePlayerJerseyNumberVariables;
    return id == otherTyped.id && 
    jerseyNumber == otherTyped.jerseyNumber;
    
  }
  @override
  int get hashCode => Object.hashAll(<Object?>[id.hashCode, jerseyNumber.hashCode]);
  

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['id'] = nativeToJson<String>(id);
    json['jerseyNumber'] = nativeToJson<int>(jerseyNumber);
    return json;
  }
}

