import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:misana_finance_app/core/theme/app_theme.dart';
import 'package:misana_finance_app/core/i18n/locale_cubit.dart';
import 'package:misana_finance_app/auth/session/auth_cubit.dart';

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
  static const _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://misana-backend-misanaapi-h3pnbw-4233c5-138-68-41-254.traefik.me/api/v1',
  );

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

  static const _strings = {
    'edit_profile': {'sw': 'Hariri Wasifu', 'en': 'Edit Profile'},
    'change_language': {'sw': 'Badili Lugha', 'en': 'Change Language'},
    'swahili': {'sw': 'Kiswahili', 'en': 'Swahili'},
    'english': {'sw': 'Kiingereza', 'en': 'English'},
    'phone': {'sw': 'Simu', 'en': 'Phone'},
    'account_id': {'sw': 'ID ya Akaunti', 'en': 'Account ID'},
    'settings': {'sw': 'Mipango', 'en': 'Settings'},
    'app_language': {'sw': 'Lugha ya Programu', 'en': 'App Language'},
    'lang_desc': {'sw': 'Badili kati ya Kiswahili na Kiingereza', 'en': 'Switch between Swahili and English'},
    'notifications': {'sw': 'Arifa', 'en': 'Notifications'},
    'notif_desc': {'sw': 'Dhibiti arifa za programu', 'en': 'Manage app notifications'},
    'security': {'sw': 'Usalama', 'en': 'Security'},
    'sec_desc': {'sw': 'Dhibiti usalama wa akaunti', 'en': 'Manage account security'},
    'help': {'sw': 'Usaidizi', 'en': 'Help & Support'},
    'help_desc': {'sw': 'Pata msaada na maswali', 'en': 'Get help and FAQs'},
    'logout': {'sw': 'Toka', 'en': 'Logout'},
    'logout_q': {'sw': 'Toka?', 'en': 'Logout?'},
    'logout_confirm': {'sw': 'Je, una hakika unataka kutoka kwenye akaunti yako?', 'en': 'Are you sure you want to logout from your account?'},
    'cancel': {'sw': 'Ghairi', 'en': 'Cancel'},
    'save': {'sw': 'Hifadhi', 'en': 'Save'},
    'app_version': {'sw': 'Toleo la Programu', 'en': 'App Version'},
    'feature_unavailable': {'sw': 'Sehemu hii haijatekelezwa bado', 'en': 'This feature not yet available'},
    'first_name': {'sw': 'Jina la Kwanza', 'en': 'First Name'},
    'last_name': {'sw': 'Jina la Ukoo', 'en': 'Last Name'},
    'phone_number': {'sw': 'Namba ya Simu', 'en': 'Phone Number'},
    'profile_updated': {'sw': 'Picha ya wasifu imesasishwa kikamilifu', 'en': 'Profile picture updated successfully'},
    'image_size_error': {'sw': 'Ukubwa wa picha lazima uwe chini ya 10MB', 'en': 'Image size must be less than 10MB'},
    'library_denied': {'sw': 'Ruhusa ya maktaba ya picha imekataliwa. Tafadhali wezesha kwenye mipangilio.', 'en': 'Photo library access denied. Please enable it in settings.'},
    'image_cancelled': {'sw': 'Uchaguzi wa picha umeghairiwa', 'en': 'Image selection cancelled'},
    'picker_error': {'sw': 'Imeshindikana kufungua kichagua picha. Tafadhali jaribu tena.', 'en': 'Failed to open image picker. Please try again.'},
    'pick_error': {'sw': 'Imeshindikana kuchagua picha', 'en': 'Failed to pick image'},
    'kyc_verified': {'sw': 'Imethibitishwa (Taarifa kamili)', 'en': 'Verified (Full Information)'},
    'kyc_pending': {'sw': 'Inasubiri uthibitisho', 'en': 'Pending verification'},
    'kyc_rejected': {'sw': 'Imekataliwa', 'en': 'Rejected'},
    'kyc_unknown': {'sw': 'Haijulikani', 'en': 'Unknown'},
  };

  String _translate(String key, String lang) {
    return _strings[key]?[lang] ?? key;
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

  String? _resolveProfileUrl(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/')) {
      return '$_apiBaseUrl$value';
    }
    return null;
  }

  Future<void> _pickImage() async {
    final lang = context.read<LocaleCubit>().state.languageCode;
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
          _showUploadError(_translate('image_size_error', lang));
          return;
        }

        if (!mounted) return;
        setState(() {
          _selectedImage = file;
          _uploadingImage = true;
        });

        try {
          await context.read<AuthCubit>().uploadProfilePicture(file);
          
          if (mounted) {
            setState(() {
              _uploadingImage = false;
            });
            _showUploadSuccess(lang);
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _selectedImage = null;
              _uploadingImage = false;
            });
            _showUploadError(_translate('pick_error', lang));
          }
        }
      }
    } on Exception catch (e) {
      _showUploadError(_parseImagePickerError(e, lang));
    }
  }

  String _parseImagePickerError(Exception e, String lang) {
    final errorString = e.toString().toLowerCase();

    if (errorString.contains('permission') || errorString.contains('denied')) {
      return _translate('library_denied', lang);
    }
    if (errorString.contains('cancelled')) {
      return _translate('image_cancelled', lang);
    }
    if (errorString.contains('plugin')) {
      return _translate('picker_error', lang);
    }

    return _translate('pick_error', lang);
  }

  void _showUploadSuccess(String lang) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _translate('profile_updated', lang),
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

  Widget _buildProfileImage(Map<String, dynamic> user) {
    final profilePicture = user['profile_picture'] as String?;
    
    if (profilePicture != null && profilePicture.isNotEmpty) {
      final resolvedUrl = _resolveProfileUrl(profilePicture);
      if (resolvedUrl != null) {
        return Image.network(
          resolvedUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 60,
            );
          },
        );
      }

      try {
        final base64Data = profilePicture.contains(',') ? profilePicture.split(',').last : profilePicture;
        final imageBytes = base64Decode(base64Data);
        return Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 60,
            );
          },
        );
      } catch (_) {
        return const Icon(
          Icons.person_rounded,
          color: Colors.white,
          size: 60,
        );
      }
    }
    
    // Show selected image during upload or default avatar
    return _selectedImage != null
        ? Image.file(
            _selectedImage!,
            fit: BoxFit.cover,
          )
        : Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 60,
          );
  }

  @override
  Widget build(BuildContext context) {
    final localeCubit = context.watch<LocaleCubit>();
    final lang = localeCubit.state.languageCode;
    final isSw = lang == 'sw';
    String t(String key) => _translate(key, lang);
    
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
      return {
            'verified': t('kyc_verified'),
            'pending': t('kyc_pending'),
            'rejected': t('kyc_rejected'),
            'unknown': t('kyc_unknown')
          }[kycNorm] ??
          t('kyc_unknown');
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
                            user: user,
                            apiBaseUrl: _apiBaseUrl,
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
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => _showEditProfileDialog(context, user, lang),
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            label: Text(
                              t('edit_profile'),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  PopupMenuButton<String>(
                    tooltip: t('change_language'),
                    onSelected: localeCubit.setFromCode,
                    icon: const Icon(Icons.language_rounded),
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'sw', child: Text('🇹🇿 ${t('swahili')}')),
                      PopupMenuItem(value: 'en', child: Text('🇬🇧 ${t('english')}')),
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
                          label: t('phone'),
                          value: phone,
                          delay: 0,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (externalId.isNotEmpty) ...[
                        _ProfileInfoCard(
                          icon: Icons.card_giftcard_rounded,
                          label: t('account_id'),
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
                        title: t('settings'),
                        delay: 3,
                      ),
                      const SizedBox(height: 12),
                      _SettingsCard(
                        icon: Icons.language_rounded,
                        label: t('app_language'),
                        subtitle: t('lang_desc'),
                        delay: 4,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: localeCubit.state.languageCode,
                            isDense: true,
                            items: [
                              DropdownMenuItem(
                                value: 'sw',
                                child: Text('🇹🇿 ${t('swahili')}'),
                              ),
                              DropdownMenuItem(
                                value: 'en',
                                child: Text('🇬🇧 ${t('english')}'),
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
                        label: t('notifications'),
                        subtitle: t('notif_desc'),
                        onTap: () {
                          Navigator.of(context).pushNamed('/notifications');
                        },
                        delay: 5,
                      ),
                      const SizedBox(height: 12),
                      _SettingsCard(
                        icon: Icons.security_rounded,
                        label: t('security'),
                        subtitle: t('sec_desc'),
                        onTap: () {
                          Navigator.of(context).pushNamed('/security');
                        },
                        delay: 6,
                      ),
                      const SizedBox(height: 12),
                      _SettingsCard(
                        icon: Icons.help_rounded,
                        label: t('help'),
                        subtitle: t('help_desc'),
                        onTap: () {
                          Navigator.of(context).pushNamed('/help-support');
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
                              _showLogoutDialog(context, lang);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.error,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.logout_rounded),
                            label: Text(
                              t('logout'),
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
                          '${t('app_version')}: 1.0.0',
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

  void _showFeatureNotAvailable(BuildContext context, String lang) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _translate('feature_unavailable', lang),
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

  void _showLogoutDialog(BuildContext context, String lang) {
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
            _translate('logout_q', lang),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            _translate('logout_confirm', lang),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_translate('cancel', lang)),
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
              child: Text(_translate('logout', lang)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, Map<String, dynamic> user, String lang) {
    final firstNameController = TextEditingController(text: user['first_name']?.toString() ?? '');
    final lastNameController = TextEditingController(text: user['last_name']?.toString() ?? '');
    final phoneController = TextEditingController(text: user['phone']?.toString() ?? '');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_translate('edit_profile', lang)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameController,
                decoration: InputDecoration(
                  labelText: _translate('first_name', lang),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lastNameController,
                decoration: InputDecoration(
                  labelText: _translate('last_name', lang),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: _translate('phone_number', lang),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_translate('cancel', lang)),
          ),
          ElevatedButton(
            onPressed: () {
              final data = {
                'first_name': firstNameController.text,
                'last_name': lastNameController.text,
                'phone': phoneController.text,
              };
              context.read<AuthCubit>().updateUserProfile(data);
              Navigator.pop(ctx);
            },
            child: Text(_translate('save', lang)),
          ),
        ],
      ),
    );
  }
}

class _ProfilePictureSection extends StatelessWidget {
  final File? selectedImage;
  final VoidCallback onPickImage;
  final bool isUploading;
  final Map<String, dynamic> user;
  final String apiBaseUrl;

  const _ProfilePictureSection({
    required this.selectedImage,
    required this.onPickImage,
    required this.isUploading,
    required this.user,
    required this.apiBaseUrl,
  });

  String? _resolveProfileUrl(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/')) {
      return '$apiBaseUrl$value';
    }
    return null;
  }

  Widget _buildProfileImage() {
    final profilePicture = user['profile_picture'] as String?;
    
    if (profilePicture != null && profilePicture.isNotEmpty && selectedImage == null) {
      try {
        final resolvedUrl = _resolveProfileUrl(profilePicture);
        if (resolvedUrl != null) {
          return Image.network(
            resolvedUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 60,
              );
            },
          );
        }

        final base64Data = profilePicture.contains(',') ? profilePicture.split(',').last : profilePicture;
        final imageBytes = base64Decode(base64Data);
        return Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 60,
            );
          },
        );
      } catch (e) {
        // If Base64 decoding fails, show default avatar
        return const Icon(
          Icons.person_rounded,
          color: Colors.white,
          size: 60,
        );
      }
    }
    
    // Show selected image during upload or default avatar
    return selectedImage != null
        ? Image.file(
            selectedImage!,
            fit: BoxFit.cover,
          )
        : Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 60,
          );
  }

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
                  child: _buildProfileImage(),
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
