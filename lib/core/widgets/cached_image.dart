import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      child: imageUrl.isEmpty
          ? _errorWidget(isDark)
          : CachedNetworkImage(
              imageUrl: imageUrl,
              width: width,
              height: height,
              fit: fit,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                highlightColor:
                    isDark ? Colors.grey.shade700 : Colors.grey.shade100,
                child: Container(
                  width: width,
                  height: height,
                  color: Colors.white,
                ),
              ),
              errorWidget: (context, url, error) => _errorWidget(isDark),
            ),
    );
  }

  Widget _errorWidget(bool isDark) {
    return Container(
      width: width,
      height: height,
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      child: Icon(
        Icons.image_outlined,
        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
        size: 32,
      ),
    );
  }
}
