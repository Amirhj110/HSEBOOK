import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_models.dart';
import '../providers/project_provider.dart';
import '../services/api_service.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  int _selectedTab = 0;
  ProjectSettings? _settings;
  bool _isLoadingSettings = false;
  bool _isSaving = false;

  // Settings controllers
  late TextEditingController _appNameController;
  late TextEditingController _projectAreaController;
  late TextEditingController _projectDurationController;
  late TextEditingController _manHoursController;
  late TextEditingController _equipmentCountController;

  Color _primaryColor = Colors.red.shade700;
  Color _secondaryColor = Colors.grey.shade800;

  @override
  void initState() {
    super.initState();
    _appNameController = TextEditingController();
    _projectAreaController = TextEditingController();
    _projectDurationController = TextEditingController();
    _manHoursController = TextEditingController();
    _equipmentCountController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
      ref.read(projectProvider.notifier).fetchProjectMembers();
    });
  }

  // ... (dispose, _loadSettings, _saveSettings, _pickLogo, _deleteUser) ...

  Future<void> _updateColors(Color primary, Color secondary) async {
    final token = ref.read(projectProvider).token;
    if (token == null) return;
    try {
      final api = ApiService(baseUrl: ApiService.getDefaultBaseUrl());
      await api.updateProjectColors(token, primary.value.toRadixString(16), secondary.value.toRadixString(16));
      setState(() {
        _primaryColor = primary;
        _secondaryColor = secondary;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Theme colors updated!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating colors: $e')));
    }
  }

  Future<void> _assignArea(int userId, String area) async {
    final token = ref.read(projectProvider).token;
    if (token == null) return;
    try {
      final api = ApiService(baseUrl: ApiService.getDefaultBaseUrl());
      await api.assignUserArea(token, userId, area);
      ref.read(projectProvider.notifier).fetchProjectMembers();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Area assigned successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error assigning area: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectProvider);
    final members = projectState.members;
    final user = projectState.user;

    if (user?.isProjectAdmin != true && user?.role != 'ADMIN') {
      return const Center(child: Text('Access Denied: Admin privileges required'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Control Panel', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
            child: Row(
              children: [
                _TabButton(label: 'Settings', icon: Icons.settings, isSelected: _selectedTab == 0, onTap: () => setState(() => _selectedTab = 0)),
                _TabButton(label: 'Users', icon: Icons.people, isSelected: _selectedTab == 1, onTap: () => setState(() => _selectedTab = 1)),
                _TabButton(label: 'Assignments', icon: Icons.map_outlined, isSelected: _selectedTab == 2, onTap: () => setState(() => _selectedTab = 2)),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildSettingsTab(),
                _buildUserManagementTab(members),
                _buildAssignmentsTab(members),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Project Customization'),
          const SizedBox(height: 16),
          // Theme Color selection
          _colorTile('Primary Theme Color', _primaryColor, (c) => _updateColors(c, _secondaryColor)),
          const SizedBox(height: 16),
          _buildSettingsFields(),
        ],
      ),
    );
  }

  Widget _buildAssignmentsTab(List<ProjectMember> members) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final controller = TextEditingController(text: member.assignedArea);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: _primaryColor.withOpacity(0.1), child: Text(member.fullName[0])),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(member.role, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: 'Assign Location (e.g., Zone B)',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _assignArea(member.userId, controller.text),
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _colorTile(String title, Color color, Function(Color) onSelect) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(backgroundColor: color, radius: 16),
          const SizedBox(width: 8),
          IconButton(onPressed: () {
            // Simple color picker pop-up simulation
            onSelect(Colors.red.shade700 == color ? Colors.blue.shade700 : Colors.red.shade700);
          }, icon: const Icon(Icons.palette_outlined)),
        ],
      ),
    );
  }
}
  @override
  void dispose() {
    _appNameController.dispose();
    _projectNameController.dispose();
    _projectAreaController.dispose();
    _projectDurationController.dispose();
    _manHoursController.dispose();
    _equipmentCountController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final token = ref.read(projectProvider).token;
    if (token == null) return;

    setState(() => _isLoadingSettings = true);
    try {
      final api = ApiService(baseUrl: ApiService.getDefaultBaseUrl());
      final data = await api.getProjectSettings(token);
      setState(() {
        _settings = ProjectSettings.fromJson(data);
        _isLoadingSettings = false;
      });

      // Populate controllers
      _appNameController.text = _settings?.appName ?? 'HSEBOOK';
      _projectNameController.text =
          ref.read(projectProvider).project?.name ?? '';
      _projectAreaController.text = _settings?.projectArea ?? '';
      _projectDurationController.text = _settings?.projectDuration ?? '';
      _manHoursController.text = (_settings?.manHours ?? 0).toString();
      _equipmentCountController.text =
          (_settings?.equipmentCount ?? 0).toString();
    } catch (e) {
      setState(() => _isLoadingSettings = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load settings: $e')));
      }
    }
  }

  Future<void> _saveSettings() async {
    final token = ref.read(projectProvider).token;
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No authentication token available'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    try {
      final api = ApiService(baseUrl: ApiService.getDefaultBaseUrl());

      final result = await api.updateProjectSettings(
        token,
        appName: _appNameController.text.trim(),
        projectArea: _projectAreaController.text.trim(),
        projectDuration: _projectDurationController.text.trim(),
        manHours: int.tryParse(_manHoursController.text) ?? 0,
        equipmentCount: int.tryParse(_equipmentCountController.text) ?? 0,
        logoBytes: _logoBytes,
        logoName: _selectedLogo?.name,
      );

      if (!mounted) return;

      setState(() => _isSaving = false);

      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save settings. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Reload settings and refresh project data
      await _loadSettings();
      ref.read(projectProvider.notifier).refreshProject();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedLogo = pickedFile;
        _logoBytes = bytes;
      });
    }
  }

  Future<void> _deleteUser(int userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete User'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this user? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final token = ref.read(projectProvider).token;
    if (token == null) return;

    try {
      final api = ApiService(baseUrl: ApiService.getDefaultBaseUrl());
      await api.deleteUser(token, userId);

      // Remove user from local list immediately for instant UI update
      ref.read(projectProvider.notifier).removeMember(userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectProvider);
    final members = projectState.members;
    final user = projectState.user;

    // Only visible to admin users
    if (user?.isProjectAdmin != true && user?.role != 'ADMIN') {
      return const Center(
        child: Text('Access Denied: Admin privileges required'),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Tab selector
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    label: 'Project Settings',
                    icon: Icons.settings,
                    isSelected: _selectedTab == 0,
                    onTap: () => setState(() => _selectedTab = 0),
                  ),
                ),
                Expanded(
                  child: _TabButton(
                    label: 'User Management',
                    icon: Icons.people,
                    isSelected: _selectedTab == 1,
                    onTap: () => setState(() => _selectedTab = 1),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _selectedTab == 0
                ? _buildSettingsTab()
                : _buildUserManagementTab(members),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    if (_isLoadingSettings) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.settings, color: Colors.red.shade600),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Project Settings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Customize your project details',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Logo picker
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: _logoBytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    _logoBytes!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : _settings?.logoUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        _settings!.logoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(
                                          Icons.business,
                                          size: 48,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.business,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _pickLogo,
                          icon: const Icon(Icons.upload),
                          label: const Text('Change Logo'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // App Name
                  TextField(
                    controller: _appNameController,
                    decoration: InputDecoration(
                      labelText: 'App Name',
                      hintText: 'HSEBOOK',
                      prefixIcon: const Icon(Icons.app_shortcut),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Project Name (read-only from Project model)
                  TextField(
                    controller: _projectNameController,
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Project Name',
                      prefixIcon: const Icon(Icons.work),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Project Area
                  TextField(
                    controller: _projectAreaController,
                    decoration: InputDecoration(
                      labelText: 'Project Area',
                      hintText: 'e.g., Construction Site A',
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Project Duration
                  TextField(
                    controller: _projectDurationController,
                    decoration: InputDecoration(
                      labelText: 'Project Duration',
                      hintText: 'e.g., 12 months',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Manpower
                  TextField(
                    controller: _manHoursController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Manpower (Man-hours)',
                      hintText: '0',
                      prefixIcon: const Icon(Icons.people),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Equipment Count
                  TextField(
                    controller: _equipmentCountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Equipment Count',
                      hintText: '0',
                      prefixIcon: const Icon(Icons.construction),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveSettings,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Saving...' : 'Save Settings'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserManagementTab(List<ProjectMember> members) {
    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No members found',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final currentUserId = ref.read(projectProvider).user?.id;
        final isCurrentUser = member.userId == currentUserId;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getRoleColor(member.role).withOpacity(0.2),
              child: Text(
                member.fullName.isNotEmpty
                    ? member.fullName[0].toUpperCase()
                    : '?',
                style: TextStyle(color: _getRoleColor(member.role)),
              ),
            ),
            title: Text(
              member.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.role),
                Text(
                  member.email,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            trailing: isCurrentUser
                ? Chip(
                    label: const Text('You'),
                    backgroundColor: Colors.blue.shade100,
                  )
                : IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteUser(member.userId),
                    tooltip: 'Delete User',
                  ),
          ),
        );
      },
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return Colors.red;
      case 'MANAGER':
        return Colors.orange;
      case 'SUPERVISOR':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.shade700 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
