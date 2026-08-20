# Implementation Plan - Glassmorphic UI

This plan describes how to introduce a glassmorphic look to the Debt Book app while maintaining the existing color theme and functions.

## User Review Required

> [!NOTE]
> Glassmorphism requires a background with some visual complexity (like gradients or shapes) to be effective. I will add subtle background blobs to the `HomeScreen` to make the glass effect visible.

## Proposed Changes

### [Component Name] UI Components & Theme

#### [NEW] [glass_container.dart](file:///C:/Users/lenovo/develop/debt_book/lib/widgets/glass_container.dart)
A reusable widget that applies `BackdropFilter` with blur and a semi-transparent background to its children.

#### [MODIFY] [main.dart](file:///C:/Users/lenovo/develop/debt_book/lib/main.dart)
- Update `ThemeData` to use more transparent card colors where appropriate.
- Adjust `AppBar` and `Scaffold` background defaults if needed.

#### [MODIFY] [home_screen.dart](file:///C:/Users/lenovo/develop/debt_book/lib/screens/home_screen.dart)
- Wrap the body in a `Stack` to add decorative background blobs.
- Update the layout to accommodate glassmorphic elements.

#### [MODIFY] [overview_card.dart](file:///C:/Users/lenovo/develop/debt_book/lib/widgets/overview_card.dart)
- Replace the standard `Container` with `GlassContainer`.
- Adjust borders and shadows to fit the glassmorphic style.

#### [MODIFY] [debt_person_card.dart](file:///C:/Users/lenovo/develop/debt_book/lib/widgets/debt_person_card.dart)
- Replace the `Card` with `GlassContainer`.
- Refine internal padding and borders.

## Verification Plan

### Manual Verification
- Run the app and check the `HomeScreen`.
- Verify the blur effect is visible behind the cards.
- Ensure all functions (Add, Update, Pay, Delete) still work correctly.
- Test in both Light and Dark modes.
