import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../providers/post_provider.dart';
import '../providers/project_provider.dart';
import '../services/api_service.dart';

class PostCard extends ConsumerStatefulWidget {
  final PostModel post;
  const PostCard({super.key, required this.post});

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  List<Comment> _allComments = [];
  bool _isLoadingComments = false;

  /// Helper function for dynamic status coloring
  Color _getStatusColor(String status) {
    return status == "APPROVED" || status == "Complete"
        ? Colors.green.shade700
        : Colors.red.shade700;
  }

  Color _getCategoryColor() {
    switch (widget.post.category.toLowerCase()) {
      case 'unsafe act':
        return Colors.red.shade700;
      case 'unsafe condition':
        return Colors.amber.shade700;
      case 'safe act':
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Future<void> _loadAllComments() async {
    if (_isLoadingComments) return;
    setState(() => _isLoadingComments = true);
    try {
      final token = ref.read(projectProvider).token;
      if (token == null) return;
      final api = ApiService(baseUrl: ApiService.getDefaultBaseUrl());
      final comments = await api.getComments(token, widget.post.id);
      setState(() {
        _allComments = comments;
        _isLoadingComments = false;
      });
    } catch (e) {
      setState(() => _isLoadingComments = false);
    }
  }

  void _showAddCommentDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.comment, color: Colors.red),
            SizedBox(width: 8),
            Text('Add Comment'),
          ],
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Write a comment...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final content = controller.text.trim();
              if (content.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final token = ref.read(projectProvider).token;
                if (token == null) return;
                final api = ApiService(baseUrl: ApiService.getDefaultBaseUrl());
                final newComment = await api.addComment(
                  token,
                  widget.post.id,
                  content,
                );
                // Add to local list and update UI instantly
                ref
                    .read(postProvider.notifier)
                    .addCommentLocally(widget.post.id, newComment);
                setState(() {
                  _allComments.add(newComment);
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Comment added!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _togglePostStatus() {
    final token = ref.read(projectProvider).token;
    ref
        .read(postProvider.notifier)
        .togglePostStatus(widget.post.id, token: token);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final postState = ref.watch(postProvider);
    // Find the current post in the state to get latest status
    final currentPost = postState.posts.firstWhere(
      (p) => p.id == widget.post.id,
      orElse: () => widget.post,
    );
    final statusColor = _getStatusColor(currentPost.status);
    final categoryColor = _getCategoryColor();

    final projectState = ref.watch(projectProvider);
    final user = projectState.user;
    final role = user?.role ?? 'OFFICER';
    final isAdmin = user?.isProjectAdmin ?? false;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: categoryColor,
              child: currentPost.authorProfilePicture != null
                  ? ClipOval(
                      child: Image.network(
                        currentPost.authorProfilePicture!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text(
                      currentPost.authorName.isNotEmpty
                          ? currentPost.authorName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            title: Text(
              currentPost.authorName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${currentPost.authorRole} • ${currentPost.authorAssignedArea}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.circle, size: 10, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      currentPost.status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: categoryColor),
                      ),
                      child: Text(
                        currentPost.category,
                        style: TextStyle(
                          color: categoryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (currentPost.commentsCount > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.comment, size: 14, color: Colors.grey),
                      Text(
                        currentPost.commentsCount.toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                Text(
                  _formatDate(currentPost.createdAt),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              currentPost.content,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          // Display multiple images
          if (currentPost.imageUrls.isNotEmpty)
            SizedBox(
              height: 250,
              child: PageView.builder(
                itemCount: currentPost.imageUrls.length,
                itemBuilder: (context, index) {
                  final imgUrl = currentPost.imageUrls[index];
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imgUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                          child: Icon(Icons.broken_image, size: 50),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const Divider(height: 1),
          // YouTube-Style Comment Dropdown
          ExpansionTile(
            leading: const Icon(Icons.comment, size: 20),
            title: Text(
              'Comments (${currentPost.commentsCount})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            onExpansionChanged: (expanded) {
              if (expanded && _allComments.isEmpty) {
                _loadAllComments();
              }
            },
            children: [
              if (_isLoadingComments)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_allComments.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No comments yet. Be the first!',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _allComments.length,
                  itemBuilder: (context, index) {
                    final comment = _allComments[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red.shade100,
                        child: Text(
                          comment.authorName.isNotEmpty
                              ? comment.authorName[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(
                        comment.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(comment.content),
                      trailing: Text(
                        _formatDate(comment.createdAt),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              // Add comment button
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton.icon(
                  onPressed: _showAddCommentDialog,
                  icon: const Icon(Icons.add_comment, size: 20),
                  label: const Text('Add a comment'),
                ),
              ),
            ],
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (role == 'SUPERVISOR' ||
                    role == 'MANAGER' ||
                    role == 'ADMIN' ||
                    isAdmin) ...[
                  TextButton.icon(
                    onPressed: _togglePostStatus,
                    icon: Icon(
                      currentPost.status == 'Complete'
                          ? Icons.check_circle
                          : Icons.pending,
                      color: statusColor,
                      size: 28,
                    ),
                    label: Text(
                      currentPost.status == 'Complete'
                          ? 'Mark Pending'
                          : 'Mark Complete',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showAddCommentDialog,
                    icon: const Icon(
                      Icons.comment_rounded,
                      color: Colors.black,
                      size: 28,
                    ),
                    label: const Text(
                      'Comment',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                if (role == 'ADMIN' || role == 'MANAGER' || isAdmin) ...[
                  TextButton.icon(
                    onPressed: () => _confirmDeletePost(context, ref),
                    icon: const Icon(
                      Icons.delete_forever_rounded,
                      color: Colors.red,
                      size: 28,
                    ),
                    label: const Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePost(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Post'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final projectState = ref.read(projectProvider);
              final token = projectState.token;
              if (token == null) return;
              Navigator.pop(ctx);
              try {
                await ref
                    .read(postProvider.notifier)
                    .deletePost(token, widget.post.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Post deleted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting post: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
