import 'package:flutter/material.dart';

// TODO: Import Supabase and other dependencies
// import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // TODO: Initialize Supabase
  // WidgetsFlutterBinding.ensureInitialized();
  // await Supabase.initialize(url: 'YOUR_URL', anonKey: 'YOUR_KEY');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Bus App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // The initial route will be a splash/loading screen that determines
      // the user's authentication state and role.
      home: const AuthWrapper(),
    );
  }
}

// This widget will wrap the logic for checking auth state and role.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // TODO: Listen to Supabase auth state changes
    // Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    //   final AuthChangeEvent event = data.event;
    //   if (event == AuthChangeEvent.signedIn) {
    //     _redirectUser();
    //   }
    // });
  }

  Future<void> _redirectUser() async {
    // In a real app, this would be asynchronous.
    // 1. Wait for the session to be available.
    // await Future.delayed(Duration.zero);

    // 2. Get the JWT and decode it to find the custom claim for the role.
    // final accessToken = Supabase.instance.client.auth.currentSession?.accessToken;
    // if (accessToken == null) {
    //   // User is not signed in, show login screen
    //   Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    //   return;
    // }
    // final decodedToken = ... decode JWT ...
    // final String userRole = decodedToken['app_role'] ?? 'parent'; // Default to parent for safety

    // MOCK: Simulate role-based routing
    const userRole = 'parent'; // Change to 'driver' to test the other flow

    if (userRole == 'driver') {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const DriverHomeScreen()));
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ParentHomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    // A simple loading screen while we check the auth state.
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// --- Placeholder Screens ---

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Login Screen')));
  }
}

// TODO: Move these screens into their respective feature folders
// e.g., features/parent/presentation/screens/home_screen.dart

class ParentHomeScreen extends StatelessWidget {
  const ParentHomeScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppBar(title: Text('Parent Dashboard')),
      body: Center(child: Text('Parent View: Map, Notifications, etc.')),
    );
  }
}

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppBar(title: Text('Driver Dashboard')),
      body: Center(child: Text('Driver View: Start/End Trip, Student List, etc.')),
    );
  }
}
