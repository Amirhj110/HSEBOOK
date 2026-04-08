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
    // Find the latest post from provider to keep UI in sync
    final currentPost = postState.posts.firstWhere(
      (p) => p.id == widget.post.id,
      orElse: () => widget.post,
    );
    final statusColor = currentPost.isComplete ? Colors.green.shade700 : Colors.red.shade700;
    final categoryColor = _getCategoryColor();

    final projectState = ref.watch(projectProvider);
    final user = projectState.user;
    final role = user?.role ?? 'OFFICER';
    final isAdmin = user?.isProjectAdmin ?? false;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Author & Status
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: categoryColor.withOpacity(0.1),
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
                      style: TextStyle(color: categoryColor, fontWeight: FontWeight.bold),
                    ),
            ),
            title: Text(
              currentPost.authorName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${currentPost.authorRole} • ${currentPost.location}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _badge(currentPost.postType.toUpperCase(), Colors.blue.shade700),
                    const SizedBox(width: 8),
                    _badge(currentPost.incidentType.toUpperCase(), categoryColor),
                    const SizedBox(width: 8),
                    _badge(currentPost.status.toUpperCase(), statusColor),
                  ],
                ),
              ],
            ),
            trailing: Text(
              _formatDate(currentPost.createdAt),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ),

          // Post Content Sections
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (currentPost.observation.isNotEmpty) ...[
                  Text(
                    currentPost.observation,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  currentPost.description,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
                if (currentPost.rectification.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_outline, size: 18, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                              children: [
                                const TextSpan(text: 'Rectification: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: currentPost.rectification),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Image Gallery
          if (currentPost.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: currentPost.imageUrls.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        currentPost.imageUrls[index],
                        width: 300,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),

          // Quick Comments (Top 2)
          if (currentPost.recentComments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: currentPost.recentComments.take(2).map((c) => _buildMiniComment(c)).toList(),
              ),
            ),

          // Action Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                if (role == 'SUPERVISOR' || role == 'MANAGER' || role == 'ADMIN' || isAdmin)
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _showAddCommentDialog,
                      icon: const Icon(Icons.comment_outlined, size: 20),
                      label: const Text('Comment'),
                    ),
                  ),
                if (role == 'MANAGER' || role == 'ADMIN' || isAdmin)
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _togglePostStatus,
                      icon: Icon(
                        currentPost.isComplete ? Icons.lock_open : Icons.lock_outline,
                        size: 20,
                        color: statusColor,
                      ),
                      label: Text(
                        currentPost.isComplete ? 'Reopen' : 'Close',
                        style: TextStyle(color: statusColor),
                      ),
                    ),
                  ),
                if (isAdmin || role == 'ADMIN')
                  IconButton(
                    onPressed: () => _confirmDeletePost(context, ref),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                
                // Expansion toggle for all comments
                if (currentPost.commentsCount > 2)
                  TextButton(
                    onPressed: _loadAllComments,
                    child: Text('View all ${currentPost.commentsCount} comments'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMiniComment(Comment comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${comment.authorName}: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Expanded(
            child: Text(
              comment.content,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
