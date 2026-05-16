class ExerciciResult {
  final double angleMaxim;
  final int repeticions;

  ExerciciResult({
    required this.angleMaxim,
    required this.repeticions,
  });

  factory ExerciciResult.fromMap(Map<dynamic, dynamic> map) {
    return ExerciciResult(
      angleMaxim: (map['angleMaxim'] as num? ?? 0.0).toDouble(),
      repeticions: (map['repeticions'] as num? ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'angleMaxim': angleMaxim,
      'repeticions': repeticions,
    };
  }
}

class SessionData {
  final String sessionId;
  final Map<String, ExerciciResult> results; // Guardat com a claus "ex1", "ex2", "ex3"

  SessionData({
    required this.sessionId,
    required this.results,
  });

  factory SessionData.fromMap(String id, Map<dynamic, dynamic> map) {
    final Map<String, ExerciciResult> parsedResults = {};
    map.forEach((key, value) {
      if ((key == 'ex1' || key == 'ex2' || key == 'ex3') && value is Map) {
        parsedResults[key.toString()] = ExerciciResult.fromMap(value);
      }
    });

    return SessionData(
      sessionId: id,
      results: parsedResults,
    );
  }
}