import 'package:flutter/material.dart';

/// Skeleton Loading Screens - Task B3
/// Replaces loading spinners with content-aware skeletons
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton for card list
class SkeletonCardList extends StatelessWidget {
  final int itemCount;

  const SkeletonCardList({
    Key? key,
    this.itemCount = 5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SkeletonLoader(
                      width: 48,
                      height: 48,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLoader(
                            width: double.infinity,
                            height: 16,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          const SizedBox(height: 8),
                          SkeletonLoader(
                            width: 150,
                            height: 12,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SkeletonLoader(
                  width: double.infinity,
                  height: 12,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 8),
                SkeletonLoader(
                  width: double.infinity,
                  height: 12,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 8),
                SkeletonLoader(
                  width: 200,
                  height: 12,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton for profile screen
class SkeletonProfile extends StatelessWidget {
  const SkeletonProfile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Avatar
          SkeletonLoader(
            width: 120,
            height: 120,
            borderRadius: BorderRadius.circular(60),
          ),
          const SizedBox(height: 16),
          
          // Name
          SkeletonLoader(
            width: 200,
            height: 24,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 8),
          
          // Bio
          SkeletonLoader(
            width: 150,
            height: 16,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 32),
          
          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) {
              return Column(
                children: [
                  SkeletonLoader(
                    width: 60,
                    height: 60,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  const SizedBox(height: 8),
                  SkeletonLoader(
                    width: 80,
                    height: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 32),
          
          // Content cards
          ...List.generate(3, (index) {
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(
                      width: double.infinity,
                      height: 16,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 12),
                    SkeletonLoader(
                      width: double.infinity,
                      height: 100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Skeleton for dashboard
class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          SkeletonLoader(
            width: 200,
            height: 32,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(height: 24),
          
          // Stats grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: List.generate(4, (index) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SkeletonLoader(
                        width: 48,
                        height: 48,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      const SizedBox(height: 12),
                      SkeletonLoader(
                        width: 80,
                        height: 16,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(height: 8),
                      SkeletonLoader(
                        width: 60,
                        height: 12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          
          // Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: 150,
                    height: 20,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(height: 16),
                  SkeletonLoader(
                    width: double.infinity,
                    height: 200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for level selection
class SkeletonLevelGrid extends StatelessWidget {
  const SkeletonLevelGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkeletonLoader(
                  width: 80,
                  height: 80,
                  borderRadius: BorderRadius.circular(40),
                ),
                const SizedBox(height: 16),
                SkeletonLoader(
                  width: double.infinity,
                  height: 16,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 8),
                SkeletonLoader(
                  width: 100,
                  height: 12,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

