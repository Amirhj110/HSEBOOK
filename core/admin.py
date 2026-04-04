from django.contrib import admin
from .models import User, Project, Profile, Post, ProjectSettings


@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ('username', 'email', 'role', 'is_project_admin', 'is_staff', 'date_joined')
    list_filter = ('role', 'is_project_admin', 'is_staff')
    search_fields = ('username', 'email', 'first_name', 'last_name')


@admin.register(Project)
class ProjectAdmin(admin.ModelAdmin):
    list_display = ('name', 'access_code', 'admin', 'created_at')


@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'project')
    list_filter = ('project',)


@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    list_display = ('id', 'author', 'project', 'status', 'created_at')
    list_filter = ('status', 'project')


@admin.register(ProjectSettings)
class ProjectSettingsAdmin(admin.ModelAdmin):
    list_display = ('app_name', 'project', 'theme', 'project_area', 'project_duration')