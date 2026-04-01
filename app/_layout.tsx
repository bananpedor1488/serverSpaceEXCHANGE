import { Stack } from 'expo-router';
import { useColorScheme } from 'react-native';
import { useEffect } from 'react';
import { useAuthStore } from '../store/auth.store';
import { router } from 'expo-router';
import IdentityUpdateModal from '../components/IdentityUpdateModal';

export default function RootLayout() {
  const colorScheme = useColorScheme();
  const { userId } = useAuthStore();

  useEffect(() => {
    if (!userId) {
      router.replace('/(onboarding)');
    } else {
      router.replace('/(tabs)');
    }
  }, [userId]);

  return (
    <>
      <Stack
        screenOptions={{
          headerShown: false,
          contentStyle: {
            backgroundColor: colorScheme === 'dark' ? '#000' : '#fff',
          },
        }}
      >
        <Stack.Screen name="(onboarding)" />
        <Stack.Screen name="(tabs)" />
        <Stack.Screen name="chat/[id]" />
      </Stack>
      <IdentityUpdateModal />
    </>
  );
}
