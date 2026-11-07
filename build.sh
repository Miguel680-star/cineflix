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
# Se crea solo si Render tiene configuradas las variables DJANGO_SUPERUSER_*.
if [ -n "$DJANGO_SUPERUSER_USERNAME" ] && [ -n "$DJANGO_SUPERUSER_PASSWORD" ]; then
  python manage.py createsuperuser --no-input || true
fi
