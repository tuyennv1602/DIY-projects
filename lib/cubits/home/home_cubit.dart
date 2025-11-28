import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kstudio/models/project.dart';
import 'package:kstudio/models/tag.dart';
import 'package:kstudio/services/firestore_service.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final FirestoreService _firestoreService;

  HomeCubit(this._firestoreService) : super(const HomeState());

  Future<void> loadProjects() async {
    emit(state.copyWith(isLoading: true));
    try {
      final projects = await _firestoreService.fetchProjects();
      emit(state.copyWith(projects: projects, isLoading: false, error: null));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> loadTags() async {
    try {
      final tags = await _firestoreService.fetchTags();
      emit(state.copyWith(tags: tags));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> searchProjects(String query) async {
    if (query.isEmpty) {
      emit(state.copyWith(searchResults: state.projects, searchKey: query));
      return;
    }
    emit(
      state.copyWith(
        searchResults: List.from(
          state.projects.where(
            (e) =>
                e.title.toLowerCase().contains(query.toLowerCase()) ||
                e.description.toLowerCase().contains(query.toLowerCase()),
          ),
        ),
        searchKey: query,
      ),
    );
  }

  void addTagFilter(String tag) {
    if (!state.selectedTags.contains(tag)) {
      emit(state.copyWith(selectedTags: [...state.selectedTags, tag]));
      _applyFilters();
    }
  }

  void removeTagFilter(String tag) {
    if (state.selectedTags.contains(tag)) {
      emit(
        state.copyWith(
          selectedTags: state.selectedTags.where((t) => t != tag).toList(),
        ),
      );
      _applyFilters();
    }
  }

  void clearFilters() {
    emit(state.copyWith(selectedTags: [], searchResults: state.projects));
  }

  void _applyFilters() {
    List<Project> filtered = state.projects;
    if (state.selectedTags.isNotEmpty) {
      filtered = filtered.where((project) {
        return state.selectedTags.any((tag) => project.tags.contains(tag));
      }).toList();
    }
    emit(state.copyWith(searchResults: filtered));
  }
}
