import 'package:flutter/material.dart';

/// Search & Filter System - Task B7
/// Advanced search with filters, sorting, and suggestions
class SearchFilterScreen extends StatefulWidget {
  final String searchType; // 'lessons', 'questions', 'users'

  const SearchFilterScreen({
    Key? key,
    required this.searchType,
  }) : super(key: key);

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  
  List<String> _recentSearches = [];
  List<String> _suggestions = [];
  bool _showFilters = false;
  
  // Filter options
  String _sortBy = 'relevance';
  List<String> _selectedSubjects = [];
  List<int> _selectedDifficulties = [];
  RangeValues _durationRange = const RangeValues(0, 60);

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _searchController.addListener(_onSearchChanged);
  }

  void _loadRecentSearches() {
    // Load from SharedPreferences
    setState(() {
      _recentSearches = ['Algebra', 'Fractions', 'Geometry'];
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    
    // Generate suggestions
    setState(() {
      _suggestions = _generateSuggestions(query);
    });
  }

  List<String> _generateSuggestions(String query) {
    // Mock suggestions - replace with actual API call
    final allSuggestions = [
      'Algebra basics',
      'Algebraic expressions',
      'Fractions and decimals',
      'Fraction multiplication',
      'Geometry fundamentals',
      'Geometric shapes',
    ];
    
    return allSuggestions
        .where((s) => s.toLowerCase().contains(query.toLowerCase()))
        .take(5)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildSearchBar(),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters panel
          if (_showFilters) _buildFiltersPanel(),
          
          // Search results or suggestions
          Expanded(
            child: _searchController.text.isEmpty
                ? _buildRecentSearches()
                : _suggestions.isNotEmpty
                    ? _buildSuggestions()
                    : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocus,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search ${widget.searchType}...',
        border: InputBorder.none,
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _suggestions = []);
                },
              )
            : null,
      ),
      onSubmitted: _performSearch,
    );
  }

  Widget _buildFiltersPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sort by
          Row(
            children: [
              Text(
                'Sort by:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'relevance', label: Text('Relevance')),
                    ButtonSegment(value: 'popular', label: Text('Popular')),
                    ButtonSegment(value: 'recent', label: Text('Recent')),
                  ],
                  selected: {_sortBy},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() => _sortBy = newSelection.first);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Subjects
          Text(
            'Subjects:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Math', 'Science', 'English', 'History'].map((subject) {
              final isSelected = _selectedSubjects.contains(subject);
              return FilterChip(
                label: Text(subject),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSubjects.add(subject);
                    } else {
                      _selectedSubjects.remove(subject);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          
          // Difficulty
          Text(
            'Difficulty:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              {'label': 'Easy', 'value': 1, 'color': Colors.green},
              {'label': 'Medium', 'value': 2, 'color': Colors.orange},
              {'label': 'Hard', 'value': 3, 'color': Colors.red},
            ].map((diff) {
              final isSelected = _selectedDifficulties.contains(diff['value']);
              return FilterChip(
                label: Text(diff['label'] as String),
                selected: isSelected,
                selectedColor: (diff['color'] as Color).withOpacity(0.2),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDifficulties.add(diff['value'] as int);
                    } else {
                      _selectedDifficulties.remove(diff['value']);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Start searching',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Find lessons, questions, and more',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Searches',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () {
                setState(() => _recentSearches.clear());
              },
              child: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._recentSearches.map((search) {
          return ListTile(
            leading: const Icon(Icons.history),
            title: Text(search),
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () {
                setState(() => _recentSearches.remove(search));
              },
            ),
            onTap: () {
              _searchController.text = search;
              _performSearch(search);
            },
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSuggestions() {
    return ListView.builder(
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return ListTile(
          leading: const Icon(Icons.search),
          title: Text(suggestion),
          trailing: const Icon(Icons.north_west, size: 16),
          onTap: () {
            _searchController.text = suggestion;
            _performSearch(suggestion);
          },
        );
      },
    );
  }

  Widget _buildSearchResults() {
    // Mock results - replace with actual search results
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              child: Text('${index + 1}'),
            ),
            title: Text('Result ${index + 1}'),
            subtitle: Text('Description for result ${index + 1}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to result
            },
          ),
        );
      },
    );
  }

  void _performSearch(String query) {
    if (query.isEmpty) return;
    
    // Add to recent searches
    setState(() {
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 10) {
        _recentSearches = _recentSearches.take(10).toList();
      }
      _suggestions = [];
    });
    
    // Perform actual search
    // TODO: Implement search API call
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }
}

