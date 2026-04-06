import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_models.dart';

class ObservationCard extends StatelessWidget {
  final PostModel observation;
  final VoidCallback? onStatusToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onCommentTap;

  const ObservationCard({
    super.key,
    required this.observation,
    this.onStatusToggle,
    this.onDelete,
    this.onCommentTap,
  });

  Color _getStatusColor() {
    switch (observation.status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade700;
      case 'complete':
        return Colors.green.shade700;
      case 'open':
        return Colors.red.shade700;
      case 'closed':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Color _getCategoryColor() {
    switch (observation.category.toLowerCase()) {
      case 'unsafe act':
        return Colors.red.shade700;
      case 'unsafe condition':
        return Colors.orange.shade700;
      case 'safe act':
        return Colors.blue.shade700;
      default:
        return Colors.blueGrey.shade700;
    }
  }

  IconData _getCategoryIcon() {
    switch (observation.category.toLowerCase()) {
      case 'unsafe act':
        return Icons.warning_rounded;
      case 'unsafe condition':
        return Icons.construction;
      case 'safe act':
        return Icons.shield;
      default:
        return Icons.assignment_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final categoryColor = _getCategoryColor();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with author info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: categoryColor.withOpacity(0.2),
                  backgroundImage: observation.authorProfilePicture != null
                      ? NetworkImage(observation.authorProfilePicture!)
                      : null,
                  child: observation.authorProfilePicture == null
                      ? Text(
                          observation.authorName.isNotEmpty
                              ? observation.authorName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: categoryColor,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        observation.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            observation.authorRole,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.room_outlined,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              observation.authorAssignedArea.isNotEmpty
                                  ? observation.authorAssignedArea
                                  : 'Not assigned',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor, width: 1.5),
                  ),
                  child: Text(
                    observation.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Category badge
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(_getCategoryIcon(), color: categoryColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  observation.category,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: categoryColor,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat(
                    'MMM dd, yyyy • hh:mm a',
                  ).format(observation.createdAt),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              observation.content,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ),
          // Images
          if (observation.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: PageView.builder(
                itemCount: observation.imageUrls.length,
                controller: PageController(viewportFraction: 0.9),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        observation.imageUrls[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.broken_image,
                            size: 60,
                            color: Colors.grey,
                          ),
                        ),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: Colors.grey.shade200,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: categoryColor,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
          ],
          // Footer with count and actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                if (observation.commentsCount > 0) ...[
                  InkWell(
                    onTap: onCommentTap,
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_outlined,
                          color: Colors.grey.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${observation.commentsCount} Comments',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
                if (onStatusToggle != null)
                  TextButton.icon(
                    onPressed: onStatusToggle,
                    icon: Icon(
                      observation.isComplete
                          ? Icons.check_circle
                          : Icons.pending,
                      color: statusColor,
                    ),
                    label: Text(
                      observation.isComplete ? 'Pending' : 'Complete',
                      style: TextStyle(color: statusColor),
                    ),
                  ),
                if (onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Delete',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
