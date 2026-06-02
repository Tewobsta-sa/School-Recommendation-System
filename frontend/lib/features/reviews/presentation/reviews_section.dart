import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/auth_dtos.dart';
import '../../auth/state/auth_controller.dart';
import '../data/review_dtos.dart';
import '../state/reviews_controller.dart';

/// Read-by-everyone, write-by-PARENT reviews block. Embedded under the
/// school detail body so it inherits the outer ResponsiveShell scroll.
class ReviewsSection extends ConsumerStatefulWidget {
  final int schoolId;
  final VoidCallback? onReviewSubmitted;
  final int totalReviewCount;
  const ReviewsSection({
    super.key,
    required this.schoolId,
    this.onReviewSubmitted,
    required this.totalReviewCount,
  });

  @override
  ConsumerState<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends ConsumerState<ReviewsSection> {
  bool _showForm = false;
  int _rating = 5;
  ReviewCategoryTag _tag = ReviewCategoryTag.teachingQuality;
  TextEditingController _commentCtrl = TextEditingController();
  Review? _editingReview;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(reviewsControllerProvider(widget.schoolId).notifier)
          .ensureLoaded();
    });
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller =
        ref.watch(reviewsControllerProvider(widget.schoolId));
    final auth = ref.watch(authControllerProvider);
    final isParent = auth.user?.role == UserRole.parent;
    final myReview = isParent
        ? controller.items.where((r) => r.parentId == auth.user?.id).cast<Review?>().firstOrNull
        : null;
    
    // Show only first 3 reviews in the preview
    final previewReviews = controller.items.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Reviews', style: theme.textTheme.titleLarge),
                const Spacer(),
                if (controller.initialized)
                  Text('${widget.totalReviewCount}',
                      style: theme.textTheme.titleMedium),
                if (widget.totalReviewCount > 3) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => context.go('/schools/${widget.schoolId}/reviews'),
                    child: const Text('See all'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            if (isParent && !_showForm)
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: controller.saving
                      ? null
                      : () => _toggleForm(myReview),
                  icon: Icon(myReview == null ? Icons.add : Icons.edit),
                  label: Text(
                    myReview == null ? 'Write a review' : 'Edit my review',
                  ),
                ),
              ),
            if (_showForm && _editingReview == null)
              _ReviewForm(
                key: const ValueKey('new-review-form'), // Add stable key
                rating: _rating,
                tag: _tag,
                commentCtrl: _commentCtrl,
                onRatingChanged: (v) => setState(() => _rating = v),
                onTagChanged: (v) => setState(() => _tag = v),
                onSave: _saveReview,
                onCancel: () => setState(() {
                  _showForm = false;
                  _commentCtrl.clear();
                  _rating = 5;
                  _tag = ReviewCategoryTag.teachingQuality;
                  _editingReview = null;
                }),
                saving: controller.saving,
              ),
            const SizedBox(height: 12),
            if (controller.loading && controller.items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (controller.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  controller.error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              )
            else if (controller.items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No reviews yet.'),
              )
            else
              Column(
                children: [
                  for (final r in previewReviews)
                    if (_editingReview?.id == r.id && _showForm)
                      _ReviewForm(
                        key: ValueKey('form-${r.id}'), // Add stable key
                        rating: _rating,
                        tag: _tag,
                        commentCtrl: _commentCtrl,
                        onRatingChanged: (v) => setState(() => _rating = v),
                        onTagChanged: (v) => setState(() => _tag = v),
                        onSave: _saveReview,
                        onCancel: () => setState(() {
                          _showForm = false;
                          _commentCtrl.clear();
                          _rating = 5;
                          _tag = ReviewCategoryTag.teachingQuality;
                          _editingReview = null;
                        }),
                        saving: controller.saving,
                      )
                    else
                      _ReviewTile(
                        key: ValueKey('review-${r.id}'), // Add stable key
                        review: r,
                        mine: r.parentId == auth.user?.id && isParent,
                        onEdit: () => _toggleForm(r),
                        onDelete: () => _confirmDelete(r),
                      ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _toggleForm(Review? existing) {
    setState(() {
      final isSameReview = _editingReview != null && 
                          existing != null && 
                          _editingReview!.id == existing.id;
      
      if (_showForm && isSameReview) {
        // Toggle off if clicking the same review
        _showForm = false;
        _commentCtrl.clear();
        _rating = 5;
        _tag = ReviewCategoryTag.teachingQuality;
        _editingReview = null;
      } else {
        // Show form for new or different review
        _showForm = true;
        _editingReview = existing;
        if (existing != null) {
          _rating = existing.rating;
          _tag = existing.categoryTag;
          _commentCtrl.text = existing.comment ?? '';
        } else {
          _rating = 5;
          _tag = ReviewCategoryTag.teachingQuality;
          _commentCtrl.clear();
        }
      }
    });
  }

  Future<void> _saveReview() async {
    final controller =
        ref.read(reviewsControllerProvider(widget.schoolId).notifier);
    final input = ReviewInput(
      rating: _rating,
      comment: _commentCtrl.text.trim().isEmpty
          ? null
          : _commentCtrl.text.trim(),
      categoryTag: _tag,
    );
    
    // Store current edit state to preserve on error
    final currentEditingReview = _editingReview;
    
    final ok = _editingReview == null
        ? await controller.create(input)
        : await controller.update(_editingReview!.id, input);
    
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.error ?? 'Failed to save review')),
      );
      // Ensure form stays open on error so user can retry
      setState(() {
        _showForm = true;
        // Preserve editing state on error
        _editingReview = currentEditingReview;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review saved')),
      );
      setState(() {
        _showForm = false;
        _commentCtrl.clear();
        _rating = 5;
        _tag = ReviewCategoryTag.teachingQuality;
        _editingReview = null;
      });
      widget.onReviewSubmitted?.call();
    }
  }

  Future<void> _confirmDelete(Review r) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.delete_outline,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 12),
            const Text('Delete review?'),
          ],
        ),
        content: const Text(
          'This action cannot be undone. Your review will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
            ),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final controller =
        ref.read(reviewsControllerProvider(widget.schoolId).notifier);
    await controller.remove(r.id);
  }
}

