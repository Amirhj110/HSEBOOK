from django.urls import path

from .views import (
    AdminRegistrationView,
    CommentCreateView,
    CommentListView,
    ConversationListView,
    HIPGeneratorView,
    IncidentReportExportView,
    LoginView,
    MessageCreateView,
    MessageListView,
    PostDeleteView,
    PostListCreateView,
    PostStatusUpdateView,
    ProjectCreateView,
    ProjectDetailView,
    ProjectMembersView,
    ProjectRegenerateKeyView,
    ProjectSettingsView,
    ProjectStatsView,
    RiskTrendAnalysisView,
    SocialAuthCallbackView,
    StaffRegistrationView,
    UnreadMessageCountView,
    UserManagementView,
    UserProfileUpdateView,
    UserProfileView,
    UserRoleChangeView,
)

urlpatterns = [
    # Authentication
    path('login/', LoginView.as_view(), name='api-login'),
    
    # Registration
    path('register/admin/', AdminRegistrationView.as_view(), name='admin-register'),
    path('register/staff/', StaffRegistrationView.as_view(), name='staff-register'),
    path('auth/social/', SocialAuthCallbackView.as_view(), name='social-auth'),
    
    # User Profile
    path('user/profile/', UserProfileView.as_view(), name='user-profile'),
    path('user/profile/update/', UserProfileUpdateView.as_view(), name='user-profile-update'),
    
    # Admin User Management
    path('admin/users/', UserManagementView.as_view(), name='admin-users'),
    path('admin/change-role/', UserRoleChangeView.as_view(), name='admin-change-role'),
    
    # Posts
    path('posts/', PostListCreateView.as_view(), name='posts-list-create'),
    path('posts/<int:post_id>/delete/', PostDeleteView.as_view(), name='post-delete'),
    path('posts/<int:post_id>/status/', PostStatusUpdateView.as_view(), name='post-status-update'),
    path('posts/<int:post_id>/comments/', CommentListView.as_view(), name='post-comments-list'),
    path('posts/<int:post_id>/comments/create/', CommentCreateView.as_view(), name='post-comments-create'),
    
    # Messages
    path('messages/', MessageListView.as_view(), name='messages-list'),
    path('messages/send/', MessageCreateView.as_view(), name='messages-send'),
    path('messages/conversations/', ConversationListView.as_view(), name='messages-conversations'),
    path('messages/unread-count/', UnreadMessageCountView.as_view(), name='messages-unread-count'),
    
    # Projects
    path('projects/create/', ProjectCreateView.as_view(), name='project-create'),
    path('project/', ProjectDetailView.as_view(), name='project-detail'),
    path('project/members/', ProjectMembersView.as_view(), name='project-members'),
    path('project/regenerate-key/', ProjectRegenerateKeyView.as_view(), name='project-regenerate-key'),
    path('project/settings/', ProjectSettingsView.as_view(), name='project-settings'),
    
    # Safety Intelligence
    path('project/stats/', ProjectStatsView.as_view(), name='project-stats'),
    path('intelligence/export/<str:format_type>/', IncidentReportExportView.as_view(), name='incident-export'),
    path('intelligence/risk-trends/', RiskTrendAnalysisView.as_view(), name='risk-trends'),
    path('intelligence/hip-generator/', HIPGeneratorView.as_view(), name='hip-generator'),
]