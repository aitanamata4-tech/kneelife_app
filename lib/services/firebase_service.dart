import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class KneeLifeFirebaseException implements Exception {
  final String message;
  KneeLifeFirebaseException(this.message);
  @override
  String toString() => message;
}

class FirebaseService {
  // Patró Singleton mantingut per especificació
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  /// NOTA DE SEGURETAT PER AL DESENVOLUPADOR:
  /// Recorda configurar les regles de Firebase Realtime Database de la següent forma:
  /// {
  ///   "rules": {
  ///     "Sessions": {
  ///       "$uid": {
  ///         ".read": "$uid === auth.uid",
  ///         ".write": "$uid === auth.uid"
  ///       }
  ///     },
  ///     "Assignacions": {
  ///       "$uid": {
  ///         ".read": "$uid === auth.uid",
  ///         ".write": "$uid === auth.uid"
  ///       }
  ///     },
  ///     "Exercicis": {
  ///       ".read": "auth !== null",
  ///       ".write": "false"
  ///     },
  ///     "Usuaris": {
  ///       "$uid": {
  ///         ".read": "$uid === auth.uid",
  ///         ".write": "$uid === auth.uid"
  ///       }
  ///     }
  ///   }
  /// }

  // 1. GESTIÓ DE USUARIS: Guardar dades del nou usuari al registrar-se
  Future<void> registrarDadesUsuari({required String nom, required String cognom, required String email}) async {
    final uid = currentUid;
    if (uid == null) throw KneeLifeFirebaseException("No hi ha cap usuari autenticat.");

    try {
      await _db.ref("Usuaris/$uid").set({
        "nom": nom,
        "cognom": cognom,
        "email": email,
        "dataRegistre": DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw KneeLifeFirebaseException("Error en desar les dades de l'usuari: $e");
    }
  }

  // 2. MANUAL: Descarregar la llista completa d'exercicis disponibles
  Future<List<Map<String, dynamic>>> descarrregarExercicis() async {
    try {
      final snapshot = await _db.ref("Exercicis").get();
      if (!snapshot.exists || snapshot.value == null) return [];

      final List<Map<String, dynamic>> llista = [];
      
      if (snapshot.value is List) {
        final listData = snapshot.value as List<dynamic>;
        for (int i = 0; i < listData.length; i++) {
          if (listData[i] != null) {
            final map = Map<String, dynamic>.from(listData[i] as Map);
            map['id'] = i.toString();
            llista.add(map);
          }
        }
      } else if (snapshot.value is Map) {
        final mapData = snapshot.value as Map<dynamic, dynamic>;
        mapData.forEach((key, value) {
          final map = Map<String, dynamic>.from(value as Map);
          map['id'] = key.toString();
          llista.add(map);
        });
      }

      return llista;
    } catch (e) {
      throw KneeLifeFirebaseException("No s'ha pogut obtenir el manual d'exercicis: $e");
    }
  }

  // 3. CLINICA: Llegir l'exercici objectiu assignat pel fisioterapeuta
  Future<Map<String, dynamic>?> obtenirAssignacioClinica() async {
    final uid = currentUid;
    if (uid == null) throw KneeLifeFirebaseException("No hi ha cap usuari autenticat.");

    try {
      final snapshot = await _db.ref("Assignacions/$uid").get();
      if (!snapshot.exists || snapshot.value == null) return null;

      return Map<String, dynamic>.from(snapshot.value as Map);
    } catch (e) {
      throw KneeLifeFirebaseException("Error en obtenir l'assignació clínica: $e");
    }
  }

  // 4. HISTORIAL DE SESSIONS MASSIVES DINÀMIQUES (CORREGIT)
  // En lloc de sobreescriure amb valors estàtics de prova, rep la llista d'exercicis
  // reals fets pel pacient i els munta de forma neta per enviar-los a Firebase.
  Future<void> pujarSessio({
    required Map<String, Map<String, dynamic>> resultatsExercicis,
    required int nivellDolorGeneral,
  }) async {
    final uid = currentUid;
    if (uid == null) throw KneeLifeFirebaseException("No hi ha cap usuari autenticat.");

    try {
      final refSessions = _db.ref("Sessions/$uid");
      final snapshot = await refSessions.get();
      
      int recompteSessions = 0;
      if (snapshot.exists && snapshot.value != null) {
        if (snapshot.value is Map) {
          recompteSessions = (snapshot.value as Map).length;
        } else if (snapshot.value is List) {
          recompteSessions = (snapshot.value as List).where((e) => e != null).length;
        }
      }

      final novaClauSessio = "sessio${recompteSessions + 1}";

      // Mapegem l'estructura arrel amb la data actual en format ISO
      final Map<String, dynamic> dadesSessio = {
        'data': DateTime.now().toIso8601String(),
      };

      // Mapegem de forma dinàmica només els exercicis completats a la pantalla
      resultatsExercicis.forEach((exId, dades) {
        dadesSessio[exId] = {
          'angle_maxim': dades['angle_maxim'],
          'repeticions': dades['repeticions'],
          'dolor': dades['dolor'] ?? nivellDolorGeneral,
        };
      });

      await refSessions.child(novaClauSessio).set(dadesSessio);
      debugPrint("Sessió dinàmica desada correctament a /Sessions/$uid/$novaClauSessio");
    } catch (e) {
      throw KneeLifeFirebaseException("No s'ha pogut pujar la sessió completa a Firebase: $e");
    }
  }

  // Mètode original mantingut per compatibilitat amb altres pantalles existents
  Future<void> pujarResultatsSessio({
    required List<Map<String, dynamic>> exercicisCompletats,
    required int valoracioDolor,
  }) async {
    final uid = currentUid;
    if (uid == null) throw KneeLifeFirebaseException("No hi ha cap usuari autenticat.");

    try {
      final refSessions = _db.ref("Sessions/$uid");
      final snapshot = await refSessions.get();
      
      int recompteSessions = 0;
      if (snapshot.exists && snapshot.value != null) {
        if (snapshot.value is Map) {
          recompteSessions = (snapshot.value as Map).length;
        } else if (snapshot.value is List) {
          recompteSessions = (snapshot.value as List).where((e) => e != null).length;
        }
      }

      final novaClauSessio = "sessio${recompteSessions + 1}";

      await refSessions.child(novaClauSessio).set({
        "data": DateTime.now().toIso8601String(),
        "valoracioDolor": valoracioDolor,
        "exercicis": exercicisCompletats,
      });

      debugPrint("Sessió desada correctament a Firebase amb la clau: $novaClauSessio");
    } catch (e) {
      throw KneeLifeFirebaseException("No s'ha pogut pujar la sessió a la base de dades: $e");
    }
  }

  // 5. GRÀFICS: Escoltador o descàrrega de tot l'historial de sessions per a les gràfiques
  Future<Map<String, dynamic>> obtenirHistorialSessions() async {
    final uid = currentUid;
    if (uid == null) throw KneeLifeFirebaseException("No hi ha cap usuari autenticat.");

    try {
      final snapshot = await _db.ref("Sessions/$uid").get();
      if (!snapshot.exists || snapshot.value == null) return {};

      return Map<String, dynamic>.from(snapshot.value as Map);
    } catch (e) {
      throw KneeLifeFirebaseException("Error en carregar l'historial de sessions: $e");
    }
  }
}