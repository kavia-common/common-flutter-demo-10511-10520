import 'package:flutter/material.dart';

void main() {
  runApp(const CommonFlutterDemoApp());
}

class CommonFlutterDemoApp extends StatelessWidget {
  const CommonFlutterDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.indigo);

    return MaterialApp(
      title: 'Common Flutter Demo',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/': (_) => const HomeScreen(),
        '/detail': (_) => const DetailScreen(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = List<String>.generate(10, (i) => 'Demo item ${i + 1}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            title: Text(item),
            subtitle: const Text('Tap to view details'),
            onTap: () => Navigator.of(context).pushNamed('/detail'),
          );
        },
      ),
    );
  }
}

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail'),
      ),
      body: const Center(
        child: Text(
          'Detail screen placeholder.\n\nNext step: biometric + device security flow migration.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
