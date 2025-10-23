import 'package:flutter/material.dart';
import 'dart:io';

class ResultPage extends StatelessWidget {
  final String nama;
  final String email;
  final String umur;
  final String gender;
  final String status;
  final List<String> hobi;
  final File imageFile;

  const ResultPage({
    super.key,
    required this.nama,
    required this.email,
    required this.umur,
    required this.gender,
    required this.status,
    required this.hobi,
    required this.imageFile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: Text('Hasil Input'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: FileImage(imageFile),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Data yang Anda Masukkan',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800),
                  ),
                  SizedBox(height: 20),
                  ListTile(
                    leading: Icon(Icons.person, color: Colors.teal),
                    title: Text('Nama Lengkap'),
                    subtitle: Text(nama),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.email, color: Colors.teal),
                    title: Text('Email'),
                    subtitle: Text(email),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.cake, color: Colors.teal),
                    title: Text('Umur'),
                    subtitle: Text('$umur tahun'),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.wc, color: Colors.teal),
                    title: Text('Jenis Kelamin'),
                    subtitle: Text(gender),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.school, color: Colors.teal),
                    title: Text('Status Mahasiswa'),
                    subtitle: Text(status),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.favorite, color: Colors.teal),
                    title: Text('Hobi'),
                    subtitle: Text(hobi.isNotEmpty
                        ? hobi.join(', ')
                        : 'Tidak ada hobi yang dipilih'),
                  ),
                  SizedBox(height: 30),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Icon(Icons.arrow_back),
                    label: Text('Kembali ke Form'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}