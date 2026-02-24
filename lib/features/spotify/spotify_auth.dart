import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

import 'package:dragonfly/features/spotify/spotify_impl.dart';

final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());

final spotifyAuthProvider = StateNotifierProvider<SpotifyAuthNotifier, SpotifyAuthState>((ref) {
  return SpotifyAuthNotifier(ref.watch(secureStorageProvider));
});

class SpotifyAuthState {
  final String? accessToken;
  final String? refreshToken;
  final bool isLoading;

  SpotifyAuthState({this.accessToken, this.refreshToken, this.isLoading = false});

  SpotifyAuthState copyWith({String? accessToken, String? refreshToken, bool? isLoading}) {
    return SpotifyAuthState(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Handles the Spotify authentication flow using PKCE.
// Manages access and refresh tokens, storing them securely.
class SpotifyAuthNotifier extends StateNotifier<SpotifyAuthState> {
  final FlutterSecureStorage _storage;
  final String _clientId = 'a06a1cb0e61d489aa0ea1b8ebb930930';
  final String _redirectUri = 'com.ingramjam.dragonfly://callback';

  SpotifyAuthNotifier(this._storage) : super(SpotifyAuthState()) {
    _loadTokens();
  }

  // Load tokens from secure storage on startup.
  Future<void> _loadTokens() async {
    final accessToken = await _storage.read(key: 'spotify_access_token');
    final refreshToken = await _storage.read(key: 'spotify_refresh_token');
    state = state.copyWith(accessToken: accessToken, refreshToken: refreshToken);
  }

  // Kicks off the Spotify authentication process.
  Future<void> signIn() async {
    state = state.copyWith(isLoading: true);
    final codeVerifier = SpotifyImpl.generateCodeVerifier();
    await _storage.write(key: 'spotify_code_verifier', value: codeVerifier);
    final codeChallenge = SpotifyImpl.codeChallengeFromVerifier(codeVerifier);
    final url = SpotifyImpl.buildAuthorizeUrl(redirectUri: _redirectUri, codeChallenge: codeChallenge);
    
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    state = state.copyWith(isLoading: false);
  }

  // Exchanges the authorization code for an access token.
  Future<void> exchangeCodeForToken(String code) async {
    state = state.copyWith(isLoading: true);
    final codeVerifier = await _storage.read(key: 'spotify_code_verifier');
    if (codeVerifier == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': _clientId,
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': _redirectUri,
        'code_verifier': codeVerifier,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await _storage.write(key: 'spotify_access_token', value: data['access_token']);
      await _storage.write(key: 'spotify_refresh_token', value: data['refresh_token']);
      state = state.copyWith(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
        isLoading: false,
      );
    } else {
      // Handle error
      state = state.copyWith(isLoading: false);
    }
  }

  // Clears tokens from storage and logs the user out.
  Future<void> signOut() async {
    await _storage.delete(key: 'spotify_access_token');
    await _storage.delete(key: 'spotify_refresh_token');
    state = SpotifyAuthState();
  }
}
