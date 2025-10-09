import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sp/core/models/question.dart';
import 'package:sp/shared/widgets/elevated_card.dart';
import 'package:sp/shared/widgets/interactive_button.dart';
import 'package:sp/core/utils/question_validator.dart';
import 'drag_drop_widget.dart';

class QuestionWidget extends StatefulWidget {
  final Question question;
  final Function(String) onAnswerSubmitted;
  final VoidCallback? onSkip;
  final VoidCallback? onHint;
  final bool canUseHint;
  final int hintCost;
  final String? selectedAnswer;

  const QuestionWidget({
    super.key,
    required this.question,
    required this.onAnswerSubmitted,
    this.onSkip,
    this.onHint,
    this.canUseHint = true,
    this.hintCost = 10,
    this.selectedAnswer,
  });

  @override
  State<QuestionWidget> createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends State<QuestionWidget> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  bool _showHint = false;
  String? _selectedAnswer;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Match-the-following state
  List<String> _left = const [];
  List<String> _right = const [];
  Map<String, String> _matches = {}; // left -> right

  @override
  void initState() {
    super.initState();
    _selectedAnswer = widget.selectedAnswer;
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    // Start animations
    _fadeController.forward();
    _scaleController.forward();
    
    if (widget.question.type == QuestionType.numericInput && _selectedAnswer != null) {
      _textController.text = _selectedAnswer!;
    }
    if (widget.question.type == QuestionType.dragDrop) {
      _parseMatchOptions();
    }
  }

  void _parseMatchOptions() {
    // The AI service encodes pairs as ["LEFT:a|b|c", "RIGHT:x|y|z"]
    for (final token in widget.question.options) {
      if (token.startsWith('LEFT:')) {
        _left = token.substring(5).split('|');
      } else if (token.startsWith('RIGHT:')) {
        _right = token.substring(6).split('|');
      }
    }
    // Reset matches
    _matches.clear();
  }

