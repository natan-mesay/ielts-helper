# Project Context: IELTS Academic Active-Recall & Spaced Repetition App

> **Role & Persona:** Senior Flutter Developer & UI/UX Designer (10 years experience).  
> **App Mission:** Help students pass the IELTS exam by developing active recall, spelling accuracy, and contextual academic vocabulary mastery.

---

## 1. Executive Summary

This project is a high-performance cross-platform Flutter application tailored for IELTS preparation. Rather than relying on passive multiple-choice or simple card flipping, the app employs an **Active-Recall Cloze Typing Engine** powered by the **SuperMemo SM-2 Spaced Repetition algorithm**.

Students are presented with authentic academic sentences with key IELTS vocabulary words masked in context. They must **type the exact word**, reinforcing spelling, morphology, and collocations necessary for Band 7+ scores in IELTS Writing (Tasks 1 & 2) and Listening.

---

## 2. Technology Stack & Environment

| Layer | Technology | Details |
| :--- | :--- | :--- |
| **Framework** | Flutter 3.47.2 | Channel `stable`, Engine revision `1cf1c4773fb` |
| **Language** | Dart 3.13.2 | Null-safety enabled |
| **SDK Path** | `/home/natan/develop/flutter` | Configured with Linux, Web, and Android support |
| **Architecture** | Feature-First Clean Architecture | Domain models, isolated service engines, reactive UI controllers |
| **State Management** | `ChangeNotifier` | Declarative, lightweight, zero unnecessary boilerplate |
| **Styling & Fonts** | Material 3 + Google Fonts | Plus Jakarta Sans typography; Academic Indigo & Emerald palette |
| **Micro-Animations**| `flutter_animate: ^4.5.2` | Card shakes on typos, smooth slide-ins, victory trophy scale |
| **Local Storage** | `shared_preferences: ^2.5.5` | Persistent JSON storage for SRS review intervals and streaks |
| **Web Server** | Built-in Python / Flutter Web | Fully compiled release bundle in `build/web` |
| **Automation** | GNU Make (`Makefile`) | One-command builds for APK, tests, scraping, and web runs |

---

## 3. Vocabulary Dataset Layer

