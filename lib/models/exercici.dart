class Exercici {
  final String id; // "ex1", "ex2", "ex3"
  final String nom;
  final String descripcio;

  Exercici({
    required this.id,
    required this.nom,
    required this.descripcio,
  });

  // Serveix per transformar les dades que venen de Firebase (Map) en un objecte de Dart
  factory Exercici.fromMap(String id, Map<dynamic, dynamic> map) {
    return Exercici(
      id: id,
      nom: map['nom'] as String? ?? '',
      descripcio: map['descripcio'] as String? ?? '',
    );
  }

  // Serveix per si mai s'han d'enviar les dades en format Map
  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'descripcio': descripcio,
    };
  }
}