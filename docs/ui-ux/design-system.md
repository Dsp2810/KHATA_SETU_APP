# KhataSetu - UI/UX Design System

## 🎨 Design Philosophy

KhataSetu's design is built around the principle of **"Simple for Bharat"** - creating a premium fintech experience that village shopkeepers can use without technical expertise.

### Core Principles

1. **Simplicity First**: Minimal cognitive load, clear actions
2. **Trust & Security**: Professional appearance that builds confidence
3. **Accessibility**: Works for users with limited digital literacy
4. **Speed**: Quick actions for busy shopkeepers
5. **Offline-Ready**: Visual indication of sync status

---

## 🎨 Color Palette

### Primary Colors

```scss
// Primary Brand Colors
$primary-500: #2563EB;      // Main brand color - Blue
$primary-600: #1D4ED8;      // Pressed state
$primary-400: #60A5FA;      // Hover state
$primary-100: #DBEAFE;      // Light background
$primary-50:  #EFF6FF;      // Subtle background

// Secondary Colors
$secondary-500: #10B981;    // Success - Green
$secondary-600: #059669;    // Success dark

// Accent Colors
$accent-500: #F59E0B;       // Warning - Amber
$accent-600: #D97706;       // Warning dark
```

### Semantic Colors

```scss
// Status Colors
$success: #10B981;          // Green - Payments, cleared
$warning: #F59E0B;          // Amber - Due soon, low stock
$danger:  #EF4444;          // Red - Overdue, critical
$info:    #3B82F6;          // Blue - Information

// Text Colors
$text-primary:   #1F2937;   // Main text (Gray-800)
$text-secondary: #6B7280;   // Secondary text (Gray-500)
$text-tertiary:  #9CA3AF;   // Placeholder text (Gray-400)
$text-inverse:   #FFFFFF;   // Text on dark backgrounds

// Background Colors
$bg-primary:   #FFFFFF;     // Main background
$bg-secondary: #F9FAFB;     // Secondary background (Gray-50)
$bg-tertiary:  #F3F4F6;     // Card backgrounds (Gray-100)
$bg-dark:      #111827;     // Dark mode background
```

### Risk Indicator Colors

```scss
// Customer Risk Levels
$risk-low:    #10B981;      // Green (0-30 score)
$risk-medium: #F59E0B;      // Amber (31-60 score)
$risk-high:   #EF4444;      // Red (61-100 score)
```

---

## 📝 Typography

### Font Family

```scss
// Primary Font - Clean & Modern
$font-primary: 'Poppins', 'Inter', sans-serif;

// For Gujarati text
$font-gujarati: 'Noto Sans Gujarati', 'Poppins', sans-serif;

// Monospace (for numbers, codes)
$font-mono: 'JetBrains Mono', 'Roboto Mono', monospace;
```

### Type Scale

```scss
// Headings
$h1: 32px / 1.2 / 700;      // Page titles
$h2: 24px / 1.3 / 600;      // Section headers
$h3: 20px / 1.4 / 600;      // Card titles
$h4: 18px / 1.4 / 500;      // Subsection headers
$h5: 16px / 1.5 / 500;      // Small headers

// Body Text
$body-large:  16px / 1.5 / 400;   // Primary content
$body-normal: 14px / 1.5 / 400;   // Standard text
$body-small:  12px / 1.5 / 400;   // Captions, labels

// Special
$amount-large:  32px / 1.2 / 700; // Dashboard amounts
$amount-medium: 24px / 1.2 / 600; // Card amounts
```

---

## 📐 Spacing System

```scss
// Base unit: 4px
$space-1:  4px;
$space-2:  8px;
$space-3:  12px;
$space-4:  16px;
$space-5:  20px;
$space-6:  24px;
$space-8:  32px;
$space-10: 40px;
$space-12: 48px;
$space-16: 64px;

// Common Patterns
$card-padding: 16px;
$section-gap: 24px;
$list-item-gap: 12px;
$screen-padding: 16px;
```

---

## 🔲 Components

### Buttons

