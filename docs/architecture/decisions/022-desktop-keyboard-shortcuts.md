# ADR-022 — Desktop keyboard shortcuts

**Status:** Accepted  
**Date:** 2026-09-24

## Context

Phase 6 first shipped the archived-spec set: Space = pause/resume anywhere, Ctrl+Enter = start the last skill whose Play was pressed, Ctrl+Shift+Enter = stop. Manual acceptance on Windows found:

- Ctrl+Enter depended on hidden state (it did nothing until Play had been clicked once) and is conventionally "submit / send" in forms.
- A global Space handler competes with Space activating the focused control (GNOME HIG: Space toggles the focused control; Return activates it). WCAG 2.1.4 expects single-key shortcuts to be active only when the relevant component has focus, or to be remappable or switchable off.
- Ctrl+N ("New") is the standard creation shortcut on Windows, GNOME and KDE, and was missing.

## Decision

- **Timer screen:** Space toggles pause/resume while the timer screen itself holds keyboard focus (the default when it opens). Once the user tabs to a control, Space activates that control as usual. Space does nothing on any other route.
- **Skills:** Ctrl+N opens the New skill editor, only while Skills is the top route (no sheet, dialog, or timer above it).
- **Tabs:** Escape on Learning Log, Statistics, or Settings returns to Skills (unchanged, [ADR-019](019-four-destination-nav.md)).
- **Removed:** Ctrl+Enter (start) and Ctrl+Shift+Enter (stop). Start is Play → Start; Stop is the on-screen Stop button, the tray, or the notification.
- No system-wide hotkeys. Shortcuts are listed in Settings → Keyboard shortcuts and shown in desktop tooltips.

## Consequences

Space no longer needs text-field suppression because it only exists on a screen without text fields. New shortcuts (for example Ctrl+F for Learning Log search, Ctrl+, for Settings, Ctrl+1–4 for tabs) are proposed through issues and follow the same focus rules.
