# Hybrid Database Architecture

## Overview

This project uses a **hybrid database approach**:
- **libsql_dart** → Shared data (sync between users/devices)
- **ObjectBox** → Local/internal data (AI chat, cache)

---

## Data Distribution

### 🔵 Remote (libsql_dart) - Shared Data

| Repository | Table | Purpose | Shared With |
|------------|-------|---------|-------------|
| `JobApplicationRepository` | `job_applications` | Job applications | Recruiter ↔ Jobseeker |
| `SavedJobRepository` | `saved_jobs` | Bookmarked jobs | Jobseeker (sync devices) |
| `JobPostingRepository` | `job_postings` | Job postings | Recruiter → Jobseeker |
| `CandidateRepository` | `candidates` | Candidate profiles | Jobseeker → Recruiter |

### 🟣 Local (ObjectBox) - Internal Data

| Repository | Entity | Purpose |
|------------|--------|---------|
| `ChatSessionRepository` | `ChatSessionRecord` | AI chat sessions |
| `ShortlistArtifactRepository` | `RecruiterShortlistRecord` | Screening results cache |
| `ScorecardArtifactRepository` | `CandidateScorecardRecord` | Interview scorecards |
| `InterviewGuideArtifactRepository` | `InterviewGuideRecord` | Generated interview guides |

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        REMOTE (Turso/LibSQL)                     │
│  • job_applications  • saved_jobs  • job_postings  • candidates │
└─────────────────────────────────────────────────────────────────┘
                            ▲
                            │ libsql_dart (auto-sync)
                            ▼
┌─────────────────────┐           ┌─────────────────────┐
│  Recruiter App      │           │  Jobseeker App      │
├─────────────────────┤           ├─────────────────────┤
│ libsql_dart:        │           │ libsql_dart:        │
│ • Job applications  │           │ • My applications   │
│ • Job postings      │           │ • Saved jobs        │
│ • Candidates        │           │ • My profile        │
│                     │           │                     │
│ ObjectBox:          │           │ ObjectBox:          │
│ • AI chat sessions  │           │ • AI chat sessions  │
│ • Shortlist cache   │           │ • AI cache          │
│ • Scorecards        │           │                     │
└─────────────────────┘           └─────────────────────┘
```

---

## Usage Examples

### Initialize Database

✅ **Already done in `main_jobseeker.dart` and `main_recruiter.dart`:**

```dart
import 'lib/services/hybrid_database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadEnv();
  await hybridDatabase.autoInit(); // ← Auto: replica (mobile) or remote (web)
  runApp(MyApp());
}
```

```dart
import 'lib/services/hybrid_database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadEnv();

  // Auto-detect: replica (mobile) or remote (web)
  await hybridDatabase.autoInit(syncIntervalSeconds: 5);

  runApp(MyApp());
}
```

### Job Applications (Shared)

```dart
import 'lib/repositories/job_application_repository.dart';

final repo = JobApplicationRepository();

// Jobseeker: Apply to job
await repo.create(JobApplication.create(
  jobId: 'job_123',
  jobTitle: 'Senior Flutter Dev',
  company: 'Tech Co',
  coverLetter: 'I am interested...',
));

// Recruiter: View applications for a job
final apps = await repo.getByJobId('job_123');

// Recruiter: Update status
await repo.updateStatus('app_456', ApplicationStatus.interviewing);

// Jobseeker: View my applications
final myApps = await repo.getByCandidateId('candidate_789');
```

### Saved Jobs (Sync Across Devices)

```dart
import 'lib/repositories/saved_job_repository.dart';

final repo = SavedJobRepository();

// Save a job
await repo.saveJob(
  jobId: 'job_123',
  title: 'Senior Flutter Dev',
  company: 'Tech Co',
  location: 'Remote',
);

// Get all saved jobs
final saved = await repo.getAll();

// Toggle save status
final isSaved = await repo.toggle('job_123',
  title: 'Senior Flutter Dev',
  company: 'Tech Co',
);
```

### Job Postings (Recruiter → Jobseeker)

```dart
import 'lib/repositories/job_posting_repository.dart';

final repo = JobPostingRepository();

// Recruiter: Create job posting
await repo.create(JobPosting(
  id: 'posting_123',
  jobId: 'job_456',
  title: 'Senior Flutter Dev',
  department: 'Engineering',
  location: 'Remote',
  description: 'We are looking for...',
  requirementsJson: '[{"skill": "Flutter", "required": true}]',
  status: 'draft',
));

// Recruiter: Publish
await repo.publish('job_456');

// Jobseeker: Browse active jobs
final jobs = await repo.getActive();

// Jobseeker: Search
final results = await repo.search('Flutter');
```

### AI Chat (Local Only)

```dart
import 'lib/repositories/chat_session_repository.dart';

// Still uses ObjectBox - no sync
final repo = ChatSessionRepository();
await repo.createSession(sessionId, title);
```

---

## Environment Variables

```bash
# .env
LIBSQL_URL=libsql://your-database.turso.io
LIBSQL_URL_TOKEN=your_auth_token
JOBSEEKER_USER_ID=jobseeker_123
RECRUITER_USER_ID=recruiter_123
```

`JOBSEEKER_USER_ID` and `RECRUITER_USER_ID` are temporary ownership identifiers for shared data until the app uses a real auth/session provider.

---

## Migration Status

### Repositories
- ✅ `JobApplicationRepository` - Uses libsql_dart
- ✅ `SavedJobRepository` - Uses libsql_dart
- ✅ `JobPostingRepository` - Uses libsql_dart
- ✅ `CandidateRepository` - Uses libsql_dart
- ⚪ `ChatSessionRepository` - Stays on ObjectBox
- ⚪ `ShortlistArtifactRepository` - Stays on ObjectBox
- ⚪ `ScorecardArtifactRepository` - Stays on ObjectBox
- ⚪ `InterviewGuideArtifactRepository` - Stays on ObjectBox

### Screens (Jobseeker)
- ✅ `JobBrowseScreen` - Browse jobs from libsql_dart
- ✅ `MyApplicationsScreen` - View applications from libsql_dart
- ✅ `SavedJobsScreen` - Manage saved jobs from libsql_dart
- ✅ `JobSeekerHomeScreen` - Updated with navigation to new screens

### Screens (Recruiter)
- ✅ Recruiter read path for job postings now uses `JobPostingRepository` / libsql_dart
- ⚪ Recruiter AI artifacts still use ObjectBox
  - `RecruiterJobPostListScreen` - Reads job postings from LibSQL, combines with local shortlist/scorecard/guide artifacts
  - `ShortlistResultScreen` - Uses ObjectBox for AI screening cache
  - `JobCandidatesScreen` - Uses ObjectBox for shortlist, scorecard, and interview guide artifacts
  - `RecruiterScreeningListScreen` - Reads jobs from LibSQL, screening artifacts from ObjectBox
  - `RecruiterInterviewListScreen` - Reads jobs from LibSQL, interview artifacts from ObjectBox

### Current Boundary
- `libsql_dart` is the source of truth for shared business entities.
- `ObjectBox` is reserved for local recruiter artifacts and chat persistence.
