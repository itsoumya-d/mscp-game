import 'package:flutter/material.dart';
import 'package:sp/core/services/content/step_by_step_solution_service.dart';

/// Step-by-Step Solution Widget - Task F3
/// Display detailed solution walkthroughs
class StepByStepSolutionWidget extends StatefulWidget {
  final Solution solution;
  final VoidCallback? onComplete;

  const StepByStepSolutionWidget({
    Key? key,
    required this.solution,
    this.onComplete,
  }) : super(key: key);

  @override
  State<StepByStepSolutionWidget> createState() =>
      _StepByStepSolutionWidgetState();
}

class _StepByStepSolutionWidgetState extends State<StepByStepSolutionWidget>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  bool _showAllSteps = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStepsTab(),
                _buildAlternativeMethodsTab(),
                _buildKeyTakeawaysTab(),
                _buildCommonMistakesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Step-by-Step Solution',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.solution.questionText,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Answer: ${widget.solution.correctAnswer}',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabs: const [
        Tab(text: 'Steps', icon: Icon(Icons.format_list_numbered)),
        Tab(text: 'Alternatives', icon: Icon(Icons.alt_route)),
        Tab(text: 'Key Points', icon: Icon(Icons.star)),
        Tab(text: 'Mistakes', icon: Icon(Icons.warning_amber)),
      ],
    );
  }

  Widget _buildStepsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Solution Steps',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showAllSteps = !_showAllSteps;
                  if (_showAllSteps) {
                    _currentStep = widget.solution.steps.length - 1;
                  } else {
                    _currentStep = 0;
                  }
                });
              },
              icon: Icon(_showAllSteps ? Icons.visibility_off : Icons.visibility),
              label: Text(_showAllSteps ? 'Hide Steps' : 'Show All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_showAllSteps)
          ...widget.solution.steps.map((step) => _buildStepCard(step))
        else
          _buildProgressiveSteps(),
      ],
    );
  }

  Widget _buildProgressiveSteps() {
    return Column(
      children: [
        // Show completed steps
        ...widget.solution.steps
            .take(_currentStep + 1)
            .map((step) => _buildStepCard(step)),
        
        // Show next step button
        if (_currentStep < widget.solution.steps.length - 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _currentStep++;
                });
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next Step'),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ElevatedButton.icon(
              onPressed: widget.onComplete,
              icon: const Icon(Icons.check_circle),
              label: const Text('Complete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStepCard(SolutionStep step) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: step.isHighlighted
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    '${step.stepNumber}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (step.isHighlighted)
                  const Icon(Icons.star, color: Colors.amber),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              step.explanation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (step.formula != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Text(
                  step.formula!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            if (step.example != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Example: ${step.example}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlternativeMethodsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Alternative Methods',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        ...widget.solution.alternativeMethods.map(_buildAlternativeMethodCard),
      ],
    );
  }

  Widget _buildAlternativeMethodCard(AlternativeMethod method) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: const Icon(Icons.alt_route),
        title: Text(method.name),
        subtitle: Text(method.description),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Steps:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ...method.steps.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${entry.key + 1}. '),
                        Expanded(child: Text(entry.value)),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'When to use: ${method.whenToUse}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyTakeawaysTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Key Takeaways',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        ...widget.solution.keyTakeaways.map((takeaway) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: Text(takeaway),
            ),
          );
        }),
        const SizedBox(height: 16),
        Text(
          'Related Concepts',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.solution.relatedConcepts.map((concept) {
            return Chip(
              label: Text(concept),
              avatar: const Icon(Icons.link, size: 16),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCommonMistakesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Common Mistakes to Avoid',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        ...widget.solution.commonMistakes.map(_buildCommonMistakeCard),
      ],
    );
  }

  Widget _buildCommonMistakeCard(CommonMistake mistake) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    mistake.mistake,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Why this happens:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(mistake.why),
            const SizedBox(height: 8),
            Text(
              'How to avoid:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(mistake.howToAvoid),
          ],
        ),
      ),
    );
  }
}

