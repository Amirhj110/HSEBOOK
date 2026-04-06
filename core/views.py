import json
from datetime import datetime
from django.http import HttpResponse
from typing import Any, cast

from rest_framework import generics, permissions, serializers, status
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.tokens import RefreshToken

from django.db import models
from .models import Post, Profile, Project, ProjectSettings, User, Comment, Message, AreaAssignment
from .intelligence import (
    generate_incident_report_excel, 
    generate_incident_report_pdf,
    generate_risk_trend_ai,
    generate_hip_ai
)
from .serializers import (
    AdminRegistrationSerializer,
    PostSerializer,
    ProjectMemberSerializer,
    ProjectSerializer,
    ProjectSettingsSerializer,
    RoleChangeSerializer,
    StaffRegistrationSerializer,
    UserProfileSerializer,
    UserProfileUpdateSerializer,
    UserManagementSerializer,
    CommentCreateSerializer,
    CommentSerializer,
    MessageSerializer,
    ConversationSerializer,
    AreaAssignmentSerializer,
    AreaAssignmentCreateSerializer,
)


def get_recent_comments_for_post(post, limit=2):
    comments = post.comments.order_by('-created_at')[:limit]
    return comments


def get_authenticated_user(request) -> Any:
    """Return the authenticated request user with a concrete runtime type for API use."""
    return cast(Any, request.user)


def get_user_project(user: User):
    """Return the user project, infer from admin-owned project if profile is missing."""
    try:
        if user.profile.project:
            return user.profile.project
    except Profile.DoesNotExist:
        pass

    project = Project.objects.filter(admin=user).first()
    if not project:
        project = Project.objects.filter(admin__username__iexact=user.username).first()
    if not project:
        project = Project.objects.filter(admin__email__iexact=user.email).first()

    if project:
        profile, _ = Profile.objects.get_or_create(user=user)
        if profile.project != project:
            profile.project = project
            profile.save()
    return project


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    """Custom JWT token serializer that includes additional user claims."""
    
    @classmethod
    def get_token(cls, user: Any):
        token = super().get_token(user)
        
        # Add custom claims
        token['username'] = user.username
        token['role'] = user.role
        token['is_project_admin'] = user.is_project_admin
        
        # Get project_id from profile
        try:
            profile = user.profile
            if profile.project:
                token['project_id'] = profile.project.id
                token['project_name'] = profile.project.name
        except Profile.DoesNotExist:
            pass
        
        return token


class LoginView(TokenObtainPairView):
    """Custom login view that returns tokens with custom claims."""
    serializer_class = CustomTokenObtainPairSerializer
    permission_classes = [permissions.AllowAny]


def get_tokens_for_user(user: Any):
    """Generate access and refresh tokens for a user with custom claims."""
    refresh = RefreshToken.for_user(user)
    
    # Add custom claims to the refresh token
    refresh['username'] = user.username
    refresh['role'] = user.role
    refresh['is_project_admin'] = user.is_project_admin
    
    # Get project_id from profile
    try:
        profile = user.profile
        if profile.project:
            refresh['project_id'] = profile.project.id
            refresh['project_name'] = profile.project.name
    except Profile.DoesNotExist:
        pass
    
    return {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
    }


class AdminRegistrationView(generics.CreateAPIView):
    """Admin registration endpoint.
    
    Creates a new admin user, project, and links them together.
    The admin user has access to all project features.
    """
    serializer_class = AdminRegistrationSerializer
    permission_classes = [permissions.AllowAny]
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        
        # Generate tokens for the new user
        tokens = get_tokens_for_user(user)
        
        return Response({
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'role': user.role,
                'is_project_admin': user.is_project_admin,
            },
            'tokens': tokens,
            'project': ProjectSerializer(user.profile.project).data,
            'message': 'Admin registration successful. Project created.'
        }, status=status.HTTP_201_CREATED)


