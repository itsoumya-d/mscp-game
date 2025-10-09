import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../services/unified_lesson_service.dart';
import '../../features/lessons/lesson_screen.dart';

/// Enhanced lesson widget that ensures consistent question-answering functionality
/// across all lessons in the application
class EnhancedLessonWidget extends StatefulWidget {
  final String skillId;
  final String skillName;
  final SubjectType subject;
  final int? difficulty;
  final int lessonCount;
  final Function(Lesson)? onLessonTap;
  final bool showProgress;
  final EdgeInsets? padding;

  const EnhancedLessonWidget({
    Key? key,
    required this.skillId,
    required this.skillName,
    required this.subject,
    this.difficulty,
    this.lessonCount = 3,
    this.onLessonTap,
    this.showProgress = true,
    this.padding,
  }) : super(key: key);

  @override
  State<EnhancedLessonWidget> createState() => _EnhancedLessonWidgetState();
}

class _EnhancedLessonWidgetState extends State<EnhancedLessonWidget> {
  final UnifiedLessonService _lessonService = UnifiedLessonService.instance;
  List<Lesson>? _lessons;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  @override
  void didUpdateWidget(EnhancedLessonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.skillId != widget.skillId ||
        oldWidget.subject != widget.subject ||
        oldWidget.difficulty != widget.difficulty) {
      _loadLessons();
    }
  }

  Future<void> _loadLessons() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final lessons = await _lessonService.getLessonsForSkill(
        skillId: widget.skillId,
        skillName: widget.skillName,
        subject: widget.subject,
        difficulty: widget.difficulty,
        lessonCount: widget.lessonCount,
      );

      setState(() {
        _lessons = lessons.map((lesson) => lesson.toLesson()).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.skillName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.subject.name} • ${widget.lessonCount} lessons',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        if (widget.showProgress && _lessons != null)
          _buildProgressIndicator(),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    final completedCount = _lessons!.where((lesson) => lesson.isCompleted).length;
    final progress = _lessons!.isNotEmpty ? completedCount / _lessons!.length : 0.0;

    return Column(
      children: [
        CircularProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$completedCount/${_lessons!.length}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_lessons == null || _lessons!.isEmpty) {
      return _buildEmptyWidget();
    }

    return _buildLessonsList();
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[600],
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to load lessons',
            style: TextStyle(
              color: Colors.red[800],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _error!,
            style: TextStyle(color: Colors.red[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadLessons,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.school_outlined,
            color: Colors.grey[600],
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            'No lessons available',
            style: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Lessons for this skill are being prepared.',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsList() {
    return Column(
      children: _lessons!.asMap().entries.map((entry) {
        final index = entry.key;
        final lesson = entry.value;
        return _buildLessonCard(lesson, index);
      }).toList(),
    );
  }

  Widget _buildLessonCard(Lesson lesson, int index) {
    final isLocked = index > 0 && !_lessons![index - 1].isCompleted;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isLocked ? null : () => _handleLessonTap(lesson),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildLessonIcon(lesson, isLocked),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildLessonInfo(lesson, isLocked),
                ),
                _buildLessonActions(lesson, isLocked),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLessonIcon(Lesson lesson, bool isLocked) {
    IconData iconData;
    Color iconColor;

    if (isLocked) {
      iconData = Icons.lock;
      iconColor = Colors.grey;
    } else if (lesson.isCompleted) {
      iconData = Icons.check_circle;
      iconColor = Colors.green;
    } else {
      iconData = Icons.play_circle_outline;
      iconColor = Theme.of(context).primaryColor;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  Widget _buildLessonInfo(Lesson lesson, bool isLocked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lesson.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isLocked ? Colors.grey : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          lesson.description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isLocked ? Colors.grey : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        _buildLessonStats(lesson, isLocked),
      ],
    );
  }

  Widget _buildLessonStats(Lesson lesson, bool isLocked) {
    return Row(
      children: [
        Icon(
          Icons.quiz,
          size: 16,
          color: isLocked ? Colors.grey : Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 4),
        Text(
          '${lesson.questions.length} questions',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isLocked ? Colors.grey : Theme.of(context).primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Icon(
          Icons.star,
          size: 16,
          color: isLocked ? Colors.grey : Colors.amber,
        ),
        const SizedBox(width: 4),
        Text(
          '${lesson.xpReward} XP',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isLocked ? Colors.grey : Colors.amber[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLessonActions(Lesson lesson, bool isLocked) {
    if (isLocked) {
      return const SizedBox.shrink();
    }

    return Icon(
      Icons.arrow_forward_ios,
      size: 16,
      color: Colors.grey[400],
    );
  }

  void _handleLessonTap(Lesson lesson) {
    if (widget.onLessonTap != null) {
      widget.onLessonTap!(lesson);
    } else {
      // Default navigation to lesson screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LessonScreen(
            lesson: lesson,
            subjectType: widget.subject,
            skillId: widget.skillId,
          ),
        ),
      );
    }
  }
}