The underlying vocabulary database was scraped directly from [IELTS Liz](https://ieltsliz.com/vocabulary/) using a concurrent multi-threaded Python engine ([`scraper.py`](scraper.py)).

- **Total Unique Vocabulary Items:** `932`
- **Total Topics & Lesson Decks:** `33`
- **Dataset Files:**
  - `ielts_vocabulary.json` (408 KB) & `ielts_vocabulary.csv` (206 KB)
  - `ielts_vocabulary_topics.json` (6 KB) & `ielts_vocabulary_topics.csv` (3.7 KB)
  - Synced to Flutter asset bundle: `assets/data/`

### Data Schema (`VocabularyItem`)
```json
{
  "id": "IELTS-VOCAB-0110",
  "term": "abduction",
  "part_of_speech": "noun",
  "definition": "taking someone against their will (kidnapping)",
  "pronunciation": "",
  "synonyms": "kidnapping",
  "example": "Police launched an operation following the abduction of the young girl.",
  "topic": "Crime & Punishment",
  "subtopic": "Major Crimes",
  "category": "Detailed Lists for Word Power",
  "source_url": "https://ieltsliz.com/crime-and-punishment-vocabulary/"
}
```

---

## 4. Spaced Repetition Engine (SM-2)

Located at [`lib/features/srs/services/srs_engine.dart`](lib/features/srs/services/srs_engine.dart).

### Mathematical Model
- **Quality Score ($q \in [0..5]$)**:
  - `5`: Instant correct typing without hints within 10 seconds.
  - `4`: Correct typing with minor hesitation or Tier-1 hint.
  - `3`: Correct typing after letter clues or serious difficulty.
  - `2`: Minor spelling typo (Damerau-Levenshtein distance = 1).
  - `1`: Incorrect answer; target word revealed.
  - `0`: Complete skip or blank answer.

- **Ease Factor Update Formula**:
  $$EF' = \max\left(1.3, EF + (0.1 - (5 - q) \times (0.08 + (5 - q) \times 0.02))\right)$$

- **Interval Scheduling**:
  - $q \ge 3$:
    - $repetition = 0 \implies \text{Interval} = 1\text{ day}$
    - $repetition = 1 \implies \text{Interval} = 6\text{ days}$
    - $repetition \ge 2 \implies \text{Interval} = \text{round}(\text{Interval} \times EF)$
  - $q < 3$ (Lapse):
    - $repetition = 0$
    - $\text{Interval} = 1\text{ day}$
    - $\text{LapseCount} += 1$
    - $EF = \max(1.3, EF - 0.2)$

- **Card States (`SrsState`)**: `newCard` $\to$ `learning` $\to$ `review` $\to$ `mastered` (graduated when interval $\ge 21$ days).

---

## 5. Active-Recall & Cloze Features

1. **Contextual Cloze Generation (`cloze_generator.dart`)**:
   - Analyzes authentic IELTS Liz sentences and masks the target root/stem into `[ _____ ]`.
   - Dynamically calculates letter counts, first letter, and last letter.
   - Falls back to structured academic context frames when an explicit sentence is absent.

2. **Typo Tolerance (`answer_evaluator.dart`)**:
   - Implements **Damerau-Levenshtein distance** supporting insertions, deletions, substitutions, and transpositions (e.g. `abductoin` vs `abduction`).
   - Flags an **Amber Spelling Alert** for 1-letter typos on words $\ge 5$ letters, giving candidates targeted feedback without frustrating them.

3. **3-Tier Progressive Hint System**:
   - **Tier 1 (💡)**: Part of Speech & Contextual Definition.
   - **Tier 2 (🔤)**: First and last letter clues (`D · · · · · · · · L`).
   - **Tier 3 (🗣️)**: Phonetic transcription and pronunciation guide.

---

## 6. Project Directory Tree

```
ielts/
├── Makefile                                      # Build & run automation
├── scraper.py                                    # IELTS Liz scraper
├── ielts_vocabulary.json                         # Master vocabulary dataset
├── ielts_vocabulary.csv                          # CSV dataset export
├── ielts_vocabulary_topics.json                  # Topic catalog
├── ielts_vocabulary_topics.csv                   # CSV topic export
├── CONTEXT.md                                    # This project context document
├── pubspec.yaml                                  # Flutter dependencies & assets
├── assets/
│   └── data/
│       ├── ielts_vocabulary.json
│       └── ielts_vocabulary_topics.json
├── lib/
│   ├── main.dart                                 # App entry point
│   ├── models/
│   │   └── vocabulary_item.dart                  # VocabularyItem & TopicInfo models
│   ├── services/
│   │   └── vocabulary_service.dart               # Asset loading & study queue builder
│   ├── core/
│   │   └── theme/
│   │       └── app_theme.dart                    # Material 3 colors, typography, styles
│   └── features/
│       ├── srs/
│       │   ├── models/
│       │   │   └── srs_card.dart                 # SRS memory state model
│       │   └── services/
│       │       ├── srs_engine.dart               # SuperMemo SM-2 logic
│       │       └── srs_storage_service.dart      # SharedPreferences persistence & streaks
│       └── flashcards/
│           ├── models/
│           │   └── cloze_prompt.dart             # Cloze sentence and clues model
│           ├── services/
│           │   ├── cloze_generator.dart          # Sentence blank generator
│           │   └── answer_evaluator.dart         # Damerau-Levenshtein evaluator
│           └── presentation/
│               ├── controllers/
│               │   └── study_session_controller.dart # Session state machine
│               ├── screens/
│               │   ├── deck_dashboard_screen.dart   # Main dashboard with decks & queue
│               │   ├── flashcard_study_screen.dart   # Interactive typing card screen
│               │   └── session_summary_screen.dart  # Session metrics & accuracy ring
│               └── widgets/
│                   ├── cloze_card_view.dart         # Academic sentence card view
│                   ├── typing_input_area.dart       # Active recall input field
│                   └── feedback_sheet.dart          # Animated bottom sheet feedback
├── features/reading/                             # IELTS Academic Reading Practice Module
│   ├── models/
│   │   ├── reading_question.dart                # Question types, accepted answers, citations
│   │   ├── reading_test.dart                    # Passages, paragraphs, word count
│   │   └── reading_test_result.dart             # Result persistence, accuracy, band range
│   ├── services/
│   │   ├── band_score_calculator.dart           # Cambridge Academic conversion & projection
│   │   ├── reading_evaluator.dart               # Deterministic grading & word limit enforcement
│   │   └── reading_service.dart                 # Asset test loader & SharedPreferences cache
│   └── presentation/
│       ├── widgets/
│       │   ├── passage_view.dart                # Full passage text, font controls, anchors
│       │   ├── question_card.dart               # Tailored inputs (TFNG, MC, Blanks)
│       │   └── question_drawer.dart             # Collapsible drawer with question navigator
│       └── screens/
│           ├── reading_home_screen.dart         # Test catalog, category filters, past bands
│           ├── reading_test_screen.dart         # Timed exam session with auto-scroll
│           └── reading_result_screen.dart       # Band score hero card, reviews & explanations
├── features/navigation/
│   └── main_navigation_shell.dart               # Bottom navigation bar (Vocab + Reading)
└── test/
    ├── srs_engine_test.dart                      # SM-2 unit test suite
    ├── answer_evaluator_test.dart                # Evaluator & typo unit test suite
    ├── cloze_generator_test.dart                 # Cloze generator unit test suite
    ├── band_score_calculator_test.dart           # Cambridge band score conversion test suite
    ├── reading_evaluator_test.dart               # Reading evaluator unit test suite
    ├── reading_service_test.dart                 # Reading test & result model test suite
    └── widget_test.dart                          # Dashboard initialization test
```

---

## 7. Verification & Quality Assurance

- **Static Analysis**: `flutter analyze` $\to$ **`0 issues found`** (100% clean).
- **Automated Tests**: `flutter test` $\to$ **`25 / 25 tests passed`** (100% pass rate across Vocab & Reading).
- **Web Release Build**: `flutter build web --release` $\to$ **Compiled successfully** into `build/web`.
- **Android APK Build**: Automated via `make apk` $\to$ `ielts_app.apk`.

---

## 8. Common Developer Commands

```bash
# Build Android APK
make apk                # Builds APK -> ielts_app.apk
make apk-debug          # Fast debug APK
make apk-split          # Split APKs -> build/app/outputs/flutter-apk/

# Web App
make serve              # Serve release build on http://localhost:8080
make run-brave          # Launch web version in Brave browser
make build-web          # Compile release web bundle

# Quality & Testing
make test               # Runs static analysis (flutter analyze) and all 25 tests
make clean              # Cleans build artifacts

# Data Maintenance
make scrape             # Re-runs scraper.py and updates assets/data/
```
