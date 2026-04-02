import React, { useState, useEffect } from 'react';
import {
  View, Text, StyleSheet, ScrollView, TouchableOpacity,
  ActivityIndicator, TextInput, Alert, Modal
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../contexts/AuthContext';
import { apiCall } from '../../utils/api';
import { COLORS, SPACING, RADIUS } from '../../utils/theme';

export default function CardScreen() {
  const { user } = useAuth();
  const [balance, setBalance] = useState(0);
  const [cardNumber, setCardNumber] = useState('');
  const [transactions, setTransactions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showTopUp, setShowTopUp] = useState(false);
  const [topUpAmount, setTopUpAmount] = useState('');
  const [topUpLoading, setTopUpLoading] = useState(false);
  const [nfcPulse, setNfcPulse] = useState(false);

  useEffect(() => { fetchCardData(); }, []);

  // NFC pulse animation
  useEffect(() => {
    const interval = setInterval(() => setNfcPulse(p => !p), 1500);
    return () => clearInterval(interval);
  }, []);

  async function fetchCardData() {
    try {
      const [balData, txData] = await Promise.all([
        apiCall('/card/balance', { token: user?.token }),
        apiCall('/card/transactions', { token: user?.token }),
      ]);
      setBalance(balData.balance);
      setCardNumber(balData.card_number);
      setTransactions(txData);
    } catch (e) {} finally { setLoading(false); }
  }

  async function handleTopUp() {
    const amount = parseFloat(topUpAmount);
    if (!amount || amount < 10 || amount > 5000) {
      Alert.alert('Invalid Amount', 'Enter between Rs 10 and Rs 5000');
      return;
    }
    setTopUpLoading(true);
    try {
      const data = await apiCall('/card/topup', {
        method: 'POST',
        body: { amount },
        token: user?.token,
      });
      setBalance(data.balance);
      setShowTopUp(false);
      setTopUpAmount('');
      fetchCardData();
    } catch (e: any) {
      Alert.alert('Error', e.message);
    } finally {
      setTopUpLoading(false);
    }
  }

  const quickAmounts = [100, 200, 500, 1000];

  return (
    <SafeAreaView style={styles.container} edges={['top']}>
      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        <Text style={styles.title}>Metro Card</Text>
        <Text style={styles.subtitle}>Your virtual transit card</Text>

        {loading && (
          <ActivityIndicator color={COLORS.primary} size="large" style={{ marginVertical: 20 }} />
        )}

        {!loading && (
          <>
        {/* Virtual Card */}
        <View style={styles.virtualCard} testID="virtual-metro-card">
          <View style={styles.cardTop}>
            <View>
              <Text style={styles.cardLabel}>KOLKATA METRO</Text>
              <Text style={styles.cardType}>Smart Card</Text>
            </View>
            <View style={[styles.nfcIcon, nfcPulse && styles.nfcPulse]}>
              <Ionicons name="wifi" size={24} color={COLORS.primary} style={{ transform: [{ rotate: '90deg' }] }} />
            </View>
          </View>
          <Text style={styles.cardNumber} testID="card-number">{cardNumber}</Text>
          <View style={styles.cardBottom}>
            <View>
              <Text style={styles.balanceLabel}>BALANCE</Text>
              <Text style={styles.balanceAmount} testID="card-balance">Rs {balance.toFixed(2)}</Text>
            </View>
            <Text style={styles.cardHolder}>{user?.name?.toUpperCase()}</Text>
          </View>
        </View>

        {/* NFC Tap Area */}
        <View style={styles.nfcSection}>
          <TouchableOpacity testID="nfc-tap-button" style={[styles.nfcButton, nfcPulse && styles.nfcButtonPulse]}>
            <Ionicons name="wifi" size={32} color={COLORS.primary} style={{ transform: [{ rotate: '90deg' }] }} />
            <Text style={styles.nfcText}>Tap to Pay (NFC)</Text>
            <Text style={styles.nfcHint}>Hold your phone near the reader</Text>
          </TouchableOpacity>
        </View>

        {/* Actions */}
        <View style={styles.cardActions}>
          <TouchableOpacity
            testID="topup-button"
            style={styles.actionButton}
            onPress={() => setShowTopUp(true)}
          >
            <Ionicons name="add-circle" size={24} color={COLORS.success} />
            <Text style={styles.actionText}>Top Up</Text>
          </TouchableOpacity>
          <TouchableOpacity testID="card-history-button" style={styles.actionButton}>
            <Ionicons name="time" size={24} color={COLORS.secondary} />
            <Text style={styles.actionText}>History</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.actionButton}>
            <Ionicons name="settings" size={24} color={COLORS.textSecondary} />
            <Text style={styles.actionText}>Settings</Text>
          </TouchableOpacity>
        </View>

        {/* Transactions */}
        <Text style={styles.sectionTitle}>Recent Transactions</Text>
        {transactions.length === 0 ? (
          <Text style={styles.noTxn}>No transactions yet</Text>
        ) : (
          transactions.slice(0, 10).map((txn, idx) => (
            <View key={idx} style={styles.txnCard} testID={`transaction-${idx}`}>
              <View style={[styles.txnIcon, { backgroundColor: txn.type === 'topup' ? 'rgba(0,178,89,0.15)' : 'rgba(255,140,0,0.15)' }]}>
                <Ionicons
                  name={txn.type === 'topup' ? 'arrow-down' : 'arrow-up'}
                  size={20}
                  color={txn.type === 'topup' ? COLORS.success : COLORS.primary}
                />
              </View>
              <View style={styles.txnInfo}>
                <Text style={styles.txnType}>{txn.type === 'topup' ? 'Top Up' : 'Payment'}</Text>
                <Text style={styles.txnDesc}>{txn.description || 'Balance recharge'}</Text>
              </View>
              <Text style={[styles.txnAmount, { color: txn.type === 'topup' ? COLORS.success : COLORS.error }]}>
                {txn.type === 'topup' ? '+' : ''}{txn.amount < 0 ? '' : '+'}{typeof txn.amount === 'number' ? `Rs ${Math.abs(txn.amount)}` : txn.amount}
              </Text>
            </View>
          ))
        )}
          </>
        )}
      </ScrollView>

      {/* Top Up Modal */}
      <Modal visible={showTopUp} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Top Up Card</Text>
              <TouchableOpacity testID="close-topup-modal" onPress={() => setShowTopUp(false)}>
                <Ionicons name="close" size={24} color={COLORS.textPrimary} />
              </TouchableOpacity>
            </View>
            <Text style={styles.currentBalance}>Current Balance: Rs {balance.toFixed(2)}</Text>
            <View style={styles.amountInput}>
              <Text style={styles.rupeeSign}>Rs</Text>
              <TextInput
                testID="topup-amount-input"
                style={styles.amountField}
                value={topUpAmount}
                onChangeText={setTopUpAmount}
                keyboardType="numeric"
                placeholder="0"
                placeholderTextColor={COLORS.textSecondary}
              />
            </View>
            <View style={styles.quickAmounts}>
              {quickAmounts.map((amt) => (
                <TouchableOpacity
                  key={amt}
                  testID={`quick-amount-${amt}`}
                  style={[styles.quickBtn, topUpAmount === String(amt) && styles.quickBtnActive]}
                  onPress={() => setTopUpAmount(String(amt))}
                >
                  <Text style={[styles.quickBtnText, topUpAmount === String(amt) && styles.quickBtnTextActive]}>
                    Rs {amt}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
            <TouchableOpacity
              testID="confirm-topup-button"
              style={[styles.confirmButton, topUpLoading && { opacity: 0.6 }]}
              onPress={handleTopUp}
              disabled={topUpLoading}
            >
              {topUpLoading ? (
                <ActivityIndicator color="#000" />
              ) : (
                <Text style={styles.confirmText}>Add Rs {topUpAmount || '0'}</Text>
              )}
            </TouchableOpacity>
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
  virtualCard: {
    backgroundColor: COLORS.surface, borderRadius: RADIUS.xl,
    padding: SPACING.lg, borderWidth: 1, borderColor: COLORS.border,
    marginBottom: SPACING.md,
    shadowColor: COLORS.primary, shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15, shadowRadius: 16, elevation: 8,
  },
  cardTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: SPACING.lg },
  cardLabel: { fontSize: 11, fontWeight: '800', color: COLORS.primary, letterSpacing: 2 },
  cardType: { fontSize: 13, color: COLORS.textSecondary, marginTop: 2 },
  nfcIcon: {
    width: 44, height: 44, borderRadius: 22,
    backgroundColor: 'rgba(255,140,0,0.1)', alignItems: 'center', justifyContent: 'center',
  },
  nfcPulse: {
    shadowColor: COLORS.primary, shadowOpacity: 0.4,
    shadowRadius: 12, elevation: 6,
  },
  cardNumber: { fontSize: 20, fontWeight: '700', color: COLORS.textPrimary, letterSpacing: 3, marginBottom: SPACING.lg },
  cardBottom: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-end' },
  balanceLabel: { fontSize: 10, fontWeight: '700', color: COLORS.textSecondary, letterSpacing: 1 },
  balanceAmount: { fontSize: 24, fontWeight: '900', color: COLORS.textPrimary },
  cardHolder: { fontSize: 12, fontWeight: '600', color: COLORS.textSecondary, letterSpacing: 1 },
  nfcSection: { marginBottom: SPACING.md },
  nfcButton: {
    alignItems: 'center', justifyContent: 'center',
    backgroundColor: COLORS.surface, borderRadius: RADIUS.xl,
    padding: SPACING.lg, borderWidth: 2,
    borderColor: 'rgba(255,140,0,0.2)', borderStyle: 'dashed',
  },
  nfcButtonPulse: { borderColor: COLORS.primary },
  nfcText: { fontSize: 16, fontWeight: '700', color: COLORS.primary, marginTop: SPACING.sm },
  nfcHint: { fontSize: 12, color: COLORS.textSecondary, marginTop: 4 },
  cardActions: { flexDirection: 'row', gap: SPACING.sm, marginBottom: SPACING.lg },
  actionButton: {
    flex: 1, alignItems: 'center', gap: 6,
    backgroundColor: COLORS.surface, borderRadius: RADIUS.lg,
    padding: SPACING.md, borderWidth: 1, borderColor: COLORS.border,
  },
  actionText: { fontSize: 12, fontWeight: '600', color: COLORS.textPrimary },
  sectionTitle: { fontSize: 18, fontWeight: '700', color: COLORS.textPrimary, marginBottom: SPACING.md },
  noTxn: { color: COLORS.textSecondary, textAlign: 'center', marginTop: SPACING.lg },
  txnCard: {
    flexDirection: 'row', alignItems: 'center', gap: SPACING.md,
    backgroundColor: COLORS.surface, borderRadius: RADIUS.lg,
    padding: SPACING.md, marginBottom: SPACING.sm,
    borderWidth: 1, borderColor: COLORS.border,
  },
  txnIcon: { width: 40, height: 40, borderRadius: 20, alignItems: 'center', justifyContent: 'center' },
  txnInfo: { flex: 1 },
  txnType: { fontSize: 14, fontWeight: '600', color: COLORS.textPrimary },
  txnDesc: { fontSize: 12, color: COLORS.textSecondary, marginTop: 2 },
  txnAmount: { fontSize: 15, fontWeight: '700' },
  modalOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.8)', justifyContent: 'flex-end' },
  modalContent: {
    backgroundColor: COLORS.surface, borderTopLeftRadius: RADIUS.xl,
    borderTopRightRadius: RADIUS.xl, padding: SPACING.lg,
  },
  modalHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: SPACING.md },
  modalTitle: { fontSize: 20, fontWeight: '800', color: COLORS.textPrimary },
  currentBalance: { fontSize: 14, color: COLORS.textSecondary, marginBottom: SPACING.md },
  amountInput: {
    flexDirection: 'row', alignItems: 'center',
    backgroundColor: COLORS.surfaceElevated, borderRadius: RADIUS.lg,
    padding: SPACING.md, marginBottom: SPACING.md,
  },
  rupeeSign: { fontSize: 28, fontWeight: '900', color: COLORS.textSecondary, marginRight: SPACING.sm },
  amountField: { flex: 1, fontSize: 32, fontWeight: '900', color: COLORS.textPrimary },
  quickAmounts: { flexDirection: 'row', gap: SPACING.sm, marginBottom: SPACING.lg },
  quickBtn: {
    flex: 1, alignItems: 'center', paddingVertical: 10,
    borderRadius: RADIUS.full, borderWidth: 1, borderColor: COLORS.border,
  },
  quickBtnActive: { backgroundColor: COLORS.primary, borderColor: COLORS.primary },
  quickBtnText: { fontSize: 13, fontWeight: '600', color: COLORS.textSecondary },
  quickBtnTextActive: { color: '#000' },
  confirmButton: {
    backgroundColor: COLORS.primary, borderRadius: RADIUS.full,
    height: 52, alignItems: 'center', justifyContent: 'center',
  },
  confirmText: { fontSize: 16, fontWeight: '700', color: '#000' },
});
