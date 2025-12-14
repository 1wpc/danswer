import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }
  
  Future<void> refreshProfile() async {
    await _fetchProfile();
  }
}
