import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String _selectedExerciseKey = "ex1"; // Exercici seleccionat per defecte
  bool _isLoading = true;
  Map<String, dynamic> _sessionHistory = {};
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    try {
      final firebaseService = context.read<FirebaseService>();
      final data = await firebaseService.obtenirHistorialSessions();
      setState(() {
        _sessionHistory = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("El Teu Progrés")),
        body: Center(child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(_errorMessage, style: const TextStyle(color: AppTheme.errorRed), textAlign: TextAlign.center),
        )),
      );
    }

    // Ordenem les sessions cronològicament (sessio1, sessio2...) exigit per la spec
    final sortedSessionKeys = _sessionHistory.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    return Scaffold(
      appBar: AppBar(
        title: const Text("El Teu Progrés"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Evolució de l'Angle",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            
            // CORREGIT: 'initialValue' en comptes de 'value' per evitar obsolescència (deprecation)
            DropdownButtonFormField<String>(
              initialValue: _selectedExerciseKey,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: "ex1", child: Text("Exercici 1 — Lliscament de Taló")),
                DropdownMenuItem(value: "ex2", child: Text("Exercici 2 — Extensió en Arc Curt")),
                DropdownMenuItem(value: "ex3", child: Text("Exercici 3 — Sentadilles Assistides")),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedExerciseKey = value);
                }
              },
            ),
            const SizedBox(height: 24),

            // GRÀFIC 1: EVOLUCIÓ PER EXERCICI (LINE CHART)
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 220,
                  child: _buildLineChart(sortedSessionKeys),
                ),
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              "Rècords Absoluts",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppTheme.textDark),
            ),
            const SizedBox(height: 16),

            // GRÀFIC 2: MILLOR RÈCORD HISTÒRIC (BAR CHART)
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 200,
                  child: _buildBarChart(),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ESTADÍSTIQUES RESUM A SOTA
            _buildSummaryStats(sortedSessionKeys.length, sortedSessionKeys.isEmpty ? "Cap" : sortedSessionKeys.last),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(List<String> sortedKeys) {
    List<FlSpot> spots = [];

    for (int i = 0; i < sortedKeys.length; i++) {
      final sessionData = _sessionHistory[sortedKeys[i]];
      if (sessionData != null && sessionData['exercicis'] != null) {
        final List<dynamic> exercicis = sessionData['exercicis'];
        
        final exerciciFiltrat = exercicis.firstWhere(
          (e) => e != null && e['id'] == _selectedExerciseKey,
          orElse: () => null,
        );

        if (exerciciFiltrat != null && exerciciFiltrat['angleMaxim'] != null) {
          double angle = double.tryParse(exerciciFiltrat['angleMaxim'].toString()) ?? 0.0;
          spots.add(FlSpot(i.toDouble() + 1, angle));
        }
      }
    }

    if (spots.isEmpty) {
      return const Center(child: Text("Encara no hi ha dades per a aquest exercici.", style: TextStyle(color: Colors.grey)));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text("Sessió", style: TextStyle(fontSize: 12, color: Colors.grey)),
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (val, _) => Text(val.toInt().toString(), style: const TextStyle(fontSize: 10)),
            ),
          ),
          leftTitles: const AxisTitles(
            axisNameWidget: Text("Angle (°)", style: TextStyle(fontSize: 12, color: Colors.grey)),
            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.primaryBlue,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              // CORREGIT: Ús de .withValues per evitar pèrdua de precisió en versions modernes de Flutter
              color: AppTheme.primaryBlue.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    Map<String, double> recordsMaxims = {"ex1": 0.0, "ex2": 0.0, "ex3": 0.0};

    _sessionHistory.forEach((_, sessionData) {
      if (sessionData != null && sessionData['exercicis'] != null) {
        final List<dynamic> exercicis = sessionData['exercicis'];
        for (var ex in exercicis) {
          if (ex != null && ex['id'] != null && ex['angleMaxim'] != null) {
            String id = ex['id'].toString();
            double angle = double.tryParse(ex['angleMaxim'].toString()) ?? 0.0;
            if (recordsMaxims.containsKey(id) && angle > recordsMaxims[id]!) {
              recordsMaxims[id] = angle;
            }
          }
        }
      }
    });

    if (recordsMaxims.values.every((v) => v == 0.0)) {
      return const Center(child: Text("Encara no hi ha historial de sessions.", style: TextStyle(color: Colors.grey)));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly,
        maxY: 140,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        // CORREGIT: Agrupats correctament tots els títols dins de titlesData segons la nova versió de fl_chart
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                switch (value.toInt()) {
                  case 0: return const Text('Ex. 1', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold));
                  case 1: return const Text('Ex. 2', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold));
                  case 2: return const Text('Ex. 3', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold));
                  default: return const Text('');
                }
              },
            ),
          ),
        ),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: recordsMaxims["ex1"]!, color: AppTheme.primaryBlue, width: 22, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: recordsMaxims["ex2"]!, color: AppTheme.lightBlue, width: 22, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: recordsMaxims["ex3"]!, color: const Color(0xFF1976D2), width: 22, borderRadius: BorderRadius.circular(4))]),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(int total, String ultima) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // CORREGIT: També actualitzat amb .withValues aquí
        color: AppTheme.primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text("Total de sessions", style: TextStyle(color: Colors.grey, fontSize: 13)),
              Text("$total", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            ],
          ),
          const VerticalDivider(color: Colors.grey, thickness: 1),
          Column(
            children: [
              const Text("Última sessió", style: TextStyle(color: Colors.grey, fontSize: 13)),
              Text(ultima, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            ],
          ),
        ],
      ),
    );
  }
}