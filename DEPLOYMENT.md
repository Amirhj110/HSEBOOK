# Deployment Instructions for HSEBOOK on PythonAnywhere

## 1. Clone the Repository
```bash
git clone https://github.com/Amirhj110/HSEBOOK.git
cd HSEBOOK
```

## 2. Create a Virtual Environment
```bash
mkvirtualenv HSEBOOK
```

## 3. Install Dependencies
```bash
pip install -r requirements.txt
```

## 4. Set Environment Variables
- **SECRET_KEY**: Set this in PythonAnywhere's environment variables (e.g., via the dashboard or using `setenv SECRET_KEY your_secret_key`).
- **ALLOWED_HOSTS**: Ensure `ALLOWED_HOSTS` in `settings.py` includes `['localhost', '127.0.0.1', 'hsebook.pythonanywhere.com']`.

## 5. WSGI Configuration
- The WSGI application is already configured in `settings.py` as:
  ```python
  WSGI_APPLICATION = 'hse_api.wsgi.application'
  ```
  No additional commands are required unless you modify this setting.

## 6. Database Setup (if needed)
- If using SQLite (default), no action is required as `db.sqlite3` is already in place.
- For PostgreSQL, additional setup would be needed (not required here).

## 7. Final Steps
- Push the repository to GitHub (if not already done).
- Deploy the app via PythonAnywhere's dashboard or CLI.