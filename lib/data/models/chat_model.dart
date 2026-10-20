class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final String timestamp;
  final bool isMe;
  final bool isRead;
  final bool isViewOnce;
  final bool isSavedToVault;
  final String? mediaDescription;
  final String? mediaAssetPath;
  final String? mediaSize;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.isRead = true,
    this.isViewOnce = false,
    this.isSavedToVault = false,
    this.mediaDescription,
    this.mediaAssetPath,
    this.mediaSize,
  });

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? text,
    String? timestamp,
    bool? isMe,
    bool? isRead,
    bool? isViewOnce,
    bool? isSavedToVault,
    String? mediaDescription,
    String? mediaAssetPath,
    String? mediaSize,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isMe: isMe ?? this.isMe,
      isRead: isRead ?? this.isRead,
      isViewOnce: isViewOnce ?? this.isViewOnce,
      isSavedToVault: isSavedToVault ?? this.isSavedToVault,
      mediaDescription: mediaDescription ?? this.mediaDescription,
      mediaAssetPath: mediaAssetPath ?? this.mediaAssetPath,
      mediaSize: mediaSize ?? this.mediaSize,
    );
  }
}

class ChatConversation {
  final String id;
  final String contactName;
  final String avatarInitials;
  final String? avatarAssetPath;
  final bool isOnline;
  final bool isLocked;
  final bool isVerified;
  final String? tag;
  final int unreadCount;
  final String lastMessageTime;
  final String previewText;
  final List<ChatMessage> realMessages;
  final List<ChatMessage> decoyMessages;
  final String? camouflageAlias;
  final bool isGhostMode;

  const ChatConversation({
    required this.id,
    required this.contactName,
    required this.avatarInitials,
    this.avatarAssetPath,
    this.isOnline = false,
    this.isLocked = false,
    this.isVerified = false,
    this.tag,
    this.unreadCount = 0,
    required this.lastMessageTime,
    required this.previewText,
    required this.realMessages,
    required this.decoyMessages,
    this.camouflageAlias,
    this.isGhostMode = false,
  });

  ChatConversation copyWith({
    String? id,
    String? contactName,
    String? avatarInitials,
    String? avatarAssetPath,
    bool? isOnline,
    bool? isLocked,
    bool? isVerified,
    String? tag,
    int? unreadCount,
    String? lastMessageTime,
    String? previewText,
    List<ChatMessage>? realMessages,
    List<ChatMessage>? decoyMessages,
    String? camouflageAlias,
    bool? isGhostMode,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      contactName: contactName ?? this.contactName,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      avatarAssetPath: avatarAssetPath ?? this.avatarAssetPath,
      isOnline: isOnline ?? this.isOnline,
      isLocked: isLocked ?? this.isLocked,
      isVerified: isVerified ?? this.isVerified,
      tag: tag ?? this.tag,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      previewText: previewText ?? this.previewText,
      realMessages: realMessages ?? this.realMessages,
      decoyMessages: decoyMessages ?? this.decoyMessages,
      camouflageAlias: camouflageAlias ?? this.camouflageAlias,
      isGhostMode: isGhostMode ?? this.isGhostMode,
    );
  }
}
