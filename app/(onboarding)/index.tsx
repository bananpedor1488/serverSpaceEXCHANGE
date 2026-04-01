import { View, Text, StyleSheet, Pressable, useColorScheme } from 'react-native';
import { useState, useEffect } from 'react';
import { router } from 'expo-router';
import * as Haptics from 'expo-haptics';
import Animated, { FadeIn, FadeOut, SlideInRight } from 'react-native-reanimated';
import { useAuthStore } from '../../store/auth.store';
import { api } from '../../services/api';

export default function OnboardingScreen() {
  const [step, setStep] = useState(0);
  const [username, setUsername] = useState('');
  const colorScheme = useColorScheme();
  const isDark = colorScheme === 'dark';
  const { setAuth, setDeviceId } = useAuthStore();

  useEffect(() => {
    const timer = setTimeout(() => {
      if (step === 0) setStep(1);
      else if (step === 1) setStep(2);
    }, 2000);
    return () => clearTimeout(timer);
  }, [step]);

  const generateIdentity = async () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    const deviceId = Math.random().toString(36).substring(2);
    const publicKey = Math.random().toString(36).substring(2);
    
    const data = await api.register(deviceId, publicKey);
    setDeviceId(deviceId);
    setAuth(data.user_id, data.identity);
    
    router.replace('/(tabs)');
  };

  return (
    <View style={[styles.container, { backgroundColor: isDark ? '#000' : '#fff' }]}>
      {step >= 0 && (
        <Animated.Text
          entering={FadeIn.duration(1000)}
          exiting={FadeOut}
          style={[styles.text, { color: isDark ? '#fff' : '#000' }]}
        >
          Ты никто.
        </Animated.Text>
      )}
      
      {step >= 1 && (
        <Animated.Text
          entering={FadeIn.duration(1000).delay(500)}
          style={[styles.text, { color: isDark ? '#fff' : '#000' }]}
        >
          Но ты можешь стать кем угодно.
        </Animated.Text>
      )}

      {step >= 2 && (
        <Animated.View entering={SlideInRight.duration(600)} style={styles.buttonContainer}>
          <Pressable
            onPress={generateIdentity}
            style={({ pressed }) => [
              styles.button,
              { opacity: pressed ? 0.7 : 1 },
            ]}
          >
            <Text style={styles.buttonText}>Начать</Text>
          </Pressable>
        </Animated.View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  text: {
    fontSize: 28,
    fontWeight: '300',
    marginVertical: 10,
    textAlign: 'center',
  },
  buttonContainer: {
    marginTop: 40,
  },
  button: {
    backgroundColor: '#007AFF',
    paddingHorizontal: 40,
    paddingVertical: 14,
    borderRadius: 12,
  },
  buttonText: {
    color: '#fff',
    fontSize: 17,
    fontWeight: '600',
  },
});
