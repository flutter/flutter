import 'package:flutter/material.dart';

class UserModel {
  int id;
  String codeName;
  String name;
  String major;

  UserModel(this.id, this.codeName, this.name, this.major);
}

class ItemUser extends StatelessWidget {
  final int index;
  final UserModel data;

  ItemUser(this.index, this.data);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 24, left: 16, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.lightBlue,
            child: Text(
              data.codeName,
              style: TextStyle(color: Colors.white),
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    data.name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 2),
                    child: Text(data.major),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<UserModel> data = [
  UserModel(1, "IK", "Ikhwan Koto", "Sistem Informasi"),
  UserModel(2, "PA", "Pake Arrayid", "Fisika"),
  UserModel(3, "RK", "Ryan Kimo", "Olah Raga"),
  UserModel(4, "AM", "Arif Mahran", "Biologi"),
  UserModel(5, "NH", "Nurrahman Hado", "Sistem Komputer"),
  UserModel(6, "AN", "Ade Nuri", "Psikologi"),
  UserModel(7, "FC", "Fitriani Chairi", "Ilmu Komputer"),
  UserModel(8, "EA", "Elsa Aprilio", "Teknik Mesin"),
  UserModel(9, "PC", "Putri Coti", "Teknik Industri"),
  UserModel(10, "SE", "deni ", "Geografi"),
];

class UserListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("User List"),
      ),
      body: ListView.builder(
        padding: EdgeInsets.only(bottom: 24),
        itemCount: data.length,
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
            child: ItemUser(index, data[index]),
            onTap: () {
              // Do something
            },
          );
        },
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: UserListScreen(),
  ));
}
