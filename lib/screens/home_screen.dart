import 'package:flutter/material.dart';
import '../models/furniture_item.dart';
import '../services/database_service.dart';
import '../widgets/item_card.dart';
import 'item_registration_screen.dart';
import 'item_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<FurnitureItem> _items = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<FurnitureItem> items;
      switch (_selectedFilter) {
        case 'All':
          items = await _databaseService.getAllItems();
          break;
        default:
          if (FurnitureCategory.categories.contains(_selectedFilter)) {
            items = await _databaseService.getItemsByCategory(_selectedFilter);
          } else if (FurnitureRoom.rooms.contains(_selectedFilter)) {
            items = await _databaseService.getItemsByRoom(_selectedFilter);
          } else {
            items = await _databaseService.getAllItems();
          }
      }

      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading items: $e')),
        );
      }
    }
  }

  void _navigateToAddItem() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ItemRegistrationScreen(),
      ),
    );

    if (result == true) {
      _loadItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relocata'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            onSelected: (String filter) {
              setState(() {
                _selectedFilter = filter;
              });
              _loadItems();
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(value: 'All', child: Text('All Items')),
                const PopupMenuDivider(),
                ...FurnitureCategory.categories.map((category) =>
                    PopupMenuItem(value: category, child: Text(category))),
                const PopupMenuDivider(),
                ...FurnitureRoom.rooms.map((room) =>
                    PopupMenuItem(value: room, child: Text(room))),
              ];
            },
            child: Chip(
              label: Text(_selectedFilter),
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddItem,
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_items.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadItems,
      child: Column(
        children: [
          _buildSummaryCard(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return ItemCard(
                  item: _items[index],
                  onTap: () => _navigateToItemDetails(_items[index]),
                  onDelete: () => _deleteItem(_items[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'All'
                ? 'No furniture items yet'
                : 'No items in $_selectedFilter',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first item',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(
              'Total Items',
              _items.length.toString(),
              Icons.inventory_2,
            ),
            _buildSummaryItem(
              'Measured',
              _items.where((item) => item.area != null).length.toString(),
              Icons.straighten,
            ),
            _buildSummaryItem(
              'Categories',
              _items.map((item) => item.category).toSet().length.toString(),
              Icons.category,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  void _navigateToItemDetails(FurnitureItem item) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ItemDetailsScreen(item: item),
      ),
    );

    // If the item was edited or deleted, refresh the list
    if (result == true) {
      _loadItems();
    }
  }

  void _deleteItem(FurnitureItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deleteItem(item.id);
        _loadItems();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${item.name} deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting item: $e')),
          );
        }
      }
    }
  }
}