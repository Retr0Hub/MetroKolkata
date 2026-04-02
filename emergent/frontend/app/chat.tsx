import React, { useState, useRef, useEffect } from 'react';
import {
  View, Text, StyleSheet, TextInput, TouchableOpacity,
  FlatList, KeyboardAvoidingView, Platform, ActivityIndicator
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter, Stack } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../contexts/AuthContext';
import { apiCall } from '../utils/api';
import { COLORS, SPACING, RADIUS } from '../utils/theme';

type Message = {
  id: string;
  role: 'user' | 'assistant';
  content: string;
};

const SUGGESTED_PROMPTS = [
  'First train from Dum Dum?',
  'How to reach Park Street from Howrah?',
  'What are the interchange stations?',
  'Metro fare from Sealdah to Esplanade?',
];

export default function ChatScreen() {
  const { user } = useAuth();
  const router = useRouter();
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [sessionId, setSessionId] = useState<string | null>(null);
  const flatListRef = useRef<FlatList>(null);

  async function sendMessage(text?: string) {
    const msg = text || input.trim();
    if (!msg || loading) return;

    const userMsg: Message = { id: Date.now().toString(), role: 'user', content: msg };
    setMessages((prev) => [...prev, userMsg]);
    setInput('');
    setLoading(true);

    try {
      const data = await apiCall('/chat', {
        method: 'POST',
        body: { message: msg, session_id: sessionId },
        token: user?.token,
      });
      if (data.session_id) setSessionId(data.session_id);
      const botMsg: Message = { id: (Date.now() + 1).toString(), role: 'assistant', content: data.response };
      setMessages((prev) => [...prev, botMsg]);
    } catch (e: any) {
      const errMsg: Message = { id: (Date.now() + 1).toString(), role: 'assistant', content: 'Sorry, I could not process your request. Please try again.' };
      setMessages((prev) => [...prev, errMsg]);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    if (messages.length > 0) {
      setTimeout(() => flatListRef.current?.scrollToEnd({ animated: true }), 100);
    }
  }, [messages]);

  return (
    <SafeAreaView style={styles.container} edges={['top']}>
      <Stack.Screen options={{ headerShown: false }} />
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity testID="chat-back-button" onPress={() => router.back()}>
          <Ionicons name="arrow-back" size={24} color={COLORS.textPrimary} />
        </TouchableOpacity>
        <View style={styles.headerCenter}>
          <View style={styles.aiDot} />
          <Text style={styles.headerTitle}>Metro AI Assistant</Text>
        </View>
        <View style={{ width: 24 }} />
      </View>

      <KeyboardAvoidingView
        style={styles.chatArea}
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        keyboardVerticalOffset={90}
      >
        <FlatList
          ref={flatListRef}
          data={messages}
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.messagesList}
          ListEmptyComponent={
            <View style={styles.emptyChat}>
              <View style={styles.aiAvatar}>
                <Ionicons name="train" size={32} color={COLORS.primary} />
              </View>
              <Text style={styles.emptyTitle}>KolkataMetro AI</Text>
              <Text style={styles.emptySubtitle}>Ask me anything about Kolkata Metro</Text>
              <View style={styles.suggestionsContainer}>
                {SUGGESTED_PROMPTS.map((prompt, idx) => (
                  <TouchableOpacity
                    key={idx}
                    testID={`suggested-prompt-${idx}`}
                    style={styles.suggestionChip}
                    onPress={() => sendMessage(prompt)}
                  >
                    <Text style={styles.suggestionText}>{prompt}</Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>
          }
          renderItem={({ item }) => (
            <View style={[
              styles.messageBubble,
              item.role === 'user' ? styles.userBubble : styles.aiBubble,
            ]}>
              {item.role === 'assistant' && (
                <View style={styles.aiIcon}>
                  <Ionicons name="train" size={14} color={COLORS.primary} />
                </View>
              )}
              <Text style={[
                styles.messageText,
                item.role === 'user' && styles.userMessageText,
              ]}>
                {item.content}
              </Text>
            </View>
          )}
        />

        {loading && (
          <View style={styles.typingIndicator}>
            <ActivityIndicator size="small" color={COLORS.primary} />
            <Text style={styles.typingText}>AI is thinking...</Text>
          </View>
        )}

        {/* Input Area */}
        <View style={styles.inputArea}>
          <TextInput
            testID="chat-input"
            style={styles.textInput}
            value={input}
            onChangeText={setInput}
            placeholder="Ask about metro routes, timings..."
            placeholderTextColor={COLORS.textSecondary}
            multiline
            maxLength={500}
            onSubmitEditing={() => sendMessage()}
          />
          <TouchableOpacity
            testID="chat-send-button"
            style={[styles.sendButton, (!input.trim() || loading) && styles.sendButtonDisabled]}
            onPress={() => sendMessage()}
            disabled={!input.trim() || loading}
          >
            <Ionicons name="send" size={20} color={input.trim() && !loading ? '#000' : COLORS.textSecondary} />
          </TouchableOpacity>
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: COLORS.background },
  header: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    paddingHorizontal: SPACING.md, paddingVertical: SPACING.sm,
    borderBottomWidth: 1, borderBottomColor: COLORS.border,
  },
  headerCenter: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  aiDot: { width: 8, height: 8, borderRadius: 4, backgroundColor: '#00FF88' },
  headerTitle: { fontSize: 17, fontWeight: '700', color: COLORS.textPrimary },
  chatArea: { flex: 1 },
  messagesList: { padding: SPACING.md, flexGrow: 1 },
  emptyChat: { alignItems: 'center', justifyContent: 'center', flex: 1, paddingTop: 60 },
  aiAvatar: {
    width: 64, height: 64, borderRadius: 32,
    backgroundColor: COLORS.surface, alignItems: 'center',
    justifyContent: 'center', borderWidth: 2, borderColor: COLORS.primary,
    marginBottom: SPACING.md,
  },
  emptyTitle: { fontSize: 22, fontWeight: '800', color: COLORS.textPrimary },
  emptySubtitle: { fontSize: 14, color: COLORS.textSecondary, marginTop: 4, marginBottom: SPACING.lg },
  suggestionsContainer: { width: '100%', gap: SPACING.sm },
  suggestionChip: {
    backgroundColor: COLORS.surface, borderRadius: RADIUS.full,
    paddingVertical: 12, paddingHorizontal: SPACING.md,
    borderWidth: 1, borderColor: COLORS.border,
  },
  suggestionText: { color: COLORS.textPrimary, fontSize: 14, textAlign: 'center' },
  messageBubble: {
    maxWidth: '85%', borderRadius: RADIUS.lg,
    padding: SPACING.md, marginBottom: SPACING.sm,
  },
  userBubble: {
    alignSelf: 'flex-end', backgroundColor: COLORS.primary,
    borderBottomRightRadius: 4,
  },
  aiBubble: {
    alignSelf: 'flex-start', backgroundColor: COLORS.surface,
    borderBottomLeftRadius: 4, borderWidth: 1, borderColor: COLORS.border,
  },
  aiIcon: {
    width: 22, height: 22, borderRadius: 11,
    backgroundColor: 'rgba(255,140,0,0.15)', alignItems: 'center',
    justifyContent: 'center', marginBottom: 4,
  },
  messageText: { fontSize: 15, color: COLORS.textPrimary, lineHeight: 22 },
  userMessageText: { color: '#000' },
  typingIndicator: {
    flexDirection: 'row', alignItems: 'center', gap: 8,
    paddingHorizontal: SPACING.md, paddingVertical: 6,
  },
  typingText: { fontSize: 12, color: COLORS.textSecondary },
  inputArea: {
    flexDirection: 'row', alignItems: 'flex-end', gap: SPACING.sm,
    paddingHorizontal: SPACING.md, paddingVertical: SPACING.sm,
    borderTopWidth: 1, borderTopColor: COLORS.border,
    backgroundColor: COLORS.background,
  },
  textInput: {
    flex: 1, backgroundColor: COLORS.surface,
    borderRadius: RADIUS.lg, paddingHorizontal: SPACING.md,
    paddingVertical: 12, color: COLORS.textPrimary,
    fontSize: 15, maxHeight: 100, borderWidth: 1,
    borderColor: COLORS.border,
  },
  sendButton: {
    width: 44, height: 44, borderRadius: 22,
    backgroundColor: COLORS.primary, alignItems: 'center', justifyContent: 'center',
  },
  sendButtonDisabled: { backgroundColor: COLORS.surface },
});
