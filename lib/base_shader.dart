import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class BaseShader {
  BaseShader({
    required this.shaderAssetPath,
  });

  final String shaderAssetPath;

  late ui.FragmentProgram _program;
  late ui.FragmentShader _shader;

  bool _isLoaded = false;

  ui.FragmentShader get shader => _shader;
  bool get isLoaded => _isLoaded;

  Future<void> initialize() async {
    await _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      _program = await ui.FragmentProgram.fromAsset(shaderAssetPath);
      _shader = _program.fragmentShader();
      _isLoaded = true;
    } catch (e) {
      debugPrint('Error loading shader: $e');
    }
  }

  void updateShaderUniforms({
    required double width,
    required double height,
    required ui.Image? backgroundImage,
  }) {
    throw UnimplementedError();
  }
}
