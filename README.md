NEXORA RESUME APP
AI-POWERED RESUME AND CAREER PREPARATION APPLICATION

============================================================
1. PROJECT OVERVIEW
============================================================

Nexora Resume App is an AI-powered resume and career preparation application designed to help students and job seekers create professional resumes, analyze resume quality, discover job opportunities, match resumes with job descriptions, generate cover letters, and prepare for interviews using Artificial Intelligence.

The project consists of two separate repositories:

1. resumeapp-mobile-main
   Flutter-based mobile application.

2. resumeapp-backend-main
   Java Spring Boot backend REST API.

The mobile application communicates with the backend through REST APIs. The backend handles authentication, database operations, resume processing, job management, and AI integration.

============================================================
2. PROJECT FEATURES
============================================================

A. MOBILE APPLICATION FEATURES

1. User Registration
2. User Login
3. JWT Authentication
4. Dashboard
5. Resume Upload
6. Resume Analysis
7. Resume History
8. Resume Builder
9. Resume PDF Generation
10. Resume Sharing
11. AI Resume Feedback
12. Job Listings
13. External Job Search
14. Resume-to-Job Matching
15. Job Match Score
16. Match Details
17. AI Cover Letter Generator
18. AI Mentor Chat
19. AI Interview Preparation
20. Text-Based Interview
21. Interview Feedback
22. Personalized Learning Roadmap
23. Progress Tracking
24. Help and Support Screen

B. BACKEND FEATURES

1. REST API Development
2. User Authentication
3. User Registration and Login
4. JWT Authentication
5. Resume Management
6. Resume Analysis
7. Resume Feedback
8. Job Management
9. Applied Job Management
10. Application Management
11. Job Match Score Management
12. Google Gemini AI Integration
13. Adzuna Job API Integration
14. Cover Letter Generation
15. AI Mentor Services
16. Resume Builder API
17. Database Integration
18. Security Configuration
19. Rate Limiting
20. Global Exception Handling
21. PDF Document Processing
22. Office Document Processing

============================================================
3. TECHNOLOGY STACK
============================================================

FRONTEND:

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

BACKEND:

- Java 17
- Spring Boot
- Spring MVC
- Spring Security
- Spring Data JPA
- Hibernate
- JWT Authentication
- Maven

DATABASE:

- PostgreSQL
- H2 Database

AI INTEGRATION:

- Google Gemini API

DOCUMENT PROCESSING:

- Apache PDFBox
- Apache POI

DEVELOPMENT TOOLS:

- Android Studio
- Visual Studio Code
- IntelliJ IDEA
- Flutter SDK
- Git
- GitHub
- Maven

============================================================
4. PROJECT ARCHITECTURE
============================================================

Flutter Mobile Application
        |
        | REST API / HTTP / JSON
        | JWT Bearer Authentication
        |
        v
Spring Boot Backend
        |
        +---- Controllers
        |
        +---- Services
        |
        +---- Repositories
        |
        +---- Security Configuration
        |
        +---- JWT Authentication Filter
        |
        +---- Rate Limit Filter
        |
        +---- Global Exception Handler
        |
        v
Database
        |
        +---- PostgreSQL
        +---- H2
        |
        v
External Services
        |
        +---- Google Gemini API
        +---- Adzuna Job API

============================================================
5. COMPLETE PROJECT STRUCTURE
============================================================

A. FLUTTER MOBILE APPLICATION
   Repository: resumeapp-mobile-main

