from firebase_admin import auth

def create_firebase_user(email, password, name):
    user = auth.create_user(
        email=email,
        password=password,
        display_name=name
    )
    return user.uid

def delete_firebase_user(uid):
    auth.delete_user(uid)