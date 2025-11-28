import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:kstudio/models/project.dart';
import 'package:kstudio/services/firestore_service.dart';
import 'package:kstudio/utils/context_extension.dart';
import 'package:kstudio/widgets/tag_chip.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_html/flutter_html.dart';

class ProjectDetailPage extends StatefulWidget {
  final String projectKey;

  const ProjectDetailPage({super.key, required this.projectKey});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  late Future<Project?> _projectFuture;
  final ScrollController _sectionsScrollController = ScrollController();
  String? _selectedSection;

  @override
  void initState() {
    super.initState();
    final firestoreService = GetIt.instance<FirestoreService>();
    _projectFuture = firestoreService.fetchProjectByKey(widget.projectKey);
  }

  @override
  void dispose() {
    _sectionsScrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(GlobalKey key, String name) {
    setState(() => _selectedSection = name);
    Scrollable.ensureVisible(key.currentContext!);
    // Optional: add smooth scroll animation here
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      body: FutureBuilder<Project?>(
        future: _projectFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading project',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
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
                    'Project not found',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          final project = snapshot.data!;

          if (isMobile) {
            return _buildMobileLayout(context, project);
          } else {
            return _buildDesktopLayout(context, project);
          }
        },
      ),
    );
  }

  // Desktop Layout (2-column)
  Widget _buildDesktopLayout(BuildContext context, Project project) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSectionsContent(context, project),
            ),
          ),
        ),
        Expanded(child: _buildProjectSummary(context, project)),
      ],
    );
  }

  // Mobile Layout (stacked)
  Widget _buildMobileLayout(BuildContext context, Project project) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildProjectSummary(context, project),
          const Divider(height: 32),
          _buildSectionsContent(context, project),
        ],
      ),
    );
  }

  // Project Summary Widget
  Widget _buildProjectSummary(BuildContext context, Project project) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: context.isMobile
            ? null
            : Border(
                left: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
                  width: 4,
                ),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: project.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 200,
              placeholder: (context, url) => Container(
                color: Theme.of(context).colorScheme.surface,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: Theme.of(context).colorScheme.surface,
                child: const Icon(Icons.image_not_supported),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Title
          Text(
            project.title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // Description
          Text(
            project.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          // Tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: project.tags.map((tag) => TagChip(label: tag)).toList(),
          ),
          const SizedBox(height: 16),
          // Version & Date
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.tag,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'v${project.versionName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Updated ${Jiffy.parseFromDateTime(project.lastUpdated).fromNow()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionsContent(BuildContext context, Project project) {
    final sections = project.sections;
    List<({GlobalKey key, String name, dynamic value})> sectionTags = [
      if (sections.overview?.isNotEmpty ?? false)
        (
          key: GlobalKey(debugLabel: 'Overview'),
          name: 'Overview',
          value: sections.overview,
        ),
      if (sections.demo?.isNotEmpty ?? false)
        (
          key: GlobalKey(debugLabel: 'Demo'),
          name: 'Demo',
          value: sections.demo,
        ),
      if (sections.guide?.isNotEmpty ?? false)
        (
          key: GlobalKey(debugLabel: 'Assembly Guide'),
          name: 'Assembly Guide',
          value: sections.guide,
        ),
      if (sections.firmwares != null && sections.firmwares!.isNotEmpty)
        (
          key: GlobalKey(debugLabel: 'Firmware'),
          name: 'Firmware',
          value: sections.firmwares,
        ),
      if (sections.printFile?.isNotEmpty ?? false)
        (
          key: GlobalKey(debugLabel: '3D Model'),
          name: '3D Model',
          value: sections.printFile,
        ),
      if (sections.accessory?.isNotEmpty ?? false)
        (
          key: GlobalKey(debugLabel: 'Accessory'),
          name: 'Accessory',
          value: sections.accessory,
        ),
    ].toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sectionTags.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(24),
            child: _buildSectionNavigation(context, sectionTags),
          ),
        ],
        if (sectionTags.isNotEmpty)
          ...sectionTags.map(
            (e) => Section(key: e.key, value: e.value, name: e.name),
          ),
        const SizedBox(height: 32),
      ],
    );
  }

  // Section Navigation Tabs
  Widget _buildSectionNavigation(
    BuildContext context,
    List<({GlobalKey key, String name, dynamic value})> tags,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tags.map((item) {
          final isSelected =
              _selectedSection == item.name ||
              (_selectedSection == null && item == tags.first);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_formatSectionName(item.name)),
              selected: isSelected,
              onSelected: (_) => _scrollToSection(item.key, item.name),
              backgroundColor: isSelected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                  : null,
              selectedColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.2),
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.2),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatSectionName(String key) {
    return key
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

class Section extends StatefulWidget {
  final dynamic value;
  final String name;
  const Section({super.key, required this.value, required this.name});

  @override
  State<Section> createState() => _SectionState();
}

class _SectionState extends State<Section> {
  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      maintainState: true,
      initiallyExpanded: true,
      shape: RoundedRectangleBorder(),
      tilePadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      childrenPadding: EdgeInsets.symmetric(
        horizontal: context.isMobile ? 8 : 16,
      ),
      title: Text(
        widget.name,
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      children: [
        if (widget.value is String)
          Html(
            data: widget.value,
            style: {
              "p": Style(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: FontSize(16),
                whiteSpace: WhiteSpace.pre,
              ),
              "h3": Style(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: FontSize(18),
                whiteSpace: WhiteSpace.pre,
              ),
            },
          ),
        if (widget.value is List<Firmware>)
          _FirmwareList(firmwares: widget.value),
      ],
    );
  }
}

class _FirmwareList extends StatefulWidget {
  final List<Firmware> firmwares;
  const _FirmwareList({required this.firmwares});

  @override
  State<_FirmwareList> createState() => _FirmwareListState();
}

class _FirmwareListState extends State<_FirmwareList> {
  List<Firmware> get firmwares => widget.firmwares;
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.only(left: 16),
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, index) {
        return ExpansionTile(
          maintainState: true,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          expandedAlignment: Alignment.centerLeft,
          childrenPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              width: 1,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              width: 1,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.2),
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'v${firmwares[index].versionName}',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(fontSize: 20),
              ),
              Text(
                Jiffy.parseFromDateTime(
                  firmwares[index].updatedAt,
                ).format(pattern: 'MMM d, yyyy hh:MM a'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          children: [
            Align(
              alignment: AlignmentGeometry.centerLeft,
              child: IconButton(
                onPressed: () {},
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith(
                    (_) => Theme.of(context).colorScheme.primary,
                  ),
                  side: WidgetStateBorderSide.resolveWith(
                    (_) => BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                icon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    spacing: 8,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download),
                      Text(
                        'Install firmware',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('#Changelog', style: Theme.of(context).textTheme.bodyLarge),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(firmwares[index].changeLogs),
            ),
          ],
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: firmwares.length,
    );
  }
}
