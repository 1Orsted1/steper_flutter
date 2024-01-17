import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Steper'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final health = HealthFactory();
  List<(String, DateTime, DateTime)> stepsByWeek = [];
  int? stepsToday;

  Future<List<(String, DateTime, DateTime)>?> _getStepsData() async {
    final activityPermission = await Permission.activityRecognition.request();
    //final locationPersmission = await Permission.location.request();
    if (activityPermission.isGranted) {
      //&& locationPersmission.isGranted) {
      bool requested =
          await health.requestAuthorization([HealthDataType.STEPS]);
      List<(String, DateTime, DateTime)> steps = [];
      if (requested) {
        final weekDays = getWeeksDays();
        for (var element in weekDays) {
          final healthData = await health.getTotalStepsInInterval(
            element.$1,
            element.$2,
          );
          steps.add((
            healthData == null ? "0" : healthData.toString(),
            element.$1,
            element.$2,
          ));
        }
        setState(() {
          stepsByWeek = steps;
        });
        return steps;
      }
    }
    return null;
  }

  List<(DateTime, DateTime)> getWeeksDays() {
    DateTime now = DateTime.now();

    // Find the first day of the current month
    DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);

    // Calculate the current week number
    int currentWeek = ((now.day - firstDayOfMonth.day) / 7).ceil();

    // Calculate the starting and ending days for each week
    List<(DateTime, DateTime)> weekDays = [];
    for (int week = currentWeek; week > 0; week--) {
      DateTime startOfWeek =
          firstDayOfMonth.add(Duration(days: (week - 1) * 7));
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
      weekDays.add((startOfWeek, endOfWeek));
    }
    return weekDays;
  }

  void _todaySteps() async {
    final activityPermission = await Permission.activityRecognition.request();
    //final locationPersmission = await Permission.location.request();
    if (activityPermission.isGranted) {
      //&& locationPersmission.isGranted) {
      bool requested =
          await health.requestAuthorization([HealthDataType.STEPS]);
      if (requested) {
        final now = DateTime.now();
        final DateTime startDay = DateTime(
          now.year,
          now.month,
          now.day,
        );
        final stptoday = await health.getTotalStepsInInterval(
          startDay,
          now,
        );
        setState(() {
          stepsToday = stptoday;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var format = DateFormat.yMMMd();
    final List<Widget> steps = (stepsByWeek.isEmpty)
        ? []
        : stepsByWeek
            .map(
              (e) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("steps from"),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(format.format(e.$2)),
                          const Text("to"),
                          Text(format.format(e.$3)),
                        ],
                      ),
                      const Padding(padding: EdgeInsets.all(8)),
                      Text("${(e.$1)}(7 days)"),
                    ],
                  ),
                ),
              ),
            )
            .toList();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: ListView(
        // mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(padding: EdgeInsets.all(32)),
          const Center(
            child: Text(
              'push the button to get the information:',
              style: TextStyle(fontSize: 18),
            ),
          ),
          (stepsToday == null)
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(child: Text("STEPS TODAY :$stepsToday")),
                ),
          ElevatedButton(
              onPressed: _todaySteps, child: const Text("GetStepsToday")),
          ...steps
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getStepsData,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
