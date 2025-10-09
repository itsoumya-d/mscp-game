import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DragDropWidget extends StatefulWidget {
  final List<String> leftItems;
  final List<String> rightItems;
  final Map<String, String> initialMatches;
  final Function(Map<String, String>) onMatchesChanged;
  final ThemeData theme;

  const DragDropWidget({
    super.key,
    required this.leftItems,
    required this.rightItems,
    required this.initialMatches,
    required this.onMatchesChanged,
    required this.theme,
  });

  @override
  State<DragDropWidget> createState() => _DragDropWidgetState();
}

class _DragDropWidgetState extends State<DragDropWidget>
    with TickerProviderStateMixin {
  late Map<String, String> _matches;
  String? _draggedItem;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _matches = Map.from(widget.initialMatches);
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startPulse() {
    _pulseController.repeat(reverse: true);
  }

  void _stopPulse() {
    _pulseController.stop();
    _pulseController.reset();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.leftItems.isEmpty || widget.rightItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: widget.theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Drag & Drop options unavailable',
                style: widget.theme.textTheme.titleMedium?.copyWith(
                  color: widget.theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        
        if (isNarrow) {
          return Column(
            children: [
              _buildDragSection(),
              const SizedBox(height: 24),
              _buildDropSection(),
            ],
          );
        }
        
        return Row(
          children: [
            Expanded(child: _buildDragSection()),
            const SizedBox(width: 16),
            Expanded(child: _buildDropSection()),
          ],
        );
      },
    );
  }

  Widget _buildDragSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app,
                color: widget.theme.colorScheme.onPrimaryContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Drag Items',
                style: widget.theme.textTheme.titleMedium?.copyWith(
                  color: widget.theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: widget.leftItems.length,
            itemBuilder: (context, index) {
              final item = widget.leftItems[index];
              final isMatched = _matches.containsKey(item);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Draggable<String>(
                  data: item,
                  onDragStarted: () {
                    setState(() => _draggedItem = item);
                    HapticFeedback.mediumImpact();
                    _startPulse();
                  },
                  onDragEnd: (details) {
                    setState(() => _draggedItem = null);
                    _stopPulse();
                  },
                  feedback: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 200,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: widget.theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item,
                        style: widget.theme.textTheme.bodyLarge?.copyWith(
                          color: widget.theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: _buildDragItem(item, isMatched, isDragging: true),
                  ),
                  child: _buildDragItem(item, isMatched),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDragItem(String item, bool isMatched, {bool isDragging = false}) {
    final matchedRight = _matches[item];
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _draggedItem == item && !isDragging ? _pulseAnimation.value : 1.0,
          child: Material(
            elevation: isMatched ? 2 : 4,
            borderRadius: BorderRadius.circular(12),
            shadowColor: widget.theme.colorScheme.primary.withValues(alpha: 0.3),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isMatched 
                    ? widget.theme.colorScheme.primary.withValues(alpha: 0.5)
                    : widget.theme.colorScheme.outline.withValues(alpha: 0.3),
                  width: isMatched ? 2 : 1,
                ),
                gradient: isMatched
                  ? LinearGradient(
                      colors: [
                        widget.theme.colorScheme.primaryContainer,
                        widget.theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
                color: isMatched ? null : widget.theme.colorScheme.surface,
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isMatched 
                        ? widget.theme.colorScheme.primary 
                        : widget.theme.colorScheme.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      item,
                      style: widget.theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: isMatched ? FontWeight.w600 : FontWeight.normal,
                        color: isMatched 
                          ? widget.theme.colorScheme.onPrimaryContainer 
                          : widget.theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (matchedRight != null) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.link,
                            size: 16,
                            color: widget.theme.colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            matchedRight,
                            style: widget.theme.textTheme.bodySmall?.copyWith(
                              color: widget.theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.place,
                color: widget.theme.colorScheme.onSecondaryContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Drop Targets',
                style: widget.theme.textTheme.titleMedium?.copyWith(
                  color: widget.theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: widget.rightItems.length,
            itemBuilder: (context, index) {
              final item = widget.rightItems[index];
              final isOccupied = _matches.values.contains(item);
              final occupyingLeft = isOccupied 
                ? _matches.entries.firstWhere((e) => e.value == item).key
                : null;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: DragTarget<String>(
                  onWillAcceptWithDetails: (details) => !isOccupied,
                  onAcceptWithDetails: (details) {
                    final leftItem = details.data;
                    setState(() {
                      // Remove previous assignment of this right item
                      _matches.removeWhere((key, value) => value == item);
                      // Remove previous assignment of this left item
                      _matches.remove(leftItem);
                      // Create new match
                      _matches[leftItem] = item;
                    });
                    widget.onMatchesChanged(_matches);
                    HapticFeedback.heavyImpact();
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isHovering = candidateData.isNotEmpty;
                    
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Material(
                        elevation: isHovering ? 8 : (isOccupied ? 4 : 2),
                        borderRadius: BorderRadius.circular(12),
                        shadowColor: isHovering 
                          ? widget.theme.colorScheme.secondary.withValues(alpha: 0.5)
                          : null,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isHovering
                                ? widget.theme.colorScheme.secondary
                                : isOccupied 
                                  ? widget.theme.colorScheme.primary.withValues(alpha: 0.5)
                                  : widget.theme.colorScheme.outline.withValues(alpha: 0.3),
                              width: isHovering ? 3 : (isOccupied ? 2 : 1),
                            ),
                            gradient: isHovering
                              ? LinearGradient(
                                  colors: [
                                    widget.theme.colorScheme.secondaryContainer.withValues(alpha: 0.8),
                                    widget.theme.colorScheme.secondaryContainer.withValues(alpha: 0.6),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : isOccupied
                                ? LinearGradient(
                                    colors: [
                                      widget.theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                                      widget.theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: (!isHovering && !isOccupied) ? widget.theme.colorScheme.surface : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isOccupied 
                                  ? Icons.check_circle 
                                  : isHovering 
                                    ? Icons.add_circle_outline
                                    : Icons.radio_button_unchecked,
                                color: isOccupied 
                                  ? widget.theme.colorScheme.primary 
                                  : isHovering
                                    ? widget.theme.colorScheme.secondary
                                    : widget.theme.colorScheme.outline,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item,
                                      style: widget.theme.textTheme.bodyLarge?.copyWith(
                                        color: isOccupied 
                                          ? widget.theme.colorScheme.onPrimaryContainer
                                          : isHovering
                                            ? widget.theme.colorScheme.onSecondaryContainer
                                            : widget.theme.colorScheme.onSurface,
                                        fontWeight: isOccupied ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                    if (occupyingLeft != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Matched with: $occupyingLeft',
                                        style: widget.theme.textTheme.bodySmall?.copyWith(
                                          color: widget.theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isOccupied) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _matches.removeWhere((key, value) => value == item);
                                    });
                                    widget.onMatchesChanged(_matches);
                                    HapticFeedback.lightImpact();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: widget.theme.colorScheme.errorContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: widget.theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}