  @override
  void dispose() {
    _textController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _selectAnswer(String answer) {
    setState(() {
      _selectedAnswer = answer;
    });
    // Add haptic feedback
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Validate question before rendering
    final validationResult = QuestionValidator.validateQuestion(widget.question);

    if (!validationResult.isValid) {
      return _buildInvalidQuestionUI(theme, validationResult);
    }

    final isMatch = widget.question.type == QuestionType.dragDrop;
    final isReadyToSubmit = () {
      if (isMatch) {
        return _matches.length == _left.length && _left.isNotEmpty;
      }
      return _selectedAnswer != null && _selectedAnswer!.isNotEmpty;
    }();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Question text with enhanced styling
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  widget.question.questionText,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Answer input area - Use SizedBox with fixed height instead of Expanded
              SizedBox(
                height: 400, // Fixed height to allow scrolling
                child: switch (widget.question.type) {
                  QuestionType.multipleChoice => _buildMultipleChoice(theme),
                  QuestionType.numericInput => _buildNumericInput(theme),
                  QuestionType.dragDrop => DragDropWidget(
                    leftItems: _left,
                    rightItems: _right,
                    initialMatches: _matches,
                    onMatchesChanged: (newMatches) {
                      setState(() {
                        _matches = newMatches;
                      });
                    },
                    theme: theme,
                  ),
                  QuestionType.trueFalse => _buildTrueFalse(theme),
                  QuestionType.fillInTheBlank => _buildFillInTheBlank(theme),
                  QuestionType.clickableAnswer => _buildClickableAnswer(theme),
                  QuestionType.shortAnswer => _buildShortAnswer(theme),
                },
              ),

            // Hint section with enhanced styling
            if (widget.question.hint != null && widget.question.hint!.isNotEmpty) ...[
              const SizedBox(height: 16),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _showHint 
                    ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.8)
                    : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Hint',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        if (!_showHint && widget.canUseHint)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${widget.hintCost} XP',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (_showHint) ...[
                      const SizedBox(height: 12),
                      AnimatedOpacity(
                        opacity: _showHint ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          widget.question.hint!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                    if (!_showHint) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: widget.canUseHint ? () {
                            setState(() {
                              _showHint = true;
                            });
                            widget.onHint?.call();
                            HapticFeedback.mediumImpact();
                          } : null,
                          icon: const Icon(Icons.help_outline, size: 18),
                          label: Text('Show Hint (${widget.hintCost} XP)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Action buttons with enhanced styling
            const SizedBox(height: 24),
            Row(
              children: [
                // Skip button
                if (widget.onSkip != null)
                  Expanded(
                    child: InteractiveButton(
                      text: 'Skip',
                      onPressed: widget.onSkip,
                      icon: Icons.skip_next,
                      style: InteractiveButtonStyle.outline,
                      enableSoundEffects: true,
                      enableHapticFeedback: true,
                    ),
                  ),
                
                if (widget.onSkip != null) const SizedBox(width: 16),
                
                // Submit button
                Expanded(
                  flex: 2,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: ElevatedButton.icon(
                      onPressed: isReadyToSubmit ? () {
                        String answer;
                        if (isMatch) {
                          // Format matches as "a->x,b->y,c->z"
                          answer = _matches.entries
                              .map((e) => '${e.key}->${e.value}')
                              .join(',');
                        } else {
                          answer = _selectedAnswer ?? _textController.text;
                        }
                        widget.onAnswerSubmitted(answer);
                        HapticFeedback.heavyImpact();
                      } : null,
                      icon: Icon(
                        Icons.check_circle,
                        size: 20,
                        color: isReadyToSubmit 
                          ? theme.colorScheme.onPrimary 
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      label: const Text('Submit', style: TextStyle(fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isReadyToSubmit
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surface,
                        foregroundColor: isReadyToSubmit
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: isReadyToSubmit ? 4 : 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildMultipleChoice(ThemeData theme) {
    return Column(
      children: widget.question.options.map((option) {
        final isSelected = _selectedAnswer == option;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          margin: const EdgeInsets.only(bottom: 10),
          child: Material(
            elevation: isSelected ? 8 : 2,
            borderRadius: BorderRadius.circular(16),
            shadowColor: theme.colorScheme.primary.withValues(alpha: 0.6),
            child: InkWell(
              onTap: () => _selectAnswer(option),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.6),
                            theme.colorScheme.primary.withValues(alpha: 0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.6),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withValues(alpha: 0.6),
                          width: 2,
                        ),
                      ),
                      child: AnimatedScale(
                        scale: isSelected ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.check,
                          color: theme.colorScheme.onPrimary,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected 
                              ? theme.colorScheme.primary 
                              : theme.colorScheme.onSurface,
                        ) ?? const TextStyle(),
                        child: Text(option),
                      ),
                    ),
                    if (isSelected)
                      AnimatedScale(
                        scale: 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: theme.colorScheme.primary,
                          size: 16,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNumericInput(ThemeData theme) {
    // For accessibility and speed, present 4-6 tap options instead of typing.
    // If options are provided by the question, use them; otherwise synthesize around the correct answer.
    List<String> options = List.of(widget.question.options);
    final correct = widget.question.correctAnswer;

    int? correctInt = int.tryParse(correct);
    if (options.isEmpty && correctInt != null) {
      final base = correctInt;
      final candidates = <int>{base};
      // Add plausible distractors near the correct integer
      for (int delta in [1, -1, 2, -2, 5, -5]) {
        if (candidates.length >= 4) break;
        candidates.add(base + delta);
      }
      options = candidates.map((e) => e.toString()).toList();
      options.shuffle();
    } else if (options.isEmpty) {
      // Fallback: create generic numeric choices
      options = [correct, '0', '1', '2']..shuffle();
    }

    return _buildChoiceGrid(theme, options);
  }

  Widget _buildChoiceGrid(ThemeData theme, List<String> options) {
    // Limit to max 6 options to prevent RangeError and ensure proper grid layout
    final displayOptions = options.take(6).toList();

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.6,
      ),
      itemCount: displayOptions.length,
      itemBuilder: (context, i) {
        // Additional safety check
        if (i >= displayOptions.length) {
          return const SizedBox.shrink();
        }

        final opt = displayOptions[i];
        final isSelected = _selectedAnswer == opt;
        return ElevatedCard(
          onTap: () {
            // FIX: Select answer instead of immediately submitting
            // This prevents auto-skip bug in numeric input
            _selectAnswer(opt);
            HapticFeedback.selectionClick();
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: isSelected
                  ? Border.all(color: theme.colorScheme.primary, width: 2)
                  : null,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              opt,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? theme.colorScheme.primary : null,
              ),
            ),
          ),
        );
      },
    );
  }



  Widget _buildTrueFalse(ThemeData theme) {
    return Column(
      children: ['True', 'False'].asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isSelected = _selectedAnswer == option;
        final isTrue = option == 'True';

        return AnimatedContainer(
          duration: Duration(milliseconds: (300 + (index * 100)).toInt()),
          curve: Curves.easeOutBack,
          margin: const EdgeInsets.only(bottom: 20),
          child: Material(
            elevation: isSelected ? 12 : 4,
            borderRadius: BorderRadius.circular(20),
            shadowColor: (isTrue ? Colors.green : Colors.red).withValues(alpha: 0.3),
            child: InkWell(
              onTap: () => _selectAnswer(option),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            (isTrue ? Colors.green : Colors.red).withValues(alpha: 0.6),
                            (isTrue ? Colors.green : Colors.red).withValues(alpha: 0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [
                            theme.colorScheme.surface,
                            theme.colorScheme.surface.withValues(alpha: 0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  border: Border.all(
                    color: isSelected
                        ? (isTrue ? Colors.green : Colors.red)
                        : theme.colorScheme.outline.withValues(alpha: 0.6),
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? (isTrue ? Colors.green : Colors.red)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? (isTrue ? Colors.green : Colors.red)
                              : theme.colorScheme.outline.withValues(alpha: 0.6),
                          width: 2,
                        ),
                      ),
                      child: AnimatedScale(
                        scale: isSelected ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.elasticOut,
                        child: Icon(
                          isTrue ? Icons.check : Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected 
                              ? (isTrue ? Colors.green : Colors.red)
                              : theme.colorScheme.onSurface,
                        ) ?? const TextStyle(),
                        child: Text(option),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isSelected ? 0.25 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        isTrue ? Icons.thumb_up : Icons.thumb_down,
                        color: isSelected 
                            ? (isTrue ? Colors.green : Colors.red)
                            : theme.colorScheme.outline,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFillInTheBlank(ThemeData theme) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(24),
            shadowColor: theme.colorScheme.primary.withValues(alpha: 0.6),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.surface,
                    theme.colorScheme.surface.withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
              child: TextField(
                controller: _textController,
                onChanged: (value) {
                  _selectAnswer(value);
                },
                decoration: InputDecoration(
                  hintText: '✏️ Type your answer here...',
                  hintStyle: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.all(24),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.edit,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                ),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Fill in the blank with the correct answer',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClickableAnswer(ThemeData theme) {
    return Column(
      children: widget.question.options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isSelected = _selectedAnswer == option;

        return AnimatedContainer(
          duration: Duration(milliseconds: (300 + (index * 100)).toInt()),
          curve: Curves.easeOutBack,
          margin: const EdgeInsets.only(bottom: 16),
          child: Material(
            elevation: isSelected ? 10 : 4,
            borderRadius: BorderRadius.circular(18),
            shadowColor: theme.colorScheme.primary.withValues(alpha: 0.6),
            child: InkWell(
              onTap: () => _selectAnswer(option),
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.6),
                            theme.colorScheme.primary.withValues(alpha: 0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [
                            theme.colorScheme.surface,
                            theme.colorScheme.surface.withValues(alpha: 0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.6),
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withValues(alpha: 0.6),
                          width: 2,
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: isSelected
                            ? Icon(
                                Icons.touch_app,
                                color: Colors.white,
                                size: 20,
                                key: const ValueKey('selected'),
                              )
                            : Icon(
                                Icons.touch_app_outlined,
                                color: theme.colorScheme.outline,
                                size: 20,
                                key: const ValueKey('unselected'),
                              ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected 
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ) ?? const TextStyle(),
                        child: Text(option),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isSelected ? 0.25 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: isSelected 
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.6),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildShortAnswer(ThemeData theme) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(24),
            shadowColor: theme.colorScheme.secondary.withValues(alpha: 0.6),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.surface,
                    theme.colorScheme.surface.withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
              child: TextField(
                controller: _textController,
                onChanged: (value) {
                  _selectAnswer(value);
                },
                maxLines: 5,
                minLines: 3,
                decoration: InputDecoration(
                  hintText: '📝 Write your detailed answer here...',
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.all(24),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.create,
                      color: theme.colorScheme.secondary,
                      size: 20,
                    ),
                  ),
                ),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.secondaryContainer.withValues(alpha: 0.6),
                  theme.colorScheme.secondaryContainer.withValues(alpha: 0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.secondary.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.psychology,
                    color: theme.colorScheme.secondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Writing Tip',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Write a complete, detailed answer. Your response will be compared with the model answer for accuracy.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build UI for invalid questions
  Widget _buildInvalidQuestionUI(ThemeData theme, QuestionValidationResult validationResult) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Question Cannot Be Displayed',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'This question has data issues and cannot be displayed properly.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Issues Found:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...validationResult.errors.map((error) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.close,
                          size: 16,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            error,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (widget.onSkip != null)
              ElevatedButton.icon(
                onPressed: widget.onSkip,
                icon: const Icon(Icons.skip_next),
                label: const Text('Skip This Question'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
