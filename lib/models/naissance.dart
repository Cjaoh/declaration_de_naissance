class Naissance {
  final int? id;
  final String nom;
  final String prenom;
  final DateTime dateNaissance;
  final String lieu;
  final String sexe;
  final bool synced;

  Naissance({
    this.id,
    required this.nom,
    required this.prenom,
    required this.dateNaissance,
    required this.lieu,
    required this.sexe,
    this.synced = false,
  });

  factory Naissance.fromMap(Map<String, dynamic> map) => Naissance(
        id: map['id'],
        nom: map['nom'],
        prenom: map['prenom'],
        dateNaissance: DateTime.parse(map['dateNaissance']),
        lieu: map['lieu'],
        sexe: map['sexe'],
        synced: map['synced'] == 1,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nom': nom,
        'prenom': prenom,
        'dateNaissance': dateNaissance.toIso8601String(),
        'lieu': lieu,
        'sexe': sexe,
        'synced': synced ? 1 : 0,
      };
}