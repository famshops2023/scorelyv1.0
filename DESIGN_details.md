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