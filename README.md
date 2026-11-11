# NEXORA RESUME APP
## AI-Powered Resume and Career Preparation Application

---

## 1. Project Overview

Nexora Resume App is an AI-powered resume and career preparation application designed to help students and job seekers create professional resumes, analyze resume quality, discover job opportunities, match resumes with job descriptions, generate cover letters, and prepare for interviews using Artificial Intelligence.

The project consists of two separate repositories:

1. **resumeapp-mobile-main** – Flutter-based mobile application.
2. **resumeapp-backend-main** – Java Spring Boot backend REST API.

The mobile application communicates with the backend through REST APIs. The backend handles authentication, database operations, resume processing, job management, and AI integration.

---

## 2. Project Features

### A. Mobile Application Features

- User Registration
- User Login
- JWT Authentication
- Dashboard
- Resume Upload
- Resume Analysis
- Resume History
- Resume Builder
- Resume PDF Generation
- Resume Sharing
- AI Resume Feedback
- Job Listings
- External Job Search
- Resume-to-Job Matching
- Job Match Score
- Match Details
- AI Cover Letter Generator
- AI Mentor Chat
- AI Interview Preparation
- Text-Based Interview
- Interview Feedback
- Personalized Learning Roadmap
- Progress Tracking
- Help and Support Screen

### B. Backend Features

- REST API Development
- User Authentication
- User Registration and Login
- JWT Authentication
- Resume Management
- Resume Analysis
- Resume Feedback
- Job Management
- Applied Job Management
- Application Management
- Job Match Score Management
- Google Gemini AI Integration
- Adzuna Job API Integration
- Cover Letter Generation
- AI Mentor Services
- Resume Builder API
- Database Integration
- Security Configuration
- Rate Limiting
- Global Exception Handling
- PDF Document Processing
- Office Document Processing

---

## 3. Technology Stack

### Frontend

- Flutter
- Dart
- Material Design 3
- HTTP Package
- Shared Preferences
- File Picker
- Camera
- Permission Handler
- Flutter TTS
- Path Provider
- Share Plus

### Backend

- Java 17
- Spring Boot
- Spring MVC
- Spring Security
- Spring Data JPA
- Hibernate
- JWT Authentication
- Maven

### Database

- PostgreSQL
- H2 Database

### AI Integration

- Google Gemini API

### Document Processing

- Apache PDFBox
- Apache POI

### Development Tools

- Android Studio
- Visual Studio Code
- IntelliJ IDEA
- Flutter SDK
- Git
- GitHub
- Maven

---

## 4. Project Architecture

The application follows a client-server architecture.

```text
                  NEXORA RESUME APP
                         |
                         v
             Flutter Mobile Application
                         |
                         |
              REST API / HTTP / JSON
              JWT Bearer Authentication
                         |
                         v
              Spring Boot Backend
                         |
          +--------------+--------------+
          |              |              |
          v              v              v
     Controllers     Services      Repositories
          |              |              |
          +--------------+--------------+
                         |
                         v
               Security Configuration
                         |
          +--------------+--------------+
          |              |              |
          v              v              v
    JWT Filter     Rate Limit Filter   Exception Handler
                         |
                         v
                     Database
                         |
              +----------+----------+
              |                     |
              v                     v
          PostgreSQL               H2
                         |
                         v
                External Services
                         |
              +----------+----------+
              |                     |
              v                     v
        Google Gemini API      Adzuna Job API
```

---

## 5. Complete Project Structure

### A. Flutter Mobile Application

Repository: `resumeapp-mobile-main`

