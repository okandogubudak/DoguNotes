import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: _buildProfessionalAppBar(isDarkMode),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.privacy_tip_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gizlilik Politikası',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Son güncellenme: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode 
                                  ? const Color(0xFF94A3B8) 
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Content Sections
              ..._buildPrivacyPolicySections(isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildProfessionalAppBar(bool isDarkMode) {
    return AppBar(
      backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: isDarkMode ? Colors.white : const Color(0xFF334155),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Gizlilik Politikası',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
    );
  }

  List<Widget> _buildPrivacyPolicySections(bool isDarkMode) {
    final sections = [
      {
        'title': '1. Veri Toplama',
        'content': 'Uygulamamız, yalnızca cihazınızda yerel olarak saklanan notlarınızı yönetir. Hiçbir kişisel veriniz sunucularımıza gönderilmez veya üçüncü taraflarla paylaşılmaz.',
        'icon': Icons.data_usage_rounded,
      },
      {
        'title': '2. Veri Saklama',
        'content': 'Tüm notlarınız ve ayarlarınız cihazınızın yerel depolama alanında saklanır. Bu veriler yalnızca sizin kontrolünüzdedir ve uygulama dışından erişilemez.',
        'icon': Icons.storage_rounded,
      },
      {
        'title': '3. Güvenlik',
        'content': 'Verilerinizin güvenliği için PIN kodu koruma sistemi kullanıyoruz. PIN kodunuz cihazınızda şifrelenmiş olarak saklanır ve hiçbir zaman dışarıya gönderilmez.',
        'icon': Icons.security_rounded,
      },
      {
        'title': '4. İzinler',
        'content': 'Uygulama yalnızca gerekli izinleri talep eder: depolama (medya dosyaları için), mikrofon (ses kaydı için) ve kamera (fotoğraf çekimi için). Bu izinler sadece ilgili özellikler kullanıldığında aktif olur.',
        'icon': Icons.admin_panel_settings_rounded,
      },
      {
        'title': '5. Çocukların Gizliliği',
        'content': 'Uygulamamız 13 yaş altındaki çocuklardan bilerek kişisel bilgi toplamaz. Ebeveynlerin çocuklarının internet aktivitelerini izlemelerini öneririz.',
        'icon': Icons.child_care_rounded,
      },
      {
        'title': '6. Değişiklikler',
        'content': 'Bu gizlilik politikasında yapılacak değişiklikler uygulama güncellemeleri ile birlikte duyurulacaktır. Düzenli olarak kontrol etmenizi öneririz.',
        'icon': Icons.update_rounded,
      },
      {
        'title': '7. İletişim',
        'content': 'Gizlilik politikamız hakkında sorularınız varsa, uygulama içindeki iletişim bölümünden bize ulaşabilirsiniz.',
        'icon': Icons.contact_support_rounded,
      },
    ];

    return sections.map((section) => Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            section['icon'] as IconData,
            color: const Color(0xFF6366F1),
            size: 20,
          ),
        ),
        title: Text(
          section['title'] as String,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              section['content'] as String,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDarkMode 
                    ? const Color(0xFF94A3B8) 
                    : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    )).toList();
  }
} 