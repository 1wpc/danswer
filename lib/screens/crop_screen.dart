import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:crop_image/crop_image.dart';
import 'package:path_provider/path_provider.dart';
import '../l10n/app_localizations.dart';

class CropScreen extends StatefulWidget {
  final File imageFile;

  const CropScreen({super.key, required this.imageFile});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final CropController _controller = CropController(
    aspectRatio: null,
    defaultCrop: const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9),
  );

  bool _isProcessing = false;

  Future<void> _cropAndReturn() async {
    final l10n = AppLocalizations.of(context)!;
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      final image = await _controller.croppedBitmap();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (data == null) {
        throw Exception('Failed to get image data');
      }
      
      final bytes = data.buffer.asUint8List();
      
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.png').create();
      await file.writeAsBytes(bytes);
      
      if (mounted) {
        Navigator.of(context).pop(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.get('error')}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l10n.get('cropProblem')),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.rotate_right),
            onPressed: _controller.rotateRight,
            tooltip: l10n.get('rotate'),
          ),
          IconButton(
            icon: _isProcessing 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.check),
            onPressed: _cropAndReturn,
            tooltip: l10n.get('solve'),
          ),
        ],
      ),
      body: Center(
        child: CropImage(
          controller: _controller,
          image: Image.file(widget.imageFile),
          minimumImageSize: 10, // Allows very small crops
          gridColor: Colors.white,
          gridCornerSize: 30,
          scrimColor: Colors.black87,
          alwaysMove: true,
        ),
      ),
    );
  }
}