```text
resumeapp-mobile-main/
│
├── .gitignore
├── .metadata
├── AI_MENTOR_DESIGN.md
├── README.md
├── analysis_options.yaml
├── flutter
├── hr_avatar.png.jfif
├── nexora_ai_mentor_demo.html
├── pubspec.lock
├── pubspec.yaml
├── voice_tester.html
│
├── assets/
│   └── icon.png
│
├── android/
│   ├── .gitignore
│   ├── build.gradle.kts
│   ├── gradle.properties
│   ├── settings.gradle.kts
│   │
│   ├── gradle/
│   │   └── wrapper/
│   │       └── gradle-wrapper.properties
│   │
│   └── app/
│       ├── build.gradle.kts
│       │
│       └── src/
│           ├── debug/
│           │   └── AndroidManifest.xml
│           │
│           ├── main/
│           │   ├── AndroidManifest.xml
│           │   │
│           │   ├── kotlin/
│           │   │   ├── com/
│           │   │   │   ├── example/
│           │   │   │   │   └── resumeapp_mobile/
│           │   │   │   │       └── MainActivity.kt
│           │   │   │   │
│           │   │   └── nexora/
│           │   │       └── resume/
│           │   │           └── MainActivity.kt
│           │   │
│           │   └── res/
│           │       ├── drawable/
│           │       │   └── launch_background.xml
│           │       │
│           │       ├── drawable-v21/
│           │       │   └── launch_background.xml
│           │       │
│           │       ├── mipmap-hdpi/
│           │       │   └── ic_launcher.png
│           │       │
│           │       ├── mipmap-mdpi/
│           │       │   └── ic_launcher.png
│           │       │
│           │       ├── mipmap-xhdpi/
│           │       │   └── ic_launcher.png
│           │       │
│           │       ├── mipmap-xxhdpi/
│           │       │   └── ic_launcher.png
│           │       │
│           │       ├── mipmap-xxxhdpi/
│           │       │   └── ic_launcher.png
│           │       │
│           │       ├── values/
│           │       │   └── styles.xml
│           │       │
│           │       └── values-night/
│           │           └── styles.xml
│           │
│           └── profile/
│               └── AndroidManifest.xml
│
├── lib/
│   ├── main.dart
│   ├── api_service.dart
│   ├── app_background.dart
│   ├── cover_letter_screen.dart
│   ├── dashboard_screen.dart
│   ├── external_jobs_screen.dart
│   ├── help_screen.dart
│   ├── login_screen.dart
│   ├── match_detail_screen.dart
│   ├── nexora_ascend_screen.dart
│   ├── nexora_chat_screen.dart
│   ├── nexora_interview_feedback_screen.dart
│   ├── nexora_interview_screen.dart
│   ├── nexora_logo.dart
│   ├── nexora_roadmap_screen.dart
│   ├── nexora_text_interview_screen.dart
│   ├── progress_screen.dart
│   ├── register_screen.dart
│   ├── resume_analysis_screen.dart
│   ├── resume_builder_screen.dart
│   ├── resume_history_screen.dart
│   └── resume_upload_screen.dart
│
├── test/
│   └── widget_test.dart
│
├── web/
│   ├── favicon.png
│   ├── index.html
│   ├── manifest.json
│   │
│   └── icons/
│       ├── Icon-192.png
│       ├── Icon-512.png
│       ├── Icon-maskable-192.png
│       └── Icon-maskable-512.png
│
├── linux/
│   ├── .gitignore
│   ├── CMakeLists.txt
│   │
│   ├── flutter/
│   │   ├── CMakeLists.txt
│   │   ├── generated_plugin_registrant.cc
│   │   ├── generated_plugin_registrant.h
│   │   └── generated_plugins.cmake
│   │
│   └── runner/
│       ├── CMakeLists.txt
│       ├── main.cc
│       ├── my_application.cc
│       └── my_application.h
│
└── windows/
    ├── .gitignore
    ├── CMakeLists.txt
    │
    ├── flutter/
    │   ├── CMakeLists.txt
    │   ├── generated_plugin_registrant.cc
    │   ├── generated_plugin_registrant.h
    │   └── generated_plugins.cmake
    │
    └── runner/
        ├── CMakeLists.txt
        ├── Runner.rc
        ├── flutter_window.cpp
        ├── flutter_window.h
        ├── main.cpp
        ├── resource.h
        ├── runner.exe.manifest
        ├── utils.cpp
        ├── utils.h
        ├── win32_window.cpp
        ├── win32_window.h
        │
        └── resources/
            └── app_icon.ico
```

### B. Spring Boot Backend

Repository: `resumeapp-backend-main`

