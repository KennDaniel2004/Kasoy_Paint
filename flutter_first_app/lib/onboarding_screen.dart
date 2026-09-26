import 'package:flutter/material.dart';
import 'main.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;
  String _selectedService = 'Car';

  static const int _pageCount = 3;

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _next() {
    if (_page == _pageCount - 1) {
      _goToLogin();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  const _IntroPage(),
                  _ServicePage(
                    selected: _selectedService,
                    onSelect: (s) => setState(() => _selectedService = s),
                  ),
                  const _QuotePage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
              child: Row(
                children: [
                  Row(
                    children: List.generate(
                      _pageCount,
                      (i) => Container(
                        margin: const EdgeInsets.only(right: 6),
                        width: i == _page ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: i == _page
                              ? AppColors.primaryOrange
                              : Colors.black12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _goToLogin,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 26),
                    ),
                    child: Text(_page == _pageCount - 1 ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Onboarding page 1 — hero panel + intro copy.
class _IntroPage extends StatelessWidget {
  const _IntroPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero image — tall, soft corners, matches the mockup's
          // wide-format car photo filling the top of the page.
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/images/boarding1.png',
              height: 340,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 340,
                color: AppColors.fieldFill,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.image_outlined,
                  size: 48,
                  color: AppColors.textGrey,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Professional Vehicle\nPainting',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              height: 1.2,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Give your vehicle a fresh, clean, and professional finish with '
            'our world-class oven-bake and customized color grading.',
            style: TextStyle(
              color: AppColors.textGrey,
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

/// Onboarding page 2 — choose vehicle type.
class _ServicePage extends StatelessWidget {
  const _ServicePage({required this.selected, required this.onSelect});

  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Your Service',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Choose the service that matches your vehicle type and get '
            'started with premium finish options.',
            style: TextStyle(
              color: AppColors.textGrey,
              fontSize: 14.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _ServiceCard(
                  label: 'Car',
                  icon: Icons.directions_car_rounded,
                  enabled: true,
                  selected: selected == 'Car',
                  onTap: () => onSelect('Car'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ServiceCard(
                  label: 'Motorcycle',
                  icon: Icons.two_wheeler_rounded,
                  enabled: true,
                  selected: selected == 'Motorcycle',
                  onTap: () => onSelect('Motorcycle'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ServiceCard(
                  label: 'Tricycle',
                  icon: Icons.electric_rickshaw_rounded,
                  enabled: true,
                  selected: selected == 'Tricycle',
                  onTap: () => onSelect('Tricycle'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.selected,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent =
        enabled ? AppColors.primaryOrange : Colors.grey.shade400;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primaryOrange : Colors.transparent,
            width: 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: enabled
                  ? AppColors.primaryOrange.withValues(alpha: 0.12)
                  : Colors.grey.shade100,
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: enabled ? AppColors.textDark : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Onboarding page 3 — request-a-quote preview card.
class _QuotePage extends StatelessWidget {
  const _QuotePage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- WHITE CHAT CARD CONTAINER ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.04),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Row: Avatar + Text
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.fieldFill,
                      child: Icon(Icons.person,
                          size: 18, color: AppColors.textGrey),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Hi, I have a deep scratch and dent on my front bumper. Can I get a quote to fix this?',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. The Image (Full width)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/boarding2.png',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),

                // 3. The Orange Quote Box (Inside the white bubble)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated Quote Generated',
                        style: TextStyle(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Processing detail quote in progress...',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // --- TITLE AND DESCRIPTION ---
          const Text(
            'Request a Quote',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Send your vehicle details and request an estimated quotation '
            'easily before visiting our shop.',
            style: TextStyle(
              color: AppColors.textGrey,
              fontSize: 14.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}