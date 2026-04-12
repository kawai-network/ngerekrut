import 'package:ngerekrut/langchain/langchain.dart';

import '../models/chat_session_record.dart';
import '../objectbox.g.dart';
import '../objectbox_store_provider.dart';

class ChatSessionRepository {
  Future<void> initialize() async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }
  }

  List<ChatSessionRecord> listSessions() {
    final box = ObjectBoxStoreProvider.box<ChatSessionRecord>();
    final query = box
        .query()
        .order(ChatSessionRecord_.updatedAt, flags: Order.descending)
        .build();
    final sessions = query.find();
    query.close();
    return sessions;
  }

  ChatSessionRecord createSession({String? title}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final session = ChatSessionRecord(
      sessionId: _generateSessionId(),
      title: title?.trim().isNotEmpty == true ? title!.trim() : 'Chat Baru',
      lastMessagePreview: '',
      messageCount: 0,
      createdAt: now,
      updatedAt: now,
    );
    final box = ObjectBoxStoreProvider.box<ChatSessionRecord>();
    session.id = box.put(session);
    return session;
  }

  ChatSessionRecord ensureSession(String sessionId, {String? title}) {
    final existing = findBySessionId(sessionId);
    if (existing != null) return existing;

    final now = DateTime.now().millisecondsSinceEpoch;
    final session = ChatSessionRecord(
      sessionId: sessionId,
      title: title?.trim().isNotEmpty == true ? title!.trim() : 'Chat Baru',
      lastMessagePreview: '',
      messageCount: 0,
      createdAt: now,
      updatedAt: now,
    );
    final box = ObjectBoxStoreProvider.box<ChatSessionRecord>();
    session.id = box.put(session);
    return session;
  }

  ChatSessionRecord? findBySessionId(String sessionId) {
    final box = ObjectBoxStoreProvider.box<ChatSessionRecord>();
    final query = box
        .query(ChatSessionRecord_.sessionId.equals(sessionId))
        .build();
    final session = query.findFirst();
    query.close();
    return session;
  }

  ChatSessionRecord recordMessage(String sessionId, String content) {
    final session = ensureSession(sessionId);
    final normalized = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    final now = DateTime.now().millisecondsSinceEpoch;

    session.messageCount += 1;
    session.lastMessagePreview = _preview(normalized);
    session.updatedAt = now;
    if (session.messageCount == 1 && session.title == 'Chat Baru') {
      session.title = _deriveTitle(normalized);
    }

    final box = ObjectBoxStoreProvider.box<ChatSessionRecord>();
    session.id = box.put(session);
    return session;
  }

  ChatSessionRecord setTitle(String sessionId, String title) {
    final session = ensureSession(sessionId);
    final normalized = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isNotEmpty) {
      session.title = normalized;
      session.updatedAt = DateTime.now().millisecondsSinceEpoch;
      final box = ObjectBoxStoreProvider.box<ChatSessionRecord>();
      session.id = box.put(session);
    }
    return session;
  }

  void deleteSession(String sessionId) {
    final box = ObjectBoxStoreProvider.box<ChatSessionRecord>();
    final query = box
        .query(ChatSessionRecord_.sessionId.equals(sessionId))
        .build();
    final session = query.findFirst();
    query.close();
    if (session != null) {
      box.remove(session.id);
    }
    ChatMessageQuery.deleteSession(sessionId);
  }

  String _generateSessionId() =>
      'chat_${DateTime.now().microsecondsSinceEpoch}';

  String _deriveTitle(String content) {
    if (content.isEmpty) return 'Chat Baru';
    if (content.length <= 42) return content;
    return '${content.substring(0, 42).trimRight()}...';
  }

  String _preview(String content) {
    if (content.isEmpty) return 'Belum ada pesan';
    if (content.length <= 72) return content;
    return '${content.substring(0, 72).trimRight()}...';
  }
}
