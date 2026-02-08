# iOS App Setup

## Configuration

The app is **pre-configured** to connect to a live hosted Supabase instance. You can run it immediately without changing any config.

If you prefer to run against a **local** backend:

1. Open `NeverGoneDemo/Config.swift`.
2. Update `supabaseURL` and `supabaseAnonKey` with your local credential if running locally.
   - Run `supabase status` in the `backend` directory to get these values.
   - URL: usually `http://localhost:54321`
   - Anon Key: provided in output.

## Running in Simulator

1. Open `NeverGoneDemo.xcodeproj` in Xcode 15+.
2. Select a simulator (e.g., iPhone 15 Pro).
3. Press `Cmd + R` to run.

## Usage

1. **Sign Up**:
   - Use any email (e.g., `test@example.com`) and password.
   - If running locally, check `http://localhost:54324` for the confirmation email/OTP.
2. **Chat**:
   - Tap the "+" button to start a new chat session.
   - Type a message and tap send.
   - The assistant response will stream back.
3. **Trigger Streaming**:
   - Just send a message! The backend `chat_stream` function will automatically stream the response.
