import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Charts',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChartPage(),
    );
  }
}

class ChartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Charts'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              ChartContainer(child: PieChartWidget()),
              SizedBox(height: 40),
              ChartContainer(child: BarChartWidget()),
              SizedBox(height: 100),
              ChartContainer(child: RadarChartWidget()),
            ],
          ),
        ),
      ),
    );
  }
}

class ChartContainer extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final double borderWidth;
  final BorderRadius borderRadius;

  const ChartContainer({
    Key? key,
    required this.child,
    this.borderColor = Colors.black,
    this.borderWidth = 2.0,
    this.borderRadius = BorderRadius.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: borderRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: child,
      ),
    );
  }
}

class PieData {
  final String label;
  final double value;

  PieData(this.label, this.value);

  factory PieData.fromJson(Map<String, dynamic> json) {
    return PieData(
      json['label'],
      json['value'].toDouble(),
    );
  }
}

class BarData {
  final String label;
  final double value1;
  final double value2;

  BarData(this.label, this.value1, this.value2);

  factory BarData.fromJson(Map<String, dynamic> json) {
    return BarData(
      json['label'],
      json['value1'].toDouble(),
      json['value2'].toDouble(),
    );
  }
}

class RadarData {
  final String label;
  final List<double> values;

  RadarData(this.label, this.values);

  factory RadarData.fromJson(Map<String, dynamic> json) {
    List<double> values = List<double>.from(json['values'].map((value) => value.toDouble()));
    return RadarData(json['label'], values);
  }
}

Future<Map<String, dynamic>> loadChartData() async {
  final String response = await rootBundle.loadString('assets/data.json');
  final Map<String, dynamic> data = jsonDecode(response);
  return data;
}

Future<List<PieData>> loadPieData() async {
  final data = await loadChartData();
  final List<dynamic> pieData = data['pieChartData'];
  return pieData.map((json) => PieData.fromJson(json)).toList();
}

Future<List<BarData>> loadBarData() async {
  final data = await loadChartData();
  final List<dynamic> barData = data['barChartData'];
  return barData.map((json) => BarData.fromJson(json)).toList();
}

Future<List<RadarData>> loadRadarData() async {
  final data = await loadChartData();
  final List<dynamic> radarDataList = data['radarChartData'];
  final List<RadarData> radarData = [];

  for (var radarSet in radarDataList) {
    radarSet.forEach((key, value) {
      radarData.add(RadarData.fromJson(value));
    });
  }

  return radarData;
}

class PieChartWidget extends StatefulWidget {
  @override
  _PieChartWidgetState createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<PieChartWidget> {
  late Future<List<PieData>> futurePieData;
  int touchedIndex = -1;
  List<Color> colors = [];

  @override
  void initState() {
    super.initState();
    futurePieData = loadPieData();
  }

  Color getRandomColor() {
    final Random random = Random();
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PieData>>(
      future: futurePieData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No data available'));
        } else {
          if (colors.isEmpty) {
            colors = List.generate(snapshot.data!.length, (index) => getRandomColor());
          }

          return Column(
            children: [
              PieChartWithLegend(
                data: snapshot.data!,
                colors: colors,
                isDoughnut: false,
                touchedIndex: touchedIndex,
                onTouched: (index) {
                  setState(() {
                    touchedIndex = index;
                  });
                },
              ),
              SizedBox(height: 60),
              PieChartWithLegend(
                data: snapshot.data!,
                colors: colors,
                isDoughnut: true,
                touchedIndex: touchedIndex,
                onTouched: (index) {
                  setState(() {
                    touchedIndex = index;
                  });
                },
              ),
            ],
          );
        }
      },
    );
  }
}

class PieChartWithLegend extends StatelessWidget {
  final List<PieData> data;
  final List<Color> colors;
  final bool isDoughnut;
  final int touchedIndex;
  final Function(int) onTouched;

