import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/note_model.dart';
import '../../providers/notes_provider.dart';
import '../../providers/theme_provider.dart';

import '../note/note_view_screen.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  String _searchQuery = '';
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    // Arşivlenmiş notları yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotesProvider>(context, listen: false).loadArchivedNotes();
    });
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
        child: Column(
          children: [
            // Search & Filter Section
            _buildSearchSection(isDarkMode),
            
            // Notes List/Grid
            Expanded(
              child: Consumer<NotesProvider>(
                builder: (context, notesProvider, child) {
                  final archivedNotes = notesProvider.archivedNotes;

                  if (archivedNotes.isEmpty) {
                    return _buildEmptyState(isDarkMode);
                  }

                  return _buildNotesView(archivedNotes, isDarkMode);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildProfessionalAppBar(bool isDarkMode) {
    return AppBar(
      backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: isDarkMode ? Colors.white : const Color(0xFF334155),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.archive_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Arşiv',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
      actions: [
        // View Toggle
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildViewToggleButton(
                icon: Icons.grid_view_rounded,
                isSelected: _isGridView,
                onTap: () => setState(() => _isGridView = true),
                isDarkMode: isDarkMode,
              ),
              _buildViewToggleButton(
                icon: Icons.view_list_rounded,
                isSelected: !_isGridView,
                onTap: () => setState(() => _isGridView = false),
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF3B82F6)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isSelected 
                ? Colors.white
                : isDarkMode 
                    ? const Color(0xFF94A3B8) 
                    : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.all(20),
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
      child: TextField(
        style: TextStyle(
          fontSize: 16,
          color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: 'Arşivde ara...',
          hintStyle: TextStyle(
            color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
          Provider.of<NotesProvider>(context, listen: false).setArchiveSearchQuery(value);
        },
      ),
    );
  }

  Widget _buildNotesView(List<NoteModel> notes, bool isDarkMode) {
    if (_isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return _buildArchiveNoteCard(note, isDarkMode);
        },
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: _buildArchiveNoteCard(note, isDarkMode, isListView: true),
          );
        },
      );
    }
  }

  Widget _buildArchiveNoteCard(NoteModel note, bool isDarkMode, {bool isListView = false}) {
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
          onTap: () => _showNoteActions(note),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with archive indicator
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.archive_rounded,
                            size: 12,
                            color: Color(0xFF6366F1),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Arşivlendi',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (note.isPinned) ...[
                      const Icon(
                        Icons.push_pin_rounded,
                        size: 16,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (note.isFavorite) ...[
                      const Icon(
                        Icons.favorite_rounded,
                        size: 16,
                        color: Color(0xFFEF4444),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Title
                if (note.title.isNotEmpty) ...[
                  Text(
                    note.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: isListView ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Content
                if (note.content.isNotEmpty) ...[
                  Text(
                    note.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode 
                          ? const Color(0xFF94A3B8) 
                          : const Color(0xFF64748B),
                      height: 1.4,
                    ),
                    maxLines: isListView ? 3 : 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],
                
                if (!isListView) const Spacer(),
                
                // Footer
                Row(
                  children: [
                    // Category
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Color(int.parse(note.color.replaceAll('#', '0xFF')))
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        note.category,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(int.parse(note.color.replaceAll('#', '0xFF'))),
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Date
                    Text(
                      _formatDate(note.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode 
                            ? const Color(0xFF64748B) 
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? const Color(0xFF1E293B) 
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isDarkMode 
                    ? const Color(0xFF334155) 
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: const Icon(
              Icons.archive_outlined,
              size: 60,
              color: Color(0xFF6366F1),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Arşiv Boş',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Henüz arşivlenmiş notunuz yok',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode 
                  ? const Color(0xFF94A3B8) 
                  : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text(
              'Ana Sayfaya Dön',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNoteActions(NoteModel note) {
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isDarkMode 
                      ? const Color(0xFF475569) 
                      : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Title
              Text(
                note.title.isNotEmpty ? note.title : 'Başlıksız Not',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Actions
              _buildActionTile(
                icon: Icons.visibility_rounded,
                title: 'Görüntüle',
                color: const Color(0xFF3B82F6),
                onTap: () {
                  Navigator.pop(context);
                  _viewNote(note);
                },
                isDarkMode: isDarkMode,
              ),
              
              _buildActionTile(
                icon: Icons.unarchive_rounded,
                title: 'Arşivden Çıkar',
                color: const Color(0xFF10B981),
                onTap: () {
                  Navigator.pop(context);
                  _unarchiveNote(note);
                },
                isDarkMode: isDarkMode,
              ),
              
              _buildActionTile(
                icon: Icons.delete_rounded,
                title: 'Kalıcı Olarak Sil',
                color: const Color(0xFFEF4444),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(note);
                },
                isDarkMode: isDarkMode,
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
      onTap: onTap,
    );
  }

  void _viewNote(NoteModel note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteViewScreen(note: note),
      ),
    );
  }

  void _unarchiveNote(NoteModel note) {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    notesProvider.unarchiveNote(note.id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Not arşivden çıkarıldı'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDeleteConfirmation(NoteModel note) {
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Notu Sil',
          style: TextStyle(
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Bu notu kalıcı olarak silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
          style: TextStyle(
            color: isDarkMode 
                ? const Color(0xFF94A3B8) 
                : const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: TextStyle(
                color: isDarkMode 
                    ? const Color(0xFF94A3B8) 
                    : const Color(0xFF64748B),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteNote(note);
            },
            child: const Text(
              'Sil',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteNote(NoteModel note) {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    notesProvider.deleteNote(note.id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Not kalıcı olarak silindi'),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Bugün';
    } else if (difference == 1) {
      return 'Dün';
    } else if (difference < 7) {
      return '$difference gün önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
} 