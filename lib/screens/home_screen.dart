import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'result_screen.dart';
import 'settings_screen.dart';
import 'crop_screen.dart';
import 'history_screen.dart';
import '../services/settings_service.dart';
import '../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        _cropImage(pickedFile.path);
      }
    } catch (e) {
      _showError('${l10n.get('failedToPick')}: $e');
    }
  }

  Future<void> _cropImage(String sourcePath) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // Use the custom CropScreen instead of ImageCropper
      final File? croppedFile = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CropScreen(imageFile: File(sourcePath)),
        ),
      );

      if (croppedFile != null) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ResultScreen(imageFile: croppedFile),
          ),
        );
      }
    } catch (e) {
      _showError('${l10n.get('failedToCrop')}: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final l10n = AppLocalizations.of(context)!;
    
    // Filter providers that have API Key configured
    final configuredProviders = settings.providers.where((p) => p.apiKey.isNotEmpty).toList();
    
    // Build dropdown items
    final List<DropdownMenuItem<String>> dropdownItems = [];
    for (var provider in configuredProviders) {
      for (var model in provider.models) {
        final value = '${provider.id}:$model';
        dropdownItems.add(
          DropdownMenuItem<String>(
            value: value,
            child: Text(
              '${provider.name} - $model',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
    }

    // Construct current value
    String? currentValue = '${settings.selectedProviderId}:${settings.model}';
    
    // Validate if current value is in the list
    if (!dropdownItems.any((item) => item.value == currentValue)) {
      currentValue = null;
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: colorScheme.primary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.settings, color: colorScheme.primary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.primaryContainer.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Hero Section
              Expanded(
                flex: 2,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/custom_logo.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Error loading logo: $error');
                              return Icon(
                                Icons.auto_awesome,
                                size: 100,
                                color: colorScheme.primary,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.get('appTitle'), // Or a welcome message if available
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          l10n.get('welcomeMessage'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Model Selector Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, top: 8),
                          child: Text(
                            l10n.get('currentModel'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        if (configuredProviders.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: colorScheme.error),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.get('apiKeyRequired'),
                                    style: TextStyle(color: colorScheme.error),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: currentValue,
                              isExpanded: true,
                              icon: Icon(Icons.expand_more, color: colorScheme.primary),
                              style: TextStyle(
                                fontSize: 16,
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                              hint: Text(l10n.get('modelName')),
                              items: dropdownItems,
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  final parts = newValue.split(':');
                                  if (parts.length == 2) {
                                    settings.setModel(parts[1], parts[0]);
                                  }
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Action Buttons
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionButton(
                        context,
                        icon: Icons.camera_alt_rounded,
                        label: l10n.get('takePhoto'),
                        onPressed: () => _pickImage(ImageSource.camera),
                        isPrimary: true,
                      ),
                      const SizedBox(height: 16),
                      _buildActionButton(
                        context,
                        icon: Icons.photo_library_rounded,
                        label: l10n.get('pickGallery'),
                        onPressed: () => _pickImage(ImageSource.gallery),
                        isPrimary: false,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: isPrimary
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 28),
              label: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 4,
                shadowColor: colorScheme.primary.withValues(alpha: 0.4),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 28),
              label: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                side: BorderSide(color: colorScheme.primary, width: 2),
              ),
            ),
    );
  }
}
