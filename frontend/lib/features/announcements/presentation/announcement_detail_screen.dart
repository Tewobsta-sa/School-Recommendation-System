import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config.dart';
import '../../../shared/widgets/responsive_shell.dart';
import '../../../shared/utils/image_picker.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/state/auth_controller.dart';
import '../data/announcement_dtos.dart';
import '../data/announcement_repository.dart';
import '../data/comment_dtos.dart';

import '../../../shared/widgets/like_action.dart';
import '../../../shared/widgets/report_dialog.dart';
import '../../../shared/widgets/share_action.dart';
import '../../../shared/widgets/comment_tile.dart';
import '../../../shared/widgets/custom_components.dart';
import '../../../features/reports/data/report_dtos.dart';
import '../../../features/likes/data/like_dtos.dart';

/// `/announcements/:id` — single announcement view. Loaded on demand so
/// deep links from notifications work without first hitting the list.
class AnnouncementDetailScreen extends ConsumerStatefulWidget {
  final int announcementId;
  const AnnouncementDetailScreen({super.key, required this.announcementId});

  @override
  ConsumerState<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState
    extends ConsumerState<AnnouncementDetailScreen> {
  bool _loading = true;
  String? _error;
  Announcement? _item;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final item = await ref
          .read(announcementRepositoryProvider)
          .getById(widget.announcementId);
      if (!mounted) return;
      setState(() => _item = item);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = _item;
    return ResponsiveShell(
      title: a?.title ?? 'Announcement',
      leading: BackButton(onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/announcements');
        }
      }),
      child: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 64),
              child: Center(child: CircularProgressIndicator()),
            )
          : _error != null
              ? Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: theme.colorScheme.onErrorContainer),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!)),
                        TextButton(
                            onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : a == null
                  ? const SizedBox.shrink()
                  : _Body(announcement: a, onRefresh: _load),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  final Announcement announcement;
  final VoidCallback? onRefresh;
  const _Body({required this.announcement, this.onRefresh});

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  final _commentCtrl = TextEditingController();
  bool _posting = false;
  int _commentRefreshKey = 0;
  bool _isOwner = false;
  bool _showCommentInput = false;

  @override
  void initState() {
    super.initState();
    _checkOwnership();
  }

  void _checkOwnership() {
    final authState = ref.read(authControllerProvider);
    final user = authState.user;
    if (user != null) {
      setState(() {
        _isOwner = user.id == widget.announcement.publisherId;
      });
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _deleteAnnouncement() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: const Text('Are you sure you want to delete this announcement?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(announcementRepositoryProvider)
            .delete(widget.announcement.id);
        if (mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Announcement deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  Future<void> _showEditDialog() async {
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => _EditAnnouncementDialog(
          announcement: widget.announcement,
        ),
      );

      if (result == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Announcement updated successfully')),
          );
          // Reload the announcement to show updated content
          widget.onRefresh?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open edit dialog: $e')),
        );
      }
    }
  }

  void _toggleCommentInput() {
    setState(() {
      _showCommentInput = !_showCommentInput;
    });
  }

  List<Widget> _buildCommentList(List<Comment> comments) {
    final List<Widget> widgets = [];
    for (int i = 0; i < comments.length; i++) {
      widgets.add(CommentTile(comment: comments[i], showCard: false));
      if (i < comments.length - 1) {
        widgets.add(const Divider());
      }
    }
    return widgets;
  }

  Future<void> _postComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _posting = true);
    try {
      await ref
          .read(announcementRepositoryProvider)
          .postAnnouncementComment(widget.announcement.id, text);
      _commentCtrl.clear();
      // Bump the key to force FutureBuilder to refetch.
      setState(() => _commentRefreshKey++);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post comment: $e')),
      );
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = widget.announcement;
    final image = a.imgUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- ANNOUNCEMENT CARD ---
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (image != null && image.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            _absoluteImage(image),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Center(
                                  child: Icon(Icons.image_not_supported_outlined)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            AppBadge(
                              label: a.category.label(),
                            ),
                            if (a.urgencyLevel != UrgencyLevel.normal)
                              AppBadge(
                                label: a.urgencyLevel.label(),
                              ),
                            AppBadge(
                              icon: a.publisherType == PublisherType.moe
                                  ? Icons.account_balance_outlined
                                  : Icons.school_outlined,
                              label: a.school?.schoolName ?? a.publisherType.label(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Text(a.title, style: theme.textTheme.headlineSmall),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _formatAnnouncementDate(a.datePosted),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SelectableText(
                          a.content,
                          style: theme.textTheme.bodyLarge,
                        ),
                        if (a.school != null) ...[
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            onPressed: () =>
                                GoRouter.of(context).go('/schools/${a.school!.id}'),
                            icon: const Icon(Icons.open_in_new),
                            label: Text('View ${a.school!.schoolName}'),
                          ),
                        ],

                        // --- ACTION BAR ---
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_isOwner)
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: _showEditDialog,
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outlined),
                                    onPressed: _deleteAnnouncement,
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            Row(
                              children: [
                                LikeAction(
                                    targetType: LikeTargetType.announcement,
                                    targetId: a.id),
                                ShareAction(
                                  title: a.title,
                                  content: a.content,
                                  url: 'https://yourapp.com/announcements/${a.id}',
                                ),
                                _CommentToggleButton(
                                  showInput: _showCommentInput,
                                  onPressed: _toggleCommentInput,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.flag_outlined),
                                  onPressed: () => showDialog(
                                    context: context,
                                    builder: (_) => ReportDialog(
                                      targetType: ReportTargetType.announcement,
                                      targetId: a.id,
                                    ),
                                  ),
                                  tooltip: 'Report',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),

          // --- COMMENT SECTION (separate card) ---
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Comments', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),

                    // Comment input (toggled by button)
                    if (_showCommentInput) ...[
                      TextField(
                        controller: _commentCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Add a comment',
                          hintText: 'Share your thoughts...',
                        ),
                        minLines: 2,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _posting ? null : _postComment,
                          icon: _posting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send),
                          label: const Text('Comment'),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Comments list (always visible, separated by horizontal lines)
                    FutureBuilder(
                      key: ValueKey(_commentRefreshKey),
                      future: ref
                          .read(announcementRepositoryProvider)
                          .getAnnouncementComments(a.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text('Error loading comments: ${snapshot.error}');
                        }

                        final comments = snapshot.data ?? [];
                        if (comments.isEmpty) {
                          return const Text('No comments yet. Be the first to comment!');
                        }

                        return Column(
                          children: _buildCommentList(comments),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          ),
        ],
      );
  }
}