class _ReviewTile extends StatelessWidget {
  final Review review;
  final bool mine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Key? key;
  const _ReviewTile({
    required this.review,
    required this.mine,
    required this.onEdit,
    required this.onDelete,
    this.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                child: Text(
                  (review.parentFullName ?? '?')
                      .characters
                      .firstOrNull
                      ?.toUpperCase() ??
                      '?',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.parentFullName ?? 'Parent',
                        style: theme.textTheme.titleSmall),
                    Row(
                      children: [
                        for (var i = 0; i < 5; i++)
                          Icon(
                            i < review.rating
                                ? Icons.star
                                : Icons.star_border,
                            color: theme.colorScheme.tertiary,
                            size: 16,
                          ),
                        const SizedBox(width: 8),
                        Text(review.categoryTag.label(),
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              if (mine) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outlined),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ],
          ),
          if (review.comment?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 52),
              child: Text(review.comment!),
            ),
          const Divider(height: 24),
        ],
      ),
    );
  }
}

class _ReviewForm extends StatelessWidget {
  final int rating;
  final ReviewCategoryTag tag;
  final TextEditingController commentCtrl;
  final Function(int) onRatingChanged;
  final Function(ReviewCategoryTag) onTagChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final bool saving;
  final Key? key;

  const _ReviewForm({
    required this.rating,
    required this.tag,
    required this.commentCtrl,
    required this.onRatingChanged,
    required this.onTagChanged,
    required this.onSave,
    required this.onCancel,
    required this.saving,
    this.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: key,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rating', style: theme.textTheme.titleSmall),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    onPressed: () => onRatingChanged(i),
                    icon: Icon(
                      i <= rating ? Icons.star : Icons.star_border,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ReviewCategoryTag>(
              value: tag,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final t in ReviewCategoryTag.values)
                  DropdownMenuItem(value: t, child: Text(t.label())),
              ],
              onChanged: (v) => onTagChanged(v ?? tag),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: commentCtrl,
              decoration: const InputDecoration(
                labelText: 'Comment (optional)',
                hintText: 'Share your experience…',
              ),
              minLines: 2,
              maxLines: 5,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: saving ? null : onSave,
                  child: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
