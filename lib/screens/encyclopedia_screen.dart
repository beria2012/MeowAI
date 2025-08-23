import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../utils/theme.dart';
import '../models/cat_breed.dart';
import '../services/breed_data_service.dart';
import '../widgets/cat_paw_button.dart';
import 'breed_detail_screen.dart';

class EncyclopediaScreen extends StatefulWidget {
  const EncyclopediaScreen({super.key});

  @override
  State<EncyclopediaScreen> createState() => _EncyclopediaScreenState();
}

class _EncyclopediaScreenState extends State<EncyclopediaScreen>
    with TickerProviderStateMixin {
  final BreedDataService _breedService = BreedDataService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<CatBreed> _allBreeds = [];
  List<CatBreed> _filteredBreeds = [];
  String _searchQuery = '';
  BreedFilter _currentFilter = BreedFilter.all;
  BreedSort _currentSort = BreedSort.name;
  bool _isLoading = true;
  
  late AnimationController _searchAnimationController;
  late AnimationController _filterAnimationController;

  @override
  void initState() {
    super.initState();
    
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _loadBreeds();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchAnimationController.dispose();
    _filterAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadBreeds() async {
    setState(() => _isLoading = true);
    
    try {
      await _breedService.initialize();
      _allBreeds = _breedService.getAllBreeds();
      _applyFiltersAndSort();
    } catch (e) {
      print('Error loading breeds: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFiltersAndSort();
    });
    
    if (_searchQuery.isNotEmpty) {
      _searchAnimationController.forward();
    } else {
      _searchAnimationController.reverse();
    }
  }

  void _applyFiltersAndSort() {
    List<CatBreed> filtered = List.from(_allBreeds);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = _breedService.searchBreeds(_searchQuery);
    }
    
    // Apply category filter
    switch (_currentFilter) {
      case BreedFilter.popular:
        filtered = filtered.where((breed) => !breed.isRare && breed.socialNeeds >= 4).toList();
        break;
      case BreedFilter.rare:
        filtered = filtered.where((breed) => breed.isRare).toList();
        break;
      case BreedFilter.hypoallergenic:
        filtered = filtered.where((breed) => breed.isHypoallergenic).toList();
        break;
      case BreedFilter.familyFriendly:
        filtered = filtered.where((breed) => 
            breed.socialNeeds >= 4 && 
            breed.energyLevel >= 3 && 
            breed.energyLevel <= 4).toList();
        break;
      case BreedFilter.lowMaintenance:
        filtered = filtered.where((breed) => 
            breed.groomingNeeds <= 3 && 
            breed.sheddingLevel <= 3).toList();
        break;
      case BreedFilter.all:
      default:
        break;
    }
    
    // Apply sorting
    switch (_currentSort) {
      case BreedSort.name:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case BreedSort.origin:
        filtered.sort((a, b) => a.origin.compareTo(b.origin));
        break;
      case BreedSort.popularity:
        filtered.sort((a, b) => b.socialNeeds.compareTo(a.socialNeeds));
        break;
      case BreedSort.rarity:
        filtered.sort((a, b) => b.isRare.toString().compareTo(a.isRare.toString()));
        break;
    }
    
    setState(() {
      _filteredBreeds = filtered;
    });
  }

  void _showFilterSheet() {
    _filterAnimationController.forward();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterSheet(),
    ).then((_) {
      _filterAnimationController.reverse();
    });
  }

  Widget _buildFilterSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Breeds',
                  style: AppTextStyles.headline2,
                ),
                const SizedBox(height: 20),
                
                _buildFilterSection(
                  'Category',
                  BreedFilter.values,
                  _currentFilter,
                  (filter) {
                    setState(() {
                      _currentFilter = filter;
                      _applyFiltersAndSort();
                    });
                  },
                ),
                
                const SizedBox(height: 20),
                
                _buildSortSection(
                  'Sort By',
                  BreedSort.values,
                  _currentSort,
                  (sort) {
                    setState(() {
                      _currentSort = sort;
                      _applyFiltersAndSort();
                    });
                  },
                ),
                
                const SizedBox(height: 30),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _currentFilter = BreedFilter.all;
                            _currentSort = BreedSort.name;
                            _applyFiltersAndSort();
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection<T>(
    String title,
    List<T> options,
    T current,
    Function(T) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.headline3.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = option == current;
            return GestureDetector(
              onTap: () => onChanged(option),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getOptionLabel(option),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSortSection<T>(
    String title,
    List<T> options,
    T current,
    Function(T) onChanged,
  ) {
    return _buildFilterSection(title, options, current, onChanged);
  }

  String _getOptionLabel(dynamic option) {
    if (option is BreedFilter) {
      switch (option) {
        case BreedFilter.all:
          return 'All Breeds';
        case BreedFilter.popular:
          return 'Popular';
        case BreedFilter.rare:
          return 'Rare';
        case BreedFilter.hypoallergenic:
          return 'Hypoallergenic';
        case BreedFilter.familyFriendly:
          return 'Family Friendly';
        case BreedFilter.lowMaintenance:
          return 'Low Maintenance';
      }
    } else if (option is BreedSort) {
      switch (option) {
        case BreedSort.name:
          return 'Name';
        case BreedSort.origin:
          return 'Origin';
        case BreedSort.popularity:
          return 'Popularity';
        case BreedSort.rarity:
          return 'Rarity';
      }
    }
    return option.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilterChips(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: LoadingPawAnimation(
                        message: 'Loading breed encyclopedia...',
                      ),
                    )
                  : _buildBreedList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Breed Encyclopedia',
                  style: AppTextStyles.headline1.copyWith(fontSize: 28),
                ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0),
                
                const SizedBox(height: 8),
                
                Text(
                  '${_filteredBreeds.length} breeds available',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: const Icon(
              Icons.pets,
              color: Colors.white,
              size: 32,
            ),
          ).animate().scale(delay: 400.ms, duration: 600.ms),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search breeds...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
        ),
      ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    'All',
                    _currentFilter == BreedFilter.all,
                    () {
                      setState(() {
                        _currentFilter = BreedFilter.all;
                        _applyFiltersAndSort();
                      });
                    },
                  ),
                  _buildFilterChip(
                    'Popular',
                    _currentFilter == BreedFilter.popular,
                    () {
                      setState(() {
                        _currentFilter = BreedFilter.popular;
                        _applyFiltersAndSort();
                      });
                    },
                  ),
                  _buildFilterChip(
                    'Rare',
                    _currentFilter == BreedFilter.rare,
                    () {
                      setState(() {
                        _currentFilter = BreedFilter.rare;
                        _applyFiltersAndSort();
                      });
                    },
                  ),
                  _buildFilterChip(
                    'Hypoallergenic',
                    _currentFilter == BreedFilter.hypoallergenic,
                    () {
                      setState(() {
                        _currentFilter = BreedFilter.hypoallergenic;
                        _applyFiltersAndSort();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _showFilterSheet,
            child: AnimatedBuilder(
              animation: _filterAnimationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_filterAnimationController.value * 0.1),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: const Icon(
                      Icons.tune,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ).animate().slideY(delay: 800.ms, begin: 0.2, end: 0);
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isSelected ? Colors.white : AppTheme.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBreedList() {
    if (_filteredBreeds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No breeds found',
              style: AppTextStyles.headline3.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: _filteredBreeds.length,
      itemBuilder: (context, index) {
        final breed = _filteredBreeds[index];
        return BreedCard(
          breed: breed,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => BreedDetailScreen(breed: breed),
              ),
            );
          },
        ).animate().fadeIn(
          delay: (index * 50).ms,
          duration: 600.ms,
        ).slideX(
          begin: 0.2,
          end: 0,
        );
      },
    );
  }
}

