import { View, Text, StyleSheet, Modal, useColorScheme } from 'react-native';
import { useEffect, useState } from 'react';
import Animated, { FadeIn, FadeOut, ZoomIn } from 'react-native-reanimated';
import * as Haptics from 'expo-haptics';
import { useAuthStore } from '../store/auth.store';
import { socketService } from '../services/socket';

export default function IdentityUpdateModal() {
  const [visible, setVisible] = useState(false);
  const [newIdentity, setNewIdentity] = useState<any>(null);
  const { setIdentity } = useAuthStore();
  const colorScheme = useColorScheme();
  const isDark = colorScheme === 'dark';

  useEffect(() => {
    socketService.onIdentityUpdate((identity) => {
      setNewIdentity(identity);
      setVisible(true);
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      
      setTimeout(() => {
        setIdentity(identity);
        setVisible(false);
      }, 3000);
    });
  }, []);

  if (!visible || !newIdentity) return null;

  return (
    <Modal transparent visible={visible} animationType="fade">
      <View style={styles.overlay}>
        <Animated.View
          entering={ZoomIn.duration(600)}
          exiting={FadeOut}
          style={[styles.modal, { backgroundColor: isDark ? '#1C1C1E' : '#fff' }]}
        >
          <Text style={[styles.title, { color: isDark ? '#fff' : '#000' }]}>
            Ты стал другим
          </Text>
          <View style={styles.avatar} />
          <Text style={[styles.username, { color: isDark ? '#fff' : '#000' }]}>
            {newIdentity.username}
          </Text>
        </Animated.View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.7)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modal: {
    width: 280,
    padding: 32,
    borderRadius: 24,
    alignItems: 'center',
  },
  title: {
    fontSize: 22,
    fontWeight: '600',
    marginBottom: 24,
  },
  avatar: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: '#007AFF',
    marginBottom: 16,
  },
  username: {
    fontSize: 20,
    fontWeight: '500',
  },
});
