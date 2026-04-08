"""
URL configuration for hse_api project.
"""
from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('core.urls')),
    path('', include('core.urls')),
]

# Serve media files with CORS headers (always, not just DEBUG)
urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
