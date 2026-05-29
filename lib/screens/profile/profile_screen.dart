import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart'; 
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final user = ref.watch(currentUserProvider);
    
    // Membaca status tema aktif dari Riverpod
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Profil Saya')),
      body: profileAsync.when(
        data: (profile) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Avatar
                _buildAvatar(profile?.avatarUrl, profile?.fullName),
                const SizedBox(height: 16),
                Text(
                  profile?.fullName ?? 'Pengguna',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '-',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'INFORMASI AKUN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Info Cards Container
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    children: [
                      _ActionTile(
                        icon: Icons.person_outline_rounded,
                        label: 'Ubah Nama',
                        value: profile?.fullName ?? '-',
                        onTap: () =>
                            _showEditProfileModal(context, ref, profile),
                      ),
                      Divider(
                        height: 1,
                        indent: 56,
                        color: Theme.of(context).dividerColor,
                      ),
                      _ActionTile(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: user?.email ?? '-',
                        onTap: null, 
                        showArrow: false,
                      ),
                      Divider(
                        height: 1,
                        indent: 56,
                        color: Theme.of(context).dividerColor,
                      ),
                      _ActionTile(
                        icon: Icons.phone_outlined,
                        label: 'Ubah Nomor Telepon',
                        value: profile?.phoneNumber ?? 'Belum diisi',
                        onTap: () =>
                            _showEditProfileModal(context, ref, profile),
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // PENGATURAN APLIKASI
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'PENGATURAN APLIKASI',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        themeMode == ThemeMode.dark 
                            ? Icons.dark_mode_rounded 
                            : Icons.light_mode_rounded, 
                        color: Colors.amber, 
                        size: 20
                      ),
                    ),
                    title: Text(
                      'Mode Gelap',
                      style: TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    trailing: Switch(
                      value: themeMode == ThemeMode.dark,
                      activeColor: AppTheme.primary,
                      onChanged: (isDark) {
                        ref.read(themeProvider.notifier).setThemeMode(
                              isDark ? ThemeMode.dark : ThemeMode.light,
                            );
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Logout Button Container
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.danger,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _ActionTile(
                    icon: Icons.logout_rounded,
                    label: 'Keluar Akun',
                    iconColor: Colors.white,
                    textColor: Colors.white,
                    onTap: () => _confirmLogout(context, ref),
                    showArrow: false,
                    isLast: true,
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Gagal memuat profil: $e',
            style: const TextStyle(color: AppTheme.danger),
          ),
        ),
      ),
      bottomNavigationBar: profileAsync.whenOrNull(
        data: (profile) {
          final isAdmin =
              profile?.role == 'admin' || profile?.role == 'petugas';
          if (isAdmin) {
            return BottomNavigationBar(
              backgroundColor: Theme.of(context).cardColor,
              selectedItemColor: AppTheme.primary,
              unselectedItemColor: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              currentIndex: 2,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.list_alt_outlined),
                  activeIcon: Icon(Icons.list_alt),
                  label: 'Laporan',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profil',
                ),
              ],
              onTap: (index) {
                if (index == 0) context.go('/admin/dashboard');
                if (index == 1) context.go('/admin/reports');
              },
            );
          }
          // Warga navigation
          return NavigationBar(
            backgroundColor: Theme.of(context).cardColor,
            indicatorColor: AppTheme.primary.withOpacity(0.12),
            selectedIndex: 2,
            onDestinationSelected: (index) {
              if (index == 0) context.go('/home');
              if (index == 1) context.go('/history');
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
        },
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, String? name) {
    final initials = name != null && name.isNotEmpty
        ? name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : '?';

    return CircleAvatar(
      radius: 48,
      backgroundColor: AppTheme.primary.withOpacity(0.15),
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
      child: avatarUrl == null
          ? Text( // const di depan Text ini sudah dibuang untuk mengatasi error compilation
              initials,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            )
          : null,
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          TextButton(
            child: const Text(
              'Keluar',
              style: TextStyle(color: AppTheme.danger),
            ),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Supabase.instance.client.auth.signOut();
        if (context.mounted) {
          ref.invalidate(profileProvider);
          context.go('/login');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal keluar: $e'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
      }
    }
  }

  void _showEditProfileModal(
    BuildContext context,
    WidgetRef ref,
    dynamic profile,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _EditProfileForm(profile: profile, ref: ref),
      ),
    );
  }
}

class _EditProfileForm extends StatefulWidget {
  final dynamic profile;
  final WidgetRef ref;

  const _EditProfileForm({required this.profile, required this.ref});

  @override
  State<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<_EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: widget.profile?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = {
        'id': user.id,
        'full_name': _nameCtrl.text.trim(),
        'phone_number': _phoneCtrl.text.trim(),
      };

      await Supabase.instance.client.from('profiles').upsert(data);

      if (mounted) {
        widget.ref.invalidate(profileProvider);
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: AppTheme.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Profil',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => context.pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateProfile,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final bool showArrow;
  final bool isLast;
  final Color iconColor;
  final Color? textColor;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    this.value,
    this.showArrow = true,
    this.isLast = false,
    this.iconColor = AppTheme.primary,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final finalTextColor = textColor ?? Theme.of(context).textTheme.bodyLarge?.color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isLast ? 16 : 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: finalTextColor,
                    ),
                  ),
                  if (value != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      value!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showArrow)
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}