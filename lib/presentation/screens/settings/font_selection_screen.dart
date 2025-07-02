import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/theme_provider.dart';

class FontSelectionScreen extends StatefulWidget {
  const FontSelectionScreen({super.key});

  @override
  State<FontSelectionScreen> createState() => _FontSelectionScreenState();
}

class _FontSelectionScreenState extends State<FontSelectionScreen> {
  bool _fontsLoaded = false;

  // Sadece Google Fonts (garanti çalışan)
  final List<Map<String, String>> _fonts = [
    {'name': 'Default', 'displayName': 'Varsayılan (Sistem)', 'type': 'system'},
    {'name': 'Roboto', 'displayName': 'Roboto', 'type': 'google'},
    {'name': 'Open Sans', 'displayName': 'Open Sans', 'type': 'google'},
    {'name': 'Lato', 'displayName': 'Lato', 'type': 'google'},
    {'name': 'Poppins', 'displayName': 'Poppins', 'type': 'google'},
    {'name': 'Nunito', 'displayName': 'Nunito', 'type': 'google'},
    {'name': 'Inter', 'displayName': 'Inter', 'type': 'google'},
    {'name': 'Source Sans Pro', 'displayName': 'Source Sans Pro', 'type': 'google'},
    {'name': 'Montserrat', 'displayName': 'Montserrat', 'type': 'google'},
    {'name': 'Playfair Display', 'displayName': 'Playfair Display', 'type': 'google'},
    {'name': 'Merriweather', 'displayName': 'Merriweather', 'type': 'google'},
    {'name': 'Ubuntu', 'displayName': 'Ubuntu', 'type': 'google'},
    {'name': 'Dancing Script', 'displayName': 'Dancing Script', 'type': 'google'},
    {'name': 'Comfortaa', 'displayName': 'Comfortaa', 'type': 'google'},
  ];

  @override
  void initState() {
    super.initState();
    _preloadFonts();
  }

  // Font tipine göre TextStyle döndürür
  TextStyle _getFontTextStyle(Map<String, String> font, double fontSize, FontWeight fontWeight, Color color) {
    final name = font['name']!;
    final type = font['type']!;
    
    if (type == 'system' || name == 'Default') {
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    }
    
    if (type == 'google') {
      try {
        switch (name) {
          case 'Roboto':
            return GoogleFonts.roboto(fontSize: fontSize, fontWeight: fontWeight, color: color);
          case 'Open Sans':
            return GoogleFonts.openSans(fontSize: fontSize, fontWeight: fontWeight, color: color);
          case 'Lato':
            return GoogleFonts.lato(fontSize: fontSize, fontWeight: fontWeight, color: color);
          case 'Poppins':
            return GoogleFonts.poppins(fontSize: fontSize, fontWeight: fontWeight, color: color);
          case 'Nunito':
            return GoogleFonts.nunito(fontSize: fontSize, fontWeight: fontWeight, color: color);
          case 'Inter':
            return GoogleFonts.inter(fontSize: fontSize, fontWeight: fontWeight, color: color);
          case 'Source Sans Pro':
            return GoogleFonts.getFont('Source Sans Pro', fontSize: fontSize, fontWeight: fontWeight, color: color);
          case 'Montserrat':
            return GoogleFonts.montserrat(fontSize: fontSize, fontWeight: fontWeight, color: color);
          case 'Playfair Display':
            return GoogleFonts.getFont('Playfair Display', fontSize: fontSize, fontWeight: fontWeight, color: color);
          case 'Merriweather':
            return GoogleFonts.getFont('Merriweather', fontSize: fontSize, fontWeight: fontWeight, color: color);
          case 'Ubuntu':
            return GoogleFonts.ubuntu(fontSize: fontSize, fontWeight: fontWeight, color: color);
          case 'Dancing Script':
            return GoogleFonts.dancingScript(fontSize: fontSize, fontWeight: fontWeight, color: color);
          case 'Comfortaa':
            return GoogleFonts.comfortaa(fontSize: fontSize, fontWeight: fontWeight, color: color);
          default:
            return GoogleFonts.getFont(name, fontSize: fontSize, fontWeight: fontWeight, color: color);
        }
      } catch (e) {
        return TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color);
      }
    }
    
    return TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color);
  }

  Future<void> _preloadFonts() async {
    // Asset fontları yükle
    for (final f in _fonts) {
      final family = f['name']!;
      final type = f['type']!;
      final path = f['file'];
      
      if (type == 'system' || type == 'google') continue; // Google Fonts otomatik yüklenir
      
      if (type == 'asset' && path != null && path.isNotEmpty) {
        try {
          final loader = FontLoader(family)..addFont(rootBundle.load(path));
          await loader.load();
          print('Asset font yüklendi: $family');
        } catch (e) {
          print('Asset font yükleme hatası ($family): $e');
        }
      }
    }
    if (mounted) setState(() => _fontsLoaded = true);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final currentFont = Provider.of<ThemeProvider>(context).fontFamily;

    if (!_fontsLoaded) {
      return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(centerTitle: true,title: const Text('Yazı Tipi Seç'),backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Yazı Tipi Seç'),
        backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDarkMode ? Colors.white : const Color(0xFF334155)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _fonts.length,
        itemBuilder: (context, index) {
          final font = _fonts[index];
          final name = font['name']!;
          final displayName = font['displayName'] ?? name;

          final isSelected = currentFont == name;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected 
                    ? const Color(0xFF3B82F6)
                    : (isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.06),
                  blurRadius: isSelected ? 12 : 8,
                  offset: Offset(0, isSelected ? 4 : 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
                  final type = font['type']!;
                  
                  if (type == 'google') {
                    // Google font seçildi
                    await themeProvider.setGoogleFont(name);
                  } else {
                    // System veya asset font seçildi
                    await themeProvider.setFontFamily(name, assetPath: font['file']);
                  }
                  
                  if (context.mounted) Navigator.pop(context);
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: _getFontTextStyle(font, 18, FontWeight.w600, isDarkMode ? Colors.white : const Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Örnek metin: DoguNotes uygulamasında bu yazı tipi böyle görünecek. Türkçe karakterler: ğüşıöç',
                              style: _getFontTextStyle(font, 14, FontWeight.normal, isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B)).copyWith(height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (isSelected)
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        )
                      else
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDarkMode ? const Color(0xFF475569) : const Color(0xFFD1D5DB),
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 