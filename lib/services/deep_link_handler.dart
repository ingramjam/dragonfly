import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';

import 'package:dragonfly/features/spotify/spotify_auth.dart';
import 'package:dragonfly/services/session_service.dart';
import 'package:dragonfly/providers.dart';

class DeepLinkHandler extends ConsumerStatefulWidget {
  final Widget child;
  const DeepLinkHandler({super.key, required this.child});

  @override
  ConsumerState<DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends ConsumerState<DeepLinkHandler> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _initUniLinks();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _initUniLinks() async {
    _sub = linkStream.listen((String? link) {
      if (link != null) {
        final uri = Uri.parse(link);
        // Handles Spotify auth callback
        if (uri.host == 'callback' && uri.queryParameters.containsKey('code')) {
          ref.read(spotifyAuthProvider.notifier).exchangeCodeForToken(uri.queryParameters['code']!);
        }
        // Handle join links
        if (uri.host == 'join' && uri.pathSegments.isNotEmpty) {
          final sessionId = uri.pathSegments.first;
          final sessionManager = SessionManager(ref.read(firebaseDatabaseProvider), ref.read(uuidProvider).v4());
          sessionManager.joinSession(sessionId);
          // Here you would navigate to a session page
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Joining session: $sessionId')));
          }
        }
      }
    }, onError: (err) {
      // Handle exception by warning the user their action did not succeed
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
