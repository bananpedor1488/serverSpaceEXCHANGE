import { View, Text, StyleSheet, Switch, useColorScheme, Alert } from 'react-native';
import { useState } from 'react';
import * as Haptics from 'expo-haptics';
import Animated, { FadeOut, FadeIn } from 'react-native-reanimated';
import { useAuthStore } from '../../store/auth.store';
import { api } from '../../services/api';

export default function ProfileScreen() {
  const { identity, ephemeralEnabled, setEphemeralEnabled, deviceId } = useAuthStore();
  const [isToggling, setIsToggling] = useState(false);
  const colorScheme = useColorScheme();
  const isDark = colorScheme === 'dark';

  const handleToggle = async (value: boolean) => {
    if (value) {
      Alert.alert(
        'Ephemeral Identity',
        'Твоя личность будет исчезать каждые 24 часа',
        [
          { text: 'Отмена', style: 'cancel' },
          {
            text: 'Включить',
            onPress: async () => {
              Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
              setIsToggling(true);
              await api.toggleEphemeral(deviceId!, value);
              setEphemeralEnabled(value);
              setIsToggling(false);
            },
          },
        ]
      );
    } else {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      setIsToggling(true);
      await api.toggleEphemeral(deviceId!, value);
      setEphemeralEnabled(value);
      setIsToggling(false);
    }
  };

  const getTimeRemaining = () => {
    if (!identity?.expires_at) return null;
    const now = new Date().getTime();
    const expires = new Date(identity.expires_at).getTime();
    const hours = Math.floor((expires - now) / (1000 * 60 * 60));
    return hours > 0 ? `${hours}ч` : 'скоро';
  };

  return (
    <View style={[styles.container, { backgroundColor: isDark ? '#000' : '#fff' }]}>
      <Text style={[styles.title, { color: isDark ? '#fff' : '#000' }]}>Профиль</Text>

      {identity && (
        <Animated.View
          entering={FadeIn}
          exiting={FadeOut}
          style={[styles.card, { backgroundColor: isDark ? '#1C1C1E' : '#F2F2F7' }]}
        >
          <View style={styles.avatarLarge} />
          <Text style={[styles.username, { color: isDark ? '#fff' : '#000' }]}>
            {identity.username}
          </Text>
          {ephemeralEnabled && (
            <Text style={styles.timer}>⏱ {getTimeRemaining()}</Text>
          )}
        </Animated.View>
      )}

      <View style={[styles.settingCard, { backgroundColor: isDark ? '#1C1C1E' : '#F2F2F7' }]}>
        <View style={styles.settingRow}>
          <View>
            <Text style={[styles.settingTitle, { color: isDark ? '#fff' : '#000' }]}>
              Ephemeral Identity
            </Text>
            <Text style={styles.settingDesc}>
              Личность меняется каждые 24 часа
            </Text>
          </View>
          <Switch
            value={ephemeralEnabled}
            onValueChange={handleToggle}
            disabled={isToggling}
            trackColor={{ false: '#767577', true: '#34C759' }}
            thumbColor="#fff"
          />
        </View>
      </View>
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
  card: {
    marginHorizontal: 20,
    padding: 24,
    borderRadius: 16,
    alignItems: 'center',
    marginBottom: 20,
  },
  avatarLarge: {
    width: 100,
    height: 100,
    borderRadius: 50,
    backgroundColor: '#007AFF',
    marginBottom: 16,
  },
  username: {
    fontSize: 24,
    fontWeight: '600',
  },
  timer: {
    fontSize: 15,
    color: '#FF9500',
    marginTop: 8,
  },
  settingCard: {
    marginHorizontal: 20,
    padding: 16,
    borderRadius: 16,
  },
  settingRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  settingTitle: {
    fontSize: 17,
    fontWeight: '600',
    marginBottom: 4,
  },
  settingDesc: {
    fontSize: 13,
    color: '#8E8E93',
  },
});
