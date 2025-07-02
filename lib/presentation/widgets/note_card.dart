import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/note_model.dart';
import '../providers/theme_provider.dart';

class NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isGridView; // Grid mi List mi gösterimi

  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onLongPress,
    this.isGridView = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode; // Koyu tema kontrolü
    final color = _parseColor(note.color); // Kategori rengini al

    return Hero(
      tag: 'note-${note.id}', // Sayfa geçişlerinde animasyon için
      child: Container(
        height: 200, // Sabit yükseklik - Grid ve List'te aynı
        margin: const EdgeInsets.all(4), // Kartlar arası boşluk
        child: Material(
          color: Colors.transparent,
          child: InkWell( // Dokunma efektleri için
            onTap: () {
              HapticFeedback.lightImpact(); // Hafif titreşim
              onTap?.call();
            },
            onLongPress: () {
              HapticFeedback.mediumImpact(); // Orta titreşim
              onLongPress?.call();
            },
            borderRadius: BorderRadius.circular(16), // Yuvarlatılmış köşeler
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16), // Yuvarlatılmış köşeler
                color: isDarkMode 
                    ? const Color(0xFF1E293B) // Koyu tema rengi
                    : Colors.white, // Açık tema rengi
                border: Border.all(color: color.withOpacity(0.33), width: .75), // Kategori renginde çerçeve
                boxShadow: [ // Gölge efektleri
                  BoxShadow( // Ana gölge
                    color: Colors.black.withOpacity(isDarkMode ? 0.21 : 0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow( // Kategori renginde glow efekti
                    color: color.withOpacity(isDarkMode ? 0.42 : 0.28),
                    blurRadius: 12,
                    spreadRadius: 1,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(4), // İç boşluk
                child: Column( // Dikey sıralama
                  children: [
                    // BAŞLIK BÖLÜMÜ - En üstte, merkezi
                    SizedBox(
                      height: 30, // Başlık alanının yüksekliği
                      child: Stack( // Üst üste yerleştirme için
                        children: [
                          // Başlık metni - Her zaman merkezi, otomatik boyut ayarlama
                          Center(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final maxWidth = constraints.maxWidth - 40; // Pin/favorite ikonları için yer bırak
                                return Container(
                                  constraints: BoxConstraints(maxWidth: maxWidth),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown, // Yazıyı küçült, büyütme
                                    child: Text(
                                      note.title.isNotEmpty ? note.title : 'Başlıksız Not',
                                      textAlign: TextAlign.center, // Merkezi hizalama
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold, // Kalın yazı
                                        color: isDarkMode ? Colors.white : Colors.black,
                                        fontSize: isGridView ? 16 : 15, // Grid/List için farklı varsayılan boyut
                                      ),
                                      maxLines: 1, // Tek satır
                                      overflow: TextOverflow.ellipsis, // Uzun başlıkları "..." ile kes
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Pin ve Favori simgeleri - Sağ tarafta
                          if (note.isPinned || note.isFavorite)
                            Positioned( // Sabit konum
                              right: 0, // Sağ tarafa yasla
                              top: 8, // Üstten 5px aşağı
                              child: Row( // Yan yana sıralama
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (note.isPinned) // Eğer sabitlenmişse
                                    const Icon(
                                      Icons.push_pin,
                                      size: 14,
                                      color: Colors.orange, // Turuncu pin simgesi
                                    ),
                                  if (note.isPinned && note.isFavorite) // Her ikisi varsa araya boşluk
                                    const SizedBox(width: 0),
                                  if (note.isFavorite) // Eğer favoriyse
                                    const Icon(
                                      Icons.favorite,
                                      size: 14,
                                      color: Colors.red, // Kırmızı kalp simgesi
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 4), // Başlık ile içerik arası boşluk
                    
                    // İÇERİK BÖLÜMÜ - Defter çizgileri ile
                    Expanded( // Kalan alanı kapla
                      child: SizedBox(
                        width: double.infinity, // Tam genişlik
                        child: CustomPaint( // Özel çizim (defter çizgileri)
                          painter: NotebookLinesPainter( // Çizgi çizen sınıf
                            isDarkMode: isDarkMode,
                            isGridView: isGridView,
                          ),
                          child: Container(
                            padding: const EdgeInsets.only(left: 6, right: 6, top: 2),
                            child: Text(
                              note.content.isNotEmpty ? note.content : '',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white.withOpacity(0.9)
                                    : Colors.black87,
                                fontSize: 13,
                                height: 1.8,
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: isGridView ? 3 : 6,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8), // İçerik ile footer arası boşluk
                    
                    // FOOTER BÖLÜMÜ - Tarih merkezi, medya simgeleri solda
                    SizedBox(
                      height: 25, // Footer yüksekliği
                      child: Stack( // Üst üste yerleştirme
                        children: [
                          // Tarih - Her zaman merkezi
                          Center(
                            child: Text(
                              _formatDate(note.updatedAt), // Tarihi formatla
                              style: TextStyle(
                                color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.5), // Yarı opak
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Medya simgeleri - Sol tarafta
                          if (note.attachments.isNotEmpty || note.audioPath != null)
                            Positioned( // Sabit konum
                              left: 0, // Sol tarafa yasla
                              top: 0, // Üstten 5px aşağı
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (note.attachments.isNotEmpty) // Eğer ek dosya varsa
                                    Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      child: Icon(
                                        Icons.attach_file,
                                        size: 10,
                                        color: Colors.blue.withOpacity(0.7), // Mavi ataşman simgesi
                                      ),
                                    ),
                                  if (note.audioPath != null) // Eğer ses kaydı varsa
                                    Icon(
                                      Icons.mic,
                                      size: 14,
                                      color: Colors.green.withOpacity(0.7), // Yeşil mikrofon simgesi
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
          ),
        ),
      ),
    );
  }

  // Renk string'ini Color objesine çevir
  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.substring(1, 7), radix: 16) + 0xFF000000);
    } catch (e) {
      return const Color(0xFF3B82F6); // Hata durumunda varsayılan mavi
    }
  }

  // Tarihi okunabilir formata çevir
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Şimdi';
        }
        return '${difference.inMinutes} dakika önce';
      }
      return '${difference.inHours} saat önce';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}

// Defter çizgilerini çizen özel sınıf
class NotebookLinesPainter extends CustomPainter {
  final bool isDarkMode; // Tema bilgisi
  final bool isGridView; // Grid/List görünüm bilgisi

  NotebookLinesPainter({
    required this.isDarkMode,
    required this.isGridView,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint() // Çizgi çizme ayarları
      ..color = (isDarkMode ? Colors.white : Colors.grey.shade300).withOpacity(0.3) // Çizgi rengi
      ..strokeWidth = 0.7 // Çizgi kalınlığı
      ..style = PaintingStyle.stroke; // Çizgi stili

    // Yazı ile çizgilerin uyumlu olması için hesaplamalar - Gerçek defter gibi
    const double fontSize = 13.0; // Yazı boyutu
    const double lineHeight = 1.8; // Satır yükseklik çarpanı (text style ile aynı)
    const double lineSpacing = fontSize * lineHeight; // Satırlar arası mesafe
    const double textTopPadding = 2.0; // Container'daki top padding ile uyumlu
    const double baselineOffset = fontSize * 1.82; // Çizgiyi yazının altına koymak için
    
    // Grid için 3, List için 6 yatay çizgi çiz - yazıların altında (gerçek defter gibi)
    final lineCount = isGridView ? 3 : 6;
    for (int i = 0; i < lineCount; i++) {
      // Her satırın altındaki çizgiyi hesapla (yazının altına çizgi)
      final lineY = textTopPadding + baselineOffset + (i * lineSpacing);
      
      if (lineY < size.height - 2) { // Alan içinde kalırsa çiz
        canvas.drawLine(
          Offset(6, lineY), // Başlangıç noktası (soldan 6px)
          Offset(size.width - 6, lineY), // Bitiş noktası (sağdan 6px)
          paint, // Çizgi ayarları
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false; // Yeniden çizilsin mi?
}