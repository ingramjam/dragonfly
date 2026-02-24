import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'spotify_impl.dart';

class SpotifySettingsPage extends StatefulWidget {
  const SpotifySettingsPage({super.key});

  @override
  State<SpotifySettingsPage> createState() => _SpotifySettingsPageState();
}

class _SpotifySettingsPageState extends State<SpotifySettingsPage> {
  final TextEditingController _redirectController = TextEditingController(text: 'com.ingramjam.dragonfly://callback');
  String? _lastUrl;

  @override
  void dispose() {
    _redirectController.dispose();
    super.dispose();
  }

  Future<void> _openAuth() async {
    final redirect = _redirectController.text.trim();
    if (redirect.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter the redirect URI')));
      return;
    }
    final verifier = SpotifyImpl.generateCodeVerifier();
    final challenge = SpotifyImpl.codeChallengeFromVerifier(verifier);
    final url = SpotifyImpl.buildAuthorizeUrl(redirectUri: redirect, codeChallenge: challenge);
    setState(() => _lastUrl = url);
    final uri = Uri.parse(url);
    if (!mounted) return;
    if (!await canLaunchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot open browser on this platform')));
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    // Note: after redirect, capture the incoming URI via deep link handling
    // and call token exchange with the stored verifier.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spotify Settings')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('PKCE Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              const Text('Client ID (public):', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 6),
              SelectableText(SpotifyImpl.clientId, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              
              TextField(
                controller: _redirectController,
                decoration: const InputDecoration(labelText: 'Redirect URI (Must match Spotify Dashboard)'),
              ),
              const SizedBox(height: 24),
              
              const Text('This screen is for debugging the raw PKCE flow manually.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 24),
              
              ElevatedButton.icon(
                onPressed: _openAuth,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Connect to Spotify (open browser)'),
              ),
              if (_lastUrl != null) ...[
                const SizedBox(height: 24),
                const Text('Auth URL (for debug):', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SelectableText(_lastUrl!, style: const TextStyle(fontSize: 10, fontFamily: 'Courier', color: Colors.grey)),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
