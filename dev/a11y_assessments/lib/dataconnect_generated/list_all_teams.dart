part of 'generated.dart';

class ListAllTeamsVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListAllTeamsVariablesBuilder(this._dataConnect, );
  Deserializer<ListAllTeamsData> dataDeserializer = (dynamic json)  => ListAllTeamsData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListAllTeamsData, void>> execute() {
    return ref().execute();
  }

  QueryRef<ListAllTeamsData, void> ref() {
    
    return _dataConnect.query("ListAllTeams", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListAllTeamsTeams {
  final String id;
  final String name;
  final String? description;
  ListAllTeamsTeams.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']),
  description = json['description'] == null ? null : nativeFromJson<String>(json['description']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAllTeamsTeams otherTyped = other as ListAllTeamsTeams;
    return id == otherTyped.id && 
    name == otherTyped.name && 
    description == otherTyped.description;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode, description.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    if (description != null) {
      json['description'] = nativeToJson<String?>(description);
    }
    return json;
  }

  ListAllTeamsTeams({
    required this.id,
    required this.name,
    this.description,
  });
}

@immutable
class ListAllTeamsData {
  final List<ListAllTeamsTeams> teams;
  ListAllTeamsData.fromJson(dynamic json):
  
  teams = (json['teams'] as List<dynamic>)
        .map((e) => ListAllTeamsTeams.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAllTeamsData otherTyped = other as ListAllTeamsData;
    return teams == otherTyped.teams;
    
  }
  @override
  int get hashCode => teams.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teams'] = teams.map((e) => e.toJson()).toList();
    return json;
  }

  ListAllTeamsData({
    required this.teams,
  });
}

