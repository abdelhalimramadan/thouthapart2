import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:thotha_mobile_app/core/networking/api_constants.dart';
import 'package:thotha_mobile_app/features/home_screen/ui/category_doctors_screen.dart';
import 'package:thotha_mobile_app/core/routing/routes.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static final String _apiBase = '${ApiConstants.baseUrl}/api';
  static const Map<String, String> _apiHeaders = {
    'Content-Type': 'application/json'
  };

  static const Color _color2 = Color(0xFF53CAF9);
  static const Color _color3 = Color(0x2853CAF9);
  static const Color _outline = Color(0xFFCCCCE5);
  static const String _thinkingText = 'يفكر.....';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _apiBase,
      headers: _apiHeaders,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  bool _isLoading = false;
  bool _chatMode = false;
  String? _sessionId;
  String? _activeQuestionId;
  List<Map<String, dynamic>> _categories = []; // قائمة الكاتيجوريات من API

  final List<_FlowItem> _flowItems = <_FlowItem>[];
  final List<_ChatItem> _chatHistory = <_ChatItem>[];

  @override
  void initState() {
    super.initState();
    _inputController.addListener(() {
      if (mounted) setState(() {});
    });
    _inputFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _loadCategories(); // جلب الكاتيجوريات عند البداية
    _startSessionOnce();
  }

  Future<void> _startSessionOnce() async {
    if (_isLoading || _sessionId != null || _flowItems.isNotEmpty) return;
    setState(() => _isLoading = true);
    try {
      final res = await _dio.post('/session/start', data: {'language': 'ar'});
      final data = res.data;
      if (data is Map && data['session_id'] != null) {
        _sessionId = data['session_id'].toString();
      }
      _processResponse(data);
    } catch (_) {
      setState(() => _chatMode = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  bool _processResponse(dynamic data) {
    final nextStep = (data is Map)
        ? (data['next_step'] ?? data['next'] ?? data['mode'] ?? data['state'])
        : null;

    if (data is Map && data['chatbot_mode'] == true) {
      setState(() => _chatMode = true);
      return true;
    }
    if (nextStep is String &&
        <String>['chat', 'chatbot', 'ai'].contains(nextStep.toLowerCase())) {
      setState(() => _chatMode = true);
      return true;
    }

    if (data is Map) {
      final result = data['result'];
      String? category;
      if (result is Map) {
        category = (result['category'] ?? result['category_en'])?.toString();
      }
      if (category != null && category.trim().isNotEmpty) {
        setState(() {
          _flowItems.add(_FlowItem.result(
              text: '✅ تم تحديد الفئة: $category', category: category));
        });
        return true;
      }
    }

    final q = _normalizeQuestion(data);
    if (q != null) {
      setState(() {
        _flowItems.add(_FlowItem.question(q));
        _activeQuestionId = q.id;
      });
      return true;
    }

    setState(() => _chatMode = true);
    return false;
  }

  _FlowQuestion? _normalizeQuestion(dynamic data) {
    if (data is! Map) return null;
    final q = (data['question'] is Map) ? (data['question'] as Map) : null;
    final id = (data['question_id'] ??
            data['questionId'] ??
            q?['id'] ??
            q?['question_id'] ??
            q?['questionId'])
        ?.toString();
    final text = (data['question_text'] ??
            (data['question'] is String ? data['question'] : null) ??
            q?['text'] ??
            q?['question_text'])
        ?.toString();
    if (id == null || id.isEmpty || text == null || text.isEmpty) return null;

    final rawAnswers =
        (data['answers'] ?? data['options'] ?? q?['answers'] ?? q?['options']);
    final List<_FlowAnswer> answers = [];
    if (rawAnswers is List) {
      for (final a in rawAnswers) {
        if (a is Map) {
          final aid = (a['id'] ?? a['answer_id'] ?? a['value'])?.toString();
          final at = (a['text'] ?? a['label'] ?? a['answer_text'] ?? a['title'])
               ?.toString();
          if (aid != null && aid.isNotEmpty && at != null && at.isNotEmpty) {
            answers.add(_FlowAnswer(id: aid, text: at));
          }
        }
      }
    }
    return _FlowQuestion(id: id, text: text, answers: answers);
  }

  Future<void> _submitAnswer(_FlowQuestion q, _FlowAnswer a) async {
    if (_sessionId == null || _sessionId!.isEmpty) return;

    setState(() {
      _isLoading = true;
      _activeQuestionId = null;
      _flowItems.add(_FlowItem.answer(text: a.text));
    });
    _scrollToBottom();

    final isOther =
        RegExp(r'(اخر|أخر|other)', caseSensitive: false).hasMatch(a.text);
    if (isOther) {
      setState(() {
        _flowItems.add(_FlowItem.result(
            text: 'من فضلك اكتب رسالتك بالتفصيل عشان أقدر أساعدك بشكل أفضل:'));
        _chatMode = true;
        _isLoading = false;
      });
      _scrollToBottom();
      return;
    }

    try {
      final res = await _dio.post('/session/answer', data: {
        'session_id': _sessionId,
        'question_id': q.id,
        'answer_id': a.id
      });
      final data = res.data;
      if (!_processResponse(data)) {
        setState(() {
          _flowItems.add(_FlowItem.result(
            text:
                'عذراً، أحتاج المزيد من المعلومات. من فضلك اكتب رسالة بالتفصيل عشان أقدر أفهم احتياجك بشكل أفضل:',
          ));
          _chatMode = true;
        });
      }
    } catch (_) {
      setState(() => _chatMode = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  Future<void> _sendChatMessage() async {
    final msg = _inputController.text.trim();
    if (msg.isEmpty) return;

    _inputController.clear();
    _inputFocusNode.requestFocus();

    setState(() {
      _chatHistory.add(_ChatItem.user(msg));
      _chatHistory.add(_ChatItem.bot(_thinkingText));
    });
    _scrollToBottom();

    const errorMsg = 'عذراً، حدث خطأ في الاتصال. حاول مرة أخرى.';
    try {
      final res = await _dio
          .post('/chat', data: {'message': msg, 'session_id': _sessionId});
      final data = res.data;
      if (data is Map && data['session_id'] != null) {
        _sessionId = data['session_id'].toString();
      }
      final reply = (data is Map && data['reply'] != null)
          ? data['reply'].toString()
          : errorMsg;
      setState(() {
        _chatHistory.removeWhere(
            (m) => m.role == _ChatRole.bot && m.text == _thinkingText);
        _chatHistory.add(_ChatItem.bot(reply));
      });
    } catch (_) {
      setState(() {
        _chatHistory.removeWhere(
            (m) => m.role == _ChatRole.bot && m.text == _thinkingText);
        _chatHistory.add(_ChatItem.bot(errorMsg));
      });
    } finally {
      _scrollToBottom();
    }
  }

  /// جلب الكاتيجوريات من API
  Future<void> _loadCategories() async {
    try {
      final res = await _dio.get('/category/getCategories');
      final data = res.data;

      final List? raw = data is List
          ? data
          : (data is Map ? (data['categories'] ?? data['data']) as List? : null);

      if (raw != null) {
        final parsed = <Map<String, dynamic>>[];
        for (final c in raw) {
          if (c is Map) parsed.add(Map<String, dynamic>.from(c));
        }
        if (mounted) setState(() => _categories = parsed);
      }
    } catch (e) {
    }
  }

  /// ابحث عن category_id باستخدام الاسم المترجم
  int? _getCategoryIdByName(String categoryName) {
    try {
      final normalizedInput = _normalize(categoryName);
      for (var cat in _categories) {
        final name = cat['name']?.toString() ?? '';
        final nameAr = cat['name_ar']?.toString() ?? '';

        if (_normalize(name) == normalizedInput ||
            _normalize(nameAr) == normalizedInput) {
          return cat['id'] as int?;
        }
      }
    } catch (_) {}
    return null;
  }

  String _normalize(String s) {
    return s
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[^\u0621-\u064A0-9a-zA-Z]'), '')
        .toLowerCase();
  }

  String _mapToAppCategory(String raw) {
    const map = <String, String>{
      'تبييض الأسنان': 'تنظيف وتبييض الأسنان',
      'Teeth Whitening': 'تنظيف وتبييض الأسنان',
      'زراعة الأسنان': 'زراعة الأسنان',
      'Dental Implants': 'زراعة الأسنان',
      'حشوات الأسنان': 'حشو تجميلي',
      'Dental Fillings': 'حشو تجميلي',
      'خلع الأسنان': 'الجراحة والخلع',
      'Tooth Extraction': 'الجراحة والخلع',
      'تيجان الأسنان / التركيبات': 'تيجان وجسور',
      'Dental Crowns / Prosthodontics': 'تيجان وجسور',
      'تقويم الأسنان': 'تقويم الأسنان',
      'Braces': 'تقويم الأسنان',
      'فحص شامل للأسنان': 'فحص شامل',
      'Comprehensive Dental Examination': 'فحص شامل',
      'حشو املجم': 'حشو املجم',
      'حشو عصب': 'حشو عصب',
      'تيجان وجسور': 'تيجان وجسور',
      'تركيبات متحركة': 'تركيبات متحركة',
      'تنظيف وتبييض': 'تنظيف وتبييض الأسنان',
      'الاطفال': 'طب أسنان الأطفال',
      'الجراحة والخلع': 'الجراحة والخلع',
      'Pediatric': 'طب أسنان الأطفال',
      'Pediatric Dentistry': 'طب أسنان الأطفال',
      'طب الأسنان للأطفال': 'طب أسنان الأطفال',
      'طب أسنان الأطفال': 'طب أسنان الأطفال',
      'تركيبات ثابتة (تيجان وجسور)': 'تيجان وجسور',
      'Crowns and Bridges': 'تيجان وجسور',
    };
    return map[raw] ?? map[raw.trim()] ?? raw;
  }

  void _openCategory(String rawCategory) {
    final mapped = _mapToAppCategory(rawCategory);
    final categoryId = _getCategoryIdByName(mapped);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryDoctorsScreen(
          categoryName: mapped,
          categoryId: categoryId, // تمرير ID الصحيح
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          _header(theme),
          Expanded(
            child: _chatBody(
              theme,
              bottomPadding: _chatMode ? 0 : 0,
            ),
          ),
          if (_chatMode)
            SafeArea(
              top: false,
              child: _footer(theme),
            ),
        ],
      ),
    );
  }

  Widget _header(ThemeData theme) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(
        left: 22.w,
        right: 22.w,
        bottom: 15.h,
        top: topPad + 15.h,
      ),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? theme.cardColor : _color2,
        border: theme.brightness == Brightness.dark 
            ? Border(bottom: BorderSide(color: theme.dividerColor)) 
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset('assets/svg/ثوثه الدكتور 1.svg',
                  width: 32.r, height: 32.r),
              SizedBox(width: 8.w),
              Text(
                'ثوثة الطبيب الذكي',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w600,
                  fontSize: 18.sp,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            child: InkWell(
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    Routes.categoriesScreen,
                    (route) => false,
                  );
                }
              },
              child: Padding(
                padding: EdgeInsets.all(8.r),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 24.r,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatBody(
    ThemeData theme, {
    required double bottomPadding,
  }) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(16.w, 25.h, 16.w,
          25.h + (bottomPadding > 0 ? bottomPadding : 0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _botMessage('👋🏻 اهلا بك\nازاى اقدر اساعدك؟'),
          if (_isLoading && _flowItems.isEmpty) ...[
            SizedBox(height: 16.h),
            _botMessage('...جاري تجهيز الأسئلة'),
          ],
          for (final item in _flowItems) ...[
            SizedBox(height: 16.h),
            if (item.type == _FlowType.question) ...[
              _botMessage(item.question!.text),
              if (!_chatMode &&
                  _activeQuestionId == item.question!.id &&
                  item.question!.answers.isNotEmpty) ...[
                SizedBox(height: 14.h),
                _quickReplies(item.question!),
              ],
            ] else if (item.type == _FlowType.result) ...[
              _botMessage(item.text),
              if (item.category != null) ...[
                SizedBox(height: 14.h),
                _resultButton(item.category!),
              ],
            ] else ...[
              _userMessage(item.text),
            ],
          ],
          for (final m in _chatHistory) ...[
            SizedBox(height: 16.h),
            if (m.role == _ChatRole.user)
              _userMessage(m.text)
            else
              _botMessage(m.text),
          ],
        ],
      ),
    );
  }

  Widget _footer(ThemeData theme) {
    final hasText = _inputController.text.trim().isNotEmpty;
    final isFocused = _inputFocusNode.hasFocus;

    return Container(
      padding: EdgeInsets.fromLTRB(22.w, 15.h, 22.w, 20.h),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: theme.brightness == Brightness.dark 
            ? Border(top: BorderSide(color: theme.dividerColor)) 
            : null,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark ? theme.cardColor : Colors.white,
          borderRadius: BorderRadius.circular(32.r),
          border: Border.all(
              color: isFocused ? _color2 : (theme.brightness == Brightness.dark ? Colors.grey[700]! : _outline), 
              width: isFocused ? 2 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                focusNode: _inputFocusNode,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendChatMessage(),
                style: TextStyle(
                    fontFamily: 'Cairo', 
                    color: theme.colorScheme.onSurface,
                    fontSize: 16.sp),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالتك..............................',
                  hintStyle: TextStyle(
                      fontFamily: 'Cairo', color: Color(0xFF6B8090), fontSize: 14.sp),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 17.w, vertical: 12.h),
                ),
              ),
            ),
            if (hasText)
              Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: InkWell(
                  onTap: _isLoading ? null : _sendChatMessage,
                  borderRadius: BorderRadius.circular(999.r),
                  child: Container(
                    height: 35.r,
                    width: 35.r,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: _color2),
                    child: Icon(Icons.arrow_upward,
                        color: Colors.white, size: 18.r),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _botAvatar({required double size}) {
    return Container(
      height: size.r,
      width: size.r,
      padding: EdgeInsets.all(size.r * 0.18),
      decoration: const BoxDecoration(color: _color2, shape: BoxShape.circle),
      child: SvgPicture.asset('assets/svg/ثوثه الدكتور 1.svg'),
    );
  }

  Widget _botMessage(String text) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            constraints: BoxConstraints(maxWidth: 0.75.sw),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark 
                  ? theme.colorScheme.surfaceVariant.withOpacity(0.5) 
                  : _color3,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(13.r),
                topRight: Radius.circular(13.r),
                bottomRight: Radius.circular(13.r),
                bottomLeft: Radius.circular(3.r),
              ),
            ),
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14.sp,
                height: 1.5,
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        _botAvatar(size: 32),
      ],
    );
  }

  Widget _userMessage(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: 0.75.sw),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: _color2,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(13.r),
            topRight: Radius.circular(13.r),
            bottomRight: Radius.circular(3.r),
            bottomLeft: Radius.circular(13.r),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14.sp,
            height: 1.5,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _quickReplies(_FlowQuestion q) {
    final theme = Theme.of(context);
    final answers = q.answers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final a in answers) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _submitAnswer(q, a),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.brightness == Brightness.dark 
                    ? theme.cardColor 
                    : _color3,
                foregroundColor: theme.colorScheme.onSurface,
                side: theme.brightness == Brightness.dark 
                    ? BorderSide(color: theme.dividerColor) 
                    : null,
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999.r),
                ),
              ),
              child: Text(
                a.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
        ],
      ],
    );
  }

  Future<void> _restartSession() async {
    setState(() => _isLoading = true);
    try {
      final res = await _dio.post('/session/start', data: {'language': 'ar'});
      final data = res.data;
      if (data is Map && data['session_id'] != null) {
        _sessionId = data['session_id'].toString();
      }
      setState(() {
        _chatMode = false;
        _activeQuestionId = null;
        _flowItems.add(_FlowItem.result(text: '— بدء محادثة جديدة —'));
      });
      _processResponse(data);
    } catch (_) {
      setState(() => _chatMode = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  Widget _resultButton(String category) {
    return Column(
      children: [
        Center(
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 6.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: _color2.withValues(alpha: 0.3),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => _openCategory(category),
              style: ElevatedButton.styleFrom(
                backgroundColor: _color2,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    EdgeInsets.symmetric(horizontal: 28.w, vertical: 14.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r)),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 0.75.sw),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: Text(
                        'عرض حالات $category',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Icon(Icons.arrow_back_rounded, size: 20.r),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Center(
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _restartSession,
            icon: Icon(Icons.refresh_rounded, size: 18.r, color: _color2),
            label: Text(
              'إعادة المحادثة من البداية',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: _color2,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _color2, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999.r)),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            ),
          ),
        ),
      ],
    );
  }
}

enum _FlowType { question, answer, result }

class _FlowItem {
  final _FlowType type;
  final String text;
  final _FlowQuestion? question;
  final String? category;

  _FlowItem._(
      {required this.type, required this.text, this.question, this.category});

  factory _FlowItem.question(_FlowQuestion q) =>
      _FlowItem._(type: _FlowType.question, text: q.text, question: q);
  factory _FlowItem.answer({required String text}) =>
      _FlowItem._(type: _FlowType.answer, text: text);
  factory _FlowItem.result({required String text, String? category}) =>
      _FlowItem._(type: _FlowType.result, text: text, category: category);
}

class _FlowQuestion {
  final String id;
  final String text;
  final List<_FlowAnswer> answers;
  _FlowQuestion({required this.id, required this.text, required this.answers});
}

class _FlowAnswer {
  final String id;
  final String text;
  _FlowAnswer({required this.id, required this.text});
}

enum _ChatRole { user, bot }

class _ChatItem {
  final _ChatRole role;
  final String text;
  _ChatItem._(this.role, this.text);

  factory _ChatItem.user(String text) => _ChatItem._(_ChatRole.user, text);
  factory _ChatItem.bot(String text) => _ChatItem._(_ChatRole.bot, text);
}
