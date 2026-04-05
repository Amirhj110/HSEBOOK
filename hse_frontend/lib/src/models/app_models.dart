import 'package:hive/hive.dart';

enum UserRole { admin, manager, supervisor, officer }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.manager:
        return 'Manager';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.officer:
        return 'Officer';
    }
  }

  String get apiValue {
    switch (this) {
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.manager:
        return 'MANAGER';
      case UserRole.supervisor:
        return 'SUPERVISOR';
      case UserRole.officer:
        return 'OFFICER';
    }
  }

  static UserRole fromString(String value) {
    final upper = value.toUpperCase();
    switch (upper) {
      case 'ADMIN':
        return UserRole.admin;
      case 'MANAGER':
        return UserRole.manager;
      case 'SUPERVISOR':
        return UserRole.supervisor;
      default:
        return UserRole.officer;
    }
  }
}

class Comment {
  final int id;
  final String authorName;
  final String content;
  final String? authorPicture;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.authorName,
    required this.content,
    this.authorPicture,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as int? ?? 0,
      authorName: json['author_name'] as String? ?? '',
      content: json['content'] as String? ?? '',
      authorPicture: json['author_picture'],
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class AppUser {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final bool isProjectAdmin;
  final int? projectId;
  final String? profilePicture;
  final String bio;
  final String assignedArea;

  const AppUser({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.isProjectAdmin,
    this.projectId,
    this.profilePicture,
    this.bio = '',
    this.assignedArea = '',
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    String? profilePicture;
    String bio = '';
    String assignedArea = '';
    int? projectId;

    final profile = json['profile'] as Map<String, dynamic>?;
    if (profile != null) {
      profilePicture = profile['profile_picture'];
      bio = profile['bio'] as String? ?? '';
      assignedArea = profile['assigned_area'] as String? ?? '';
      projectId = profile['project_id'] as int?;
    }

    profilePicture = profilePicture ?? json['profile_picture'];
    bio = bio.isNotEmpty ? bio : json['bio'] as String? ?? '';
    assignedArea = assignedArea.isNotEmpty
        ? assignedArea
        : json['assigned_area'] as String? ?? '';
    projectId = projectId ?? json['project_id'] as int?;

    return AppUser(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      role: json['role'] as String? ?? 'OFFICER',
      isProjectAdmin: json['is_project_admin'] as bool? ?? false,
      projectId: projectId,
      profilePicture: profilePicture,
      bio: bio,
      assignedArea: assignedArea,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'is_project_admin': isProjectAdmin,
      'project_id': projectId,
      'profile_picture': profilePicture,
      'bio': bio,
      'assigned_area': assignedArea,
    };
  }
}

class Project {
  final int id;
  final String name;
  final String area;
  final String duration;
  final String accessCode;
  final int? adminId;

  const Project({
    required this.id,
    required this.name,
    required this.area,
    required this.duration,
    required this.accessCode,
    this.adminId,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      area: json['area'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      accessCode: (json['access_code'] as String? ?? ''),
      adminId: json['admin'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'area': area,
      'duration': duration,
      'access_code': accessCode,
      'admin': adminId,
    };
  }

  Project copyWith({
    int? id,
    String? name,
    String? area,
    String? duration,
    String? accessCode,
    int? adminId,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      area: area ?? this.area,
      duration: duration ?? this.duration,
      accessCode: accessCode ?? this.accessCode,
      adminId: adminId ?? this.adminId,
    );
  }
}

class ProjectStats {
  final String projectName;
  final String projectArea;
  final String projectDuration;
  final int manHours;
  final int totalObservations;
  final int equipmentCount;
  final int pendingObservations;
  final int completeObservations;

  const ProjectStats({
    required this.projectName,
    required this.projectArea,
    required this.projectDuration,
    required this.manHours,
    required this.totalObservations,
    required this.equipmentCount,
    required this.pendingObservations,
    required this.completeObservations,
  });

  factory ProjectStats.fromJson(Map<String, dynamic> json) {
    return ProjectStats(
      projectName: json['project_name'] as String? ?? '',
      projectArea: json['project_area'] as String? ?? '',
      projectDuration: json['project_duration'] as String? ?? '',
      manHours: json['man_hours'] as int? ?? 0,
      totalObservations: json['total_observations'] as int? ?? 0,
      equipmentCount: json['equipment_count'] as int? ?? 0,
      pendingObservations: json['pending_observations'] as int? ?? 0,
      completeObservations: json['complete_observations'] as int? ?? 0,
    );
  }
}

class ProjectSettings {
  final int id;
  final String appName;
  final String theme;
  final String? logoUrl;
  final String projectArea;
  final String projectDuration;
  final int manHours;
  final int equipmentCount;

  const ProjectSettings({
    required this.id,
    required this.appName,
    required this.theme,
    this.logoUrl,
    this.projectArea = '',
    this.projectDuration = '',
    this.manHours = 0,
    this.equipmentCount = 0,
  });

  factory ProjectSettings.fromJson(Map<String, dynamic> json) {
    return ProjectSettings(
      id: json['id'] as int? ?? 0,
      appName: json['app_name'] as String? ?? 'HSEBOOK',
      theme: json['theme'] as String? ?? 'hse_red',
      logoUrl: json['logo'] as String?,
      projectArea: json['project_area'] as String? ?? '',
      projectDuration: json['project_duration'] as String? ?? '',
      manHours: json['man_hours'] as int? ?? 0,
      equipmentCount: json['equipment_count'] as int? ?? 0,
    );
  }
}

class Message {
  final int id;
  final int senderId;
  final String senderName;
  final String? senderProfilePicture;
  final int recipientId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderProfilePicture,
    required this.recipientId,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int? ?? 0,
      senderId: json['sender'] as int? ?? 0,
      senderName: json['sender_name'] as String? ?? 'Unknown',
      senderProfilePicture: json['sender_profile_picture'] as String?,
      recipientId: json['recipient'] as int? ?? 0,
      content: json['content'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_profile_picture': senderProfilePicture,
      'recipient_id': recipientId,
      'content': content,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ProjectMember {
  final int userId;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final bool isProjectAdmin;
  final DateTime joinedAt;

  const ProjectMember({
    required this.userId,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.isProjectAdmin,
    required this.joinedAt,
  });

  factory ProjectMember.fromJson(Map<String, dynamic> json) {
    return ProjectMember(
      userId: json['user_id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      firstName: (json['first_name'] as String? ?? ''),
      lastName: (json['last_name'] as String? ?? ''),
      role: (json['role'] as String? ?? 'OFFICER'),
      isProjectAdmin: json['is_project_admin'] as bool? ?? false,
      joinedAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  String get fullName => '$firstName $lastName'.trim().isNotEmpty
      ? '$firstName $lastName'.trim()
      : username;
}

class PostModel {
  final int id;
  final String authorName;
  final String authorUsername;
  final String authorRole;
  final String? authorProfilePicture;
  final String authorAssignedArea;
  final String content;
  final String status;
  final String category;
  final String severity;
  final String location;
  final String assignedArea;
  final List<String> imageUrls;
  final List<Comment> recentComments;
  final int commentsCount;
  final int projectId;
  final String projectName;
  final DateTime createdAt;
  final String? imageUrl;

  const PostModel({
    required this.id,
    required this.authorName,
    this.authorUsername = '',
    this.authorRole = 'OFFICER',
    this.authorProfilePicture,
    this.authorAssignedArea = '',
    required this.content,
    required this.status,
    required this.category,
    this.severity = 'Low',
    this.location = '',
    this.assignedArea = '',
    this.imageUrls = const [],
    this.recentComments = const [],
    this.commentsCount = 0,
    required this.projectId,
    this.projectName = '',
    required this.createdAt,
    this.imageUrl,
  });

  bool get isComplete => status == 'Complete';
  bool get isPending => status == 'Pending';

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    final status = (json['status'] ?? 'Pending').toString();
    final images = json['images'] as List<dynamic>? ?? [];
    final recentComments = (json['recent_comments'] as List<dynamic>? ?? []);
    final image = json['image'];

    String? profilePic = json['author_profile_picture'];
    String authorRole = json['author_role'] as String? ?? 'OFFICER';
    String authorArea = json['author_assigned_area'] as String? ?? '';

    if (profilePic == null && author != null) {
      final profile = author['profile'] as Map<String, dynamic>?;
      if (profile != null) {
        profilePic = profile['profile_picture'];
      }
    }

    return PostModel(
      id: json['id'] as int? ?? 0,
      authorName: author?['username'] as String? ?? 'Unknown',
      authorUsername: author?['username'] as String? ?? '',
      authorRole: authorRole,
      authorProfilePicture: profilePic,
      authorAssignedArea: authorArea,
      content: json['content'] as String? ?? '',
      status: status,
      category: json['category'] as String? ?? 'Unsafe Act',
      severity: json['severity'] as String? ?? 'Low',
      location: json['location'] as String? ?? '',
      assignedArea: json['assigned_area'] as String? ?? '',
      imageUrls: images
          .map(
            (e) => (e is Map && e['image'] != null)
                ? e['image'].toString()
                : e.toString(),
          )
          .toList(),
      recentComments: recentComments
          .map((e) => Comment.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      commentsCount: json['comments_count'] as int? ?? 0,
      projectId: json['project'] as int? ?? 0,
      projectName: json['project_name']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      imageUrl: image?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'status': status,
      'project': projectId,
      'project_name': projectName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  PostModel copyWith({
    int? id,
    String? authorName,
    String? content,
    String? status,
    String? category,
    String? severity,
    String? location,
    String? assignedArea,
    List<String>? imageUrls,
    int? commentsCount,
    DateTime? createdAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      authorUsername: authorUsername,
      authorRole: authorRole,
      authorAssignedArea: authorAssignedArea,
      content: content ?? this.content,
      status: status ?? this.status,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      location: location ?? this.location,
      assignedArea: assignedArea ?? this.assignedArea,
      imageUrls: imageUrls ?? this.imageUrls,
      recentComments: recentComments,
      commentsCount: commentsCount ?? this.commentsCount,
      projectId: projectId,
      projectName: projectName,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl,
    );
  }
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;

  const AuthTokens({required this.accessToken, required this.refreshToken});

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access'] as String,
      refreshToken: json['refresh'] as String,
    );
  }
}

class LoginResponse {
  final AppUser user;
  final AuthTokens tokens;
  final Project? project;

  const LoginResponse({required this.user, required this.tokens, this.project});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
      tokens: AuthTokens.fromJson(json['tokens'] as Map<String, dynamic>),
      project: json['project'] != null
          ? Project.fromJson(json['project'] as Map<String, dynamic>)
          : null,
    );
  }
}

// Hive Type Adapters
class AppUserAdapter extends TypeAdapter<AppUser> {
  @override
  final int typeId = 0;

  @override
  AppUser read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppUser(
      id: fields[0] as int,
      username: fields[1] as String,
      email: fields[2] as String,
      firstName: fields[3] as String,
      lastName: fields[4] as String,
      role: fields[5] as String,
      isProjectAdmin: fields[6] as bool,
      projectId: fields[7] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, AppUser obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.firstName)
      ..writeByte(4)
      ..write(obj.lastName)
      ..writeByte(5)
      ..write(obj.role)
      ..writeByte(6)
      ..write(obj.isProjectAdmin)
      ..writeByte(7)
      ..write(obj.projectId);
  }
}

class ProjectAdapter extends TypeAdapter<Project> {
  @override
  final int typeId = 1;

  @override
  Project read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Project(
      id: fields[0] as int,
      name: fields[1] as String,
      area: fields[2] as String,
      duration: fields[3] as String,
      accessCode: fields[4] as String,
      adminId: fields[5] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Project obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.area)
      ..writeByte(3)
      ..write(obj.duration)
      ..writeByte(4)
      ..write(obj.accessCode)
      ..writeByte(5)
      ..write(obj.adminId);
  }
}

class PostModelAdapter extends TypeAdapter<PostModel> {
  @override
  final int typeId = 2;

  @override
  PostModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PostModel(
      id: fields[0] as int,
      authorName: fields[1] as String,
      content: fields[2] as String,
      status: fields[3] as String? ?? 'Pending',
      category: fields[4] as String? ?? 'Unsafe Act',
      assignedArea: fields[5] as String? ?? '',
      imageUrls: (fields[6] as List<dynamic>?)?.cast<String>() ?? [],
      commentsCount: fields[7] as int? ?? 0,
      projectId: fields[8] as int,
      projectName: fields[9] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[10] as int),
    );
  }

  @override
  void write(BinaryWriter writer, PostModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.authorName)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.assignedArea)
      ..writeByte(6)
      ..write(obj.imageUrls)
      ..writeByte(7)
      ..write(obj.commentsCount)
      ..writeByte(8)
      ..write(obj.projectId)
      ..writeByte(9)
      ..write(obj.projectName)
      ..writeByte(10)
      ..write(obj.createdAt.millisecondsSinceEpoch);
  }
}

class ProjectMemberAdapter extends TypeAdapter<ProjectMember> {
  @override
  final int typeId = 3;

  @override
  ProjectMember read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectMember(
      userId: fields[0] as int,
      username: fields[1] as String,
      email: fields[2] as String,
      firstName: fields[3] as String,
      lastName: fields[4] as String,
      role: fields[5] as String,
      isProjectAdmin: fields[6] as bool,
      joinedAt: DateTime.fromMillisecondsSinceEpoch(fields[7] as int),
    );
  }

  @override
  void write(BinaryWriter writer, ProjectMember obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.firstName)
      ..writeByte(4)
      ..write(obj.lastName)
      ..writeByte(5)
      ..write(obj.role)
      ..writeByte(6)
      ..write(obj.isProjectAdmin)
      ..writeByte(7)
      ..write(obj.joinedAt.millisecondsSinceEpoch);
  }
}
