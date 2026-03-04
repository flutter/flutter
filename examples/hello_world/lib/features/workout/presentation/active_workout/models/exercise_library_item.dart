class ExerciseLibraryItem {
  const ExerciseLibraryItem({
    required this.id,
    required this.slug,
    required this.navnDa,
    required this.navnEn,
    required this.kategori,
    required this.bevaegelsesmoenster,
    required this.primaerMuskelgruppe,
    required this.udstyr,
    required this.niveau,
    required this.type,
  });

  final int id;
  final String slug;
  final String navnDa;
  final String navnEn;
  final String kategori;
  final String bevaegelsesmoenster;
  final String primaerMuskelgruppe;
  final String udstyr;
  final String niveau;
  final String type;

  factory ExerciseLibraryItem.fromJson(Map<String, dynamic> json) {
    return ExerciseLibraryItem(
      id: json['id'] as int,
      slug: json['slug'] as String,
      navnDa: json['navn_da'] as String,
      navnEn: json['navn_en'] as String,
      kategori: json['kategori'] as String,
      bevaegelsesmoenster: json['bevaegelsesmoenster'] as String,
      primaerMuskelgruppe: json['primaer_muskelgruppe'] as String,
      udstyr: json['udstyr'] as String,
      niveau: json['niveau'] as String,
      type: json['type'] as String,
    );
  }
}
