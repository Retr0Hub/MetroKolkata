export const COLORS = {
  background: '#0A0A0B',
  surface: '#1A1A1C',
  surfaceElevated: '#25252A',
  primary: '#FF8C00',
  secondary: '#0078D7',
  success: '#00B259',
  purple: '#800080',
  textPrimary: '#FFFFFF',
  textSecondary: '#A1A1AA',
  border: 'rgba(255, 255, 255, 0.1)',
  error: '#FF4444',
  metro: {
    blue: '#0078D7',
    green: '#00B259',
    purple: '#800080',
    orange: '#FF8C00',
  }
};

export const SPACING = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 48,
};

export const RADIUS = {
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
  full: 999,
};

export const FONT = {
  h1: { fontSize: 32, fontWeight: '900' as const },
  h2: { fontSize: 24, fontWeight: '700' as const },
  h3: { fontSize: 18, fontWeight: '600' as const },
  body: { fontSize: 16, fontWeight: '400' as const },
  small: { fontSize: 13, fontWeight: '600' as const, textTransform: 'uppercase' as const, letterSpacing: 1.5 },
  caption: { fontSize: 12, fontWeight: '400' as const },
};
