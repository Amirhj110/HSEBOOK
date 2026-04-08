from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers

from django.db import models
from .models import Post, Profile, Project, ProjectSettings, User, Comment, PostImage, Message, AreaAssignment


class ProjectSerializer(serializers.ModelSerializer):
    class Meta:
        model = Project
        fields = ['id', 'name', 'access_code', 'admin', 'created_at']
        read_only_fields = ['id', 'access_code', 'created_at']


class AdminRegistrationSerializer(serializers.ModelSerializer):
    project_name = serializers.CharField(write_only=True, max_length=255)
    project_area = serializers.CharField(write_only=True, max_length=255)
    project_duration = serializers.CharField(write_only=True, max_length=100)
    password = serializers.CharField(write_only=True, validators=[validate_password])

    class Meta:
        model = User
        fields = [
            'username', 'email', 'password', 'first_name', 'last_name',
            'project_name', 'project_area', 'project_duration'
        ]
        extra_kwargs = {
            'email': {'required': True},
            'first_name': {'required': True},
            'last_name': {'required': True},
        }

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value

    def validate_username(self, value):
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError("A user with this username already exists.")
        return value

    def create(self, validated_data):
        project_name = validated_data.pop('project_name')
        project_area = validated_data.pop('project_area')
        project_duration = validated_data.pop('project_duration')
        validated_data['role'] = User.Role.ADMIN
        validated_data['is_project_admin'] = True
        user = User.objects.create_user(**validated_data)
        project = Project.objects.create(name=project_name, admin=user)
        # Store area and duration in ProjectSettings
        ProjectSettings.objects.create(
            project=project,
            project_area=project_area,
            project_duration=project_duration,
        )
        profile, _ = Profile.objects.get_or_create(user=user)
        profile.project = project
        profile.save()
        return user


class StaffRegistrationSerializer(serializers.ModelSerializer):
    project_name = serializers.CharField(write_only=True, max_length=255)
    access_code = serializers.CharField(write_only=True, max_length=12)
    password = serializers.CharField(write_only=True, validators=[validate_password])
    role = serializers.CharField(write_only=True, required=False, allow_blank=True)

    class Meta:
        model = User
        fields = [
            'username', 'email', 'password', 'first_name', 'last_name',
            'project_name', 'access_code', 'role'
        ]
        extra_kwargs = {
            'email': {'required': True},
            'first_name': {'required': True},
            'last_name': {'required': True},
        }

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value

    def validate_username(self, value):
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError("A user with this username already exists.")
        return value

    def validate(self, attrs):
        project_name = attrs.get('project_name')
        access_code = attrs.get('access_code')
        try:
            project = Project.objects.get(name=project_name)
            if project.access_code != access_code:
                raise serializers.ValidationError({'access_code': 'Invalid access code for this project.'})
        except Project.DoesNotExist:
            raise serializers.ValidationError({'project_name': 'Project with this name does not exist.'})
        attrs['project'] = project
        return attrs

    def create(self, validated_data):
        validated_data.pop('project_name')
        validated_data.pop('access_code')
        project = validated_data.pop('project')
        selected_role = validated_data.pop('role', None)
        role_mapping = {
            'HSE OFFICER': User.Role.OFFICER,
            'HSE SUPERVISOR': User.Role.SUPERVISOR,
            'HSE MANAGER': User.Role.MANAGER,
        }
        validated_data['role'] = role_mapping.get(selected_role, User.Role.OFFICER)
        validated_data['is_project_admin'] = False
        user = User.objects.create_user(**validated_data)
        profile, _ = Profile.objects.get_or_create(user=user)
        profile.project = project
        profile.save()
        return user


class UserSummarySerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name', 'email', 'role', 'is_project_admin']


class UserProfileSerializer(serializers.ModelSerializer):
    """Serializer for user profile with explicit profile and project data."""
    profile = serializers.SerializerMethodField()
    project = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'role', 'is_project_admin', 'project', 'profile']

    def get_profile(self, obj):
        try:
            profile = obj.profile
            return {
                'id': profile.id,
                'bio': profile.bio or '',
                'profile_picture': profile.profile_picture.url if profile.profile_picture else None,
                'project_id': profile.project.id if profile.project else None,
            }
        except Profile.DoesNotExist:
            return None

    def get_project(self, obj):
        try:
            profile = obj.profile
            if profile.project:
                project = profile.project
                # Get area/duration from ProjectSettings if available
                area = ''
                duration = ''
                try:
                    settings = ProjectSettings.objects.get(project=project)
                    area = settings.project_area
                    duration = settings.project_duration
                except ProjectSettings.DoesNotExist:
                    pass
                return {
                    'id': project.id,
                    'name': project.name,
                    'access_code': project.access_code,
                    'area': area,
                    'duration': duration,
                }
        except (Profile.DoesNotExist, AttributeError):
            pass
        return None


