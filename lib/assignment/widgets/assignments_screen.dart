import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cached/flutter_cached.dart';
import 'package:schulcloud/app/app.dart';
import 'package:schulcloud/assignment/assignment.dart';
import 'package:schulcloud/course/course.dart';
import 'package:time_machine/time_machine.dart';

import '../data.dart';

class AssignmentsScreen extends SortFilterWidget<Assignment> {
  AssignmentsScreen({
    SortFilterSelection<Assignment> sortFilterSelection,
  }) : super(sortFilterSelection ?? sortFilterConfig.defaultSelection);

  static final sortFilterConfig = SortFilter<Assignment>(
    sorters: {
      'createdAt': Sorter<Assignment>.simple(
        (s) => s.general_entity_property_createdAt,
        selector: (assignment) => assignment.createdAt,
      ),
      'updatedAt': Sorter<Assignment>.simple(
        (s) => s.general_entity_property_updatedAt,
        selector: (assignment) => assignment.updatedAt,
      ),
      'availableAt': Sorter<Assignment>.simple(
        (s) => s.assignment_assignment_property_availableAt,
        webQueryKey: 'availableDate',
        selector: (assignment) => assignment.availableAt,
      ),
      'dueAt': Sorter<Assignment>.simple(
        (s) => s.assignment_assignment_property_dueAt,
        selector: (assignment) => assignment.dueAt,
      ),
    },
    defaultSorter: 'dueAt',
    filters: {
      'dueAt': DateRangeFilter<Assignment>(
        (s) => s.assignment_assignment_property_dueAt,
        webQueryKey: 'dueDate',
        selector: (assignment) => assignment.dueAt?.inLocalZone()?.calendarDate,
        defaultSelection: DateRangeFilterSelection(start: LocalDate.today()),
      ),
      'more': FlagsFilter<Assignment>(
        (s) => s.general_entity_property_more,
        filters: {
          'isArchived': FlagFilter<Assignment>(
            (s) => s.general_entity_property_isArchived,
            selector: (assignment) => assignment.isArchived,
            defaultSelection: false,
          ),
          'isPrivate': FlagFilter<Assignment>(
            (s) => s.assignment_assignment_property_isPrivate,
            webQueryKey: 'private',
            selector: (assignment) => assignment.isPrivate,
          ),
          'hasPublicSubmissions': FlagFilter<Assignment>(
            (s) => s.assignment_assignment_property_hasPublicSubmissions,
            webQueryKey: 'publicSubmissions',
            selector: (assignment) => assignment.hasPublicSubmissions,
          ),
        },
      ),
    },
  );

  @override
  _AssignmentsScreenState createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen>
    with SortFilterStateMixin<AssignmentsScreen, Assignment> {
  @override
  Widget build(BuildContext context) {
    final s = context.s;

    return Scaffold(
      body: CachedBuilder<List<Assignment>>(
        controller: services.storage.root.assignments.controller,
        errorBannerBuilder: (_, error, st) => ErrorBanner(error, st),
        errorScreenBuilder: (_, error, st) => ErrorScreen(error, st),
        builder: (context, allAssignments) {
          final assignments = sortFilterSelection.apply(allAssignments);

          return CustomScrollView(
            slivers: <Widget>[
              FancyAppBar(
                title: Text(s.assignment),
                actions: <Widget>[SortFilterIconButton(showSortFilterSheet)],
              ),
              if (assignments.isEmpty)
                SortFilterEmptyState(
                  showSortFilterSheet,
                  text: s.assignment_assignmentsScreen_empty,
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, index) => Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: AssignmentCard(
                        assignment: assignments[index],
                        setFlagFilterCallback: setFlagFilter,
                      ),
                    ),
                    childCount: assignments.length,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class AssignmentCard extends StatelessWidget {
  const AssignmentCard({
    @required this.assignment,
    @required this.setFlagFilterCallback,
  })  : assert(assignment != null),
        assert(setFlagFilterCallback != null);

  final Assignment assignment;
  final SetFlagFilterCallback<Assignment> setFlagFilterCallback;

  void _showAssignmentDetailsScreen(BuildContext context) {
    context.navigator.pushNamed('/homework/${assignment.id}');
  }

  @override
  Widget build(BuildContext context) {
    return FancyCard(
      onTap: () => _showAssignmentDetailsScreen(context),
      omitBottomPadding: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          SizedBox(height: 4),
          ChipGroup(children: _buildChips(context)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Expanded(
          child: FancyText(
            assignment.name,
            style: context.textTheme.subhead,
            maxLines: 2,
          ),
        ),
        if (assignment.dueAt != null) ...[
          SizedBox(width: 8),
          Text(
            assignment.dueAt.shortDateTimeString,
            style: context.textTheme.caption,
          ),
        ],
      ],
    );
  }

  List<Widget> _buildChips(BuildContext context) {
    final s = context.s;

    return <Widget>[
      if (assignment.courseId != null)
        CachedRawBuilder<Course>(
          controller: assignment.courseId.controller,
          builder: (_, update) {
            return CourseChip(
              update.data,
              onPressed: () {
                // TODO(JonasWanke): filter list by course, https://github.com/schul-cloud/schulcloud-flutter/issues/145
              },
            );
          },
        ),
      if (assignment.isOverdue)
        ActionChip(
          avatar: Icon(
            Icons.flag,
            color: context.theme.errorColor,
          ),
          label: Text(s.assignment_assignment_overdue),
          onPressed: () {},
        ),
      if (assignment.isArchived)
        FlagFilterPreviewChip(
          icon: Icons.archive,
          label: s.assignment_assignment_isArchived,
          flag: 'isArchived',
          callback: setFlagFilterCallback,
        ),
      if (assignment.isPrivate)
        FlagFilterPreviewChip(
          icon: Icons.lock,
          label: s.assignment_assignment_isPrivate,
          flag: 'isPrivate',
          callback: setFlagFilterCallback,
        ),
    ];
  }
}
