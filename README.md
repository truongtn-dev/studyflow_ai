# StudyFlow AI

Flutter project – PRM393 Mobile Programming.

## Chạy project

```bash
cd studyflow_ai
flutter pub get
flutter run
```

## Cấu trúc đã scaffold

```
lib/
├── main.dart, app.dart
├── theme/          ← UI Design System (AppColors, AppTheme)
├── widgets/        ← SfCard, SfButton, EmptyState, LoadingShimmer
├── db/             ← DatabaseHelper (SQLite 8 bảng)
├── models/         ← User, Course, Task
├── repositories/   ← UserRepository, CourseRepository
├── providers/      ← ThemeProvider
└── screens/        ← Splash, MainShell, Dashboard, Profile, placeholders
```

## Phân công tiếp theo

| Folder | Người |
|--------|-------|
| `lib/db/`, `lib/repositories/`, `lib/models/` | Minh Khánh |
| `lib/theme/`, `lib/widgets/`, `lib/screens/home/` | Hữu Duy |
| `lib/screens/auth/` | Nhựt Linh |
| `lib/screens/ai/` | Thành Trương |
| `lib/screens/tasks/`, `lib/screens/study/` | Tuấn Huy |
| `lib/screens/cards/` | Nhất Thiện |

## Database

SQLite file: `studyflow.db`  
Schema: `../database/studyflow_schema.sql`
