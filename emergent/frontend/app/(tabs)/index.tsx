import React, { useEffect, useState } from 'react';
import {
  View, Text, StyleSheet, ScrollView, TouchableOpacity,
  ActivityIndicator, RefreshControl
} from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../contexts/AuthContext';
import { apiCall } from '../../utils/api';
import { COLORS, SPACING, RADIUS } from '../../utils/theme';

const LINE_COLORS: Record<string, string> = {
  blue: '#0078D7', green: '#00B259', purple: '#800080', orange: '#FF8C00'
};

export default function HomeScreen() {
  const { user } = useAuth();
  const router = useRouter();
  const [lines, setLines] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => { fetchData(); }, []);

  async function fetchData() {
    try {
      const data = await apiCall('/metro/lines');
      setLines(data);
    } catch (e) {} finally { setLoading(false); setRefreshing(false); }
  }

  const quickActions = [
    { icon: 'navigate', label: 'Find Route', color: COLORS.secondary, route: '/(tabs)/route' },
    { icon: 'ticket', label: 'Buy Ticket', color: COLORS.success, route: '/(tabs)/tickets' },
    { icon: 'card', label: 'Metro Card', color: COLORS.primary, route: '/(tabs)/card' },
    { icon: 'chatbubble-ellipses', label: 'AI Chat', color: '#E040FB', route: '/chat' },
  ];

  const hour = new Date().getHours();
  const greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';

  return (
    <SafeAreaView style={styles.container} edges={['top']}>
      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.scrollContent}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => { setRefreshing(true); fetchData(); }} tintColor={COLORS.primary} />}
      >
        {/* Header */}
        <View style={styles.header}>
          <View>
            <Text style={styles.greeting} testID="home-greeting">{greeting}</Text>
            <Text style={styles.userName}>{user?.name || 'Traveller'}</Text>
          </View>
          <TouchableOpacity testID="home-chat-btn" style={styles.chatFab} onPress={() => router.push('/chat')}>
            <Ionicons name="chatbubble-ellipses" size={22} color="#000" />
          </TouchableOpacity>
        </View>

        {/* Metro Status */}
        <View style={styles.statusCard}>
          <View style={styles.statusDot} />
          <Text style={styles.statusText}>Metro Services Active</Text>
          <Text style={styles.statusTime}>6:45 AM - 9:45 PM</Text>
        </View>

        {/* Quick Actions */}
        <Text style={styles.sectionTitle}>Quick Actions</Text>
        <View style={styles.actionsGrid}>
          {quickActions.map((action, idx) => (
            <TouchableOpacity
              key={idx}
              testID={`quick-action-${action.label.toLowerCase().replace(' ', '-')}`}
              style={styles.actionCard}
              onPress={() => router.push(action.route as any)}
              activeOpacity={0.7}
            >
              <View style={[styles.actionIcon, { backgroundColor: action.color + '20' }]}>
                <Ionicons name={action.icon as any} size={24} color={action.color} />
              </View>
              <Text style={styles.actionLabel}>{action.label}</Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* Metro Lines */}
        <Text style={styles.sectionTitle}>Metro Lines</Text>
        {loading ? (
          <ActivityIndicator color={COLORS.primary} size="large" />
        ) : (
          lines.map((line) => (
            <TouchableOpacity
              key={line.id}
              testID={`metro-line-${line.id}`}
              style={styles.lineCard}
              activeOpacity={0.7}
            >
              <View style={[styles.lineIndicator, { backgroundColor: LINE_COLORS[line.id] || COLORS.primary }]} />
              <View style={styles.lineInfo}>
                <Text style={styles.lineName}>{line.name}</Text>
                <Text style={styles.lineStations}>{line.station_count} stations</Text>
                <Text style={styles.lineRange} numberOfLines={1}>
                  {line.stations[0]} → {line.stations[line.stations.length - 1]}
                </Text>
              </View>
              <Ionicons name="chevron-forward" size={20} color={COLORS.textSecondary} />
            </TouchableOpacity>
          ))
        )}

        {/* Popular Routes */}
        <Text style={styles.sectionTitle}>Popular Routes</Text>
        {[
          { from: 'Dum Dum', to: 'Park Street' },
          { from: 'Salt Lake Sector V', to: 'Esplanade' },
          { from: 'Howrah', to: 'Sealdah' },
        ].map((route, idx) => (
          <TouchableOpacity
            key={idx}
            testID={`popular-route-${idx}`}
            style={styles.routeCard}
            onPress={() => router.push({ pathname: '/(tabs)/route', params: { from: route.from, to: route.to } })}
            activeOpacity={0.7}
          >
            <View style={styles.routeStations}>
              <View style={styles.routeDot} />
              <View style={styles.routeLine} />
              <View style={[styles.routeDot, { backgroundColor: COLORS.primary }]} />
            </View>
            <View style={styles.routeInfo}>
              <Text style={styles.routeFrom}>{route.from}</Text>
              <Text style={styles.routeTo}>{route.to}</Text>
            </View>
            <Ionicons name="arrow-forward-circle" size={28} color={COLORS.primary} />
          </TouchableOpacity>
        ))}

        <View style={{ height: 20 }} />
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: COLORS.background },
  scrollContent: { padding: SPACING.md },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: SPACING.lg },
  greeting: { fontSize: 14, color: COLORS.textSecondary, fontWeight: '500' },
  userName: { fontSize: 26, fontWeight: '900', color: COLORS.textPrimary, marginTop: 2 },
  chatFab: {
    width: 48, height: 48, borderRadius: 24,
    backgroundColor: COLORS.primary, alignItems: 'center', justifyContent: 'center',
  },
  statusCard: {
    flexDirection: 'row', alignItems: 'center',
    backgroundColor: COLORS.surface, borderRadius: RADIUS.lg,
    padding: SPACING.md, borderWidth: 1, borderColor: COLORS.border,
    marginBottom: SPACING.lg, gap: SPACING.sm,
  },
  statusDot: { width: 10, height: 10, borderRadius: 5, backgroundColor: '#00FF88' },
  statusText: { flex: 1, color: COLORS.textPrimary, fontWeight: '600', fontSize: 15 },
  statusTime: { color: COLORS.textSecondary, fontSize: 12 },
  sectionTitle: {
    fontSize: 18, fontWeight: '700', color: COLORS.textPrimary,
    marginBottom: SPACING.md, marginTop: SPACING.sm,
  },
  actionsGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: SPACING.sm, marginBottom: SPACING.md },
  actionCard: {
    width: '48%', flexGrow: 1, backgroundColor: COLORS.surface,
    borderRadius: RADIUS.lg, padding: SPACING.md, borderWidth: 1,
    borderColor: COLORS.border, alignItems: 'center', gap: SPACING.sm,
  },
  actionIcon: {
    width: 52, height: 52, borderRadius: 26,
    alignItems: 'center', justifyContent: 'center',
  },
  actionLabel: { fontSize: 13, fontWeight: '600', color: COLORS.textPrimary },
  lineCard: {
    flexDirection: 'row', alignItems: 'center',
    backgroundColor: COLORS.surface, borderRadius: RADIUS.lg,
    padding: SPACING.md, marginBottom: SPACING.sm,
    borderWidth: 1, borderColor: COLORS.border, gap: SPACING.md,
  },
  lineIndicator: { width: 5, height: 50, borderRadius: 3 },
  lineInfo: { flex: 1 },
  lineName: { fontSize: 15, fontWeight: '700', color: COLORS.textPrimary },
  lineStations: { fontSize: 12, color: COLORS.textSecondary, marginTop: 2 },
  lineRange: { fontSize: 12, color: COLORS.textSecondary, marginTop: 2 },
  routeCard: {
    flexDirection: 'row', alignItems: 'center',
    backgroundColor: COLORS.surface, borderRadius: RADIUS.lg,
    padding: SPACING.md, marginBottom: SPACING.sm,
    borderWidth: 1, borderColor: COLORS.border, gap: SPACING.md,
  },
  routeStations: { alignItems: 'center', gap: 2 },
  routeDot: { width: 10, height: 10, borderRadius: 5, backgroundColor: COLORS.secondary },
  routeLine: { width: 2, height: 20, backgroundColor: COLORS.border },
  routeInfo: { flex: 1 },
  routeFrom: { fontSize: 14, fontWeight: '600', color: COLORS.textPrimary },
  routeTo: { fontSize: 14, fontWeight: '600', color: COLORS.primary, marginTop: 4 },
});
