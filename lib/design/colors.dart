import 'dart:ui';

/// Единая палитра приложения.
///
/// Глубокий «ночной» фон, графитовые поверхности, фиолетовый как основной
/// цвет действий и циан как акцент для выделения/прогресса.
const Color background = Color(0xFF080B14);
const Color surface = Color(0xFF111827);
const Color surfaceElevated = Color(0xFF192234);

/// Обратная совместимость со старыми именами: теперь это поверхностные цвета.
const Color primary = surface;
const Color purple = Color(0xFF6C5CE7);

/// Основной цвет кнопок и выбранных состояний.
const Color secondary = purple;

/// Акцент: прогресс, активные иконки, подсветка текущего трека.
const Color accent = Color(0xFF22D3EE);

const Color mint = Color(0xFF34D399);
const Color amber = Color(0xFFFBBF24);
const Color danger = Color(0xFFFB7185);

const Color textColor = Color(0xFFF8FAFC);
const Color textMuted = Color(0xFF94A3B8);
const Color textSubtle = Color(0xFF64748B);
const Color outline = Color(0xFF26334A);

/// Тёмный текст на циановых поверхностях.
const Color onAccent = Color(0xFF04121C);
