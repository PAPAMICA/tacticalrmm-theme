# Generated for tacticalrmm-theme

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("accounts", "0040_role_can_use_registry"),
    ]

    operations = [
        migrations.AddField(
            model_name="user",
            name="ui_theme",
            field=models.CharField(default="dracula", max_length=50),
        ),
    ]