```
┌─────────────────────────────────────────────────────────────────┐
│                       BUTTON VARIANTS                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  PRIMARY BUTTON                                                  │
│  ┌─────────────────────────────┐                                │
│  │       Save Customer         │  Blue filled, white text      │
│  │       Height: 48px          │  Border radius: 12px          │
│  └─────────────────────────────┘                                │
│                                                                  │
│  SECONDARY BUTTON                                                │
│  ┌─────────────────────────────┐                                │
│  │         Cancel              │  White fill, blue border      │
│  │                             │  Blue text                    │
│  └─────────────────────────────┘                                │
│                                                                  │
│  DANGER BUTTON                                                   │
│  ┌─────────────────────────────┐                                │
│  │         Delete              │  Red filled, white text       │
│  └─────────────────────────────┘                                │
│                                                                  │
│  TEXT BUTTON                                                     │
│  [ View More → ]                   No background, blue text     │
│                                                                  │
│  ICON BUTTON                                                     │
│    ⚙️  🔔  ➕                      48x48px touch target         │
│                                                                  │
│  FAB (Floating Action Button)                                    │
│      ┌───┐                                                       │
│      │ + │   56x56px, Primary blue                              │
│      └───┘   Shadow elevation                                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Cards

```
┌─────────────────────────────────────────────────────────────────┐
│                        CARD STYLES                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  STANDARD CARD                                                   │
│  ┌───────────────────────────────────────┐                      │
│  │  Title                                │  Background: White   │
│  │  Content goes here                    │  Border radius: 16px │
│  │  ...                                  │  Shadow: subtle      │
│  └───────────────────────────────────────┘  Padding: 16px       │
│                                                                  │
│  STAT CARD (Dashboard)                                           │
│  ┌───────────────────────────────────────┐                      │
│  │            ₹45,000                    │  Centered content    │
│  │          Total Pending                │  Large amount        │
│  └───────────────────────────────────────┘  Small label below   │
│                                                                  │
│  LIST ITEM CARD                                                  │
│  ┌───────────────────────────────────────┐                      │
│  │ 🔴 Suresh Sharma               ₹12,000│  Left: avatar/icon  │
│  │    📱 98765 43210           45 days ▶ │  Right: amount/arrow │
│  └───────────────────────────────────────┘                      │
│                                                                  │
│  ELEVATED CARD                                                   │
│  ┌───────────────────────────────────────┐                      │
│  │                                       │  Larger shadow       │
│  │  Important content                    │  Slight scale        │
│  │                                       │  on interaction      │
│  └───────────────────────────────────────┘                      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Input Fields

```
┌─────────────────────────────────────────────────────────────────┐
│                      INPUT FIELD STATES                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  DEFAULT STATE                                                   │
│  ┌─────────────────────────────────────────┐                    │
│  │  📱 Phone Number                       │  Label above        │
│  │  ────────────────────────────────────  │  Placeholder gray   │
│  │  Enter phone number                    │  Border: Gray-300   │
│  └─────────────────────────────────────────┘                    │
│                                                                  │
│  FOCUSED STATE                                                   │
│  ┌─────────────────────────────────────────┐                    │
│  │  📱 Phone Number                       │  Label: Primary     │
│  │  ════════════════════════════════════  │  Border: Primary    │
│  │  98765 43210                           │  Border width: 2px  │
│  └─────────────────────────────────────────┘                    │
│                                                                  │
│  ERROR STATE                                                     │
│  ┌─────────────────────────────────────────┐                    │
│  │  📱 Phone Number                       │  Label: Red         │
│  │  ════════════════════════════════════  │  Border: Red        │
│  │  987654                                │                     │
│  └─────────────────────────────────────────┘                    │
│  ⚠️ Please enter valid 10-digit number    │  Error text below   │
│                                                                  │
│  DISABLED STATE                                                  │
│  ┌─────────────────────────────────────────┐                    │
│  │  📱 Phone Number                       │  Background: Gray   │
│  │  ────────────────────────────────────  │  Text: Gray-400     │
│  │  98765 43210                           │  Not editable       │
│  └─────────────────────────────────────────┘                    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Chips & Tags

```
┌─────────────────────────────────────────────────────────────────┐
│                       CHIPS & TAGS                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  FILTER CHIPS                                                    │
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐                               │
│  │ All │ │ Due │ │Clear│ │Risky│   Pill shape                 │
│  └─────┘ └─────┘ └─────┘ └─────┘   Toggle selection           │
│     ●       ○       ○       ○                                   │
│                                                                  │
│  STATUS BADGE                                                    │
│  ┌──────────┐        Green: Paid/Cleared                        │
│  │ ● Paid   │        Yellow: Pending                            │
│  └──────────┘        Red: Overdue                               │
│                                                                  │
│  CATEGORY TAG                                                    │
│  ┌───────────┐                                                  │
│  │ 🍚 Grocery │   Icon + label                                  │
│  └───────────┘                                                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🎭 Icons

### Icon Set
Using **Lucide Icons** or **Phosphor Icons** for consistent style

### Common Icons

