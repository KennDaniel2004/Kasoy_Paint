import 'package:flutter/material.dart';
import '../main.dart';
import '../models/painting_service.dart';
import '../utils/currency_formatter.dart';

/// Card displaying a single painting service: image, name, and price.
///
/// Sized explicitly via [width] and [height] so nothing overflows the
/// parent row. Image area = height - text block; the text block is a
/// fixed 62px tall (name + price + padding).
class PaintingServiceCard extends StatelessWidget {
  const PaintingServiceCard({
    super.key,
    required this.service,
    required this.onTap,
    this.width = 200,
    this.height = 215,
  });

  final PaintingService service;
  final VoidCallback onTap;
  final double width;
  final double height;

  /// Bottom text block height (name + price + padding). Fixed so the
  /// image gets exactly `height - _textBlockHeight` pixels.
  static const double _textBlockHeight = 62;

  @override
  Widget build(BuildContext context) {
    final imageHeight = height - _textBlockHeight;

    return Semantics(
      button: true,
      label: '${service.name}, starting at '
          '${formatPhp(service.startingPrice)}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image area (explicit height, no AspectRatio guessing) ──
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: SizedBox(
                  width: width,
                  height: imageHeight,
                  child: Image.asset(
                    service.image,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => _ImageFallback(
                      label: service.vehicleType,
                    ),
                  ),
                ),
              ),
              // ── Text area (fixed height) ──
              SizedBox(
                height: _textBlockHeight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        service.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textGrey,
                          ),
                          children: [
                            const TextSpan(text: 'Starting at '),
                            TextSpan(
                              text: formatPhp(service.startingPrice),
                              style: const TextStyle(
                                color: AppColors.primaryOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Coloured fallback used when a service image asset is missing.
class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.fieldFill,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.image_outlined,
            color: AppColors.textGrey,
            size: 28,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textGrey,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}