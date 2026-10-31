import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/responsive.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final uid = ref.watch(currentUidProvider);
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.chats)),
        body: EmptyState(
          icon: Icons.chat_bubble_outline,
          title: t.loginToChat,
          action: FilledButton(onPressed: () => context.push('/login?from=/chats'), child: Text(t.login)),
        ),
      );
    }
    final chats = ref.watch(myChatsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.chats)),
      body: MaxWidth(
        maxWidth: 800,
        child: AsyncBody(
          value: chats,
          onRetry: () => ref.invalidate(myChatsProvider),
          data: (list) {
            final visible = list.where((c) => c.lastMessage.isNotEmpty).toList();
            if (visible.isEmpty) {
              return EmptyState(icon: Icons.forum_outlined, title: t.noChats, subtitle: t.noChatsHint);
            }
            return ListView.separated(
              itemCount: visible.length,
              separatorBuilder: (_, _) => const Divider(indent: 84),
              itemBuilder: (_, i) {
                final c = visible[i];
                final unread = c.unreadFor(uid);
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  onTap: () => context.push('/chat/${c.id}'),
                  leading: SizedBox(
                    width: 56,
                    height: 56,
                    child: ClipRRect(borderRadius: BorderRadius.circular(12), child: NetImage(c.listingImage)),
                  ),
                  title: Row(children: [
                    Expanded(
                      child: Text(c.otherName(uid), maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w600)),
                    ),
                    Text(timeAgo(c.lastMessageAt, t), style: context.text.labelSmall?.copyWith(color: context.colors.outline)),
                  ]),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.listingTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.colors.primary, fontSize: 12)),
                    Row(children: [
                      Expanded(
                        child: Text(
                          '${c.lastSenderId == uid ? '${t.you}: ' : ''}${c.lastMessage}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: unread > 0 ? FontWeight.w700 : null),
                        ),
                      ),
                      if (unread > 0) Badge(label: Text('$unread')),
                    ]),
                  ]),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
