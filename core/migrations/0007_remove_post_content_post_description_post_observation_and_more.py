# Generated migration to replace content field with observation/description/rectification

from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ('core', '0006_post_location_post_severity_profile_assigned_area'),
    ]

    operations = [
        # Remove the old content field
        migrations.RemoveField(
            model_name='post',
            name='content',
        ),
        # Add the new fields
        migrations.AddField(
            model_name='post',
            name='observation',
            field=models.TextField(default=''),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name='post',
            name='description',
            field=models.TextField(blank=True, default=''),
        ),
        migrations.AddField(
            model_name='post',
            name='rectification',
            field=models.TextField(blank=True, default=''),
        ),
    ]
