# TRUSTY MOBILE RELEASE NOTES
## Can Göymen
## Version 1.0.10 - 2024-11-09
## Build 16

### 🆕 New Features
- **Followed Push Notification**: Push notifications have been added for following users.
- **Username Changes**: Users can change their usernames, but only once.
- **Image Popup**: Uploaded images can now be viewed in a popup with a blurred background for enhanced user experience.
- **Password Reset**: A password reset function has been introduced, allowing users to reset their passwords in the "Password Reset" section under Settings.
- **Email Verification**: Users can now verify their email addresses for additional account security.

### 🛠️ Improvements
- **New Logo**: Updated with a fresh, shiny logo.
- **New Default Profile Picture**: The default profile picture has been updated. New images are generated using the user's name for personalization.
- **New Banner Image**: The default banner image has been replaced with a background showcasing Curiosity.tech.
- **Signup Page**: The signup page has been redesigned for a modern, user-friendly experience.
- **Signin Page**: The signin page has been revamped to match the new design aesthetics.
- **Welcome Page**: The welcome page has been updated to create a better first impression for new users.

### 🐛 Bug Fixes
- **General UI and UX Fixes**: Minor visual and interaction bugs have been fixed to ensure a smoother user experience.
- **Username Validation**: Fixed logic to correctly validate username changes, ensuring existing usernames are checked properly and informative feedback is provided.

### ⚙️ Technical Notes
- Removed push notification triggers from the client side during tweet composition; now handled through backend functions for better scalability and maintainability.
- Refined the username validation logic to check for unique usernames while allowing users to keep their current username without triggering an error.
