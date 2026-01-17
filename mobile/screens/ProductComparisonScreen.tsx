import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  FlatList,
  StyleSheet,
  TouchableOpacity,
  ActivityIndicator,
  ScrollView,
} from 'react-native';
import { useRoute, RouteProp, useNavigation } from '@react-navigation/native';
import { compareProducts, compareWithAI, ApiProduct } from '../services/api';
import { ScreenWrapper } from '../components/ScreenWrapper';
import { ProductCard } from '../components/ProductCard';
import { useTheme } from '../context/ThemeContext';
import { Ionicons } from '@expo/vector-icons';

type RootStackParamList = {
  ProductComparison: { selectedProductIds: number[] };
};

type ProductComparisonRouteProp = RouteProp<RootStackParamList, 'ProductComparison'>;

export const ProductComparisonScreen: React.FC = () => {
  const route = useRoute<ProductComparisonRouteProp>();
  const navigation = useNavigation();
  const { selectedProductIds } = route.params;
  const { colors } = useTheme();

  const [products, setProducts] = useState<ApiProduct[]>([]);
  const [analysis, setAnalysis] = useState<string>('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadComparison();
  }, []);

  const loadComparison = async () => {
    try {
      setLoading(true);
      setError(null);

      const [productsData, analysisData] = await Promise.all([
        compareProducts(selectedProductIds),
        compareWithAI(selectedProductIds),
      ]);

      setProducts(productsData);
      setAnalysis(analysisData.analysis);
    } catch (err: any) {
      setError(err.message || 'Karşılaştırma yüklenemedi');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <ScreenWrapper>
        <View style={styles.center}>
          <ActivityIndicator size="large" color={colors.primary} />
          <Text style={[styles.loadingText, { color: colors.foreground }]}>
            Ürünler karşılaştırılıyor...
          </Text>
        </View>
      </ScreenWrapper>
    );
  }

  if (error) {
    return (
      <ScreenWrapper>
        <View style={styles.center}>
          <Text style={[styles.errorText, { color: colors.destructive }]}>
            {error}
          </Text>
          <TouchableOpacity
            style={[styles.retryButton, { backgroundColor: colors.primary }]}
            onPress={loadComparison}
          >
            <Text style={[styles.retryText, { color: colors.primaryForeground }]}>
              Tekrar Dene
            </Text>
          </TouchableOpacity>
        </View>
      </ScreenWrapper>
    );
  }

  return (
    <ScreenWrapper>
      <ScrollView style={styles.container}>
        {/* Header with Back Button */}
        <View style={styles.header}>
          <TouchableOpacity
            style={[styles.backButton, { backgroundColor: colors.secondary }]}
            onPress={() => navigation.goBack()}
            activeOpacity={0.8}
          >
            <Ionicons name="arrow-back" size={24} color={colors.foreground} />
          </TouchableOpacity>
          <Text style={[styles.title, { color: colors.foreground }]}>
            Ürün Karşılaştırma
          </Text>
          <View style={styles.headerSpacer} />
        </View>

        {/* Products Horizontal List */}
        <FlatList
          data={products}
          keyExtractor={(item) => item.id.toString()}
          horizontal
          showsHorizontalScrollIndicator={false}
          renderItem={({ item }) => (
            <View style={styles.productCard}>
              <ProductCard
                product={item}
                numColumns={1}
              />
            </View>
          )}
          contentContainerStyle={styles.productsList}
        />

        {/* AI Analysis */}
        {analysis && (
          <View style={[styles.analysisContainer, { backgroundColor: colors.secondary }]}>
            <Text style={[styles.analysisTitle, { color: colors.foreground }]}>
              🤖 AI Analizi
            </Text>
            <Text style={[styles.analysisText, { color: colors.foreground }]}>
              {analysis}
            </Text>
          </View>
        )}
      </ScrollView>
    </ScreenWrapper>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
  },
  center: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    textAlign: 'center',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 20,
  },
  backButton: {
    padding: 8,
    borderRadius: 20,
    width: 40,
    height: 40,
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerSpacer: {
    width: 40,
  },
  loadingText: {
    marginTop: 10,
    fontSize: 16,
  },
  errorText: {
    fontSize: 16,
    textAlign: 'center',
    marginBottom: 20,
  },
  retryButton: {
    paddingHorizontal: 20,
    paddingVertical: 10,
    borderRadius: 8,
  },
  retryText: {
    fontSize: 16,
    fontWeight: 'bold',
  },
  productsList: {
    paddingVertical: 10,
  },
  productCard: {
    width: 280,
    marginRight: 16,
  },
  analysisContainer: {
    marginTop: 20,
    padding: 16,
    borderRadius: 12,
  },
  analysisTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  analysisText: {
    fontSize: 16,
    lineHeight: 24,
  },
});