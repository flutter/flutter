import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'result_page.dart';

class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  _FormPageState createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _umurController = TextEditingController();

  String? _selectedGender;
  String? _statusMahasiswa;
  final Map<String, bool> _hobi = {
    'Membaca': false,
    'Olahraga': false,
    'Menulis': false,
    'Gaming': false,
  };

  
  // Reset semua data form
  void _resetForm() {
    _formKey.currentState?.reset();
    _namaController.clear();
    _emailController.clear();
    _umurController.clear();
    _selectedGender = null;
    _statusMahasiswa = null;
    _selectedImage = null;
    _hobi.updateAll((key, value) => false);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Form berhasil direset!'),
        backgroundColor: Colors.teal,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Validasi data lengkap
  bool _isFormComplete() {
    return _formKey.currentState!.validate() &&
        _statusMahasiswa != null &&
        _selectedGender != null &&
        _selectedImage != null;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_pin, size: 70, color: Colors.teal),
                    SizedBox(height: 10),
                    Text(
                      'Form Biodata',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                    SizedBox(height: 25),

                    // Foto Profil
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (_) => Container(
                            padding: EdgeInsets.all(16),
                            height: 160,
                            child: Column(
                              children: [
                                Text('Pilih Sumber Foto',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _ambilDariKamera();
                                      },
                                      icon: Icon(Icons.camera_alt),
                                      label: Text('Kamera'),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _ambilDariGaleri();
                                      },
                                      icon: Icon(Icons.photo),
                                      label: Text('Galeri'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.teal.shade200,
                        backgroundImage:
                            _selectedImage != null ? FileImage(_selectedImage!) : null,
                        child: _selectedImage == null
                            ? Icon(Icons.camera_alt,
                                size: 40, color: Colors.white)
                            : null,
                      ),
                    ),
                    SizedBox(height: 20),
                    if (_selectedImage == null)
                      Text(
                        'Belum ada foto diunggah',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    SizedBox(height: 20),

                    // Input Nama
                    TextFormField(
                      controller: _namaController,
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.teal.shade50,
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Nama wajib diisi' : null,
                    ),
                    SizedBox(height: 16),

                    // Input Email
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.teal.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Email wajib diisi';
                        if (!value.contains('@')) return 'Format email tidak valid';
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Input Umur
                    TextFormField(
                      controller: _umurController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Umur',
                        prefixIcon: Icon(Icons.cake),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.teal.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Umur wajib diisi';
                        if (int.tryParse(value) == null) {
                          return 'Umur harus berupa angka';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Dropdown Jenis Kelamin
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      decoration: InputDecoration(
                        labelText: 'Jenis Kelamin',
                        prefixIcon: Icon(Icons.wc),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.teal.shade50,
                      ),
                      items: [
                        DropdownMenuItem(value: 'Laki-laki', child: Text('Laki-laki')),
                        DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Pilih jenis kelamin' : null,
                    ),
                    SizedBox(height: 16),

                    // Radio Status Mahasiswa
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status Mahasiswa:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                value: 'Aktif',
                                groupValue: _statusMahasiswa,
                                title: Text('Aktif'),
                                onChanged: (value) {
                                  setState(() => _statusMahasiswa = value);
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                value: 'Cuti',
                                groupValue: _statusMahasiswa,
                                title: Text('Cuti'),
                                onChanged: (value) {
                                  setState(() => _statusMahasiswa = value);
                                },
                              ),
                            ),
                          ],
                        ),
                        if (_statusMahasiswa == null)
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0, top: 4),
                            child: Text('Pilih salah satu status',
                                style:
                                    TextStyle(color: Colors.red[700], fontSize: 13)),
                          ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Checkbox Hobi
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pilih Hobi:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        ..._hobi.keys.map((String key) {
                          return CheckboxListTile(
                            title: Text(key),
                            value: _hobi[key],
                            activeColor: Colors.teal,
                            onChanged: (bool? value) {
                              setState(() {
                                _hobi[key] = value ?? false;
                              });
                            },
                          );
                        }),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Tombol Kirim & Reset
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: Icon(Icons.send),
                            label: Text('Kirim Data'),
                            onPressed: () {
                              if (_isFormComplete()) {
                                List<String> selectedHobi = _hobi.entries
                                    .where((entry) => entry.value)
                                    .map((entry) => entry.key)
                                    .toList();

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ResultPage(
                                      nama: _namaController.text,
                                      email: _emailController.text,
                                      umur: _umurController.text,
                                      gender: _selectedGender!,
                                      status: _statusMahasiswa!,
                                      hobi: selectedHobi,
                                      imageFile: _selectedImage!,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Lengkapi semua biodata dan unggah foto terlebih dahulu!'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: Icon(Icons.refresh),
                            label: Text('Reset'),
                            onPressed: _resetForm,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
   File? _selectedImage; // Menyimpan gambar yang diambil/dipilih
  final ImagePicker _picker = ImagePicker();

  // Ambil foto dari kamera
  Future<void> _ambilDariKamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Pilih foto dari galeri
  Future<void> _ambilDariGaleri() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }
}