class Siswa {
  int id;
  String nama;
  int usia;

  Siswa({required this.id, required this.nama, required this.usia});

  factory Siswa.fromJson(Map<String, dynamic> json) {
    return Siswa(
      id: json['id'],
      nama: json['nama'],
      usia: json['usia'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'usia': usia,
  };
}
