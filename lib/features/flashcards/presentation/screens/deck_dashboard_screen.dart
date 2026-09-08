import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/vocabulary_item.dart';
import '../../../../services/vocabulary_service.dart';
import '../../../srs/models/srs_card.dart';
import '../../../srs/services/srs_storage_service.dart';
import 'flashcard_study_screen.dart';

class DeckDashboardScreen extends StatefulWidget {
  const DeckDashboardScreen({super.key});

  @override
  State<DeckDashboardScreen> createState() => _DeckDashboardScreenState();
}

class _DeckDashboardScreenState extends State<DeckDashboardScreen> {
  final VocabularyService _vocabService = VocabularyService();
  final SrsStorageService _storageService = SrsStorageService();

  bool _isLoading = true;
  List<TopicInfo> _topics = [];
    int _streak = 0;
  int _dueCount = 0;
  int _masteredCount = 0;
  int _learningCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    final topics = await _vocabService.loadTopics();
    final cards = await _storageService.loadCards();
    final streak = await _storageService.getStreak();

    int due = 0;
    int mastered = 0;
    int learning = 0;

    for (final card in cards.values) {
      if (card.state == SrsState.mastered) {
        mastered++;
      } else if (card.state == SrsState.learning) {
        learning++;
      }
      if (card.isDue) {
        due++;
      }
    }

    if (mounted) {
      setState(() {
        _topics = topics;
                _streak = streak;
        _dueCount = due;
        _masteredCount = mastered;
        _learningCount = learning;
        _isLoading = false;
      });
    }
  }

  void _openStudySession({String? topic}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardStudyScreen(topic: topic),
      ),
    );
    _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.school, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'iils',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: AppTheme.primary,
                  ),
                ),
                Text(
                  'Active Recall & Spaced Repetition',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Streak Flame
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                const SizedBox(width: 4),
                Text(
                  '$_streak',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // Daily SRS Review Card
                  _buildDailyQueueBanner(),
                  const SizedBox(height: 24),

                  // Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'IELTS Topic Decks',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryLight,
                        ),
                      ),
                      Text(
                        '${_topics.length} topics',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Topic List
                  ..._topics.map((t) => _buildTopicTile(t)),
                ],
              ),
            ),
    );
  }

  Widget _buildDailyQueueBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'SPACED REPETITION',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Text(
                '$_dueCount due today',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Daily Active Recall Queue',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Type academic words in context to solidify your memory for IELTS Writing & Speaking.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Mini stats
          Row(
            children: [
              _buildMiniStat('Learning', '$_learningCount', Colors.amber.shade200),
              const SizedBox(width: 16),
              _buildMiniStat('Mastered', '$_masteredCount', Colors.greenAccent.shade100),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _openStudySession(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.play_arrow, size: 20),
                    SizedBox(width: 4),
                    Text('Start Session', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildTopicTile(TopicInfo info) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
          child: const Icon(Icons.bookmark_outline, color: AppTheme.primary, size: 20),
        ),
        title: Text(
          info.topic,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        subtitle: Text(
          '${info.category} • ${info.itemCount} academic words',
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryLight,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => _openStudySession(topic: info.topic),
      ),
    );
  }
}
