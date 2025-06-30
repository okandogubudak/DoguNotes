import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen>
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
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.article_rounded,
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
                            'Hizmet Şartları',
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
              ..._buildTermsSections(isDarkMode),
              
              // Agreement Section
              Container(
                margin: const EdgeInsets.only(top: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981).withOpacity(0.1),
                      const Color(0xFF059669).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Anlaşma Kabulu',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Uygulamayı kullanarak bu şartları kabul etmiş sayılırsınız.',
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
        'Hizmet Şartları',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
    );
  }

  List<Widget> _buildTermsSections(bool isDarkMode) {
    final sections = [
      {
        'title': '1. Hizmet Tanımı',
        'content': 'Bu uygulama, kullanıcıların notlarını güvenli bir şekilde oluşturmasına, düzenlemesine ve saklamasına olanak tanıyan bir not alma uygulamasıdır. Tüm veriler kullanıcının cihazında yerel olarak saklanır.',
        'icon': Icons.description_rounded,
      },
      {
        'title': '2. Kullanım Koşulları',
        'content': 'Bu uygulamayı yalnızca yasal amaçlar için kullanabilirsiniz. Uygulamayı zararlı, yasadışı veya başkalarının haklarını ihlal edecek şekilde kullanamazsınız.',
        'icon': Icons.rule_rounded,
      },
      {
        'title': '3. Kullanıcı Sorumlulukları',
        'content': 'Kullanıcılar, oluşturdukları içerikten sorumludur. PIN kodunuzu güvenli tutmak ve cihazınızın güvenliğini sağlamak sizin sorumluluğunuzdadır.',
        'icon': Icons.person_rounded,
      },
      {
        'title': '4. Fikri Mülkiyet',
        'content': 'Uygulama ve içerdiği tüm yazılım, tasarım ve özellikler telif hakkı ile korunmaktadır. Kullanıcılar yalnızca kullanım hakkına sahiptir.',
        'icon': Icons.copyright_rounded,
      },
      {
        'title': '5. Hizmet Sınırlamaları',
        'content': 'Uygulama "olduğu gibi" sağlanır. Hizmet kesintileri, veri kaybı veya diğer teknik problemlerden dolayı sorumluluk kabul edilmez.',
        'icon': Icons.warning_rounded,
      },
      {
        'title': '6. Güncelleme ve Değişiklik',
        'content': 'Bu şartlar herhangi bir zamanda değiştirilebilir. Önemli değişiklikler uygulama güncellemeleri ile duyurulacaktır.',
        'icon': Icons.update_rounded,
      },
      {
        'title': '7. Hesap Sonlandırma',
        'content': 'Kullanıcılar istediği zaman uygulamayı silebilir. Bu durumda tüm yerel veriler otomatik olarak silinecektir.',
        'icon': Icons.exit_to_app_rounded,
      },
      {
        'title': '8. Destek ve İletişim',
        'content': 'Teknik destek ve sorularınız için uygulama içindeki iletişim kanallarını kullanabilirsiniz. En kısa sürede geri dönüş sağlanmaya çalışılır.',
        'icon': Icons.support_agent_rounded,
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
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            section['icon'] as IconData,
            color: const Color(0xFF10B981),
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