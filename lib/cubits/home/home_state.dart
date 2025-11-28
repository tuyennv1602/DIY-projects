part of 'home_cubit.dart';

class HomeState extends Equatable {
  final List<Project> projects;
  final List<Banner> banners;
  final List<Project> searchResults;
  final List<String> selectedTags;
  final bool isLoading;
  final String? error;
  final List<Tag> tags;
  final String? searchKey;

  const HomeState({
    this.projects = const [],
    this.banners = const [],
    this.searchResults = const [],
    this.selectedTags = const [],
    this.isLoading = false,
    this.error,
    this.searchKey,
    this.tags = const [],
  });

  HomeState copyWith({
    List<Project>? projects,
    List<Project>? searchResults,
    List<String>? selectedTags,
    bool? isLoading,
    String? error,
    List<Tag>? tags,
    List<Banner>? banners,
    String? searchKey,
  }) {
    return HomeState(
      projects: projects ?? this.projects,
      searchResults: searchResults ?? this.searchResults,
      selectedTags: selectedTags ?? this.selectedTags,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      tags: tags ?? this.tags,
      banners: banners ?? this.banners,
      searchKey: searchKey ?? this.searchKey,
    );
  }

  bool get hasFilter =>
      selectedTags.isNotEmpty || (searchKey?.isNotEmpty ?? false);

  @override
  List<Object?> get props => [
    projects,
    banners,
    searchResults,
    selectedTags,
    isLoading,
    error,
    tags,
    searchKey,
  ];
}
