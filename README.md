# IELTS Helper (Flutter)

A modern, offline-first Flutter application designed for IELTS Academic preparation. Combines an **Active-Recall Cloze Typing Engine** powered by the **SuperMemo SM-2 Spaced Repetition algorithm**, an **Anki-style intra-session relearning loop**, an **embedded SQLite database** for granular attempt tracking, and an authentic **IELTS Academic Reading exam simulation**.

---

## What the App Does

* **Active-Recall Cloze Typing Engine**:
  * Tests vocabulary in authentic IELTS contexts rather than passive multiple-choice or simple flashcard flipping.
  * Candidates must type the exact word into the sentence blank, reinforcing active recall and spelling accuracy essential for IELTS Writing and Listening.
  * **3-Tier Progressive Hint System**: Tier 1 (Part of speech & definition), Tier 2 (First & last letter clues `D · · · · · · · · L`), and Tier 3 (Phonetic transcription and pronunciation guide).
  * **Typo Tolerance**: Uses **Damerau-Levenshtein distance** to detect 1-letter typos and transpositions, awarding amber spelling alerts (`quality = 2`) without failing the candidate for minor slips.

* **Anki-Style Spaced Repetition & Relearning**:
  * **SM-2 Spaced Repetition**: Dynamic interval scheduling ($I' = I \times EF$) and ease factor adjustments based on recall quality ($0..5$).
  * **Intra-Session Relearning Loop**: When an answer is incorrect or the user selects "Don't Know", the card is re-inserted ~3 cards ahead into the active session queue. The session only completes when all cards have been successfully recalled and typed.
  * **15-Card Topic Progression**: Topic decks default to 15 cards per session. Session 1 covers the first 15 words; subsequent sessions seamlessly advance to remaining unstudied words (e.g. cards 16–25) plus due reviews, avoiding repetitive looping.

* **Embedded SQLite Database & Attempt Analytics**:
  * Powered by `sqflite` (Android/iOS) and `sqflite_common_ffi` (Linux desktop & unit tests).
  * **`srs_cards` Table**: Persists SM-2 state (repetition, ease factor, interval, due date, lapse count, state).
  * **`review_logs` Table**: Anki `revlog` equivalent recording every attempt (target word, user input, quality rating, correctness, hint level, time taken in seconds, timestamp).
  * **Streak & State Persistence**: Records daily study streaks and last study date. Includes automatic migration from legacy `SharedPreferences`.

* **IELTS Academic Reading Module**:
  * Authentic long-form reading passages with paragraph labeling and interactive font size controls.
  * Realistic IELTS question types: **True / False / Not Given (TFNG)**, **Multiple Choice**, and **Summary Fill-in-the-Blank**.
  * **Automated Evaluator & Cambridge Band Score Calculator**: Converts raw correct question counts (0–40) into official Cambridge IELTS Band Scores (0.0 to 9.0) with score breakdowns and detailed answer explanations.

* **Comprehensive IELTS Vocabulary Dataset**:
  * **932 unique academic vocabulary items** categorized across **33 IELTS topics** scraped from authentic IELTS Liz resources.
  * Includes definitions, parts of speech, collocations, authentic example sentences, and pronunciation transcriptions.

---

## Code Structure

```
lib/
├── core/
│   ├── database/
│   │   └── app_database.dart               # SQLite database singleton (srs_cards, review_logs, metadata)
│   └── theme/
│       └── app_theme.dart                  # Material 3 colors, typography & custom input styles
├── features/
│   ├── flashcards/
│   │   ├── models/
│   │   │   └── cloze_prompt.dart           # Cloze sentence blank model with alternative answers
│   │   ├── presentation/
│   │   │   ├── controllers/
│   │   │   │   └── study_session_controller.dart # Active session state machine with Anki relearn loop
│   │   │   ├── screens/
│   │   │   │   ├── deck_dashboard_screen.dart   # Dashboard with daily SRS queue and IELTS topic decks
│   │   │   │   ├── flashcard_study_screen.dart   # Interactive typing card view with timer & repeat badge
│   │   │   │   └── session_summary_screen.dart  # Session metrics, accuracy ring & study streak
│   │   │   └── widgets/
│   │   │       ├── cloze_card_view.dart         # Contextual academic sentence card component
│   │   │       ├── feedback_sheet.dart          # Bottom sheet feedback with "Will repeat" indicator
│   │   │       └── typing_input_area.dart       # Active recall text field, hints, and submit controls
│   │   └── services/
│   │       ├── answer_evaluator.dart         # Damerau-Levenshtein distance evaluator & typo scoring
│   │       └── cloze_generator.dart          # Sentence blank extractor and contextual fallback engine
│   ├── navigation/
│   │   └── main_navigation_shell.dart       # Bottom navigation bar (Vocabulary & Reading practice)
│   ├── reading/
│   │   ├── models/
│   │   │   ├── reading_question.dart        # TFNG, multiple-choice & blank question models
│   │   │   ├── reading_test.dart            # Academic reading test, passages & paragraph structure
│   │   │   └── reading_test_result.dart     # Test score results, band calculation & answer reviews
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── reading_home_screen.dart     # Reading test catalog and historical band scores
│   │   │   │   ├── reading_result_screen.dart   # Band score summary card, answer review & explanations
│   │   │   │   └── reading_test_screen.dart     # Timed exam simulation with auto-scroll passage view
│   │   │   └── widgets/
│   │   │       ├── passage_view.dart            # Paragraph-annotated passage text & font controls
│   │   │       ├── question_card.dart           # Tailored input components per IELTS question type
│   │   │       └── question_drawer.dart         # Collapsible question drawer with navigation anchors
│   │   └── services/
│   │       ├── band_score_calculator.dart   # Official Cambridge 40-question to 9.0 Band converter
│   │       ├── reading_evaluator.dart       # Deterministic grading & word limit enforcement
│   │       └── reading_service.dart         # Test loader and result persistence
│   └── srs/
│       ├── models/
│       │   ├── review_log.dart              # Anki-style revlog attempt model with timestamps
│       │   └── srs_card.dart                # SuperMemo SM-2 memory state & card lifecycle model
│       └── services/
│           ├── srs_engine.dart              # SM-2 interval, quality rating & ease factor logic
│           └── srs_storage_service.dart     # SQLite storage repository & legacy migration
├── models/
│   └── vocabulary_item.dart                 # Vocabulary item & topic category schema
├── services/
│   └── vocabulary_service.dart              # Asset loading & 15-card topic progression queue builder
└── main.dart                                # Application entry point & theme initialization
```

---

## How to Run the App

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.13.2` or later)
* Android SDK / Android Studio (for Android build or emulator)
* Linux desktop build tools (if running on Linux desktop):
  ```bash
  sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev
  ```

### 1. Clone the Repository
```bash
git clone https://github.com/natan-mesay/ielts-helper.git
cd ielts-helper
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run Static Analysis & Tests
Verify code formatting, static analysis, and 100% test pass rate:
```bash
flutter analyze
flutter test
```

### 4. Launch the App
Run on a connected Android device, emulator, or Linux desktop:
```bash
flutter run
```

### 5. Build Release APK (Android)
To build a standalone production APK:
```bash
flutter build apk --release
```
The resulting APK will be generated at:
`build/app/outputs/flutter-apk/app-release.apk`

---

## Automation Shortcuts (`Makefile`)
A `Makefile` is included for common developer workflows:
* `make test` — Runs static analysis (`flutter analyze`) and all 37 automated tests.
* `make apk` — Builds production release APK.
* `make apk-debug` — Fast debug APK build.
* `make clean` — Cleans Flutter build artifacts.
