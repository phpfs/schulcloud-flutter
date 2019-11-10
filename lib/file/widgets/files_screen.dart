import 'package:flutter_cached/flutter_cached.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schulcloud/app/app.dart';
import 'package:schulcloud/course/course.dart';

import '../bloc.dart';
import '../data.dart';
import 'file_browser.dart';
import 'page_route.dart';

class FilesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Provider<Bloc>.value(
      value: Bloc(
        storage: StorageService.of(context),
        network: NetworkService.of(context),
        userFetcher: UserFetcherService.of(context),
      ),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: Text('Files', style: TextStyle(color: Colors.black)),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: <Widget>[
              _RecentFiles(),
              _CoursesList(),
              _UserFiles(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentFiles extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Recent'),
        ),
        SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16),
            children: List.generate(10, (index) {
              return _RecentFileCard();
            }),
          ),
        ),
      ],
    );
  }
}

class _RecentFileCard extends StatelessWidget {
  const _RecentFileCard({Key key, this.file}) : super(key: key);

  final File file;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(right: 8, bottom: 16),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(file?.name ?? 'some_file.txt'),
            Text(
              dateTimeToString(
                file?.updatedAt ?? DateTime.now().subtract(Duration(days: 1)),
              ),
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoursesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Course files'),
        ),
        CachedRawBuilder(
          controller: Bloc.of(context).fetchCourses()..fetch(),
          builder: (BuildContext context, CacheUpdate<List<Course>> update) {
            return GridView.extent(
              primary: false,
              shrinkWrap: true,
              maxCrossAxisExtent: 300,
              childAspectRatio: 3.2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: <Widget>[
                for (var course in update.data ?? [])
                  _CourseCard(course: course),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({Key key, this.course}) : super(key: key);

  final Course course;

  void _showCourseFiles(BuildContext context) {
    Navigator.of(context).push(FileBrowserPageRoute(
      builder: (context) => FileBrowser(owner: course),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showCourseFiles(context),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: <Widget>[
              Icon(Icons.folder, color: course.color),
              SizedBox(width: 8),
              Expanded(child: Text(course.name)),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserFiles extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Your files'),
        ),
        CachedRawBuilder(
          controller: UserFetcherService.of(context).fetchCurrentUser()
            ..fetch(),
          builder: (context, CacheUpdate<User> update) {
            return update.hasData
                ? FileBrowser(owner: update.data, isEmbedded: true)
                : Container();
          },
        ),
      ],
    );
  }
}
