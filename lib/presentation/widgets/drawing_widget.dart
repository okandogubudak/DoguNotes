import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../core/theme/app_theme.dart';
import '../providers/theme_provider.dart';

class DrawingWidget extends StatefulWidget {
  final String? backgroundImagePath;
  final Function(String)? onSaveDrawing;
  final double width;
  final double height;

  const DrawingWidget({
    super.key,
    this.backgroundImagePath,
    this.onSaveDrawing,
    this.width = 350,
    this.height = 400,
  });

  @override
  State<DrawingWidget> createState() => _DrawingWidgetState();
}

class _DrawingWidgetState extends State<DrawingWidget>
    with TickerProviderStateMixin {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final List<DrawingPath> _paths = [];
  final List<List<DrawingPath>> _undoHistory = [];
  final List<TextOverlay> _textOverlays = [];
  int? _selectedTextIndex;
  bool _isDraggingText = false;
  int? _selectedShapeIndex;
  bool _isDraggingShape = false;
  Offset? _dragOffset;
  
  DrawingTool _currentTool = DrawingTool.pen;
  Color _currentColor = AppTheme.primaryColor;
  double _currentStrokeWidth = 3.0;
  bool _isDrawing = false;
  Offset? _currentPoint;
  Offset? _startPoint;
  ui.Image? _backgroundImage;
  bool _isLoadingImage = true;
  String? _loadError;

  // Professional Animation Controllers
  late AnimationController _toolbarController;
  late AnimationController _fadeController;
  late Animation<double> _toolbarAnimation;
  late Animation<double> _fadeAnimation;

  // Professional Color Palette - Using AppTheme colors
  final List<Color> _colorPalette = [
    AppTheme.primaryColor,
    AppTheme.secondaryColor,
    AppTheme.accentColor,
    AppTheme.errorColor,
    AppTheme.successColor,
    AppTheme.warningColor,
    Colors.black,
    Colors.white,
    const Color(0xFF6366F1), // Indigo
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEC4899), // Pink
    const Color(0xFF06B6D4), // Cyan
  ];

  // Professional Brush Sizes
  final List<double> _brushSizes = [1.0, 2.0, 4.0, 6.0, 8.0, 12.0];

  @override
  void initState() {
    super.initState();
    _initializeProfessionalAnimations();
    _loadBackgroundImage();
  }

  void _initializeProfessionalAnimations() {
    _toolbarController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _toolbarAnimation = CurvedAnimation(
      parent: _toolbarController,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Start animations
    _toolbarController.forward();
    _fadeController.forward();
  }

  Future<void> _loadBackgroundImage() async {
    if (widget.backgroundImagePath != null) {
      debugPrint('DrawingWidget - Loading background image: ${widget.backgroundImagePath}');
      setState(() {
        _isLoadingImage = true;
        _loadError = null;
      });
      
      try {
        final file = File(widget.backgroundImagePath!);
        debugPrint('DrawingWidget - File exists: ${await file.exists()}');
        
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          debugPrint('DrawingWidget - File size: ${bytes.length} bytes');
          
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          
          setState(() {
            _backgroundImage = frame.image;
            _isLoadingImage = false;
          });
          debugPrint('DrawingWidget - Background image loaded successfully');
        } else {
          setState(() {
            _isLoadingImage = false;
            _loadError = 'Resim dosyası bulunamadı';
          });
          debugPrint('DrawingWidget - Background image file does not exist');
        }
      } catch (e) {
        setState(() {
          _isLoadingImage = false;
          _loadError = 'Resim yüklenirken hata oluştu: $e';
        });
        debugPrint('DrawingWidget - Error loading background image: $e');
      }
    } else {
      setState(() {
        _isLoadingImage = false;
        _loadError = 'Düzenlenecek resim belirtilmedi';
      });
      debugPrint('DrawingWidget - No background image path provided');
    }
  }

  @override
  void dispose() {
    _toolbarController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.backgroundGradient(isDarkMode),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            _buildProfessionalHeader(isDarkMode),
            Expanded(
              child: _buildDrawingArea(isDarkMode),
            ),
            _buildProfessionalToolbar(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalHeader(bool isDarkMode) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(_toolbarAnimation),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassContainer(isDarkMode),
        child: Row(
          children: [
            Icon(
              Icons.draw_rounded,
              color: AppTheme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Çizim Düzenleyici',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? AppTheme.darkText : AppTheme.lightText,
              ),
            ),
            const Spacer(),
                         _buildProfessionalHeaderButton(
               icon: Icons.undo_rounded,
               onTap: _canUndo ? _undo : null,
               tooltip: 'Geri Al',
               isDarkMode: isDarkMode,
             ),
            const SizedBox(width: 8),
            _buildProfessionalHeaderButton(
              icon: Icons.clear_rounded,
              onTap: _clearCanvas,
              tooltip: 'Temizle',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(width: 8),
            _buildProfessionalHeaderButton(
              icon: Icons.save_rounded,
              onTap: _saveDrawing,
              tooltip: 'Kaydet',
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalHeaderButton({
    required IconData icon,
    VoidCallback? onTap,
    required String tooltip,
    required bool isDarkMode,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: onTap != null 
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: onTap != null 
                    ? AppTheme.primaryColor.withOpacity(0.2)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: onTap != null 
                  ? AppTheme.primaryColor
                  : (isDarkMode ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawingArea(bool isDarkMode) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: widget.width,
        height: widget.height,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withOpacity(0.95) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: RepaintBoundary(
            key: _repaintBoundaryKey,
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: CustomPaint(
                painter: DrawingPainter(
                  paths: _paths,
                  textOverlays: _textOverlays,
                  backgroundImage: _backgroundImage,
                  currentPoint: _currentPoint,
                  startPoint: _startPoint,
                  currentTool: _currentTool,
                  currentColor: _currentColor,
                  currentStrokeWidth: _currentStrokeWidth,
                  isDrawing: _isDrawing,
                ),
                size: Size(widget.width, widget.height),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalToolbar(bool isDarkMode) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(_toolbarAnimation),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassContainer(isDarkMode),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tools Row
            _buildToolsRow(isDarkMode),
            const SizedBox(height: 16),
            // Colors Row
            _buildColorsRow(isDarkMode),
            const SizedBox(height: 16),
            // Brush Sizes Row
            _buildBrushSizesRow(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsRow(bool isDarkMode) {
    final tools = [
      (DrawingTool.pen, Icons.edit_rounded, 'Kalem'),
      (DrawingTool.brush, Icons.brush_rounded, 'Fırça'),
      (DrawingTool.eraser, Icons.auto_fix_high_rounded, 'Silgi'),
      (DrawingTool.line, Icons.horizontal_rule_rounded, 'Çizgi'),
      (DrawingTool.rectangle, Icons.crop_square_rounded, 'Kare'),
      (DrawingTool.circle, Icons.circle_outlined, 'Daire'),
      (DrawingTool.text, Icons.text_fields_rounded, 'Metin'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: tools.map((tool) {
        final isSelected = _currentTool == tool.$1;
        return _buildToolButton(
          tool: tool.$1,
          icon: tool.$2,
          label: tool.$3,
          isSelected: isSelected,
          isDarkMode: isDarkMode,
        );
      }).toList(),
    );
  }

  Widget _buildToolButton({
    required DrawingTool tool,
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isDarkMode,
  }) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _currentTool = tool),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppTheme.primaryColor
                  : AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected 
                  ? Colors.white
                  : AppTheme.primaryColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorsRow(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _colorPalette.map((color) {
        final isSelected = _currentColor == color;
        return _buildColorButton(
          color: color,
          isSelected: isSelected,
          isDarkMode: isDarkMode,
        );
      }).toList(),
    );
  }

  Widget _buildColorButton({
    required Color color,
    required bool isSelected,
    required bool isDarkMode,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _currentColor = color),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected 
                  ? AppTheme.primaryColor
                  : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrushSizesRow(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _brushSizes.map((size) {
        final isSelected = _currentStrokeWidth == size;
        return _buildBrushSizeButton(
          size: size,
          isSelected: isSelected,
          isDarkMode: isDarkMode,
        );
      }).toList(),
    );
  }

  Widget _buildBrushSizeButton({
    required double size,
    required bool isSelected,
    required bool isDarkMode,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _currentStrokeWidth = size),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isSelected 
                ? AppTheme.primaryColor.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected 
                  ? AppTheme.primaryColor
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: _currentColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    final point = details.localPosition;
    
    // Check if we're clicking on a text overlay
    for (int i = 0; i < _textOverlays.length; i++) {
      final textOverlay = _textOverlays[i];
      final textBounds = Rect.fromCenter(
        center: textOverlay.position,
        width: textOverlay.text.length * 12.0, // Approximate width
        height: textOverlay.fontSize + 10,
      );
      
      if (textBounds.contains(point)) {
        setState(() {
          _selectedTextIndex = i;
          _isDraggingText = true;
        });
        return;
      }
    }
    
    // Check if we're clicking on a shape (only rectangle and circle for now)
    for (int i = _paths.length - 1; i >= 0; i--) {
      final path = _paths[i];
      if (path.tool == DrawingTool.rectangle || path.tool == DrawingTool.circle) {
        if (path.points.length >= 2) {
          final rect = Rect.fromPoints(path.points.first, path.points.last);
          if (rect.contains(point)) {
            setState(() {
              _selectedShapeIndex = i;
              _isDraggingShape = true;
              _dragOffset = point - rect.center;
            });
            return;
          }
        }
      }
    }
    
    setState(() {
      _selectedTextIndex = null;
      _isDraggingText = false;
      _selectedShapeIndex = null;
      _isDraggingShape = false;
      _isDrawing = true;
      _startPoint = point;
      _currentPoint = point;
      
      // Kalem ve fırça için hemen yeni path oluştur
      if (_currentTool == DrawingTool.pen || _currentTool == DrawingTool.brush) {
        _paths.add(DrawingPath(
          points: [point],
          color: _currentColor,
          strokeWidth: _currentStrokeWidth,
          tool: _currentTool,
        ));
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final point = details.localPosition;
    
    if (_isDraggingText && _selectedTextIndex != null) {
      // Drag text overlay
      setState(() {
        _textOverlays[_selectedTextIndex!] = _textOverlays[_selectedTextIndex!].copyWith(
          position: point,
        );
      });
      return;
    }
    
    if (_isDraggingShape && _selectedShapeIndex != null && _dragOffset != null) {
      // Drag shape
      setState(() {
        final path = _paths[_selectedShapeIndex!];
        final newCenter = point - _dragOffset!;
        final rect = Rect.fromPoints(path.points.first, path.points.last);
        final size = rect.size;
        
        _paths[_selectedShapeIndex!] = DrawingPath(
          points: [
            newCenter - Offset(size.width / 2, size.height / 2),
            newCenter + Offset(size.width / 2, size.height / 2),
          ],
          color: path.color,
          strokeWidth: path.strokeWidth,
          tool: path.tool,
        );
      });
      return;
    }
    
    if (!_isDrawing) return;
    
    setState(() {
      _currentPoint = point;
      
      // Kalem ve fırça için devam eden noktaları ekle
      if (_currentTool == DrawingTool.pen || _currentTool == DrawingTool.brush) {
        if (_paths.isNotEmpty) {
          _paths.last.points.add(point);
        }
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isDraggingText) {
      setState(() {
        _isDraggingText = false;
        _selectedTextIndex = null;
      });
      return;
    }
    
    if (_isDraggingShape) {
      setState(() {
        _isDraggingShape = false;
        _selectedShapeIndex = null;
        _dragOffset = null;
      });
      return;
    }
    
    if (!_isDrawing) return;
    
    setState(() {
      _isDrawing = false;
      
      // Şekil çizim araçları için path oluştur (kalem/fırça zaten oluşturuldu)
      if (_currentTool != DrawingTool.pen && _currentTool != DrawingTool.brush) {
        if (_startPoint != null && _currentPoint != null) {
          _paths.add(DrawingPath(
            points: [_startPoint!, _currentPoint!],
            color: _currentColor,
            strokeWidth: _currentStrokeWidth,
            tool: _currentTool,
          ));
        }
      }
      
      // Undo history'ye ekle
      _saveToHistory();
      
      _startPoint = null;
      _currentPoint = null;
    });
  }

  void _saveToHistory() {
    _undoHistory.add(List<DrawingPath>.from(_paths));
    if (_undoHistory.length > 20) {
      _undoHistory.removeAt(0);
    }
  }

  void _undo() {
    if (_undoHistory.isNotEmpty) {
      setState(() {
        _undoHistory.removeLast();
        if (_undoHistory.isNotEmpty) {
          _paths.clear();
          _paths.addAll(_undoHistory.last);
        } else {
          _paths.clear();
        }
      });
    }
  }

  void _clearCanvas() {
    setState(() {
      _paths.clear();
      _textOverlays.clear();
      _undoHistory.clear();
    });
  }

  Future<String?> _saveDrawing() async {
    try {
      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Çizim kaydedilemedi: Render hatası')),
        );
        return null;
      }

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Çizim kaydedilemedi: Veri hatası')),
        );
        return null;
      }

      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final fileName = 'Dogu_Drawing_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = path.join(tempDir.path, fileName);
      
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Çizim başarıyla kaydedildi!'),
          backgroundColor: Colors.green,
        ),
      );
      
      if (widget.onSaveDrawing != null) {
        widget.onSaveDrawing!(filePath);
      }
      
      // Kaydetme sonrası geri dön
      Navigator.of(context).pop(filePath);
      
      return filePath;
    } catch (e) {
      debugPrint('Çizim kaydetme hatası: $e');
      return null;
    }
  }

  bool get _canUndo => _undoHistory.isNotEmpty;

  DrawingPath? _getCurrentPreviewPath() {
    if (_startPoint == null || _currentPoint == null) return null;
    
    // Sadece şekil araçları için preview göster
    if (_currentTool == DrawingTool.pen || _currentTool == DrawingTool.brush) {
      return null; // Kalem/fırça için preview yok
    }
    
    return DrawingPath(
      points: [_startPoint!, _currentPoint!],
      color: _currentColor.withOpacity(0.5), // Preview için şeffaf
      strokeWidth: _currentStrokeWidth,
      tool: _currentTool,
    );
  }
}

// Çizim araçları enum'u
enum DrawingTool {
  pen,
  brush,
  eraser,
  line,
  rectangle,
  circle,
  text,
}

// Çizim yolu modeli
class DrawingPath {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final DrawingTool tool;

  DrawingPath({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.tool,
  });
}

// Metin overlay modeli
class TextOverlay {
  final String text;
  final Offset position;
  final Color color;
  final double fontSize;

  TextOverlay({
    required this.text,
    required this.position,
    required this.color,
    required this.fontSize,
  });
  
  TextOverlay copyWith({
    String? text,
    Offset? position,
    Color? color,
    double? fontSize,
  }) {
    return TextOverlay(
      text: text ?? this.text,
      position: position ?? this.position,
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}

// Custom painter
class DrawingPainter extends CustomPainter {
  final List<DrawingPath> paths;
  final DrawingPath? currentPath;
  final List<TextOverlay> textOverlays;
  final ui.Image? backgroundImage;
  final Offset? currentPoint;
  final Offset? startPoint;
  final DrawingTool currentTool;
  final Color currentColor;
  final double currentStrokeWidth;
  final bool isDrawing;

  DrawingPainter({
    required this.paths,
    this.currentPath,
    required this.textOverlays,
    this.backgroundImage,
    this.currentPoint,
    this.startPoint,
    required this.currentTool,
    required this.currentColor,
    required this.currentStrokeWidth,
    required this.isDrawing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Arka plan resmi çiz
    if (backgroundImage != null) {
      canvas.drawImageRect(
        backgroundImage!,
        Rect.fromLTWH(0, 0, backgroundImage!.width.toDouble(), backgroundImage!.height.toDouble()),
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint(),
      );
    } else {
      // Beyaz arka plan
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white,
      );
    }

    // Tamamlanmış yolları çiz
    for (final path in paths) {
      _drawPath(canvas, path);
    }

    // Geçerli yolu çiz
    if (currentPath != null && currentPath!.points.isNotEmpty) {
      _drawPath(canvas, currentPath!);
    }

    // Metin overlay'lerini çiz
    for (final textOverlay in textOverlays) {
      _drawText(canvas, textOverlay);
    }
  }

  void _drawPath(Canvas canvas, DrawingPath drawingPath) {
    if (drawingPath.points.isEmpty) return;

    final paint = Paint()
      ..color = drawingPath.color
      ..strokeWidth = drawingPath.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (drawingPath.tool) {
      case DrawingTool.pen:
      case DrawingTool.brush:
        paint.style = PaintingStyle.stroke;
        final path = Path();
        path.moveTo(drawingPath.points.first.dx, drawingPath.points.first.dy);
        for (int i = 1; i < drawingPath.points.length; i++) {
          path.lineTo(drawingPath.points[i].dx, drawingPath.points[i].dy);
        }
        canvas.drawPath(path, paint);
        break;

      case DrawingTool.eraser:
        paint.style = PaintingStyle.stroke;
        paint.blendMode = BlendMode.clear;
        final path = Path();
        path.moveTo(drawingPath.points.first.dx, drawingPath.points.first.dy);
        for (int i = 1; i < drawingPath.points.length; i++) {
          path.lineTo(drawingPath.points[i].dx, drawingPath.points[i].dy);
        }
        canvas.drawPath(path, paint);
        break;

      case DrawingTool.line:
        if (drawingPath.points.length >= 2) {
          paint.style = PaintingStyle.stroke;
          canvas.drawLine(drawingPath.points.first, drawingPath.points.last, paint);
        }
        break;

      case DrawingTool.rectangle:
        if (drawingPath.points.length >= 2) {
          paint.style = PaintingStyle.stroke;
          final rect = Rect.fromPoints(drawingPath.points.first, drawingPath.points.last);
          canvas.drawRect(rect, paint);
        }
        break;

      case DrawingTool.circle:
        if (drawingPath.points.length >= 2) {
          paint.style = PaintingStyle.stroke;
          final center = drawingPath.points.first;
          final radius = (drawingPath.points.last - drawingPath.points.first).distance;
          canvas.drawCircle(center, radius, paint);
        }
        break;

      case DrawingTool.text:
        // Text tool is handled separately in the main draw method
        break;
    }
  }

  void _drawText(Canvas canvas, TextOverlay textOverlay) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: textOverlay.text,
        style: TextStyle(
          color: textOverlay.color,
          fontSize: textOverlay.fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(canvas, textOverlay.position);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
} 