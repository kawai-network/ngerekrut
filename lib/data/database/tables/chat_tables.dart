/// SQL table definitions for the chat database.
/// 
/// This file contains the schema definitions used for migrations
/// and documentation purposes.
library;

class TableDefinitions {
  /// Schema version table
  static const String schemaVersion = '''
    CREATE TABLE schema_version (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      version INTEGER NOT NULL
    )
  ''';

  /// Users table - stores user information
  static const String users = '''
    CREATE TABLE users (
      id VARCHAR PRIMARY KEY,
      name VARCHAR,
      image_source VARCHAR,
      created_at BIGINT,
      metadata JSON
    )
  ''';

  /// Messages table - hybrid approach with common fields normalized
  /// and type-specific data in JSON columns
  static const String messages = '''
    CREATE TABLE messages (
      -- Base fields (normalized)
      id VARCHAR PRIMARY KEY,
      type VARCHAR NOT NULL,
      author_id VARCHAR NOT NULL,
      reply_to_message_id VARCHAR,
      
      -- Timestamps (epoch milliseconds)
      created_at BIGINT,
      deleted_at BIGINT,
      failed_at BIGINT,
      sent_at BIGINT,
      delivered_at BIGINT,
      seen_at BIGINT,
      updated_at BIGINT,
      edited_at BIGINT,
      
      -- Status fields
      pinned BOOLEAN DEFAULT FALSE,
      status VARCHAR,
      
      -- Type-specific content (hybrid approach)
      text_content TEXT,           -- For TextMessage.text
      media_source VARCHAR,        -- For Image/File/Video/Audio source
      media_metadata JSON,         -- Type-specific metadata (see below)
      custom_metadata JSON,        -- For CustomMessage and general metadata
      
      -- Foreign keys
      FOREIGN KEY (author_id) REFERENCES users(id)
    )
  ''';

  /// Reactions table - normalized for efficient querying
  static const String reactions = '''
    CREATE TABLE reactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      message_id VARCHAR NOT NULL,
      reaction_key VARCHAR NOT NULL,
      user_id VARCHAR NOT NULL,
      FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE,
      FOREIGN KEY (user_id) REFERENCES users(id)
    )
  ''';

  /// Index definitions for performance optimization
  static const List<String> indexes = [
    'CREATE INDEX idx_messages_author ON messages(author_id)',
    'CREATE INDEX idx_messages_created ON messages(created_at DESC)',
    'CREATE INDEX idx_messages_status ON messages(status)',
    'CREATE INDEX idx_messages_type ON messages(type)',
    'CREATE INDEX idx_messages_deleted ON messages(deleted_at)',
    'CREATE INDEX idx_reactions_message ON reactions(message_id)',
    'CREATE INDEX idx_reactions_user ON reactions(user_id)',
    'CREATE INDEX idx_users_name ON users(name)',
  ];

  /// Media metadata structure by message type:
  /// 
  /// TextMessage:
  /// {
  ///   "linkPreviewData": { "link": "...", "title": "...", ... }
  /// }
  /// 
  /// ImageMessage:
  /// {
  ///   "text": "...",
  ///   "thumbhash": "...",
  ///   "blurhash": "...",
  ///   "width": 1920.0,
  ///   "height": 1080.0,
  ///   "size": 123456,
  ///   "hasOverlay": false
  /// }
  /// 
  /// FileMessage:
  /// {
  ///   "name": "document.pdf",
  ///   "size": 123456,
  ///   "mimeType": "application/pdf"
  /// }
  /// 
  /// VideoMessage:
  /// {
  ///   "text": "...",
  ///   "name": "video.mp4",
  ///   "size": 123456,
  ///   "width": 1920.0,
  ///   "height": 1080.0
  /// }
  /// 
  /// AudioMessage:
  /// {
  ///   "text": "...",
  ///   "duration": 123456,  // milliseconds
  ///   "size": 123456,
  ///   "waveform": [0.1, 0.5, 0.8, ...]
  /// }
}
