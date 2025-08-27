import 'package:flutter/material.dart';

void main() {
  // TODO: Initialize Supabase
  runApp(const SupervisorApp());
}

class SupervisorApp extends StatelessWidget {
  const SupervisorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supervisor App',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: const SupervisorHomeScreen(),
    );
  }
}

class SupervisorHomeScreen extends StatefulWidget {
  const SupervisorHomeScreen({Key? key}) : super(key: key);

  @override
  _SupervisorHomeScreenState createState() => _SupervisorHomeScreenState();
}

class _SupervisorHomeScreenState extends State<SupervisorHomeScreen> {
  // Mock data for the supervisor's view
  final String _busPlate = 'ح ب أ-1234';
  final List<Map<String, dynamic>> _students = [
    { 'name': 'ليان الزهراني', 'status': 'picked_up', 'attendance': 'confirmed' },
    { 'name': 'مازن الزهراني', 'status': 'arrived', 'attendance': 'confirmed' },
    { 'name': 'طالب آخر', 'status': 'pending', 'attendance': 'absent' },
  ];

  @override
  void initState() {
    super.initState();
    // TODO:
    // 1. Fetch supervisor's assigned bus.
    // 2. Fetch students for that bus's current trip.
    // 3. Subscribe to Supabase Realtime for trip events and location updates.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bus Supervisor: $_busPlate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () { /* Show notifications screen */ },
          ),
        ],
      ),
      body: Column(
        children: [
          // Placeholder for a small map view
          Container(
            height: 200,
            color: Colors.grey[300],
            child: const Center(child: Text('Live Map View Placeholder')),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Student Monitoring', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          // List of students on the bus
          Expanded(
            child: ListView.builder(
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      student['attendance'] == 'confirmed' ? Icons.check_circle : Icons.cancel,
                      color: student['attendance'] == 'confirmed' ? Colors.green : Colors.red,
                    ),
                    title: Text(student['name']),
                    subtitle: Text('Status: ${student['status']}'),
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
