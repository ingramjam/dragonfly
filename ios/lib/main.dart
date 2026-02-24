import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart' as uuid;
import 'package:dragonfly/services/deep_link_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/spotify/spotify_settings.dart';
import 'package:dragonfly/services/bluetooth_service.dart';
import 'package:dragonfly/features/spotify/spotify_auth.dart';
import 'package:dragonfly/services/session_service.dart';



void main() {
  runApp(const ProviderScope(child: DragonFlyDemoApp()));
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
      home: DeepLinkHandler(
        child: const HomePage(),
      ),
      routes: {
        '/demo': (_) => const DemoPage(),
        '/spotify': (_) => const SpotifySettingsPage(),
      },
    );
  }
}

String generatePadId() {
  // Use UUID to create a friendly short pad id
  final id = const uuid.Uuid().v4();
  return id.split('-').first;
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final String padId;
  String? connectedBluetooth;
  final List<Map<String, String>> joinedDevices = [];
  @override
  void initState() {
    super.initState();
    padId = generatePadId();
  }

  void _createAndShareSession() async {
    final sessionManager = SessionManager(ref.read(firebaseDatabaseProvider), const uuid.Uuid().v4());
    final sessionId = await sessionManager.createSession();
    final joinLink = 'dragonfly://join/$sessionId';
    // Here you would use a share plugin to share the link
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share this link to join: $joinLink')));
  }

  @override
  Widget build(BuildContext context) {
    final spotifyState = ref.watch(spotifyAuthProvider);
    final bluetoothState = ref.watch(bluetoothServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('DragonFly Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Welcome to DragonFly',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            const Text('This demo shows a simulated Lily Pad host + scanner flow.', textAlign: TextAlign.center),
            const SizedBox(height: 24),

            // Lily Pad card with QR and actions
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(children: [
                  const Text('This device Lily Pad ID', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SelectableText(padId, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                      // Simple visual placeholder for QR (platform package mismatch caused build error).
                      // This shows the pad ID in a bordered box so the demo runs reliably on web.
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: SelectableText(padId, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontFamily: 'monospace')),
                        ),
                      ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.qr_code),
                        label: const Text('Open Demo (web)'),
                        onPressed: () => Navigator.of(context).pushNamed('/demo'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.music_note),
                        label: Text(spotifyState.accessToken != null ? 'Spotify Settings' : 'Login to Spotify'),
                        onPressed: () {
                          if (spotifyState.accessToken != null) {
                            Navigator.of(context).pushNamed('/spotify');
                          } else {
                            ref.read(spotifyAuthProvider.notifier).signIn();
                          }
                        },
                      ),
                    ],
                  ),
                ]),
              ),
            ),

            const SizedBox(height: 16),

            // Bluetooth card
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Text('Bluetooth', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(bluetoothState.connectedDevice == null ? 'Not connected' : 'Connected to: ${bluetoothState.connectedDevice!.name}'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (bluetoothState.isScanning) {
                        ref.read(bluetoothServiceProvider.notifier).stopScan();
                      } else {
                        ref.read(bluetoothServiceProvider.notifier).startScan();
                      }
                    },
                    child: Text(bluetoothState.isScanning ? 'Stop Scanning' : 'Scan for Devices'),
                  ),
                  if (bluetoothState.discoveredDevices.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView(
                        children: bluetoothState.discoveredDevices
                            .map((d) => ListTile(
                                  title: Text(d.name.isNotEmpty ? d.name : 'Unknown Device'),
                                  subtitle: Text(d.id),
                                  onTap: () => ref.read(bluetoothServiceProvider.notifier).connect(d),
                                ))
                            .toList(),
                      ),
                    )
                ]),
              ),
            ),

            const SizedBox(height: 12),

            // Joined devices list
            Expanded(
              child: Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Text('Joined Devices', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: joinedDevices.isEmpty
                          ? const Center(child: Text('No devices joined yet'))
                          : ListView.builder(
                              itemCount: joinedDevices.length,
                              itemBuilder: (context, idx) {
                                final d = joinedDevices[idx];
                                return ListTile(
                                  leading: const Icon(Icons.person),
                                  title: Text(d['name'] ?? 'Unknown'),
                                  subtitle: Text('Device: ${d['device'] ?? '-'}\nID: ${d['id'] ?? '-'}'),
                                  isThreeLine: true,
                                );
                              },
                            ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _createAndShareSession,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Create & Share Session'),
                    ),
                  ]),
                ),
              ),
            ),

            const SizedBox(height: 8),
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
