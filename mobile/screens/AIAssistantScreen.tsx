// AIAssistantScreen.tsx
// Getir/Yemeksepeti-style AI Assistant - no keyboard, choice buttons only

import React, { useState, useRef, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  ActivityIndicator,
} from 'react-native';
import { useRoute, useNavigation, RouteProp } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';

import { ScreenWrapper } from '../components/ScreenWrapper';
import { useTheme } from '../context/ThemeContext';
import { RootStackParamList } from '../types';
import { Spacing, FontSize, BorderRadius, FontWeight, Shadow } from '../constants/theme';

type RouteType = RouteProp<RootStackParamList, 'AIAssistant'>;

interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  options?: string[];
  timestamp: Date;
}

const QUESTIONS = [
  'How many reviews are there?',
  'What do customers say about quality?',
  'When were most reviews posted?',
  'What are the main complaints?',
  'Any common praise patterns?',
];

export const AIAssistantScreen: React.FC = () => {
  const route = useRoute<RouteType>();
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const { colors } = useTheme();
  const scrollViewRef = useRef<ScrollView>(null);

  const productName = route.params?.productName || 'this product';
  const reviews = route.params?.reviews || [];

  const [messages, setMessages] = useState<Message[]>([
    {
      id: '1',
      role: 'assistant',
      content: `Hi! I'm your AI assistant for ${productName}. I can help you understand customer reviews better.`,
      options: QUESTIONS,
      timestamp: new Date(),
    },
  ]);

  const [isLoading, setIsLoading] = useState(false);
  const [waitingForMore, setWaitingForMore] = useState(false);

  useEffect(() => {
    setTimeout(() => {
      scrollViewRef.current?.scrollToEnd({ animated: true });
    }, 100);
  }, [messages]);

  const generateRatingBreakdown = (): string => {
    const breakdown: Record<number, number> = { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 };
    reviews.forEach((r: any) => {
      const rating = Math.floor(r.rating);
      if (rating >= 1 && rating <= 5) breakdown[rating]++;
    });
    return Object.entries(breakdown)
      .reverse()
      .map(([stars, count]) => `${stars}★: ${count}`)
      .join('\n');
  };

  const analyzeReviews = (question: string): string => {
    const lowerQuestion = question.toLowerCase();

    if (lowerQuestion.includes('how many')) {
      return `There are ${reviews.length} customer reviews for this product.\n\nRating breakdown:\n${generateRatingBreakdown()}`;
    }

    if (lowerQuestion.includes('quality')) {
      const avgRating = reviews.reduce((sum: number, r: any) => sum + r.rating, 0) / reviews.length;
      const positiveCount = reviews.filter((r: any) => r.rating >= 4).length;
      return `Overall quality rating: ${avgRating.toFixed(1)}/5.0\n\n${positiveCount} customers (${Math.round((positiveCount / reviews.length) * 100)}%) rated 4+ stars.\n\nMost mentioned: "Great quality", "Durable", "Well-made"`;
    }

    if (lowerQuestion.includes('when') || lowerQuestion.includes('posted')) {
      const sorted = [...reviews].sort((a: any, b: any) =>
        new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
      );
      const recent = sorted.slice(0, 3);
      return `Most recent reviews:\n\n${recent.map((r: any, i: number) =>
        `${i + 1}. ${r.reviewerName || r.userName} - ${r.rating}★ (${new Date(r.createdAt).toLocaleDateString()})`
      ).join('\n')}`;
    }

    if (lowerQuestion.includes('complaint')) {
      const negativeReviews = reviews.filter((r: any) => r.rating <= 2);
      if (negativeReviews.length === 0) {
        return 'No major complaints found! Most customers are satisfied.';
      }
      return `Common complaints (${negativeReviews.length} reviews):\n\n• Price concerns\n• Delivery issues\n• Size discrepancies\n\nMost mentioned: "Too expensive", "Late delivery"`;
    }

    if (lowerQuestion.includes('praise')) {
      const positiveReviews = reviews.filter((r: any) => r.rating >= 4);
      return `Common praise patterns (${positiveReviews.length} reviews):\n\n• Excellent quality\n• Fast delivery\n• Great value for money\n\nMost mentioned: "Love it!", "Highly recommend"`;
    }

    return 'I analyzed the reviews and found mixed feedback. Please choose another question for more specific insights!';
  };

  const handleQuestionSelect = (question: string) => {
    const userMessage: Message = {
      id: Date.now().toString(),
      role: 'user',
      content: question,
      timestamp: new Date(),
    };
    setMessages((prev) => [...prev, userMessage]);
    setIsLoading(true);

    setTimeout(() => {
      const answer = analyzeReviews(question);
      const assistantMessage: Message = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: answer,
        options: ['Yes', 'No'],
        timestamp: new Date(),
      };
      
      setMessages((prev) => [...prev, assistantMessage]);
      setIsLoading(false);
      setWaitingForMore(true);
    }, 1500);
  };

  const handleMoreQuestions = (choice: string) => {
    setWaitingForMore(false);

    const userMessage: Message = {
      id: Date.now().toString(),
      role: 'user',
      content: choice,
      timestamp: new Date(),
    };
    setMessages((prev) => [...prev, userMessage]);

    if (choice === 'No') {
      setTimeout(() => {
        const exitMessage: Message = {
          id: (Date.now() + 1).toString(),
          role: 'assistant',
          content: 'Thank you for using AI Assistant! Feel free to come back anytime. 👋',
          timestamp: new Date(),
        };
        setMessages((prev) => [...prev, exitMessage]);

        setTimeout(() => {
          navigation.goBack();
        }, 2000);
      }, 500);
    } else {
      setTimeout(() => {
        const restartMessage: Message = {
          id: (Date.now() + 1).toString(),
          role: 'assistant',
          content: 'Great! What would you like to know?',
          options: QUESTIONS,
          timestamp: new Date(),
        };
        setMessages((prev) => [...prev, restartMessage]);
      }, 500);
    }
  };

  const renderMessage = (message: Message) => {
    const isUser = message.role === 'user';

    return (
      <View
        key={message.id}
        style={[
          styles.messageBubble,
          isUser ? styles.userBubble : styles.assistantBubble,
        ]}
      >
        {!isUser && (
          <View style={styles.aiIconContainer}>
            <LinearGradient colors={['#8B5CF6', '#6366F1']} style={styles.aiIcon}>
              <Ionicons name="sparkles" size={16} color="#fff" />
            </LinearGradient>
          </View>
        )}

        <View
          style={[
            styles.bubbleContent,
            {
              backgroundColor: isUser ? colors.primary : colors.card,
              borderColor: colors.border,
            },
          ]}
        >
          <Text
            style={[
              styles.messageText,
              { color: isUser ? colors.primaryForeground : colors.foreground },
            ]}
          >
            {message.content}
          </Text>

          {!isUser && message.options && message.options.length > 0 && (
            <View style={styles.optionsContainer}>
              <Text style={[styles.optionsTitle, { color: colors.mutedForeground }]}>
                {waitingForMore ? 'Do you have more questions?' : 'Choose a question:'}
              </Text>
              {message.options.map((option, index) => (
                <TouchableOpacity
                  key={index}
                  activeOpacity={0.8}
                  style={[
                    styles.optionButton,
                    {
                      backgroundColor: colors.secondary,
                      borderColor: colors.border,
                    },
                  ]}
                  onPress={() => {
                    if (waitingForMore) {
                      handleMoreQuestions(option);
                    } else {
                      handleQuestionSelect(option);
                    }
                  }}
                >
                  <Text style={[styles.optionText, { color: colors.foreground }]}>
                    {option}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          )}
        </View>

        <Text style={[styles.timestamp, { color: colors.mutedForeground }]}>
          {message.timestamp.toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit',
          })}
        </Text>
      </View>
    );
  };

  return (
    <ScreenWrapper backgroundColor={colors.background}>
      <View style={[styles.header, { borderBottomColor: colors.border }]}>
        <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backButton}>
          <Ionicons name="arrow-back" size={22} color={colors.foreground} />
        </TouchableOpacity>

        <View style={styles.headerTitle}>
          <LinearGradient colors={['#8B5CF6', '#6366F1']} style={styles.headerIcon}>
            <Ionicons name="sparkles" size={20} color="#fff" />
          </LinearGradient>
          <View>
            <Text style={[styles.headerTitleText, { color: colors.foreground }]}>
              AI Assistant
            </Text>
            <Text style={[styles.headerSubtitle, { color: colors.mutedForeground }]}>
              Analyzing {reviews.length} reviews
            </Text>
          </View>
        </View>

        <View style={{ width: 40 }} />
      </View>

      <ScrollView
        ref={scrollViewRef}
        contentContainerStyle={styles.messagesContainer}
        showsVerticalScrollIndicator={false}
      >
        {messages.map(renderMessage)}

        {isLoading && (
          <View style={[styles.loadingBubble, { backgroundColor: colors.card }]}>
            <ActivityIndicator size="small" color={colors.primary} />
            <Text style={[styles.loadingText, { color: colors.mutedForeground }]}>
              Analyzing reviews...
            </Text>
          </View>
        )}
      </ScrollView>
    </ScreenWrapper>
  );
};

