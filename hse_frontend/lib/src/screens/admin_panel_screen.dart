import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  XFile? _selectedLogo;
  Uint8List? _logoBytes;

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

  @override
  void dispose() {
    _appNameController.dispose();
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
      final settings = ProjectSettings.fromJson(data);
      setState(() {
        _settings = settings;
        _isLoadingSettings = false;
        _appNameController.text = settings.appName;
        _projectAreaController.text = settings.projectArea;
        _projectDurationController.text = settings.projectDuration;
        _manHoursController.text = settings.manHours.toString();
        _equipmentCountController.text = settings.equipmentCount.toString();
      });
    } catch (e) {
      setState(() => _isLoadingSettings = false);
    }
  }

  Future<void> _saveSettings() async {
    final token = ref.read(projectProvider).token;
    if (token == null) return;
    setState(() => _isSaving = true);
    try {
      final api = ApiService(baseUrl: ApiService.getDefaultBaseUrl());
      await api.updateProjectSettings(
        token,
        appName: _appNameController.text.trim(),
        projectArea: _projectAreaController.text.trim(),
        projectDuration: _projectDurationController.text.trim(),
        manHours: int.tryParse(_manHoursController.text) ?? 0,
        equipmentCount: int.tryParse(_equipmentCountController.text) ?? 0,
        logoBytes: _logoBytes,
        logoName: _selectedLogo?.name,
      );
      await _loadSettings();
      ref.read(projectProvider.notifier).refreshProject();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved!')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    final token = ref.read(projectProvider).token;
    if (token == null) return;
    try {
      final api = ApiService(baseUrl: ApiService.getDefaultBaseUrl());
      await api.deleteUser(token, userId);
      ref.read(projectProvider.notifier).removeMember(userId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting user: $e')));
    }
  }

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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Theme colors updated!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating colors: $e')));
    }
  }

  Future<void> _assignArea(int userId, String area) async {
    final token = ref.read(projectProvider).token;
    if (token == null) return;
    try {
      final api = ApiService(baseUrl: ApiService.getDefaultBaseUrl());
      await api.assignUserArea(token, userId, area);
      ref.read(projectProvider.notifier).fetchProjectMembers();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Area assigned successfully!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error assigning area: $e')));
    }
  }

  Future<void> _copyAccessKeyToClipboard() async {
    if (_settings?.accessCode == null) return;
    await Clipboard.setData(ClipboardData(text: _settings!.accessCode!));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Access key copied to clipboard!')),
      );
    }
  }

  Future<void> _regenerateAccessKey() async {
    final token = ref.read(projectProvider).token;
    if (token == null) return;
    setState(() => _isSaving = true);
    try {
      final api = ApiService(baseUrl: ApiService.getDefaultBaseUrl());
      final result = await api.regenerateProjectKey(token);
      final newKey = result['access_code'] as String?;
      if (newKey != null) {
        setState(() {
          _settings = _settings?.copyWith(accessCode: newKey);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Access key regenerated successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to regenerate key: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
    if (_isLoadingSettings) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Project Access Key', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Share this key with Officers and Supervisors to join your project:',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _settings?.accessCode ?? 'Loading...',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _copyAccessKeyToClipboard(),
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('Copy Key'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : () => _regenerateAccessKey(),
                          icon: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh, size: 18),
                          label: Text(_isSaving ? 'Regenerating...' : 'Regenerate'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Project Customization', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _colorTile('Primary Theme Color', _primaryColor, (c) => _updateColors(c, _secondaryColor)),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                  child: _logoBytes != null ? Image.memory(_logoBytes!) : (_settings?.logoUrl != null ? Image.network(_settings!.logoUrl!) : const Icon(Icons.business, size: 40)),
                ),
                TextButton.icon(onPressed: _pickLogo, icon: const Icon(Icons.upload), label: const Text('Change Logo')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(controller: _appNameController, decoration: const InputDecoration(labelText: 'App Name', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _projectAreaController, decoration: const InputDecoration(labelText: 'Project Area', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _projectDurationController, decoration: const InputDecoration(labelText: 'Project Duration', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: TextField(controller: _manHoursController, decoration: const InputDecoration(labelText: 'Manpower'), keyboardType: TextInputType.number)),
              const SizedBox(width: 16),
              Expanded(child: TextField(controller: _equipmentCountController, decoration: const InputDecoration(labelText: 'Equipment'), keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isSaving ? null : _saveSettings, child: Text(_isSaving ? 'Saving...' : 'Save Settings'))),
        ],
      ),
    );
  }

  Widget _buildUserManagementTab(List<ProjectMember> members) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(member.fullName[0])),
            title: Text(member.fullName),
            subtitle: Text(member.role),
            trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteUser(member.userId)),
          ),
        );
      },
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
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(child: Text(member.fullName[0])),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextField(controller: controller, decoration: const InputDecoration(hintText: 'Location', isDense: true)),
                    ],
                  ),
                ),
                IconButton(onPressed: () => _assignArea(member.userId, controller.text), icon: const Icon(Icons.check_circle, color: Colors.green)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _colorTile(String title, Color color, Function(Color) onSelect) {
    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(backgroundColor: color, radius: 14),
          IconButton(onPressed: () => onSelect(color == Colors.red.shade700 ? Colors.blue.shade700 : Colors.red.shade700), icon: const Icon(Icons.palette)),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isSelected ? Colors.red.shade700 : Colors.transparent, borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey.shade700),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }
}
