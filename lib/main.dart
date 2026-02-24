import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const DragonFlyDemoApp());
}

class DragonFlyDemoApp extends StatelessWidget {
  const DragonFlyDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DragonFly Web Demo',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      routes: {
        '/': (_) => const HomePage(),
        '/demo': (_) => const DemoPage(),
      },
    );
  }
}

String generatePadId() {
  final rnd = Random();
  return List<int>.generate(6, (_) => rnd.nextInt(36))
      .map((n) => n.toRadixString(36)).join();
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final String padId;

  @override
  void initState() {
    super.initState();
    padId = generatePadId();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lily Pad — DragonFly (Demo)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Text('Welcome to DragonFly',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            const Text('This demo shows a simulated Lily Pad host + scanner flow.', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(children: [
                  const Text('This device Lily Pad ID', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SelectableText(padId, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code),
                    label: const Text('Open Demo (web)'),
                    onPressed: () => Navigator.of(context).pushNamed('/demo'),
                  ),
                ]),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'DragonFly Demo',
                  applicationVersion: '0.1',
                  children: [const Text('A small demo for the Lily Pad QR + scanner flow.')],
                );
              },
              child: const Text('About this demo'),
            ),
          ],
        ),
      ),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  final TextEditingController _controller = TextEditingController();
  String? lastScanned;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _simulateScan() {
    final code = _controller.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter an ID to simulate')));
      return;
    }
    setState(() => lastScanned = code);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Lily Pad Found'),
        content: Text('ID: $code'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demo — Scan Simulator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Simulate scanning a Lily Pad QR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(controller: _controller, decoration: const InputDecoration(labelText: 'Paste Lily Pad ID here')),
          const SizedBox(height: 12),
          ElevatedButton.icon(onPressed: _simulateScan, icon: const Icon(Icons.play_arrow), label: const Text('Simulate Scan')),
          const SizedBox(height: 20),
          Text('Last scanned: ${lastScanned ?? 'none'}'),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back')),
        ]),
      ),
    );
  }
}