class CommentSerializer(serializers.ModelSerializer):
    author_name = serializers.CharField(source='author.username')
    author_picture = serializers.SerializerMethodField()

    class Meta:
        model = Comment
        fields = ['id', 'author_name', 'content', 'author_picture', 'created_at']

    def get_author_picture(self, obj):
        try:
            if obj.author.profile.profile_picture:
                request = self.context.get('request')
                return request.build_absolute_uri(obj.author.profile.profile_picture.url) if request else None
        except (Profile.DoesNotExist, AttributeError):
            pass
        return None


class PostImageSerializer(serializers.ModelSerializer):
    image = serializers.SerializerMethodField()

    class Meta:
        model = PostImage
        fields = ['id', 'image']

    def get_image(self, obj):
        if obj.image:
            request = self.context.get('request')
            return request.build_absolute_uri(obj.image.url) if request else None
        return None


class PostSerializer(serializers.ModelSerializer):
    author = UserSummarySerializer(read_only=True)
    author_profile_picture = serializers.SerializerMethodField()
    author_role = serializers.CharField(source='author.role', read_only=True)
    author_assigned_area = serializers.SerializerMethodField()
    project_name = serializers.CharField(source='project.name', read_only=True)
    images = PostImageSerializer(read_only=True, many=True)
    category = serializers.CharField(required=False, default='Unsafe Act')
    severity = serializers.CharField(required=False, default='Low')
    location = serializers.CharField(required=False, allow_blank=True, default='')
    assigned_area = serializers.CharField(required=False, allow_blank=True, default='')
    status = serializers.ChoiceField(
        choices=['Pending', 'Complete'],
        required=False,
        default='Pending'
    )
    # Computed fields extracted from content
    observation = serializers.SerializerMethodField()
    description = serializers.SerializerMethodField()
    rectification = serializers.SerializerMethodField()
    comments_count = serializers.SerializerMethodField()
    recent_comments = serializers.SerializerMethodField()

    class Meta:
        model = Post
        fields = ['id', 'author', 'author_profile_picture', 'author_role', 'author_assigned_area',
                  'content', 'observation', 'description', 'rectification',
                  'category', 'severity', 'location', 'assigned_area', 'status',
                  'project', 'project_name', 'images',
                  'comments_count', 'recent_comments', 'created_at']
        read_only_fields = ['id', 'created_at', 'author', 'project', 'observation', 'description', 'rectification']

    def get_author_profile_picture(self, obj):
        try:
            if obj.author.profile.profile_picture:
                request = self.context.get('request')
                return request.build_absolute_uri(obj.author.profile.profile_picture.url) if request else None
        except Profile.DoesNotExist:
            pass
        return None

    def get_author_assigned_area(self, obj):
        try:
            return obj.author.profile.assigned_area or ''
        except Profile.DoesNotExist:
            return ''

    def get_comments_count(self, obj):
        return obj.comments.count()

    def get_recent_comments(self, obj):
        recent = obj.comments.order_by('-created_at')[:2]
        return CommentSerializer(recent, many=True, context=self.context).data

    def get_observation(self, obj):
        """Extract observation from content field."""
        content = obj.content or ''
        # Look for pattern: observation text before "\n\nDescription:"
        if '\n\nDescription:' in content:
            return content.split('\n\nDescription:')[0].strip()
        return content.strip()

    def get_description(self, obj):
        """Extract description from content field."""
        content = obj.content or ''
        if '\n\nDescription:' in content and '\n\nRectification:' in content:
            start = content.find('\n\nDescription:') + len('\n\nDescription:')
            end = content.find('\n\nRectification:')
            return content[start:end].strip()
        elif '\n\nDescription:' in content:
            return content.split('\n\nDescription:')[1].strip()
        return ''

    def get_rectification(self, obj):
        """Extract rectification from content field."""
        content = obj.content or ''
        if '\n\nRectification:' in content:
            return content.split('\n\nRectification:')[1].strip()
        return ''

    def validate_status(self, value):
        """Normalize status value to handle edge cases from frontend."""
        if isinstance(value, str):
            # Strip any accidental slashes or quotes
            value = value.strip('/"\'\\')
            # Capitalize first letter to match choices
            value = value.capitalize()
            # Map common variations
            status_map = {
                'open': 'Pending',
                'pending': 'Pending',
                'close': 'Complete',
                'closed': 'Complete',
                'complete': 'Complete',
                'done': 'Complete',
            }
            value = status_map.get(value.lower(), value)
        return value


class ProjectMemberSerializer(serializers.ModelSerializer):
    user_id = serializers.IntegerField(source='user.id')
    username = serializers.CharField(source='user.username')
    email = serializers.EmailField(source='user.email')
    first_name = serializers.CharField(source='user.first_name')
    last_name = serializers.CharField(source='user.last_name')
    role = serializers.CharField(source='user.role')
    is_project_admin = serializers.BooleanField(source='user.is_project_admin')

    class Meta:
        model = Profile
        fields = ['user_id', 'username', 'email', 'first_name', 'last_name', 'role', 'is_project_admin']


