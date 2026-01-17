// React Native ProductListScreen with Server-side Filtering + Dark Mode Toggle + Grid Layout Toggle
import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { getProducts, ApiProduct } from '../services/api';
import { TouchableWithoutFeedback } from 'react-native';
import {
  View,
  Text,
  FlatList,
  StyleSheet,
  TouchableOpacity,
  ActivityIndicator,
  useWindowDimensions,
  Platform,
  Modal,
  TextInput,
} from 'react-native';

import { useNavigation, useFocusEffect } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';

import { ScreenWrapper } from '../components/ScreenWrapper';
import { ProductCard } from '../components/ProductCard';
import { SelectableProductCard } from '../components/SelectableProductCard';
import { CategoryFilter } from '../components/CategoryFilter';
import { SortFilter } from '../components/SortFilter';
import { SearchBar } from '../components/SearchBar';
import { LoadMoreCard } from '../components/LoadMoreCard';
import { useNotifications } from '../context/NotificationContext';
import { useWishlist, WishlistItem } from '../context/WishlistContext';
import { useTheme } from '../context/ThemeContext';

import { RootStackParamList } from '../types';
import { Spacing, FontSize, FontWeight, BorderRadius } from '../constants/theme';

export const ProductListScreen: React.FC = () => {
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const { colors, colorScheme, toggleTheme } = useTheme();
  const { unreadCount } = useNotifications();
  const { wishlistCount } = useWishlist();

  const { width } = useWindowDimensions();
  const isWeb = Platform.OS === 'web';

  // Grid mode: 1, 2, 4 columns (cycles)
  const [gridMode, setGridMode] = useState<1 | 2 | 4>(2);
  
  const numColumns = gridMode;

  // Multi-select mode
  const [isSelectionMode, setIsSelectionMode] = useState(false);
  const [selectedItems, setSelectedItems] = useState<Set<string>>(new Set());
  const { addToWishlist, addMultipleToWishlist, isInWishlist } = useWishlist();


  const [apiProducts, setApiProducts] = useState<ApiProduct[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Pagination states
  const [currentPage, setCurrentPage] = useState(0);
  const [hasMore, setHasMore] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [totalPages, setTotalPages] = useState(0);

  const [selectedCategory, setSelectedCategory] = useState('All');
  const [searchQuery, setSearchQuery] = useState('');
  const [sortBy, setSortBy] = useState('name,asc');
  
  // Yeni filtre state'leri
  const [minPrice, setMinPrice] = useState<number | undefined>(undefined);
  const [maxPrice, setMaxPrice] = useState<number | undefined>(undefined);
  const [minRating, setMinRating] = useState<number | undefined>(undefined);
  
  // Modal state'leri
  const [showPriceModal, setShowPriceModal] = useState(false);
  const [showRatingModal, setShowRatingModal] = useState(false);

  // Toggle grid: 1 → 2 → 4 → 1
  const toggleGridMode = () => {
    setGridMode(prev => {
      if (prev === 1) return 2;
      if (prev === 2) return 4;
      return 1;
    });
  };

  // Get icon for current grid mode
  const getGridIcon = (): keyof typeof Ionicons.glyphMap => {
    if (gridMode === 1) return 'list';
    if (gridMode === 2) return 'grid';
    return 'apps'; // 4 columns
  };


  // Selection handlers
  const handleCardPress = (product: ApiProduct) => {
    if (isSelectionMode) {
      const productId = String((product as any)?.id ?? '');
      const newSelected = new Set(selectedItems);
      if (newSelected.has(productId)) {
        newSelected.delete(productId);
      } else {
        newSelected.add(productId);
      }
      setSelectedItems(newSelected);
      if (newSelected.size === 0) {
        setIsSelectionMode(false);
      }
    } else {
      navigation.navigate('ProductDetails', {
        productId: String((product as any)?.id ?? ''),
        imageUrl: (product as any)?.imageUrl,
        name: (product as any)?.name,
      } as any);
    }
  };

  const handleCardLongPress = (product: ApiProduct) => {
    const productId = String((product as any)?.id ?? '');
    setIsSelectionMode(true);
    setSelectedItems(new Set([productId]));
  };

  // Bulk add selected products to wishlist (professional method name)
  const handleAddMultiple = () => {
    // Convert Set to Array for processing
    const selectedProductIds = Array.from(selectedItems);
    
    // Build wishlist items array
    const itemsToAdd: Array<Omit<WishlistItem, 'addedAt'>> = [];
    
    selectedProductIds.forEach(productId => {
      const product = apiProducts.find(p => String((p as any)?.id) === productId);
      if (product) {
        itemsToAdd.push({
          id: productId,
          name: (product as any)?.name ?? 'Product',
          price: (product as any)?.price,
          imageUrl: (product as any)?.imageUrl,
          category: (product as any)?.category,
          averageRating: (product as any)?.averageRating,
        });
      }
    });
    
    // Add all items to wishlist in one optimized batch
    addMultipleToWishlist(itemsToAdd);
    
    // Reset selection state
    setSelectedItems(new Set());
    setIsSelectionMode(false);
  };

  const handleCancelSelection = () => {
    setSelectedItems(new Set());
    setIsSelectionMode(false);
  };

  const handleCompare = () => {
    const selectedIds = Array.from(selectedItems).map(id => parseInt(id)).filter(id => !isNaN(id));
    if (selectedIds.length >= 2) {
      navigation.navigate('ProductComparison', { selectedProductIds: selectedIds });
      setSelectedItems(new Set());
      setIsSelectionMode(false);
    }
  };

  const fetchProducts = useCallback(async (pageNum: number = 0, append: boolean = false) => {
    try {
      if (!append) {
        setLoading(true);
      } else {
        setLoadingMore(true);
      }
      setError(null);

      const page = await getProducts({ 
        page: pageNum, 
        size: 20,
        sort: sortBy,
        category: selectedCategory,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minRating: minRating
      });
      
      const newProducts = page?.content ?? [];
      
      if (append) {
        setApiProducts(prev => [...prev, ...newProducts]);
      } else {
        setApiProducts(newProducts);
      }
      
      setCurrentPage(pageNum);
      setTotalPages(page?.totalPages ?? 0);
      setHasMore(!page?.last);
      
    } catch (e: any) {
      setError(e?.message ?? 'API error');
    } finally {
      setLoading(false);
      setLoadingMore(false);
    }
  }, [selectedCategory, sortBy]);

  useEffect(() => {
    fetchProducts(0, false);
  }, [selectedCategory, sortBy, minPrice, maxPrice, minRating]);

  useFocusEffect(
    useCallback(() => {
      fetchProducts(0, false);
    }, [selectedCategory, sortBy, minPrice, maxPrice, minRating])
  );

  const loadMoreProducts = useCallback(() => {
    if (!loadingMore && hasMore && !loading) {
      fetchProducts(currentPage + 1, true);
    }
  }, [loadingMore, hasMore, loading, currentPage, fetchProducts]);

  const filteredProducts = useMemo(() => {
    let filtered = apiProducts;

    if (searchQuery.trim()) {
      const query = searchQuery.trim().toLowerCase();
      filtered = filtered.filter((p) => {
        const name = String((p as any)?.name ?? '').toLowerCase();
        const description = String((p as any)?.description ?? '').toLowerCase();
        const category = String((p as any)?.category ?? '').toLowerCase();
        return (
          name.includes(query) ||
          description.includes(query) ||
          category.includes(query)
        );
      });
    }

    return filtered;
  }, [apiProducts, searchQuery]);

  const stats = useMemo(() => {
    const totalReviews = apiProducts.reduce((acc, p) => acc + ((p as any)?.reviewCount ?? 0), 0);
    const sumRating = apiProducts.reduce((acc, p) => acc + ((p as any)?.averageRating ?? 0), 0);
    const avgRating = apiProducts.length > 0 ? sumRating / apiProducts.length : 0;

    return {
      totalReviews,
      avgRating,
      productCount: apiProducts.length,
    };
  }, [apiProducts]);

  const header = useMemo(() => (
    <View>
      <View style={styles.topBar}>
        <View style={styles.logoContainer}>
          <LinearGradient colors={[colors.primary, colors.accent]} style={styles.logoIcon}>
            <Ionicons name="star" size={16} color={colors.primaryForeground} />
          </LinearGradient>
          <Text style={[styles.logoText, { color: colors.foreground }]}>ProductReview</Text>
        </View>

        <View style={styles.headerButtons}>
          {/* Compare Button */}
          {!isSelectionMode && (
            <TouchableOpacity
              style={[styles.compareButton, { backgroundColor: colors.secondary }]}
              onPress={() => setIsSelectionMode(true)}
              activeOpacity={0.8}
            >
              <Ionicons name="git-compare-outline" size={20} color={colors.foreground} />
            </TouchableOpacity>
          )}

          {/* Dark Mode Toggle */}
          <TouchableOpacity
            style={[styles.themeButton, { backgroundColor: colors.secondary }]}
            onPress={toggleTheme}
            activeOpacity={0.8}
          >
            <Ionicons 
              name={colorScheme === 'dark' ? 'sunny' : 'moon'} 
              size={20} 
              color={colors.foreground} 
            />
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.wishlistButton}
            onPress={() => navigation.navigate('Wishlist')}
            activeOpacity={0.8}
          >
            <Ionicons name="heart-outline" size={22} color={colors.foreground} />
            {wishlistCount > 0 && (
              <View style={[styles.badge, { backgroundColor: colors.primary }]}>
                <Text style={styles.badgeText}>{wishlistCount}</Text>
              </View>
            )}
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.notificationButton}
            onPress={() => navigation.navigate('Notifications')}
            activeOpacity={0.8}
          >
            <Ionicons name="notifications-outline" size={22} color={colors.foreground} />
            {unreadCount > 0 && (
              <View style={[styles.badge, { backgroundColor: colors.destructive }]}>
                <Text style={styles.badgeText}>{unreadCount}</Text>
              </View>
            )}
          </TouchableOpacity>
        </View>
      </View>

      <View style={[styles.heroSection, { backgroundColor: colors.secondary }]}>
        <Text style={[styles.heroTitle, { color: colors.foreground }]}>
          Find Products You&apos;ll <Text style={{ color: colors.primary }}>Love</Text>
        </Text>

        <View style={styles.statsRow}>
          {[
            { icon: 'star', value: stats.avgRating.toFixed(1), label: 'Avg Rating' },
            { icon: 'chatbubbles', value: stats.totalReviews.toLocaleString(), label: 'Reviews' },
            { icon: 'cube', value: String(stats.productCount), label: 'Products' },
          ].map((s, i) => (
            <View key={i} style={styles.statItem}>
              <LinearGradient colors={[colors.primary, colors.accent]} style={styles.statIcon}>
                <Ionicons name={s.icon as any} size={18} color={colors.primaryForeground} />
              </LinearGradient>
              <View>
                <Text style={[styles.statValue, { color: colors.foreground }]}>{s.value}</Text>
                <Text style={[styles.statLabel, { color: colors.mutedForeground }]}>{s.label}</Text>
              </View>
            </View>
          ))}
        </View>
      </View>

      <View style={styles.searchSection}>
        <SearchBar value={searchQuery} onChangeText={setSearchQuery} />
      </View>

      {/* Filtre Butonları */}
      <View style={styles.filtersSection}>
        <View style={styles.filterContainer}>
          <TouchableOpacity
            style={[styles.filterButton, { backgroundColor: colors.secondary }]}
            onPress={() => setShowPriceModal(true)}
            activeOpacity={0.8}
          >
            <Ionicons name="cash-outline" size={16} color={colors.foreground} />
            <Text style={[styles.filterButtonText, { color: colors.foreground }]}>
              Fiyat: {minPrice !== undefined || maxPrice !== undefined ? 
                `$${minPrice ?? 0} - ${maxPrice ?? '∞'}$` : 'Tümü'}
            </Text>
          </TouchableOpacity>
          {(minPrice !== undefined || maxPrice !== undefined) && (
            <TouchableOpacity
              style={[styles.clearFilterButton, { backgroundColor: colors.destructive }]}
              onPress={() => {
                setMinPrice(undefined);
                setMaxPrice(undefined);
              }}
              activeOpacity={0.8}
            >
              <Ionicons name="close" size={14} color="#fff" />
            </TouchableOpacity>
          )}
        </View>

        <View style={styles.filterContainer}>
          <TouchableOpacity
            style={[styles.filterButton, { backgroundColor: colors.secondary }]}
            onPress={() => setShowRatingModal(true)}
            activeOpacity={0.8}
          >
            <Ionicons name="star-outline" size={16} color={colors.foreground} />
            <Text style={[styles.filterButtonText, { color: colors.foreground }]}>
              Puan: {minRating !== undefined ? `${minRating}+ yıldız` : 'Tümü'}
            </Text>
          </TouchableOpacity>
          {minRating !== undefined && (
            <TouchableOpacity
              style={[styles.clearFilterButton, { backgroundColor: colors.destructive }]}
              onPress={() => setMinRating(undefined)}
              activeOpacity={0.8}
            >
              <Ionicons name="close" size={14} color="#fff" />
            </TouchableOpacity>
          )}
        </View>
      </View>

      <View style={styles.sectionHeader}>
        <Text style={[styles.sectionTitle, { color: colors.foreground }]}>Explore Products</Text>
      </View>

      <View style={styles.categoryFilterWrapper}>
        <CategoryFilter selectedCategory={selectedCategory} onCategoryChange={setSelectedCategory} />
      </View>

      <View style={styles.sortFilterWrapper}>
        <View style={styles.sortHeader}>
          <Text style={[styles.filterLabel, { color: colors.mutedForeground }]}>Sort by:</Text>
          
          {/* Grid Toggle Button */}
          <TouchableOpacity
            onPress={toggleGridMode}
            style={[styles.gridToggleButton, { backgroundColor: colors.secondary }]}
            activeOpacity={0.8}
          >
            <Ionicons name={getGridIcon()} size={20} color={colors.foreground} />
          </TouchableOpacity>
        </View>
        
        <SortFilter selectedSort={sortBy} onSortChange={setSortBy} />
      </View>

      {loading && <ActivityIndicator style={{ marginTop: 16 }} />}
      {error && <Text style={{ color: colors.destructive, padding: Spacing.lg }}>{error}</Text>}
    </View>
  ), [
    colors,
    colorScheme,
    toggleTheme,
    navigation,
    unreadCount,
    wishlistCount,
    stats,
    searchQuery,
    selectedCategory,
    sortBy,
    loading,
    error,
    gridMode,
  ]);

  return (
    <ScreenWrapper backgroundColor={colors.background}>
      <TouchableWithoutFeedback onPress={() => {
        if (isSelectionMode && selectedItems.size > 0) {
          handleCancelSelection();
        }
      }}>
        <View style={{ flex: 1 }}>
      <FlatList
        data={filteredProducts}
        key={`${numColumns}-${isSelectionMode ? 'select' : 'normal'}`}
        numColumns={numColumns}
        keyExtractor={(item) => String((item as any)?.id)}
        ListHeaderComponent={header}
        contentContainerStyle={[
          styles.listContent,
          isWeb && styles.webMaxWidth,
        ]}
        columnWrapperStyle={numColumns > 1 ? styles.columnWrapper : undefined}
        ItemSeparatorComponent={numColumns === 1 ? () => <View style={{ height: Spacing.md }} /> : undefined}
        renderItem={({ item }) => (
          <View
            style={[
              numColumns > 1 && styles.gridItem,
              numColumns > 1 && { flex: 1, maxWidth: `${100 / numColumns - 1}%` },
              numColumns === 1 && { paddingHorizontal: Spacing.lg },
            ]}
          >
            <SelectableProductCard
              product={item}
              numColumns={numColumns}
              isSelectionMode={isSelectionMode}
              isSelected={selectedItems.has(String((item as any)?.id ?? ''))}
              onPress={handleCardPress}
              onLongPress={handleCardLongPress}
            />
          </View>
        )}
        showsVerticalScrollIndicator={false}
        keyboardShouldPersistTaps="handled"
        keyboardDismissMode="none"
        
        ListFooterComponent={
          <>
            {filteredProducts.length > 0 && (
              <LoadMoreCard
                onPress={loadMoreProducts}
                loading={loadingMore}
                hasMore={hasMore}
                currentPage={currentPage}
                totalPages={totalPages}
              />
            )}
          </>
        }
        
        ListEmptyComponent={
          !loading ? (
            <View style={{ padding: Spacing.xl }}>
              <Text style={{ color: colors.mutedForeground }}>No products found.</Text>
            </View>
          ) : null
        }
      />

          {/* Floating action bar */}
          {isSelectionMode && selectedItems.size > 0 && (
            <View style={[styles.floatingBar, { backgroundColor: colors.card, borderColor: colors.border }]}>
              <TouchableOpacity
                style={[styles.floatingButton, styles.cancelButton]}
                onPress={handleCancelSelection}
                activeOpacity={0.8}
              >
                <Text style={[styles.floatingButtonText, { color: colors.foreground }]}>
                  Cancel
                </Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={[styles.floatingButton, styles.addButton, { backgroundColor: colors.primary }]}
                onPress={handleAddMultiple}
                activeOpacity={0.8}
              >
                <Ionicons name="heart" size={18} color="#fff" />
                <Text style={[styles.floatingButtonText, { color: '#fff' }]}>
                  Add to Wishlist ({selectedItems.size})
                </Text>
              </TouchableOpacity>

              {selectedItems.size >= 2 && (
                <TouchableOpacity
                  style={[styles.floatingButton, styles.compareFloatingButton, { backgroundColor: colors.accent }]}
                  onPress={handleCompare}
                  activeOpacity={0.8}
                >
                  <Ionicons name="git-compare" size={18} color="#fff" />
                  <Text style={[styles.floatingButtonText, { color: '#fff' }]}>
                    Compare ({selectedItems.size})
                  </Text>
                </TouchableOpacity>
              )}
            </View>
          )}
        </View>
      </TouchableWithoutFeedback>

      {/* Fiyat Filtresi Modal */}
      <Modal
        visible={showPriceModal}
        transparent
        animationType="fade"
        onRequestClose={() => setShowPriceModal(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={[styles.modalContent, { backgroundColor: colors.background }]}>
            <Text style={[styles.modalTitle, { color: colors.foreground }]}>Fiyat Aralığı</Text>
            
            <View style={styles.inputRow}>
              <Text style={[styles.inputLabel, { color: colors.foreground }]}>Min:</Text>
              <TextInput
                style={[styles.textInput, { backgroundColor: colors.secondary, color: colors.foreground }]}
                placeholder="0"
                placeholderTextColor={colors.mutedForeground}
                keyboardType="numeric"
                value={minPrice?.toString() ?? ''}
                onChangeText={(text) => setMinPrice(text ? parseInt(text) : undefined)}
              />
            </View>

            <View style={styles.inputRow}>
              <Text style={[styles.inputLabel, { color: colors.foreground }]}>Max:</Text>
              <TextInput
                style={[styles.textInput, { backgroundColor: colors.secondary, color: colors.foreground }]}
                placeholder="Sınırsız"
                placeholderTextColor={colors.mutedForeground}
                keyboardType="numeric"
                value={maxPrice?.toString() ?? ''}
                onChangeText={(text) => setMaxPrice(text ? parseInt(text) : undefined)}
              />
            </View>

            <View style={styles.modalButtons}>
              <TouchableOpacity
                style={[styles.modalButton, styles.cancelModalButton]}
                onPress={() => setShowPriceModal(false)}
              >
                <Text style={[styles.modalButtonText, { color: colors.foreground }]}>İptal</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.modalButton, { backgroundColor: colors.primary }]}
                onPress={() => setShowPriceModal(false)}
              >
                <Text style={[styles.modalButtonText, { color: colors.primaryForeground }]}>Uygula</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      {/* Puan Filtresi Modal */}
      <Modal
        visible={showRatingModal}
        transparent
        animationType="fade"
        onRequestClose={() => setShowRatingModal(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={[styles.modalContent, { backgroundColor: colors.background }]}>
            <Text style={[styles.modalTitle, { color: colors.foreground }]}>Minimum Puan</Text>
            
            {[4, 3, 2, 1].map((rating) => (
              <TouchableOpacity
                key={rating}
                style={[styles.ratingOption, { backgroundColor: minRating === rating ? colors.primary : colors.secondary }]}
                onPress={() => setMinRating(minRating === rating ? undefined : rating)}
              >
                <View style={{ flexDirection: 'row' }}>
                  {[...Array(5)].map((_, i) => (
                    <Ionicons
                      key={i}
                      name={i < rating ? "star" : "star-outline"}
                      size={16}
                      color={minRating === rating ? colors.primaryForeground : colors.foreground}
                    />
                  ))}
                </View>
                <Text style={[styles.ratingText, { color: minRating === rating ? colors.primaryForeground : colors.foreground }]}>
                  {rating}+ yıldız
                </Text>
              </TouchableOpacity>
            ))}

            <View style={styles.modalButtons}>
              <TouchableOpacity
                style={[styles.modalButton, styles.cancelModalButton]}
                onPress={() => setShowRatingModal(false)}
              >
                <Text style={[styles.modalButtonText, { color: colors.foreground }]}>İptal</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.modalButton, { backgroundColor: colors.primary }]}
                onPress={() => setShowRatingModal(false)}
              >
                <Text style={[styles.modalButtonText, { color: colors.primaryForeground }]}>Uygula</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </ScreenWrapper>
  );
};

