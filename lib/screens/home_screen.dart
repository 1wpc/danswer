import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'result_screen.dart';
import 'crop_screen.dart';
import 'camera_crop_screen.dart';
import '../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _captureAndCrop() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final Uint8List? croppedBytes = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const CameraCropScreen(),
        ),
      );

      if (croppedBytes != null) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ResultScreen(imageBytes: croppedBytes),
          ),
        );
      }
    } catch (e) {
      _showError('${l10n.get('error')}: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final croppedBytes = await _cropImage(bytes);
        
        if (croppedBytes != null) {
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ResultScreen(imageBytes: croppedBytes),
            ),
          );
        }
      }
    } catch (e) {
      _showError('${l10n.get('failedToPick')}: $e');
    }
  }

  Future<Uint8List?> _cropImage(Uint8List imageBytes) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // Use the custom CropScreen instead of ImageCropper
      return await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CropScreen(imageBytes: imageBytes),
        ),
      );
    } catch (e) {
      _showError('${l10n.get('failedToCrop')}: $e');
      return null;
    }
  }

  Future<void> _pickMultiPageImage() async {
    final l10n = AppLocalizations.of(context)!;
    List<Uint8List> images = [];
    bool continueAdding = true;

    while (continueAdding) {
      try {
        if (!mounted) break;
        final Uint8List? croppedBytes = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const CameraCropScreen(),
          ),
        );

        if (croppedBytes != null) {
          images.add(croppedBytes);
          
          if (!mounted) break;

          // Ask user to continue
          final shouldContinue = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text('${l10n.get('pageAdded')}${images.length}'),
              content: Text(l10n.get('addAnotherPage')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.get('finish')),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.get('addPage')),
                ),
              ],
            ),
          );
          
          continueAdding = shouldContinue ?? false;
        } else {
          // User cancelled crop, maybe stop?
          continueAdding = false; 
        }
      } catch (e) {
        _showError('${l10n.get('failedToPick')}: $e');
        continueAdding = false;
      }
    }

    if (images.isNotEmpty) {
      _stitchAndSolve(images);
    }
  }

  Future<void> _stitchAndSolve(List<Uint8List> images) async {
    if (images.length == 1) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ResultScreen(imageBytes: images.first),
        ),
      );
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    _showLoading(l10n.get('stitching'));

    try {
      // Decode images in a separate isolate or just async to avoid blocking UI too much
      // For simplicity here, running in main isolate but with await where possible
      // Actually image decoding is sync in `image` package. 
      // Ideally should be compute(), but `image` package objects are not easily transferable across isolates without serialization.
      
      await Future.delayed(const Duration(milliseconds: 100)); // Give UI time to show dialog

      List<img.Image> decodedImages = [];
      int maxWidth = 0;
      int totalHeight = 0;

      for (var bytes in images) {
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          decodedImages.add(decoded);
          if (decoded.width > maxWidth) maxWidth = decoded.width;
          totalHeight += decoded.height;
        }
      }

      if (decodedImages.isEmpty) throw Exception('No valid images');

      // Create canvas
      final mergedImage = img.Image(width: maxWidth, height: totalHeight);
      
      int currentY = 0;
      for (var image in decodedImages) {
        int dstX = (maxWidth - image.width) ~/ 2;
        img.compositeImage(mergedImage, image, dstX: dstX, dstY: currentY);
        currentY += image.height;
      }

      final mergedBytes = Uint8List.fromList(img.encodeJpg(mergedImage));
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ResultScreen(imageBytes: mergedBytes),
        ),
      );

    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      _showError('${l10n.get('failedToStitch')}: $e');
    }
  }

  void _showLoading(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Main Camera Button
                    GestureDetector(
                      onTap: _captureAndCrop,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.25),
                              blurRadius: 40,
                              spreadRadius: 5,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.camera_rounded,
                          size: 80,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              decoration: BoxDecoration(
                color: colorScheme.surface,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSecondaryButton(
                    context,
                    icon: Icons.burst_mode_rounded,
                    label: l10n.get('crossPageCapture'),
                    onPressed: _pickMultiPageImage,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  _buildSecondaryButton(
                    context,
                    icon: Icons.photo_library_rounded,
                    label: l10n.get('pickGallery'),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
