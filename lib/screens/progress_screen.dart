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

    // Ordenem les sessions cronològicament (sessio1, sessio2...)
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
                DropdownMenuItem(value: "ex4", child: Text("Exercici 4 — Flexió en Bipedestació")),
                DropdownMenuItem(value: "ex5", child: Text("Exercici 5 — Extensió Assegut")),
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
                  height: 220,
                  child: _buildBarChart(),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ESTADÍSTIQUES RESUM
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
      if (sessionData != null && sessionData[_selectedExerciseKey] != null) {
        final exData = sessionData[_selectedExerciseKey];
        if (exData['angle_maxim'] != null) {
          double angle = double.tryParse(exData['angle_maxim'].toString()) ?? 0.0;
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
              color: AppTheme.primaryBlue.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    Map<String, double> recordsMaxims = {"ex1": 0.0, "ex2": 0.0, "ex3": 0.0, "ex4": 0.0, "ex5": 0.0};

    _sessionHistory.forEach((_, sessionData) {
      if (sessionData != null) {
        recordsMaxims.forEach((exerciseKey, currentMax) {
          if (sessionData[exerciseKey] != null && sessionData[exerciseKey]['angle_maxim'] != null) {
            double angle = double.tryParse(sessionData[exerciseKey]['angle_maxim'].toString()) ?? 0.0;
            if (angle > currentMax) {
              recordsMaxims[exerciseKey] = angle;
            }
          }
        });
      }
    });

    if (recordsMaxims.values.every((v) => v == 0.0)) {
      return const Center(child: Text("Encara no hi ha historial de sessions.", style: TextStyle(color: Colors.grey)));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 120, 
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey[200]!,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35, 
              interval: 30,     
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    '${value.toInt()}°',
                    style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30, 
              getTitlesWidget: (double value, TitleMeta meta) {
                String text = '';
                switch (value.toInt()) {
                  case 0: text = 'Ex. 1'; break;
                  case 1: text = 'Ex. 2'; break;
                  case 2: text = 'Ex. 3'; break;
                  case 3: text = 'Ex. 4'; break;
                  case 4: text = 'Ex. 5'; break;
                }
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8, 
                  child: Text(
                    text,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: recordsMaxims["ex1"]!, color: AppTheme.primaryBlue, width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: recordsMaxims["ex2"]!, color: AppTheme.lightBlue, width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: recordsMaxims["ex3"]!, color: const Color(0xFF1976D2), width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]),
          BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: recordsMaxims["ex4"]!, color: Colors.orange, width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]),
          BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: recordsMaxims["ex5"]!, color: Colors.teal, width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(int total, String ultima) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
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