import 'package:app/app.dart';
import 'package:app/model/post.dart';
import 'package:app/state.dart';
import 'package:app/widget/create_post.dart';
import 'package:app/widget/post.dart';

class CommentsWidget extends StatefulWidget {
  final String fullPostId;
  final Post parent;

  CommentsWidget(this.fullPostId, this.parent);

  @override
  _CommentsWidgetState createState() => _CommentsWidgetState();
}

class _CommentsWidgetState extends State<CommentsWidget> {
  @override
  void initState() {
    comments = {};
    _loadComments();

    dp.getFeedStream(key: 'comments/${widget.fullPostId}').listen((event) {
      _loadComments();
    });
    super.initState();
  }

  Future<void> loadComment(String id) async {
    try {
      final p = await dp.getPost(id);

      comments[id] = (p);

      setState(() {});
    } catch (e) {}
  }

  void _loadComments() async {
    print('_loadComments');

    final list = (await commentsIndex.get(widget.fullPostId)) ?? [];

    for (final commentId in list) {
      loadComment(commentId);
    }
  }

  Map<String, Post> comments;

  @override
  Widget build(BuildContext context) {
    return comments == null
        ? Center(child: CircularProgressIndicator())
        : Column(
            children: [
              if (AppState.isLoggedIn)
                Padding(
                  padding: const EdgeInsets.only(left: 0.0 + 8),
                  child: CreatePostWidget(
                    parent: widget.parent,
                    commentTo: widget.fullPostId,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(left: 0.0),
                child: Column(
                  children: [
                    for (final p in comments.values)
                      Padding(
                        padding: const EdgeInsets.all(1.0),
                        child: PostWidget(
                          p,
                          noDecoration: true,
                          indentContent: false,
                        ),
                      ),
                  ],
                ),
              )
            ],
          );
  }
}
