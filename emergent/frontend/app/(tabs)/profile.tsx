import React, { useState, useEffect } from 'react';
import {
  View, Text, StyleSheet, ScrollView, TouchableOpacity, Alert
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import { useAuth } from '../../contexts/AuthContext';
import { apiCall } from '../../utils/api';
import { COLORS, SPACING, RADIUS } from '../../utils/theme';

export default function ProfileScreen() {
  const { user, logout } = useAuth();
  const router = useRouter();
  const [favorites, setFavorites] = useState<string[]>([]);

  useEffect(() => {
    if (user?.token) {
      apiCall('/favorites', { token: user.token })
        .then((data) => setFavorites(data.favorites || []))
        .catch(() => {});
    }
  }, []);

  async function handleLogout() {
    Alert.alert('Logout', 'Are you sure you want to logout?', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Logout',
        style: 'destructive',
        onPress: async () => {
          await logout();
          router.replace('/(auth)/login');
        },
      },
    ]);
  }

  async function removeFavorite(station: string) {
    try {
      await apiCall('/favorites/remove', {
        method: 'POST',
        body: { station },
        token: user?.token,
      });
      setFavorites(favorites.filter((f) => f !== station));
    } catch (e) {}
  }

  const menuItems = [
    { icon: 'notifications-outline', label: 'Notifications', color: COLORS.primary },
    { icon: 'location-outline', label: 'Location Tracking', color: COLORS.success },
    { icon: 'shield-outline', label: 'Privacy & Security', color: COLORS.secondary },
    { icon: 'help-circle-outline', label: 'Help & Support', color: '#E040FB' },
    { icon: 'information-circle-outline', label: 'About App', color: COLORS.textSecondary },
  ];

  return (
    <SafeAreaView style={styles.container} edges={['top']}>
      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        {/* User Card */}
        <View style={styles.userCard} testID="profile-user-card">
          <View style={styles.avatar}>
            <Text style={styles.avatarText}>{user?.name?.[0]?.toUpperCase() || 'U'}</Text>
          </View>
          <View style={styles.userInfo}>
            <Text style={styles.userName}>{user?.name}</Text>
            <Text style={styles.userEmail}>{user?.email}</Text>
            <View style={styles.roleBadge}>
              <Text style={styles.roleText}>{user?.role?.toUpperCase() || 'USER'}</Text>
            </View>
          </View>
        </View>

        {/* Favorites */}
        <Text style={styles.sectionTitle}>Favorite Stations</Text>
        {favorites.length === 0 ? (
          <View style={styles.emptyFav}>
            <Ionicons name="heart-outline" size={24} color={COLORS.textSecondary} />
            <Text style={styles.emptyFavText}>No favorite stations yet</Text>
          </View>
        ) : (
          <View style={styles.favList}>
            {favorites.map((station) => (
              <View key={station} style={styles.favItem}>
                <Ionicons name="heart" size={18} color={COLORS.error} />
                <Text style={styles.favName}>{station}</Text>
                <TouchableOpacity testID={`remove-fav-${station}`} onPress={() => removeFavorite(station)}>
                  <Ionicons name="close-circle" size={20} color={COLORS.textSecondary} />
                </TouchableOpacity>
              </View>
            ))}
          </View>
        )}

        {/* Menu Items */}
        <Text style={styles.sectionTitle}>Settings</Text>
        {menuItems.map((item, idx) => (
          <TouchableOpacity key={idx} style={styles.menuItem} testID={`menu-${item.label.toLowerCase().replace(/\s+/g, '-')}`}>
            <View style={[styles.menuIcon, { backgroundColor: item.color + '15' }]}>
              <Ionicons name={item.icon as any} size={22} color={item.color} />
            </View>
            <Text style={styles.menuLabel}>{item.label}</Text>
            <Ionicons name="chevron-forward" size={18} color={COLORS.textSecondary} />
          </TouchableOpacity>
        ))}

        {/* Logout */}
        <TouchableOpacity
          testID="logout-button"
          style={styles.logoutButton}
          onPress={handleLogout}
          activeOpacity={0.7}
        >
          <Ionicons name="log-out-outline" size={22} color={COLORS.error} />
          <Text style={styles.logoutText}>Logout</Text>
        </TouchableOpacity>

        <Text style={styles.version}>Kolkata Metro v1.0.0</Text>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: COLORS.background },
  scrollContent: { padding: SPACING.md },
  userCard: {
    flexDirection: 'row', alignItems: 'center', gap: SPACING.md,
    backgroundColor: COLORS.surface, borderRadius: RADIUS.xl,
    padding: SPACING.lg, borderWidth: 1, borderColor: COLORS.border,
    marginBottom: SPACING.lg,
  },
  avatar: {
    width: 64, height: 64, borderRadius: 32,
    backgroundColor: COLORS.primary, alignItems: 'center', justifyContent: 'center',
  },
  avatarText: { fontSize: 28, fontWeight: '900', color: '#000' },
  userInfo: { flex: 1 },
  userName: { fontSize: 20, fontWeight: '800', color: COLORS.textPrimary },
  userEmail: { fontSize: 13, color: COLORS.textSecondary, marginTop: 2 },
  roleBadge: {
    alignSelf: 'flex-start', backgroundColor: 'rgba(255,140,0,0.15)',
    paddingHorizontal: 8, paddingVertical: 2, borderRadius: RADIUS.full, marginTop: 4,
  },
  roleText: { fontSize: 10, fontWeight: '800', color: COLORS.primary, letterSpacing: 1 },
  sectionTitle: { fontSize: 18, fontWeight: '700', color: COLORS.textPrimary, marginBottom: SPACING.md },
  emptyFav: {
    flexDirection: 'row', alignItems: 'center', gap: SPACING.sm,
    backgroundColor: COLORS.surface, borderRadius: RADIUS.lg,
    padding: SPACING.md, marginBottom: SPACING.lg,
    borderWidth: 1, borderColor: COLORS.border,
  },
  emptyFavText: { color: COLORS.textSecondary, fontSize: 14 },
  favList: { marginBottom: SPACING.lg },
  favItem: {
    flexDirection: 'row', alignItems: 'center', gap: SPACING.sm,
    backgroundColor: COLORS.surface, borderRadius: RADIUS.lg,
    padding: SPACING.md, marginBottom: SPACING.sm,
    borderWidth: 1, borderColor: COLORS.border,
  },
  favName: { flex: 1, fontSize: 14, fontWeight: '600', color: COLORS.textPrimary },
  menuItem: {
    flexDirection: 'row', alignItems: 'center', gap: SPACING.md,
    backgroundColor: COLORS.surface, borderRadius: RADIUS.lg,
    padding: SPACING.md, marginBottom: SPACING.sm,
    borderWidth: 1, borderColor: COLORS.border,
  },
  menuIcon: { width: 40, height: 40, borderRadius: 20, alignItems: 'center', justifyContent: 'center' },
  menuLabel: { flex: 1, fontSize: 15, fontWeight: '500', color: COLORS.textPrimary },
  logoutButton: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'center',
    gap: SPACING.sm, backgroundColor: 'rgba(255,68,68,0.1)',
    borderRadius: RADIUS.full, height: 52, marginTop: SPACING.lg,
    borderWidth: 1, borderColor: 'rgba(255,68,68,0.2)',
  },
  logoutText: { fontSize: 16, fontWeight: '700', color: COLORS.error },
  version: { textAlign: 'center', color: COLORS.textSecondary, fontSize: 12, marginTop: SPACING.md, marginBottom: SPACING.xl },
});