// Comment toggle button - StatefulWidget to avoid Flutter web bug
class _CommentToggleButton extends StatefulWidget {
  final bool showInput;
  final VoidCallback onPressed;
  const _CommentToggleButton({required this.showInput, required this.onPressed});

  @override
  State<_CommentToggleButton> createState() => _CommentToggleButtonState();
}

class _CommentToggleButtonState extends State<_CommentToggleButton> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(widget.showInput ? Icons.comment : Icons.comment_outlined),
      onPressed: widget.onPressed,
      tooltip: 'Comments',
    );
  }
}

// Comment section widget (no longer used, kept for reference)
class _CommentSection extends ConsumerWidget {
  final int announcementId;
  final TextEditingController commentCtrl;
  final bool posting;
  final VoidCallback onPostComment;
  final int refreshKey;

  const _CommentSection({
    super.key,
    required this.announcementId,
    required this.commentCtrl,
    required this.posting,
    required this.onPostComment,
    required this.refreshKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        Text('Comments', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),

        // Comment input
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: commentCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Add a comment',
                    hintText: 'Share your thoughts...',
                  ),
                  minLines: 2,
                  maxLines: 5,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: posting ? null : onPostComment,
                    icon: posting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: const Text('Comment'),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Comments list
        FutureBuilder(
          key: ValueKey(refreshKey),
          future: ref
              .read(announcementRepositoryProvider)
              .getAnnouncementComments(announcementId),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text(
                  'Error loading comments: ${snapshot.error}');
            }

            final comments = snapshot.data ?? [];
            if (comments.isEmpty) {
              return const Text('No comments yet. Be the first to comment!');
            }

            return Column(
              children: comments
                  .map((c) => CommentTile(comment: c))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

String _absoluteImage(String url) {
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  if (url.startsWith('/')) return '${AppConfig.apiBaseUrl}$url';
  return '${AppConfig.apiBaseUrl}/$url';
}

String _formatAnnouncementDate(dynamic dateInput) {
  DateTime d;
  if (dateInput is DateTime) {
    d = dateInput;
  } else if (dateInput is String) {
    d = DateTime.tryParse(dateInput) ?? DateTime.now();
  } else {
    return 'Unknown date';
  }
  
  final now = DateTime.now();
  final diff = now.difference(d);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 30) return '${diff.inDays}d ago';
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _EditAnnouncementDialog extends ConsumerStatefulWidget {
  final Announcement announcement;
  const _EditAnnouncementDialog({required this.announcement});

  @override
  ConsumerState<_EditAnnouncementDialog> createState() => _EditAnnouncementDialogState();
}

class _EditAnnouncementDialogState extends ConsumerState<_EditAnnouncementDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late AnnouncementCategory _selectedCategory;
  late UrgencyLevel _selectedUrgency;
  bool _isSubmitting = false;
  PickedImage? _pickedImage;
  bool _removeExistingImage = false;
  String? _pickError;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.announcement.title);
    _contentController = TextEditingController(text: widget.announcement.content);
    _selectedCategory = widget.announcement.category;
    _selectedUrgency = widget.announcement.urgencyLevel;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _pickError = null);
    try {
      final picked = await pickImageFromUser();
      if (picked == null) return;
      setState(() {
        _pickedImage = picked;
        _removeExistingImage = false;
      });
    } catch (e) {
      setState(() => _pickError = 'Failed to pick image: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _pickedImage = null;
      _removeExistingImage = true;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final input = AnnouncementInput(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _selectedCategory,
        urgencyLevel: _selectedUrgency,
        schoolId: widget.announcement.schoolId,
      );
      
      final repo = ref.read(announcementRepositoryProvider);
      
      // Update the announcement text fields
      await repo.update(widget.announcement.id, input);
      
      // Handle image changes
      if (_pickedImage != null) {
        // Upload new image (replaces existing if any)
        await repo.uploadImage(
          id: widget.announcement.id,
          filename: _pickedImage!.filename,
          bytes: _pickedImage!.bytes,
        );
      } else if (_removeExistingImage && widget.announcement.imgUrl != null) {
        // Remove existing image
        await repo.deleteImage(widget.announcement.id);
      }
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasExistingImage = widget.announcement.imgUrl != null && widget.announcement.imgUrl!.isNotEmpty;
    final displayImage = _pickedImage ?? (hasExistingImage && !_removeExistingImage ? widget.announcement.imgUrl : null);
    
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, color: theme.colorScheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Text(
                    'Edit Announcement',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title field
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      // Content field
                      TextFormField(
                        controller: _contentController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Content',
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Content is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      // Category and Urgency in a row
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<AnnouncementCategory>(
                              value: _selectedCategory,
                              decoration: InputDecoration(
                                labelText: 'Category',
                                filled: true,
                                fillColor: theme.colorScheme.surfaceContainerHighest,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: AnnouncementCategory.values.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(category.label()),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedCategory = value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<UrgencyLevel>(
                              value: _selectedUrgency,
                              decoration: InputDecoration(
                                labelText: 'Urgency',
                                filled: true,
                                fillColor: theme.colorScheme.surfaceContainerHighest,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: UrgencyLevel.values.map((level) {
                                return DropdownMenuItem(
                                  value: level,
                                  child: Text(level.label()),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedUrgency = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Image section
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Image preview or placeholder
                            if (displayImage != null)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: _pickedImage != null
                                    ? Image.memory(
                                        _pickedImage!.bytes,
                                        width: double.infinity,
                                        height: 150,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.network(
                                        _absoluteImage(widget.announcement.imgUrl!),
                                        width: double.infinity,
                                        height: 150,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: double.infinity,
                                          height: 150,
                                          color: theme.colorScheme.surfaceContainerHighest,
                                          child: const Icon(Icons.image_not_supported_outlined, size: 40),
                                        ),
                                      ),
                              )
                            else
                              Container(
                                width: double.infinity,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate, 
                                        size: 40, 
                                        color: theme.colorScheme.onSurfaceVariant),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No image selected',
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            // Image actions
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  if (displayImage != null)
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _removeImage,
                                        icon: const Icon(Icons.delete_outline, size: 18),
                                        label: const Text('Remove', style: TextStyle(fontSize: 12)),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                        ),
                                      ),
                                    ),
                                  if (displayImage != null) const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: _pickImage,
                                      icon: Icon(displayImage == null ? Icons.add_photo_alternate : Icons.swap_horiz, size: 18),
                                      label: Text(displayImage == null ? 'Add Image' : 'Replace', style: TextStyle(fontSize: 12)),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_pickError != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _pickError!,
                            style: TextStyle(color: theme.colorScheme.onErrorContainer, fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Footer actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Changes'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
