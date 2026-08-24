# Scorely Application Design System

This document contains the centralized design system for the Scorely application, covering both the Light Mode (Global UI) and Dark Mode (Live Scoring UI) themes.

---

## 1. Light Mode Theme (Global UI)

---
name: Premium Cricket Scorer
colors:
  surface: '#f7f9fc'
  surface-dim: '#d8dadd'
  surface-bright: '#f7f9fc'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f4f7'
  surface-container: '#eceef1'
  surface-container-high: '#e6e8eb'
  surface-container-highest: '#e0e3e6'
  on-surface: '#191c1e'
  on-surface-variant: '#5d3f3c'
  inverse-surface: '#2d3133'
  inverse-on-surface: '#eff1f4'
  outline: '#926f6b'
  outline-variant: '#e7bdb8'
  surface-tint: '#c00014'
  primary: '#ba0013'
  on-primary: '#ffffff'
  primary-container: '#e31e24'
  on-primary-container: '#fffafa'
  inverse-primary: '#ffb4ab'
  secondary: '#575d78'
  on-secondary: '#ffffff'
  secondary-container: '#d8defe'
  on-secondary-container: '#5b627c'
  tertiary: '#006b1b'
  on-tertiary: '#ffffff'
  tertiary-container: '#1d862d'
  on-tertiary-container: '#f5ffef'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdad6'
  primary-fixed-dim: '#ffb4ab'
  on-primary-fixed: '#410002'
  on-primary-fixed-variant: '#93000d'
  secondary-fixed: '#dbe1ff'
  secondary-fixed-dim: '#bfc5e4'
  on-secondary-fixed: '#131b31'
  on-secondary-fixed-variant: '#3f465f'
  tertiary-fixed: '#94f990'
  tertiary-fixed-dim: '#78dc77'
  on-tertiary-fixed: '#002204'
  on-tertiary-fixed-variant: '#005313'
  background: '#f7f9fc'
  on-background: '#191c1e'
  surface-variant: '#e0e3e6'
typography:
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-bold:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.05em
  score-display:
    fontFamily: Plus Jakarta Sans
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.04em
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  container-padding: 20px
  card-gutter: 12px
---

## Brand & Style
The design system is built for a premium, high-performance cricket scoring experience. It targets serious players, league organizers, and enthusiasts who require precision and speed. The visual style is **Corporate / Modern** with a high-energy "Sporty" edge. It utilizes crisp white surfaces against a sophisticated deep navy foundation to create a professional broadcast-quality feel. 

The aesthetic is characterized by intentional whitespace, high-contrast action areas, and a tactile "card-on-canvas" approach that provides clarity during fast-paced match play. It evokes confidence, urgency, and athletic precision.

## Colors
The palette is rooted in the heritage of the sport. **Sporty Red** is the high-energy primary color used for critical actions, highlights, and primary buttons. **Deep Navy** serves as the authoritative grounding color, used for headers and primary text to ensure a premium feel. 

