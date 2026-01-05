part of 'generated.dart';

class ListMyTeamsVariablesBuilder {
  ListMyTeamsVariablesBuilder(this._dataConnect, );
  
  final FirebaseDataConnect _dataConnect;
  Deserializer<ListMyTeamsData> dataDeserializer = (dynamic json)  => ListMyTeamsData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListMyTeamsData, void>> execute() {
    return ref().execute();
  }

  QueryRef<ListMyTeamsData, void> ref() {
    
    return _dataConnect.query('ListMyTeams', dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListMyTeamsTeams {

  ListMyTeamsTeams({
    required this.id,
    required this.name,
    this.description,
  });
  ListMyTeamsTeams.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']),
  description = json['description'] == null ? null : nativeFromJson<String>(json['description']);
  final String id;
  final String name;
  final String? description;
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListMyTeamsTeams otherTyped = other as ListMyTeamsTeams;
    return id == otherTyped.id && 
    name == otherTyped.name && 
    description == otherTyped.description;
    
  }
  @override
  int get hashCode => Object.hashAll(<Object?>[id.hashCode, name.hashCode, description.hashCode]);
  

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    if (description != null) {
      json['description'] = nativeToJson<String?>(description);
    }
    return json;
  }
}

@immutable
class ListMyTeamsData {

  ListMyTeamsData({
    required this.teams,
  });
  ListMyTeamsData.fromJson(dynamic json):
  
  teams = (json['teams'] as List<dynamic>)
        .map((e) => ListMyTeamsTeams.fromJson(e))
        .toList();
  final List<ListMyTeamsTeams> teams;
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListMyTeamsData otherTyped = other as ListMyTeamsData;
    return teams == otherTyped.teams;
    
  }
  @override
  int get hashCode => teams.hashCode;
  

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['teams'] = teams.map((ListMyTeamsTeams e) => e.toJson()).toList();
    return json;
  }
}

