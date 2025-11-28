import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:kstudio/models/project.dart';
import 'package:kstudio/models/tag.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Project>> fetchProjects() async {
    try {
      final snapshot = await _firestore
          .collection('projects')
          .where('is_beta', isEqualTo: kDebugMode ? null : false)
          .get();
      return snapshot.docs.map((doc) {
        return Project.fromFirestore(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching projects: $e');
      }
      return [];
    }
  }

  Future<List<Project>> fetchHighlightProjects() async {
    try {
      final snapshot = await _firestore
          .collection('projects')
          .where('highlight', isEqualTo: true)
          .get();
      return snapshot.docs
          .map((doc) => Project.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching highlight projects: $e');
      }
      return [];
    }
  }

  Future<Project?> fetchProjectById(String id) async {
    try {
      final doc = await _firestore.collection('projects').doc(id).get();
      if (doc.exists) {
        return Project.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching project: $e');
      }
      return null;
    }
  }

  Future<Project?> fetchProjectByKey(String key) async {
    try {
      final snapshot = await _firestore
          .collection('projects')
          .where('key', isEqualTo: key)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return Project.fromFirestore(
          snapshot.docs.first.data(),
          snapshot.docs.first.id,
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching project by key: $e');
      }
      return null;
    }
  }

  Future<List<Tag>> fetchTags() async {
    try {
      final snapshot = await _firestore
          .collection('tags')
          .orderBy('index')
          .get();
      return snapshot.docs.map((doc) => Tag.fromMap(doc.data())).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching tags: $e');
      }
      return [];
    }
  }

  Future<List<Project>> searchProjects(String query) async {
    try {
      final allProjects = await fetchProjects();
      final lowerQuery = query.toLowerCase();
      return allProjects.where((project) {
        return project.title.toLowerCase().contains(lowerQuery) ||
            project.description.toLowerCase().contains(lowerQuery) ||
            project.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error searching projects: $e');
      }
      return [];
    }
  }
}
