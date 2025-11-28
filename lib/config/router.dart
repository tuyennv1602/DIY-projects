import 'package:go_router/go_router.dart';
import 'package:kstudio/pages/home_page.dart';
import 'package:kstudio/pages/project_detail_page.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/project/:key',
      name: 'project-detail',
      builder: (context, state) {
        final key = state.pathParameters['key'] ?? '';
        return ProjectDetailPage(projectKey: key);
      },
    ),
  ],
);
