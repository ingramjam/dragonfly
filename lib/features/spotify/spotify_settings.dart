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
    if (!await canLaunchUrl(uri)) {
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Client ID (public):', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          SelectableText(SpotifyImpl.clientId),
          const SizedBox(height: 16),
          TextField(
            controller: _redirectController,
            decoration: const InputDecoration(labelText: 'Redirect URI'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _openAuth, child: const Text('Connect to Spotify (open browser)')),
          const SizedBox(height: 12),
          if (_lastUrl != null) ...[
            const Text('Auth URL (for debug):', style: TextStyle(fontWeight: FontWeight.w600)),
            SelectableText(_lastUrl!),
          ]
        ]),
      ),
    );
  }
}