```
Navigation:
  🏠 Home          - house
  👥 Customers     - users
  ➕ Add           - plus
  📦 Inventory     - package
  📊 Reports       - chart-bar

Actions:
  ✏️ Edit          - pencil
  🗑️ Delete        - trash
  📤 Share         - share
  📥 Download      - download
  🔍 Search        - search

Status:
  ✅ Success       - check-circle
  ⚠️ Warning       - alert-triangle
  ❌ Error         - x-circle
  ℹ️ Info          - info

Ledger:
  📥 Credit In     - arrow-down-left (green)
  📤 Payment Out   - arrow-up-right (blue)
  💰 Cash          - banknotes
  📱 UPI           - smartphone
  🏦 Bank          - building-2

Others:
  🔔 Notifications - bell
  ⚙️ Settings      - settings
  🌙 Dark Mode     - moon
  🌐 Language      - globe
```

---

## ✨ Animations & Micro-interactions

### Page Transitions

```dart
// Slide + Fade transition
Duration: 300ms
Curve: Curves.easeInOutCubic

// Page enters from right
// Page exits to left with fade
```

### Button Interactions

```dart
// Scale on press
onTapDown: scale(0.96)
onTapUp: scale(1.0)
Duration: 100ms

// Ripple effect on tap
Material ripple with theme color
```

### Card Interactions

```dart
// Hover/Press elevation change
Default shadow: 4px
Pressed shadow: 8px
Duration: 150ms
```

### Success Animations

```dart
// Checkmark animation on success
Lottie animation or custom
Duration: 600ms
Colors: Green (#10B981)
```

### Skeleton Loading

```dart
// Shimmer effect for loading states
Base color: Gray-200
Highlight color: Gray-100
Shimmer direction: left to right
Duration: 1500ms
```

### Pull to Refresh

```dart
// Custom refresh indicator
Color: Primary brand blue
Indicator: Circular progress
Show shop name during refresh
```

---

## 📱 Responsive Breakpoints

```scss
// Mobile First Design
$mobile:  0px - 599px;     // Default
$tablet:  600px - 959px;   // Tablet (future web)
$desktop: 960px+;          // Desktop (future web)

// Flutter considerations
Small phones:  < 360dp width
Normal phones: 360dp - 400dp
Large phones:  > 400dp width
```

---

## 🌙 Dark Mode

```scss
// Dark Mode Color Mappings
$dm-bg-primary:   #0F172A;    // Slate-900
$dm-bg-secondary: #1E293B;    // Slate-800
$dm-bg-card:      #334155;    // Slate-700

$dm-text-primary:   #F8FAFC;  // Slate-50
$dm-text-secondary: #94A3B8;  // Slate-400

$dm-border: #475569;          // Slate-600

// Primary colors stay same
// Success/Warning/Danger slightly muted
```

---

## 🗣️ Localization UI

### Language Toggle

```
┌─────────────────────────────────────────────────────────────────┐
│                     LANGUAGE SELECTOR                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  In Settings:                                                    │
│  ┌──────────────────────────────────────────┐                   │
│  │  🌐 Language / ભાષા                   ▶ │                   │
│  └──────────────────────────────────────────┘                   │
│                                                                  │
│  Selection Screen:                                               │
│  ┌──────────────────────────────────────────┐                   │
│  │  ☑ English                              │                   │
│  ├──────────────────────────────────────────┤                   │
│  │  ☐ ગુજરાતી (Gujarati)                    │                   │
│  ├──────────────────────────────────────────┤                   │
│  │  ☐ हिंदी (Hindi) - Coming Soon          │                   │
│  └──────────────────────────────────────────┘                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### RTL Support
Not required for Gujarati/Hindi (both are LTR)

---

## 🚫 Empty & Error States

### Empty State Design

```
┌─────────────────────────────────────────────────────────────────┐
│                       EMPTY STATES                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  NO CUSTOMERS YET                                                │
│  ┌─────────────────────────────────────────┐                    │
│  │                                         │                    │
│  │          [Illustration]                 │                    │
│  │                                         │                    │
│  │      No customers added yet             │                    │
│  │   Add your first customer to get        │                    │
│  │   started with digital khata            │                    │
│  │                                         │                    │
│  │        [+ Add Customer]                 │                    │
│  │                                         │                    │
│  └─────────────────────────────────────────┘                    │
│                                                                  │
│  NO TRANSACTIONS                                                 │
│  ┌─────────────────────────────────────────┐                    │
│  │                                         │                    │
│  │          [Ledger illustration]          │                    │
│  │                                         │                    │
│  │      No transactions yet                │                    │
│  │   Start recording credit and            │                    │
│  │   payment entries                       │                    │
│  │                                         │                    │
│  └─────────────────────────────────────────┘                    │
│                                                                  │
│  SEARCH NO RESULTS                                               │
│  ┌─────────────────────────────────────────┐                    │
│  │                                         │                    │
│  │          [Search illustration]          │                    │
│  │                                         │                    │
│  │      No results for "xyz"               │                    │
│  │   Try a different search term           │                    │
│  │                                         │                    │
│  └─────────────────────────────────────────┘                    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Error State Design

