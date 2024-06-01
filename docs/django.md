# Django

## Extend User Model
for example to use an encrypted field for the email address
```py
# base/models.py
from django.contrib.auth.models import AbstractUser as DjangoUser

from pgcrypto.fields import EncryptedEmailField


class User(DjangoUser):
    email = EncryptedEmailField()
```

```py
# app/settings.py
AUTH_USER_MODEL = "base.User"
```
