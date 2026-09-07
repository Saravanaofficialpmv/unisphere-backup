import 'package:flutter/material.dart';

/// Centralized Design System Color Palette for Unisphere College Management System.
/// Defines all brand, background, text, status, glassmorphic, module, and role colors.
class AppColors {
  // ── BRAND & PRIMARY COLORS ──────────────────────────────────────────────
  static const Color primary = Color(0xFF2563EB); // Royal Indigo Blue (Brand Primary)
  static const Color primaryLight = Color(0xFF3B82F6); // Vibrant Electric Blue
  static const Color primaryDark = Color(0xFF1D4ED8); // Deep Navy Indigo
  static const Color primaryAccent = Color(0xFF3F51B5); // Classic Indigo Accent
  static const Color primarySubtle = Color(0xFFEEF2FF); // Soft Indigo Blue Background Tint

  // ── BACKGROUND & SURFACE COLORS ─────────────────────────────────────────
  static const Color background = Color(0xFFFFFFFF); // Clean Pure White
  static const Color backgroundSubtle = Color(0xFFF8FAFC); // Slate 50 Off-White
  static const Color cardBackground = Color(0xFFFFFFFF); // Surface Card White
  static const Color surfaceSecondary = Color(0xFFF1F5F9); // Slate 100 Neutral Surface
  static const Color surfaceTertiary = Color(0xFFE2E8F0); // Slate 200 Subtler Surface

  // ── TYPOGRAPHY & TEXT COLORS ─────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900 - Primary Body & Title
  static const Color textSecondary = Color(0xFF64748B); // Slate 500 - Secondary Subtitles & Labels
  static const Color textTertiary = Color(0xFF94A3B8); // Slate 400 - Muted Captions & Placeholders
  static const Color textQuaternary = Color(0xFFCBD5E1); // Slate 300 - Disabled / Subtle Text
  static const Color textDarkHeading = Color(0xFF2D3142); // Deep Charcoal Slate Heading

  // ── STATUS & SEMANTIC COLORS ────────────────────────────────────────────
  static const Color success = Color(0xFF10B981); // Emerald Green Success
  static const Color successLight = Color(0xFFE8F5E9); // Light Emerald Tint
  static const Color successDark = Color(0xFF2E7D32); // Forest Green Dark Text
  static const Color warning = Color(0xFFF59E0B); // Amber Warning
  static const Color warningLight = Color(0xFFFEF3C7); // Soft Amber Tint
  static const Color warningDark = Color(0xFFEA580C); // Deep Amber / Orange Dark Text
  static const Color error = Color(0xFFEF4444); // Coral Red Error
  static const Color errorLight = Color(0xFFFEE2E2); // Soft Red Tint
  static const Color errorDark = Color(0xFFB91C1C); // Dark Crimson Red Text
  static const Color info = Color(0xFF3B82F6); // Info Sky Blue
  static const Color infoLight = Color(0xFFE0F2FE); // Soft Sky Blue Tint
  static const Color infoDark = Color(0xFF0284C7); // Dark Sky Blue Text

  // ── NEUTRAL BORDERS & DIVIDERS ──────────────────────────────────────────
  static const Color border = Color(0xFFE2E8F0); // Standard Slate Border
  static const Color borderSubtle = Color(0xFFF1F5F9); // Subtle Slate Border
  static const Color divider = Color(0xFFF1F5F9); // Divider Line Color

  // ── MODULE ACCENT COLORS ────────────────────────────────────────────────
  static const Color timetableAccent = Color(0xFF5C6BC0); // Indigo Class Timetable
  static const Color assignmentAccent = Color(0xFF26A69A); // Teal Assignments
  static const Color gradesAccent = Color(0xFFEF5350); // Coral Gradebook
  static const Color feesAccent = Color(0xFFFFA726); // Amber Fees & Financials
  static const Color eventsAccent = Color(0xFF8E24AA); // Purple Campus Events
  static const Color hackathonAccent = Color(0xFF00ACC1); // Cyan Hackathons & Tech
  static const Color libraryAccent = Color(0xFF43A047); // Green Digital Library

  // ── ROLE-BASED ACCENT COLORS ─────────────────────────────────────────────
  static const Color studentRole = Color(0xFF2563EB); // Student Portal (Blue)
  static const Color staffRole = Color(0xFF7C3AED); // Staff / Faculty Portal (Purple)
  static const Color hodRole = Color(0xFF2563EB); // HOD / Dept Portal (Royal Indigo Blue - Unified with App Primary)
  static const Color parentRole = Color(0xFF059669); // Parent Portal (Teal)
  static const Color adminRole = Color(0xFFDC2626); // Admin Portal (Red)

  // ── GLASSMORPHISM & GRADIENTS ───────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassCardGradient = LinearGradient(
    colors: [
      Color(0xE6FFFFFF), // White 90%
      Color(0xA6FFFFFF), // White 65%
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
