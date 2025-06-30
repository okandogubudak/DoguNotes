import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/export_service.dart';
import '../../providers/theme_provider.dart';
import '../../providers/notes_provider.dart';
import '../auth/pin_setup_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import 'category_management_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../auth/splash_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  final PermissionService _permissionService = PermissionService();
  
  Map<String, bool> _permissions = {};
  
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final permissions = <String, bool>{};
    permissions['Kamera'] = await _permissionService.isCameraPermissionGranted();
    permissions['Mikrofon'] = await _permissionService.isMicrophonePermissionGranted();
    permissions['Bildirimler'] = await _permissionService.isNotificationPermissionGranted();
    
    setState(() {
      _permissions = permissions;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: _buildProfessionalAppBar(isDarkMode),
      body: _buildProfessionalBody(isDarkMode),
    );
  }

  PreferredSizeWidget _buildProfessionalAppBar(bool isDarkMode) {
    return AppBar(
      backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      elevation: 0,
      toolbarHeight: 72,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: isDarkMode ? Colors.white : const Color(0xFF334155),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.settings_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Ayarlar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
    );
  }

  Widget _buildProfessionalBody(bool isDarkMode) {
    return Container(
      color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Güvenlik
          _buildSectionTitle('Güvenlik', Icons.security_rounded, isDarkMode),
          const SizedBox(height: 12),
          _buildPinChangeCard(isDarkMode),
          
          const SizedBox(height: 32),
          
          // Kategoriler
          _buildSectionTitle('Kategoriler', Icons.category_rounded, isDarkMode),
          const SizedBox(height: 12),
          _buildCategoryManagementCard(isDarkMode),
          
          const SizedBox(height: 32),
          
          // İzinler
          _buildSectionTitle('İzinler', Icons.admin_panel_settings_rounded, isDarkMode),
          const SizedBox(height: 12),
          _buildPermissionsCard(isDarkMode),
          
          const SizedBox(height: 32),
          
          // Veri Yönetimi
          _buildSectionTitle('Veri Yönetimi', Icons.storage_rounded, isDarkMode),
          const SizedBox(height: 12),
          _buildDataManagementCards(isDarkMode),
          
          const SizedBox(height: 32),
          
          // İletişim
          _buildSectionTitle('İletişim', Icons.contact_support_rounded, isDarkMode),
          const SizedBox(height: 12),
          _buildContactCard(isDarkMode),
          
          const SizedBox(height: 32),
          
          // Hakkında
          _buildSectionTitle('Hakkında', Icons.info_rounded, isDarkMode),
          const SizedBox(height: 12),
          _buildAboutCards(isDarkMode),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDarkMode) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF3B82F6),
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildPinChangeCard(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _navigateToPinSetup,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Color(0xFF3B82F6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PIN Değiştir',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Güvenlik PIN\'ini güncelle',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryManagementCard(bool isDarkMode) {
    return _buildActionCard(
      icon: Icons.category_rounded,
      iconColor: const Color(0xFF3B82F6),
      title: 'Kategori Yönetimi',
      subtitle: 'Kategorileri düzenleyin',
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const CategoryManagementScreen(),
          ),
        );
      },
      isDarkMode: isDarkMode,
    );
  }

  Widget _buildPermissionsCard(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Color(0xFFF59E0B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Uygulama İzinleri',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Verilen izinleri görüntüle',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Permissions List
          if (_permissions.isNotEmpty) ...[
            Container(
              height: 1,
              color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            ..._permissions.entries.map((entry) {
              final isGranted = entry.value;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isGranted ? null : () => _requestPermission(entry.key),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getPermissionIcon(entry.key),
                          color: isGranted ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          size: 20,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (isGranted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Aktif',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'İzin Ver',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 10,
                                  color: Color(0xFFEF4444),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    size: 20,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'İzinler kontrol ediliyor...',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataManagementCards(bool isDarkMode) {
    return Column(
      children: [
        // Export Data
        _buildActionCard(
          icon: Icons.file_download_rounded,
          iconColor: const Color(0xFF3B82F6),
          title: 'Verileri Dışa Aktar',
          subtitle: 'Notlarınızı yedekleyin',
          onTap: _exportData,
          isDarkMode: isDarkMode,
        ),
        
        const SizedBox(height: 12),
        
        // Import Data
        _buildActionCard(
          icon: Icons.file_upload_rounded,
          iconColor: const Color(0xFF10B981),
          title: 'Verileri İçe Aktar',
          subtitle: 'Yedekten notları geri yükleyin',
          onTap: _importData,
          isDarkMode: isDarkMode,
        ),
        
        const SizedBox(height: 12),
        
        // Clear All Data
        _buildActionCard(
          icon: Icons.delete_forever_rounded,
          iconColor: const Color(0xFFEF4444),
          title: 'Tüm Verileri Sil',
          subtitle: 'Bu işlem geri alınamaz',
          onTap: _clearAllData,
          isDarkMode: isDarkMode,
          isDestructive: true,
        ),
        
        const SizedBox(height: 12),
        
        // Reset App
        _buildActionCard(
          icon: Icons.restart_alt_rounded,
          iconColor: const Color(0xFF6366F1),
          title: 'Uygulamayı Sıfırla',
          subtitle: 'Tüm veriler silinir ve uygulama ilk kurulumuna döner',
          onTap: _resetApplication,
          isDarkMode: isDarkMode,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildContactCard(bool isDarkMode) {
    return _buildActionCard(
      icon: Icons.email_rounded,
      iconColor: const Color(0xFF10B981),
      title: 'İletişim',
      subtitle: 'okandogubudak@gmail.com',
      onTap: _openContactEmail,
      isDarkMode: isDarkMode,
    );
  }

  Widget _buildAboutCards(bool isDarkMode) {
    return Column(
      children: [
        // App Version
        _buildInfoCard(
          icon: Icons.info_outline_rounded,
          iconColor: const Color(0xFF3B82F6),
          title: 'Uygulama Sürümü',
          subtitle: AppConstants.appVersion,
          isDarkMode: isDarkMode,
        ),
        
        const SizedBox(height: 12),
        
        // Privacy Policy
        _buildActionCard(
          icon: Icons.privacy_tip_outlined,
          iconColor: const Color(0xFF10B981),
          title: 'Gizlilik Politikası',
          subtitle: 'Veri kullanım politikamızı okuyun',
          onTap: _openPrivacyPolicy,
          isDarkMode: isDarkMode,
        ),
        
        const SizedBox(height: 12),
        
        // Terms of Service
        _buildActionCard(
          icon: Icons.description_outlined,
          iconColor: const Color(0xFFF59E0B),
          title: 'Kullanım Şartları',
          subtitle: 'Hizmet şartlarımızı görüntüleyin',
          onTap: _openTermsOfService,
          isDarkMode: isDarkMode,
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDarkMode,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDestructive 
            ? const Color(0xFFEF4444).withOpacity(isDarkMode ? 0.1 : 0.05)
            : isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDestructive 
              ? const Color(0xFFEF4444).withOpacity(0.3)
              : isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDestructive 
                              ? const Color(0xFFEF4444)
                              : isDarkMode ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDestructive 
                              ? const Color(0xFFEF4444).withOpacity(0.7)
                              : isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isDestructive 
                      ? const Color(0xFFEF4444)
                      : isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDarkMode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPermissionIcon(String permission) {
    switch (permission) {
      case 'Kamera':
        return Icons.camera_alt_rounded;
      case 'Mikrofon':
        return Icons.mic_rounded;

      case 'Bildirimler':
        return Icons.notifications_rounded;
      default:
        return Icons.security_rounded;
    }
  }

  void _navigateToPinSetup() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PinSetupScreen(isFirstTime: false),
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      // Kullanıcıya seçenek sun
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Verileri Dışa Aktar'),
          content: const Text('Verilerinizi nereye kaydetmek istiyorsunuz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('device'),
              child: const Text('Cihaza Kaydet'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('share'),
              child: const Text('Paylaş'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('İptal'),
            ),
          ],
        ),
      );

      if (choice == null) return;

      final notesProvider = Provider.of<NotesProvider>(context, listen: false);
      
      if (choice == 'device') {
        final success = await notesProvider.exportNotes();
        if (success) {
          _showSnackBar('Veriler cihaza başarıyla kaydedildi');
        } else {
          _showSnackBar('Veri dışa aktarımı başarısız', isError: true);
        }
      } else if (choice == 'share') {
        final success = await notesProvider.shareNotes();
        if (success) {
          _showSnackBar('Veriler paylaşıldı');
        } else {
          _showSnackBar('Veri paylaşımı başarısız', isError: true);
        }
      }
    } catch (e) {
      _showSnackBar('Bir hata oluştu: $e', isError: true);
    }
  }

  Future<void> _importData() async {
    try {
      final notesProvider = Provider.of<NotesProvider>(context, listen: false);
      final success = await notesProvider.importNotes();
      
      if (success) {
        _showSnackBar('Veriler başarıyla içe aktarıldı');
      } else {
        _showSnackBar('Veri içe aktarımı başarısız', isError: true);
      }
    } catch (e) {
      _showSnackBar('Bir hata oluştu: $e', isError: true);
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Tüm Verileri Sil'),
        content: const Text(
          'Bu işlem tüm notlarınızı kalıcı olarak silecektir. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.clearAllData();
        final notesProvider = Provider.of<NotesProvider>(context, listen: false);
        await notesProvider.loadNotes();
        _showSnackBar('Tüm veriler silindi');
      } catch (e) {
        _showSnackBar('Veri silme işlemi başarısız: $e', isError: true);
      }
    }
  }

  void _openPrivacyPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyScreen(),
      ),
    );
  }

  void _openTermsOfService() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TermsOfServiceScreen(),
      ),
    );
  }

  Future<void> _openContactEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'okandogubudak@gmail.com',
      query: 'subject=DoguNotes İletişim&body=Merhaba DoguNotes ekibi,%0A%0A',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } else {
      // E-posta açılamazsa kullanıcıya bilgi ver
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('E-posta Açılamadı'),
          content: const Text(
            'E-posta uygulaması bulunamadı. Lütfen manuel olarak iletişime geçin:\n\nokandogubudak@gmail.com'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: 'okandogubudak@gmail.com'));
                Navigator.pop(context);
                _showSnackBar('E-posta adresi kopyalandı');
              },
              child: const Text('Kopyala'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _requestPermission(String permissionName) async {
    try {
      PermissionStatus status = PermissionStatus.denied;
      
      switch (permissionName) {
        case 'Kamera':
          status = await _permissionService.requestCameraPermission();
          break;
        case 'Mikrofon':
          status = await _permissionService.requestMicrophonePermission();
          break;

        case 'Bildirimler':
          status = await _permissionService.requestNotificationPermission();
          break;
      }
      
      final granted = status == PermissionStatus.granted;
      
      if (granted) {
        _showSnackBar('$permissionName izni verildi');
        _checkPermissions(); // İzinleri yenile
      } else {
        _showSnackBar('$permissionName izni reddedildi', isError: true);
        // Ayarlar sayfasına yönlendir
        await openAppSettings();
      }
    } catch (e) {
      _showSnackBar('İzin isteği sırasında hata oluştu: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError 
            ? const Color(0xFFEF4444) 
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _resetApplication() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uygulamayı Sıfırla'),
        content: const Text('Bu işlem tüm notları, kategorileri, PIN kodunu ve önbelleği siler. Uygulama ilk kurulumuna dönecek. Devam etmek istiyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sıfırla', style: TextStyle(color: Color(0xFFEF4444)))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final dbService = DatabaseService();
      await dbService.clearAllData();

      // Clear user categories
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_categories');

      // İsteğe bağlı: geçici önbellek klasörünü temizle
      try {
        final tempDir = await getTemporaryDirectory();
        await tempDir.delete(recursive: true);
      } catch (_) {}

      // Clear auth (PIN) and mark first time
      final authService = AuthService();
      await authService.clearAuthData();
      await authService.setFirstTime(true);

      // Navigate to splash by clearing stack
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sıfırlama başarısız: $e')),
        );
      }
    }
  }
} 