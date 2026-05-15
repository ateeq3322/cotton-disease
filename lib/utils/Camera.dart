// lib/utils/Camera.dart
// ─────────────────────────────────────────────────────────────
// CropGuard — Camera screen
// Fixes: controller disposed on ALL exit paths (back, gallery,
//        capture), no setState after dispose, _mounted guard
// ─────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cotton_disease/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'constants/fonts.dart';
import 'imagePreview.dart';

class CameraUIScreen extends StatefulWidget {
  const CameraUIScreen({super.key});

  @override
  State<CameraUIScreen> createState() => _CameraUIScreenState();
}

class _CameraUIScreenState extends State<CameraUIScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isFlashOn = false;
  bool _isTakingPicture = false;
  bool _isInitializing = false;
  int _selectedCameraIndex = 0;

  // Single source of truth for "is this widget still alive"
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause camera when app goes to background, resume on foreground
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _disposeController();
    } else if (state == AppLifecycleState.resumed) {
      _startCamera(_selectedCameraIndex);
    }
  }

  Future<void> _initCamera() async {
    await Permission.camera.request();
    final cameras = await availableCameras();
    if (_disposed) return;
    _cameras = cameras;
    if (_cameras!.isNotEmpty) {
      await _startCamera(_selectedCameraIndex);
    }
  }

  Future<void> _startCamera(int index) async {
    if (_disposed || _isInitializing) return;
    _isInitializing = true;

    // Dispose previous controller safely before creating new one
    await _disposeController();

    if (_disposed) {
      _isInitializing = false;
      return;
    }

    try {
      final controller = CameraController(
        _cameras![index],
        ResolutionPreset.high, // max causes OOM on low-end; high is safer
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();

      if (_disposed) {
        await controller.dispose();
        _isInitializing = false;
        return;
      }

      _controller = controller;
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Camera init error: $e');
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _disposeController() async {
    final old = _controller;
    _controller = null;
    try {
      await old?.dispose();
    } catch (_) {}
  }

  void _toggleFlash() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    _isFlashOn = !_isFlashOn;
    _controller!.setFlashMode(
      _isFlashOn ? FlashMode.torch : FlashMode.off,
    );
    if (mounted) setState(() {});
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2 || _isInitializing) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    await _startCamera(_selectedCameraIndex);
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked =
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null || !mounted) return;

    final resultPath = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (_) => ImagePreviewScreen(imagePath: picked.path),
      ),
    );

    if (resultPath != null && mounted) {
      Navigator.pop(context, resultPath);
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isTakingPicture ||
        _disposed) return;

    _isTakingPicture = true;
    if (mounted) setState(() {});

    try {
      final picture = await _controller!.takePicture();
      if (_disposed) return;

      final directory = await getApplicationDocumentsDirectory();
      final fileName = path.basename(picture.path);
      final savedPath = '${directory.path}/$fileName';
      final savedFile = await File(picture.path).copy(savedPath);

      final croppedFile = await _cropToCenterBox(savedFile);
      if (_disposed || !mounted) return;

      final resultPath = await Navigator.push<String?>(
        context,
        MaterialPageRoute(
          builder: (_) => ImagePreviewScreen(imagePath: croppedFile.path),
        ),
      );

      if (resultPath != null && mounted) {
        Navigator.pop(context, resultPath);
      }
    } catch (e) {
      debugPrint('Capture error: $e');
    } finally {
      if (!_disposed && mounted) {
        _isTakingPicture = false;
        setState(() {});
      }
    }
  }

  Future<File> _cropToCenterBox(File file) async {
    final imageBytes = await file.readAsBytes();
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) return file;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double boxSize = screenWidth * 0.65;
    final double boxLeft = (screenWidth - boxSize) / 2;
    final double boxTop = (screenHeight - boxSize) / 2;

    final double scaleX = decoded.width / screenWidth;
    final double scaleY = decoded.height / screenHeight;

    int cropX = (boxLeft * scaleX).round();
    int cropY = (boxTop * scaleY).round();
    int cropWidth = (boxSize * scaleX).round();
    int cropHeight = (boxSize * scaleY).round();

    cropX = cropX.clamp(0, decoded.width - cropWidth);
    cropY = cropY.clamp(0, decoded.height - cropHeight);

    final cropped = img.copyCrop(
      decoded,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );

    final croppedPath = file.path.replaceAll('.jpg', '_cropped.jpg');
    return File(croppedPath)..writeAsBytesSync(img.encodeJpg(cropped));
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview — fitted to avoid black bars
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.previewSize!.height,
                height: _controller!.value.previewSize!.width,
                child: CameraPreview(_controller!),
              ),
            ),
          ),

          // Crop overlay
          LayoutBuilder(
            builder: (context, constraints) {
              final boxSize = constraints.maxWidth * 0.65;
              final screenW = constraints.maxWidth;
              final screenH = constraints.maxHeight;
              return Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _OverlayPainter(
                        boxRect: Rect.fromCenter(
                          center: Offset(screenW / 2, screenH / 2),
                          width: boxSize,
                          height: boxSize,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: boxSize,
                      height: boxSize,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      bodyText(
                          text: 'Cotton Sense AI',
                          color: white,
                          weight: FontWeight.w600),
                      cardSubtitle(
                          text: 'Take close shot for better results',
                          color: white),
                    ],
                  ),
                  IconButton(
                    onPressed: _toggleFlash,
                    icon: Icon(
                      _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom controls
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_library,
                        color: Colors.white, size: 40),
                    onPressed: _pickFromGallery,
                  ),
                  const SizedBox(width: 40),
                  GestureDetector(
                    onTap: _capturePhoto,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _isTakingPicture ? Colors.grey : Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: _isTakingPicture
                          ? const Center(
                        child: CircularProgressIndicator(
                            color: Colors.white),
                      )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 40),
                  IconButton(
                    onPressed: _switchCamera,
                    icon: const Icon(Icons.cameraswitch,
                        color: Colors.white, size: 40),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final Rect boxRect;
  const _OverlayPainter({required this.boxRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    final outer = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final inner = Path()..addRect(boxRect);
    canvas.drawPath(
        Path.combine(PathOperation.difference, outer, inner), paint);
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter old) =>
      old.boxRect != boxRect;
}