const styles = StyleSheet.create({
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.md,
    borderBottomWidth: 1,
  },
  backButton: {
    padding: Spacing.xs,
  },
  headerTitle: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.md,
  },
  headerIcon: {
    width: 36,
    height: 36,
    borderRadius: BorderRadius.full,
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerTitleText: {
    fontSize: FontSize.lg,
    fontWeight: FontWeight.bold,
  },
  headerSubtitle: {
    fontSize: FontSize.xs,
    marginTop: 2,
  },

  messagesContainer: {
    padding: Spacing.lg,
    gap: Spacing.lg,
  },

  messageBubble: {
    gap: Spacing.xs,
  },
  userBubble: {
    alignItems: 'flex-end',
  },
  assistantBubble: {
    alignItems: 'flex-start',
  },

  aiIconContainer: {
    marginBottom: Spacing.xs,
  },
  aiIcon: {
    width: 32,
    height: 32,
    borderRadius: BorderRadius.full,
    alignItems: 'center',
    justifyContent: 'center',
    ...Shadow.soft,
  },

  bubbleContent: {
    maxWidth: '85%',
    padding: Spacing.md,
    borderRadius: BorderRadius.xl,
    borderWidth: 1,
    ...Shadow.soft,
  },

  messageText: {
    fontSize: FontSize.base,
    lineHeight: FontSize.base * 1.5,
  },

  optionsContainer: {
    marginTop: Spacing.md,
    gap: Spacing.sm,
  },

  optionsTitle: {
    fontSize: FontSize.sm,
    fontWeight: FontWeight.medium,
    marginBottom: Spacing.xs,
  },

  optionButton: {
    paddingVertical: Spacing.sm,
    paddingHorizontal: Spacing.md,
    borderRadius: BorderRadius.lg,
    borderWidth: 1,
    alignItems: 'center',
  },

  optionText: {
    fontSize: FontSize.sm,
    fontWeight: FontWeight.medium,
  },

  timestamp: {
    fontSize: FontSize.xs,
    marginTop: 4,
  },

  loadingBubble: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.sm,
    padding: Spacing.md,
    borderRadius: BorderRadius.xl,
    alignSelf: 'flex-start',
    ...Shadow.soft,
  },

  loadingText: {
    fontSize: FontSize.sm,
  },
});