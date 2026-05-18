import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../services/chat_service.dart';
import '../services/user_data_service.dart';
import '../utils/user_preferences.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  String? _userEmail;
  final String _sessionStartedAt = DateTime.now().toIso8601String();

  // Chat-specific colors — clearly distinct for each side
  static const Color _botBubble  = Color(0xFF1E293B);  // dark slate
  static const Color _userBubble = Color(0xFFFDB022);  // solar orange
  static const Color _botText    = Color(0xFFE2E8F0);  // off-white
  static const Color _userText   = Color(0xFF1E293B);  // dark for contrast on orange

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'assistant',
      'content': 'Hello! I\'m your Smart Solar Advisor 🌞\nHow can I help you with your solar energy needs today?',
    });
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    _userEmail = await UserPreferences.getUserEmail();
  }

  @override
  void dispose() {
    if (_userEmail != null) {
      UserDataService.saveChatSession(
        userEmail: _userEmail!,
        messages: List<Map<String, String>>.from(_messages),
        sessionStartedAt: _sessionStartedAt,
      );
    }
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    _controller.clear();

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });

    _scrollToBottom();

    final response = await ChatService.sendMessage(_messages);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _messages.add({
          'role': 'assistant',
          'content': response['success'] == true
              ? response['reply'] as String
              : 'Sorry, I encountered an error: ${response['message']}',
        });
      });
      _scrollToBottom();
    }

    // Keep keyboard open & re-focus
    _focusNode.requestFocus();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (_isLoading) _buildTypingIndicator(),
          _buildInputBar(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0F172A),
      elevation: 0,
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFDB022), Color(0xFFFF8C00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFDB022).withOpacity(0.35),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Solar Advisor AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Online',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFF1E293B)),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg   = _messages[index];
        final isUser = msg['role'] == 'user';
        // Show date separator before first message of a new day (simplified)
        return _buildMessageBubble(msg['content']!, isUser, index);
      },
    );
  }

  Widget _buildMessageBubble(String text, bool isUser, int index) {
    final showAvatar = !isUser &&
        (index == 0 ||
            _messages[index - 1]['role'] == 'user');

    return Padding(
      padding: EdgeInsets.only(
        top: index == 0 ? 0 : 4,
        bottom: 4,
        left: isUser ? 64 : 0,
        right: isUser ? 0 : 64,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bot avatar
          if (!isUser) ...[
            showAvatar
                ? Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFDB022), Color(0xFFFF8C00)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.smart_toy_rounded,
                        color: Colors.white, size: 18),
                  )
                : const SizedBox(width: 32),
            const SizedBox(width: 8),
          ],

          // Bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? _userBubble : _botBubble,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(18),
                  topRight:    const Radius.circular(18),
                  bottomLeft:  isUser
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isUser ? _userBubble : Colors.black)
                        .withOpacity(0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? _userText : _botText,
                  fontSize: 14.5,
                  height: 1.4,
                ),
              ),
            ),
          ),

          // User avatar
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFF334155), width: 1.5),
              ),
              child: const Icon(Icons.person_rounded,
                  color: Color(0xFF94A3B8), size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFDB022), Color(0xFFFF8C00)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _botBubble,
              borderRadius: const BorderRadius.only(
                topLeft:     Radius.circular(18),
                topRight:    Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft:  Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _buildDot(i)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + index * 200),
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: AppColors.primaryOrange
                .withOpacity(0.4 + 0.6 * value),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () => setState(() {}),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(
          top: BorderSide(color: const Color(0xFF1E293B), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF334155),
                    width: 1,
                  ),
                ),
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.enter &&
                        !HardwareKeyboard.instance.isShiftPressed) {
                      _sendMessage();
                    }
                  },
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontSize: 14.5,
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Ask about solar energy…',
                      hintStyle: TextStyle(
                          color: Color(0xFF64748B), fontSize: 14.5),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _isLoading ? null : _sendMessage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: _isLoading
                      ? const LinearGradient(
                          colors: [Color(0xFF334155), Color(0xFF334155)])
                      : const LinearGradient(
                          colors: [Color(0xFFFDB022), Color(0xFFFF8C00)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  shape: BoxShape.circle,
                  boxShadow: _isLoading
                      ? []
                      : [
                          BoxShadow(
                            color: const Color(0xFFFDB022).withOpacity(0.4),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: _isLoading
                      ? const Color(0xFF64748B)
                      : Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}