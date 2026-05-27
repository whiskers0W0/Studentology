import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:studentology/models/exam_model.dart';
import 'package:studentology/models/grade_model.dart';
import 'package:studentology/models/schedule_model.dart';
import 'package:studentology/models/subject_model.dart';
import 'package:studentology/models/task_model.dart';
import 'package:studentology/models/thesis_idea_model.dart';
import 'package:studentology/models/user_model.dart';

// ── Suggested Firestore Security Rules ──────────────────────────────────────
//
// Paste these into Firebase Console → Firestore → Rules, then Publish.
//
// rules_version = '2';
// service cloud.firestore {
//   match /databases/{database}/documents {
//
//     // Users may only read and write their own profile document.
//     match /users/{userId} {
//       allow read, write: if request.auth != null && request.auth.uid == userId;
//
//       // All subcollections (subjects, tasks, exams, grades, thesisIdeas)
//       // are equally guarded: only the owning user may access them.
//       match /{collection}/{docId} {
//         allow read, write: if request.auth != null && request.auth.uid == userId;
//       }
//     }
//   }
// }
//
// ── Index requirements ──────────────────────────────────────────────────────
// Firestore auto-creates single-field indexes. The compound queries below
// require manual composite indexes (Firebase Console → Firestore → Indexes):
//
//   Collection     Fields ordered                Needed by
//   ──────────── ─────────────────────────────── ────────────────────────────
//   thesisIdeas  isSaved ASC, generatedAt DESC   streamThesisIdeas()
//
// All other orderBy() calls use a single field so no composite index needed.
// ────────────────────────────────────────────────────────────────────────────

