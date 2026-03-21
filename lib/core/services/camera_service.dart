import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  CameraController? get controller => _controller;

  // ─── Initialize Camera ─────────────────────────────────────────────────────
  Future<bool> initializeCamera() async {
    final cameraPermission = await Permission.camera.request();
    if (!cameraPermission.isGranted) return false;

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return false;

      _controller = CameraController(
        _cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      _isInitialized = true;
      return true;
    } catch (e) {
      _isInitialized = false;
      return false;
    }
  }

  // ─── Take Photo ────────────────────────────────────────────────────────────
  Future<String?> takePicture() async {
    if (!_isInitialized || _controller == null) return null;

    try {
      final XFile photo = await _controller!.takePicture();

      // Save to app directory with timestamp
      final directory = await getApplicationDocumentsDirectory();
      final photoDir = Directory('${directory.path}/property_photos');
      if (!await photoDir.exists()) {
        await photoDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedPath = '${photoDir.path}/property_$timestamp.jpg';

      final File savedFile = await File(photo.path).copy(savedPath);
      return savedFile.path;
    } catch (e) {
      return null;
    }
  }

  // ─── Pick from Gallery ────────────────────────────────────────────────────
  Future<String?> pickFromGallery() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1080,
    );
    return image?.path;
  }

  // ─── Compress Image ────────────────────────────────────────────────────────
  Future<String?> compressImage(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) return imagePath;

      final compressed = img.encodeJpg(decodedImage, quality: 75);
      await File(imagePath).writeAsBytes(compressed);
      return imagePath;
    } catch (e) {
      return imagePath;
    }
  }

  // ─── Delete Photo ──────────────────────────────────────────────────────────
  Future<void> deletePhoto(String photoPath) async {
    final file = File(photoPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // ─── Dispose ──────────────────────────────────────────────────────────────
  Future<void> dispose() async {
    if (_controller != null && _isInitialized) {
      await _controller!.dispose();
      _isInitialized = false;
      _controller = null;
    }
  }
}
