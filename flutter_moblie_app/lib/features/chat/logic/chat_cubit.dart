import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/chat_repo.dart';
import '../data/models/chat_models.dart';
import 'chat_state.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

class ChatCubit extends Cubit<ChatState> {
  final ChatRepo _chatRepo;

  ChatCubit(this._chatRepo) : super(ChatState.initial());

  Future<void> startSession() async {
    emit(ChatState.loading());

    // Load categories first for matching later
    final categories = await _loadCategories();

    final result = await _chatRepo.startSession();

    if (result['success'] == true) {
      final data = result['data'];
      final response = ChatResponse.fromJson(data);

      final flowItems = <FlowItem>[];
      final chatHistory = <ChatItem>[];

      _processResponse(response, flowItems, chatHistory, response.sessionId,
          true, categories);
    } else {
      emit(ChatState.error(result['error'] ?? 'chat.failed_to_start_a'.tr()));
    }
  }

  Future<List<Map<String, dynamic>>> _loadCategories() async {
    try {
      // ApiConstants.getCategories is /api/category/getCategories
      final response = await _chatRepo.getCategories();
      if (response['success'] == true && response['data'] is List) {
        return List<Map<String, dynamic>>.from(response['data'] as List);
      }
    } catch (_) {}
    return [];
  }

  void _processResponse(
    ChatResponse response,
    List<FlowItem> flowItems,
    List<ChatItem> chatHistory,
    String? sessionId,
    bool emitNew,
    List<Map<String, dynamic>> categories,
  ) {
    bool chatMode = false;
    String? activeQuestionId;

    final nextStep = response.nextStep;
    if (response.chatbotMode == true ||
        ['chat', 'chatbot', 'ai'].contains(nextStep?.toLowerCase())) {
      chatMode = true;
    }

    if (response.result != null) {
      final category =
          (response.result!['category'] ?? response.result!['category_en'])
              ?.toString();
      if (category != null && category.trim().isNotEmpty) {
        flowItems.add(FlowItem(
          type: FlowType.result,
          text: '✅ تم تحديد الفئة: $category',
          category: category,
        ));
      }
    }

    final q = response.question;
    if (q != null && q.id != null && q.text != null) {
      flowItems
          .add(FlowItem(type: FlowType.question, text: q.text!, question: q));
      activeQuestionId = q.id;
    } else if (response.questionId != null && response.questionText != null) {
      // Support for flat question response
      final flatQ = ChatQuestion(
        id: response.questionId,
        text: response.questionText,
        answers: response.answers,
      );
      flowItems.add(FlowItem(
          type: FlowType.question, text: flatQ.text!, question: flatQ));
      activeQuestionId = flatQ.id;
    }

    if (emitNew) {
      emit(ChatState.success(
        flowItems: flowItems,
        chatHistory: chatHistory,
        categories: categories,
        sessionId: sessionId,
        activeQuestionId: activeQuestionId,
        chatMode: chatMode,
      ));
    }
  }

