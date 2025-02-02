# Django

## Basic Structure
1. Initialize django project
    - Create project directory
    - Create `README.md`, `LICENSE` and `.gitignore` using [gitignore.io](https://www.toptal.com/developers/gitignore/)
    - Add `Django==5.0.7` to `requirements.txt`
    - Initialize Django Project using `django-admin startproject app`
2. Adjust django settings (`project-name/app/settings.py`)
    - Randomize `SECRET_KEY`
      ```py
      import random
      from os import environ
      from string import punctuation, digits, ascii_letters

      SECRET_KEY = environ.get('SECRET_KEY', repr(''.join([
        random.SystemRandom().choice(ascii_letters + digits + punctuation) for i in range(
          random.randint(64, 80)
        )])
      ))
      ```
    - Make `DEBUG` and `ALLOWED_HOSTS` dynamic
      ```py
      DEBUG = bool(int(environ.get('DEBUG', '0')))
      ALLOWED_HOSTS = environ.get('ALLOWED_HOSTS', '127.0.0.1').split(' ')
      ```
    - Adjust database configuration (PostgreSQL / MariaDB)
    - Adjust paths to templates and static files
      ```py
      #TEMPLATES = [{
      #    'DIRS': [BASE_DIR.joinpath('templates'),],             # <--- This line

      STATIC_ROOT = BASE_DIR.joinpath('static')
      ```
    - Add django translations and set timezone
      ```py
      from django.utils.translation import gettext_lazy as _

      MIDDLEWARE = [
        'django.middleware.security.SecurityMiddleware',
        'django.contrib.sessions.middleware.SessionMiddleware',
        'django.middleware.locale.LocaleMiddleware',              # <--- this line
        'django.middleware.common.CommonMiddleware',

      LANGUAGES = [
          ('en', _('English')),
          ('de', _('German')),
      ]

      TIME_ZONE = 'Europe/Berlin'

      USE_L10N = True
      USE_I18N = True
      ```
      Replace static list in `app/urls.py` with `i18n_patterns()`
      ```py
      from django.conf.urls.i18n import i18n_patterns
      urlpatterns = i18n_patterns(
          path('admin/', admin.site.urls),
      )
      ```
    - Rename admin Site
      ```py
      # app/urls.py

      from django.utils.translation import gettext as _

      admin.site.site_header = admin.site.site_title = _('Your project')
      admin.site.index_title = _('Welcome to your project')
      ```
3. Create django base app
    - Create app using `python3 manage.py startapp base`
    - Load base app in `app/settings.py`:
      ```py
      INSTALLED_APPS += [
        'base.apps.BaseConfig',
      ]
      ```
    - Add view, url routing and static files for `manifest.json`
      ```py
      # base/views.py
      from django.http import HttpRequest, JsonResponse

      def manifest(request: HttpRequest) -> JsonResponse:
          return JsonResponse({
              'name': '',
              'short_name': '',
              'icons': [
                  {
                      'src': 'img/android-chrome-192x192.png',
                      'sizes': '192x192',
                      'type': 'image/png'
                  }, {
                      'src': 'img/android-chrome-512x512.png',
                      'sizes': '512x512',
                      'type': 'image/png'
                  }
              ],
              'theme_color': '#ffffff',
              'background_color': '#ffffff',
              'display': 'standalone'
          })
      ```
4. [Optional] Add Django Rest Framework
    - Add `'rest_framework.apps.RestFrameworkConfig',` to `INSTALLED_APPS` in `app/settings.py`
    - Add `djangorestframework==3.15.2` to `requirements.txt`
5. [Optional] Add open id connect to login (I suggest using keycloak or authentik instead of implementing authentification with support for multifactorauthentication yourself)
6. [Optional] Add `Dockerfile` and `entrypoint.sh` to build docker image
7. [Optional] Add continous integration pipeline to build and push docker image

## Extend User Model
```py
# base/models.py
from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    birthdate = models.DateField(null=True, blank=True)
```

```py
# base/admin.py
from base.models import User
from django.contrib import admin

admin.site.register(User)
```

```py
# app/settings.py
AUTH_USER_MODEL = "base.User"
```