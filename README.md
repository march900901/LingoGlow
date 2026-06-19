# LingoGlow - Premium Spaced Repetition Vocabulary Trainer

LingoGlow is a cross-platform vocabulary training application built with **Flutter** and powered by **Supabase**. It utilizes the **SuperMemo-2 (SM-2)** spaced repetition algorithm to optimize learning.

## Key Features

1. **Comprehensive Training Flow**:
   - **Spelling Test**: Character-level diff highlights showing additions, missing letters, and corrections.
   - **Synonyms & Antonyms**: Interactive tagging system requiring at least 3 synonyms and 2 antonyms. Auto-reveals suggestions if input is incomplete.
   - **Sentence Making**: Verifies correct target word usage and highlights syntax/spelling mistakes.
   - **Flashcard Rating**: Evaluates recall confidence to schedule reviews.
2. **Dual Mode Storage**:
   - **Offline Local Mode**: Default fallback using `shared_preferences` storage to let you start practicing instantly.
   - **Supabase Cloud Mode**: Syncs data dynamically across devices via Google OAuth2.
3. **Responsive Design**: Designed to fit mobile and desktop screen form factors.

---

## Getting Started

### 1. Flutter Setup
To run this application locally, ensure you have Flutter installed.

```bash
# Get dependencies
flutter pub get

# Run on your default device (web, desktop, or mobile)
flutter run
```

### 2. Supabase Setup
If you want to enable Cloud Sync:
1. Go to [Supabase](https://supabase.com) and create a new project.
2. In the **SQL Editor**, paste and run the contents of `supabase/schema.sql` to initialize your database table and configure Row Level Security (RLS) policies.
3. Navigate to **Authentication -> Providers -> Google** in Supabase to configure Google OAuth credentials.
4. In the LingoGlow app, go to the **Cloud Settings (雲端設定)** tab and input your **Supabase URL** and **Anon Key**.
5. Once connected, log in with Google to synchronize your vocabulary database.

---

## How to Push this Project to GitHub

To upload this project to your GitHub account:

1. Open your terminal in this project directory (`C:\Users\User\.gemini\antigravity\scratch\lingo_glow`).
2. Create a new, empty repository on [GitHub](https://github.com/new). Name it `lingo_glow`. Do **not** initialize it with a README, license, or `.gitignore` (as these are already created for you).
3. Copy the URL of your new GitHub repository. It will look like `https://github.com/your-username/lingo_glow.git`.
4. Run the following commands:

```bash
# Rename default branch to main
git branch -M main

# Add your GitHub repository as the remote origin
git remote add origin <YOUR_GITHUB_REPOSITORY_URL>

# Push code to GitHub
git push -u origin main
```
