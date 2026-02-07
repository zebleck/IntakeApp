import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

enum ShimmerStyle { listTile, card }

class ShimmerPlaceholder extends StatelessWidget {
  final ShimmerStyle style;
  final int count;

  const ShimmerPlaceholder({
    super.key,
    this.style = ShimmerStyle.listTile,
    this.count = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withAlpha(13),
      highlightColor: Colors.white.withAlpha(38),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: List.generate(count, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                height: style == ShimmerStyle.card ? 80 : 48,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(13),
                  borderRadius: BorderRadius.circular(
                    style == ShimmerStyle.card ? 16 : 12,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
