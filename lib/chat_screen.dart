import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firebase_service.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

class ChatScreen extends StatefulWidget {
  final String? roomId; // If null, it's the current Admin's UID
  final String? schoolName; // For Super Admin title

  const ChatScreen({super.key, this.roomId, this.schoolName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late String _currentRoomId;
  String _adminName = 'Admin';
  bool _isAutoMessageSent = false;
  bool _isSuperAdmin = false;
  bool _showScrollToBottom = false;
  bool _isFocused = false;

  // Animation controllers
  late AnimationController _inputGlowController;
  late Animation<double> _inputGlowAnimation;

  @override
  void initState() {
    super.initState();
    _currentRoomId = widget.roomId ?? _firebaseService.currentAdminId ?? '';
    _isSuperAdmin = widget.roomId != null;

    print("💬 [CHAT DEBUG] ChatScreen Initialized");
    print(
      "💬 [CHAT DEBUG] Room ID Source: ${widget.roomId != null ? 'Widget Parameter' : 'Current Admin Auth'}",
    );
    print("💬 [CHAT DEBUG] Final Room ID: '$_currentRoomId'");
    print("💬 [CHAT DEBUG] Is Super Admin View: $_isSuperAdmin");

    debugPrint(
      "💬 [Chat] Initialized room: $_currentRoomId (as Super Admin: $_isSuperAdmin)",
    );

    // Input glow animation
    _inputGlowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _inputGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _inputGlowController, curve: Curves.easeInOut),
    );

    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
      if (_focusNode.hasFocus) {
        _inputGlowController.repeat(reverse: true);
      } else {
        _inputGlowController.stop();
        _inputGlowController.reset();
      }
    });

    _scrollController.addListener(_scrollListener);
    _loadData();
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      bool shouldShow = _scrollController.offset > 300;
      if (shouldShow != _showScrollToBottom) {
        setState(() => _showScrollToBottom = shouldShow);
      }
    }
  }

  @override
  void dispose() {
    _inputGlowController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!_isSuperAdmin) {
      // It's Admin side
      final profile = await _firebaseService.getAdminProfile();
      if (profile != null && mounted) {
        setState(() {
          _adminName = profile['adminName'] ?? 'Admin';
        });
      }
      _checkAndSendAutoMessage();
    }

    // Mark as read based on who is viewing
    _firebaseService.markChatAsRead(_currentRoomId, _isSuperAdmin);
  }

  void _checkAndSendAutoMessage() async {
    if (_isSuperAdmin) return; // Only for Admin side
    if (_currentRoomId.isEmpty) {
      print("💬 [CHAT DEBUG] Auto-message check aborted: Room ID is empty.");
      return;
    }

    try {
      print("💬 [CHAT DEBUG] Checking for existing messages...");
      final messages = await _firebaseService
          .getMessagesStream(_currentRoomId)
          .first;
      if (messages.docs.isEmpty && !_isAutoMessageSent) {
        _isAutoMessageSent = true;
        print(
          "💬 [CHAT DEBUG] Sending automated welcome message to $_adminName...",
        );
        await _firebaseService.sendAutoWelcomeMessage(
          _currentRoomId,
          _adminName,
        );
      }
    } catch (e) {
      print("💬 [CHAT DEBUG] Error in auto-message check: $e");
    }
  }

  void _sendMessage() async {
    print("--------------------------------------------------");
    print("📱 [UI DEBUG] Send button clicked!");
    if (_messageController.text.trim().isEmpty) {
      print("⚠️ [UI DEBUG] Aborting: Message text is empty.");
      return;
    }

    final text = _messageController.text.trim();
    print("📱 [UI DEBUG] Sending text: '$text'");
    print("📱 [UI DEBUG] To Room: '$_currentRoomId'");

    _messageController.clear();

    try {
      await _firebaseService.sendMessage(_currentRoomId, text);
      print("📱 [UI DEBUG] sendMessage call finished.");
    } catch (e) {
      print("❌ [UI DEBUG] ERROR sending message: $e");
    }

    // Auto-scroll to bottom
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  /// Determine if a message bubble should be on the right (sent by current user)
  bool _isMyMessage(Map<String, dynamic> msg) {
    String senderRole = msg['senderRole'] ?? '';
    String senderId = msg['senderId'] ?? '';

    // System messages always on the left
    if (senderRole == 'system') return false;

    // Fallback for legacy messages or extra safety
    if (_isSuperAdmin) {
      // Super Admin view: super_admin messages OR messages NOT matching roomId are "mine"
      return senderRole == 'super_admin' ||
          (senderId.isNotEmpty && senderId != _currentRoomId);
    } else {
      // Admin view: admin messages OR messages matching roomId (currentAdminId) are "mine"
      return senderRole == 'admin' ||
          (senderId.isNotEmpty && senderId == _currentRoomId);
    }
  }

  /// Check if we need a date separator between messages
  String? _getDateSeparator(List<QueryDocumentSnapshot> messages, int index) {
    if (index >= messages.length) return null;

    var currentMsg = messages[index].data() as Map<String, dynamic>;
    var currentTs = currentMsg['timestamp'] as Timestamp?;
    if (currentTs == null) return null;

    DateTime currentDate = currentTs.toDate();

    // Last message (oldest in reversed list) always shows date
    if (index == messages.length - 1) {
      return _formatDateSeparator(currentDate);
    }

    // Compare with the next message (older in the reversed list)
    var nextMsg = messages[index + 1].data() as Map<String, dynamic>;
    var nextTs = nextMsg['timestamp'] as Timestamp?;
    if (nextTs == null) return _formatDateSeparator(currentDate);

    DateTime nextDate = nextTs.toDate();

    if (currentDate.day != nextDate.day ||
        currentDate.month != nextDate.month ||
        currentDate.year != nextDate.year) {
      return _formatDateSeparator(currentDate);
    }
    return null;
  }

  String _formatDateSeparator(DateTime date) {
    final now = _firebaseService.secureTime;
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);

    if (msgDate == today) return 'Today';
    if (msgDate == yesterday) return 'Yesterday';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      body: Column(
        children: [
          // --- CUSTOM GRADIENT APP BAR ---
          _buildAppBar(),
          // --- CHAT BODY ---
          Expanded(
            child: Stack(
              children: [
                // Background pattern
                Positioned.fill(
                  child: CustomPaint(painter: _ChatPatternPainter()),
                ),
                // Messages list
                StreamBuilder<QuerySnapshot>(
                  stream: _firebaseService.getMessagesStream(_currentRoomId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2168F8),
                          strokeWidth: 2.5,
                        ),
                      );
                    }

                    final messages = snapshot.data!.docs;

                    if (messages.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        var msg =
                            messages[index].data() as Map<String, dynamic>;
                        bool isMe = _isMyMessage(msg);
                        bool isSystem = (msg['senderRole'] ?? '') == 'system';
                        String? dateSeparator = _getDateSeparator(
                          messages,
                          index,
                        );

                        return Column(
                          children: [
                            // Date separator
                            if (dateSeparator != null)
                              _buildDateSeparator(dateSeparator),
                            // System message (special style)
                            if (isSystem)
                              _buildSystemMessage(msg['text'], msg['timestamp'])
                            else
                              _buildAnimatedBubble(msg, isMe, index),
                          ],
                        );
                      },
                    );
                  },
                ),
                // Scroll to bottom FAB
                if (_showScrollToBottom)
                  Positioned(
                    bottom: 10,
                    right: 16,
                    child: _buildScrollToBottomFab(),
                  ),
              ],
            ),
          ),
          // --- MESSAGE INPUT ---
          _buildMessageInput(),
        ],
      ),
    );
  }

  // ===== APP BAR =====
  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.of(context).padding.top + 8,
        16,
        16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A5CE8), Color(0xFF2979FF), Color(0xFF40C4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x402168F8),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 4),
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(
                _isSuperAdmin
                    ? Icons.school_rounded
                    : Icons.support_agent_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Title + Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSuperAdmin
                      ? (widget.schoolName ?? 'Chat')
                      : 'FeePal Support',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF4ADE80,
                            ).withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isSuperAdmin
                          ? 'Admin Support Chat'
                          : 'We typically reply within minutes',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isSuperAdmin)
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.white,
              ),
              tooltip: 'Delete Chat',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Chat'),
                    content: const Text(
                      'Are you sure you want to completely delete this chat? This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _firebaseService.deleteSuperAdminChat(
                            _currentRoomId,
                          );
                          if (mounted) Navigator.pop(context);
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ===== EMPTY STATE =====
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2168F8).withValues(alpha: 0.1),
                  const Color(0xFF40C4FF).withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: Color(0xFF2168F8),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No messages yet',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation!',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ===== DATE SEPARATOR =====
  Widget _buildDateSeparator(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300], thickness: 0.5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300], thickness: 0.5)),
        ],
      ),
    );
  }

  // ===== SYSTEM MESSAGE (Auto Welcome) =====
  Widget _buildSystemMessage(String text, dynamic timestamp) {
    String time = '';
    if (timestamp != null) {
      DateTime dt = (timestamp as Timestamp).toDate();
      time = DateFormat('hh:mm a').format(dt);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2168F8).withValues(alpha: 0.06),
                  const Color(0xFF40C4FF).withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF2168F8).withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2168F8).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: Color(0xFF2168F8),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'FeePal Support',
                      style: TextStyle(
                        color: Color(0xFF2168F8),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  text.replaceFirst('FeePal: ', ''),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
                if (time.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    time,
                    style: TextStyle(color: Colors.grey[400], fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== ANIMATED BUBBLE WRAPPER =====
  Widget _buildAnimatedBubble(Map<String, dynamic> msg, bool isMe, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 350 + (index.clamp(0, 5) * 30)),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: child,
          ),
        );
      },
      child: _buildMessageBubble(msg, isMe),
    );
  }

  // ===== MESSAGE BUBBLE =====
  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    String text = msg['text'] ?? '';
    dynamic timestamp = msg['timestamp'];
    String senderRole = msg['senderRole'] ?? '';

    String time = '';
    if (timestamp != null) {
      DateTime dt = (timestamp as Timestamp).toDate();
      time = DateFormat('hh:mm a').format(dt);
    }

    // Sender label
    String? senderLabel;
    if (!isMe) {
      if (senderRole == 'super_admin') {
        senderLabel = 'FeePal Support';
        // Strip "FeePal: " prefix for display
        if (text.startsWith('FeePal: ')) {
          text = text.substring(8);
        }
      } else if (senderRole == 'admin') {
        senderLabel = _isSuperAdmin ? (widget.schoolName ?? 'Admin') : null;
      }
    } else {
      // My own messages from SA — strip prefix
      if (senderRole == 'super_admin' && text.startsWith('FeePal: ')) {
        text = text.substring(8);
      }
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Sender label
            if (senderLabel != null)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Text(
                  senderLabel,
                  style: const TextStyle(
                    color: Color(0xFF2168F8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            // Bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        colors: [Color(0xFF1A5CE8), Color(0xFF2979FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isMe ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isMe
                        ? const Color(0xFF2168F8).withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: isMe ? 12 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : const Color(0xFF1E293B),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.65)
                              : Colors.grey[400],
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all_rounded,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== SCROLL TO BOTTOM FAB =====
  Widget _buildScrollToBottomFab() {
    return GestureDetector(
      onTap: _scrollToBottom,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2168F8).withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.keyboard_double_arrow_down_rounded,
          color: Color(0xFF2168F8),
          size: 24,
        ),
      ),
    );
  }

  // ===== MESSAGE INPUT =====
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: _inputGlowAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFF2168F8,
                          ).withValues(alpha: 0.08 * _inputGlowAnimation.value),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: _isFocused
                              ? const Color(0xFF2168F8).withValues(alpha: 0.3)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: Color(0xFF1E293B),
                        ),
                        decoration: InputDecoration(
                          hintText: _isSuperAdmin
                              ? 'Reply to admin...'
                              : 'Type your message...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14.5,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Send button (Converted to InkWell for better touch feedback)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _sendMessage,
                      borderRadius: BorderRadius.circular(30),
                      child: Ink(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A5CE8), Color(0xFF2979FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF2168F8,
                              ).withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ===== CUSTOM CHAT BACKGROUND PAINTER =====
class _ChatPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2168F8).withValues(alpha: 0.018)
      ..style = PaintingStyle.fill;

    // Draw subtle circles pattern
    double spacing = 60;
    double radius = 3;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
