import 'package:flutter/material.dart';

/// Learning Path Screen
/// Displays a visual learning path with nodes representing topics and skills
class LearningPathScreen extends StatefulWidget {
  final String userId;
  final String subject;

  const LearningPathScreen({
    Key? key,
    required this.userId,
    required this.subject,
  }) : super(key: key);

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen> {
  List<PathNode> _pathNodes = [];
  int _currentNodeIndex = 3; // User's current position
  String _selectedGoal = 'Master Basics';

  @override
  void initState() {
    super.initState();
    _loadLearningPath();
  }

  void _loadLearningPath() {
    // Mock data - in real app, this would come from a service
    setState(() {
      _pathNodes = [
        PathNode(
          id: '1',
          title: 'Numbers & Counting',
          description: 'Learn basic number concepts',
          status: PathNodeStatus.completed,
          estimatedTime: 30,
          prerequisites: [],
        ),
        PathNode(
          id: '2',
          title: 'Addition Basics',
          description: 'Master single-digit addition',
          status: PathNodeStatus.completed,
          estimatedTime: 45,
          prerequisites: ['1'],
        ),
        PathNode(
          id: '3',
          title: 'Subtraction Basics',
          description: 'Learn single-digit subtraction',
          status: PathNodeStatus.completed,
          estimatedTime: 45,
          prerequisites: ['2'],
        ),
        PathNode(
          id: '4',
          title: 'Double-Digit Addition',
          description: 'Add numbers with two digits',
          status: PathNodeStatus.current,
          estimatedTime: 60,
          prerequisites: ['2'],
        ),
        PathNode(
          id: '5',
          title: 'Double-Digit Subtraction',
          description: 'Subtract numbers with two digits',
          status: PathNodeStatus.available,
          estimatedTime: 60,
          prerequisites: ['3', '4'],
        ),
        PathNode(
          id: '6',
          title: 'Multiplication Tables',
          description: 'Learn times tables 1-12',
          status: PathNodeStatus.locked,
          estimatedTime: 90,
          prerequisites: ['4', '5'],
        ),
        PathNode(
          id: '7',
          title: 'Division Basics',
          description: 'Understand division concepts',
          status: PathNodeStatus.locked,
          estimatedTime: 75,
          prerequisites: ['6'],
        ),
        PathNode(
          id: '8',
          title: 'Fractions Introduction',
          description: 'Learn about parts of a whole',
          status: PathNodeStatus.locked,
          estimatedTime: 90,
          prerequisites: ['7'],
        ),
      ];
    });
  }

  void _selectNode(PathNode node) {
    if (node.status == PathNodeStatus.locked) {
      _showLockedNodeDialog(node);
    } else if (node.status == PathNodeStatus.available || node.status == PathNodeStatus.current) {
      _showNodeDetails(node);
    } else {
      _showCompletedNodeDialog(node);
    }
  }

  void _showLockedNodeDialog(PathNode node) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(node.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This topic is locked. Complete the prerequisites first:'),
            const SizedBox(height: 8),
            ...node.prerequisites.map((prereqId) {
              final prereq = _pathNodes.firstWhere((n) => n.id == prereqId);
              return Text('• ${prereq.title}');
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showNodeDetails(PathNode node) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(node.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(node.description),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 4),
                Text('${node.estimatedTime} minutes'),
              ],
            ),
            if (node.prerequisites.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Prerequisites completed:'),
              ...node.prerequisites.map((prereqId) {
                final prereq = _pathNodes.firstWhere((n) => n.id == prereqId);
                return Text('✓ ${prereq.title}');
              }),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startLearning(node);
            },
            child: Text(node.status == PathNodeStatus.current ? 'Continue' : 'Start'),
          ),
        ],
      ),
    );
  }

  void _showCompletedNodeDialog(PathNode node) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(node.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 16),
            const Text('Completed!'),
            const SizedBox(height: 8),
            Text(node.description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startLearning(node);
            },
            child: const Text('Review'),
          ),
        ],
      ),
    );
  }

  void _startLearning(PathNode node) {
    // Mock navigation - in real app, this would navigate to the lesson/game
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting: ${node.title}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subject} Learning Path'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showGoalSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Header
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Goal: $_selectedGoal',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Progress: ${_getCompletedCount()}/${_pathNodes.length} topics',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    CircularProgressIndicator(
                      value: _getCompletedCount() / _pathNodes.length,
                      backgroundColor: Colors.grey[300],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _getCompletedCount() / _pathNodes.length,
                  backgroundColor: Colors.grey[300],
                ),
              ],
            ),
          ),

          // Learning Path
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ..._pathNodes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final node = entry.value;
                    return Column(
                      children: [
                        _buildPathNode(node, index),
                        if (index < _pathNodes.length - 1)
                          _buildPathConnector(node, _pathNodes[index + 1]),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathNode(PathNode node, int index) {
    Color nodeColor;
    IconData nodeIcon;
    
    switch (node.status) {
      case PathNodeStatus.completed:
        nodeColor = Colors.green;
        nodeIcon = Icons.check_circle;
        break;
      case PathNodeStatus.current:
        nodeColor = Colors.blue;
        nodeIcon = Icons.play_circle;
        break;
      case PathNodeStatus.available:
        nodeColor = Colors.orange;
        nodeIcon = Icons.radio_button_unchecked;
        break;
      case PathNodeStatus.locked:
        nodeColor = Colors.grey;
        nodeIcon = Icons.lock;
        break;
    }

    return GestureDetector(
      onTap: () => _selectNode(node),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            // Node circle
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: nodeColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: nodeColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                nodeIcon,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            
            // Node content
            Expanded(
              child: Card(
                elevation: node.status == PathNodeStatus.current ? 4 : 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        node.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${node.estimatedTime} min',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Spacer(),
                          Chip(
                            label: Text(_getStatusText(node.status)),
                            backgroundColor: nodeColor.withOpacity(0.2),
                            labelStyle: TextStyle(color: nodeColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPathConnector(PathNode currentNode, PathNode nextNode) {
    final isConnected = currentNode.status == PathNodeStatus.completed ||
        (currentNode.status == PathNodeStatus.current && 
         nextNode.status != PathNodeStatus.locked);
    
    return Container(
      width: 4,
      height: 20,
      margin: const EdgeInsets.only(left: 28),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green : Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  String _getStatusText(PathNodeStatus status) {
    switch (status) {
      case PathNodeStatus.completed:
        return 'Completed';
      case PathNodeStatus.current:
        return 'Current';
      case PathNodeStatus.available:
        return 'Available';
      case PathNodeStatus.locked:
        return 'Locked';
    }
  }

  int _getCompletedCount() {
    return _pathNodes.where((node) => node.status == PathNodeStatus.completed).length;
  }

  void _showGoalSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Learning Goals'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'Master Basics',
            'Accelerated Learning',
            'Review & Reinforce',
            'Exam Preparation',
          ].map((goal) => RadioListTile<String>(
                title: Text(goal),
                value: goal,
                groupValue: _selectedGoal,
                onChanged: (value) {
                  setState(() {
                    _selectedGoal = value!;
                  });
                  Navigator.of(context).pop();
                },
              )).toList(),
        ),
      ),
    );
  }
}

/// Model class for path nodes
class PathNode {
  final String id;
  final String title;
  final String description;
  final PathNodeStatus status;
  final int estimatedTime;
  final List<String> prerequisites;

  PathNode({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.estimatedTime,
    required this.prerequisites,
  });
}

/// Status of a path node
enum PathNodeStatus {
  completed,
  current,
  available,
  locked,
}