**Active Green** is reserved strictly for positive status indicators, such as "In-Play," successful tosses, or live match connections. The background uses a soft neutral grey (#F5F7FA) to allow the pure white cards and vibrant red accents to pop, reducing eye strain during long sessions under direct sunlight.

## Typography
This design system uses **Plus Jakarta Sans** for headlines to provide a modern, energetic, and slightly rounded geometric feel that remains highly legible. **Inter** is used for all functional body and label text to ensure maximum readability in data-dense scoring environments.

A special `score-display` role is included for primary match statistics (like total runs or overs remaining), emphasizing the "big data" aspect of the sport. All uppercase labels should utilize increased letter-spacing to maintain clarity at small sizes.

## Layout & Spacing
The layout follows a **Fixed Grid** philosophy for mobile devices, centered with a maximum content width of 480px. It utilizes a 4px baseline grid to maintain a tight, rhythmic flow. 

For the scoring interface, cards are grouped with 12px gutters. Large, thumb-friendly tap targets are prioritized, with primary action buttons spanning the full width of the container at the bottom of the viewport. Margins are set to a generous 20px to prevent content from feeling cramped against device edges.

## Elevation & Depth
Depth is achieved through **Tonal Layers** and subtle shadows. The base canvas is the neutral background. Surfaces (cards) are pure white with a very soft, diffused shadow (`0px 4px 20px rgba(26, 33, 56, 0.08)`).

To emphasize priority, the primary scoring buttons and floating action buttons (FABs) utilize a more aggressive shadow with a slight red tint to suggest they sit higher on the Z-axis. Subtle 1px borders in a very light grey (#E2E8F0) are used on secondary cards to provide definition without adding visual noise.

## Shapes
The design system employs a **Rounded** shape language. Standard UI elements like cards and input fields use a 0.5rem (8px) radius. Larger components like the "Start Match" button or primary scoreboard containers use a 1rem (16px) radius to feel more inviting and tactile. This balance of roundedness provides a modern, premium aesthetic that softens the "data-heavy" nature of a scoring app.

## Components

### Buttons
- **Primary:** Sporty Red background, white text, 16px corner radius. Includes a subtle "inner glow" or shadow for tactility.
- **Secondary:** White background, Navy border (1px), Navy text.
- **Quick-Select (Overs/Runs):** Small white pills with Navy text, turning Red when selected.

### Cards
- **Team Cards:** Feature a thick 4px vertical accent bar on the left (Red for Team A, Blue/Navy for Team B) to provide instant visual distinction.
- **Scoring Card:** Centralized, high-contrast card with large numerical displays for "Overs" or "Runs."

### Input Fields
- **Steppers:** Large +/- icons with soft-grey backgrounds to encourage rapid adjustment.
- **Selectors:** Clean, minimal dropdowns with chevron-down icons and clear placeholder text.

### Badges & Icons
- **Status Badges:** Use Active Green for "Live" or "In-Progress."
- **Icons:** High-contrast, 2px stroke-width line icons in Deep Navy. Icons should be paired with text labels in complex scoring menus to ensure no ambiguity.

### Lists
- **Player Lists:** Clean, white rows with subtle dividers. Each row should have a clear "avatar" or "initial circle" for quick identification.

---

## 2. Dark Mode Theme (Live Scoring UI)

---
name: Elite Pitch
colors:
  surface: '#111317'
  surface-dim: '#111317'
  surface-bright: '#37393e'
  surface-container-lowest: '#0c0e12'
  surface-container-low: '#1a1c20'
  surface-container: '#1e2024'
  surface-container-high: '#282a2e'
  surface-container-highest: '#333539'
  on-surface: '#e2e2e8'
  on-surface-variant: '#e7bdb9'
  inverse-surface: '#e2e2e8'
  inverse-on-surface: '#2f3035'
  outline: '#ad8884'
  outline-variant: '#5d3f3d'
  surface-tint: '#ffb3ad'
  primary: '#ffb3ad'
  on-primary: '#680009'
  primary-container: '#ff544f'
  on-primary-container: '#5c0007'
  inverse-primary: '#c0001b'
  secondary: '#bcc7de'
  on-secondary: '#263143'
  secondary-container: '#3e495d'
  on-secondary-container: '#aeb9d0'
  tertiary: '#3ce36a'
  on-tertiary: '#003912'
  tertiary-container: '#00a744'
  on-tertiary-container: '#00320f'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffdad6'
  primary-fixed-dim: '#ffb3ad'
  on-primary-fixed: '#410003'
  on-primary-fixed-variant: '#930012'
  secondary-fixed: '#d8e3fb'
  secondary-fixed-dim: '#bcc7de'
  on-secondary-fixed: '#111c2d'
  on-secondary-fixed-variant: '#3c475a'
  tertiary-fixed: '#69ff87'
  tertiary-fixed-dim: '#3ce36a'
  on-tertiary-fixed: '#002108'
  on-tertiary-fixed-variant: '#00531e'
  background: '#111317'
  on-background: '#e2e2e8'
  surface-variant: '#333539'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 48px
    fontWeight: '800'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 8px
  sm: 16px
  md: 24px
  lg: 40px
  xl: 64px
  gutter: 16px
  margin-mobile: 16px
  margin-desktop: 32px
---

## Brand & Style
The design system is engineered for a high-performance sports scoring environment, prioritizing split-second readability and premium athletic aesthetics. The brand personality is authoritative, precise, and energetic, capturing the intensity of professional cricket. 

The visual style follows a **Modern / High-Contrast** approach optimized for low-light environments (stadium boxes, evening matches). It utilizes deep, light-absorbing surfaces to minimize glare, allowing critical match data and the signature "Cricket Red" accents to command the user's focus. The interface feels like a sophisticated digital cockpit—instrumental, reliable, and elite.

## Colors
This design system utilizes a "Midnight Stadium" palette. The primary background is a deep navy-tinted charcoal (#0F1115) to ensure maximum depth. 

- **Primary Accent:** Cricket Red (#F22C33). This is a slightly more luminous version of the traditional red, tuned to vibrate against dark backgrounds without causing eye strain. It is used exclusively for primary actions, live status indicators (e.g., "LIVE"), and critical highlights.
- **Secondary/Surface:** Deep slate tones are used for container backgrounds to create subtle layering.
- **Success/Tertiary:** A vibrant green is used specifically for "Boundary" events and "Not Out" statuses.
- **Typography:** Headlines use pure white (#FFFFFF) for absolute clarity, while body text uses a refined light gray (#A1A1AA) to reduce visual noise in data-heavy views.

## Typography
The design system relies on **Plus Jakarta Sans** for its modern, geometric clarity and excellent legibility in tabular data. 

- **Display & Headlines:** Use bolder weights (700-800) with slight negative letter-spacing to create a tight, professional look for scores and player names.
- **Numerical Data:** For scoreboards, use the Display-lg style. The tabular lining of Plus Jakarta Sans ensures that numbers align perfectly in columns.
- **Labels:** Small labels use uppercase with increased letter-spacing to distinguish metadata (e.g., "OVERS", "RUN RATE") from primary content.
- **Mobile Scaling:** Headlines downscale by approximately 15% on mobile to maintain information density without breaking layout grids.

## Layout & Spacing
The layout follows a strict 8px spacing rhythm to ensure mathematical balance across dense data visualizations. 

- **Grid System:** A 12-column fluid grid is used for desktop layouts, collapsing to a 4-column grid on mobile. 
- **Information Density:** Given the nature of cricket scoring, the design system favors "High Density" in the central scoring area and "Comfortable" spacing for navigation and settings.
- **Gutters:** Standard 16px gutters keep distinct statistical blocks (e.g., Bowler stats vs. Batsman stats) separate and readable.
- **Safe Areas:** On mobile, a 16px margin is maintained on the edges of the viewport to prevent accidental touches and visual crowding.

## Elevation & Depth
In this dark-mode system, depth is communicated through **Tonal Layering** rather than traditional shadows. 

- **Level 0 (Background):** #0F1115 - The base canvas.
- **Level 1 (Cards/Containers):** #1E1E1E - Used for the main content modules.
- **Level 2 (Modals/Popovers):** #2D2D2D - The lightest surface, used for elements that sit closest to the user.
- **Borders:** Instead of heavy shadows, use low-contrast 1px strokes (#333333) to define the edges of containers. 
- **Active State Glow:** Primary buttons may use a very soft, subtle outer glow of the Primary Red (opacity 15%) to indicate focus or active live-tracking.

## Shapes
The shape language balances professional structure with modern approachability. 

- **Containers:** Use a standard 0.5rem (8px) corner radius. This provides a "Rounded" aesthetic that feels modern without being overly soft or "bubbly."
- **Interactive Elements:** Buttons and input fields follow the same 8px rounding. 
- **Data Chips:** Use the `rounded-xl` (1.5rem) setting to create pill-shaped indicators for "Wickets" or "Status" tags, distinguishing them from square-shaped structural cards.

## Components
- **Buttons:** Primary buttons are solid Cricket Red (#F22C33) with pure white text. Secondary buttons are outlined with a white stroke at 20% opacity.
- **Score Cards:** Use a Level 1 surface background with a high-contrast white score display. Trends (Run rate up/down) should use the Tertiary Green or Primary Red.
- **Input Fields:** Darker than the container surface with a subtle 1px border. On focus, the border transitions to Cricket Red.
- **Chips:** Small, pill-shaped tags used for "Over" summaries (e.g., 4, 6, W). Wicket chips use the Primary Red background; boundary chips use the Tertiary Green.
- **Lists:** Player lists use subtle dividers (#333333) with high-contrast text for names and secondary text for strike rates/averages.
- **Interactive Graphs:** Line charts should use a Primary Red stroke with a subtle gradient fill below the line, transitioning from 20% red to transparent.