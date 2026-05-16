class AssignacioExercici {
  final int angleObjectiu;
  final int repeticions;

  AssignacioExercici({
    required this.angleObjectiu,
    required this.repeticions,
  });

  factory AssignacioExercici.fromMap(Map<dynamic, dynamic> map) {
    return AssignacioExercici(
      angleObjectiu: (map['angleObjectiu'] as num? ?? 0).toInt(),
      repeticions: (map['repeticions'] as num? ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'angleObjectiu': angleObjectiu,
      'repeticions': repeticions,
    };
  }
}

class Assignacio {
  final AssignacioExercici ex1;
  final AssignacioExercici ex2;
  final AssignacioExercici ex3;

  Assignacio({
    required this.ex1,
    required this.ex2,
    required this.ex3,
  });

  factory Assignacio.fromMap(Map<dynamic, dynamic> map) {
    return Assignacio(
      ex1: AssignacioExercici.fromMap(map['ex1'] as Map? ?? {}),
      ex2: AssignacioExercici.fromMap(map['ex2'] as Map? ?? {}),
      ex3: AssignacioExercici.fromMap(map['ex3'] as Map? ?? {}),
    );
  }

  // Mètode per obtenir l'exercici que vulguem a partir de la seva clau ("ex1", "ex2" o "ex3")
  AssignacioExercici getByKey(String key) {
    switch (key) {
      case 'ex1':
        return ex1;
      case 'ex2':
        return ex2;
      case 'ex3':
        return ex3;
      default:
        throw Exception("Clau d'exercici incorrecta: $key");
    }
  }
}