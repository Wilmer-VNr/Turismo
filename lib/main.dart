import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_page.dart';
import 'publisher_page.dart';
import 'visitor_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase
  await Supabase.initialize(
    url: 'https://tfeuycmmuzxmlydubcde.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRmZXV5Y21tdXp4bWx5ZHViY2RlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE3NTk1ODYsImV4cCI6MjA2NzMzNTU4Nn0.GojXOMB1fVNr_63zRJLNIA16307CY8O4TM30qdJYxb0',
  );

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCLpbCvlKemjhpyYW549tmUMsAAKMUAQC4",
      authDomain: "movil25a.firebaseapp.com",
      projectId: "movil25a",
      storageBucket: "movil25a.firebasestorage.app",
      messagingSenderId: "544548734677",
      appId: "1:544548734677:web:310817784be0aca801c45c",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blog Turístico App',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<void> verificarYRedirigirSegunRol(BuildContext context) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      return;
    }

    try {
      final data = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single();

      final String role = data['role'];

      if (role == 'publicador') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PublisherPage()),
        );
      } else if (role == 'visitante') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const VisitorPage()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Rol desconocido: $role')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar perfil: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;

        if (session != null) {
          return FutureBuilder(
            future: verificarYRedirigirSegunRol(context),
            builder: (context, snapshot) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Cargando perfil...'),
                    ],
                  ),
                ),
              );
            },
          );
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
