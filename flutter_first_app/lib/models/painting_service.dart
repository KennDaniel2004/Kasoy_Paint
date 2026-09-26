/// Model representing a painting service offered by Kasoy Painting Shop.
///
/// NOTE: All prices are STARTING/ESTIMATED prices only. Final pricing
/// depends on vehicle condition, paint requirements, materials, and
/// onsite inspection.
class PaintingService {
  const PaintingService({
    required this.id,
    required this.name,
    required this.vehicleType,
    required this.startingPrice,
    required this.image,
    required this.description,
    required this.shortDescription,
    required this.tags,
    required this.inclusions,
    required this.additionalChargesMin,
    required this.additionalChargesMax,
    required this.additionalChargesLabel,
  });

  final String id;
  final String name;
  final String vehicleType;
  final double startingPrice;
  final String image;
  final String description;

  /// Short one-line subtitle used on the Services list screen.
  final String shortDescription;

  /// Small chips shown on the details screen (e.g. "Full Repaint").
  final List<String> tags;

  /// Bullet list of what's included in the service.
  final List<String> inclusions;

  /// Possible extra charges, shown as a range on the details screen.
  final double additionalChargesMin;
  final double additionalChargesMax;
  final String additionalChargesLabel;

  /// Sample data — replace with a Firestore query later if needed.
  static const List<PaintingService> samples = <PaintingService>[
    PaintingService(
      id: 'car_painting',
      name: 'Car Painting',
      vehicleType: 'Car',
      startingPrice: 24000,
      image: 'assets/images/carpaint_ceo.png',
      description:
          'Full-body repaint with premium oven-bake finish. Includes surface '
          'prep, primer, base coat, clear coat, and colour matching.',
      shortDescription: 'Full repair, color change, and more.',
      tags: ['Full Repaint', 'Color Change', 'Body Prep'],
      inclusions: [
        'Surface preparation & sand blasting',
        'High-quality primer and paint materials',
        'Professional oven-bake paint application',
        'Final polish, waxing and inspection',
      ],
      additionalChargesMin: 3000,
      additionalChargesMax: 5000,
      additionalChargesLabel: 'Special/Metallic colors',
    ),
    PaintingService(
      id: 'motorcycle_painting',
      name: 'Motorcycle Paint',
      vehicleType: 'Motorcycle',
      startingPrice: 3000,
      image: 'assets/images/motorpaint_ceo.png',
      description:
          'Custom paint for motorcycles including fairings, tanks, and '
          'frames. Choose from solid, metallic, or candy colours.',
      shortDescription: 'Custom colors, full repaint, and more.',
      tags: ['Full Repaint', 'Custom Color', 'Fairings'],
      inclusions: [
        'Fairing and tank surface preparation',
        'Premium primer and topcoat materials',
        'Oven-bake curing for durability',
        'Final polish and quality inspection',
      ],
      additionalChargesMin: 1500,
      additionalChargesMax: 3000,
      additionalChargesLabel: 'Custom graphics/stickers',
    ),
    PaintingService(
      id: 'tricycle_painting',
      name: 'Tricycle Paint',
      vehicleType: 'Tricycle',
      startingPrice: 7000,
      image: 'assets/images/tryclepaint_ceo.png',
      description:
          'Durable repaint for tricycles built to handle daily use. Includes '
          'rust treatment, primer, and a protective topcoat.',
      shortDescription: 'Durable and high-quality finish.',
      tags: ['Rust Treatment', 'Full Repaint', 'Protective Coat'],
      inclusions: [
        'Rust removal and metal treatment',
        'Anti-corrosion primer application',
        'Premium topcoat and clear coat',
        'Final polish and inspection',
      ],
      additionalChargesMin: 1000,
      additionalChargesMax: 2500,
      additionalChargesLabel: 'Custom designs/lettering',
    ),
  ];
}