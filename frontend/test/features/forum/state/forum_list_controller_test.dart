import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:school_rec/features/forum/data/forum_dtos.dart';
import 'package:school_rec/features/forum/data/forum_repository.dart';
import 'package:school_rec/features/forum/state/forum_list_controller.dart';
import 'package:school_rec/features/auth/data/auth_dtos.dart';
import 'forum_list_controller_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ForumRepository>()])
ForumPost _post(int id) => ForumPost(
      id: id,
      authorId: 1,
      content: 'Post $id',
      timestamp: DateTime(2024),
      threadId: null,
      isEdited: false,
      author:
          const ForumAuthor(id: 1, fullName: 'Author', role: UserRole.parent),
      replyCount: 0,
      replies: const [],
    );

void main() {
  group('ForumListController', () {
    test('loads pages and prepends created posts', () async {
      // Arrange
      final repo = MockForumRepository();
      when(repo.list(page: 1, limit: anyNamed('limit'))).thenAnswer((_) async =>
          (items: [_post(1), _post(2)], page: 1, totalPages: 2, total: 4));
      when(repo.list(page: 2, limit: anyNamed('limit'))).thenAnswer((_) async =>
          (items: [_post(3), _post(4)], page: 2, totalPages: 2, total: 4));
      when(repo.create(any)).thenAnswer((_) async => _post(99));

      final controller = ForumListController(repo);

      // Act
      await controller.ensureLoaded();
      await controller.loadMore();
      await controller.create('Hello');

      // Assert
      verify(repo.list(page: 1, limit: anyNamed('limit'))).called(1);
      verify(repo.list(page: 2, limit: anyNamed('limit'))).called(1);
      expect(controller.items.map((post) => post.id), [99, 1, 2, 3, 4]);
      expect(controller.initialized, isTrue);
      expect(controller.loading, isFalse);
      expect(controller.appending, isFalse);
    });
  });
}
