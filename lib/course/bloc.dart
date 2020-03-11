import 'package:flutter/material.dart';
import 'package:flutter_cached/flutter_cached.dart';
import 'package:meta/meta.dart';
import 'package:pedantic/pedantic.dart';
import 'package:schulcloud/app/app.dart';
import 'package:schulcloud/course/course.dart';

import 'data.dart';

@immutable
class CourseBloc {
  const CourseBloc();

  CacheController<List<Course>> fetchCourses() => fetchList(
        // Apparently this returns all courses that aren't archived by the
        // current user.
        makeNetworkCall: () => services.api.get(
          'users/${services.storage.userId}/courses',
          parameters: {'filter': 'active'},
        ),
        parser: (data) => Course.fromJson(data),
      );

  CacheController<Course> fetchCourse(Id<Course> courseId) {
    assert(courseId != null);

    return fetchSingle(
      makeNetworkCall: () => services.api.get('courses/$courseId'),
      parser: (data) => Course.fromJson(data),
    );
  }

  CacheController<List<Lesson>> fetchLessonsOfCourse(Course course) =>
      fetchList(
        parent: course.id,
        makeNetworkCall: () =>
            services.api.get('lessons?courseId=${course.id}'),
        parser: (data) => Lesson.fromJson(data),
      );

  CacheController<List<User>> fetchTeachersOfCourse(Course course) {
    final storage = services.storage;
    final userFetcher = services.get<UserFetcherService>();

    return SimpleCacheController(
      saveToCache: (teachers) =>
          storage.cache.putChildrenOfType<User>(course.id, teachers),
      loadFromCache: () => storage.cache.getChildrenOfType<User>(course.id),
      fetcher: () => Future.wait([
        for (final teacherId in course.teachers)
          () async {
            final userController = userFetcher.fetchUser(teacherId, course.id);
            unawaited(userController.fetch());
            final firstUpdate = await userController.updates
                .firstWhere((update) => update.hasData, orElse: () => null);
            return firstUpdate.data;
          }(),
      ]),
    );
  }
}