// All user data lives under /users/{userId}/<collection>/{docId}.
// This keeps every read/write strictly scoped to the authenticated user and
// avoids needing composite Firestore indexes for userId filters.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Internal path helpers ────────────────────────────────────────────────

  DocumentReference _userDoc(String userId) =>
      _db.collection('users').doc(userId);

  CollectionReference _sub(String userId, String collection) =>
      _userDoc(userId).collection(collection);

  // ── Generic CRUD (subcollection-scoped to userId) ────────────────────────

  /// Adds [data] to [collection] under this user. Returns the new document id.
  Future<String> addDocument(
    String collection,
    String userId,
    Map<String, dynamic> data,
  ) async {
    final ref = await _sub(userId, collection).add(data);
    return ref.id;
  }

  /// Merges [data] into an existing document (non-destructive update).
  Future<void> updateDocument(
    String collection,
    String userId,
    String id,
    Map<String, dynamic> data,
  ) =>
      _sub(userId, collection).doc(id).update(data);

  /// Deletes a document from the user's subcollection.
  Future<void> deleteDocument(String collection, String userId, String id) =>
      _sub(userId, collection).doc(id).delete();

  /// Returns a stream of raw maps from the user's [collection].
  /// Documents are not ordered here — callers sort in the provider layer.
  Stream<List<Map<String, dynamic>>> getDocuments(
    String collection,
    String userId,
  ) =>
      _sub(userId, collection).snapshots().map(
            (snap) => snap.docs
                .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
                .toList(),
          );

  // ── User ────────────────────────────────────────────────────────────────

  Future<UserModel?> getUser(String userId) async {
    final doc = await _userDoc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data() as Map<String, dynamic>, userId);
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) =>
      _userDoc(userId).update(data);

  // ── Schedules ────────────────────────────────────────────────────────────

  Stream<List<ScheduleModel>> streamSchedules(String userId) =>
      _sub(userId, 'schedules')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => ScheduleModel.fromMap(
                  d.data() as Map<String, dynamic>, d.id))
              .toList());

  Future<String> addSchedule(String userId, Map<String, dynamic> data) =>
      addDocument('schedules', userId, data);

  Future<void> updateSchedule(
          String userId, String scheduleId, Map<String, dynamic> data) =>
      updateDocument('schedules', userId, scheduleId, data);

  Future<void> deleteSchedule(String userId, String scheduleId) =>
      deleteDocument('schedules', userId, scheduleId);

  // ── Subjects ────────────────────────────────────────────────────────────

  Stream<List<SubjectModel>> streamSubjects(String userId) =>
      _sub(userId, 'subjects').snapshots().map(
            (snap) => snap.docs
                .map((d) =>
                    SubjectModel.fromMap(d.data() as Map<String, dynamic>, d.id))
                .toList(),
          );

  Future<String> addSubject(String userId, Map<String, dynamic> data) =>
      addDocument('subjects', userId, data);

  Future<void> updateSubject(
          String userId, String subjectId, Map<String, dynamic> data) =>
      updateDocument('subjects', userId, subjectId, data);

  Future<void> deleteSubject(String userId, String subjectId) =>
      deleteDocument('subjects', userId, subjectId);

  // ── Tasks ────────────────────────────────────────────────────────────────

  /// Ordered by [dueDate] ascending so the provider receives a pre-sorted list.
  Stream<List<TaskModel>> streamTasks(String userId) =>
      _sub(userId, 'tasks')
          .orderBy('dueDate', descending: false)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((d) =>
                    TaskModel.fromMap(d.data() as Map<String, dynamic>, d.id))
                .toList(),
          );

  Future<String> addTask(String userId, Map<String, dynamic> data) =>
      addDocument('tasks', userId, data);

  Future<void> updateTask(
          String userId, String taskId, Map<String, dynamic> data) =>
      updateDocument('tasks', userId, taskId, data);

  Future<void> deleteTask(String userId, String taskId) =>
      deleteDocument('tasks', userId, taskId);

  // ── Exams ────────────────────────────────────────────────────────────────

  /// Ordered by [examDate] ascending (soonest first).
  Stream<List<ExamModel>> streamExams(String userId) =>
      _sub(userId, 'exams')
          .orderBy('examDate', descending: false)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((d) =>
                    ExamModel.fromMap(d.data() as Map<String, dynamic>, d.id))
                .toList(),
          );

  Future<String> addExam(String userId, Map<String, dynamic> data) =>
      addDocument('exams', userId, data);

  Future<void> updateExam(
          String userId, String examId, Map<String, dynamic> data) =>
      updateDocument('exams', userId, examId, data);

  Future<void> deleteExam(String userId, String examId) =>
      deleteDocument('exams', userId, examId);

  // ── Grades ───────────────────────────────────────────────────────────────

  /// Ordered by [createdAt] ascending to preserve entry order within a term.
  Stream<List<GradeModel>> streamGrades(String userId) =>
      _sub(userId, 'grades')
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((d) =>
                    GradeModel.fromMap(d.data() as Map<String, dynamic>, d.id))
                .toList(),
          );

  Future<String> addGrade(String userId, Map<String, dynamic> data) =>
      addDocument('grades', userId, data);

  Future<void> deleteGrade(String userId, String gradeId) =>
      deleteDocument('grades', userId, gradeId);

  // ── Thesis ideas ─────────────────────────────────────────────────────────

  /// Streams only saved ideas ([isSaved] == true), ordered by [generatedAt] descending.
  Stream<List<ThesisIdeaModel>> streamThesisIdeas(String userId) =>
      _sub(userId, 'thesisIdeas')
          .where('isSaved', isEqualTo: true)
          .orderBy('generatedAt', descending: true)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((d) => ThesisIdeaModel.fromMap(
                    d.data() as Map<String, dynamic>, d.id))
                .toList(),
          );

  Future<void> saveThesisIdea(
          String userId, String ideaId, Map<String, dynamic> data) =>
      _sub(userId, 'thesisIdeas').doc(ideaId).set(data, SetOptions(merge: true));

  Future<void> deleteThesisIdea(String userId, String ideaId) =>
      deleteDocument('thesisIdeas', userId, ideaId);
}
