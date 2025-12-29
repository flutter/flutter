part of 'generated.dart';

class CreateDemoUserVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  CreateDemoUserVariablesBuilder(this._dataConnect, );
  Deserializer<CreateDemoUserData> dataDeserializer = (dynamic json)  => CreateDemoUserData.fromJson(jsonDecode(json));
  
  Future<OperationResult<CreateDemoUserData, void>> execute() {
    return ref().execute();
  }

  MutationRef<CreateDemoUserData, void> ref() {
    
    return _dataConnect.mutation("CreateDemoUser", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class CreateDemoUserUserInsert {
  final String id;
  CreateDemoUserUserInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateDemoUserUserInsert otherTyped = other as CreateDemoUserUserInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateDemoUserUserInsert({
    required this.id,
  });
}

@immutable
class CreateDemoUserData {
  final CreateDemoUserUserInsert user_insert;
  CreateDemoUserData.fromJson(dynamic json):
  
  user_insert = CreateDemoUserUserInsert.fromJson(json['user_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateDemoUserData otherTyped = other as CreateDemoUserData;
    return user_insert == otherTyped.user_insert;
    
  }
  @override
  int get hashCode => user_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['user_insert'] = user_insert.toJson();
    return json;
  }

  CreateDemoUserData({
    required this.user_insert,
  });
}

