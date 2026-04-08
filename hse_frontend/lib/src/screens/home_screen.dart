import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_models.dart';
import '../providers/post_provider.dart';
import '../providers/project_provider.dart';
import '../services/api_service.dart';
import '../widgets/post_card.dart';
import '../widgets/project_members_sidebar.dart';
import '../screens/safe_observation_form.dart';
import '../screens/profile_screen.dart';
import '../screens/admin_panel_screen.dart';
import '../screens/chat_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  bool _showMembersSidebar = false;
  ProjectSettings? _projectSettings;
  bool _isLoadingSettings = false;
  int _unreadMessageCount = 0;
  bool _isLoadingUnreadCount = false;
  List<Conversation> _conversations = [];
  bool _isLoadingConversations = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
      ref.read(projectProvider.notifier).fetchProjectMembers();
      _fetchProjectSettings();
      _fetchUnreadMessageCount();
      _fetchConversations();
      // Start polling for unread count every 10 seconds
      _startUnreadCountPolling();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for project changes - safe here because it's within build phase callback
  }

  void _fetchData() {
    final token = ref.read(projectProvider).token;
    if (token != null) {
      ref.read(postProvider.notifier).fetchPosts(token);
      // Start live feed polling every 15 seconds
      ref.read(postProvider.notifier).startLiveFeed(token);
    }
  }

  Future<void> _fetchProjectSettings() async {
    final token = ref.read(projectProvider).token;
    if (token == null) return;

    setState(() => _isLoadingSettings = true);
    try {
      final api = ApiService(baseUrl: ApiService.getDefaultBaseUrl());
      final settings = await api.getProjectSettings(token);
      setState(() {
        _projectSettings = ProjectSettings.fromJson(settings);
        _isLoadingSettings = false;
      });
    } catch (e) {
      setState(() => _isLoadingSettings = false);
      // Don't show error to user - just use defaults
    }
  }

  Future<void> _fetchUnreadMessageCount() async {
    final token = ref.read(projectProvider).token;
    if (token == null) return;

    setState(() => _isLoadingUnreadCount = true);
    try {
      final api = ApiService(baseUrl: ApiService.getDefaultBaseUrl());
      final count = await api.getUnreadMessageCount(token);
      setState(() {
        _unreadMessageCount = count;
        _isLoadingUnreadCount = false;
      });
    } catch (e) {
      setState(() => _isLoadingUnreadCount = false);
      // Don't show error to user
    }
  }

  void _startUnreadCountPolling() {
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _fetchUnreadMessageCount();
        _fetchConversations();
        _startUnreadCountPolling(); // Schedule next poll
      }
    });
  }

  Future<void> _fetchConversations() async {
    final token = ref.read(projectProvider).token;
    if (token == null) {
      setState(() => _isLoadingConversations = false);
      return;
    }

    setState(() => _isLoadingConversations = true);
    try {
      final api = ApiService(baseUrl: ApiService.getDefaultBaseUrl());
      final data = await api.getConversations(token);
      setState(() {
        _conversations = data.map((c) => Conversation.fromJson(c)).toList();
      });
    } catch (e) {
      // Error handling - keep existing conversations if any
    } finally {
      setState(() => _isLoadingConversations = false);
    }
  }

  Future<void> _markConversationAsRead(int senderId) async {
    final token = ref.read(projectProvider).token;
    if (token == null) return;

    try {
      final api = ApiService(baseUrl: ApiService.getDefaultBaseUrl());
      await api.markMessagesAsRead(token, senderId);
      // Refresh conversations and unread count
      await _fetchConversations();
      await _fetchUnreadMessageCount();
    } catch (e) {
      // Silently fail
    }
  }

  void _showCreateObservationDialog(BuildContext context) {
    final projectState = ref.read(projectProvider);
    final token = projectState.token;
    final projectId = projectState.project?.id;

    if (token == null || projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to determine the current project.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafetyObservationForm(
        onSubmit: (data) async {
          Navigator.pop(ctx);
          try {
            await ref.read(postProvider.notifier).createPost(
                  token: token,
                  projectId: projectId,
                  postType: data['postType'] as String,
                  incidentType: data['incidentType'] as String,
                  observation: data['observation'] as String,
                  description: data['description'] as String,
                  rectification: data['rectification'] as String,
                  severity: data['severity'] as String,
                  location: data['location'] as String,
                  imageBytes: data['imageBytes'] as List<Uint8List>?,
                  imageNames: data['imageNames'] as List<String>?,
                );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Observation created successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error creating observation: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ProjectState>(projectProvider, (previous, next) {
      final previousProject = previous?.project;
      final nextProject = next.project;
      if (nextProject != null && previousProject != nextProject) {
        _fetchProjectSettings();
      }
    });

    final projectState = ref.watch(projectProvider);
    final user = projectState.user;
    final project = projectState.project;
    final role = user?.role ?? 'OFFICER';
    final isAdmin = user?.isProjectAdmin ?? false;

    // Convert string role to UserRole enum
    final userRole = UserRoleX.fromString(role);

    // Build navigation items - ALWAYS ensure at least 2 items to prevent crash
    final navigationItems = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ];

    // Only add additional items if we have at least 2 base items
    if (role == 'MANAGER' || role == 'ADMIN' || isAdmin) {
      navigationItems.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Stats',
        ),
      );
    }

    if (isAdmin || role == 'ADMIN') {
      navigationItems.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
      );
    }

    final activeTabIndex = _currentIndex.clamp(0, navigationItems.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _projectSettings?.appName ?? 'HSEBOOK',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (project != null)
              Text(
                project.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        leading: Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.message),
              onPressed: () async => await _showMessengerDrawer(context),
              tooltip: 'HSE Messenger',
            ),
            if (_unreadMessageCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    _unreadMessageCount > 99
                        ? '99+'
                        : _unreadMessageCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          // Refresh project settings
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchProjectSettings();
              ref.read(projectProvider.notifier).refreshProject();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing project data...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Refresh',
          ),
          // Members sidebar toggle
          IconButton(
            icon: Icon(
              _showMembersSidebar ? Icons.people : Icons.people_outline,
            ),
            onPressed: () {
              setState(() => _showMembersSidebar = !_showMembersSidebar);
            },
            tooltip: 'Project Members',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(projectProvider.notifier).logout();
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Main content
          Expanded(
            child: Column(
              children: [
                // Project Dashboard Header
                _buildProjectDashboardHeader(),
                // Offline/Cached indicator
                _buildStatusBar(),
                // Tab content
                Expanded(child: _buildTabContent(userRole, activeTabIndex)),
              ],
            ),
          ),
          // Project Members Sidebar (now on the right)
          if (_showMembersSidebar)
            const SizedBox(width: 280, child: ProjectMembersSidebar()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateObservationDialog(context),
        backgroundColor: Colors.red.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: navigationItems.length >= 2
          ? BottomNavigationBar(
              currentIndex: activeTabIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              selectedItemColor: Colors.red.shade700,
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              items: navigationItems,
            )
          : null,
    );
  }

  Widget _buildProjectDashboardHeader() {
    final project = ref.watch(projectProvider).project;

    if (_isLoadingSettings) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.red.shade50,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final settings = _projectSettings;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border(bottom: BorderSide(color: Colors.red.shade200)),
      ),
      child: Row(
        children: [
          // Project Logo
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: settings?.logoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      settings!.logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.business,
                        size: 32,
                        color: Colors.red.shade700,
                      ),
                    ),
                  )
                : Icon(Icons.business, size: 32, color: Colors.red.shade700),
          ),
          const SizedBox(width: 16),
          // Project Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project?.name ?? 'Project Name',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Duration: ${settings?.projectDuration ?? project?.duration ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.people, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Manpower: ${settings?.manHours ?? 0}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Consumer(
      builder: (context, ref, child) {
        final postState = ref.watch(postProvider);

        if (postState.isOffline) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.orange.shade100,
            child: Row(
              children: [
                Icon(Icons.cloud_off, size: 16, color: Colors.orange.shade800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    postState.posts.isNotEmpty
                        ? 'Showing cached data (offline)'
                        : 'You are offline',
                    style: TextStyle(color: Colors.orange.shade800),
                  ),
                ),
              ],
            ),
          );
        }

        if (postState.error != null && postState.posts.isNotEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.blue.shade100,
            child: Row(
              children: [
                Icon(Icons.refresh, size: 16, color: Colors.blue.shade800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Showing cached data. Pull to refresh.',
                    style: TextStyle(color: Colors.blue.shade800),
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTabContent(UserRole role, int currentIndex) {
    switch (currentIndex) {
      case 0:
        return const _SafetyFeedTab();
      case 1:
        return const ProfileScreen();
      case 2:
        if (role == UserRole.manager || role == UserRole.admin) {
          return const _StatisticsTab();
        }
        return const ProfileScreen();
      case 3:
        if (role == UserRole.admin) {
          return const AdminPanelScreen();
        }
        return const _SafetyFeedTab();
      default:
        return const _SafetyFeedTab();
    }
  }

  Future<void> _showMessengerDrawer(BuildContext context) async {
    final projectState = ref.read(projectProvider);
    final currentUser = projectState.user;
    final token = projectState.token;

    // Ensure loading state is set before showing the drawer
    setState(() => _isLoadingConversations = true);
    
    // Refresh conversations when opening
    await _fetchConversations();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.message, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'HSE Messenger',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoadingConversations
                    ? const Center(child: CircularProgressIndicator())
                    : _conversations.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No conversations yet',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start messaging from project members',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _conversations.length,
                            itemBuilder: (context, index) {
                              final conversation = _conversations[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.red.shade100,
                                  child: Text(
                                    conversation.displayName.isNotEmpty
                                        ? conversation.displayName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(color: Colors.red.shade700),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        conversation.displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (conversation.unreadCount > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          conversation.unreadCount > 99
                                              ? '99+'
                                              : conversation.unreadCount.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(conversation.role),
                                    if (conversation.lastMessage != null)
                                      Text(
                                        conversation.lastMessage!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: conversation.unreadCount > 0
                                              ? Colors.black87
                                              : Colors.grey.shade600,
                                          fontWeight: conversation.unreadCount > 0
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                        ),
                                      ),
                                  ],
                                ),
                                isThreeLine: conversation.lastMessage != null,
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () async {
                                  // Mark messages as read before opening
                                  await _markConversationAsRead(conversation.userId);
                                  Navigator.pop(ctx);
                                  
                                  // Find the member to pass to ChatScreen
                                  final projectState = ref.read(projectProvider);
                                  final member = projectState.members.firstWhere(
                                    (m) => m.userId == conversation.userId,
                                    orElse: () => ProjectMember(
                                      userId: conversation.userId,
                                      username: conversation.username,
                                      email: '',
                                      firstName: conversation.name.split(' ').first,
                                      lastName: conversation.name.split(' ').length > 1
                                          ? conversation.name.split(' ').sublist(1).join(' ')
                                          : '',
                                      role: conversation.role,
                                      isProjectAdmin: conversation.isProjectAdmin,
                                      joinedAt: DateTime.now(),
                                    ),
                                  );
                                  
                                  await showDialog(
                                    context: context,
                                    builder: (dialogContext) => Dialog(
                                      insetPadding: const EdgeInsets.all(16),
                                      child: SizedBox(
                                        width: MediaQuery.of(context).size.width * 0.8,
                                        height: MediaQuery.of(context).size.height * 0.7,
                                        child: ChatScreen(
                                          recipient: member,
                                          currentUserId: currentUser?.id ?? 0,
                                          token: token ?? '',
                                          showAppBar: false,
                                        ),
                                      ),
                                    ),
                                  );
                                  // Refresh unread count after chat closes
                                  _fetchUnreadMessageCount();
                                  _fetchConversations();
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SafetyFeedTab extends ConsumerWidget {
  const _SafetyFeedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postState = ref.watch(postProvider);
    final token = ref.watch(projectProvider).token;

    if (postState.isLoading && postState.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (postState.error != null && postState.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${postState.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (token != null) {
                  ref.read(postProvider.notifier).fetchPosts(token);
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (postState.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No safety observations yet',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to report a safety observation!',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (token != null) {
          await ref.read(postProvider.notifier).fetchPosts(token);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: postState.posts.length,
        itemBuilder: (context, index) {
          final post = postState.posts[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PostCard(post: post),
          );
        },
      ),
    );
  }
}

class _StatisticsTab extends StatelessWidget {
  const _StatisticsTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          const Text('Statistics Dashboard', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            'Charts and metrics will be displayed here',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
