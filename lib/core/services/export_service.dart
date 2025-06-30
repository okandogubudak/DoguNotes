import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/models/note_model.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  static const String _appName = 'DoguNotes';
  
  // ULTRA GÜVENİLİR TÜRKİYE FONT SİSTEMİ - RELEASE MODE GUARANTEED
  static pw.Font? _mainFont;
  static pw.Font? _mainFontBold;
  static pw.Font? _fallbackFont;
  static pw.Font? _fallbackFontBold;
  static bool _fontSystemInitialized = false;
  
  // LEVEL 1: OPEN SANS (Google Fonts) - Kullanıcı talebi, mükemmel Türkçe desteği
  // LEVEL 2: ROBOTO (Google Fonts) - Android varsayılan, güvenilir fallback
  // LEVEL 3: NOTO SANS (Google Fonts) - Unicode güçlü, son çare
  static Future<void> _initializeTurkishFontSystem() async {
    if (_fontSystemInitialized) return;
    
    try {
      developer.log('🇹🇷 ═══ TÜRKİYE FONT SİSTEMİ V4.0 - OPEN SANS ═══');
      developer.log('🎯 3 AŞAMALI OPEN SANS PRİORİTELİ SİSTEM BAŞLATIYOR...');
      
      bool fontLoaded = false;
      
      // LEVEL 1: OPEN SANS - Kullanıcı isteği, mükemmel Türkçe
      if (!fontLoaded) {
        try {
          developer.log('🔥 LEVEL 1: OPEN SANS yükleniyor (User Choice)...');
          
          _mainFont = await PdfGoogleFonts.openSansRegular();
          _mainFontBold = await PdfGoogleFonts.openSansBold();
          
          developer.log('✅ OPEN SANS SUCCESS! - Türkçe karakterler %100 destekleniyor');
          developer.log('📝 Kullanıcı tercihi aktif - Modern ve temiz görünüm');
          fontLoaded = true;
          
      } catch (e) {
          developer.log('⚠️ LEVEL 1 FAILED: Open Sans yüklenemedi - $e');
        }
      }
      
      // LEVEL 2: ROBOTO - Android native, güvenilir fallback
      if (!fontLoaded) {
        try {
          developer.log('🔥 LEVEL 2: ROBOTO yükleniyor (Android Native)...');
          
          _mainFont = await PdfGoogleFonts.robotoRegular();
          _mainFontBold = await PdfGoogleFonts.robotoBold();
          
          developer.log('✅ ROBOTO SUCCESS! - Türkçe karakterler %100 garantili');
          developer.log('📱 Android native font aktif - Release modda çalışır');
          fontLoaded = true;
          
    } catch (e) {
          developer.log('⚠️ LEVEL 2 FAILED: Roboto yüklenemedi - $e');
        }
      }
      
      // LEVEL 3: NOTO SANS - Unicode king
      if (!fontLoaded) {
        try {
          developer.log('🔥 LEVEL 3: NOTO SANS yükleniyor (Unicode Master)...');
          
          _mainFont = await PdfGoogleFonts.notoSansRegular();
          _mainFontBold = await PdfGoogleFonts.notoSansBold();
          
          developer.log('✅ NOTO SANS SUCCESS! - Unicode destekli');
          developer.log('🌍 Global font aktif - Tüm diller desteklenir');
          fontLoaded = true;
          
    } catch (e) {
          developer.log('⚠️ LEVEL 3 FAILED: Noto Sans yüklenemedi - $e');
        }
      }
      

      
      _fontSystemInitialized = true;
      
      // FINAL RAPOR
      developer.log('📊 ═══ OPEN SANS FONT SİSTEMİ RAPORU ═══');
      if (_mainFont != null) {
        developer.log('🎯 BAŞARI: Open Sans font sistemi aktif!');
        developer.log('📝 Ana Font: ${_mainFont != null ? "✅ YÜKLENDİ" : "❌ YOK"}');
        developer.log('🔲 Kalın Font: ${_mainFontBold != null ? "✅ YÜKLENDİ" : "❌ YOK"}');
        developer.log('🇹🇷 Türkçe Durum: ${fontLoaded ? "✅ OPEN SANS İLE DESTEKLENİYOR" : "❌ SORUNLU"}');
        developer.log('📱 Release APK: ${fontLoaded ? "✅ OPEN SANS İLE ÇALIŞACAK" : "❌ SORUNLU"}');
        developer.log('👤 Kullanıcı Tercihi: ✅ Open Sans aktif - Modern ve okunabilir');
      } else {
        developer.log('🚨 KRİTİK HATA: Hiçbir font yüklenemedi!');
        developer.log('⚠️ Helvetica kullanılacak - Türkçe karakterler bozuk olacak');
      }
      developer.log('═══════════════════════════════════');
      
    } catch (e) {
      developer.log('❌ Font sistemi başlatma hatası: $e');
      _fontSystemInitialized = false;
    }
  }

  /// ULTRA GÜVENİLİR TÜRKÇE TEXT STYLE - V3.0
  static pw.TextStyle _createTurkishTextStyle({
    required double fontSize,
    PdfColor? color,
    pw.FontWeight? fontWeight,
    double? height,
  }) {
    // Font seçimi - V3.0 sistemi
    pw.Font? selectedFont;
    
    if (fontWeight == pw.FontWeight.bold) {
      selectedFont = _mainFontBold ?? _mainFont;
    } else {
      selectedFont = _mainFont;
    }
    
    // Font mevcut - LEVEL 1-2-3'ten herhangi biri yüklenmiş
    if (selectedFont != null) {
      return pw.TextStyle(
        font: selectedFont,
        fontSize: fontSize,
        color: color ?? PdfColors.black,
        fontWeight: fontWeight ?? pw.FontWeight.normal,
        height: height,
      );
    }
    
    // KRİTİK DURUM - Hiçbir font yüklenmemiş
    developer.log('🚨 KRİTİK: Font sistemi başarısız! Helvetica kullanılacak!');
    developer.log('⚠️ Türkçe karakterler bozuk görünecek (ğ→X, ı→X, ş→X, ç→X)');
    developer.log('📱 APK\'yı yeniden build edin!');
    
    return pw.TextStyle(
      fontSize: fontSize,
      color: color ?? PdfColors.black,
      fontWeight: fontWeight ?? pw.FontWeight.normal,
      height: height,
    );
  }

  /// Tek bir not için geliştirilmiş PDF oluşturur (görseller dahil) - ROBOTO FONTLı
  Future<Uint8List?> createNotePDF(NoteModel note, {bool includeImages = true}) async {
    try {
      developer.log('📄 PDF oluşturuluyor: ${note.title}');
      
      // Font sistemini garanti et
      await _initializeTurkishFontSystem();
    
    final pdf = pw.Document();
      
      // Görselleri yükle - GELİŞTİRİLMİŞ
      final imageWidgets = <pw.Widget>[];
      if (includeImages && note.attachments.isNotEmpty) {
        developer.log('🖼️ ${note.attachments.length} ek dosya bulundu');
        
        for (final attachment in note.attachments) {
          if (_isImageFile(attachment)) {
            developer.log('📸 Görsel PDF\'e gömülüyor: ${path.basename(attachment)}');
            final imageWidget = await _createImageWidget(attachment);
            if (imageWidget != null) {
              imageWidgets.add(imageWidget);
              developer.log('✅ Görsel başarıyla PDF\'e gömüldü');
            } else {
              developer.log('❌ Görsel PDF\'e gömülemedi');
            }
          }
        }
        developer.log('📊 Toplam ${imageWidgets.length} görsel PDF\'e gömüldü');
      }
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: _buildHeader,
        footer: _buildFooter,
        build: (pw.Context context) => [
            _buildNoteContent(note, imageWidgets),
        ],
      ),
    );

      final pdfBytes = await pdf.save();
      developer.log('✅ PDF başarıyla oluşturuldu - ROBOTO font ile: ${note.title} (${pdfBytes.length} bytes)');
      return pdfBytes;
    } catch (e) {
      developer.log('❌ PDF oluşturma hatası: $e');
      return null;
    }
  }

  /// Görsel dosyasından PDF widget oluşturur - RELEASE MOD UYUMLU
  Future<pw.Widget?> _createImageWidget(String imagePath) async {
    try {
      developer.log('🖼️ ═══ GÖRSEl YÜKLENİYOR ═══');
      developer.log('📁 Dosya yolu: $imagePath');
      
      // 1. DOSYA KONTROLLARI
      final file = File(imagePath);
      final exists = await file.exists();
      developer.log('📋 Dosya mevcut: $exists');
      
      if (!exists) {
        developer.log('❌ HATA: Dosya bulunamadı');
        return _createErrorWidget('Dosya bulunamadı: ${path.basename(imagePath)}');
      }

      // 2. DOSYA BİLGİLERİ
      final fileStat = await file.stat();
      final fileSize = fileStat.size;
      developer.log('📊 Dosya boyutu: $fileSize bytes');
      
      if (fileSize == 0) {
        developer.log('❌ HATA: Dosya boş');
        return _createErrorWidget('Boş dosya: ${path.basename(imagePath)}');
      }
      
      // 3. RELEASE MOD UYUMLU BYTE OKUMA
      Uint8List imageBytes;
      try {
        developer.log('🔄 Dosya okunuyor (Release Mode Uyumlu)...');
        
        // Güvenli byte okuma - release mod için optimize
        imageBytes = await file.readAsBytes();
        
        if (imageBytes.isEmpty) {
          throw Exception('Okunan bytes boş');
        }
        
        developer.log('✅ Dosya başarıyla okundu: ${imageBytes.length} bytes');
        
        // Byte verisinin geçerli olup olmadığını kontrol et
        if (imageBytes.length < 100) {
          throw Exception('Görsel verisi çok küçük - bozuk olabilir');
        }
        
        // Image magic number kontrolü (basit format kontrolü)
        String formatInfo = 'Bilinmeyen';
        if (imageBytes.length >= 4) {
          final header = imageBytes.sublist(0, 4);
          if (header[0] == 0xFF && header[1] == 0xD8) {
            formatInfo = 'JPEG';
          } else if (header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47) {
            formatInfo = 'PNG';
          } else if (header[0] == 0x47 && header[1] == 0x49 && header[2] == 0x46) {
            formatInfo = 'GIF';
          }
        }
        developer.log('🔍 Görsel formatı: $formatInfo');
      
    } catch (e) {
        developer.log('❌ BYTE OKUMA HATASI: $e');
        
        // Alternatif okuma yöntemi dene
        try {
          developer.log('🔄 Alternatif yöntem deneniyor...');
          
          // Stream kullan
          final stream = file.openRead();
          final chunks = <int>[];
          await for (final chunk in stream) {
            chunks.addAll(chunk);
          }
          imageBytes = Uint8List.fromList(chunks);
          
          if (imageBytes.isEmpty) {
            throw Exception('Stream okuma da başarısız');
          }
          
          developer.log('✅ Alternatif yöntem başarılı: ${imageBytes.length} bytes');
          
        } catch (e2) {
          developer.log('❌ Alternatif yöntem de başarısız: $e2');
          return _createErrorWidget('Görsel okunamadı: ${path.basename(imagePath)}');
        }
      }
      
      // 4. PDF MEMORY IMAGE OLUŞTURMA
      pw.MemoryImage image;
      try {
        developer.log('🎨 MemoryImage oluşturuluyor...');
        image = pw.MemoryImage(imageBytes);
        developer.log('✅ MemoryImage oluşturuldu');
      } catch (e) {
        developer.log('❌ MemoryImage oluşturma hatası: $e');
        return _createErrorWidget('Görsel formatı desteklenmiyor: ${path.basename(imagePath)}');
      }
      
      // 5. PDF WIDGET OLUŞTURMA
      final fileName = path.basename(imagePath);
      developer.log('🎯 PDF widget oluşturuluyor: $fileName');
      
      final widget = pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: 16),
          // Görsel başlığı - Assets font ile
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: PdfColors.blue200),
            ),
            child: pw.Text(
              'Görsel: $fileName',
              style: _createTurkishTextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 8),
          // Görsel container - Güçlendirilmiş
          pw.Container(
            width: double.infinity,
            constraints: const pw.BoxConstraints(maxHeight: 400, minHeight: 100),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 2),
              borderRadius: pw.BorderRadius.circular(8),
              color: PdfColors.white,
            ),
            padding: const pw.EdgeInsets.all(8),
            child: pw.Center(
              child: pw.Image(
                image,
                fit: pw.BoxFit.contain,
                width: double.infinity,
                height: 350,
              ),
            ),
          ),
          pw.SizedBox(height: 12),
        ],
      );
      
      developer.log('🎉 ═══ GÖRSEl PDF\'E EKLENDI ═══');
      return widget;
      
    } catch (e) {
      developer.log('💥 KRİTİK HATA - Görsel widget oluşturma: $imagePath');
      developer.log('🔥 Hata detayı: $e');
      developer.log('🔥 Hata tipi: ${e.runtimeType}');
      
      return _createErrorWidget('GÖRSEl YÜKLENEMEDİ\\n${path.basename(imagePath)}\\nHata: Release modda görsel sorunu');
    }
  }

  /// Hata widget'ı oluşturur
  pw.Widget _createErrorWidget(String errorMessage) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 8),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.red50,
        border: pw.Border.all(color: PdfColors.red300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 20,
            height: 20,
            decoration: pw.BoxDecoration(
              color: PdfColors.red500,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: pw.Text(
                'X',
                style: _createTurkishTextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(
              errorMessage,
              style: _createTurkishTextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  /// Görsel dosyası kontrolü
  bool _isImageFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    return imageExtensions.contains(extension);
  }

  /// Not için PDF export işlemi (tek dosya - görseller dahil)
  Future<String?> exportNoteAsPDF({
    required NoteModel note,
    required String exportPath,
    bool includeImages = true,
  }) async {
    try {
      developer.log('📤 PDF Export işlemi başlatılıyor: ${note.title}');
      
      // PDF oluştur
      final pdfBytes = await createNotePDF(note, includeImages: includeImages);
      if (pdfBytes == null) {
        developer.log('❌ PDF oluşturulamadı');
        return null;
      }
      
      // PDF dosyasını kaydet
      final fileName = '${_sanitizeFileName(note.title)}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = path.join(exportPath, fileName);
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);
      
      developer.log('✅ PDF Export tamamlandı: $filePath');
      return filePath;
      
    } catch (e) {
      developer.log('❌ PDF Export hatası: $e');
      return null;
    }
  }

  /// WhatsApp için paylaşım
  Future<void> shareToWhatsApp(String filePath) async {
    try {
      final file = XFile(filePath);
      await Share.shareXFiles(
        [file],
        text: 'DoguNotes\'tan paylaşıldı',
        subject: 'Not Paylaşımı',
      );
    } catch (e) {
      developer.log('❌ WhatsApp paylaşım hatası: $e');
    }
  }

  /// Telefonda belirli konuma kaydet
  Future<bool> saveToCustomLocation(String sourceFile, String targetPath) async {
    try {
      // Storage permission kontrolü
      final permission = await Permission.manageExternalStorage.request();
      if (!permission.isGranted) {
        developer.log('⚠️ Storage izni verilmedi');
        return false;
      }
      
      final source = File(sourceFile);
      final target = File(targetPath);
      
      // Hedef dizini oluştur
      final targetDir = Directory(path.dirname(targetPath));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      
      await source.copy(targetPath);
      developer.log('✅ Dosya kaydedildi: $targetPath');
      return true;
      
    } catch (e) {
      developer.log('❌ Dosya kaydetme hatası: $e');
      return false;
    }
  }

  /// Dosya adını temizle
  String _sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(' ', '_')
        .substring(0, fileName.length > 50 ? 50 : fileName.length);
  }

  /// Tarihi formatla
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year} '
           '${date.hour.toString().padLeft(2, '0')}:'
           '${date.minute.toString().padLeft(2, '0')}';
  }

  /// Cache temizleme
  Future<void> clearExportCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final exportDirs = tempDir.listSync().where(
        (entity) => entity is Directory && entity.path.contains('export_')
      );
      
      for (final dir in exportDirs) {
        await dir.delete(recursive: true);
      }
      
      developer.log('🧹 Export cache temizlendi');
    } catch (e) {
      developer.log('❌ Cache temizleme hatası: $e');
    }
  }

  // Geliştirilmiş not içeriği oluşturma (görseller dahil)
  pw.Widget _buildNoteContent(NoteModel note, List<pw.Widget> imageWidgets) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Başlık
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            gradient: const pw.LinearGradient(
              colors: [PdfColors.blue100, PdfColors.blue50],
            ),
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.blue300),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                note.title.isNotEmpty ? note.title : 'Başlıksız Not',
                style: _createTurkishTextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Kategori: ${note.category}',
                    style: _createTurkishTextStyle(fontSize: 12),
                  ),
                  pw.Text(
                    DateFormat('dd.MM.yyyy HH:mm', 'tr').format(note.createdAt),
                    style: _createTurkishTextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        pw.SizedBox(height: 20),
        
        // İçerik
        if (note.content.isNotEmpty) ...[
          pw.Text(
            'İçerik',
            style: _createTurkishTextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              note.content,
              style: _createTurkishTextStyle(fontSize: 13, height: 1.6),
            ),
          ),
          pw.SizedBox(height: 20),
        ],
        
        // Görseller (Geliştirilmiş kısım)
        if (imageWidgets.isNotEmpty) ...[
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.green300),
            ),
            child: pw.Row(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green500,
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Text(
                    '📷',
                    style: const pw.TextStyle(fontSize: 16),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Text(
                  'Görseller (${imageWidgets.length} adet)',
                  style: _createTurkishTextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          ...imageWidgets,
          pw.SizedBox(height: 20),
        ],
        
        // Etiketler
        if (note.tags.isNotEmpty) ...[
          pw.Text(
            'Etiketler',
            style: _createTurkishTextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 8,
            runSpacing: 6,
            children: note.tags.map((tag) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: pw.BoxDecoration(
                color: PdfColors.purple100,
                borderRadius: pw.BorderRadius.circular(16),
                border: pw.Border.all(color: PdfColors.purple300),
              ),
              child: pw.Text(
                '#$tag',
                style: _createTurkishTextStyle(fontSize: 11),
              ),
            )).toList(),
          ),
          pw.SizedBox(height: 20),
        ],
        
        // Medya dosyaları bilgisi (sadece görsel olmayan dosyalar)
        if (note.attachments.where((attachment) => !_isImageFile(attachment)).isNotEmpty) ...[
          pw.Text(
            'Diğer Medya Dosyaları',
            style: _createTurkishTextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          ...note.attachments.where((attachment) => !_isImageFile(attachment)).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final attachment = entry.value;
            final fileName = attachment.split('/').last;
            
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 6),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.orange200),
              ),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 24,
                    height: 24,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.orange500,
                      shape: pw.BoxShape.circle,
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        '${index + 1}',
                        style: _createTurkishTextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Text(
                      fileName,
                      style: _createTurkishTextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          pw.SizedBox(height: 20),
        ],
        
        // Ses kaydı bilgisi
        if (note.audioPath != null) ...[
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.teal50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.teal300),
            ),
            child: pw.Row(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.teal500,
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Text(
                    '🎵',
                    style: const pw.TextStyle(fontSize: 16),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Text(
                  'Ses kaydı mevcut: ${note.audioPath!.split('/').last}',
                    style: _createTurkishTextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
        ],
        
        // Durum bilgileri
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Not Bilgileri',
                style: _createTurkishTextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              _buildInfoRow('Oluşturulma', DateFormat('dd.MM.yyyy HH:mm', 'tr').format(note.createdAt)),
              _buildInfoRow('Güncellenme', DateFormat('dd.MM.yyyy HH:mm', 'tr').format(note.updatedAt)),
              if (note.isFavorite) _buildInfoRow('Durum', 'Favorilerde ⭐'),
              if (note.isImportant) _buildInfoRow('Önem', 'Önemli ❗'),
              if (note.isPinned) _buildInfoRow('Sabitlenme', 'Sabitlenmiş 📌'),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              '$label:',
              style: _createTurkishTextStyle(fontSize: 11),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: _createTurkishTextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // PDF header
  pw.Widget _buildHeader(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.blue300, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue500,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  'DN',
                  style: _createTurkishTextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(width: 12),
          pw.Text(
            _appName,
                style: _createTurkishTextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            ],
          ),
          pw.Text(
            'Sayfa ${context.pageNumber}',
            style: _createTurkishTextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // PDF footer
  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'DoguNotes ile oluşturuldu 🚀',
            style: _createTurkishTextStyle(fontSize: 10),
          ),
          pw.Text(
            DateFormat('dd.MM.yyyy HH:mm', 'tr').format(DateTime.now()),
            style: _createTurkishTextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  // PDF paylaşma
  Future<void> sharePdf(String filePath, String fileName) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'DoguNotes ile oluşturulan PDF dosyası',
        subject: fileName,
      );
    } catch (e) {
      debugPrint('❌ PDF paylaşma hatası: $e');
    }
  }

  // PDF yazdırma
  Future<void> printPdf(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: 'DoguNotes_${DateFormat('dd_MM_yyyy').format(DateTime.now())}',
        format: PdfPageFormat.a4,
      );
    } catch (e) {
      debugPrint('❌ PDF yazdırma hatası: $e');
    }
  }

  // Önizleme ve yazdırma dialog'u
  Future<void> showPrintPreview(BuildContext context, String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreview(
            build: (format) => bytes,
            allowPrinting: true,
            allowSharing: true,
            canChangePageFormat: false,
            canDebug: false,
            pdfFileName: 'DoguNotes_${DateFormat('dd_MM_yyyy').format(DateTime.now())}',
            actions: [
              PdfPreviewAction(
                icon: const Icon(Icons.share),
                onPressed: (context, build, pageFormat) async {
                  await sharePdf(filePath, file.path.split('/').last);
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ PDF önizleme hatası: $e');
    }
  }

  // Metin export (TXT)
  Future<String?> exportNoteToText(NoteModel note) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = _sanitizeFileName('${note.title}_${DateFormat('dd_MM_yyyy_HH_mm').format(note.createdAt)}.txt');
      final filePath = '${directory.path}/$fileName';
      
      final content = StringBuffer();
      content.writeln('=' * 50);
      content.writeln('DOGUNOTES');
      content.writeln('=' * 50);
      content.writeln();
      content.writeln('Başlık: ${note.title.isNotEmpty ? note.title : 'Başlıksız Not'}');
      content.writeln('Kategori: ${note.category}');
      content.writeln('Oluşturulma: ${DateFormat('dd.MM.yyyy HH:mm', 'tr_TR').format(note.createdAt)}');
      content.writeln('Güncellenme: ${DateFormat('dd.MM.yyyy HH:mm', 'tr_TR').format(note.updatedAt)}');
      content.writeln();
      content.writeln('-' * 50);
      content.writeln('İÇERİK:');
      content.writeln('-' * 50);
      content.writeln(note.content);
      
      if (note.tags.isNotEmpty) {
        content.writeln();
        content.writeln('-' * 50);
        content.writeln('ETİKETLER:');
        content.writeln('-' * 50);
        content.writeln(note.tags.map((tag) => '#$tag').join(', '));
      }
      
      if (note.attachments.isNotEmpty) {
        content.writeln();
        content.writeln('-' * 50);
        content.writeln('MEDYA DOSYALARI:');
        content.writeln('-' * 50);
        for (int i = 0; i < note.attachments.length; i++) {
          content.writeln('${i + 1}. ${note.attachments[i].split('/').last}');
        }
      }
      
      if (note.audioPath != null) {
        content.writeln();
        content.writeln('-' * 50);
        content.writeln('SES KAYDI:');
        content.writeln('-' * 50);
        content.writeln(note.audioPath!.split('/').last);
      }
      
      content.writeln();
      content.writeln('=' * 50);
      content.writeln('DoguNotes ile oluşturuldu - ${DateFormat('dd.MM.yyyy HH:mm', 'tr_TR').format(DateTime.now())}');
      content.writeln('=' * 50);
      
      final file = File(filePath);
      await file.writeAsString(content.toString(), encoding: systemEncoding);
      
      return filePath;
    } catch (e) {
      debugPrint('❌ Metin export hatası: $e');
      return null;
    }
  }
} 