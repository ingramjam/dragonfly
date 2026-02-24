import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_links/uni_links.dart';
import 'package:flutter/foundation.dart';
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
    if (kIsWeb) return;
    
    // Check initial link
    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        _handleLink(initialLink);
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }

    // Listen to link stream
    _sub = linkStream.listen((String? link) {
      if (link != null) {
        _handleLink(link);
      }
    }, onError: (err) {
      debugPrint('Deep link error: $err');
    });
  }

  void _handleLink(String link) {
    debugPrint('Received deep link: $link');
    final uri = Uri.parse(link);
    // Handles Spotify auth callback
    if (uri.host == 'callback' && uri.queryParameters.containsKey('code')) {
      ref.read(spotifyAuthProvider.notifier).exchangeCodeForToken(uri.queryParameters['code']!);
    }
    // Handle join links
    else if (uri.host == 'join' && uri.pathSegments.isNotEmpty) {
      // Placeholder for joining logic
      final sessionId = uri.pathSegments.last;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Joining session: $sessionId')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