```
┌─────────────────────────────────────────────────────────────────┐
│                       ERROR STATES                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  NETWORK ERROR                                                   │
│  ┌─────────────────────────────────────────┐                    │
│  │                                         │                    │
│  │          [No wifi illustration]         │                    │
│  │                                         │                    │
│  │      No internet connection             │                    │
│  │   Check your connection and try again   │                    │
│  │                                         │                    │
│  │            [Retry]                      │                    │
│  │                                         │                    │
│  └─────────────────────────────────────────┘                    │
│                                                                  │
│  SERVER ERROR                                                    │
│  ┌─────────────────────────────────────────┐                    │
│  │                                         │                    │
│  │          [Server error illustration]    │                    │
│  │                                         │                    │
│  │      Something went wrong               │                    │
│  │   We're working on fixing it.           │                    │
│  │   Please try again later.               │                    │
│  │                                         │                    │
│  │            [Retry]                      │                    │
│  │                                         │                    │
│  └─────────────────────────────────────────┘                    │
│                                                                  │
│  INLINE ERROR (Toast/Snackbar)                                   │
│  ┌─────────────────────────────────────────┐                    │
│  │ ⚠️ Failed to save. Please try again    │                    │
│  └─────────────────────────────────────────┘                    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📊 Chart Styles (fl_chart)

### Line Chart (Revenue Trend)

```dart
// Colors
lineColor: primaryBlue
gradientBelow: primaryBlue.withOpacity(0.1)
dotColor: primaryBlue
gridColor: gray200

// Style
lineWidth: 2.5
dotRadius: 4
showDots: true (on touch)
curved: true (cubic bezier)
```

### Pie Chart (Pending vs Collected)

```dart
// Colors
collected: successGreen
pending: warningAmber

// Style
sectionRadius: 80
centerSpace: 40
showPercentage: true
animationDuration: 800ms
```

### Bar Chart (Category Sales)

```dart
// Colors
barColor: primaryBlue
selectedBar: primaryDark

// Style
barWidth: 16
borderRadius: 8
showValue: onTouch
```

---

## ♿ Accessibility Guidelines

### Touch Targets
- Minimum size: 48x48dp
- Adequate spacing between interactive elements

### Color Contrast
- Text on background: 4.5:1 minimum
- Large text (>18sp): 3:1 minimum
- Use icons + color (never color alone for status)

### Screen Reader Support
- Semantic widgets with proper labels
- Image descriptions for icons
- Announced state changes

### Text Scaling
- Support system text size preferences
- Test up to 200% text scale
- Flexible layouts that adapt

---

## 📐 Layout Grid

```
┌─────────────────────────────────────────────────────────────────┐
│                        LAYOUT GRID                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  SCREEN LAYOUT                                                   │
│  ┌─────────────────────────────────────────┐                    │
│  │← 16px                              16px→│  Screen padding    │
│  │  ┌───────────────────────────────┐     │                    │
│  │  │                               │     │                    │
│  │  │       CONTENT AREA            │     │                    │
│  │  │                               │     │                    │
│  │  └───────────────────────────────┘     │                    │
│  │                                        │                    │
│  └─────────────────────────────────────────┘                    │
│                                                                  │
│  CARD GRID (2 columns)                                           │
│  ┌──────────────┐  ┌──────────────┐                             │
│  │              │  │              │   Gap: 16px                 │
│  │   Card 1     │  │   Card 2     │                             │
│  │              │  │              │                             │
│  └──────────────┘  └──────────────┘                             │
│           12px gap between cards                                 │
│                                                                  │
│  LIST ITEMS                                                      │
│  ┌─────────────────────────────────────────┐                    │
│  │  Item 1                                 │                    │
│  └─────────────────────────────────────────┘                    │
│           8px gap                                               │
│  ┌─────────────────────────────────────────┐                    │
│  │  Item 2                                 │                    │
│  └─────────────────────────────────────────┘                    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🎯 Design Checklist

### Before Development
- [ ] Color palette defined
- [ ] Typography scale set
- [ ] Icons selected
- [ ] Component library created
- [ ] Spacing system established

### During Development
- [ ] Consistent padding/margins
- [ ] Proper touch targets (48dp min)
- [ ] Loading states implemented
- [ ] Error states designed
- [ ] Empty states created

### Before Release
- [ ] Dark mode tested
- [ ] Accessibility audit passed
- [ ] Text scaling tested
- [ ] Animation performance verified
- [ ] Offline mode UI tested
