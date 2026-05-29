import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/report_model.dart';
import '../../providers/profile_provider.dart';
import '../../providers/report_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final reportsAsync = ref.watch(userReportsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(profileProvider);
            ref.invalidate(userReportsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(context, ref),
                _buildGreeting(context, profileAsync),
                const SizedBox(height: 24),
                _buildSummaryCards(context, reportsAsync),
                const SizedBox(height: 24),
                _buildReportButton(context),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, 0),
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                // SUKSES MENGGANTI IKON SEGITIGA WARNING MENJADI IKON MEGAFON PELAPORAN YANG PREMIUM
                child: const Icon(
                  Icons.campaign_rounded,
                  color: AppTheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'CatchIt',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, AsyncValue profileAsync) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: profileAsync.when(
        data: (profile) {
          final name = profile?.fullName ?? 'Pengguna';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, $name 👋',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Laporkan kerusakan fasilitas di sekitar Anda',
                style: TextStyle(
                  fontSize: 14, 
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)
                ),
              ),
            ],
          );
        },
        loading: () => Text(
          'Halo 👋',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        error: (_, __) => Text(
          'Halo 👋',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, AsyncValue<List<ReportModel>> reportsAsync) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: reportsAsync.when(
        data: (reports) {
          final total = reports.length;
          final menunggu = reports.where((r) => r.status == 'menunggu').length;
          final diproses = reports.where((r) => r.status == 'diproses').length;
          final selesai = reports.where((r) => r.status == 'selesai').length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ringkasan Laporan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'Total',
                      value: total,
                      color: AppTheme.primary,
                      icon: Icons.summarize_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Menunggu',
                      value: menunggu,
                      color: AppTheme.statusMenunggu,
                      icon: Icons.hourglass_empty_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'Diproses',
                      value: diproses,
                      color: AppTheme.statusDiproses,
                      icon: Icons.sync_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Selesai',
                      value: selesai,
                      color: AppTheme.statusSelesai,
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text(
          'Gagal memuat data: $e',
          style: const TextStyle(color: AppTheme.danger),
        ),
      ),
    );
  }

  Widget _buildReportButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () => context.push('/report/create'),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buat Laporan Baru',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Laporkan kerusakan fasilitas yang Anda temui.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white70,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return NavigationBar(
      backgroundColor: Theme.of(context).cardColor,
      indicatorColor: AppTheme.primary.withOpacity(0.12),
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        if (index == 1) context.go('/history');
        if (index == 2) context.go('/profile');
      },
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.home_outlined, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)),
          selectedIcon: const Icon(Icons.home_rounded, color: AppTheme.primary),
          label: 'Beranda',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)),
          selectedIcon: const Icon(Icons.history_rounded, color: AppTheme.primary),
          label: 'Riwayat',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)),
          selectedIcon: const Icon(Icons.person_rounded, color: AppTheme.primary),
          label: 'Profil',
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}