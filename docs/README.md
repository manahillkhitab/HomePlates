# HomePlates Privacy Policy - GitHub Pages Setup

## Quick Deploy Instructions

### Option 1: GitHub Pages (Recommended)

1. **Create a new repository** on GitHub:
   - Name: `homeplates-privacy`
   - Public repository
   - Don't initialize with README

2. **Upload `privacy.html`**:
   ```bash
   cd c:\Users\Administrator\Documents\flutter_app\docs
   git init
   git add privacy.html
   git commit -m "Add privacy policy"
   git branch -M main
   git remote add origin https://github.com/[YOUR-USERNAME]/homeplates-privacy.git
   git push -u origin main
   ```

3. **Enable GitHub Pages**:
   - Go to repository Settings
   - Pages section
   - Source: `main` branch, `/` (root)
   - Save

4. **Your URL will be**:
   ```
   https://[YOUR-USERNAME].github.io/homeplates-privacy/privacy.html
   ```

### Option 2: Use This File Directly

If you don't want to use Git:

1. Go to GitHub.com → New Repository
2. Name: `homeplates-privacy`
3. After creating, click "uploading an existing file"
4. Drag and drop `privacy.html`
5. Commit
6. Enable GitHub Pages in Settings

---

## Add to Play Store Console

Once hosted, add this URL to:
- **Play Console** → **Store Presence** → **Privacy Policy**
- Paste: `https://[YOUR-USERNAME].github.io/homeplates-privacy/privacy.html`

---

## Verification

Test your privacy policy URL in a browser to ensure it loads correctly before submitting to Play Store.

---

**File location**: `c:\Users\Administrator\Documents\flutter_app\docs\privacy.html`
