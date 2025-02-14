import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/src/extension.dart';
import 'package:stream_chat_flutter/src/stream_chat_theme.dart';
import 'package:stream_chat_flutter/src/user_mention_tile.dart';
import 'package:stream_chat_flutter_core/stream_chat_flutter_core.dart';

/// Builder function for building a mention tile.
///
/// Use [UserMentionTile] for the default implementation.
typedef MentionTileBuilder = Widget Function(
  BuildContext context,
  User user,
);

/// Overlay for displaying users that can be mentioned.
class UserMentionsOverlay extends StatefulWidget {
  /// Constructor for creating a [UserMentionsOverlay].
  UserMentionsOverlay({
    Key? key,
    required this.query,
    required this.channel,
    required this.size,
    this.client,
    this.limit = 10,
    this.mentionAllAppUsers = false,
    this.mentionsTileBuilder,
    this.onMentionUserTap,
  })  : assert(
          channel.state != null,
          'Channel ${channel.cid} is not yet initialized',
        ),
        assert(
          !mentionAllAppUsers || (mentionAllAppUsers && client != null),
          'StreamChatClient is required in order to use mentionAllAppUsers',
        ),
        super(key: key);

  /// Query for searching users.
  final String query;

  /// Limit applied on user search results.
  final int limit;

  /// The size of the overlay.
  final Size size;

  /// The channel to search for users.
  final Channel channel;

  /// The client to search for users in case [mentionAllAppUsers] is True.
  final StreamChatClient? client;

  /// When enabled mentions search users across the entire app.
  ///
  /// Defaults to false.
  final bool mentionAllAppUsers;

  /// Customize the tile for the mentions overlay.
  final MentionTileBuilder? mentionsTileBuilder;

  /// Callback called when a user is selected.
  final void Function(User user)? onMentionUserTap;

  @override
  _UserMentionsOverlayState createState() => _UserMentionsOverlayState();
}

class _UserMentionsOverlayState extends State<UserMentionsOverlay> {
  late Future<List<User>> userMentionsFuture;

  @override
  void initState() {
    super.initState();
    userMentionsFuture = queryMentions(widget.query);
  }

