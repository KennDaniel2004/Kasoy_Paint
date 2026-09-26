import 'package:flutter/material.dart';

/// Lightweight shimmer-style placeholder used while services load.
///
/// No external package required — a subtle pulsing opacity animation
/// keeps things clean without pulling in a shimmer dependency.
class ServiceCardSkeleton extends StatefulWidget {
  const ServiceCardSkeleton({super.key, this.width = 200});

  final double width;

  @override
  State<ServiceCardSkeleton> createState() => _ServiceCardSkeletonState();
}

class _ServiceCardSkeletonState extends State<ServiceCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = 0.55 + (_controller.value * 0.25);
        final base = Colors.black.withValues(alpha: 0.04);
        final pulse = Colors.black.withValues(alpha: 0.04 + (0.03 * t));

        return Container(
          width: widget.width,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Container(color: pulse),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: widget.width * 0.55,
                      height: 12,
                      decoration: BoxDecoration(
                        color: base,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: widget.width * 0.40,
                      height: 10,
                      decoration: BoxDecoration(
                        color: base,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}