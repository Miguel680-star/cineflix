#!/usr/bin/env bash
# Script de compilación que Render ejecuta en cada despliegue.
set -o errexit

pip install --upgrade pip
pip install -r requirements.txt

# Base de datos y archivos estáticos
python manage.py migrate --no-input
python manage.py collectstatic --no-input

# Contenido de ejemplo (no duplica nada si ya existe)
python manage.py seed_demo
python manage.py seed_plans

# Usuario administrador del panel.
# Se crea si no existe y SIEMPRE sincroniza la contraseña con la variable de Render,
# así el acceso (admin / DJANGO_SUPERUSER_PASSWORD) funciona en cada despliegue.
if [ -n "$DJANGO_SUPERUSER_USERNAME" ] && [ -n "$DJANGO_SUPERUSER_PASSWORD" ]; then
  python manage.py shell -c '
import os
from django.contrib.auth import get_user_model

User = get_user_model()
username = os.environ["DJANGO_SUPERUSER_USERNAME"]
password = os.environ["DJANGO_SUPERUSER_PASSWORD"]
email = os.environ.get("DJANGO_SUPERUSER_EMAIL", "")

user, created = User.objects.get_or_create(username=username)
user.email = email
user.is_staff = True
user.is_superuser = True
user.set_password(password)
user.save()
print(("Creado" if created else "Actualizado") + " superusuario: " + username)
'
fi
