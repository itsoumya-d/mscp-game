import 'package:flutter/material.dart';
import 'package:sp/core/services/content/real_world_applications_service.dart';

/// Real-World Applications Screen - See how concepts apply to real life
class RealWorldApplicationsScreen extends StatefulWidget {
  const RealWorldApplicationsScreen({Key? key}) : super(key: key);

  @override
  State<RealWorldApplicationsScreen> createState() => _RealWorldApplicationsScreenState();
}

class _RealWorldApplicationsScreenState extends State<RealWorldApplicationsScreen> {
  final _service = RealWorldApplicationsService();
  List<RealWorldApplication>? _applications;
  List<CareerConnection>? _careers;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    
    try {
      final apps = await _service.getApplicationsByTopic('Algebra');
      final careers = await _service.getCareerConnectionsForScreen();
      
      setState(() {
        _applications = apps;
        _careers = careers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-World Applications'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 24),

                // Applications
                Text(
                  'How It\'s Used',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                if (_applications != null)
                  ..._applications!.map((app) => _buildApplicationCard(app)),
                const SizedBox(height: 24),

                // Career Connections
                Text(
                  'Career Connections',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                if (_careers != null)
                  ..._careers!.map((career) => _buildCareerCard(career)),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.public, size: 32, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'See Math in Action',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Discover how the concepts you\'re learning are used in everyday life and exciting careers.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard(RealWorldApplication app) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.lightbulb, color: Colors.blue),
        ),
        title: Text(
          app.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(app.category.toString().split('.').last),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Example:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  app.example,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (app.videoUrl != null) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Play video
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Watch Video'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareerCard(CareerConnection career) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showCareerDetails(career),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.work, color: Colors.purple, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      career.careerTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      career.description,
                      style: TextStyle(color: Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.attach_money, size: 14, color: Colors.green),
                        Text(
                          career.averageSalary,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.school, size: 14, color: Colors.blue),
                        Text(
                          career.educationRequired,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showCareerDetails(CareerConnection career) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(career.careerTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                career.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Salary', career.averageSalary, Icons.attach_money),
              const SizedBox(height: 8),
              _buildInfoRow('Education', career.educationRequired, Icons.school),
              const SizedBox(height: 16),
              Text(
                'Skills Needed:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: career.skillsUsed.map((skill) {
                  return Chip(
                    label: Text(skill, style: const TextStyle(fontSize: 12)),
                    backgroundColor: Colors.blue.shade50,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Learn more feature coming soon!')),
              );
            },
            child: const Text('Learn More'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(value),
      ],
    );
  }
}

