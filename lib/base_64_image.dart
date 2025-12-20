import 'dart:convert';
import 'package:flutter/material.dart';

class Base64Image extends StatelessWidget {
  final String base64String;
  final double? width;
  final double? height;
  final BoxFit fit;

  const Base64Image({
    required this.base64String,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    String cleanBase64 = base64String.replaceFirst(RegExp(r'data:image/[^;]+;base64,'), '');
    
    return Image.memory(
      base64Decode(cleanBase64),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.error);
      },
    );
  }
}