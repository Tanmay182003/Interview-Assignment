/**
 * chat_stream Edge Function
 * 
 * Handles streaming chat responses using Server-Sent Events (SSE).
 * 
 * Flow:
 * 1. Receive session_id and message from client
 * 2. Verify session ownership via JWT
 * 3. Persist user message to database
 * 4. Stream assistant response (stubbed LLM)
 * 5. Persist complete assistant message
 * 6. Return [DONE] signal
 * 
 * Streaming Format (SSE):
 * - Each chunk: `data: {"content": "word "}\n\n`
 * - Final signal: `data: [DONE]\n\n`
 */

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

// CORS headers for local development
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface ChatRequest {
  session_id: string;
  message: string;
}

/**
 * Stubbed LLM response generator.
 * Simulates streaming by yielding words with delays.
 * 
 * In production, this would call OpenAI, Anthropic, or another LLM API.
 */
async function* generateResponse(userMessage: string): AsyncGenerator<string> {
  // Stubbed responses based on user input
  const responses = [
    `I understand you said: "${userMessage}".`,
    "This is a demo response from the NeverGone assistant.",
    "The streaming is working correctly!",
    "Each word appears progressively to demonstrate true SSE streaming.",
  ];
  
  const fullResponse = responses.join(" ");
  const words = fullResponse.split(" ");
  
  for (const word of words) {
    // Simulate LLM token generation delay (50-150ms per word)
    await new Promise((resolve) => setTimeout(resolve, 50 + Math.random() * 100));
    yield word + " ";
  }
}

/**
 * Format a chunk for SSE transmission
 */
function formatSSEChunk(content: string): string {
  return `data: ${JSON.stringify({ content })}\n\n`;
}

/**
 * Format the done signal for SSE
 */
function formatSSEDone(): string {
  return `data: [DONE]\n\n`;
}

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // Extract authorization header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Parse request body
    const { session_id, message }: ChatRequest = await req.json();
    
    if (!session_id || !message) {
      return new Response(
        JSON.stringify({ error: "Missing session_id or message" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Initialize Supabase client with user's JWT
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: {
        headers: { Authorization: authHeader },
      },
    });

    // Get the authenticated user
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "Invalid or expired token" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Verify session ownership (RLS will handle this, but explicit check for clarity)
    const { data: session, error: sessionError } = await supabase
      .from("chat_sessions")
      .select("id, user_id")
      .eq("id", session_id)
      .single();

    if (sessionError || !session) {
      return new Response(
        JSON.stringify({ error: "Session not found or access denied" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Insert user message
    const { error: insertUserError } = await supabase
      .from("chat_messages")
      .insert({
        session_id,
        role: "user",
        content: message,
      });

    if (insertUserError) {
      console.error("Failed to insert user message:", insertUserError);
      return new Response(
        JSON.stringify({ error: "Failed to save message" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Update session's updated_at timestamp
    await supabase
      .from("chat_sessions")
      .update({ updated_at: new Date().toISOString() })
      .eq("id", session_id);

    // Create streaming response
    const encoder = new TextEncoder();
    let fullAssistantResponse = "";
    let aborted = false;

    const stream = new ReadableStream({
      async start(controller) {
        try {
          // Stream the response word by word
          for await (const chunk of generateResponse(message)) {
            if (aborted) break;
            
            fullAssistantResponse += chunk;
            controller.enqueue(encoder.encode(formatSSEChunk(chunk)));
          }

          // Only persist if not aborted
          if (!aborted && fullAssistantResponse.trim()) {
            // Insert assistant message
            const { error: insertAssistantError } = await supabase
              .from("chat_messages")
              .insert({
                session_id,
                role: "assistant",
                content: fullAssistantResponse.trim(),
              });

            if (insertAssistantError) {
              console.error("Failed to insert assistant message:", insertAssistantError);
            }
          }

          // Send done signal
          controller.enqueue(encoder.encode(formatSSEDone()));
          controller.close();
        } catch (error) {
          console.error("Streaming error:", error);
          controller.error(error);
        }
      },
      cancel() {
        // Handle client disconnection
        aborted = true;
        console.log("Stream cancelled by client");
      },
    });

    return new Response(stream, {
      headers: {
        ...corsHeaders,
        "Content-Type": "text/event-stream",
        "Cache-Control": "no-cache",
        "Connection": "keep-alive",
      },
    });
  } catch (error) {
    console.error("Unexpected error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
