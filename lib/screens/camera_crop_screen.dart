import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:crop_image/crop_image.dart';
import '../l10n/app_localizations.dart';

class CameraCropScreen extends StatefulWidget {
  const CameraCropScreen({super.key});

  @override
  State<CameraCropScreen> createState() => _CameraCropScreenState();
}

class _CameraCropScreenState extends State<CameraCropScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  
  bool _isInitializing = true;
  bool _isProcessing = false;
  
  // State: 'camera' or 'crop'
  String _currentState = 'camera';
  
  Uint8List? _capturedImageBytes;
  CropController? _cropController;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Find the back camera
        CameraDescription? backCamera;
        for (var camera in _cameras!) {
          if (camera.lensDirection == CameraLensDirection.back) {
            backCamera = camera;
            break;
          }
        }
        
        // Fallback to first available if no back camera
        backCamera ??= _cameras![0];

        _cameraController = CameraController(
          backCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );
        
        await _cameraController!.initialize();
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _cropController?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (_cameraController!.value.isTakingPicture) {
      return;
    }

    try {
      setState(() {
        _isProcessing = true;
      });

      final XFile file = await _cameraController!.takePicture();
      final bytes = await file.readAsBytes();

      setState(() {
        _capturedImageBytes = bytes;
        _currentState = 'crop';
        _cropController = CropController(
          aspectRatio: null,
          defaultCrop: const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9),
        );
        _isProcessing = false;
      });
    } catch (e) {
      debugPrint('Error taking picture: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _retakePicture() {
    setState(() {
      _currentState = 'camera';
      _capturedImageBytes = null;
      _cropController?.dispose();
      _cropController = null;
    });
  }

  Future<void> _confirmCrop() async {
    if (_isProcessing || _cropController == null) return;
    final l10n = AppLocalizations.of(context);
    
    setState(() {
      _isProcessing = true;
    });

    try {
      final image = await _cropController!.croppedBitmap();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (data == null) {
        throw Exception('Failed to get image data');
      }

      final bytes = data.buffer.asUint8List();
      
      if (mounted) {
        Navigator.of(context).pop(bytes);
      }
    } catch (e) {
      if (mounted && l10n != null) {
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

    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Text(
            '${l10n.get('error')}: Camera not available',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                if (_currentState == 'crop')
                  IconButton(
                    icon: const Icon(Icons.rotate_right, color: Colors.white),
                    onPressed: _cropController?.rotateRight,
                    tooltip: l10n.get('rotate'),
                  )
                else
                  const SizedBox(width: 48), // Spacer to balance close button
              ],
            ),
            
            // Main View Area
            Expanded(
              child: Container(
                width: double.infinity,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_currentState == 'camera')
                      CameraPreview(_cameraController!)
                    else if (_currentState == 'crop' && _capturedImageBytes != null)
                      CropImage(
                        controller: _cropController!,
                        image: Image.memory(_capturedImageBytes!),
                        minimumImageSize: 10,
                        gridColor: Colors.white,
                        gridCornerSize: 30,
                        scrimColor: Colors.black87,
                        alwaysMove: true,
                      ),
                    
                    if (_isProcessing)
                      Container(
                        color: Colors.black45,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Bottom Controls
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _currentState == 'camera'
                  ? _buildCameraControls()
                  : _buildCropControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraControls() {
    return Center(
      child: GestureDetector(
        onTap: _takePicture,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCropControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: _retakePicture,
          icon: const Icon(Icons.close, size: 40, color: Colors.white),
        ),
        IconButton(
          onPressed: _confirmCrop,
          icon: const Icon(Icons.check, size: 40, color: Colors.green),
        ),
      ],
    );
  }
}