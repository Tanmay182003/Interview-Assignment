# Backend Setup

This project uses Supabase for the backend.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Supabase CLI](https://supabase.com/docs/guides/cli)

> **Note**: A live Supabase instance is already hosted and the iOS app is configured to use it. You only need to run the backend locally if you want to inspect/modify the Edge Functions or database schema yourself.

## Running Locally

To start the local Supabase stack:

```bash
supabase start
```
This will spin up the local database, auth service, and other Supabase components.

To reset the database (apply migrations):

```bash
supabase db reset
```

To serve the Edge Functions locally:

```bash
supabase functions serve --no-verify-jwt
```
Note: We use the `--no-verify-jwt` flag here mainly to bypass the CLI's automatic verification so we can handle it manually and securely within our functions (see `backend/supabase/functions/chat_stream/index.ts`).

## Auth Handling

Authentication is handled by Supabase Auth.
- When running locally, you can view the Inbucket email interface at `http://localhost:54324` to get OTP codes for signup.
- The default local API URL is `http://localhost:54321`.
- The default local Anon Key will be printed to the console when you run `supabase start`.

## Environment Variables

The Edge Functions use `Deno.env.get()` to access environment variables.
- `SUPABASE_URL`: Automatically provided by `supabase functions serve`.
- `SUPABASE_SERVICE_ROLE_KEY`: Automatically provided.
- `SUPABASE_ANON_KEY`: Automatically provided.