  @override
  void didUpdateWidget(covariant UserMentionsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.channel != oldWidget.channel ||
        widget.query != oldWidget.query ||
        widget.mentionAllAppUsers != oldWidget.mentionAllAppUsers ||
        widget.limit != oldWidget.limit) {
      userMentionsFuture = queryMentions(widget.query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = StreamChatTheme.of(context);
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      color: theme.colorTheme.barsBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.hardEdge,
      child: Container(
        constraints: BoxConstraints.loose(widget.size),
        decoration: BoxDecoration(color: theme.colorTheme.barsBg),
        child: FutureBuilder<List<User>>(
          future: userMentionsFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Offstage();
            if (!snapshot.hasData) return const Offstage();
            final users = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(0),
              shrinkWrap: true,
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Material(
                  color: theme.colorTheme.barsBg,
                  child: InkWell(
                    onTap: () => widget.onMentionUserTap?.call(user),
                    child: widget.mentionsTileBuilder?.call(context, user) ?? UserMentionTile(user),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<List<User>> queryMentions(String query) async {
    final result = await _queryMembers(query);
    return result.map((it) => it.user).whereType<User>().toList(growable: false);
  }

  Future<List<Member>> _queryMembers(String query) async {
    final response = await widget.channel.queryMembers(
      pagination: PaginationParams(limit: widget.limit),
      filter: query.isEmpty ? const Filter.empty() : Filter.autoComplete('name', query),
    );
    return response.members;
  }

  Future<List<User>> _queryUsers(String query) async {
    assert(
      widget.client != null,
      'StreamChatClient is required in order to query all app users',
    );
    final response = await widget.client!.queryUsers(
      pagination: PaginationParams(limit: widget.limit),
      filter: query.isEmpty
          ? const Filter.empty()
          : Filter.or([
              Filter.autoComplete('id', query),
              Filter.autoComplete('name', query),
            ]),
      sort: [const SortOption('id', direction: SortOption.ASC)],
    );
    return response.users;
  }
}

/// Overlay for displaying users that can be mentioned.
class CircleMentionsOverlay extends StatefulWidget {
  /// Constructor for creating a [UserMentionsOverlay].
  CircleMentionsOverlay(
      {Key? key,
      required this.query,
      required this.channel,
      required this.size,
      this.client,
      this.limit = 10,
      this.mentionAllAppUsers = false,
      this.mentionsTileBuilder,
      this.onMentionUserTap,
      required this.queryCircles})
      : assert(
          channel.state != null,
          'Channel ${channel.cid} is not yet initialized',
        ),
        assert(
          !mentionAllAppUsers || (mentionAllAppUsers && client != null),
          'StreamChatClient is required in order to use mentionAllAppUsers',
        ),
        super(key: key);

  /// Query for searching users.
  final String query;

  /// Limit applied on user search results.
  final int limit;

  /// The size of the overlay.
  final Size size;

  /// The channel to search for users.
  final Channel channel;

  /// The client to search for users in case [mentionAllAppUsers] is True.
  final StreamChatClient? client;

  /// When enabled mentions search users across the entire app.
  ///
  /// Defaults to false.
  final bool mentionAllAppUsers;

  /// Customize the tile for the mentions overlay.
  final MentionTileBuilder? mentionsTileBuilder;

  /// Callback called when a user is selected.
  final void Function(Channel channel)? onMentionUserTap;

  final Future<List<Channel>> Function(String query)? queryCircles;

  @override
  _CircleMentionsOverlayState createState() => _CircleMentionsOverlayState();
}

class _CircleMentionsOverlayState extends State<CircleMentionsOverlay> {
  late Future<List<Channel>> userMentionsFuture;

  @override
  void initState() {
    super.initState();
    userMentionsFuture = queryMentions(widget.query);
  }

  @override
  void didUpdateWidget(covariant CircleMentionsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.channel != oldWidget.channel ||
        widget.query != oldWidget.query ||
        widget.mentionAllAppUsers != oldWidget.mentionAllAppUsers ||
        widget.limit != oldWidget.limit) {
      userMentionsFuture = queryMentions(widget.query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = StreamChatTheme.of(context);
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      color: theme.colorTheme.barsBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.hardEdge,
      child: Container(
        constraints: BoxConstraints.loose(widget.size),
        decoration: BoxDecoration(color: theme.colorTheme.barsBg),
        child: FutureBuilder<List<Channel>>(
          future: userMentionsFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Offstage();
            if (!snapshot.hasData) return const Offstage();
            final users = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(0),
              shrinkWrap: true,
              itemCount: users.length,
              itemBuilder: (context, index) {
                final channel = users[index];
                return Material(
                  color: theme.colorTheme.barsBg,
                  child: InkWell(
                    onTap: () => widget.onMentionUserTap?.call(channel),
                    child: CircleMentionTile(channel),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<List<Channel>> queryMentions(String query) async {
    if (widget.queryCircles == null) {
      return [];
    }
    final channels = await widget.queryCircles!(query);
    return channels;
  }
}

/// This widget is used for showing user tiles for mentions
/// Use [title], [subtitle], [leading], [trailing] for
/// substituting widgets in respective positions
class CircleMentionTile extends StatelessWidget {
  /// Constructor for creating a [UserMentionTile] widget
  const CircleMentionTile(
    this.channel, {
    Key? key,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
  }) : super(key: key);

  /// User to display in the tile
  final Channel channel;

  /// Widget to display as title
  final Widget? title;

  /// Widget to display below [title]
  final Widget? subtitle;

  /// Widget at the start of the tile
  final Widget? leading;

  /// Widget at the end of tile
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final chatThemeData = StreamChatTheme.of(context);
    return ListTile(
      leading: Container(
          height: 42,
          width: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              const Color(0XFFFFE380).withOpacity(0.3),
              const Color(0XFFFF9D92).withOpacity(0.3),
              const Color(0XFFED7DFF).withOpacity(0.3),
              const Color(0XFFC575FF).withOpacity(0.3),
              const Color(0XFF80ABFF).withOpacity(0.3),
              const Color(0XFFA8FAFF).withOpacity(0.3),
            ]),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text(
            channel.image ?? '😊',
            style: const TextStyle(
              fontSize: 26,
            ),
          )),
      title: Text(
        channel.name!.replaceAll('circle chat', ''),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: chatThemeData.textTheme.bodyBold,
      ),
    );
/*
    return SizedBox(
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              height: 42,
              width: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  const Color(0XFFFFE380).withOpacity(0.3),
                  const Color(0XFFFF9D92).withOpacity(0.3),
                  const Color(0XFFED7DFF).withOpacity(0.3),
                  const Color(0XFFC575FF).withOpacity(0.3),
                  const Color(0XFF80ABFF).withOpacity(0.3),
                  const Color(0XFFA8FAFF).withOpacity(0.3),
                ]),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                channel.image ?? '😊',
                style: const TextStyle(
                  fontSize: 26,
                ),
              )),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              channel.name!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: chatThemeData.textTheme.bodyBold,
            ),
          ),
        ],
      ),
    );*/
  }
}