class StaffRegistrationView(generics.CreateAPIView):
    """Staff registration endpoint.
    
    Requires valid project name and access code.
    Creates user and links to the project.
    """
    serializer_class = StaffRegistrationSerializer
    permission_classes = [permissions.AllowAny]
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        
        # Generate tokens for the new user
        tokens = get_tokens_for_user(user)
        
        return Response({
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'role': user.role,
                'is_project_admin': user.is_project_admin,
            },
            'tokens': tokens,
            'project': ProjectSerializer(user.profile.project).data,
            'message': 'Staff registration successful.'
        }, status=status.HTTP_201_CREATED)


class UserProfileView(generics.RetrieveUpdateAPIView):
    """Get or update current user's profile."""
    serializer_class = UserProfileSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_object(self):
        return get_authenticated_user(self.request)


class PostListCreateView(generics.ListCreateAPIView):
    """List and create posts for the authenticated user's project."""
    queryset = Post.objects.select_related('author', 'project').order_by('-created_at')
    serializer_class = PostSerializer
    parser_classes = [MultiPartParser, FormParser]
    permission_classes = [permissions.IsAuthenticated]
    
    def perform_create(self, serializer):
        user = get_authenticated_user(self.request)
        # Get project from user's profile
        try:
            profile = user.profile
            if profile.project:
                serializer.save(author=user, project=profile.project)
            else:
                raise serializers.ValidationError("User is not associated with any project.")
        except Profile.DoesNotExist:
            raise serializers.ValidationError("User profile not found.")
    
    def get_queryset(self):
        user = get_authenticated_user(self.request)
        queryset = super().get_queryset()
        
        # Admin can see all posts, others see only their project's posts
        if user.is_project_admin:
            return queryset
        else:
            try:
                project_id = user.profile.project.id
                return queryset.filter(project_id=project_id)
            except Profile.DoesNotExist:
                return queryset.none()


class ProjectCreateView(generics.CreateAPIView):
    """Create a new project (admin only)."""
    queryset = Project.objects.all()
    serializer_class = ProjectSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def perform_create(self, serializer):
        serializer.save(admin=get_authenticated_user(self.request))


class ProjectDetailView(generics.RetrieveAPIView):
    """Get current user's project details."""
    serializer_class = ProjectSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_object(self):
        user = get_authenticated_user(self.request)
        return get_user_project(user)


class ProjectMembersView(generics.ListAPIView):
    """Get all members of the current user's project.
    
    Returns list of project members with their details.
    """
    serializer_class = ProjectMemberSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        user = get_authenticated_user(self.request)
        project = get_user_project(user)
        if project:
            return Profile.objects.filter(project=project).select_related('user')
        return Profile.objects.none()