```text
resumeapp-backend-main/
│
├── .gitattributes
├── .gitignore
├── Dockerfile
├── mvnw
├── mvnw.cmd
├── pom.xml
│
├── .mvn/
│   └── wrapper/
│       └── maven-wrapper.properties
│
└── src/
    │
    ├── main/
    │   │
    │   ├── java/
    │   │   │
    │   │   └── com/
    │   │       └── resumeapp/
    │   │           │
    │   │           ├── ResumeappApplication.java
    │   │           │
    │   │           ├── config/
    │   │           │   ├── AiController.java
    │   │           │   ├── AppConfig.java
    │   │           │   ├── GeminiModelConfig.java
    │   │           │   ├── JwtAuthenticationFilter.java
    │   │           │   ├── RateLimitFilter.java
    │   │           │   └── SecurityConfig.java
    │   │           │
    │   │           ├── controller/
    │   │           │   ├── AppliedJobController.java
    │   │           │   ├── AuthController.java
    │   │           │   ├── CoverLetterController.java
    │   │           │   ├── ExternalJobsController.java
    │   │           │   ├── HealthController.java
    │   │           │   ├── JobController.java
    │   │           │   ├── MatchScoreController.java
    │   │           │   ├── MentorController.java
    │   │           │   ├── ResumeAnalysisController.java
    │   │           │   ├── ResumeBuilderController.java
    │   │           │   ├── ResumeController.java
    │   │           │   └── ResumeFeedbackController.java
    │   │           │
    │   │           ├── dto/
    │   │           │   ├── JobDTO.java
    │   │           │   ├── LoginRequest.java
    │   │           │   └── RegisterRequest.java
    │   │           │
    │   │           ├── entity/
    │   │           │   ├── Application.java
    │   │           │   ├── ApplicationStatus.java
    │   │           │   ├── AppliedJob.java
    │   │           │   ├── Job.java
    │   │           │   ├── JobStatus.java
    │   │           │   ├── MatchScore.java
    │   │           │   ├── Resume.java
    │   │           │   ├── Role.java
    │   │           │   └── User.java
    │   │           │
    │   │           ├── exception/
    │   │           │   └── GlobalExceptionHandler.java
    │   │           │
    │   │           ├── repository/
    │   │           │   ├── ApplicationRepository.java
    │   │           │   ├── AppliedJobRepository.java
    │   │           │   ├── JobRepository.java
    │   │           │   ├── MatchScoreRepository.java
    │   │           │   ├── ResumeRepository.java
    │   │           │   └── UserRepository.java
    │   │           │
    │   │           ├── service/
    │   │           │   ├── GeminiClient.java
    │   │           │   ├── JobService.java
    │   │           │   └── JobServiceImpl.java
    │   │           │
    │   │           └── util/
    │   │               └── JwtUtil.java
    │   │
    │   ├── resources/
    │   │   └── application.yaml
    │   │
    │   └── test/
    │       └── java/
    │           └── com/
    │               └── resumeapp/
    │                   ├── ResumeappApplicationTests.java
    │                   │
    │                   └── config/
    │                       ├── AiControllerFallbackTest.java
    │                       └── GeminiModelConfigTest.java
```

---

## 6. Prerequisites

### Required Software

- Flutter SDK
- Dart SDK
- Android Studio
- Android SDK
- Java JDK 17
- Maven
- PostgreSQL
- Git

### Required API Credentials

- Google Gemini API Key
- Adzuna Application ID
- Adzuna Application Key

---

## 7. Backend Setup

### Step 1: Extract Backend

Extract the `resumeapp-backend-main.zip` file.

### Step 2: Open Terminal

Navigate to the backend project directory.

```bash
cd resumeapp-backend-main
```

### Step 3: Configure Environment Variables

Configure the required database credentials and API keys in the backend environment or application configuration.

### Step 4: Run Backend

**Windows PowerShell:**

```powershell
.\mvnw.cmd spring-boot:run
```

**Linux/macOS:**

```bash
./mvnw spring-boot:run
```

### Backend URL

```text
http://localhost:8080
```

---

## 8. Mobile Application Setup

### Step 1: Extract Mobile Application

Extract the `resumeapp-mobile-main.zip` file.

### Step 2: Open Terminal

Navigate to the mobile application directory.

```bash
cd resumeapp-mobile-main
```

### Step 3: Install Dependencies

```bash
flutter pub get
```

### Step 4: Check Flutter Setup

```bash
flutter doctor
```

### Step 5: Run Application

```bash
flutter run
```

### Step 6: Build APK

```bash
flutter build apk --release
```

### APK Output

```text
build/app/outputs/flutter-apk/app-release.apk
```

---

## 9. Configuration

### Gemini Model Configuration

The backend supports an optional comma-separated Gemini model fallback order through:

```text
GEMINI_MODELS
```

### Mobile API Base URL

The API base URL is configured in:

```text
lib/api_service.dart
```

### Hosted Backend URL

```text
https://resumeapp-backend-uo3n.onrender.com/api
```

For local development, update the API URL according to the backend host accessible from the device or emulator.

