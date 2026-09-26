import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'main.dart';
import 'models/painting_service.dart';
import 'widgets/kasoy_bottom_navigation.dart';
import 'widgets/kasoy_hero_banner.dart';
import 'widgets/kasoy_home_header.dart';
import 'widgets/kasoy_section_header.dart';
import 'widgets/painting_service_card.dart';
import 'widgets/service_card_skeleton.dart';

import 'login_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/quote_request_screen.dart';
import 'screens/requests_screen.dart';
import 'screens/service_details_screen.dart';
import 'screens/services_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  KasoyTab _currentTab = KasoyTab.home;

  bool _loading = true;
  String? _error;
  List<PaintingService> _services = const [];

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() {
        _services = PaintingService.samples;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load services.\n'
            'Please check your connection and try again.';
        _loading = false;
      });
    }
  }

  String get _firstName {
    final user = FirebaseAuth.instance.currentUser;
    final raw = user?.displayName?.trim();
    if (raw != null && raw.isNotEmpty) {
      return raw.split(RegExp(r'\s+')).first;
    }
    final email = user?.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return 'there';
  }

  void _handleTabSelected(KasoyTab tab) {
    if (tab == _currentTab) return;

    setState(() => _currentTab = tab);

    Widget? destination;
    switch (tab) {
      case KasoyTab.home:
        return;
      case KasoyTab.services:
        destination = const ServicesScreen();
        break;
      case KasoyTab.requests:
        destination = const RequestsScreen();
        break;
      case KasoyTab.messages:
        destination = const MessagesScreen();
        break;
      case KasoyTab.profile:
        destination = const ProfileScreen();
        break;
    }

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => destination!))
        .then((_) {
      if (mounted) setState(() => _currentTab = KasoyTab.home);
    });
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  void _openQuoteRequest() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QuoteRequestScreen()),
    );
  }

  void _openServices() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ServicesScreen()),
    );
  }

  void _openServiceDetails(PaintingService service) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceDetailsScreen(service: service),
      ),
    );
  }

  Future<void> _lock() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: KasoyHomeHeader(
                userName: _firstName,
                onNotificationTap: _openNotifications,
              ),
            ),
            SliverToBoxAdapter(
              child: KasoyHeroBanner(
                onRequestQuote: _openQuoteRequest,
                onViewServices: _openServices,
              ),
            ),
            SliverToBoxAdapter(
              child: KasoySectionHeader(
                title: 'Our Services',
                actionLabel: 'See All',
                onActionTap: _openServices,
              ),
            ),
            SliverToBoxAdapter(
              child: _ServicesRow(
                loading: _loading,
                error: _error,
                services: _services,
                onRetry: _loadServices,
                onServiceTap: _openServiceDetails,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: OutlinedButton.icon(
                  onPressed: _lock,
                  icon: const Icon(Icons.lock_outline_rounded, size: 18),
                  label: const Text('Lock'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: AppColors.textDark,
                    side: BorderSide(
                      color: Colors.black.withValues(alpha: 0.08),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
      bottomNavigationBar: KasoyBottomNavigation(
        currentTab: _currentTab,
        onTabSelected: _handleTabSelected,
      ),
    );
  }
}

class _ServicesRow extends StatelessWidget {
  const _ServicesRow({
    required this.loading,
    required this.error,
    required this.services,
    required this.onRetry,
    required this.onServiceTap,
  });

  final bool loading;
  final String? error;
  final List<PaintingService> services;
  final VoidCallback onRetry;
  final ValueChanged<PaintingService> onServiceTap;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return SizedBox(
        height: 210,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: 3,
          itemBuilder: (_, __) => const ServiceCardSkeleton(),
        ),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _ErrorState(message: error!, onRetry: onRetry),
      );
    }

    return SizedBox(
      height: 210,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth =
              (constraints.maxWidth * 0.62).clamp(210.0, 270.0).toDouble();

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: services.length,
            itemBuilder: (_, i) {
              final service = services[i];
              return PaintingServiceCard(
                service: service,
                width: cardWidth,
                onTap: () => onServiceTap(service),
              );
            },
          );
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded,
              color: AppColors.textGrey, size: 32),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textGrey,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(140, 44),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}