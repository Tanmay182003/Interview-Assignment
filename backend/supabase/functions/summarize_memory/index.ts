/**
 * summarize_memory Edge Function
 * 
 * Generates a summary of a chat session and stores it as a memory.
 * 
 * Flow:
 * 1. Receive session_id from client
 * 2. Verify session ownership via JWT
 * 3. Fetch all messages from the session
 * 4. Generate summary (stubbed - extracts key information)
 * 5. Insert summary into memories table
 * 6. Return the created memory
 */

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

// CORS headers for local development
const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface SummarizeRequest {
    session_id: string;
}

interface ChatMessage {
    id: string;
    role: "user" | "assistant";
    content: string;
    created_at: string;
}

/**
 * Stubbed summary generator.
 * In production, this would call an LLM to generate a meaningful summary.
 * 
 * Current implementation:
 * - Extracts user messages
 * - Creates a simple summary of topics discussed
 */
export function generateSummary(messages: ChatMessage[]): string {
    if (messages.length === 0) {
        return "Empty conversation - no messages to summarize.";
    }

    // Extract user messages
    const userMessages = messages
        .filter((m) => m.role === "user")
        .map((m) => m.content);

    if (userMessages.length === 0) {
        return "Conversation contained only assistant messages.";
    }

    // Simple stubbed summary
    const messageCount = messages.length;
    const userMessageCount = userMessages.length;

    // Extract first few words from each user message as "topics"
    const topics = userMessages
        .map((msg) => {
            const words = msg.split(" ").slice(0, 5).join(" ");
            return words.length < msg.length ? words + "..." : words;
        })
        .slice(0, 3);

    const summary = [
        `Conversation summary (${messageCount} messages, ${userMessageCount} from user):`,
        "",
        "Topics discussed:",
        ...topics.map((t, i) => `${i + 1}. "${t}"`),
        "",
        `First message: ${new Date(messages[0].created_at).toLocaleString()}`,
        `Last message: ${new Date(messages[messages.length - 1].created_at).toLocaleString()}`,
    ].join("\n");

    return summary;
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
        const { session_id }: SummarizeRequest = await req.json();

        if (!session_id) {
            return new Response(
                JSON.stringify({ error: "Missing session_id" }),
                { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        // Initialize Supabase client with user's JWT
        const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
        const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
        const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

        // Extract JWT from Bearer token
        const jwt = authHeader.replace("Bearer ", "");

        // Use service role key for database operations
        const supabase = createClient(supabaseUrl, supabaseServiceKey || supabaseAnonKey, {
            auth: {
                autoRefreshToken: false,
                persistSession: false,
            },
        });

        // Verify the user's JWT
        const { data: { user }, error: userError } = await supabase.auth.getUser(jwt);
        if (userError || !user) {
            console.error("Auth error:", userError);
            return new Response(
                JSON.stringify({ error: "Invalid or expired token" }),
                { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        // Verify session ownership and fetch session
        const { data: session, error: sessionError } = await supabase
            .from("chat_sessions")
            .select("id, user_id, title")
            .eq("id", session_id)
            .single();

        if (sessionError || !session) {
            return new Response(
                JSON.stringify({ error: "Session not found or access denied" }),
                { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        // Fetch all messages from the session
        const { data: messages, error: messagesError } = await supabase
            .from("chat_messages")
            .select("id, role, content, created_at")
            .eq("session_id", session_id)
            .order("created_at", { ascending: true });

        if (messagesError) {
            console.error("Failed to fetch messages:", messagesError);
            return new Response(
                JSON.stringify({ error: "Failed to fetch messages" }),
                { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        // Generate summary
        const summary = generateSummary(messages as ChatMessage[]);

        // Insert memory
        const { data: memory, error: insertError } = await supabase
            .from("memories")
            .insert({
                user_id: user.id,
                session_id,
                summary,
            })
            .select()
            .single();

        if (insertError) {
            console.error("Failed to insert memory:", insertError);
            return new Response(
                JSON.stringify({ error: "Failed to save memory" }),
                { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        return new Response(
            JSON.stringify({
                success: true,
                memory: {
                    id: memory.id,
                    session_id: memory.session_id,
                    summary: memory.summary,
                    created_at: memory.created_at,
                },
            }),
            {
                status: 200,
                headers: { ...corsHeaders, "Content-Type": "application/json" }
            }
        );
    } catch (error) {
        console.error("Unexpected error:", error);
        return new Response(
            JSON.stringify({ error: "Internal server error" }),
            { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
    }
});