  const PieChartWithLegend({
    Key? key,
    required this.data,
    required this.colors,
    required this.isDoughnut,
    required this.touchedIndex,
    required this.onTouched,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<PieChartSectionData> sections = data.asMap().entries.map((entry) {
      int index = entry.key;
      PieData data = entry.value;
      final isTouched = index == touchedIndex;
      final double fontSize = isTouched ? 25 : 16;
      final double radius = isTouched ? 80 : 60;
      return PieChartSectionData(
        value: data.value,
        title: '${data.value}%',
        radius: isDoughnut ? (isTouched ? 70 : 50) : radius,
        color: colors[index],
        borderSide: BorderSide(
          color: Colors.white,
          width: 2,
        ),
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 0,
                centerSpaceRadius: isDoughnut ? 40 : 0,
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
                    if (!event.isInterestedForInteractions || response == null || response.touchedSection == null) {
                      onTouched(-1);
                      return;
                    }
                    onTouched(response.touchedSection!.touchedSectionIndex);
                  },
                ),
              ),
            ),
          ),
          SizedBox(width: 20),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.asMap().entries.map((entry) {
              int index = entry.key;
              PieData data = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      color: colors[index],
                    ),
                    SizedBox(width: 8),
                    Text('${data.label}: ${data.value}%', style: TextStyle(fontSize: 16)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class BarChartWidget extends StatefulWidget {
  @override
  _BarChartWidgetState createState() => _BarChartWidgetState();
}

class _BarChartWidgetState extends State<BarChartWidget> {
  late Future<List<BarData>> futureBarData;
  List<Color> barColors = [];

  @override
  void initState() {
    super.initState();
    futureBarData = loadBarData();
  }

  Color getRandomColor() {
    final Random random = Random();
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BarData>>(
      future: futureBarData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No data available'));
        } else {
          if (barColors.isEmpty) {
            barColors = List.generate(snapshot.data!.length * 2, (index) => getRandomColor());
          }

          final barGroups = snapshot.data!.asMap().entries.map((entry) {
            int index = entry.key;
            BarData data = entry.value;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: data.value1,
                  color: barColors[index * 2],
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: data.value2,
                  color: barColors[index * 2 + 1],
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
              barsSpace: 4,
            );
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 300,
                  height: 300,
                  child: BarChart(
                    BarChartData(
                      barGroups: barGroups,
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true, interval: 10, reservedSize: 40),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                            const style = TextStyle(color: Color(0xFF7589A2), fontWeight: FontWeight.bold, fontSize: 14);
                            Widget text;
                            switch (value.toInt()) {
                              case 0:
                                text = const Text('A', style: style);
                                break;
                              case 1:
                                text = const Text('B', style: style);
                                break;
                              case 2:
                                text = const Text('C', style: style);
                                break;
                              case 3:
                                text = const Text('D', style: style);
                                break;
                              case 4:
                                text = const Text('E', style: style);
                                break;
                              default:
                                text = const Text('', style: style);
                                break;
                            }
                            return SideTitleWidget(axisSide: meta.axisSide, space: 8.0, child: text);
                          }),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(show: true),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
                SizedBox(width: 20),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: snapshot.data!.asMap().entries.map((entry) {
                    int index = entry.key;
                    BarData data = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            color: barColors[index * 2],
                          ),
                          SizedBox(width: 4),
                          Text('${data.label} Value 1: ${data.value1}', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 8),
                          Container(
                            width: 16,
                            height: 16,
                            color: barColors[index * 2 + 1],
                          ),
                          SizedBox(width: 4),
                          Text('${data.label} Value 2: ${data.value2}', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}

class RadarChartWidget extends StatefulWidget {
  @override
  _RadarChartWidgetState createState() => _RadarChartWidgetState();
}

class _RadarChartWidgetState extends State<RadarChartWidget> {
  late Future<List<RadarData>> futureRadarData;
  List<Color> radarColors = [];

  @override
  void initState() {
    super.initState();
    futureRadarData = loadRadarData();
  }

  Color getRandomColor() {
    final Random random = Random();
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RadarData>>(
      future: futureRadarData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No data available'));
        } else {
          if (radarColors.isEmpty) {
            radarColors = List.generate(snapshot.data!.length, (index) => getRandomColor());
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 300,
                  height: 300,
                  child: RadarChart(
                    RadarChartData(
                      dataSets: snapshot.data!.asMap().entries.map((entry) {
                        int index = entry.key;
                        RadarData data = entry.value;
                        return RadarDataSet(
                          dataEntries: data.values.map((value) => RadarEntry(value: value)).toList(),
                          borderColor: radarColors[index],
                          fillColor: radarColors[index].withOpacity(0.3),
                          entryRadius: 2,
                          borderWidth: 2,
                        );
                      }).toList(),
                      radarBackgroundColor: Colors.transparent,
                      borderData: FlBorderData(show: false),
                      radarBorderData: BorderSide(color: Colors.blue, width: 2),
                      titlePositionPercentageOffset: 0.2,
                      getTitle: (index, angle) {
                        return RadarChartTitle(
                          text: snapshot.data![0].values[index].toString(),
                          angle: angle,
                        );
                      },
                      tickCount: 5,
                      tickBorderData: BorderSide(color: Colors.grey, width: 1),
                      gridBorderData: BorderSide(color: Colors.grey, width: 1),
                    ),
                  ),
                ),
                SizedBox(width: 20),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: snapshot.data!.asMap().entries.map((entry) {
                    int index = entry.key;
                    RadarData data = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            color: radarColors[index],
                          ),
                          SizedBox(width: 4),
                          Text('${data.label}: ${data.values.join(', ')}', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}

