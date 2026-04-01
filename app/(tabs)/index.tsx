import { View, Text, FlatList, StyleSheet, Pressable, useColorScheme } from 'react-native';
import { useEffect, useState } from 'react';
import { router } from 'expo-router';
import { useAuthStore } from '../../store/auth.store';
import { api } from '../../services/api';
import { socketService } from '../../services/socket';

export default function ChatsScreen() {
  const [chats, setChats] = useState([]);
  const { identity, userId } = useAuthStore();
  const colorScheme = useColorScheme();
  const isDark = colorScheme === 'dark';

  useEffect(() => {
    if (identity && userId) {
      socketService.connect(userId);
      loadChats();
    }
  }, [identity, userId]);

  const loadChats = async () => {
    if (!identity) return;
    const data = await api.getUserChats(identity._id);
    setChats(data);
  };

  return (
    <View style={[styles.container, { backgroundColor: isDark ? '#000' : '#fff' }]}>
      <Text style={[styles.title, { color: isDark ? '#fff' : '#000' }]}>Чаты</Text>
      
      <FlatList
        data={chats}
        keyExtractor={(item: any) => item._id}
        renderItem={({ item }) => (
          <Pressable
            style={({ pressed }) => [
              styles.chatItem,
              { 
                backgroundColor: isDark ? '#1C1C1E' : '#F2F2F7',
                opacity: pressed ? 0.7 : 1,
              },
            ]}
            onPress={() => router.push(`/chat/${item._id}`)}
          >
            <View style={styles.avatar} />
            <Text style={[styles.chatName, { color: isDark ? '#fff' : '#000' }]}>
              {item.group_name || 'Чат'}
            </Text>
          </Pressable>
        )}
        ListEmptyComponent={
          <Text style={[styles.empty, { color: isDark ? '#8E8E93' : '#8E8E93' }]}>
            Нет чатов
          </Text>
        }
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingTop: 60,
  },
  title: {
    fontSize: 34,
    fontWeight: 'bold',
    paddingHorizontal: 20,
    marginBottom: 20,
  },
  chatItem: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    marginHorizontal: 16,
    marginVertical: 4,
    borderRadius: 12,
  },
  avatar: {
    width: 50,
    height: 50,
    borderRadius: 25,
    backgroundColor: '#007AFF',
    marginRight: 12,
  },
  chatName: {
    fontSize: 17,
    fontWeight: '600',
  },
  empty: {
    textAlign: 'center',
    marginTop: 100,
    fontSize: 17,
  },
});
