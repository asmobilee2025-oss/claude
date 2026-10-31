import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../models/chat.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

final _chatProvider = StreamProvider.family<Chat?, String>((ref, id) => ref.watch(chatRepoProvider).watchChat(id));
final _messagesProvider =
    StreamProvider.family<List<Message>, String>((ref, id) => ref.watch(chatRepoProvider).watchMessages(id));

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.chatId});
  final String chatId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _markRead(Chat c, String uid) {
    if (c.unreadFor(uid) > 0) {
      ref.read(chatRepoProvider).markRead(c.id, uid).catchError((_) {});
    }
  }

  Future<void> _send(Chat c, String uid) async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    if (text.length > AppConstants.messageMax) {
      context.toast(context.t.tooLong(AppConstants.messageMax), error: true);
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(chatRepoProvider).send(chatId: c.id, senderId: uid, otherId: c.otherId(uid), text: text);
      _ctrl.clear();
    } catch (_) {
      if (mounted) context.toast(context.t.messageNotSent, error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final uid = ref.watch(currentUidProvider);
    final chat = ref.watch(_chatProvider(widget.chatId));
    return chat.when(
      loading: () => const Scaffold(body: Loading()),
      error: (e, _) => Scaffold(appBar: AppBar(), body: EmptyState(icon: Icons.lock_outline, title: t.notAllowed)),
      data: (c) {
        if (c == null || uid == null || !c.participants.contains(uid)) {
          return Scaffold(appBar: AppBar(), body: EmptyState(icon: Icons.lock_outline, title: t.notAllowed));
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => _markRead(c, uid));
        final messages = ref.watch(_messagesProvider(c.id));
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Avatar(name: c.otherName(uid), radius: 18),
              title: Text(c.otherName(uid), maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(c.listingTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => context.push('/listing/${c.listingId}'),
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(children: [
                Expanded(
                  child: messages.when(
                    loading: () => const Loading(),
                    error: (e, _) => ErrorView(error: e),
                    data: (list) => list.isEmpty
                        ? EmptyState(icon: Icons.waving_hand_outlined, title: t.sayHello)
                        : ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.all(12),
                            itemCount: list.length,
                            itemBuilder: (_, i) => _Bubble(message: list[i], mine: list[i].senderId == uid),
                          ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                    child: Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          minLines: 1,
                          maxLines: 5,
                          maxLength: AppConstants.messageMax,
                          buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(c, uid),
                          decoration: InputDecoration(hintText: t.typeMessage),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: t.send,
                        onPressed: _sending ? null : () => _send(c, uid),
                        icon: const Icon(Icons.send),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});
  final Message message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final bg = mine ? context.colors.primary : context.colors.surfaceContainerHighest;
    final fg = mine ? context.colors.onPrimary : context.colors.onSurface;
    return Align(
      alignment: mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadiusDirectional.only(
            topStart: const Radius.circular(16),
            topEnd: const Radius.circular(16),
            bottomStart: Radius.circular(mine ? 16 : 4),
            bottomEnd: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
          SelectableText(message.text, style: TextStyle(color: fg, height: 1.35)),
          const SizedBox(height: 2),
          Text(formatTime(message.createdAt, context.locale), style: TextStyle(color: fg.withValues(alpha: 0.7), fontSize: 10)),
        ]),
      ),
    );
  }
}
