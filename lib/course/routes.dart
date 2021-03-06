import 'package:flutter_deep_linking/flutter_deep_linking.dart';
import 'package:schulcloud/app/app.dart';

import 'data.dart';
import 'widgets/course_detail_screen.dart';
import 'widgets/courses_screen.dart';
import 'widgets/lesson_screen.dart';

final courseRoutes = Route(
  matcher: Matcher.path('courses'),
  materialBuilder: (_, __) => CoursesScreen(),
  routes: [
    Route(
      matcher: Matcher.path('{courseId}'),
      materialBuilder: (_, result) =>
          CourseDetailsScreen(Id<Course>(result['courseId'])),
      routes: [
        Route(
          matcher: Matcher.path('topics/{topicId}'),
          materialBuilder: (_, result) => LessonScreen(
            courseId: Id<Course>(result['courseId']),
            lessonId: Id<Lesson>(result['topicId']),
          ),
        ),
      ],
    ),
  ],
);
