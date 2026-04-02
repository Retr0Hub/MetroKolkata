import React, { useState, useEffect } from 'react';
import {
  View, Text, StyleSheet, ScrollView, TouchableOpacity,
  ActivityIndicator, Image, Modal, Alert
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../contexts/AuthContext';
import { apiCall } from '../../utils/api';
import { COLORS, SPACING, RADIUS } from '../../utils/theme';

export default function TicketsScreen() {
  const { user } = useAuth();
  const [tickets, setTickets] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedTicket, setSelectedTicket] = useState<any>(null);

  useEffect(() => { fetchTickets(); }, []);

  async function fetchTickets() {
    try {
      const data = await apiCall('/tickets/my', { token: user?.token });
      setTickets(data);
    } catch (e) {} finally { setLoading(false); }
  }

  function formatDate(iso: string) {
    const d = new Date(iso);
    return d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' });
  }

  return (
    <SafeAreaView style={styles.container} edges={['top']}>
      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        <Text style={styles.title}>My Tickets</Text>
        <Text style={styles.subtitle}>Your booked metro tickets</Text>

        {loading ? (
          <ActivityIndicator color={COLORS.primary} size="large" style={{ marginTop: 40 }} />
        ) : tickets.length === 0 ? (
          <View style={styles.emptyState}>
            <View style={styles.emptyIcon}>
              <Ionicons name="ticket-outline" size={48} color={COLORS.textSecondary} />
            </View>
            <Text style={styles.emptyTitle}>No Tickets Yet</Text>
            <Text style={styles.emptySubtitle}>Book a ticket from the Route tab to get started</Text>
          </View>
        ) : (
          tickets.map((ticket, idx) => {
            const isActive = ticket.status === 'active' && new Date(ticket.valid_until) > new Date();
            return (
              <TouchableOpacity
                key={idx}
                testID={`ticket-${ticket.ticket_id}`}
                style={styles.ticketCard}
                onPress={() => setSelectedTicket(ticket)}
                activeOpacity={0.7}
              >
                <View style={styles.ticketHeader}>
                  <Text style={styles.ticketId}>#{ticket.ticket_id}</Text>
                  <View style={[styles.statusBadge, !isActive && styles.statusExpired]}>
                    <Text style={[styles.statusText, !isActive && styles.statusTextExpired]}>
                      {isActive ? 'Active' : 'Expired'}
                    </Text>
                  </View>
                </View>
                <View style={styles.ticketRoute}>
                  <View style={styles.routeDots}>
                    <View style={[styles.dot, { backgroundColor: COLORS.secondary }]} />
                    <View style={styles.routeLineH} />
                    <View style={[styles.dot, { backgroundColor: COLORS.primary }]} />
                  </View>
                  <View style={styles.routeNames}>
                    <Text style={styles.stationName}>{ticket.source}</Text>
                    <Text style={styles.stationName}>{ticket.destination}</Text>
                  </View>
                </View>
                <View style={styles.ticketFooter}>
                  <Text style={styles.ticketDetail}>Rs {ticket.fare} | {ticket.num_passengers} pax</Text>
                  <Text style={styles.ticketDate}>{formatDate(ticket.booked_at)}</Text>
                </View>
              </TouchableOpacity>
            );
          })
        )}
      </ScrollView>

      {/* QR Code Modal */}
      <Modal visible={selectedTicket !== null} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Ticket QR Code</Text>
              <TouchableOpacity testID="close-qr-modal" onPress={() => setSelectedTicket(null)}>
                <Ionicons name="close" size={24} color={COLORS.textPrimary} />
              </TouchableOpacity>
            </View>
            {selectedTicket && (
              <View style={styles.qrContainer}>
                <Text style={styles.qrTicketId}>#{selectedTicket.ticket_id}</Text>
                <View style={styles.qrWrapper}>
                  {selectedTicket.qr_code ? (
                    <Image
                      testID="ticket-qr-image"
                      source={{ uri: `data:image/png;base64,${selectedTicket.qr_code}` }}
                      style={styles.qrImage}
                    />
                  ) : (
                    <View style={styles.qrPlaceholder}>
                      <Ionicons name="qr-code" size={80} color={COLORS.textSecondary} />
                    </View>
                  )}
                </View>
                <View style={styles.qrDetails}>
                  <Text style={styles.qrRoute}>{selectedTicket.source} → {selectedTicket.destination}</Text>
                  <Text style={styles.qrFare}>Fare: Rs {selectedTicket.fare}</Text>
                  <Text style={styles.qrValid}>Valid until: {formatDate(selectedTicket.valid_until)}</Text>
                </View>
                <Text style={styles.qrHint}>Scan this QR at the metro gate</Text>
              </View>
            )}
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
  emptyState: { alignItems: 'center', marginTop: 60 },
  emptyIcon: {
    width: 80, height: 80, borderRadius: 40,
    backgroundColor: COLORS.surface, alignItems: 'center',
    justifyContent: 'center', marginBottom: SPACING.md,
  },
  emptyTitle: { fontSize: 18, fontWeight: '700', color: COLORS.textPrimary },
  emptySubtitle: { fontSize: 14, color: COLORS.textSecondary, marginTop: 4, textAlign: 'center' },
  ticketCard: {
    backgroundColor: COLORS.surface, borderRadius: RADIUS.xl,
    padding: SPACING.md, marginBottom: SPACING.sm,
    borderWidth: 1, borderColor: COLORS.border,
  },
  ticketHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: SPACING.sm },
  ticketId: { fontSize: 14, fontWeight: '800', color: COLORS.primary },
  statusBadge: {
    backgroundColor: 'rgba(0,178,89,0.15)', paddingHorizontal: 10,
    paddingVertical: 3, borderRadius: RADIUS.full,
  },
  statusExpired: { backgroundColor: 'rgba(255,68,68,0.15)' },
  statusText: { fontSize: 11, fontWeight: '700', color: COLORS.success },
  statusTextExpired: { color: COLORS.error },
  ticketRoute: { marginBottom: SPACING.sm },
  routeDots: { flexDirection: 'row', alignItems: 'center', gap: 4, marginBottom: 6 },
  dot: { width: 10, height: 10, borderRadius: 5 },
  routeLineH: { flex: 1, height: 2, backgroundColor: COLORS.border },
  routeNames: { flexDirection: 'row', justifyContent: 'space-between' },
  stationName: { fontSize: 14, fontWeight: '600', color: COLORS.textPrimary },
  ticketFooter: { flexDirection: 'row', justifyContent: 'space-between' },
  ticketDetail: { fontSize: 12, color: COLORS.textSecondary },
  ticketDate: { fontSize: 12, color: COLORS.textSecondary },
  modalOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.8)', justifyContent: 'center', padding: SPACING.lg },
  modalContent: {
    backgroundColor: COLORS.surface, borderRadius: RADIUS.xl,
    padding: SPACING.lg,
  },
  modalHeader: {
    flexDirection: 'row', justifyContent: 'space-between',
    alignItems: 'center', marginBottom: SPACING.lg,
  },
  modalTitle: { fontSize: 20, fontWeight: '800', color: COLORS.textPrimary },
  qrContainer: { alignItems: 'center' },
  qrTicketId: { fontSize: 18, fontWeight: '800', color: COLORS.primary, marginBottom: SPACING.md },
  qrWrapper: {
    backgroundColor: '#FFFFFF', borderRadius: RADIUS.lg,
    padding: SPACING.md, marginBottom: SPACING.md,
  },
  qrImage: { width: 200, height: 200 },
  qrPlaceholder: { width: 200, height: 200, alignItems: 'center', justifyContent: 'center', backgroundColor: COLORS.surfaceElevated },
  qrDetails: { alignItems: 'center', gap: 4, marginBottom: SPACING.md },
  qrRoute: { fontSize: 16, fontWeight: '700', color: COLORS.textPrimary },
  qrFare: { fontSize: 14, color: COLORS.success, fontWeight: '600' },
  qrValid: { fontSize: 12, color: COLORS.textSecondary },
  qrHint: { fontSize: 12, color: COLORS.textSecondary, fontStyle: 'italic' },
});
