import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart' as uuid;
import 'package:dragonfly/services/deep_link_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/spotify/spotify_settings.dart';
import 'package:dragonfly/services/bluetooth_service.dart';
import 'package:dragonfly/features/spotify/spotify_auth.dart';
import 'package:dragonfly/services/session_service.dart';
import 'package:dragonfly/theme.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart'; 



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // conditional init if we had the options generated
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: DragonFlyDemoApp()));
}

class DragonFlyDemoApp extends StatelessWidget {
  const DragonFlyDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DragonFly',
      debugShowCheckedModeBanner: false,
      theme: DragonflyTheme.darkTheme,
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Session Created! Link: $joinLink'),
      action: SnackBarAction(label: 'Copy', onPressed: () {}),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final spotifyState = ref.watch(spotifyAuthProvider);
    final bluetoothState = ref.watch(bluetoothServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emergency_recording, color: DragonflyTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('DRAGONFLY'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Host Console',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: 1.5),
                textAlign: TextAlign.center
              ),
              const SizedBox(height: 24),

              // Lily Pad Card
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 24),
                    padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text('LILY PAD ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2, color: DragonflyTheme.primaryColor)),
                        const SizedBox(height: 12),
                        SelectableText(
                          padId,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Courier'),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: 180,
                          height: 180,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.qr_code_2, size: 80, color: Colors.black),
                                const SizedBox(height: 8),
                                Text(padId, style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12.0,
                          runSpacing: 12.0,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.open_in_browser),
                              label: const Text('Web Demo'),
                              onPressed: () => Navigator.of(context).pushNamed('/demo'),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: spotifyState.accessToken != null ? const Color(0xFF1DB954) : null,
                                foregroundColor: spotifyState.accessToken != null ? Colors.white : Colors.black,
                              ),
                              icon: const Icon(Icons.music_note),
                              label: Text(spotifyState.accessToken != null ? 'Spotify Connected' : 'Connect Spotify'),
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
                      ],
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      shape: BoxShape.circle,
                      border: Border.all(color: DragonflyTheme.primaryColor, width: 2),
                      boxShadow: [
                         BoxShadow(color: DragonflyTheme.primaryColor.withOpacity(0.3), blurRadius: 12, spreadRadius: 2),
                      ]
                    ),
                    child: const Icon(Icons.hub, color: Colors.white),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              
              const Text('Hardware', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // Bluetooth card
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF252525),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.bluetooth, color: Colors.blueAccent),
                      ),
                      title: const Text('Bluetooth Scanner'),
                      subtitle: Text(bluetoothState.isScanning ? 'Scanning...' : (bluetoothState.connectedDevice != null ? 'Connected' : 'Idle')),
                      trailing: Switch(
                        value: bluetoothState.isScanning,
                        activeColor: Colors.blueAccent,
                        onChanged: (val) {
                           if (val) {
                             ref.read(bluetoothServiceProvider.notifier).startScan();
                           } else {
                             ref.read(bluetoothServiceProvider.notifier).stopScan();
                           }
                        },
                      ),
                    ),
                    if (bluetoothState.connectedDevice != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text('Connected to: ${bluetoothState.connectedDevice!.name}', style: const TextStyle(color: Colors.greenAccent)),
                      ),
                    if (bluetoothState.isScanning && bluetoothState.discoveredDevices.isNotEmpty)
                      Container(
                        height: 150,
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black26, 
                          borderRadius: BorderRadius.circular(12)
                        ),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: bluetoothState.discoveredDevices.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, idx) {
                            final d = bluetoothState.discoveredDevices[idx];
                            return ListTile(
                              dense: true,
                              title: Text(d.name.isNotEmpty ? d.name : 'Unknown Device', style: const TextStyle(fontWeight: FontWeight.w500)),
                              subtitle: Text(d.id, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              trailing: const Icon(Icons.chevron_right, size: 16),
                              onTap: () => ref.read(bluetoothServiceProvider.notifier).connect(d),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              const Text('Session Members', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // Joined devices list
              Container(
                 decoration: BoxDecoration(
                  color: const Color(0xFF252525),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    if (joinedDevices.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(child: Text('No devices joined yet\nShare the link to invite others.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))),
                      )
                    else 
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: joinedDevices.length,
                        itemBuilder: (context, idx) {
                          final d = joinedDevices[idx];
                          return ListTile(
                            leading: const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.person, color: Colors.white)),
                            title: Text(d['name'] ?? 'Unknown'),
                            subtitle: Text('Device: ${d['device'] ?? '-'}'),
                          );
                        },
                      ),
                    
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.white10))
                      ),
                      child: TextButton.icon(
                        onPressed: _createAndShareSession,
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Invite People'),
                        style: TextButton.styleFrom(foregroundColor: DragonflyTheme.accentColor), 
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              Center(
                child: TextButton(
                  onPressed: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'DragonFly Demo',
                      applicationVersion: '0.1',
                      children: [const Text('A small demo for the Lily Pad QR + scanner flow.')],
                    );
                  },
                  child: const Text('Version 0.1 (Alpha)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
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
