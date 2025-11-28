import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kstudio/cubits/home/home_cubit.dart';
import 'package:kstudio/utils/context_extension.dart';
import 'package:kstudio/widgets/app_header.dart';
import 'package:kstudio/widgets/footer.dart';
import 'package:kstudio/widgets/home_bar.dart';
import 'package:kstudio/widgets/project_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeCubit>()
        ..loadTags()
        ..loadProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple.shade900.withAlpha(100),
                    Colors.blue.shade900.withAlpha(100),
                  ],
                ),
              ),
            ),
          ),
          Column(
            children: [
              const AppHeader(),
              HomeBar(),
              Expanded(
                child: BlocBuilder<HomeCubit, HomeState>(
                  builder: (context, state) {
                    final projects = state.hasFilter
                        ? state.searchResults
                        : state.projects;
                    return CustomScrollView(
                      slivers: [
                        if (state.isLoading == true)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 100,
                              ),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          )
                        else if (projects.isEmpty)
                          SliverToBoxAdapter(child: EmptyProject())
                        else
                          SliverToBoxAdapter(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final width = constraints.maxWidth;
                                final crossAxisCount = switch (width) {
                                  < 600 => 1,
                                  < 800 => 2,
                                  < 1200 => 3,
                                  _ => 4,
                                };
                                final cardHeight = switch (width) {
                                  < 600 => 360.0,
                                  < 800 => 380.0,
                                  < 1200 => 400.0,
                                  _ => 450.0,
                                };
                                final itemWidth =
                                    (width - (isMobile ? 16 : 32) * 2) /
                                    crossAxisCount;
                                final aspectRatio = itemWidth / cardHeight;
                                return GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 16 : 32,
                                  ),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        mainAxisSpacing: 16,
                                        crossAxisSpacing: 16,
                                        childAspectRatio: aspectRatio,
                                      ),
                                  itemBuilder: (_, index) {
                                    return ProjectCard(
                                      project: projects[index],
                                      cardHeight: cardHeight,
                                    );
                                  },
                                  itemCount: projects.length,
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const Footer(),
            ],
          ),
        ],
      ),
    );
  }
}

class EmptyProject extends StatelessWidget {
  const EmptyProject({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No projects found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