class ProjectRegenerateKeyView(APIView):
    """Regenerate access key for current user's project.
    
    Only accessible by project admins.
    """
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        user = get_authenticated_user(request)
        project = get_user_project(user)
        if not project:
            return Response({
                'error': 'You do not have an associated project.'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if not (user.is_project_admin or user.role == User.Role.ADMIN):
            return Response({
                'error': 'Only project administrators can regenerate access keys.'
            }, status=status.HTTP_403_FORBIDDEN)
        
        project.access_code = ''  # Clear to trigger new code generation
        project.save()
        
        return Response({
            'message': 'Access key regenerated successfully.',
            'access_code': project.access_code,
        }, status=status.HTTP_200_OK)


class SocialAuthCallbackView(APIView):
    """Handle social auth callback.
    
    After social login, if user is new, they need to complete registration
    by providing project_name and access_code.
    """
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        # This endpoint is for completing registration after social auth
        # The actual social auth logic would be handled by a package like django-allauth
        provider = request.data.get('provider')  # 'google' or 'facebook'
        email = request.data.get('email')
        first_name = request.data.get('first_name', '')
        last_name = request.data.get('last_name', '')
        project_name = request.data.get('project_name')
        access_code = request.data.get('access_code')
        
        if not all([provider, email, project_name, access_code]):
            return Response({
                'error': 'Missing required fields: provider, email, project_name, access_code'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if user exists
        try:
            user = User.objects.get(email=email)
            # User exists, just generate tokens
            is_new_user = False
        except User.DoesNotExist:
            # New user - validate project and create
            try:
                project = Project.objects.get(name=project_name)
                if project.access_code != access_code:
                    return Response({
                        'error': 'Invalid access code for this project.'
                    }, status=status.HTTP_400_BAD_REQUEST)
                
                # Create new user
                username = email.split('@')[0]
                # Ensure unique username
                base_username = username
                counter = 1
                while User.objects.filter(username=username).exists():
                    username = f"{base_username}_{counter}"
                    counter += 1
                
                user = User.objects.create_user(
                    username=username,
                    email=email,
                    first_name=first_name,
                    last_name=last_name,
                    role='OFFICER',
                    is_project_admin=False
                )
                Profile.objects.create(user=user, project=project)
                is_new_user = True
                
            except Project.DoesNotExist:
                return Response({
                    'error': 'Project with this name does not exist.'
                }, status=status.HTTP_400_BAD_REQUEST)
        
        user = cast(Any, user)
        tokens = get_tokens_for_user(user)
        
        return Response({
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'role': user.role,
                'is_project_admin': user.is_project_admin,
            },
            'tokens': tokens,
            'is_new_user': is_new_user,
            'project': ProjectSerializer(user.profile.project).data if user.profile.project else None,
        })


# ==================== Admin User Management Views ====================

class UserManagementView(APIView):
    """List all users in the project and handle admin operations."""
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        """List all users in the same project as the requesting user."""
        user = get_authenticated_user(request)
        if not user.is_project_admin:
            return Response({'error': 'Only admins can view user management'}, status=status.HTTP_403_FORBIDDEN)
        
        try:
            project = user.profile.project
            if not project:
                return Response({'error': 'No project associated'}, status=status.HTTP_400_BAD_REQUEST)
            
            users = User.objects.filter(profile__project=project)
            serializer = UserManagementSerializer(users, many=True, context={'request': request})
            return Response(serializer.data)
        except Profile.DoesNotExist:
            return Response({'error': 'User profile not found'}, status=status.HTTP_400_BAD_REQUEST)


class UserRoleChangeView(APIView):
    """Change the role of a user."""
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        user = get_authenticated_user(request)
        if not user.is_project_admin:
            return Response({'error': 'Only admins can change roles'}, status=status.HTTP_403_FORBIDDEN)
        
        serializer = RoleChangeSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        try:
            target_user = User.objects.get(id=serializer.validated_data['user_id'])
            if target_user.profile.project != user.profile.project:
                return Response({'error': 'User is not in your project'}, status=status.HTTP_400_BAD_REQUEST)
            
            if target_user.is_project_admin and not user.is_project_admin:
                return Response({'error': 'Cannot change admin role'}, status=status.HTTP_403_FORBIDDEN)
            
            target_user.role = serializer.validated_data['new_role']
            target_user.save()
            
            return Response({
                'message': f'Role updated to {serializer.validated_data["new_role"]}',
                'user_id': target_user.id,
                'new_role': target_user.role,
            })
        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)


# ==================== Post Moderation Views ====================

class PostStatusUpdateView(APIView):
    """Update post status (Pending/Complete). Supervisors, Managers, and Admins can update."""
    permission_classes = [permissions.IsAuthenticated]
    
    def patch(self, request, post_id):
        user = get_authenticated_user(request)
        
        try:
            post = Post.objects.get(id=post_id)
            
            # Check permissions: Supervisor/Manager/Admin can update status
            can_update = (
                user.is_project_admin or
                user.role in [User.Role.ADMIN, User.Role.MANAGER, User.Role.SUPERVISOR] or
                post.author == user
            )
            
            if not can_update:
                return Response({'error': 'You do not have permission to update this post'}, status=status.HTTP_403_FORBIDDEN)
            
            new_status = request.data.get('status')
            if new_status not in [Post.Status.PENDING, Post.Status.COMPLETE]:
                return Response({'error': 'Invalid status. Use Pending or Complete.'}, status=status.HTTP_400_BAD_REQUEST)
            
            post.status = new_status
            post.save()
            
            serializer = PostSerializer(post, context={'request': request})
            return Response(serializer.data)
            
        except Post.DoesNotExist:
            return Response({'error': 'Post not found'}, status=status.HTTP_404_NOT_FOUND)


class PostDeleteView(APIView):
    """Delete a post. Only admins and managers can delete any post."""
    permission_classes = [permissions.IsAuthenticated]
    
    def delete(self, request, post_id):
        user = get_authenticated_user(request)
        
        try:
            post = Post.objects.get(id=post_id)
            
            # Check permissions: Admin/Manager can delete any post, others only their own
            can_delete = (
                user.is_project_admin or
                user.role in [User.Role.ADMIN, User.Role.MANAGER] or
                post.author == user
            )
            
            if not can_delete:
                return Response({'error': 'You do not have permission to delete this post'}, status=status.HTTP_403_FORBIDDEN)
            
            post.delete()
            return Response({'message': 'Post deleted successfully'})
            
        except Post.DoesNotExist:
            return Response({'error': 'Post not found'}, status=status.HTTP_404_NOT_FOUND)


# ==================== Profile Views ====================

class CommentListView(generics.ListAPIView):
    """Get all comments for a post."""
    serializer_class = CommentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        post_id = self.kwargs['post_id']
        return Comment.objects.filter(post_id=post_id).order_by('-created_at')


class CommentCreateView(generics.CreateAPIView):
    """Create a comment on a post."""
    serializer_class = CommentCreateSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        post_id = self.kwargs['post_id']
        post = Post.objects.get(id=post_id)
        serializer.save(author=self.request.user, post=post)


class UserProfileUpdateView(generics.UpdateAPIView):
    """Update user profile with image, bio, name."""
    serializer_class = UserProfileUpdateSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]
    
    def get_object(self):
        return get_authenticated_user(self.request)


# ==================== Project Settings Views ====================

class ProjectSettingsView(APIView):
    """Get and update project settings."""
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        """Get project settings."""
        user = get_authenticated_user(request)
        project = get_user_project(user)
        if not project:
            return Response({'error': 'No project associated'}, status=status.HTTP_400_BAD_REQUEST)
        
        settings, created = ProjectSettings.objects.get_or_create(project=project)
        serializer = ProjectSettingsSerializer(settings, context={'request': request})
        return Response(serializer.data)
    
    def post(self, request):
        """Update project settings."""
        user = get_authenticated_user(request)
        project = get_user_project(user)
        if not project:
            return Response({'error': 'No project associated'}, status=status.HTTP_400_BAD_REQUEST)
        
        if not (user.is_project_admin or user.role == User.Role.ADMIN):
            return Response({'error': 'Only admins can change settings'}, status=status.HTTP_403_FORBIDDEN)
        
        settings, _ = ProjectSettings.objects.get_or_create(project=project)
        
        # Update fields
        if 'app_name' in request.data:
            settings.app_name = request.data['app_name']
        if 'theme' in request.data:
            settings.theme = request.data['theme']
        if 'project_area' in request.data:
            settings.project_area = request.data['project_area']
        if 'project_duration' in request.data:
            settings.project_duration = request.data['project_duration']
        if 'man_hours' in request.data:
            try:
                settings.man_hours = int(request.data['man_hours'])
            except (ValueError, TypeError):
                return Response({'error': 'man_hours must be an integer.'}, status=status.HTTP_400_BAD_REQUEST)
        if 'equipment_count' in request.data:
            try:
                settings.equipment_count = int(request.data['equipment_count'])
            except (ValueError, TypeError):
                return Response({'error': 'equipment_count must be an integer.'}, status=status.HTTP_400_BAD_REQUEST)
        if 'logo' in request.FILES:
            settings.logo = request.FILES['logo']
        
        settings.save()
        
        serializer = ProjectSettingsSerializer(settings, context={'request': request})
        return Response(serializer.data)


class ProjectColorsUpdateView(APIView):
    """Update project theme colors."""
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        user = get_authenticated_user(request)
        project = get_user_project(user)
        if not project:
            return Response({'error': 'No project associated'}, status=status.HTTP_400_BAD_REQUEST)
        
        if not (user.is_project_admin or user.role == User.Role.ADMIN):
            return Response({'error': 'Only admins can change colors'}, status=status.HTTP_403_FORBIDDEN)
        
        settings, _ = ProjectSettings.objects.get_or_create(project=project)
        
        # Update theme colors if provided
        primary_color = request.data.get('primary_color')
        secondary_color = request.data.get('secondary_color')
        
        if primary_color or secondary_color:
            # Store colors in theme field as JSON
            import json
            theme_data = {}
            if settings.theme and settings.theme != 'hse_red':
                try:
                    theme_data = json.loads(settings.theme)
                except json.JSONDecodeError:
                    theme_data = {}
            
            if primary_color:
                theme_data['primary_color'] = primary_color
            if secondary_color:
                theme_data['secondary_color'] = secondary_color
            
            settings.theme = json.dumps(theme_data)
            settings.save()
        
        return Response({
            'message': 'Colors updated successfully',
            'primary_color': primary_color,
            'secondary_color': secondary_color,
        })


# ==================== Messaging Views ====================

class MessageListView(APIView):
    """Get messages between current user and another user."""
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        user = get_authenticated_user(request)
        other_user_id = request.query_params.get('user_id') or request.query_params.get('recipient_id')
        if not other_user_id:
            return Response({'error': 'user_id or recipient_id is required'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            other_user = User.objects.get(id=other_user_id)
        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

        user_project = get_user_project(user)
        other_user_project = get_user_project(other_user)

        if not user_project or not other_user_project:
            return Response({'error': 'User profile not found'}, status=status.HTTP_400_BAD_REQUEST)

        if user_project != other_user_project:
            return Response(
                {'error': 'Messages are only allowed between users in the same project.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        messages = Message.objects.filter(
            models.Q(sender=user, recipient=other_user) |
            models.Q(sender=other_user, recipient=user)
        ).order_by('created_at')

        # Mark received messages as read
        Message.objects.filter(sender=other_user, recipient=user, is_read=False).update(is_read=True)

        serializer = MessageSerializer(messages, many=True)
        return Response(serializer.data)


class MessageCreateView(generics.CreateAPIView):
    """Send a message to another user."""
    serializer_class = MessageSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def perform_create(self, serializer):
        recipient_id = self.request.data.get('recipient_id')
        if not recipient_id:
            raise serializers.ValidationError({'recipient_id': 'This field is required.'})

        try:
            recipient = User.objects.get(id=recipient_id)
        except User.DoesNotExist:
            raise serializers.ValidationError({'recipient_id': 'Invalid user.'})

        if recipient == self.request.user:
            raise serializers.ValidationError({'recipient_id': 'Cannot send a message to yourself.'})

        sender_project = get_user_project(self.request.user)
        recipient_project = get_user_project(recipient)

        if not sender_project or not recipient_project:
            raise serializers.ValidationError('User profile not found.')

        if sender_project != recipient_project:
            raise serializers.ValidationError('Messages are only allowed between users in the same project.')

        serializer.save(sender=self.request.user, recipient=recipient)


class ConversationListView(APIView):
    """Get list of conversations for the current user."""
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        user = get_authenticated_user(request)
        project = get_user_project(user)
        if not project:
            return Response({'error': 'No project associated'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Get all other users in the project
        other_users = User.objects.filter(profile__project=project).exclude(id=user.id)
        serializer = ConversationSerializer(other_users, many=True, context={'request': request})
        return Response(serializer.data)


class UnreadMessageCountView(APIView):
    """Get count of unread messages for the current user."""
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        user = get_authenticated_user(request)
        project = get_user_project(user)
        if not project:
            return Response({'error': 'No project associated'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Count unread messages from other project members
        unread_count = Message.objects.filter(
            recipient=user,
            is_read=False,
            sender__profile__project=project
        ).count()
        
        return Response({'unread_count': unread_count})


# ==================== Safety Intelligence Views ====================

class IncidentReportExportView(APIView):
    """Export incident reports as Excel or PDF."""
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request, format_type=None):
        user = get_authenticated_user(request)
        try:
            project = user.profile.project
            if not project:
                return Response({'error': 'No project associated'}, status=status.HTTP_400_BAD_REQUEST)
            
            # Get month filter from request
            month = request.data.get('month', None)  # e.g., "2024-01"
            posts = Post.objects.filter(project=project).select_related('author').order_by('-created_at')
            
            if month:
                year, m = map(int, month.split('-'))
                posts = posts.filter(created_at__year=year, created_at__month=m)
            
            if format_type == 'excel':
                output = generate_incident_report_excel(posts, project.name, month)
                response = HttpResponse(output.read(), content_type='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
                response['Content-Disposition'] = f'attachment; filename="incident_report_{month or "all"}.xlsx"'
                return response
            elif format_type == 'pdf':
                output = generate_incident_report_pdf(posts, project.name, month)
                response = HttpResponse(output.read(), content_type='application/pdf')
                response['Content-Disposition'] = f'attachment; filename="incident_report_{month or "all"}.pdf"'
                return response
            else:
                return Response({'error': 'Invalid format. Use excel or pdf.'}, status=status.HTTP_400_BAD_REQUEST)
                
        except Profile.DoesNotExist:
            return Response({'error': 'User profile not found'}, status=status.HTTP_400_BAD_REQUEST)


class RiskTrendAnalysisView(APIView):
    """Get AI-powered risk trend predictions."""
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        user = get_authenticated_user(request)
        try:
            project = user.profile.project
            if not project:
                return Response({'error': 'No project associated'}, status=status.HTTP_400_BAD_REQUEST)
            
            settings_obj, _ = ProjectSettings.objects.get_or_create(project=project)
            if not settings_obj.ai_risk_trends_enabled:
                return Response({'error': 'AI risk trends are disabled'}, status=status.HTTP_403_FORBIDDEN)
            
            posts = Post.objects.filter(project=project).order_by('-created_at')[:20]
            result = generate_risk_trend_ai(posts, project.name, settings_obj.openai_api_key)
            
            return Response(result)
        except Profile.DoesNotExist:
            return Response({'error': 'User profile not found'}, status=status.HTTP_400_BAD_REQUEST)


class HIPGeneratorView(APIView):
    """Generate Hazard Identification Plan using AI."""
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        user = get_authenticated_user(request)
        task_name = request.data.get('task_name')
        if not task_name:
            return Response({'error': 'task_name is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            project = user.profile.project
            if not project:
                return Response({'error': 'No project associated'}, status=status.HTTP_400_BAD_REQUEST)
            
            settings_obj, _ = ProjectSettings.objects.get_or_create(project=project)
            result = generate_hip_ai(task_name, settings_obj.openai_api_key)
            
            return Response(result)
        except Profile.DoesNotExist:
            return Response({'error': 'User profile not found'}, status=status.HTTP_400_BAD_REQUEST)


class ProjectStatsView(APIView):
    """Get project statistics for the home page ticker."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = get_authenticated_user(request)
        try:
            project = user.profile.project
            if not project:
                return Response({'error': 'No project associated'}, status=status.HTTP_400_BAD_REQUEST)

            settings_obj, _ = ProjectSettings.objects.get_or_create(project=project)
            total_posts = Post.objects.filter(project=project).count()

            return Response({
                'project_name': project.name,
                'project_area': settings_obj.project_area or 'N/A',
                'project_duration': settings_obj.project_duration or 'N/A',
                'man_hours': settings_obj.man_hours,
                'total_observations': total_posts,
                'equipment_count': settings_obj.equipment_count,
                'pending_observations': Post.objects.filter(project=project, status=Post.Status.PENDING).count(),
                'complete_observations': Post.objects.filter(project=project, status=Post.Status.COMPLETE).count(),
            })
        except Profile.DoesNotExist:
            return Response({'error': 'User profile not found'}, status=status.HTTP_400_BAD_REQUEST)