resumeapp-mobile-main/
|
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
|
├── assets/
│   └── icon.png
|
├── android/
│   ├── .gitignore
│   ├── build.gradle.kts
│   ├── gradle.properties
│   ├── settings.gradle.kts
│   |
│   ├── gradle/
│   │   └── wrapper/
│   │       └── gradle-wrapper.properties
│   |
│   └── app/
│       ├── build.gradle.kts
│       |
│       └── src/
│           ├── debug/
│           │   └── AndroidManifest.xml
│           |
│           ├── main/
│           │   ├── AndroidManifest.xml
│           │   |
│           │   ├── kotlin/
│           │   │   ├── com/
│           │   │   │   ├── example/
│           │   │   │   │   └── resumeapp_mobile/
│           │   │   │   │       └── MainActivity.kt
│           │   │   │   |
│           │   │   │   └── nexora/
│           │   │   │       └── resume/
│           │   │   │           └── MainActivity.kt
│           │   |
│           │   └── res/
│           │       ├── drawable/
│           │       │   └── launch_background.xml
│           │       |
│           │       ├── drawable-v21/
│           │       │   └── launch_background.xml
│           │       |
│           │       ├── mipmap-hdpi/
│           │       │   └── ic_launcher.png
│           │       |
│           │       ├── mipmap-mdpi/
│           │       │   └── ic_launcher.png
│           │       |
│           │       ├── mipmap-xhdpi/
│           │       │   └── ic_launcher.png
│           │       |
│           │       ├── mipmap-xxhdpi/
│           │       │   └── ic_launcher.png
│           │       |
│           │       ├── mipmap-xxxhdpi/
│           │       │   └── ic_launcher.png
│           │       |
│           │       ├── values/
│           │       │   └── styles.xml
│           │       |
│           │       └── values-night/
│           │           └── styles.xml
│           |
│           └── profile/
│               └── AndroidManifest.xml
|
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
|
├── test/
│   └── widget_test.dart
|
├── web/
│   ├── favicon.png
│   ├── index.html
│   ├── manifest.json
│   |
│   └── icons/
│       ├── Icon-192.png
│       ├── Icon-512.png
│       ├── Icon-maskable-192.png
│       └── Icon-maskable-512.png
|
├── linux/
│   ├── .gitignore
│   ├── CMakeLists.txt
│   |
│   ├── flutter/
│   │   ├── CMakeLists.txt
│   │   ├── generated_plugin_registrant.cc
│   │   ├── generated_plugin_registrant.h
│   │   └── generated_plugins.cmake
│   |
│   └── runner/
│       ├── CMakeLists.txt
│       ├── main.cc
│       ├── my_application.cc
│       └── my_application.h
|
└── windows/
    ├── .gitignore
    ├── CMakeLists.txt
    |
    ├── flutter/
    │   ├── CMakeLists.txt
    │   ├── generated_plugin_registrant.cc
    │   ├── generated_plugin_registrant.h
    │   └── generated_plugins.cmake
    |
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
        |
        └── resources/
            └── app_icon.ico


B. SPRING BOOT BACKEND
   Repository: resumeapp-backend-main

resumeapp-backend-main/
|
├── .gitattributes
├── .gitignore
├── Dockerfile
├── mvnw
├── mvnw.cmd
├── pom.xml
|
├── .mvn/
│   └── wrapper/
│       └── maven-wrapper.properties
|
└── src/
    |
    ├── main/
    │   |
    │   ├── java/
    │   │   |
    │   │   └── com/
    │   │       └── resumeapp/
    │   │           |
    │   │           ├── ResumeappApplication.java
    │   │           |
    │   │           ├── config/
    │   │           │   ├── AiController.java
    │   │           │   ├── AppConfig.java
    │   │           │   ├── GeminiModelConfig.java
    │   │           │   ├── JwtAuthenticationFilter.java
    │   │           │   ├── RateLimitFilter.java
    │   │           │   └── SecurityConfig.java
    │   │           |
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
    │   │           |
    │   │           ├── dto/
    │   │           │   ├── JobDTO.java
    │   │           │   ├── LoginRequest.java
    │   │           │   └── RegisterRequest.java
    │   │           |
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
    │   │           |
    │   │           ├── exception/
    │   │           │   └── GlobalExceptionHandler.java
    │   │           |
    │   │           ├── repository/
    │   │           │   ├── ApplicationRepository.java
    │   │           │   ├── AppliedJobRepository.java
    │   │           │   ├── JobRepository.java
    │   │           │   ├── MatchScoreRepository.java
    │   │           │   ├── ResumeRepository.java
    │   │           │   └── UserRepository.java
    │   │           |
    │   │           ├── service/
    │   │           │   ├── GeminiClient.java
    │   │           │   ├── JobService.java
    │   │           │   └── JobServiceImpl.java
    │   │           |
    │   │           └── util/
    │   │               └── JwtUtil.java
    │   |
    │   ├── resources/
    │   │   └── application.yaml
    │   |
    │   └── test/
    │       └── java/
    │           └── com/
    │               └── resumeapp/
    │                   ├── ResumeappApplicationTests.java
    │                   |
    │                   └── config/
    │                       ├── AiControllerFallbackTest.java
    │                       └── GeminiModelConfigTest.java


============================================================
6. PREREQUISITES
============================================================

Required Software:

- Flutter SDK
- Dart SDK
- Android Studio
- Android SDK
- Java JDK 17
- Maven
- PostgreSQL
- Git

Required API Credentials:

- Google Gemini API Key
- Adzuna Application ID
- Adzuna Application Key

============================================================
7. BACKEND SETUP
============================================================

STEP 1:
Extract resumeapp-backend-main.zip.

STEP 2:
Open terminal in backend project directory.

Command:

cd resumeapp-backend-main

STEP 3:
Configure environment variables.

STEP 4:
Run backend.

Windows PowerShell:

.\mvnw.cmd spring-boot:run

Linux/macOS:

./mvnw spring-boot:run

Backend URL:

http://localhost:8080

============================================================
8. MOBILE APPLICATION SETUP
============================================================

STEP 1:
Extract resumeapp-mobile-main.zip.

STEP 2:
Open terminal in mobile project directory.

Command:

cd resumeapp-mobile-main

