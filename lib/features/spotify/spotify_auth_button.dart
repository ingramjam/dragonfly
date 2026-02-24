
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dragonfly/features/spotify/spotify_auth.dart';

class SpotifyAuthButton extends ConsumerWidget {
  const SpotifyAuthButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(spotifyAuthProvider);

    return ElevatedButton(
      onPressed: () {
        if (authState.accessToken == null) {
          ref.read(spotifyAuthProvider.notifier).signIn();
        } else {
          ref.read(spotifyAuthProvider.notifier).signOut();
        }
      },
      child: Text(authState.accessToken == null ? 'Login with Spotify' : 'Logout'),
    );
  }
}