const styles = StyleSheet.create({
  topBar: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.md,
  },

  logoContainer: { flexDirection: 'row', alignItems: 'center', gap: Spacing.sm },

  logoIcon: {
    width: 32,
    height: 32,
    borderRadius: BorderRadius.md,
    alignItems: 'center',
    justifyContent: 'center',
  },

  logoText: { fontSize: FontSize.lg, fontWeight: FontWeight.bold },

  headerButtons: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.sm,
  },

  themeButton: {
    padding: Spacing.sm,
    borderRadius: BorderRadius.full,
    width: 36,
    height: 36,
    alignItems: 'center',
    justifyContent: 'center',
  },

  wishlistButton: { 
    position: 'relative', 
    padding: Spacing.xs,
  },

  notificationButton: { position: 'relative', padding: Spacing.xs },

  badge: {
    position: 'absolute',
    top: -4,
    right: -4,
    minWidth: 18,
    height: 18,
    borderRadius: 9,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 4,
  },

  badgeText: { color: '#fff', fontSize: 10, fontWeight: '700' },

  heroSection: {
    marginHorizontal: Spacing.lg,
    marginTop: Spacing.sm,
    marginBottom: Spacing.lg,
    borderRadius: BorderRadius.xl,
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing['2xl'],
    alignItems: 'center',
  },

  heroTitle: {
    fontSize: FontSize['2xl'],
    fontWeight: FontWeight.bold,
    textAlign: 'center',
    marginBottom: Spacing.lg,
  },

  statsRow: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: Spacing['2xl'],
    flexWrap: 'wrap',
  },

  statItem: { flexDirection: 'row', alignItems: 'center', gap: Spacing.sm },

  statIcon: {
    width: 36,
    height: 36,
    borderRadius: BorderRadius.full,
    alignItems: 'center',
    justifyContent: 'center',
  },

  statValue: { fontSize: FontSize.lg, fontWeight: FontWeight.bold },
  statLabel: { fontSize: FontSize.xs },

  searchSection: { paddingVertical: Spacing.lg },

  sectionHeader: { paddingHorizontal: Spacing.lg, marginBottom: Spacing.sm },
  sectionTitle: { fontSize: FontSize.xl, fontWeight: FontWeight.bold },

  categoryFilterWrapper: {
    marginBottom: Spacing.lg,
  },

  sortFilterWrapper: {
    marginBottom: Spacing.lg,
  },

  // YENİ: Grid toggle için
  sortHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: Spacing.lg,
    marginBottom: Spacing.xs,
  },

  filterLabel: {
    fontSize: FontSize.sm,
    fontWeight: FontWeight.medium,
  },

  gridToggleButton: {
    width: 36,
    height: 36,
    borderRadius: BorderRadius.md,
    alignItems: 'center',
    justifyContent: 'center',
  },

  listContent: {
    paddingBottom: Spacing['3xl'],
    paddingTop: Spacing.sm,
  },

  columnWrapper: {
    paddingHorizontal: Spacing.lg,
    gap: Spacing.md,
    marginTop: Spacing.xl,
  },

  gridItem: {
    minWidth: 0,
  },

  webMaxWidth: {
    width: '100%',
    maxWidth: 1200,
    alignSelf: 'center',},

  floatingBar: {
    position: 'absolute',
    bottom: Spacing.xl,
    left: Spacing.lg,
    right: Spacing.lg,
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.md,
    padding: Spacing.md,
    borderRadius: BorderRadius.xl,
    borderWidth: 1,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 8,
  },
  floatingButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: Spacing.xs,
    paddingVertical: Spacing.md,
    borderRadius: BorderRadius.lg,
  },
  cancelButton: {
    backgroundColor: 'transparent',
  },
  addButton: {
    // backgroundColor set inline
  },
  floatingButtonText: {
    fontSize: FontSize.sm,
    fontWeight: FontWeight.semibold,
  },

  // Yeni filtre stilleri
  filtersSection: {
    flexDirection: 'row',
    gap: Spacing.sm,
    paddingHorizontal: Spacing.lg,
    marginBottom: Spacing.lg,
  },
  filterContainer: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
  },
  filterButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.xs,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
    borderRadius: BorderRadius.lg,
  },
  filterButtonText: {
    fontSize: FontSize.sm,
    fontWeight: FontWeight.medium,
  },
  clearFilterButton: {
    marginLeft: Spacing.xs,
    width: 24,
    height: 24,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },

  // Modal stilleri
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalContent: {
    margin: Spacing.xl,
    borderRadius: BorderRadius.xl,
    padding: Spacing.xl,
    width: '80%',
    maxWidth: 400,
  },
  modalTitle: {
    fontSize: FontSize.xl,
    fontWeight: FontWeight.bold,
    marginBottom: Spacing.lg,
    textAlign: 'center',
  },
  inputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: Spacing.md,
  },
  inputLabel: {
    width: 40,
    fontSize: FontSize.md,
    fontWeight: FontWeight.medium,
  },
  textInput: {
    flex: 1,
    padding: Spacing.sm,
    borderRadius: BorderRadius.md,
    fontSize: FontSize.md,
  },
  ratingOption: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: Spacing.md,
    borderRadius: BorderRadius.md,
    marginBottom: Spacing.sm,
  },
  ratingText: {
    fontSize: FontSize.md,
    fontWeight: FontWeight.medium,
  },
  modalButtons: {
    flexDirection: 'row',
    gap: Spacing.md,
    marginTop: Spacing.lg,
  },
  modalButton: {
    flex: 1,
    padding: Spacing.md,
    borderRadius: BorderRadius.md,
    alignItems: 'center',
  },
  cancelModalButton: {
    backgroundColor: 'transparent',
  },
  modalButtonText: {
    fontSize: FontSize.md,
    fontWeight: FontWeight.semibold,
  },
  });