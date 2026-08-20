import 'dart:ui';
import 'package:flutter/material.dart';

class BackgroundBlobs extends StatelessWidget {
  final Widget child;
  final List<BlobConfig>? blobs;
  
  const BackgroundBlobs({
    super.key, 
    required this.child,
    this.blobs,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final defaultBlobs = [
      BlobConfig(
        top: -50,
        right: -50,
        size: 220,
        color: colorScheme.primary.withValues(alpha: isDark ? 0.12 : 0.08),
      ),
      BlobConfig(
        bottom: 100,
        left: -40,
        size: 180,
        color: Colors.purple.withValues(alpha: isDark ? 0.1 : 0.06),
      ),
      BlobConfig(
        top: 300,
        right: 30,
        size: 140,
        color: Colors.orange.withValues(alpha: isDark ? 0.08 : 0.04),
      ),
    ];

    final activeBlobs = blobs ?? defaultBlobs;

    return Stack(
      children: [
        ...activeBlobs.map((blob) => Positioned(
          top: blob.top,
          bottom: blob.bottom,
          left: blob.left,
          right: blob.right,
          child: _buildBlob(blob.size, blob.color),
        )),
        child,
      ],
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}

class BlobConfig {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final Color color;

  BlobConfig({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.color,
  });
}
