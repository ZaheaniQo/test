import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';

// TODO: Initialize Supabase with your project URL and anon key
// final supabase = Supabase.instance.client;

void main() {
  // TODO: Initialize Supabase
  runApp(const ParentApp());
}

class ParentApp extends StatelessWidget {
  const ParentApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parent App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      // For RTL support as required
      localizationsDelegates: const [
        // ... add RTL delegates
      ],
      supportedLocales: const [
        Locale('ar', ''), // Arabic
        Locale('en', ''), // English
      ],
      home: const ParentHomeScreen(),
    );
  }
}

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({Key? key}) : super(key: key);

  @override
  _ParentHomeScreenState createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const MapScreen(),
    const NotificationsScreen(),
    const ChatScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 3 // Show only on Settings screen
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OnboardingFormScreen()),
                );
              },
              child: const Icon(Icons.add),
              tooltip: 'Add Child',
            )
          : null,
    );
  }
}

class OnboardingFormScreen extends StatelessWidget {
  const OnboardingFormScreen({Key? key}) : super(key: key);

  void _submitForm() {
    // TODO: Create a JSON object with the form data
    final studentData = {
      "full_name": "Test Child",
      "grade": "3",
      "home_lat": 24.123,
      "home_lng": 46.456,
      "photo_url": null, // Would be an uploaded URL
      "home_photo_url": null, // Would be an uploaded URL
      "father_phone": "+966500000000",
      "mother_phone": "+966511111111",
    };
    // TODO: Call Supabase to insert into 'students_onboarding_requests'
    // supabase.from('students_onboarding_requests').insert({ 'parent_id': '...', 'student_data': studentData });
    print("Submitting onboarding form...");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register New Student')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(decoration: const InputDecoration(labelText: 'Child\'s Full Name')),
            const SizedBox(height: 12),
            TextFormField(decoration: const InputDecoration(labelText: 'Grade')),
            const SizedBox(height: 12),
            TextFormField(decoration: const InputDecoration(labelText: 'Home Latitude')),
            const SizedBox(height: 12),
            TextFormField(decoration: const InputDecoration(labelText: 'Home Longitude')),
            const SizedBox(height: 12),
            TextFormField(decoration: const InputDecoration(labelText: 'Father\'s Phone')),
            const SizedBox(height: 12),
            TextFormField(decoration: const InputDecoration(labelText: 'Mother\'s Phone')),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {}, // TODO: Implement image picking
              icon: const Icon(Icons.photo_camera),
              label: const Text('Upload Child Photo (Optional)'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {}, // TODO: Implement image picking
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Upload Home Entrance Photo'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitForm,
              child: const Text('Submit Request'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            )
          ],
        ),
      ),
    );
  }
}

// ----------------- SCREENS -----------------

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Mock bus location
  // LatLng _busLocation = const LatLng(24.7200, 46.6820);
  bool _showAttendanceCard = true; // Mock visibility

  @override
  void initState() {
    super.initState();
    // TODO: Subscribe to Supabase Realtime channel for location updates
    // supabase
    //   .channel('public:locations:trip_id=eq.YOUR_TRIP_ID')
    //   .on<Map<String, dynamic>>(
    //     'postgres_changes',
    //     (payload) {
    //       final newLocation = payload['new'];
    //       setState(() {
    //         _busLocation = LatLng(newLocation['lat'], newLocation['lng']);
    //       });
    //     },
    //     filter: SupabaseEventTypes.insert,
    //   ).subscribe();

    // TODO: Fetch attendance confirmation status for tomorrow
  }

  Future<void> _submitAttendance(String status) async {
    // TODO: Call the 'submit-attendance' Edge Function
    // final response = await supabase.functions.invoke(
    //   'submit-attendance',
    //   body: {
    //      'student_id': 'd1d8e7e3-6f4f-7b1a-1d5b-8f9c1e0d2g3b', // Mock student ID
    //      'date': 'YYYY-MM-DD', // Tomorrow's date
    //      'status': status,
    //   },
    // );
    print('Submitting attendance as: $status');
    setState(() {
      _showAttendanceCard = false;
    });
  }

  Widget _buildAttendanceCard() {
    return Positioned(
      top: 10,
      left: 10,
      right: 10,
      child: Card(
        color: Colors.amber[100],
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text("هل سيحضر ابنك ليان الزهراني غدًا؟", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _submitAttendance('confirmed'),
                    child: Text("نعم"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                  ElevatedButton(
                    onPressed: () => _submitAttendance('absent'),
                    child: Text("لا"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Bus Tracking')),
      body: Stack(
        children: [
          // Placeholder for Google Map
          Container(
            color: Colors.grey[200],
            child: const Center(
              child: Text(
                'Google Map Placeholder',
                style: TextStyle(fontSize: 20, color: Colors.grey),
              ),
            ),
          ),
          // Placeholder for bus marker
          // Positioned( ... child: Icon(Icons.directions_bus) ... )

          // Attendance card
          if (_showAttendanceCard) _buildAttendanceCard(),

          // Child status overlay
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Layan Al-Zahrani: Picked Up', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Mazen Al-Zahrani: Approaching (200m)'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  // Mock notifications
  final List<Map<String, String>> _notifications = const [
    { 'title': 'Bus is approaching!', 'subtitle': 'Your stop is next.', 'time': '6:28 AM' },
    { 'title': 'Bus has arrived.', 'subtitle': 'Please be ready at the pickup point.', 'time': '6:30 AM' },
    { 'title': 'Layan was picked up.', 'subtitle': 'Successfully onboard.', 'time': '6:31 AM' },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return ListTile(
            leading: const Icon(Icons.notifications_active),
            title: Text(notification['title']!),
            subtitle: Text(notification['subtitle']!),
            trailing: Text(notification['time']!),
          );
        },
      ),
    );
  }
}

class ChatScreen extends StatelessWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat with Driver')),
      body: const Center(child: Text('Chat UI Placeholder')),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: const [
          ListTile(title: Text('Notification Settings'), trailing: Icon(Icons.arrow_forward_ios)),
          ListTile(title: Text('Manage Children'), trailing: Icon(Icons.arrow_forward_ios)),
          ListTile(title: Text('Language (AR/EN)'), trailing: Icon(Icons.arrow_forward_ios)),
          ListTile(title: Text('Privacy Policy'), trailing: Icon(Icons.arrow_forward_ios)),
        ],
      ),
    );
  }
}
