
# RehabTech App Blueprint

## Overview

This document outlines the plan, features, and design of the RehabTech application, a Flutter app with Firebase integration. The app provides authentication (login and registration) for patients and therapists.

## Current Plan

The current goal is to build the authentication flow, including a login screen and a registration screen, with a modern "frosted glass" UI, as specified by the user's Figma designs.

### Steps:

1.  **Project Setup:**
    *   Add `firebase_core`, `firebase_auth`, `cloud_firestore`, and `google_fonts` to `pubspec.yaml`.
    *   Initialize Firebase in the `main.dart` file.

2.  **Create Authentication Screens:**
    *   Implement `lib/screens/login_screen.dart` with email/password login.
    *   Implement `lib/screens/register_screen.dart` with email/password registration and user data storage in Firestore.
    *   Implement a "forgot password" screen.

3.  **UI Implementation:**
    *   Create an animated gradient background widget.
    *   Create a reusable "frosted glass" card widget.
    *   Implement the UI for all screens based on the provided screenshots, ensuring responsiveness.
    *   Use the 'SF Pro' or 'Roboto' font.

4.  **Firebase Integration:**
    *   Connect the login and registration forms to Firebase Authentication.
    *   On registration, store user roles and names in Firestore.
    *   Implement error handling and user feedback using SnackBars.

## Implemented Features

### Style & Design

*   **Animated Gradient Background:** A soothing, animated gradient of blues, greens, and white serves as the main background for the app.
*   **Frosted Glass UI:** Key UI elements like forms and app bars use a "frosted glass" effect, achieved with `BackdropFilter` for a modern, layered look.
*   **Typography:** The app will use the 'SF Pro' or 'Roboto' font, with a base body text size of 16pt for readability.
*   **Color Palette:**
    *   **Primary Action:** A gradient from `#1E88E5` to `#26C6DA`.
    *   **Text:** Primarily black and shades of gray for a clean, accessible look. Links and interactive text use `#007AFF`.
    *   **Background:** Animated gradient of `#e0f7fa`, `#b2ebf2`, `#ffffff`, and `#c8e6c9`.

### Authentication

*   **Login Screen (`login_screen.dart`):**
    *   User role selection (Patient/Therapist).
    *   Email and password fields.
    *   "Sign In" button with Firebase email/password authentication.
    *   Links for password recovery and registration.
    *   Social login options (Apple & Google).
*   **Registration Screen (`register_screen.dart`):**
    *   User role selection.
    *   Fields for full name, email, and password.
    *   Password confirmation.
    *   Terms and conditions checkbox.
    *   "Create Account" button that:
        1.  Creates a user with Firebase Authentication.
        2.  Saves the user's name and role to a 'users' collection in Firestore.

