import secrets
import string

from django.contrib.auth.models import AbstractUser, UserManager
from django.db import models
from django.db.models.signals import post_save
from django.dispatch import receiver


class CustomUserManager(UserManager):
    """Custom manager for User model."""
    
    def create_user(self, username, email, password=None, **extra_fields):
        if not email:
            raise ValueError('Users must have an email address')
        email = self.normalize_email(email)
        user = self.model(username=username, email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user


class Project(models.Model):
    name = models.CharField(max_length=255)
    access_code = models.CharField(max_length=12, unique=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    # Admin who created this project
    admin = models.ForeignKey('User', on_delete=models.SET_NULL, null=True, related_name='created_projects', blank=True)

    def _generate_unique_access_code(self, length=8):
        alphabet = string.ascii_uppercase + string.digits
        while True:
            code = ''.join(secrets.choice(alphabet) for _ in range(length))
            if not Project.objects.filter(access_code=code).exists():
                return code

    def save(self, *args, **kwargs):
        if not self.access_code:
            self.access_code = self._generate_unique_access_code()
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.name} ({self.access_code})"


class User(AbstractUser):
    """
    Extended User model with role and project admin flag.
    """
    class Role(models.TextChoices):
        ADMIN = 'ADMIN', 'Admin'
        MANAGER = 'MANAGER', 'Manager'
        SUPERVISOR = 'SUPERVISOR', 'Supervisor'
        OFFICER = 'OFFICER', 'Officer'

    role = models.CharField(
        max_length=20,
        choices=Role.choices,
        default=Role.OFFICER
    )
    is_project_admin = models.BooleanField(default=False)
    
    objects = CustomUserManager()

    def __str__(self):
        return f"{self.username} ({self.role})"


class Profile(models.Model):
    """
    Profile model linking users to projects with specific roles.
    """
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='profiles', null=True, blank=True)
    profile_picture = models.ImageField(upload_to='profile_pics/', blank=True, null=True)
    bio = models.TextField(blank=True, default='')
    assigned_area = models.CharField(max_length=255, blank=True, default='')

    def __str__(self):
        return f"{self.user.username} Profile"


@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        Profile.objects.get_or_create(user=instance)


@receiver(post_save, sender=User)
def save_user_profile(sender, instance, **kwargs):
    try:
        instance.profile.save()
    except Exception:
        pass


class Post(models.Model):
    class Status(models.TextChoices):
        PENDING = 'Pending', 'Pending'
        COMPLETE = 'Complete', 'Complete'

    class Category(models.TextChoices):
        UNSAFE_ACT = 'Unsafe Act', 'Unsafe Act'
        UNSAFE_CONDITION = 'Unsafe Condition', 'Unsafe Condition'
        SAFE_ACT = 'Safe Act', 'Safe Act'

    class Severity(models.TextChoices):
        LOW = 'Low', 'Low'
        MEDIUM = 'Medium', 'Medium'
        HIGH = 'High', 'High'

    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='posts')
    observation = models.TextField()
    description = models.TextField(blank=True, default='')
    rectification = models.TextField(blank=True, default='')
    category = models.CharField(max_length=20, choices=Category.choices, default=Category.UNSAFE_ACT)
    severity = models.CharField(max_length=10, choices=Severity.choices, default=Severity.LOW)
    location = models.CharField(max_length=255, blank=True, default='')
    assigned_area = models.CharField(max_length=255, blank=True, default='')
    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='posts')
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.PENDING)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Post #{self.pk} by {self.author.username} [{self.category}]"


class PostImage(models.Model):
    """Additional images for a post."""
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='images')
    image = models.ImageField(upload_to='posts/')
    created_at = models.DateTimeField(auto_now_add=True)


class Comment(models.Model):
    """Comments on posts."""
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='comments')
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='comments')
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']


class AreaAssignment(models.Model):
    """Assignment of supervisors to specific project areas."""
    supervisor = models.ForeignKey(User, on_delete=models.CASCADE, related_name='area_assignments')
    area_name = models.CharField(max_length=255)
    assigned_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='assignments_made')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"{self.supervisor.username} → {self.area_name}"


class Message(models.Model):
    """1-to-1 messages between users."""
    sender = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sent_messages')
    recipient = models.ForeignKey(User, on_delete=models.CASCADE, related_name='received_messages')
    content = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['created_at']
    
    def __str__(self):
        return f"From {self.sender.username} to {self.recipient.username}"


class ProjectSettings(models.Model):
    """
    App settings model allowing admin to customize logo, name, theme.
    """
    class Theme(models.TextChoices):
        LIGHT = 'light', 'Light'
        DARK = 'dark', 'Dark'
        HSE_RED = 'hse_red', 'HSE Red'

    project = models.OneToOneField(Project, on_delete=models.CASCADE, related_name='settings')
    logo = models.ImageField(upload_to='logos/', blank=True, null=True)
    app_name = models.CharField(max_length=100, default='HSEBOOK')
    theme = models.CharField(max_length=20, choices=Theme.choices, default=Theme.HSE_RED)
    project_area = models.CharField(max_length=255, blank=True, default='')
    project_duration = models.CharField(max_length=100, blank=True, default='')
    
    # Safety Intelligence Fields
    man_hours = models.IntegerField(default=0, help_text='Total man-hours worked')
    equipment_count = models.IntegerField(default=0, help_text='Number of equipment items')
    openai_api_key = models.CharField(max_length=500, blank=True, default='', help_text='OpenAI API key for AI analysis')
    ai_risk_trends_enabled = models.BooleanField(default=True, help_text='Enable AI-powered risk trend predictions')

    def __str__(self):
        return f"{self.app_name} Settings"
    
    @property
    def total_observations(self):
        """Get total observations for this project."""
        from django.db.models import Count
        return self.project.posts.count() if hasattr(self.project, 'posts') else 0
