import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:crop_image/crop_image.dart';
import '../l10n/app_localizations.dart';

class CropScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const CropScreen({super.key, required this.imageBytes});

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
      
      if (mounted) {
        Navigator.of(context).pop(bytes);
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
          image: Image.memory(widget.imageBytes),
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
