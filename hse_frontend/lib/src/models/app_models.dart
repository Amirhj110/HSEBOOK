import 'package:hive/hive.dart';

enum UserRole { admin, manager, supervisor, officer }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin: return 'Admin';
      case UserRole.manager: return 'Manager';
      case UserRole.supervisor: return 'Supervisor';
      case UserRole.officer: return 'Officer';
    }
  }

  String get apiValue {
    switch (this) {
      case UserRole.admin: return 'ADMIN';
      case UserRole.manager: return 'MANAGER';
      case UserRole.supervisor: return 'SUPERVISOR';
      case UserRole.officer: return 'OFFICER';
    }
  }

  static UserRole fromString(String value) {
    final upper = value.toUpperCase();
    switch (upper) {
      case 'ADMIN': return UserRole.admin;
      case 'MANAGER': return UserRole.manager;
      case 'SUPERVISOR': return UserRole.supervisor;
      default: return UserRole.officer;
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
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_name': authorName,
      'content': content,
      'author_picture': authorPicture,
      'created_at': createdAt.toIso8601String(),
    };
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
    assignedArea = assignedArea.isNotEmpty ? assignedArea : json['assigned_area'] as String? ?? '';
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
  final String? accessCode;

  const ProjectSettings({
    required this.id,
    required this.appName,
    required this.theme,
    this.logoUrl,
    this.projectArea = '',
    this.projectDuration = '',
    this.manHours = 0,
    this.equipmentCount = 0,
    this.accessCode,
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
      accessCode: json['access_code'] as String?,
    );
  }

  ProjectSettings copyWith({
    int? id,
    String? appName,
    String? theme,
    String? logoUrl,
    String? projectArea,
    String? projectDuration,
    int? manHours,
    int? equipmentCount,
    String? accessCode,
  }) {
    return ProjectSettings(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      theme: theme ?? this.theme,
      logoUrl: logoUrl ?? this.logoUrl,
      projectArea: projectArea ?? this.projectArea,
      projectDuration: projectDuration ?? this.projectDuration,
      manHours: manHours ?? this.manHours,
      equipmentCount: equipmentCount ?? this.equipmentCount,
      accessCode: accessCode ?? this.accessCode,
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
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
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
  final String assignedArea;

  const ProjectMember({
    required this.userId,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.isProjectAdmin,
    required this.joinedAt,
    this.assignedArea = '',
  });

  factory ProjectMember.fromJson(Map<String, dynamic> json) {
    return ProjectMember(
      userId: json['user_id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      role: json['role'] as String? ?? 'OFFICER',
      isProjectAdmin: json['is_project_admin'] as bool? ?? false,
      assignedArea: json['assigned_area'] as String? ?? '',
      joinedAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  String get fullName => '$firstName $lastName'.trim().isNotEmpty ? '$firstName $lastName'.trim() : username;
}

class PostModel {
  final int id;
  final String authorName;
  final String authorUsername;
  final String authorRole;
  final String? authorProfilePicture;
  final String authorAssignedArea;
  final String observation;
  final String description;
  final String rectification;
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
  final String postType;
  final String incidentType;

  const PostModel({
    required this.id,
    required this.authorName,
    required this.authorUsername,
    required this.authorRole,
    this.authorProfilePicture,
    required this.authorAssignedArea,
    required this.observation,
    required this.description,
    required this.rectification,
    required this.status,
    required this.category,
    required this.severity,
    required this.location,
    required this.assignedArea,
    required this.imageUrls,
    required this.recentComments,
    required this.commentsCount,
    required this.projectId,
    required this.projectName,
    required this.createdAt,
    required this.postType,
    required this.incidentType,
  });

  bool get isComplete =>
      status.toLowerCase() == 'complete' ||
      status.toLowerCase() == 'closed' ||
      status.toLowerCase() == 'approved';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_name': authorName,
      'author_username': authorUsername,
      'author_role': authorRole,
      'author_profile_picture': authorProfilePicture,
      'author_assigned_area': authorAssignedArea,
      'observation': observation,
      'description': description,
      'rectification': rectification,
      'status': status,
      'category': category,
      'severity': severity,
      'location': location,
      'assigned_area': assignedArea,
      'images_urls': imageUrls,
      'recent_comments': recentComments.map((c) => c.toJson()).toList(),
      'comments_count': commentsCount,
      'project_id': projectId,
      'project_name': projectName,
      'created_at': createdAt.toIso8601String(),
      'post_type': postType,
      'incident_type': incidentType,
      'observation_text': observationText,
      'description': description,
      'rectification': rectification,
    };
  }

  PostModel copyWith({
    int? id,
    String? authorName,
    String? authorUsername,
    String? authorRole,
    String? authorProfilePicture,
    String? authorAssignedArea,
    String? observation,
    String? description,
    String? rectification,
    String? status,
    String? category,
    String? severity,
    String? location,
    String? assignedArea,
    List<String>? imageUrls,
    List<Comment>? recentComments,
    int? commentsCount,
    int? projectId,
    String? projectName,
    DateTime? createdAt,
    String? postType,
    String? incidentType,
  }) {
    return PostModel(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      authorUsername: authorUsername ?? this.authorUsername,
      authorRole: authorRole ?? this.authorRole,
      authorProfilePicture: authorProfilePicture ?? this.authorProfilePicture,
      authorAssignedArea: authorAssignedArea ?? this.authorAssignedArea,
      observation: observation ?? this.observation,
      description: description ?? this.description,
      rectification: rectification ?? this.rectification,
      status: status ?? this.status,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      location: location ?? this.location,
      assignedArea: assignedArea ?? this.assignedArea,
      imageUrls: imageUrls ?? this.imageUrls,
      recentComments: recentComments ?? this.recentComments,
      commentsCount: commentsCount ?? this.commentsCount,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      createdAt: createdAt ?? this.createdAt,
      postType: postType ?? this.postType,
      incidentType: incidentType ?? this.incidentType,
    );
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as int? ?? 0,
      authorName: json['author_name'] as String? ?? '',
      authorUsername: json['author_username'] as String? ?? '',
      authorRole: json['author_role'] as String? ?? 'OFFICER',
      authorProfilePicture: json['author_profile_picture'] as String?,
      authorAssignedArea: json['author_assigned_area'] as String? ?? '',
      observation: json['observation'] as String? ?? '',
      description: json['description'] as String? ?? '',
      rectification: json['rectification'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
      category: json['category'] as String? ?? 'Unsafe Act',
      severity: json['severity'] as String? ?? 'Low',
      location: json['location'] as String? ?? '',
      assignedArea: json['assigned_area'] as String? ?? '',
      imageUrls: (json['images_urls'] as List<dynamic>?)?.cast<String>() ?? [],
      recentComments: (json['recent_comments'] as List<dynamic>?)?.map((e) => Comment.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      commentsCount: json['comments_count'] as int? ?? 0,
      projectId: json['project_id'] as int? ?? (json['project'] is int ? json['project'] as int : 0),
      projectName: json['project_name'] as String? ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      postType: json['post_type'] as String? ?? 'Observation',
      incidentType: json['incident_type'] as String? ?? 'Near Miss',
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
      project: json['project'] != null ? Project.fromJson(json['project'] as Map<String, dynamic>) : null,
    );
  }
}

// Hive Type Adapters
class AppUserAdapter extends TypeAdapter<AppUser> {
  @override final int typeId = 0;
  @override
  AppUser read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{ for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read() };
    return AppUser(
      id: fields[0] as int, username: fields[1] as String, email: fields[2] as String, firstName: fields[3] as String, lastName: fields[4] as String, role: fields[5] as String, isProjectAdmin: fields[6] as bool, projectId: fields[7] as int?,
    );
  }
  @override
  void write(BinaryWriter writer, AppUser obj) {
    writer..writeByte(8)..writeByte(0)..write(obj.id)..writeByte(1)..write(obj.username)..writeByte(2)..write(obj.email)..writeByte(3)..write(obj.firstName)..writeByte(4)..write(obj.lastName)..writeByte(5)..write(obj.role)..writeByte(6)..write(obj.isProjectAdmin)..writeByte(7)..write(obj.projectId);
  }
}

class ProjectAdapter extends TypeAdapter<Project> {
  @override final int typeId = 1;
  @override
  Project read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{ for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read() };
    return Project(
      id: fields[0] as int, name: fields[1] as String, area: fields[2] as String, duration: fields[3] as String, accessCode: fields[4] as String, adminId: fields[5] as int?,
    );
  }
  @override
  void write(BinaryWriter writer, Project obj) {
    writer..writeByte(6)..writeByte(0)..write(obj.id)..writeByte(1)..write(obj.name)..writeByte(2)..write(obj.area)..writeByte(3)..write(obj.duration)..writeByte(4)..write(obj.accessCode)..writeByte(5)..write(obj.adminId);
  }
}

class PostModelAdapter extends TypeAdapter<PostModel> {
  @override final int typeId = 2;
  @override
  PostModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{ for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read() };
    return PostModel(
      id: fields[0] as int, authorName: fields[1] as String, authorUsername: fields[2] as String? ?? '', authorRole: fields[3] as String? ?? '', authorAssignedArea: fields[4] as String? ?? '', content: fields[5] as String, status: fields[6] as String? ?? 'Pending', category: fields[7] as String? ?? 'Unsafe Act', severity: fields[8] as String? ?? 'Low', location: fields[9] as String? ?? '', assignedArea: fields[10] as String? ?? '', imageUrls: (fields[11] as List<dynamic>?)?.cast<String>() ?? [], recentComments: (fields[12] as List<dynamic>?)?.map((e) => Comment.fromJson(e as Map<String, dynamic>)).toList() ?? [], commentsCount: fields[13] as int? ?? 0, projectId: fields[14] as int, projectName: fields[15] as String, createdAt: DateTime.fromMillisecondsSinceEpoch(fields[16] as int), postType: fields[17] as String? ?? 'Observation', incidentType: fields[18] as String? ?? 'Near Miss', observationText: fields[19] as String? ?? '', description: fields[20] as String? ?? '', rectification: fields[21] as String? ?? '',
    );
  }
  @override
  void write(BinaryWriter writer, PostModel obj) {
    writer..writeByte(22)
      ..writeByte(0)..write(obj.id)..writeByte(1)..write(obj.authorName)..writeByte(2)..write(obj.authorUsername)..writeByte(3)..write(obj.authorRole)..writeByte(4)..write(obj.authorAssignedArea)..writeByte(5)..write(obj.content)..writeByte(6)..write(obj.status)..writeByte(7)..write(obj.category)..writeByte(8)..write(obj.severity)..writeByte(9)..write(obj.location)..writeByte(10)..write(obj.assignedArea)..writeByte(11)..write(obj.imageUrls)..writeByte(12)..write(obj.recentComments)..writeByte(13)..write(obj.commentsCount)..writeByte(14)..write(obj.projectId)..writeByte(15)..write(obj.projectName)..writeByte(16)..write(obj.createdAt.millisecondsSinceEpoch)..writeByte(17)..write(obj.postType)..writeByte(18)..write(obj.incidentType)..writeByte(19)..write(obj.observationText)..writeByte(20)..write(obj.description)..writeByte(21)..write(obj.rectification);
  }
}

class ProjectMemberAdapter extends TypeAdapter<ProjectMember> {
  @override final int typeId = 3;
  @override
  ProjectMember read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{ for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read() };
    return ProjectMember(
      userId: fields[0] as int, username: fields[1] as String, email: fields[2] as String, firstName: fields[3] as String, lastName: fields[4] as String, role: fields[5] as String, isProjectAdmin: fields[6] as bool, joinedAt: DateTime.fromMillisecondsSinceEpoch(fields[7] as int), assignedArea: fields[8] as String? ?? '',
    );
  }
  @override
  void write(BinaryWriter writer, ProjectMember obj) {
    writer..writeByte(9)..writeByte(0)..write(obj.userId)..writeByte(1)..write(obj.username)..writeByte(2)..write(obj.email)..writeByte(3)..write(obj.firstName)..writeByte(4)..write(obj.lastName)..writeByte(5)..write(obj.role)..writeByte(6)..write(obj.isProjectAdmin)..writeByte(7)..write(obj.joinedAt.millisecondsSinceEpoch)..writeByte(8)..write(obj.assignedArea);
  }
}
