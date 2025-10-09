import 'package:flutter/material.dart';
import '../../core/services/asset_service.dart';

/// Avatar Customization - Task D4
/// Avatar builder with unlockable items (hairstyles, clothes, accessories)
class AvatarCustomizationScreen extends StatefulWidget {
  final String userId;

  const AvatarCustomizationScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<AvatarCustomizationScreen> createState() =>
      _AvatarCustomizationScreenState();
}

class _AvatarCustomizationScreenState extends State<AvatarCustomizationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Current avatar configuration
  AvatarConfig _currentAvatar = AvatarConfig(
    skinTone: 0,
    hairstyle: 0,
    hairColor: 0,
    outfit: 0,
    accessory: null,
    background: 0,
  );

  // Available items (mock data - replace with backend)
  final List<AvatarItem> _skinTones = List.generate(
    6,
    (i) => AvatarItem(
      id: 'skin_$i',
      name: 'Skin Tone ${i + 1}',
      isUnlocked: true,
      cost: 0,
    ),
  );

  final List<AvatarItem> _hairstyles = List.generate(
    12,
    (i) => AvatarItem(
      id: 'hair_$i',
      name: 'Hairstyle ${i + 1}',
      isUnlocked: i < 3,
      cost: i < 3 ? 0 : 100 * (i - 2),
    ),
  );

  final List<AvatarItem> _hairColors = List.generate(
    8,
    (i) => AvatarItem(
      id: 'color_$i',
      name: 'Hair Color ${i + 1}',
      isUnlocked: i < 4,
      cost: i < 4 ? 0 : 50 * (i - 3),
    ),
  );

  final List<AvatarItem> _outfits = List.generate(
    15,
    (i) => AvatarItem(
      id: 'outfit_$i',
      name: 'Outfit ${i + 1}',
      isUnlocked: i < 2,
      cost: i < 2 ? 0 : 200 * (i - 1),
    ),
  );

  final List<AvatarItem> _accessories = List.generate(
    10,
    (i) => AvatarItem(
      id: 'accessory_$i',
      name: 'Accessory ${i + 1}',
      isUnlocked: i < 1,
      cost: i < 1 ? 0 : 150 * i,
    ),
  );

  final List<AvatarItem> _backgrounds = List.generate(
    8,
    (i) => AvatarItem(
      id: 'bg_$i',
      name: 'Background ${i + 1}',
      isUnlocked: i < 2,
      cost: i < 2 ? 0 : 100 * (i - 1),
    ),
  );

  int _userGems = 1500; // Mock user gems

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Avatar'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.diamond, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  '$_userGems',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Avatar preview
          _buildAvatarPreview(),
          
          // Category tabs
          _buildCategoryTabs(),
          
          // Item grid
          Expanded(
            child: _buildItemGrid(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAvatarPreview() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getSkinToneColor(_currentAvatar.skinTone),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Base avatar using SVG
              Center(
                child: AssetService.getAvatarIcon(
                  'default_avatar',
                  width: 120,
                  height: 120,
                  color: _getSkinToneColor(_currentAvatar.skinTone),
                ),
              ),
              // Hairstyle overlay
              Center(
                child: Icon(
                  _getHairstyleIcon(_currentAvatar.hairstyle),
                  size: 80,
                  color: _getHairColor(_currentAvatar.hairColor),
                ),
              ),
              // Accessory
              if (_currentAvatar.accessory != null)
                Positioned(
                  top: 20,
                  right: 20,
                  child: Icon(
                    Icons.star,
                    size: 30,
                    color: Colors.amber,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        indicatorColor: Theme.of(context).colorScheme.primary,
        tabs: const [
          Tab(icon: Icon(Icons.face), text: 'Skin'),
          Tab(icon: Icon(Icons.face_retouching_natural), text: 'Hair'),
          Tab(icon: Icon(Icons.palette), text: 'Color'),
          Tab(icon: Icon(Icons.checkroom), text: 'Outfit'),
          Tab(icon: Icon(Icons.watch), text: 'Accessory'),
          Tab(icon: Icon(Icons.wallpaper), text: 'Background'),
        ],
      ),
    );
  }

  Widget _buildItemGrid() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildGrid(_skinTones, (index) {
          setState(() => _currentAvatar.skinTone = index);
        }),
        _buildGrid(_hairstyles, (index) {
          setState(() => _currentAvatar.hairstyle = index);
        }),
        _buildGrid(_hairColors, (index) {
          setState(() => _currentAvatar.hairColor = index);
        }),
        _buildGrid(_outfits, (index) {
          setState(() => _currentAvatar.outfit = index);
        }),
        _buildGrid(_accessories, (index) {
          setState(() => _currentAvatar.accessory = index);
        }),
        _buildGrid(_backgrounds, (index) {
          setState(() => _currentAvatar.background = index);
        }),
      ],
    );
  }

  Widget _buildGrid(List<AvatarItem> items, Function(int) onSelect) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildItemCard(item, index, onSelect);
      },
    );
  }

  Widget _buildItemCard(AvatarItem item, int index, Function(int) onSelect) {
    final isSelected = _isItemSelected(item.id);

    return Card(
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: InkWell(
        onTap: item.isUnlocked
            ? () => onSelect(index)
            : () => _showPurchaseDialog(item),
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.isUnlocked ? Icons.check_circle : Icons.lock,
                  size: 40,
                  color: item.isUnlocked
                      ? (isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey)
                      : Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (!item.isUnlocked) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.diamond, size: 12, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        '${item.cost}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            if (isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _resetAvatar,
              child: const Text('Reset'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _saveAvatar,
              child: const Text('Save Avatar'),
            ),
          ),
        ],
      ),
    );
  }

  bool _isItemSelected(String itemId) {
    if (itemId.startsWith('skin_')) {
      return itemId == 'skin_${_currentAvatar.skinTone}';
    } else if (itemId.startsWith('hair_')) {
      return itemId == 'hair_${_currentAvatar.hairstyle}';
    } else if (itemId.startsWith('color_')) {
      return itemId == 'color_${_currentAvatar.hairColor}';
    } else if (itemId.startsWith('outfit_')) {
      return itemId == 'outfit_${_currentAvatar.outfit}';
    } else if (itemId.startsWith('accessory_')) {
      return _currentAvatar.accessory != null &&
          itemId == 'accessory_${_currentAvatar.accessory}';
    } else if (itemId.startsWith('bg_')) {
      return itemId == 'bg_${_currentAvatar.background}';
    }
    return false;
  }

  Color _getSkinToneColor(int index) {
    final tones = [
      const Color(0xFFFFDBAC),
      const Color(0xFFF1C27D),
      const Color(0xFFE0AC69),
      const Color(0xFFC68642),
      const Color(0xFF8D5524),
      const Color(0xFF5C3317),
    ];
    return tones[index % tones.length];
  }

  IconData _getHairstyleIcon(int index) {
    final styles = [
      Icons.face,
      Icons.face_2,
      Icons.face_3,
      Icons.face_4,
      Icons.face_5,
      Icons.face_6,
    ];
    return styles[index % styles.length];
  }

  Color _getHairColor(int index) {
    final colors = [
      Colors.black,
      Colors.brown,
      Colors.amber,
      Colors.orange,
      Colors.red,
      Colors.blue,
      Colors.purple,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }

  void _showPurchaseDialog(AvatarItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Purchase ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cost: ${item.cost} gems'),
            const SizedBox(height: 8),
            Text('Your gems: $_userGems'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _userGems >= item.cost
                ? () {
                    setState(() {
                      _userGems -= item.cost;
                      item.isUnlocked = true;
                    });
                    Navigator.pop(context);
                  }
                : null,
            child: const Text('Purchase'),
          ),
        ],
      ),
    );
  }

  void _resetAvatar() {
    setState(() {
      _currentAvatar = AvatarConfig(
        skinTone: 0,
        hairstyle: 0,
        hairColor: 0,
        outfit: 0,
        accessory: null,
        background: 0,
      );
    });
  }

  void _saveAvatar() {
    // Save avatar to backend
    Navigator.pop(context, _currentAvatar);
  }
}

/// Avatar configuration
class AvatarConfig {
  int skinTone;
  int hairstyle;
  int hairColor;
  int outfit;
  int? accessory;
  int background;

  AvatarConfig({
    required this.skinTone,
    required this.hairstyle,
    required this.hairColor,
    required this.outfit,
    this.accessory,
    required this.background,
  });
}

/// Avatar item
class AvatarItem {
  final String id;
  final String name;
  bool isUnlocked;
  final int cost;

  AvatarItem({
    required this.id,
    required this.name,
    required this.isUnlocked,
    required this.cost,
  });
}

