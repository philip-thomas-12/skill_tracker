import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraDialog extends StatefulWidget {
  const CameraDialog({super.key});

  @override
  State<CameraDialog> createState() => _CameraDialogState();
}

class _CameraDialogState extends State<CameraDialog> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInit = false;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras!.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _controller!.initialize();
        if (mounted) setState(() => _isInit = true);
      }
    } catch (e) {
      debugPrint("Camera INIT Error: $e");
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isTakingPicture) return;

    setState(() => _isTakingPicture = true);

    try {
      final XFile photo = await _controller!.takePicture();
      final Uint8List bytes = await photo.readAsBytes();
      final String name = photo.name;
      
      if (mounted) {
        Navigator.pop(context, {
          'bytes': bytes,
          'name': name.isEmpty ? 'camera_photo.jpg' : name,
        });
      }
    } catch (e) {
      debugPrint("Take Picture Error: $e");
      setState(() => _isTakingPicture = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit || _controller == null) {
      return Dialog(
        backgroundColor: const Color(0xFF1C1E24),
        child: Container(
          height: 300,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(color: Color(0xFF2ECC71)),
              SizedBox(height: 20),
              Text("Initializing Camera...", style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Camera Feed
              Center(
                child: CameraPreview(_controller!),
              ),
              
              // Top Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black87, Colors.transparent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 30),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),

              // Capture Button
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _takePicture,
                      child: Container(
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: _isTakingPicture ? Colors.white54 : Colors.transparent,
                        ),
                        child: Center(
                          child: Container(
                            height: 54,
                            width: 54,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: _isTakingPicture 
                                ? const Center(child: CircularProgressIndicator(color: Colors.black))
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