class BreedCard extends StatelessWidget {
  final CatBreed breed;
  final VoidCallback onTap;

  const BreedCard({
    super.key,
    required this.breed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              // Breed image placeholder
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: const Icon(
                  Icons.pets,
                  color: AppTheme.primaryColor,
                  size: 32,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Breed info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            breed.name,
                            style: AppTextStyles.headline3.copyWith(fontSize: 18),
                          ),
                        ),
                        if (breed.isRare)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Rare',
                              style: AppTextStyles.caption.copyWith(
                                color: AppTheme.errorColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      breed.origin,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      breed.description,
                      style: AppTextStyles.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        _buildCharacteristicChip(
                          'Energy ${breed.energyLevel}/5',
                          AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        _buildCharacteristicChip(
                          'Social ${breed.socialNeeds}/5',
                          AppTheme.secondaryColor,
                        ),
                        if (breed.isHypoallergenic) ...[
                          const SizedBox(width: 8),
                          _buildCharacteristicChip(
                            'Hypoallergenic',
                            AppTheme.accentColor,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCharacteristicChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

enum BreedFilter {
  all,
  popular,
  rare,
  hypoallergenic,
  familyFriendly,
  lowMaintenance,
}

enum BreedSort {
  name,
  origin,
  popularity,
  rarity,
}