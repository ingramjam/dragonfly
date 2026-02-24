import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class SpotifyImpl {
  static const String clientId = 'a06a1cb0e61d489aa0ea1b8ebb930930';

  /// Generate a high-entropy code verifier for PKCE (43-128 characters).
  static String generateCodeVerifier([int length = 64]) {
    final rand = Random.secure();
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    return List<int>.generate(length, (_) => charset.codeUnitAt(rand.nextInt(charset.length)))
        .map((c) => String.fromCharCode(c))
        .join();
  }

  /// Compute the base64-url-encoded SHA256 code challenge for [verifier].
  static String codeChallengeFromVerifier(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes).bytes;
    final challenge = base64UrlEncode(digest).replaceAll('=', '');
    return challenge;
  }

  static String buildAuthorizeUrl({required String redirectUri, required String codeChallenge, String scope = 'user-read-playback-state user-modify-playback-state user-read-currently-playing'}) {
    final params = {
      'client_id': clientId,
      'response_type': 'code',
      'redirect_uri': redirectUri,
      'code_challenge_method': 'S256',
      'code_challenge': codeChallenge,
      'scope': scope,
    };
    final query = params.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');
    return 'https://accounts.spotify.com/authorize?$query';
  }
}
