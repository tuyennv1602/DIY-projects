import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kstudio/cubits/home/home_cubit.dart';
import 'package:kstudio/models/tag.dart';
import 'package:kstudio/utils/context_extension.dart';
import 'package:kstudio/widgets/search_bar.dart' as custom_search;

class HomeBar extends StatelessWidget {
  const HomeBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: context.isMobile ? 16 : 32,
        horizontal: context.isMobile ? 16 : 32,
      ),
      child: switch (context.isMobile) {
        true => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) {
                return SingleChildScrollView(
                  clipBehavior: Clip.none,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...state.tags.map((tag) {
                        final isSelected = state.selectedTags.contains(
                          tag.name,
                        );
                        return _MainTags(tag: tag, isSelected: isSelected);
                      }),
                    ],
                  ),
                );
              },
            ),
            SizedBox(
              width: double.infinity,
              child: custom_search.ProjectSearchBar(
                onChanged: (query) {
                  context.read<HomeCubit>().searchProjects(query);
                },
              ),
            ),
          ],
        ),
        false => Row(
          spacing: 16,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: BlocBuilder<HomeCubit, HomeState>(
                builder: (context, state) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Tag Chips with beautiful styling
                        ...state.tags.map((tag) {
                          final isSelected = state.selectedTags.contains(
                            tag.name,
                          );
                          return _MainTags(tag: tag, isSelected: isSelected);
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Search Bar
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                constraints: BoxConstraints(maxWidth: 400),
                child: custom_search.ProjectSearchBar(
                  onChanged: (query) {
                    context.read<HomeCubit>().searchProjects(query);
                  },
                ),
              ),
            ),
          ],
        ),
      },
    );
  }
}

class _MainTags extends StatelessWidget {
  final Tag tag;
  final bool isSelected;
  const _MainTags({required this.tag, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignCenter,
                )
              : Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.2),
                  width: 1,
                ),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (isSelected) {
                context.read<HomeCubit>().removeTagFilter(tag.name);
              } else {
                context.read<HomeCubit>().addTagFilter(tag.name);
              }
            },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text(
                tag.name,
                style: TextStyle(
                  fontSize: context.isMobile ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
