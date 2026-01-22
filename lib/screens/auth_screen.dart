import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../l10n/app_localizations.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Sign Up'), // TODO: Localize
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value?.isEmpty ?? true ? 'Please enter email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value != null && value.length < 6 ? 'Password too short' : null,
              ),
              const SizedBox(height: 24),
              if (authService.isLoading)
                const CircularProgressIndicator()
              else
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          try {
                            if (_isLogin) {
                              await context.read<AuthService>().signIn(
                                    _emailController.text.trim(),
                                    _passwordController.text.trim(),
                                  );
                            } else {
                              await context.read<AuthService>().signUp(
                                    _emailController.text.trim(),
                                    _passwordController.text.trim(),
                                  );
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Check your email for confirmation')),
                              );
                            }
                            
                            if (!mounted) return;
                            if (context.read<AuthService>().isLoggedIn) {
                              Navigator.of(context).pop();
                            }
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      child: Text(_isLogin ? 'Login' : 'Sign Up'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                        });
                      },
                      child: Text(_isLogin ? 'Create an account' : 'Already have an account? Login'),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await context.read<AuthService>().signInWithGoogle();
                          if (!mounted) return;
                          // Check if login was successful
                          // We wait a brief moment for the auth state to propagate if needed,
                          // though await signInWithGoogle should complete after auth is done.
                          if (context.read<AuthService>().isLoggedIn) {
                            Navigator.of(context).pop();
                          } else {
                            // Fallback: manually check if user is signed in on the client directly
                            // This handles race conditions where notifyListeners hasn't propagated yet
                            final user = Supabase.instance.client.auth.currentUser;
                            if (user != null) {
                                Navigator.of(context).pop();
                            }
                          }
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${l10n.get('googleSignInFailed')}$e')),
                          );
                        }
                      },
                      icon: const Icon(Icons.login), // Placeholder for Google icon
                      label: Text(l10n.get('signInWithGoogle')),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
