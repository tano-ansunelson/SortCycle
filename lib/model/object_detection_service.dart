import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:io';

class DetectedObject {
  final String label;
  final int x;
  final int y;
  final int width;
  final int height;

  DetectedObject({
    required this.label,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory DetectedObject.fromJson(Map<String, dynamic> json) {
    return DetectedObject(
      label: json['label'],
      x: json['x'],
      y: json['y'],
      width: json['width'],
      height: json['height'],
    );
  }
}

class ObjectDetectionService {
  static const MethodChannel _channel = MethodChannel(
    'com.yourapp.waste/object_detection',
  );

  Future<Map<String, dynamic>> detectObjects(File imageFile) async {
    final Uint8List imageBytes = await imageFile.readAsBytes();

    final result = await _channel.invokeMethod('detectObjects', {
      'image': imageBytes,
    });

    final base64Image = result['annotatedImage'];
    final List objectsJson = result['objects'];

    final List<DetectedObject> objects = objectsJson
        .map((json) => DetectedObject.fromJson(Map<String, dynamic>.from(json)))
        .toList();

    return {'annotatedImage': base64Image, 'objects': objects};
  }
}
