import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  User? _user;
  Map<String, dynamic>? _profile;
  bool _isLoading = false;

  User? get user => _user;
  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;
  
  bool get isLoggedIn => _user != null;
  bool get isPremium => _profile?['subscription_tier'] == 'premium';
  bool get isBasic => _profile?['subscription_tier'] == 'basic';
  bool get isPaidUser => isPremium || isBasic;

  AuthService() {
    _init();
  }

  Future<void> _init() async {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final Session? session = data.session;
      
      _user = session?.user;
      if (_user != null) {
        _fetchProfile();
      } else {
        _profile = null;
      }
      notifyListeners();
    });
  }

  Future<void> _fetchProfile() async {
    if (_user == null) return;
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', _user!.id)
          .single();
      _profile = data;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      await Supabase.instance.client.auth.signUp(email: email, password: password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      await Supabase.instance.client.auth.signInWithPassword(email: email, password: password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Configure GoogleSignIn
      // Note: For iOS/Android, ensure you have configured the Google Cloud Console and added the SHA-1 (Android) / URL Scheme (iOS)
      // and Client IDs if necessary.
      // Usually default constructor works if native config is correct.
      // For Supabase to verify the token, a Web Client ID (serverClientId) might be needed if not configured in Supabase dashboard for Android.
      // But typically with signInWithIdToken, we just need the ID token.
      
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled
        return;
      }
      
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'No ID Token found.';
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      
      // Explicitly update user state immediately after sign in
      _user = Supabase.instance.client.auth.currentUser;
      if (_user != null) {
        await _fetchProfile();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Google Sign In Error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    final googleSignIn = GoogleSignIn();
    if (await googleSignIn.isSignedIn()) {
      await googleSignIn.signOut();
    }
    await Supabase.instance.client.auth.signOut();
  }
  
  Future<void> refreshProfile() async {
    await _fetchProfile();
  }
}