class UserManagementSerializer(serializers.ModelSerializer):
    profile_picture = serializers.SerializerMethodField()
    bio = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'role',
                  'is_project_admin', 'profile_picture', 'bio', 'date_joined']
        read_only_fields = ['id', 'date_joined']

    def get_profile_picture(self, obj):
        try:
            if obj.profile.profile_picture:
                request = self.context.get('request')
                return request.build_absolute_uri(obj.profile.profile_picture.url) if request else None
        except (Profile.DoesNotExist, AttributeError):
            pass
        return None

    def get_bio(self, obj):
        try:
            return obj.profile.bio
        except Profile.DoesNotExist:
            return ''


class UserProfileUpdateSerializer(serializers.ModelSerializer):
    profile_picture = serializers.ImageField(required=False, allow_null=True)
    bio = serializers.CharField(required=False, allow_blank=True)

    class Meta:
        model = User
        fields = ['first_name', 'last_name', 'email', 'profile_picture', 'bio']

    def update(self, instance, validated_data):
        profile_picture = validated_data.pop('profile_picture', None)
        bio = validated_data.pop('bio', None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        try:
            profile = instance.profile
            if profile_picture is not None:
                profile.profile_picture = profile_picture
            if bio is not None:
                profile.bio = bio
            profile.save()
        except Profile.DoesNotExist:
            Profile.objects.create(user=instance, profile_picture=profile_picture, bio=bio or '')
        return instance


class ProjectSettingsSerializer(serializers.ModelSerializer):
    logo = serializers.SerializerMethodField()
    access_code = serializers.CharField(source='project.access_code', read_only=True)

    class Meta:
        model = ProjectSettings
        fields = ['id', 'app_name', 'theme', 'project_area', 'project_duration',
                  'logo', 'man_hours', 'equipment_count', 'openai_api_key', 'ai_risk_trends_enabled',
                  'access_code']

    def get_logo(self, obj):
        if obj.logo:
            request = self.context.get('request')
            return request.build_absolute_uri(obj.logo.url) if request else None
        return None

    def to_representation(self, instance):
        rep = super().to_representation(instance)
        rep['project_id'] = instance.project.id
        rep['project_name'] = instance.project.name
        return rep


class RoleChangeSerializer(serializers.Serializer):
    user_id = serializers.IntegerField()
    new_role = serializers.ChoiceField(choices=['ADMIN', 'MANAGER', 'SUPERVISOR', 'OFFICER'])


class MessageSerializer(serializers.ModelSerializer):
    sender_name = serializers.CharField(source='sender.username', read_only=True)
    recipient_name = serializers.CharField(source='recipient.username', read_only=True)
    recipient_id = serializers.IntegerField(write_only=True, required=False)

    class Meta:
        model = Message
        fields = [
            'id', 'sender', 'sender_name', 'recipient', 'recipient_name',
            'recipient_id', 'content', 'is_read', 'created_at'
        ]
        extra_kwargs = {
            'sender': {'read_only': True},
            'recipient': {'read_only': True},
        }

    def create(self, validated_data):
        recipient_id = validated_data.pop('recipient_id', None)
        if recipient_id is not None:
            validated_data['recipient_id'] = recipient_id
        return super().create(validated_data)


class ConversationSerializer(serializers.ModelSerializer):
    """Summarized conversation for sidebar."""
    user_id = serializers.IntegerField(source='id')
    username = serializers.CharField(source='username')
    last_message = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()
    role = serializers.CharField()
    is_project_admin = serializers.BooleanField()

    class Meta:
        model = User
        fields = ['user_id', 'username', 'role', 'is_project_admin', 'last_message', 'unread_count']

    def get_last_message(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            msg = Message.objects.filter(
                models.Q(sender=request.user, recipient=obj) | models.Q(sender=obj, recipient=request.user)
            ).order_by('-created_at').first()
            return msg.content if msg else None
        return None

    def get_unread_count(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return Message.objects.filter(sender=obj, recipient=request.user, is_read=False).count()
        return 0


class AreaAssignmentSerializer(serializers.ModelSerializer):
    supervisor_name = serializers.CharField(source='supervisor.username')
    assigned_by_name = serializers.CharField(source='assigned_by.username', read_only=True)

    class Meta:
        model = AreaAssignment
        fields = ['id', 'supervisor', 'supervisor_name', 'area_name', 'assigned_by', 'assigned_by_name', 'is_active', 'created_at']


class AreaAssignmentCreateSerializer(serializers.Serializer):
    supervisor_id = serializers.IntegerField()
    area_name = serializers.CharField(max_length=255)


class CommentCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Comment
        fields = ['content']

    def create(self, validated_data):
        # The view will set author and post, so just return the validated data
        # The serializer's default create behavior will work
        return super().create(validated_data)