// Services Layer Unified Export
library;

// Core Infrastructure & Authentication
export 'auth_service.dart';
export 'firebase_auth_service.dart';
export 'firebase_service.dart';
export 'firebase_firestore_service.dart';
export 'supabase_service.dart';
export 'storage_service.dart';
export 'user_service.dart';
export 'database_seeder.dart';

// User & Role Domain Services
export 'student_service.dart';
export 'staff_service.dart';
export 'admin_service.dart';
export 'parent_service.dart';
export 'department_service.dart';
export 'institution_service.dart';

// Hackathon Engine & Loggers
export 'hackathon_service.dart';
export 'hackathon_banner_service.dart';
export 'hackathon_activity_logger.dart';
export 'hackathon_reminder_engine.dart';

// Notification Subsystem & Schedulers
export 'notification_service.dart';
export 'notification_engine.dart';
export 'notification_scheduler_service.dart';
export 'notification_automation_rules_service.dart';
export 'notification_duplicate_preventer.dart';

// Academic & Examination Services
export 'academic_schedule_service.dart';
export 'syllabus_service.dart';
export 'question_paper_service.dart';
export 'exam_service.dart';
export 'assignment_service.dart';
export 'task_service.dart';

// Certifications, Portfolio & Profiles
export 'nptel_service.dart';
export 'certification_service.dart';
export 'resume_service.dart';
export 'resume_pdf_service.dart';
export 'gallery_service.dart';
export 'announcement_service.dart';
export 'activity_log_service.dart';
export 'leetcode_service.dart';
export 'github_service.dart';
export 'linkedin_service.dart';