  /// ابحث عن category_id باستخدام اسم الفئة
  int? getCategoryIdByName(
      String rawCategory, List<Map<String, dynamic>> categories) {
    try {
      final mapped = _mapToAppCategory(rawCategory);
      final normalizedInput = _normalize(mapped);
      for (var cat in categories) {
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
        .replaceAll('chat.a'.tr(), 'chat.a_1'.tr())
        .replaceAll('chat.e'.tr(), 'chat.a_1'.tr())
        .replaceAll('chat.oh'.tr(), 'chat.a_1'.tr())
        .replaceAll('chat.oh_1'.tr(), 'chat.e_1'.tr())
        .replaceAll('chat.yes'.tr(), 'chat.y'.tr())
        .replaceAll(RegExp(r'[^\u0621-\u064A0-9a-zA-Z]'), '')
        .toLowerCase();
  }

  String _mapToAppCategory(String raw) {
    final map = <String, String>{
      'chat.teeth_whitening'.tr(): 'chat.teeth_cleaning_and_whitening'.tr(),
      'Teeth Whitening': 'chat.teeth_cleaning_and_whitening'.tr(),
      'chat.dental_implants'.tr(): 'chat.dental_implants'.tr(),
      'Dental Implants': 'chat.dental_implants'.tr(),
      'chat.dental_fillings'.tr(): 'chat.cosmetic_filler'.tr(),
      'Dental Fillings': 'chat.cosmetic_filler'.tr(),
      'chat.tooth_extraction'.tr(): 'chat.surgery_and_extraction'.tr(),
      'Tooth Extraction': 'chat.surgery_and_extraction'.tr(),
      'chat.dental_crownsprostheses'.tr(): 'chat.crowns_and_bridges'.tr(),
      'Dental Crowns / Prosthodontics': 'chat.crowns_and_bridges'.tr(),
      'chat.orthodontics'.tr(): 'chat.orthodontics'.tr(),
      'Braces': 'chat.orthodontics'.tr(),
      'chat.a_comprehensive_dental_examination'.tr(): 'chat.comprehensive_examination'.tr(),
      'Comprehensive Dental Examination': 'chat.comprehensive_examination'.tr(),
      'chat.cleaning_and_whitening'.tr(): 'chat.teeth_cleaning_and_whitening'.tr(),
      'chat.children'.tr(): 'chat.pediatric_dentistry'.tr(),
      'Pediatric': 'chat.pediatric_dentistry'.tr(),
      'chat.crowns_and_bridges'.tr(): 'chat.crowns_and_bridges'.tr(),
      'Crowns and Bridges': 'chat.crowns_and_bridges'.tr(),
    };
    return map[raw] ?? map[raw.trim()] ?? raw;
  }

  Future<void> submitAnswer(ChatQuestion q, ChatAnswer a) async {
    final currentState = state;
    if (currentState is! ChatSuccess || currentState.sessionId == null) return;

    final flowItems = List<FlowItem>.from(currentState.flowItems);
    flowItems.add(FlowItem(type: FlowType.answer, text: a.text ?? ''));

    emit(currentState.copyWith(
      flowItems: flowItems,
      activeQuestionId: null,
      isActionLoading: true,
    ));

    final result = await _chatRepo.submitAnswer(
      sessionId: currentState.sessionId!,
      questionId: q.id!,
      answerId: a.id!,
    );

    if (result['success'] == true) {
      final response = ChatResponse.fromJson(result['data']);
      _processResponse(
        response,
        flowItems,
        currentState.chatHistory,
        currentState.sessionId,
        true,
        currentState.categories,
      );
    } else {
      // Handle error but stay in success state to show chat
      emit(currentState.copyWith(isActionLoading: false));
    }
  }

  Future<void> sendChatMessage(String message) async {
    final currentState = state;
    if (currentState is! ChatSuccess) return;

    final chatHistory = List<ChatItem>.from(currentState.chatHistory);
    chatHistory.add(ChatItem(role: ChatRole.user, text: message));
    chatHistory.add(ChatItem(role: ChatRole.bot, text: 'chat.he_thinks'.tr()));

    emit(
        currentState.copyWith(chatHistory: chatHistory, isActionLoading: true));

    final result = await _chatRepo.sendChatMessage(
      message: message,
      sessionId: currentState.sessionId,
    );

    chatHistory
        .removeWhere((m) => m.role == ChatRole.bot && m.text == 'chat.he_thinks'.tr());

    if (result['success'] == true) {
      final response = ChatResponse.fromJson(result['data']);
      final reply = response.reply ?? 'chat.sorry_i_didnt_understand'.tr();
      chatHistory.add(ChatItem(role: ChatRole.bot, text: reply));

      emit(currentState.copyWith(
        chatHistory: chatHistory,
        sessionId: response.sessionId ?? currentState.sessionId,
        isActionLoading: false,
      ));
    } else {
      chatHistory.add(ChatItem(
          role: ChatRole.bot, text: 'chat.sorry_a_connection_error'.tr()));
      emit(currentState.copyWith(
          chatHistory: chatHistory, isActionLoading: false));
    }
  }

  Future<void> restartSession() async {
    emit(ChatState.loading());
    startSession();
  }
}
