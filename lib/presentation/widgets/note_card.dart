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
  final bool isGridView;

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
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final color = _parseColor(note.color);

    // Dynamic spacing based on screen width to ensure consistent look across devices
    final screenWidth = MediaQuery.of(context).size.width;
    double spacing = screenWidth * 0.03; // ~3% of screen width
    if (spacing < 8) spacing = 8; // minimum
    if (spacing > 16) spacing = 16; // maximum

    return Hero(
      tag: 'note-${note.id}',
      child: Container(
        margin: isGridView
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap?.call();
            },
            onLongPress: () {
              HapticFeedback.mediumImpact();
              onLongPress?.call();
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isDarkMode 
                    ? const Color(0xFF1E293B)
                    : Colors.white,
                border: Border.all(color: color.withOpacity(0.33), width: .75),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: color.withOpacity(isDarkMode ? 0.6 : 0.4),
                    blurRadius: 12,
                    spreadRadius: 1,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(spacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: isGridView ? 8 : 12),
                    
                    // Title with centered alignment and icons on the right
                    if (note.title.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Text(
                                note.title,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? Colors.white : theme.colorScheme.onSurface,
                                  fontSize: 14,
                                ),
                                maxLines: isGridView ? 1 : 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (note.isPinned || note.isFavorite)
                              Positioned(
                                right: 0,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (note.isPinned)
                                      const Icon(
                                        Icons.push_pin,
                                        size: 14,
                                        color: Colors.orange,
                                      ),
                                    if (note.isPinned && note.isFavorite)
                                      const SizedBox(width: 4),
                                    if (note.isFavorite)
                                      const Icon(
                                        Icons.favorite,
                                        size: 14,
                                        color: Colors.red,
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    
                    if (note.title.isNotEmpty && note.content.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Divider(height: 1, color: Colors.grey, thickness: 0.4),
                      const SizedBox(height: 6),
                    ],
                    
                    if (note.title.isNotEmpty && note.content.isNotEmpty && isGridView == false) const SizedBox(height: 4),
                    
                    // Content Preview with reserved height (3 lines) to avoid footer shifting
                    Builder(
                      builder: (context) {
                        // Approximate height for 3 lines based on font size and line height
                        final double contentHeight = (isGridView ? 12 : 14) * 1.4 * 3;

                        if (note.content.isNotEmpty) {
                          return SizedBox(
                            height: contentHeight,
                            child: Text(
                        note.content,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDarkMode 
                              ? Colors.white.withOpacity(0.7)
                              : theme.colorScheme.onSurface.withOpacity(0.7),
                          height: 1.4,
                                fontSize: 12,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                          );
                        } else {
                          // Boş içerik için yer tutucu alan
                          return SizedBox(height: contentHeight);
                        }
                      },
                    ),
                    const SizedBox(height: 6),
                    Divider(height: 1, color: Colors.grey, thickness: 0.4),
                    const SizedBox(height: 6),
                    SizedBox(height: isGridView ? 8 : 16),
                    // Footer
                    if (isGridView)
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Row(
                          children: [
                            // Date
                            Expanded(
                              child: Center(
                                child: Text(
                                  _formatDate(note.updatedAt),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDarkMode 
                                        ? Colors.white.withOpacity(0.6)
                                        : theme.colorScheme.onSurface.withOpacity(0.6),
                                    fontSize: 10,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            // Media indicators
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (note.attachments.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(right: 4),
                                    child: Icon(
                                      Icons.attach_file,
                                      size: 14,
                                      color: Colors.blue,
                                    ),
                                  ),
                                if (note.audioPath != null)
                                  Icon(
                                    Icons.mic,
                                    size: 14,
                                    color: Colors.green,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if (!isGridView)
                    Row(
                      children: [
                        // Date
                          Expanded(
                            child: Center(
                              child: Text(
                                _formatDate(note.updatedAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDarkMode 
                                      ? Colors.white.withOpacity(0.6)
                                      : theme.colorScheme.onSurface.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        // Media indicators
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (note.attachments.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(right: 4),
                                child: Icon(
                                  Icons.attach_file,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                              ),
                            if (note.audioPath != null)
                              Icon(
                                Icons.mic,
                                size: 16,
                                color: Colors.green,
                              ),
                          ],
                        ),
                      ],
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

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.substring(1, 7), radix: 16) + 0xFF000000);
    } catch (e) {
      return const Color(0xFF3B82F6);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }
} 