STEP 3:
Install dependencies.

flutter pub get

STEP 4:
Check Flutter setup.

flutter doctor

STEP 5:
Run application.

flutter run

STEP 6:
Build APK.

flutter build apk --release

APK OUTPUT:

build/app/outputs/flutter-apk/app-release.apk

============================================================
9. CONFIGURATION
============================================================


GEMINI_MODELS
Optional comma-separated Gemini model fallback order.


MOBILE API BASE URL:

Configured in:

lib/api_service.dart

Hosted backend URL:

https://resumeapp-backend-uo3n.onrender.com/api

For local development, update the URL according to the backend host accessible from the device/emulator.

============================================================
10. API OVERVIEW
============================================================

Health Check:

/api/health

Authentication:

/api/auth/login
/api/auth/register

Jobs:

/api/jobs

Match Scores:

/api/jobs/match-scores

Job Match Details:

/api/jobs/{jobId}/match-detail

Resume Upload:

/api/resume/upload

Resume Analysis:

/api/resume/analysis
/api/resume/analysis/{resumeId}

/api/resume/feedback

AI Chat:

/api/ai/chat

Other Controller Groups:

- Applied Jobs
- External Jobs
- Cover Letter
- AI Mentor
- Resume Builder
- Resume Feedback

Exact HTTP methods and request formats are available in the respective controller files.

============================================================
11. AUTHENTICATION AND SECURITY
============================================================

The application uses JWT-based authentication.

Authentication Flow:

1. User registers.
2. User logs in.
3. Backend validates credentials.
4. Backend generates JWT token.
5. Mobile app stores the token.
6. Token is included in protected API requests.

Authorization Header:

Security Features:

- Spring Security
- JWT Authentication Filter
- Rate Limit Filter
- Global Exception Handler
- Environment-Based Configuration

============================================================
12. DATABASE
============================================================

Primary Database:

PostgreSQL

Additional Database Dependency:

H2

Database Technology:

Spring Data JPA
Hibernate

Main Entity Classes:

- User
- Resume
- Job
- Application
- AppliedJob
- MatchScore
- Role
- ApplicationStatus
- JobStatus

Database Configuration File:

src/main/resources/application.yaml

============================================================
13. AI INTEGRATION
============================================================

AI Provider:

Google Gemini API

AI Functionalities:

- Resume Analysis
- Resume Feedback
- Resume Improvement Suggestions
- AI Mentor Chat
- Cover Letter Generation
- Interview Preparation
- Career Roadmap Assistance

============================================================
14. TESTING
============================================================

FLUTTER TESTING:

Command:

flutter test

BACKEND TESTING:

Windows:

.\mvnw.cmd test

Linux/macOS:

./mvnw test

Backend Test Files:

- ResumeappApplicationTests.java
- AiControllerFallbackTest.java
- GeminiModelConfigTest.java

============================================================
15. SECURITY
============================================================

Security Measures:

- JWT Authentication
- Spring Security
- Rate Limiting
- Secure API Communication
- Environment-Based Configuration
- Global Exception Handling

Important:

Do not commit API keys, passwords, or JWT secrets to GitHub.

============================================================
16. FUTURE ENHANCEMENTS
============================================================

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

- OUTPUT SCREENSHOTS
- <img width="732" height="1600" alt="Nexora1 jpg" src="https://github.com/user-attachments/assets/ff670be9-0fbb-431b-a71a-6a66f466cf72" />
<img width="732" height="1600" alt="nexora2 jpg" src="https://github.com/user-attachments/assets/fa1706a6-f151-42cf-8694-a43b5f3334f8" />
<img width="732" height="1600" alt="Nexora3 jpg" src="https://github.com/user-attachments/assets/550f881e-51d6-400a-a695-eb4e898c4a84" />
<img width="732" height="1600" alt="Nexora4 jpg" src="https://github.com/user-attachments/assets/c67a1e66-c452-4488-acef-51f4943a7a27" />
<img width="732" height="1600" alt="Nexora5 jpg" src="https://github.com/user-attachments/assets/087ee1ee-9e67-475e-9824-8805e5391a8b" />
<img width="732" height="1600" alt="Nexora6 jpg" src="https://github.com/user-attachments/assets/f7e82df0-93fa-4fa3-96d8-a88a17f2d3b7" />
<img width="732" height="1600" alt="nexora7 jpg" src="https://github.com/user-attachments/assets/b22a35ea-0cf7-425e-b8c2-20c9f61d289f" />


============================================================
17. CONCLUSION
============================================================

Nexora Resume App is an AI-powered career assistance platform that integrates resume management, job discovery, resume analysis, job matching, cover letter generation, and interview preparation into a single mobile application.

The project combines Flutter, Spring Boot, PostgreSQL, JWT Authentication, and Google Gemini AI to provide a scalable foundation for career development and job preparation.

============================================================
END OF README
============================================================
