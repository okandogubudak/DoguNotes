import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/theme_provider.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/note_card.dart';
import '../note/add_note_screen.dart';
import '../note/note_view_screen.dart';
import '../settings/settings_screen.dart';
import '../archive/archive_screen.dart';
import '../../../core/services/category_service.dart';
import '../settings/category_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  
  bool _isSearchVisible = false;
  late AnimationController _searchAnimationController;
  late Animation<double> _searchAnimation;
  Map<String, Map<String, dynamic>> _categories = {};
  bool _categoriesLoaded = false;
  
  late PageController _categoryPageController;
  late AnimationController _categoryAnimationController;
  late Animation<double> _categoryAnimation;
  int _currentCategoryIndex = 0;
  List<String> _categoryKeys = ['Genel'];
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    
    _scrollController.addListener(_onScroll);
    
    _categoryPageController = PageController(viewportFraction: 0.3);
    _categoryAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _categoryAnimation = CurvedAnimation(
      parent: _categoryAnimationController,
      curve: Curves.easeInOut,
    );
    
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    );
    
    if (_isSearchVisible) {
      _searchAnimationController.value = 1.0;
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategoriesAndNotes();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshCategoriesIfNeeded();
      });
    }
  }

  Future<void> _loadCategoriesAndNotes() async {
    try {
      final categoryService = CategoryService.instance;
      final loadedCategories = await categoryService.loadCategories();
      
      if (loadedCategories.isNotEmpty) {
        _categories = loadedCategories;
        _categoryKeys = ['Genel', ..._categories.keys.where((key) => key != 'Genel')];
      } else {
        _categories = Map<String, Map<String, dynamic>>.from(AppConstants.noteCategories);
        _categoryKeys = ['Genel', ..._categories.keys.where((key) => key != 'Genel')];
      }
      
      if (mounted) {
        Provider.of<NotesProvider>(context, listen: false).loadNotes();
      }
      
      if (mounted) {
        setState(() {
          _categoriesLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Kategori yükleme hatası: $e');
      _categories = Map<String, Map<String, dynamic>>.from(AppConstants.noteCategories);
      _categoryKeys = ['Genel', ..._categories.keys.where((key) => key != 'Genel')];
      
      if (mounted) {
        Provider.of<NotesProvider>(context, listen: false).loadNotes();
        setState(() {
          _categoriesLoaded = true;
        });
      }
    }
  }

  Future<void> _refreshCategoriesIfNeeded() async {
    try {
      final categoryService = CategoryService.instance;
      _categories = await categoryService.loadCategories();
      
      _categoryKeys = ['Genel', ..._categories.keys.where((key) => key != 'Genel')];
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Kategori yenileme hatası: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _categoryPageController.dispose();
    _categoryAnimationController.dispose();
    _searchAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    const Color gradientStart = Color(0xFF3B82F6);
    const Color gradientEnd   = Color(0xFF1D4ED8);
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: _buildProfessionalAppBar(theme, themeProvider, isDarkMode),
      body: Column(
          children: [
          GestureDetector(
            onTap: _toggleSearch,
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isSearchVisible ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isDarkMode ? Colors.white : const Color(0xFF334155),
                      size: 28,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _searchAnimation,
            axisAlignment: -1.0,
            child: _buildProfessionalSearchSection(theme, isDarkMode),
          ),
          if (_categoriesLoaded && _categoryKeys.isNotEmpty)
            _buildProfessionalCategoryTabs(theme, isDarkMode),
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! < 0) {
                    if (_currentCategoryIndex < _categoryKeys.length - 1) {
                      _categoryPageController.animateToPage(
                        _currentCategoryIndex + 1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                      setState(() {
                        _currentCategoryIndex++;
                      });
                    }
                  } else if (details.primaryVelocity! > 0) {
                    if (_currentCategoryIndex > 0) {
                      _categoryPageController.animateToPage(
                        _currentCategoryIndex - 1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                      setState(() {
                        _currentCategoryIndex--;
                      });
                    }
                  }
                }
              },
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: _buildProfessionalNotesGrid(theme, isDarkMode),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildProfessionalCreateButton(theme, isDarkMode),
      drawer: _buildProfessionalSidebar(theme, isDarkMode),
    );
  }

  PreferredSizeWidget _buildProfessionalAppBar(ThemeData theme, ThemeProvider themeProvider, bool isDarkMode) {
    return AppBar(
      backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      elevation: 0,
      toolbarHeight: 72,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(
            Icons.menu_rounded,
            color: isDarkMode ? Colors.white : const Color(0xFF334155),
            size: 24,
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      centerTitle: true,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
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
              Icons.note_alt_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppConstants.appName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: [
        _buildViewToggle(isDarkMode),
        const SizedBox(width: 16),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
    );
  }
  
  Widget _buildProfessionalSearchSection(ThemeData theme, bool isDarkMode) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [const Color(0xFF232B3B).withOpacity(0.95), const Color(0xFF1E293B).withOpacity(0.85)]
              : [const Color(0xFFF1F5FA).withOpacity(0.95), const Color(0xFFE3ECF7).withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.18)
                : Colors.blueGrey.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.06)
                        : Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Notlarda ara...',
                      hintStyle: TextStyle(
                        color: isDarkMode ? const Color(0xFF7B8CA6) : const Color(0xFF7B8CA6),
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6),
                        size: 26,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.cancel_rounded,
                                color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _clearSearch();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                    ),
                    onChanged: _onSearchChanged,
                    onTap: () {
                      if (!_isSearchVisible) {
                        setState(() => _isSearchVisible = true);
                        _searchAnimationController.forward();
                      }
                    },
                  ),
                ),
                if (_searchController.text.isEmpty) ...[
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _buildQuickStat(
                        'Notlar',
                        _getNotesCount().toString(),
                        Icons.sticky_note_2_rounded,
                        const Color(0xFF3B82F6),
                        isDarkMode,
                        onTap: () => _resetToGeneralCategory(),
                      ),
                      const SizedBox(width: 12),
                      _buildQuickStat(
                        'Arşiv',
                        _getArchivedNotesCount().toString(),
                        Icons.archive_outlined,
                        const Color(0xFF10B981),
                        isDarkMode,
                        onTap: () => _navigateToArchive(),
                      ),
                      const SizedBox(width: 12),
                      _buildQuickStat(
                        'Favoriler',
                        _getFavoriteNotesCount().toString(),
                        Icons.favorite_rounded,
                        const Color(0xFFEF4444),
                        isDarkMode,
                        onTap: () => _filterFavorites(),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon, Color color, bool isDarkMode, {VoidCallback? onTap}) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: color,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalCategoryTabs(ThemeData theme, bool isDarkMode) {
    return Container(
      height: 50,
      color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      child: PageView.builder(
        controller: _categoryPageController,
        itemCount: _categoryKeys.length,
        onPageChanged: (index) {
          setState(() {
            _currentCategoryIndex = index;
          });

          // Seçilen kategori sağlayıcıya bildir
          final notesProvider = Provider.of<NotesProvider>(context, listen: false);
          if (_categoryKeys.isNotEmpty && index < _categoryKeys.length) {
            notesProvider.setCategory(_categoryKeys[index]);
          } else {
            notesProvider.setCategory('Genel');
          }
        },
        itemBuilder: (context, index) {
          final categoryKey = _categoryKeys[index];
          final isSelected = index == _currentCategoryIndex;
          
          return GestureDetector(
            onTap: () {
              _categoryPageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF3B82F6)
                              : isDarkMode
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                          fontFamily: Provider.of<ThemeProvider>(context, listen:false).currentFontFamily,
                        ),
                        child: Text(categoryKey),
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 3,
                    width: isSelected ? 40 : 0,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildProfessionalNotesGrid(ThemeData theme, bool isDarkMode) {
    return Consumer<NotesProvider>(
      builder: (context, notesProvider, child) {
        int safeIndex = _currentCategoryIndex;
        if (_categoryKeys.isEmpty) {
          safeIndex = 0;
        } else if (_currentCategoryIndex >= _categoryKeys.length) {
          safeIndex = 0;
          if (_currentCategoryIndex != 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() => _currentCategoryIndex = 0);
            });
          }
        }
        final selectedCategory = _categoryKeys.isNotEmpty ? _categoryKeys[safeIndex] : 'Genel';
        
        var notes = notesProvider.notes.where((note) => !note.isArchived).toList();
        
        if (selectedCategory == 'Favoriler') {
          notes = notes.where((note) => note.isFavorite).toList();
        } else if (selectedCategory != 'Genel') {
          notes = notes.where((note) => note.category == selectedCategory).toList();
        }
        
        if (_searchController.text.isNotEmpty) {
          notes = notes.where((note) {
            final query = _searchController.text.toLowerCase();
            return note.title.toLowerCase().contains(query) ||
                   note.content.toLowerCase().contains(query) ||
                   note.tags.any((tag) => tag.toLowerCase().contains(query));
          }).toList();
        }
        
        if (notes.isEmpty) {
          return _buildProfessionalEmptyState(theme, isDarkMode, selectedCategory);
        }
        
        return Container(
          color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          child: RefreshIndicator(
            onRefresh: () async {
              await notesProvider.loadNotes();
              await _refreshCategoriesIfNeeded();
            },
            color: const Color(0xFF3B82F6),
            child: _isGridView 
                ? GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.05,
                    ),
                    itemCount: notes.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return NoteCard(
                  note: notes[index],
                  isGridView: _isGridView,
                  onTap: () => _navigateToNoteView(notes[index].id),
                  onLongPress: () => _showNoteOptions(notes[index]),
                );
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: NoteCard(
                note: notes[index],
                isGridView: _isGridView,
                onTap: () => _navigateToNoteView(notes[index].id),
                onLongPress: () => _showNoteOptions(notes[index]),
              ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  Widget _buildProfessionalNoteCard(note, ThemeData theme, bool isDarkMode) {
    final cardGradient = LinearGradient(
      colors: isDarkMode
          ? [const Color(0xFF232B3B), const Color(0xFF1E293B)]
          : [const Color(0xFFF1F5FA), const Color(0xFFE3ECF7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final cardShadow = [
      BoxShadow(
        color: isDarkMode
            ? Colors.black.withOpacity(0.22)
            : Colors.blueGrey.withOpacity(0.10),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ];
    final borderRadius = BorderRadius.circular(18);
    Widget cardContent = Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              const Spacer(),
              if (note.isPinned)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(Icons.push_pin_rounded, size: 18, color: const Color(0xFF3B82F6)),
                ),
              if (note.isFavorite)
                Icon(Icons.favorite_rounded, size: 18, color: const Color(0xFFEF4444)),
            ],
          ),
          if (note.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 6),
              child: Text(
                note.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          if (note.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                note.content,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: isDarkMode ? const Color(0xFFB6C2D2) : const Color(0xFF64748B),
                  height: 1.4,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (note.attachments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(Icons.attach_file_rounded, size: 16, color: isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6)),
                ),
              if (note.audioPath != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(Icons.mic_rounded, size: 16, color: isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6)),
                ),
              Text(
                _formatDate(note.updatedAt),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToNoteView(note.id),
        onLongPress: () => _showNoteOptions(note),
        borderRadius: borderRadius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: cardGradient,
            borderRadius: borderRadius,
            boxShadow: cardShadow,
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: cardContent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalEmptyState(ThemeData theme, bool isDarkMode, String category) {
    return Container(
      color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              width: 80,
              height: 80,
            decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.note_add_rounded,
                size: 40,
                color: Color(0xFF3B82F6),
              ),
            ),
            
          const SizedBox(height: 24),
            
          Text(
              _searchController.text.isNotEmpty
                  ? 'Arama sonucu bulunamadı'
                  : '$category kategorisinde not yok',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            
          const SizedBox(height: 8),
            
          Text(
              _searchController.text.isNotEmpty
                  ? 'Farklı kelimeler ile tekrar deneyin'
                  : 'İlk notunuzu oluşturmak için + butonuna dokunun',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildProfessionalCreateButton(ThemeData theme, bool isDarkMode) {
    const Color gradientStart = Color(0xFF3B82F6);
    const Color gradientEnd   = Color(0xFF1D4ED8);

    return GestureDetector(
      onTap: _navigateToAddNote,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [gradientStart, gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: gradientStart.withOpacity(0.45),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _buildProfessionalSidebar(ThemeData theme, bool isDarkMode) {
    return Drawer(
      backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            ),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.note_alt_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Profesyonel Not Uygulaması',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nasıl Kullanılır?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3B82F6).withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTipItem('📝', 'Not Oluşturma', '+ ikonuna dokunarak yeni not ekleyin.'),
                  _buildTipItem('✏️', 'Not Düzenleme', 'Not kartına dokunup içeriği güncelleyin.'),
                  _buildTipItem('📁', 'Kategori Yönetimi', 'Menüden kategori ekleyin, düzenleyin veya silin.'),
                  _buildTipItem('🎨', 'Renk Seçimi', 'Kategori rengi not kartına otomatik yansır.'),
                  _buildTipItem('📷', 'Medya Ekleme', 'Resim / video / ses eklemek için ataç ikonunu kullanın.'),
                  _buildTipItem('⭐', 'Favori İşaretleme', 'Önemli notları favorilere ekleyin.'),
                  _buildTipItem('📌', 'Not Sabitleme', 'Notları en üstte tutmak için sabitleyin.'),
                  _buildTipItem('🔍', 'Hızlı Arama', 'Üstteki arama alanından kelime arayın.'),
                  _buildTipItem('🗂️', 'Arşivleme', 'Eski notları arşive taşıyın ve gerektiğinde geri alın.'),
                  _buildTipItem('🔒', 'Güvenlik', 'PIN veya biyometrik ile uygulamayı koruyun.'),
                  _buildTipItem('📤', 'Yedekleme', 'Notlarınızı JSON veya PDF olarak dışa aktarın.'),
                  _buildTipItem('♻️', 'Uygulamayı Sıfırla', 'Ayarlar > Veri Yönetimi bölümünden tam sıfırlama yapın.'),
                ],
              ),
            ),
          ),
          const Divider(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  final isDark = themeProvider.isDarkMode;
                  return IconButton(
                    icon: Icon(
                      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: isDark ? Colors.white : const Color(0xFF475569),
                      size: 24,
                    ),
                    splashRadius: 24,
                    onPressed: () => themeProvider.toggleTheme(),
                  );
                },
              ),
              _buildDrawerIconButton(
                icon: Icons.settings_rounded,
                onTap: () {
                  Navigator.pop(context);
                  _navigateToSettings();
                },
                isDarkMode: isDarkMode,
              ),
              _buildDrawerIconButton(
                icon: Icons.logout_rounded,
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog();
                },
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3B82F6).withOpacity(0.8),
            ),
          ),
          Text(
            description,
            style: TextStyle(
              fontSize: 10,
              color: const Color(0xFF64748B).withOpacity(0.8),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return IconButton(
      icon: Icon(icon, color: isDarkMode ? Colors.white : const Color(0xFF475569), size: 24),
      splashRadius: 24,
      onPressed: onTap,
    );
  }

  int _getNotesCount() {
    return Provider.of<NotesProvider>(context, listen: false).notes.length;
  }

  int _getArchivedNotesCount() {
    return Provider.of<NotesProvider>(context, listen: true).archivedNotes.length;
  }

  int _getFavoriteNotesCount() {
    final notes = Provider.of<NotesProvider>(context, listen: false).notes;
    return notes.where((note) => note.isFavorite).length;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Şimdi';
        }
        return '${difference.inMinutes}d önce';
      }
      return '${difference.inHours}s önce';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
      }
    });
    
    if (_isSearchVisible) {
      _searchAnimationController.forward();
    } else {
      _searchAnimationController.reverse();
    }
  }

  void _onSearchChanged(String query) {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    notesProvider.setSearchQuery(query);
    setState(() {});
  }

  void _clearSearch() {
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    notesProvider.setSearchQuery('');
    setState(() {});
  }

  void _selectCategory(int index) {
    setState(() {
      _currentCategoryIndex = index;
    });
  }

  void _navigateToAddNote() {
    final selectedCategory = _categoryKeys.isNotEmpty 
        ? _categoryKeys[_currentCategoryIndex] 
        : 'Genel';
    
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            const AddNoteScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: child,
                  ),
                );
              },
        transitionDuration: const Duration(milliseconds: 300),
              ),
    );
  }

  void _navigateToNoteView(String noteId) {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final note = notesProvider.getNoteById(noteId);
    if (note != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => NoteViewScreen(note: note),
        ),
      );
    }
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            const SettingsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }
  
  void _showNoteOptions(note) {
    // Note options modal implementation
    // This would show options like edit, delete, archive, etc.
  }

  void _navigateToArchive() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ArchiveScreen(),
      ),
    );
  }

  void _filterFavorites() {
    setState(() {
      _currentCategoryIndex = 0;
      _categoryKeys = ['Favoriler'];
    });
  }

  void _resetToGeneralCategory() {
    setState(() {
      _currentCategoryIndex = 0;
      _categoryKeys = ['Genel', ..._categories.keys.where((key) => key != 'Genel')];
    });
    
    _categoryPageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    _searchController.clear();
    FocusScope.of(context).unfocus();
  }

  void _resetToAllCategories() {
    setState(() {
      _currentCategoryIndex = 0;
      _categoryKeys = ['Genel', ..._categories.keys.where((key) => key != 'Genel')];
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final offset = _scrollController.offset;
      final shouldHideSearch = offset > 50;
      
      if ((shouldHideSearch && _isSearchVisible) && !_searchFocusNode.hasFocus && _searchController.text.isEmpty) {
        setState(() {
          _isSearchVisible = false;
        });
        _searchAnimationController.reverse();
      } else if (!shouldHideSearch && !_isSearchVisible) {
        setState(() {
          _isSearchVisible = true;
        });
        _searchAnimationController.forward();
      }
    }
  }

  void _showLogoutDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: Center(
            child: Text(
              'Uygulamadan Çık',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          content: Text(
            'Uygulamadan çıkmak istediğinize emin misiniz?',
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF334155),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
              ),
              onPressed: () {
                SystemNavigator.pop();
              },
              child: const Text('Çıkış'),
            ),
          ],
        );
      },
    );
  }

  /// Modern segment kontrolü – Izgara vs Liste
  Widget _buildViewToggle(bool isDarkMode) {
    const double itemSize = 34;

    Color _iconColor(bool selected) {
      return selected
          ? const Color(0xFF3B82F6)
          : (isDarkMode ? Colors.white : const Color(0xFF334155));
    }

    Widget _buildItem(IconData icon, bool gridMode) {
      final bool isSelected = gridMode ? _isGridView : !_isGridView;
      return GestureDetector(
        onTap: () {
          if (isSelected) return;
          setState(() {
            _isGridView = gridMode;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: itemSize,
          height: itemSize,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF3B82F6).withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _iconColor(isSelected), size: 20),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.blueGrey.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildItem(Icons.grid_view_rounded, true),
          _buildItem(Icons.view_list_rounded, false),
        ],
      ),
    );
  }
} 