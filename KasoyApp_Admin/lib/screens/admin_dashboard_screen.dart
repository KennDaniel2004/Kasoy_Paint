import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../services/admin_auth_service.dart';
import '../services/admin_firestore_service.dart';
import '../widgets/admin_bottom_nav.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  AdminTab _tab = AdminTab.home;

  void _onTab(AdminTab t) {
    if (t == _tab) return;
    setState(() => _tab = t);
    if (t != AdminTab.home) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${t.name} tab coming soon.'),
          duration: const Duration(milliseconds: 1200),
        ),
      );
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _tab = AdminTab.home);
      });
    }
  }

  String get _firstName {
    final user = FirebaseAuth.instance.currentUser;
    final raw = user?.displayName?.trim();
    if (raw != null && raw.isNotEmpty) {
      return raw.split(RegExp(r'\s+')).first;
    }
    return 'Admin';
  }

  Future<void> _logout() async {
    await AdminAuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.surfaceLight,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _Header(firstName: _firstName)),
            SliverToBoxAdapter(
              child: StreamBuilder<int>(
                stream: AdminFirestoreService.instance.watchTotalRequests(),
                builder: (context, snapshot) {
                  final total = snapshot.data ?? 0;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.55,
                      children: [
                        _StatCard(
                          label: 'Total Requests',
                          value: '$total',
                          delta: '+12%',
                        ),
                        const _StatCard(
                            label: 'In Progress', value: '0', delta: '+8%'),
                        const _StatCard(
                            label: 'This Week', value: '0', delta: '+20%'),
                        const _StatCard(
                            label: 'Completed', value: '0', delta: '+15%'),
                      ],
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Recent Requests',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AdminColors.textDark,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Requests tab coming soon.')),
                        );
                      },
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: AdminColors.primaryOrange,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: AdminFirestoreService.instance.watchRecentQuotes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(
                            color: AdminColors.primaryOrange),
                      ),
                    );
                  }
                  final rows = snapshot.data ?? const [];
                  if (rows.isEmpty) {
                    return const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: _EmptyRequests(),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _QuoteTile(data: rows[i]),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: AdminColors.textDark,
                    side: BorderSide(
                        color: Colors.black.withValues(alpha: 0.10)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNav(current: _tab, onTap: _onTab),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.firstName});
  final String firstName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Good Morning, Admin',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AdminColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Here's what's happening today.",
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AdminColors.textGrey.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.notifications_none_rounded,
                    color: AdminColors.textDark, size: 22),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AdminColors.primaryOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.delta,
  });

  final String label;
  final String value;
  final String delta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AdminColors.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AdminColors.textDark,
              height: 1.0,
            ),
          ),
          Row(
            children: [
              const Icon(Icons.arrow_upward_rounded,
                  size: 12, color: AdminColors.success),
              const SizedBox(width: 2),
              Text(
                delta,
                style: const TextStyle(
                  fontSize: 11,
                  color: AdminColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuoteTile extends StatelessWidget {
  const _QuoteTile({required this.data});
  final Map<String, dynamic> data;

  String _fmtPrice(dynamic v) {
    if (v == null) return '—';
    if (v is num) {
      final s = v.round().toString();
      final buf = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        final rem = s.length - i;
        buf.write(s[i]);
        if (rem > 1 && rem % 3 == 1) buf.write(',');
      }
      return '₱$buf';
    }
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final name = (data['vehicleModel'] as String?) ?? 'Vehicle';
    final service = (data['serviceId'] as String?) ?? 'Service';
    final status = (data['status'] as String?) ?? 'pending';
    final price = _fmtPrice(data['quotedAmount']);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AdminColors.fieldFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.directions_car_rounded,
                color: AdminColors.textGrey, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.textDark)),
                const SizedBox(height: 2),
                Text(service,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AdminColors.textGrey)),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AdminColors.primaryOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.replaceAll('_', ' '),
                    style: const TextStyle(
                        fontSize: 10.5,
                        color: AdminColors.primaryOrange,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Text(price,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AdminColors.textDark)),
        ],
      ),
    );
  }
}

class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AdminColors.primaryOrange.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inbox_outlined,
                color: AdminColors.primaryOrange, size: 30),
          ),
          const SizedBox(height: 14),
          const Text('No requests yet',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textDark)),
          const SizedBox(height: 6),
          const Text(
            'New customer quote requests will appear here in real time.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12.5,
                color: AdminColors.textGrey,
                height: 1.4),
          ),
        ],
      ),
    );
  }
}