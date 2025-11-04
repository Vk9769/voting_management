import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SelfiePointPage extends StatefulWidget {
  const SelfiePointPage({super.key});

  @override
  State<SelfiePointPage> createState() => _SelfiePointPageState();
}

class _SelfiePointPageState extends State<SelfiePointPage>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  XFile? _capturedImage;
  bool _isSelfieUploaded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late Future<CameraController> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = initCamera();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  Future<CameraController> initCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.front);
      final controller =
      CameraController(frontCamera, ResolutionPreset.medium);
      await controller.initialize();
      return controller;
    } catch (e) {
      Fluttertoast.showToast(msg: "Camera initialization failed: $e");
      throw e;
    }
  }

  Future<void> capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isTakingPicture) return;

    try {
      final image = await _controller!.takePicture();
      setState(() => _capturedImage = image);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error capturing photo: $e');
    }
  }

  Future<void> submitPhoto() async {
    if (_capturedImage == null) return;
    setState(() {
      _isSelfieUploaded = true;
      _capturedImage = null;
    });
    Fluttertoast.showToast(msg: "Selfie uploaded successfully!");
  }

  void resetUploadStatus() {
    setState(() {
      _isSelfieUploaded = false;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isSelfieUploaded
              ? [const Color(0xFF10B981), const Color(0xFF059669)]
              : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_isSelfieUploaded
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444))
                .withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isSelfieUploaded ? Icons.check_circle : Icons.info,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            _isSelfieUploaded ? "✓ Selfie Uploaded" : "⚠ Selfie Not Uploaded",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Instructions",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionItem(
            "1",
            "Make sure your finger has voting ink",
          ),
          const SizedBox(height: 10),
          _buildInstructionItem(
            "2",
            "Hold the front camera pointing at your face and inked finger",
          ),
          const SizedBox(height: 10),
          _buildInstructionItem(
            "3",
            "Tap 'Capture' to take selfie",
          ),
          const SizedBox(height: 10),
          _buildInstructionItem(
            "4",
            "Review and submit your selfie",
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Color(0xFF3B82F6),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4B5563),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isFullWidth = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          "Selfie Point",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF3B82F6),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildStatusCard(),

              _buildInstructionsCard(),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: AspectRatio(
                  aspectRatio: 4 / 5,
                  child: FutureBuilder<CameraController>(
                    future: _initializeControllerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (snapshot.hasError) {
                          return Container(
                            color: const Color(0xFFEF4444),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.white, size: 48),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Camera error: ${snapshot.error}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        _controller = snapshot.data;
                        if (_controller == null ||
                            !_controller!.value.isInitialized) {
                          return Container(
                            color: const Color(0xFFF3F4F6),
                            child: const Center(
                              child: Text("Camera not available"),
                            ),
                          );
                        }

                        return _capturedImage == null
                            ? CameraPreview(_controller!)
                            : Image.file(
                          File(_capturedImage!.path),
                          fit: BoxFit.cover,
                        );
                      } else {
                        return Container(
                          color: const Color(0xFFF3F4F6),
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (_capturedImage == null)
                      _buildModernButton(
                        label: "Capture Selfie",
                        icon: Icons.camera_alt,
                        color: const Color(0xFF3B82F6),
                        onPressed: capturePhoto,
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _buildModernButton(
                              label: "Submit",
                              icon: Icons.check,
                              color: const Color(0xFF10B981),
                              onPressed: submitPhoto,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildModernButton(
                              label: "Retake",
                              icon: Icons.refresh,
                              color: const Color(0xFFF59E0B),
                              onPressed: () =>
                                  setState(() => _capturedImage = null),
                            ),
                          ),
                        ],
                      ),
                    if (_isSelfieUploaded) ...[
                      const SizedBox(height: 12),
                      _buildModernButton(
                        label: "Upload Another Selfie",
                        icon: Icons.restart_alt,
                        color: const Color(0xFF6B7280),
                        onPressed: resetUploadStatus,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
