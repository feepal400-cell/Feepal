import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firebase_service.dart';
import 'package:intl/intl.dart';

class ParentAdminChatScreen extends StatefulWidget {
  final String parentId;
  final String adminId;
  final String parentName;
  final String role; // 'parent' or 'admin'

  const ParentAdminChatScreen({
    super.key,
    required this.parentId,
    required this.adminId,
    required this.parentName,
    required this.role,
  });

  @override
  State<ParentAdminChatScreen> createState() => _ParentAdminChatScreenState();
}

class _ParentAdminChatScreenState extends State<ParentAdminChatScreen>
    with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _showScrollToBottom = false;
  bool _isFocused = false;

  late AnimationController _inputGlowController;
  late Animation<double> _inputGlowAnimation;

  @override
  void initState() {
    super.initState();

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

    // Mark chat as read
    _firebaseService.markParentAdminChatAsRead(
      widget.parentId,
      widget.adminId,
      widget.role,
    );
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

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final text = _messageController.text.trim();
    _messageController.clear();

    await _firebaseService.sendParentAdminMessage(
      parentId: widget.parentId,
      adminId: widget.adminId,
      text: text,
      senderRole: widget.role,
      parentName: widget.parentName,
    );

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

  bool _isMyMessage(String senderRole) {
    return senderRole == widget.role;
  }

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
    // Theme colors based on role
    Color primaryColor = widget.role == 'admin'
        ? const Color(0xFF9E38FF)
        : const Color(0xFF00D4FF);
    Color primaryColorDark = widget.role == 'admin'
        ? const Color(0xFF7B1FA2)
        : const Color(0xFF009BCB);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      body: Column(
        children: [
          // --- HEADER ---
          _buildAppBar(primaryColor, primaryColorDark),
          // --- CHAT BODY ---
          Expanded(
            child: Stack(
              children: [
                // Messages list
                StreamBuilder<QuerySnapshot>(
                  stream: _firebaseService.getParentAdminMessagesStream(
                    widget.parentId,
                    widget.adminId,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: primaryColor,
                          strokeWidth: 2.5,
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState(primaryColor);
                    }

                    final messages = snapshot.data!.docs;

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        var msg =
                            messages[index].data() as Map<String, dynamic>;
                        String msgSenderRole = msg['senderRole'] ?? '';
                        bool isMe = _isMyMessage(msgSenderRole);
                        String? dateSeparator = _getDateSeparator(
                          messages,
                          index,
                        );

                        return Column(
                          children: [
                            if (dateSeparator != null)
                              _buildDateSeparator(dateSeparator),
                            _buildAnimatedBubble(
                              msg,
                              isMe,
                              index,
                              primaryColor,
                              primaryColorDark,
                            ),
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
                    child: _buildScrollToBottomFab(primaryColor),
                  ),
              ],
            ),
          ),
          // --- MESSAGE INPUT ---
          _buildMessageInput(primaryColor),
        ],
      ),
    );
  }

  // ===== APP BAR =====
  Widget _buildAppBar(Color primaryColor, Color primaryColorDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.of(context).padding.top + 8,
        16,
        16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColorDark,
            primaryColor,
            primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
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
                widget.role == 'parent'
                    ? Icons.school_rounded
                    : Icons.person_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.role == 'parent'
                      ? 'School Administration'
                      : widget.parentName,
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
                      widget.role == 'parent'
                          ? 'Contact School'
                          : 'Parent Contact',
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
          if (widget.role == 'admin')
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
                          await _firebaseService.deleteParentChat(
                            widget.parentId,
                            widget.adminId,
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
  Widget _buildEmptyState(Color primaryColor) {
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
                  primaryColor.withValues(alpha: 0.1),
                  primaryColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: primaryColor,
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

  // ===== ANIMATED BUBBLE WRAPPER =====
  Widget _buildAnimatedBubble(
    Map<String, dynamic> msg,
    bool isMe,
    int index,
    Color primaryColor,
    Color primaryColorDark,
  ) {
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
      child: _buildMessageBubble(msg, isMe, primaryColor, primaryColorDark),
    );
  }

  // ===== MESSAGE BUBBLE =====
  Widget _buildMessageBubble(
    Map<String, dynamic> msg,
    bool isMe,
    Color primaryColor,
    Color primaryColorDark,
  ) {
    String text = msg['text'] ?? '';
    dynamic timestamp = msg['timestamp'];

    String time = '';
    if (timestamp != null) {
      DateTime dt = (timestamp as Timestamp).toDate();
      time = DateFormat('hh:mm a').format(dt);
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: isMe
                ? LinearGradient(
                    colors: [primaryColorDark, primaryColor],
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
                    ? primaryColor.withValues(alpha: 0.25)
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
      ),
    );
  }

  // ===== SCROLL TO BOTTOM FAB =====
  Widget _buildScrollToBottomFab(Color primaryColor) {
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
              color: primaryColor.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.keyboard_double_arrow_down_rounded,
          color: primaryColor,
          size: 24,
        ),
      ),
    );
  }

  // ===== MESSAGE INPUT =====
  Widget _buildMessageInput(Color primaryColor) {
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
                          color: primaryColor.withValues(
                            alpha: 0.08 * _inputGlowAnimation.value,
                          ),
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
                              ? primaryColor.withValues(alpha: 0.3)
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
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor,
                          primaryColor.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: _sendMessage,
                        child: const Center(
                          child: Padding(
                            padding: EdgeInsets.only(left: 4.0),
                            child: Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
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
