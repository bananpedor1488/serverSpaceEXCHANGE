import { View, Text, StyleSheet, FlatList, TextInput, Pressable, useColorScheme, KeyboardAvoidingView, Platform } from 'react-native';
import { useEffect, useState } from 'react';
import { useLocalSearchParams, router } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import * as Haptics from 'expo-haptics';
import { useAuthStore } from '../../store/auth.store';
import { socketService } from '../../services/socket';

interface Message {
  _id: string;
  sender_identity_id: string;
  encrypted_content: string;
  createdAt: string;
}

export default function ChatScreen() {
  const { id } = useLocalSearchParams();
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputText, setInputText] = useState('');
  const [isTyping, setIsTyping] = useState(false);
  const { identity } = useAuthStore();
  const colorScheme = useColorScheme();
  const isDark = colorScheme === 'dark';

  useEffect(() => {
    if (id) {
      socketService.joinChat(id as string);
      
      socketService.onMessage((msg) => {
        setMessages((prev) => [msg, ...prev]);
        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      });

      socketService.onTyping((data) => {
        if (data.identity_id !== identity?._id) {
          setIsTyping(true);
          setTimeout(() => setIsTyping(false), 2000);
        }
      });
    }
  }, [id]);

  const sendMessage = () => {
    if (!inputText.trim() || !identity) return;

    socketService.sendMessage(id as string, identity._id, inputText, 'text');
    setInputText('');
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
  };

  const handleTyping = () => {
    if (identity) {
      socketService.sendTyping(id as string, identity._id);
    }
  };

  return (
    <KeyboardAvoidingView
      style={[styles.container, { backgroundColor: isDark ? '#000' : '#fff' }]}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      keyboardVerticalOffset={90}
    >
      <View style={[styles.header, { backgroundColor: isDark ? '#1C1C1E' : '#F2F2F7' }]}>
        <Pressable onPress={() => router.back()} style={styles.backButton}>
          <Ionicons name="chevron-back" size={28} color="#007AFF" />
        </Pressable>
        <Text style={[styles.headerTitle, { color: isDark ? '#fff' : '#000' }]}>Чат</Text>
      </View>

      <FlatList
        data={messages}
        inverted
        keyExtractor={(item) => item._id}
        renderItem={({ item }) => {
          const isMine = item.sender_identity_id === identity?._id;
          return (
            <View style={[styles.messageContainer, isMine && styles.myMessageContainer]}>
              <View
                style={[
                  styles.messageBubble,
                  isMine ? styles.myBubble : styles.otherBubble,
                ]}
              >
                <Text style={[styles.messageText, isMine && styles.myMessageText]}>
                  {item.encrypted_content}
                </Text>
              </View>
            </View>
          );
        }}
        contentContainerStyle={styles.messagesList}
      />

      {isTyping && (
        <View style={styles.typingContainer}>
          <Text style={styles.typingText}>печатает...</Text>
        </View>
      )}

      <View style={[styles.inputContainer, { backgroundColor: isDark ? '#1C1C1E' : '#F2F2F7' }]}>
        <TextInput
          style={[styles.input, { color: isDark ? '#fff' : '#000' }]}
          value={inputText}
          onChangeText={(text) => {
            setInputText(text);
            handleTyping();
          }}
          placeholder="Сообщение"
          placeholderTextColor="#8E8E93"
          multiline
        />
        <Pressable
          onPress={sendMessage}
          disabled={!inputText.trim()}
          style={({ pressed }) => [
            styles.sendButton,
            { opacity: pressed ? 0.7 : 1 },
          ]}
        >
          <Ionicons
            name="arrow-up-circle"
            size={32}
            color={inputText.trim() ? '#007AFF' : '#8E8E93'}
          />
        </Pressable>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingTop: 50,
    paddingBottom: 12,
    paddingHorizontal: 16,
    borderBottomWidth: 0.5,
    borderBottomColor: '#E5E5EA',
  },
  backButton: {
    marginRight: 8,
  },
  headerTitle: {
    fontSize: 17,
    fontWeight: '600',
  },
  messagesList: {
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  messageContainer: {
    marginVertical: 4,
    alignItems: 'flex-start',
  },
  myMessageContainer: {
    alignItems: 'flex-end',
  },
  messageBubble: {
    maxWidth: '75%',
    padding: 12,
    borderRadius: 18,
  },
  myBubble: {
    backgroundColor: '#007AFF',
    borderBottomRightRadius: 4,
  },
  otherBubble: {
    backgroundColor: '#E5E5EA',
    borderBottomLeftRadius: 4,
  },
  messageText: {
    fontSize: 17,
    color: '#000',
  },
  myMessageText: {
    color: '#fff',
  },
  typingContainer: {
    paddingHorizontal: 20,
    paddingVertical: 8,
  },
  typingText: {
    fontSize: 14,
    color: '#8E8E93',
    fontStyle: 'italic',
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderTopWidth: 0.5,
    borderTopColor: '#E5E5EA',
  },
  input: {
    flex: 1,
    fontSize: 17,
    paddingHorizontal: 16,
    paddingVertical: 8,
    maxHeight: 100,
  },
  sendButton: {
    marginLeft: 8,
    marginBottom: 4,
  },
});
