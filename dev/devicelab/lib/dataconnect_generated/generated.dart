library dataconnect_generated;
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'create_demo_user.dart';

part 'list_all_teams.dart';

part 'update_player_jersey_number.dart';

part 'list_my_teams.dart';







class ExampleConnector {
  
  
  CreateDemoUserVariablesBuilder createDemoUser () {
    return CreateDemoUserVariablesBuilder(dataConnect, );
  }
  
  
  ListAllTeamsVariablesBuilder listAllTeams () {
    return ListAllTeamsVariablesBuilder(dataConnect, );
  }
  
  
  UpdatePlayerJerseyNumberVariablesBuilder updatePlayerJerseyNumber ({required String id, required int jerseyNumber, }) {
    return UpdatePlayerJerseyNumberVariablesBuilder(dataConnect, id: id,jerseyNumber: jerseyNumber,);
  }
  
  
  ListMyTeamsVariablesBuilder listMyTeams () {
    return ListMyTeamsVariablesBuilder(dataConnect, );
  }
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'us-central1',
    'example',
    'scholesa-edu-2',
  );

  ExampleConnector({required this.dataConnect});
  static ExampleConnector get instance {
    return ExampleConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}
