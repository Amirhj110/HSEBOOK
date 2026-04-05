import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';

class ProjectState {
  final bool isLoggedIn;
  final String? token;
  final String? refreshToken;
  final AppUser? user;
  final Project? project;
  final List<ProjectMember> members;
  final bool isLoading;
  final String? error;

  const ProjectState({
    this.isLoggedIn = false,
    this.token,
    this.refreshToken,
    this.user,
    this.project,
    this.members = const [],
    this.isLoading = false,
    this.error,
  });

  ProjectState copyWith({
    bool? isLoggedIn,
    String? token,
    String? refreshToken,
    AppUser? user,
    Project? project,
    List<ProjectMember>? members,
    bool? isLoading,
    String? error,
  }) {
    return ProjectState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      user: user ?? this.user,
      project: project ?? this.project,
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProjectNotifier extends StateNotifier<ProjectState> {
  ProjectNotifier() : super(const ProjectState()) {
    _initHive();
  }

  final api = ApiService(baseUrl: ApiService.getDefaultBaseUrl());
  static const String _userBoxName = 'user_box';
  static const String _projectBoxName = 'project_box';

  Future<void> _initHive() async {
    await Hive.initFlutter();
    await _loadCachedData();
  }

  Future<void> _loadCachedData() async {
    try {
      final userBox = await Hive.openBox(_userBoxName);
      final projectBox = await Hive.openBox(_projectBoxName);

      final cachedUser = userBox.get('current_user');
      final cachedProject = projectBox.get('current_project');
      final cachedToken = userBox.get('token');
      final cachedRefreshToken = userBox.get('refresh_token');

      if (cachedUser != null && cachedToken != null) {
        state = state.copyWith(
          isLoggedIn: true,
          user: AppUser.fromJson(Map<String, dynamic>.from(cachedUser)),
          project: cachedProject != null
              ? Project.fromJson(Map<String, dynamic>.from(cachedProject))
              : null,
          token: cachedToken,
          refreshToken: cachedRefreshToken,
        );
      }
    } catch (e) {
      // Ignore cache errors
    }
  }

  Future<void> _cacheUserData() async {
    try {
      final userBox = await Hive.openBox(_userBoxName);
      final projectBox = await Hive.openBox(_projectBoxName);

      if (state.user != null) {
        await userBox.put('current_user', state.user!.toJson());
      }
      if (state.project != null) {
        await projectBox.put('current_project', state.project!.toJson());
      }
      if (state.token != null) {
        await userBox.put('token', state.token);
      }
      if (state.refreshToken != null) {
        await userBox.put('refresh_token', state.refreshToken);
      }
    } catch (e) {
      // Ignore cache errors
    }
  }

  /// Admin Registration - Creates user and project
  Future<void> registerAsAdmin({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String projectName,
    required String projectArea,
    required String projectDuration,
    String? role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await api.registerAdmin(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        projectName: projectName,
        projectArea: projectArea,
        projectDuration: projectDuration,
        role: role,
      );

      final loginResponse = LoginResponse.fromJson(response);
      state = state.copyWith(
        isLoggedIn: true,
        token: loginResponse.tokens.accessToken,
        refreshToken: loginResponse.tokens.refreshToken,
        user: loginResponse.user,
        project: loginResponse.project,
        isLoading: false,
      );
      await _cacheUserData();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Staff Registration - Joins existing project
  Future<void> registerAsStaff({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String projectName,
    required String accessCode,
    String? role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await api.registerStaff(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        projectName: projectName,
        accessCode: accessCode,
        role: role,
      );

      final loginResponse = LoginResponse.fromJson(response);
      state = state.copyWith(
        isLoggedIn: true,
        token: loginResponse.tokens.accessToken,
        refreshToken: loginResponse.tokens.refreshToken,
        user: loginResponse.user,
        project: loginResponse.project,
        isLoading: false,
      );
      await _cacheUserData();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Regular Login
  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await api.login(username: username, password: password);
      final token = result['access']?.toString();
      final refresh = result['refresh']?.toString();

      if (token == null) throw Exception('No access token received');

      // Get user profile to get project info
      final profile = await api.getUserProfile(token);
      final user = AppUser.fromJson(profile);

      // Get project details if available
      Project? project;
      try {
        final projectData = await api.getProject(token);
        project = Project.fromJson(projectData);
      } catch (e) {
        // User might not have a project yet
      }

      state = state.copyWith(
        isLoggedIn: true,
        token: token,
        refreshToken: refresh,
        user: user,
        project: project,
        isLoading: false,
      );
      await _cacheUserData();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Fetch project members
  Future<void> fetchProjectMembers() async {
    final token = state.token;
    if (token == null) return;

    try {
      final members = await api.getProjectMembers(token);
      state = state.copyWith(members: members);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Regenerate project access key
  Future<String> regenerateAccessKey(String token) async {
    final result = await api.regenerateProjectKey(token);
    final newKey = result['access_code'] as String?;

    if (newKey != null && state.project != null) {
      final updatedProject = Project(
        id: state.project!.id,
        name: state.project!.name,
        area: '',
        duration: '',
        accessCode: newKey,
        adminId: state.project!.adminId,
      );
      state = state.copyWith(project: updatedProject);
      await _cacheUserData();
    }

    return newKey ?? '';
  }

  /// Refresh project data from API
  Future<void> refreshProject() async {
    final token = state.token;
    if (token == null) return;

    try {
      final projectData = await api.getProject(token);
      final project = Project.fromJson(projectData);
      state = state.copyWith(project: project);
      await _cacheUserData();
    } catch (e) {
      // Handle error silently
    }
  }

  /// Remove a member from the local list (for immediate UI update)
  void removeMember(int userId) {
    final updatedMembers = state.members
        .where((m) => m.userId != userId)
        .toList();
    state = state.copyWith(members: updatedMembers);
  }

  Future<void> updateUserProfile(
    String token, {
    String? firstName,
    String? lastName,
    String? bio,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await api.updateUserProfile(
        token,
        firstName: firstName,
        lastName: lastName,
        bio: bio,
      );
      // Refresh profile
      final profile = await api.getUserProfile(token);
      final updatedUser = AppUser.fromJson(profile);
      state = state.copyWith(user: updatedUser, isLoading: false);
      await _cacheUserData();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  void logout() {
    state = const ProjectState();
    // Clear cached data
    Hive.deleteBoxFromDisk(_userBoxName);
    Hive.deleteBoxFromDisk(_projectBoxName);
  }
}

final projectProvider = StateNotifierProvider<ProjectNotifier, ProjectState>(
  (ref) => ProjectNotifier(),
);