---

## 10. API Overview

### Health Check

```text
/api/health
```

### Authentication

```text
/api/auth/login
/api/auth/register
```

### Jobs

```text
/api/jobs
```

### Match Scores

```text
/api/jobs/match-scores
```

### Job Match Details

```text
/api/jobs/{jobId}/match-detail
```

### Resume Upload

```text
/api/resume/upload
```

### Resume Analysis

```text
/api/resume/analysis
/api/resume/analysis/{resumeId}
```

### Resume Feedback

```text
/api/resume/feedback
```

### AI Chat

```text
/api/ai/chat
```

### Other Controller Groups

- Applied Jobs
- External Jobs
- Cover Letter
- AI Mentor
- Resume Builder
- Resume Feedback

Exact HTTP methods and request formats are available in the respective controller files.

---

## 11. Authentication and Security

The application uses JWT-based authentication.

### Authentication Flow

1. User registers.
2. User logs in.
3. Backend validates credentials.
4. Backend generates a JWT token.
5. Mobile app stores the token.
6. Token is included in protected API requests.

### Authorization

Protected API requests use JWT Bearer authentication.

### Security Features

- Spring Security
- JWT Authentication Filter
- Rate Limit Filter
- Global Exception Handler
- Environment-Based Configuration

---

## 12. Database

### Primary Database

PostgreSQL

### Additional Database Dependency

H2

### Database Technology

- Spring Data JPA
- Hibernate

### Main Entity Classes

- User
- Resume
- Job
- Application
- AppliedJob
- MatchScore
- Role
- ApplicationStatus
- JobStatus

### Database Configuration File

```text
src/main/resources/application.yaml
```

---

## 13. AI Integration

### AI Provider

Google Gemini API

### AI Functionalities

- Resume Analysis
- Resume Feedback
- Resume Improvement Suggestions
- AI Mentor Chat
- Cover Letter Generation
- Interview Preparation
- Career Roadmap Assistance

---

## 14. Testing

### Flutter Testing

Run Flutter tests using:

```bash
flutter test
```

### Backend Testing

**Windows:**

```powershell
.\mvnw.cmd test
```

**Linux/macOS:**

```bash
./mvnw test
```

### Backend Test Files

- ResumeappApplicationTests.java
- AiControllerFallbackTest.java
- GeminiModelConfigTest.java

---

## 15. Security

### Security Measures

- JWT Authentication
- Spring Security
- Rate Limiting
- Secure API Communication
- Environment-Based Configuration
- Global Exception Handling

### Important

Do not commit API keys, passwords, or JWT secrets to GitHub.

---


## 16. Output Screenshots

### Nexora Resume App Screenshots

![Nexora Screenshot 1](https://github.com/user-attachments/assets/ff670be9-0fbb-431b-a71a-6a66f466cf72)

![Nexora Screenshot 2](https://github.com/user-attachments/assets/fa1706a6-f151-42cf-8694-a43b5f3334f8)

![Nexora Screenshot 3](https://github.com/user-attachments/assets/550f881e-51d6-400a-a695-eb4e898c4a84)

![Nexora Screenshot 4](https://github.com/user-attachments/assets/c67a1e66-c452-4488-acef-51f4943a7a27)

![Nexora Screenshot 5](https://github.com/user-attachments/assets/087ee1ee-9e67-475e-9824-8805e5391a8b)

![Nexora Screenshot 6](https://github.com/user-attachments/assets/f7e82df0-93fa-4fa3-96d8-a88a17f2d3b7)

![Nexora Screenshot 7](https://github.com/user-attachments/assets/b22a35ea-0cf7-425e-b8c2-20c9f61d289f)

---

## 17. Future Enhancements

- Advanced AI Resume Optimization
- ATS Score Prediction
- Integration with More Job Portals
- Voice-Based AI Interview
- Real-Time Interview Analysis
- Additional Resume Templates
- Career Analytics Dashboard
- Personalized Job Recommendations
- Cloud Resume Storage
- Push Notifications
- Multi-Language Support

---

## 18. Conclusion

Nexora Resume App is an AI-powered career assistance platform that integrates resume management, job discovery, resume analysis, job matching, cover letter generation, and interview preparation into a single mobile application.

The project combines Flutter, Spring Boot, PostgreSQL, JWT Authentication, and Google Gemini AI to provide a scalable foundation for career development and job preparation.

---

**END OF README**
