import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';

class PostState {
  final List<PostModel> posts;
  final bool isLoading;
  final bool isOffline;
  final String? error;

  const PostState({
    this.posts = const [],
    this.isLoading = false,
    this.isOffline = false,
    this.error,
  });

  PostState copyWith({
    List<PostModel>? posts,
    bool? isLoading,
    bool? isOffline,
    String? error,
  }) {
    return PostState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isOffline: isOffline ?? this.isOffline,
      error: error,
    );
  }
}

class PostNotifier extends StateNotifier<PostState> {
  PostNotifier() : super(const PostState()) {
    _init();
  }

  final api = ApiService(baseUrl: ApiService.getDefaultBaseUrl());
  static const String _postsBoxName = 'posts_cache';
  Box<dynamic>? _postsBox;
  Timer? _liveFeedTimer;
  String? _lastToken;

  Future<void> _init() async {
    await Hive.initFlutter();
    _postsBox = await Hive.openBox(_postsBoxName);
    await _checkConnectivity();
    _listenToConnectivity();
  }

  /// Start live feed polling (call after login)
  void startLiveFeed(String token) {
    _lastToken = token;
    _liveFeedTimer?.cancel();
    _liveFeedTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_lastToken != null) {
        fetchPosts(_lastToken!, silent: true);
      }
    });
  }

  /// Stop live feed polling
  void stopLiveFeed() {
    _liveFeedTimer?.cancel();
    _liveFeedTimer = null;
    _lastToken = null;
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnectivity(result);
  }

  void _listenToConnectivity() {
    Connectivity().onConnectivityChanged.listen(_updateConnectivity);
  }

  void _updateConnectivity(List<ConnectivityResult> results) {
    final isOffline = results.contains(ConnectivityResult.none);
    if (state.isOffline != isOffline) {
      state = state.copyWith(isOffline: isOffline);
      if (!isOffline && state.posts.isEmpty) {
        fetchPosts('');
      }
    }
  }

  Future<void> _cachePosts() async {
    if (_postsBox == null) return;
    final postsJson = state.posts.map((p) => p.toJson()).toList();
    await _postsBox!.put('cached_posts', postsJson);
    await _postsBox!.put('cache_time', DateTime.now().toIso8601String());
  }

  Future<void> _loadCachedPosts() async {
    if (_postsBox == null) return;
    final cached = _postsBox!.get('cached_posts');
    if (cached != null && cached is List) {
      final posts = cached
          .whereType<Map>()
          .map((p) => PostModel.fromJson(Map<String, dynamic>.from(p)))
          .toList();
      state = state.copyWith(posts: posts);
    }
  }

  Future<void> fetchPosts(String token, {bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final posts = await api.fetchPosts(token);
      state = state.copyWith(posts: posts, isLoading: false);
      await _cachePosts();
    } catch (e) {
      // If we get an error, try to load cached posts
      await _loadCachedPosts();
      if (!silent) {
        state = state.copyWith(
          isLoading: false,
          error: 'Unable to fetch posts. Showing cached data.',
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<void> createPost({
    required String token,
    required String content,
    required int projectId,
    String category = 'Unsafe Act',
    String severity = 'Medium',
    String location = '',
    List<Uint8List>? imageBytes,
    List<String>? imageNames,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final post = await api.createPost(
        token: token,
        content: content,
        projectId: projectId,
        category: category,
        severity: severity,
        location: location,
        imageBytes: imageBytes,
        imageNames: imageNames,
      );
      state = state.copyWith(posts: [post, ...state.posts], isLoading: false);
      await _cachePosts();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> deletePost(String token, int postId) async {
    await api.deletePost(token, postId);
    final updatedPosts = state.posts.where((p) => p.id != postId).toList();
    state = state.copyWith(posts: updatedPosts);
    await _cachePosts();
  }

  Future<void> togglePostStatus(int postId, {String? token}) async {
    // Find the post
    final postIndex = state.posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    final post = state.posts[postIndex];
    final newStatus = post.status == 'Pending' ? 'Complete' : 'Pending';

    // Optimistically update UI - instant color flip
    final updatedPosts = [...state.posts];
    updatedPosts[postIndex] = post.copyWith(status: newStatus);
    state = state.copyWith(posts: updatedPosts);

    // Persist to server
    if (token != null) {
      try {
        await api.updatePostStatus(token, postId, newStatus);
        await _cachePosts();
      } catch (e) {
        // Revert on error
        state = state.copyWith(posts: state.posts);
      }
    } else {
      await _cachePosts();
    }
  }

  /// Add a comment to a post locally (API call should be done before this)
  void addCommentLocally(int postId, Comment comment) {
    final postIndex = state.posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    final post = state.posts[postIndex];
    final updatedComments = [...post.recentComments, comment];
    final updatedPosts = [...state.posts];
    updatedPosts[postIndex] = PostModel(
      id: post.id,
      authorName: post.authorName,
      authorUsername: post.authorUsername,
      authorRole: post.authorRole,
      authorProfilePicture: post.authorProfilePicture,
      authorAssignedArea: post.authorAssignedArea,
      content: post.content,
      status: post.status,
      category: post.category,
      severity: post.severity,
      location: post.location,
      assignedArea: post.assignedArea,
      imageUrls: post.imageUrls,
      recentComments: updatedComments,
      commentsCount: post.commentsCount + 1,
      projectId: post.projectId,
      projectName: post.projectName,
      createdAt: post.createdAt,
      imageUrl: post.imageUrl,
    );
    state = state.copyWith(posts: updatedPosts);
  }
}

final postProvider = StateNotifierProvider<PostNotifier, PostState>(
  (ref) => PostNotifier(),
);
