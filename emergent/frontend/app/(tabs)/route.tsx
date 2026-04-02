import React, { useState, useEffect } from 'react';
import {
  View, Text, StyleSheet, ScrollView, TouchableOpacity,
  ActivityIndicator, Modal, FlatList, TextInput
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useLocalSearchParams } from 'expo-router';
import { apiCall } from '../../utils/api';
import { COLORS, SPACING, RADIUS } from '../../utils/theme';

const LINE_COLORS: Record<string, string> = {
  blue: '#0078D7', green: '#00B259', purple: '#800080', orange: '#FF8C00'
};

export default function RouteScreen() {
  const params = useLocalSearchParams<{ from?: string; to?: string }>();
  const [source, setSource] = useState(params.from || '');
  const [destination, setDestination] = useState(params.to || '');
  const [stations, setStations] = useState<any[]>([]);
  const [route, setRoute] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [showPicker, setShowPicker] = useState<'source' | 'destination' | null>(null);
  const [searchText, setSearchText] = useState('');

  useEffect(() => {
    apiCall('/metro/stations').then(setStations).catch(() => {});
  }, []);

  useEffect(() => {
    if (params.from) setSource(params.from);
    if (params.to) setDestination(params.to);
  }, [params.from, params.to]);

  async function findRoute() {
    if (!source || !destination) return;
    setLoading(true);
    try {
      const data = await apiCall('/metro/route', {
        method: 'POST',
        body: { source, destination },
      });
      setRoute(data);
    } catch (e: any) {
      setRoute(null);
    } finally {
      setLoading(false);
    }
  }

  function swapStations() {
    const temp = source;
    setSource(destination);
    setDestination(temp);
    setRoute(null);
  }

  const filteredStations = stations.filter((s) =>
    s.name.toLowerCase().includes(searchText.toLowerCase())
  );

  return (
    <SafeAreaView style={styles.container} edges={['top']}>
      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        <Text style={styles.title}>Find Your Route</Text>
        <Text style={styles.subtitle}>Plan your journey across Kolkata Metro</Text>

        {/* Station Picker */}
        <View style={styles.pickerCard}>
          <TouchableOpacity
            testID="source-picker"
            style={styles.stationInput}
            onPress={() => { setShowPicker('source'); setSearchText(''); }}
          >
            <View style={[styles.stationDot, { backgroundColor: COLORS.secondary }]} />
            <Text style={source ? styles.stationText : styles.placeholderText}>
              {source || 'Select Source Station'}
            </Text>
          </TouchableOpacity>

          <TouchableOpacity testID="swap-stations-button" style={styles.swapButton} onPress={swapStations}>
            <Ionicons name="swap-vertical" size={20} color={COLORS.primary} />
          </TouchableOpacity>

          <TouchableOpacity
            testID="destination-picker"
            style={styles.stationInput}
            onPress={() => { setShowPicker('destination'); setSearchText(''); }}
          >
            <View style={[styles.stationDot, { backgroundColor: COLORS.primary }]} />
            <Text style={destination ? styles.stationText : styles.placeholderText}>
              {destination || 'Select Destination Station'}
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            testID="find-route-button"
            style={[styles.findButton, (!source || !destination) && styles.findButtonDisabled]}
            onPress={findRoute}
            disabled={!source || !destination || loading}
            activeOpacity={0.8}
          >
            {loading ? (
              <ActivityIndicator color="#000" />
            ) : (
              <>
                <Ionicons name="search" size={20} color="#000" />
                <Text style={styles.findButtonText}>Find Route</Text>
              </>
            )}
          </TouchableOpacity>
        </View>

        {/* Route Result */}
        {route && (
          <View style={styles.resultCard} testID="route-result">
            <View style={styles.resultHeader}>
              <Text style={styles.resultTitle}>Route Found</Text>
              <View style={styles.resultBadges}>
                <View style={styles.badge}>
                  <Ionicons name="time" size={14} color={COLORS.primary} />
                  <Text style={styles.badgeText}>{route.estimated_time} min</Text>
                </View>
                <View style={styles.badge}>
                  <Ionicons name="train" size={14} color={COLORS.secondary} />
                  <Text style={styles.badgeText}>{route.total_stations} stations</Text>
                </View>
                <View style={styles.badge}>
                  <Ionicons name="cash" size={14} color={COLORS.success} />
                  <Text style={styles.badgeText}>Rs {route.fare}</Text>
                </View>
              </View>
              {route.line_changes > 0 && (
                <View style={[styles.badge, { backgroundColor: 'rgba(255,140,0,0.15)' }]}>
                  <Ionicons name="git-branch" size={14} color={COLORS.primary} />
                  <Text style={styles.badgeText}>{route.line_changes} line change{route.line_changes > 1 ? 's' : ''}</Text>
                </View>
              )}
            </View>

            {/* Route Timeline */}
            {route.segments.map((seg: any, idx: number) => (
              <View key={idx} style={styles.segment}>
                <Text style={styles.segmentLine}>
                  <View style={[styles.segmentDot, { backgroundColor: seg.color }]} />
                  {'  '}{seg.line_name}
                </Text>
                {seg.stations.map((station: string, sIdx: number) => (
                  <View key={sIdx} style={styles.timelineRow}>
                    <View style={styles.timelineLeft}>
                      <View style={[
                        styles.timelineDot,
                        { backgroundColor: sIdx === 0 || sIdx === seg.stations.length - 1 ? seg.color : COLORS.textSecondary }
                      ]} />
                      {sIdx < seg.stations.length - 1 && (
                        <View style={[styles.timelineLine, { backgroundColor: seg.color + '40' }]} />
                      )}
                    </View>
                    <Text style={[
                      styles.timelineStation,
                      (sIdx === 0 || sIdx === seg.stations.length - 1) && styles.timelineStationBold
                    ]}>
                      {station}
                    </Text>
                  </View>
                ))}
                {idx < route.segments.length - 1 && (
                  <View style={styles.changeIndicator}>
                    <Ionicons name="git-branch" size={16} color={COLORS.primary} />
                    <Text style={styles.changeText}>Change Line</Text>
                  </View>
                )}
              </View>
            ))}
          </View>
        )}
      </ScrollView>

      {/* Station Picker Modal */}
      <Modal visible={showPicker !== null} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>
                Select {showPicker === 'source' ? 'Source' : 'Destination'}
              </Text>
              <TouchableOpacity testID="close-station-picker" onPress={() => setShowPicker(null)}>
                <Ionicons name="close" size={24} color={COLORS.textPrimary} />
              </TouchableOpacity>
            </View>
            <View style={styles.searchWrapper}>
              <Ionicons name="search" size={18} color={COLORS.textSecondary} />
              <TextInput
                testID="station-search-input"
                style={styles.searchInput}
                placeholder="Search station..."
                placeholderTextColor={COLORS.textSecondary}
                value={searchText}
                onChangeText={setSearchText}
                autoFocus
              />
            </View>
            <FlatList
              data={filteredStations}
              keyExtractor={(item) => item.name}
              renderItem={({ item }) => (
                <TouchableOpacity
                  testID={`station-option-${item.name.replace(/\s+/g, '-').toLowerCase()}`}
                  style={styles.stationOption}
                  activeOpacity={0.6}
                  onPress={() => {
                    const picker = showPicker;
                    setShowPicker(null);
                    setTimeout(() => {
                      if (picker === 'source') setSource(item.name);
                      else setDestination(item.name);
                      setRoute(null);
                    }, 100);
                  }}
                >
                  <Text style={styles.stationOptionText}>{item.name}</Text>
                  <View style={styles.stationLineDots}>
                    {item.line_colors.map((c: string, i: number) => (
                      <View key={i} style={[styles.miniDot, { backgroundColor: c }]} />
                    ))}
                  </View>
                </TouchableOpacity>
              )}
            />
          </View>
        </View>
      </Modal>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: COLORS.background },
  scrollContent: { padding: SPACING.md },
  title: { fontSize: 28, fontWeight: '900', color: COLORS.textPrimary },
  subtitle: { fontSize: 14, color: COLORS.textSecondary, marginTop: 4, marginBottom: SPACING.lg },
  pickerCard: {
    backgroundColor: COLORS.surface, borderRadius: RADIUS.xl,
    padding: SPACING.md, borderWidth: 1, borderColor: COLORS.border,
    marginBottom: SPACING.lg,
  },
  stationInput: {
    flexDirection: 'row', alignItems: 'center', gap: SPACING.sm,
    backgroundColor: COLORS.surfaceElevated, borderRadius: RADIUS.md,
    padding: SPACING.md, marginBottom: SPACING.sm,
  },
  stationDot: { width: 12, height: 12, borderRadius: 6 },
  stationText: { fontSize: 15, color: COLORS.textPrimary, fontWeight: '600' },
  placeholderText: { fontSize: 15, color: COLORS.textSecondary },
  swapButton: {
    alignSelf: 'center', width: 40, height: 40, borderRadius: 20,
    backgroundColor: COLORS.surfaceElevated, alignItems: 'center',
    justifyContent: 'center', marginVertical: -8, zIndex: 1,
    borderWidth: 1, borderColor: COLORS.border,
  },
  findButton: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'center',
    backgroundColor: COLORS.primary, borderRadius: RADIUS.full,
    height: 48, gap: SPACING.sm, marginTop: SPACING.sm,
  },
  findButtonDisabled: { opacity: 0.4 },
  findButtonText: { fontSize: 16, fontWeight: '700', color: '#000' },
  resultCard: {
    backgroundColor: COLORS.surface, borderRadius: RADIUS.xl,
    padding: SPACING.md, borderWidth: 1, borderColor: COLORS.border,
  },
  resultHeader: { marginBottom: SPACING.md },
  resultTitle: { fontSize: 20, fontWeight: '800', color: COLORS.textPrimary, marginBottom: SPACING.sm },
  resultBadges: { flexDirection: 'row', gap: SPACING.sm, flexWrap: 'wrap' },
  badge: {
    flexDirection: 'row', alignItems: 'center', gap: 4,
    backgroundColor: COLORS.surfaceElevated, paddingHorizontal: 10,
    paddingVertical: 5, borderRadius: RADIUS.full,
  },
  badgeText: { fontSize: 12, fontWeight: '600', color: COLORS.textPrimary },
  segment: { marginBottom: SPACING.md },
  segmentLine: { fontSize: 13, fontWeight: '700', color: COLORS.textSecondary, marginBottom: 8, flexDirection: 'row', alignItems: 'center' },
  segmentDot: { width: 8, height: 8, borderRadius: 4, display: 'inline' as any },
  timelineRow: { flexDirection: 'row', alignItems: 'flex-start', marginLeft: 4 },
  timelineLeft: { alignItems: 'center', width: 20, marginRight: 10 },
  timelineDot: { width: 10, height: 10, borderRadius: 5, marginTop: 4 },
  timelineLine: { width: 2, height: 20 },
  timelineStation: { fontSize: 14, color: COLORS.textSecondary, paddingVertical: 2 },
  timelineStationBold: { color: COLORS.textPrimary, fontWeight: '700' },
  changeIndicator: {
    flexDirection: 'row', alignItems: 'center', gap: 6,
    backgroundColor: 'rgba(255,140,0,0.1)', padding: 8,
    borderRadius: RADIUS.sm, marginTop: 4,
  },
  changeText: { fontSize: 12, color: COLORS.primary, fontWeight: '600' },
  modalOverlay: {
    flex: 1, backgroundColor: 'rgba(0,0,0,0.8)',
    justifyContent: 'flex-end',
  },
  modalContent: {
    backgroundColor: COLORS.surface, borderTopLeftRadius: RADIUS.xl,
    borderTopRightRadius: RADIUS.xl, maxHeight: '80%',
    padding: SPACING.md,
  },
  modalHeader: {
    flexDirection: 'row', justifyContent: 'space-between',
    alignItems: 'center', marginBottom: SPACING.md,
  },
  modalTitle: { fontSize: 20, fontWeight: '800', color: COLORS.textPrimary },
  searchWrapper: {
    flexDirection: 'row', alignItems: 'center', gap: 8,
    backgroundColor: COLORS.surfaceElevated, borderRadius: RADIUS.md,
    paddingHorizontal: SPACING.md, marginBottom: SPACING.md, height: 48,
  },
  searchInput: { flex: 1, color: COLORS.textPrimary, fontSize: 15 },
  stationOption: {
    flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center',
    paddingVertical: 14, paddingHorizontal: 4,
    borderBottomWidth: 1, borderBottomColor: COLORS.border,
  },
  stationOptionText: { fontSize: 15, color: COLORS.textPrimary, fontWeight: '500' },
  stationLineDots: { flexDirection: 'row', gap: 4 },
  miniDot: { width: 8, height: 8, borderRadius: 4 },
});
