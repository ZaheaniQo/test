import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// TODO: Initialize Supabase with your project URL and anon key
// final supabase = Supabase.instance.client;

void main() {
  // TODO: Ensure Flutter bindings are initialized
  // WidgetsFlutterBinding.ensureInitialized();

  // TODO: Initialize Supabase
  // await Supabase.initialize(
  //   url: 'YOUR_SUPABASE_URL',
  //   anonKey: 'YOUR_SUPABASE_ANON_KEY',
  // );

  runApp(const DriverApp());
}

class DriverApp extends StatelessWidget {
  const DriverApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Driver App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // For RTL support as required
      localizationsDelegates: const [
        // ... add RTL delegates
      ],
      supportedLocales: const [
        Locale('ar', ''), // Arabic
        Locale('en', ''), // English
      ],
      home: const DriverHomeScreen(),
    );
  }
}

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({Key? key}) : super(key: key);

  @override
  _DriverHomeScreenState createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  String _tripStatus = 'scheduled'; // Mock status
  final String _tripId = 'a0a1b2b3-4c5d-6e7f-8a9b-0c1d2e3f4g5h'; // Mock trip ID from seed

  // Mock list of stops for the demo route, now with attendance status
  // TODO: This data should be fetched by joining trips -> routes -> stops -> attendance_confirmations
  final List<Map<String, dynamic>> _stops = [
    { 'id': 'stop_1_uuid', 'student_id': 'd1d8e7e3-6f4f-7b1a-1d5b-8f9c1e0d2g3b', 'name': 'ليان الزهراني', 'status': 'pending', 'attendance': 'confirmed' },
    { 'id': 'stop_2_uuid', 'student_id': 'e2e9f8f4-7a5a-8c2b-2e6c-9aa02f1e3h4c', 'name': 'مازن الزهراني', 'status': 'pending', 'attendance': 'absent' },
    { 'id': 'stop_3_uuid', 'student_id': 'some_other_uuid', 'name': 'طالب آخر', 'status': 'pending', 'attendance': 'no_response' },
  ];

  Future<void> _startTrip() async {
    // TODO: Call the 'trip-start' Edge Function
    // final response = await supabase.functions.invoke(
    //   'trip-start',
    //   body: { 'trip_id': _tripId },
    // );
    // if (response.error == null) {
    //   setState(() => _tripStatus = 'in_progress');
    // }
    print('Calling trip-start function for trip $_tripId');
    setState(() => _tripStatus = 'in_progress');
  }

  Future<void> _finishTrip() async {
    // TODO: Call the 'trip-finish' Edge Function
    // final response = await supabase.functions.invoke(
    //   'trip-finish',
    //   body: { 'trip_id': _tripId },
    // );
    // if (response.error == null) {
    //   setState(() => _tripStatus = 'completed');
    // }
    print('Calling trip-finish function for trip $_tripId');
    setState(() => _tripStatus = 'completed');
  }

  Future<void> _handleDriverEvent(String stopId, String studentId, String eventType) async {
    // TODO: Call the 'event-driver' Edge Function
    // final response = await supabase.functions.invoke(
    //   'event-driver',
    //   body: {
    //      'trip_id': _tripId,
    //      'stop_id': stopId,
    //      'student_id': studentId,
    //      'event_type': eventType,
    //   },
    // );
    print('Calling event-driver: $eventType for student $studentId');
    setState(() {
      final stop = _stops.firstWhere((s) => s['id'] == stopId);
      stop['status'] = eventType;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          // Placeholder for Chat
          IconButton(onPressed: () {}, icon: const Icon(Icons.chat)),
          // Placeholder for BG Location Toggle
          Switch(value: true, onChanged: (val) {}),
        ],
      ),
      body: Column(
        children: [
          // Trip controls
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _tripStatus == 'scheduled' ? _startTrip : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Trip'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                ElevatedButton.icon(
                  onPressed: _tripStatus == 'in_progress' ? _finishTrip : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Finish Trip'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ),
          Text('Trip Status: $_tripStatus', style: Theme.of(context).textTheme.headline6),
          const Divider(),
          // Stops list
          Expanded(
            child: ListView.builder(
              itemCount: _stops.length,
              itemBuilder: (context, index) {
                final stop = _stops[index];
                final attendanceStatus = stop['attendance'];

                Widget attendanceIcon;
                switch (attendanceStatus) {
                  case 'confirmed':
                    attendanceIcon = Icon(Icons.check_circle, color: Colors.green, semanticLabel: 'Confirmed');
                    break;
                  case 'absent':
                    attendanceIcon = Icon(Icons.cancel, color: Colors.red, semanticLabel: 'Absent');
                    break;
                  default:
                    attendanceIcon = Icon(Icons.help_outline, color: Colors.grey, semanticLabel: 'No Response');
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  // Make the card visually distinct for absent students
                  color: attendanceStatus == 'absent' ? Colors.grey[300] : null,
                  child: ListTile(
                    leading: Wrap(
                      spacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        attendanceIcon,
                        CircleAvatar(child: Text('${index + 1}')),
                      ]
                    ),
                    title: Text(stop['name'], style: TextStyle(decoration: attendanceStatus == 'absent' ? TextDecoration.lineThrough : null)),
                    subtitle: Text('Driver Action: ${stop['status']}'),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        // Big buttons for quick actions
                        IconButton(onPressed: () => _handleDriverEvent(stop['id'], stop['student_id'], 'arrived'), icon: const Icon(Icons.location_on), tooltip: 'Arrived'),
                        IconButton(onPressed: () => _handleDriverEvent(stop['id'], stop['student_id'], 'picked_up'), icon: const Icon(Icons.check_circle), color: Colors.green, tooltip: 'Picked Up'),
                        IconButton(onPressed: () => _handleDriverEvent(stop['id'], stop['student_id'], 'absent'), icon: const Icon(Icons.cancel), color: Colors.orange, tooltip: 'Absent'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
