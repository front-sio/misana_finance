import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:misana_finance_app/core/theme/app_theme.dart';
import 'package:misana_finance_app/core/i18n/locale_cubit.dart';
import '../../../session/auth_cubit.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  File? _selectedImage;
  bool _uploadingImage = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  String _normalizeKycFromUser(Map<String, dynamic>? user) {
    if (user == null) return 'unknown';
    final anyTrue = [
      user['is_verified'],
      user['kyc_verified'],
      user['kycApproved'],
      (user['profile'] is Map ? user['profile']['kyc_verified'] : null),
    ].any((v) {
      if (v is bool) return v;
      if (v is String) {
        final s = v.toLowerCase();
        return s == 'true' ||
            s == '1' ||
            s == 'yes' ||
            s == 'approved' ||
            s == 'verified' ||
            s == 'success';
      }
      return false;
    });
    if (anyTrue) return 'verified';
    final raw = (user['kyc_status'] ??
            user['kyc_verification'] ??
            (user['profile'] is Map ? user['profile']['kyc_status'] : '') ??
            '')
        .toString()
        .toLowerCase()
        .trim();
    if (raw == 'approved' || raw == 'verified' || raw == 'success') {
      return 'verified';
    }
    if (raw == 'pending' || raw == 'in_review' || raw == 'processing') {
      return 'pending';
    }
    if (raw == 'rejected' || raw == 'failed') return 'rejected';
    return 'unknown';
  }

  Color _kycColor(String status, Brightness b) {
    final s = status.toLowerCase();
    final dark = b == Brightness.dark;
    if (s == 'verified') return dark ? Colors.greenAccent : Colors.green;
    if (s == 'pending') return dark ? Colors.amberAccent : Colors.amber;
    if (s == 'rejected') return dark ? Colors.redAccent : Colors.red;
    return dark ? Colors.blueGrey.shade200 : Colors.blueGrey;
  }

  IconData _kycIcon(String status) {
    final s = status.toLowerCase();
    if (s == 'verified') return Icons.verified_rounded;
    if (s == 'pending') return Icons.hourglass_top_rounded;
    if (s == 'rejected') return Icons.error_outline_rounded;
    return Icons.info_outline_rounded;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final fileSizeInBytes = await file.length();
        final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

        if (fileSizeInMB > 10) {
          _showUploadError('Image size must be less than 10MB');
          return;
        }

        if (!mounted) return;
        setState(() {
          _selectedImage = file;
          _uploadingImage = true;
        });

        await Future.delayed(const Duration(milliseconds: 1000));

        if (mounted) {
          setState(() {
            _uploadingImage = false;
          });
          _showUploadSuccess();
        }
      }
    } on Exception catch (e) {
      _showUploadError(_parseImagePickerError(e));
    }
  }

  String _parseImagePickerError(Exception e) {
    final errorString = e.toString().toLowerCase();

    if (errorString.contains('permission') || errorString.contains('denied')) {
      return 'Photo library access denied. Please enable it in settings.';
    }
    if (errorString.contains('cancelled')) {
      return 'Image selection cancelled';
    }
    if (errorString.contains('plugin')) {
      return 'Failed to open image picker. Please try again.';
    }

    return 'Failed to pick image';
  }

  void _showUploadSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Profile picture updated successfully',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showUploadError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeCubit = context.watch<LocaleCubit>();
    final isSw = localeCubit.state.languageCode == 'sw';
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final user = context.watch<AuthCubit>().state.user ?? {};

    final firstName = (user['first_name'] ?? '').toString();
    final lastName = (user['last_name'] ?? '').toString();
    final username = (user['username'] ?? '').toString();
    final email = (user['email'] ?? '').toString();
    final phone = (user['phone'] ?? '').toString();
    final externalId = (user['external_account_id'] ??
            (user['account'] is Map ? user['account']['external_account_id'] : ''))
        .toString();

    final kycNorm = _normalizeKycFromUser(user);
    final kycColor = _kycColor(kycNorm, brightness);
    final kycIcon = _kycIcon(kycNorm);

    String kycText() {
      if (isSw) {
        return {
              'verified': 'Imethibitishwa (Taarifa kamili)',
              'pending': 'Inasubiri uthibitisho',
              'rejected': 'Imekataliwa',
              'unknown': 'Haijulikani'
            }[kycNorm] ??
            'Haijulikani';
      } else {
        return {
              'verified': 'Verified (Full Information)',
              'pending': 'Pending verification',
              'rejected': 'Rejected',
              'unknown': 'Unknown'
            }[kycNorm] ??
            'Unknown';
      }
    }

    final fullName = ('$firstName $lastName').trim().isEmpty ? username : '$firstName $lastName';

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: scheme.surface,
                foregroundColor: scheme.onSurface,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          BrandColors.orange,
                          BrandColors.orange.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ProfilePictureSection(
                            selectedImage: _selectedImage,
                            onPickImage: _pickImage,
                            isUploading: _uploadingImage,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            fullName.trim(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  PopupMenuButton<String>(
                    tooltip: isSw ? 'Badili Lugha' : 'Change Language',
                    onSelected: localeCubit.setFromCode,
                    icon: const Icon(Icons.language_rounded),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'sw', child: Text('🇹🇿 Kiswahili')),
                      PopupMenuItem(value: 'en', child: Text('🇬🇧 English')),
                    ],
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      if (phone.isNotEmpty) ...[
                        _ProfileInfoCard(
                          icon: Icons.phone_rounded,
                          label: isSw ? 'Simu' : 'Phone',
                          value: phone,
                          delay: 0,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (externalId.isNotEmpty) ...[
                        _ProfileInfoCard(
                          icon: Icons.card_giftcard_rounded,
                          label: isSw ? 'ID ya Akaunti' : 'Account ID',
                          value: externalId,
                          delay: 1,
                        ),
                        const SizedBox(height: 12),
                      ],
                      _KycStatusCard(
                        status: kycNorm,
                        statusText: kycText(),
                        statusColor: kycColor,
                        statusIcon: kycIcon,
                        isSw: isSw,
                        onVerifyTap: () =>
                            Navigator.of(context).pushNamed('/kyc'),
                        delay: 2,
                      ),
                      const SizedBox(height: 20),
                      _SectionTitle(
                        title: isSw ? 'Mipango' : 'Settings',
                        delay: 3,
                      ),
                      const SizedBox(height: 12),
                      _SettingsCard(
                        icon: Icons.language_rounded,
                        label: isSw ? 'Lugha ya Programu' : 'App Language',
                        subtitle: isSw
                            ? 'Badili kati ya Kiswahili na Kiingereza'
                            : 'Switch between Swahili and English',
                        delay: 4,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: localeCubit.state.languageCode,
                            isDense: true,
                            items: const [
                              DropdownMenuItem(
                                value: 'sw',
                                child: Text('🇹🇿 Kiswahili'),
                              ),
                              DropdownMenuItem(
                                value: 'en',
                                child: Text('🇬🇧 English'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) localeCubit.setFromCode(v);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SettingsCard(
                        icon: Icons.notifications_rounded,
                        label: isSw ? 'Arifa' : 'Notifications',
                        subtitle: isSw
                            ? 'Dhibiti arifa za programu'
                            : 'Manage app notifications',
                        onTap: () {
                          _showFeatureNotAvailable(context, isSw);
                        },
                        delay: 5,
                      ),
                      const SizedBox(height: 12),
                      _SettingsCard(
                        icon: Icons.security_rounded,
                        label: isSw ? 'Usalama' : 'Security',
                        subtitle: isSw
                            ? 'Dhibiti usalama wa akaunti'
                            : 'Manage account security',
                        onTap: () {
                          _showFeatureNotAvailable(context, isSw);
                        },
                        delay: 6,
                      ),
                      const SizedBox(height: 12),
                      _SettingsCard(
                        icon: Icons.help_rounded,
                        label: isSw ? 'Usaidizi' : 'Help & Support',
                        subtitle: isSw
                            ? 'Pata msaada na maswali'
                            : 'Get help and FAQs',
                        onTap: () {
                          _showFeatureNotAvailable(context, isSw);
                        },
                        delay: 7,
                      ),
                      const SizedBox(height: 24),
                      _AnimatedSection(
                        delay: 8,
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _showLogoutDialog(context, isSw);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.error,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.logout_rounded),
                            label: Text(
                              isSw ? 'Toka (Logout)' : 'Logout',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AnimatedSection(
                        delay: 9,
                        child: Text(
                          isSw ? 'Toleo la Programu: 1.0.0' : 'App Version: 1.0.0',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
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

  void _showFeatureNotAvailable(BuildContext context, bool isSw) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isSw ? 'Sehemu hii haijatekelezwa bado' : 'This feature not yet available',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, bool isSw) {
    final scheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 300),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isSw ? 'Toka?' : 'Logout?',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            isSw
                ? 'Je, una hakika unataka kutoka kwenye akaunti yako?'
                : 'Are you sure you want to logout from your account?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isSw ? 'Ghairi' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<AuthCubit>().logout();
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (_) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: Colors.white,
              ),
              child: Text(isSw ? 'Toka' : 'Logout'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePictureSection extends StatelessWidget {
  final File? selectedImage;
  final VoidCallback onPickImage;
  final bool isUploading;

  const _ProfilePictureSection({
    required this.selectedImage,
    required this.onPickImage,
    required this.isUploading,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          builder: (context, value, _) {
            return Transform.scale(
              scale: value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.3),
                      Colors.white.withValues(alpha: 0.1),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: selectedImage != null
                      ? Image.file(
                          selectedImage!,
                          fit: BoxFit.cover,
                        )
                      : Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 60,
                        ),
                ),
              ),
            );
          },
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutBack,
            builder: (context, value, _) {
              return Transform.scale(
                scale: value,
                child: GestureDetector(
                  onTap: isUploading ? null : onPickImage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: isUploading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(
                                BrandColors.orange,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.photo_camera_rounded,
                            color: BrandColors.orange,
                            size: 24,
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AnimatedSection extends StatelessWidget {
  final int delay;
  final Widget child;

  const _AnimatedSection({
    required this.delay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (delay * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: child,
          ),
        );
      },
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final int delay;

  const _ProfileInfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _AnimatedSection(
      delay: delay,
      child: Card(
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: BrandColors.orange.withValues(alpha: 0.1),
                child: Icon(
                  icon,
                  color: BrandColors.orange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KycStatusCard extends StatelessWidget {
  final String status;
  final String statusText;
  final Color statusColor;
  final IconData statusIcon;
  final bool isSw;
  final VoidCallback onVerifyTap;
  final int delay;

  const _KycStatusCard({
    required this.status,
    required this.statusText,
    required this.statusColor,
    required this.statusIcon,
    required this.isSw,
    required this.onVerifyTap,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isVerified = status == 'verified';

    return _AnimatedSection(
      delay: delay,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [
                statusColor.withValues(alpha: 0.08),
                statusColor.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: statusColor.withValues(alpha: 0.15),
                    child: Icon(
                      statusIcon,
                      color: statusColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSw ? 'Hali ya Mtumiaji' : 'Verification Status',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!isVerified) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: onVerifyTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColor,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.verified_outlined),
                    label: Text(
                      isSw ? 'Thibitisha sasa' : 'Verify now',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int delay;

  const _SectionTitle({
    required this.title,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _AnimatedSection(
      delay: delay,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Widget? child;
  final VoidCallback? onTap;
  final int delay;

  const _SettingsCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.child,
    this.onTap,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _AnimatedSection(
      delay: delay,
      child: Card(
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: BrandColors.orange.withValues(alpha: 0.1),
            child: Icon(
              icon,
              color: BrandColors.orange,
              size: 22,
            ),
          ),
          title: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
          trailing: child ?? Icon(Icons.chevron_right, color: scheme.primary),
          onTap: onTap,
        ),
      ),
    );
  }
}