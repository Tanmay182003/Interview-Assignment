/**
 * Deno Tests for Edge Function Helpers
 * 
 * Run with: deno test --allow-read backend/supabase/functions/tests/
 */

import { assertEquals, assertStringIncludes } from "https://deno.land/std@0.177.0/testing/asserts.ts";

// Import the generateSummary function for testing
// Note: In a real setup, we'd export this from a shared module
// For this test, we'll recreate the function to test its logic

interface ChatMessage {
    id: string;
    role: "user" | "assistant";
    content: string;
    created_at: string;
}

/**
 * Stubbed summary generator (copied from summarize_memory for testing)
 */
function generateSummary(messages: ChatMessage[]): string {
    if (messages.length === 0) {
        return "Empty conversation - no messages to summarize.";
    }

    const userMessages = messages
        .filter((m) => m.role === "user")
        .map((m) => m.content);

    if (userMessages.length === 0) {
        return "Conversation contained only assistant messages.";
    }

    const messageCount = messages.length;
    const userMessageCount = userMessages.length;

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

/**
 * SSE chunk formatter (copied from chat_stream for testing)
 */
function formatSSEChunk(content: string): string {
    return `data: ${JSON.stringify({ content })}\n\n`;
}

function formatSSEDone(): string {
    return `data: [DONE]\n\n`;
}

// ============================================================================
// SUMMARY GENERATION TESTS
// ============================================================================

Deno.test("generateSummary - empty messages returns empty summary", () => {
    const result = generateSummary([]);
    assertEquals(result, "Empty conversation - no messages to summarize.");
});

Deno.test("generateSummary - only assistant messages returns appropriate message", () => {
    const messages: ChatMessage[] = [
        {
            id: "1",
            role: "assistant",
            content: "Hello, how can I help you?",
            created_at: "2024-01-01T10:00:00Z",
        },
    ];
    const result = generateSummary(messages);
    assertEquals(result, "Conversation contained only assistant messages.");
});

Deno.test("generateSummary - includes message count", () => {
    const messages: ChatMessage[] = [
        {
            id: "1",
            role: "user",
            content: "Hello there",
            created_at: "2024-01-01T10:00:00Z",
        },
        {
            id: "2",
            role: "assistant",
            content: "Hi! How can I help?",
            created_at: "2024-01-01T10:00:01Z",
        },
        {
            id: "3",
            role: "user",
            content: "Tell me about the weather",
            created_at: "2024-01-01T10:00:02Z",
        },
    ];

    const result = generateSummary(messages);
    assertStringIncludes(result, "3 messages");
    assertStringIncludes(result, "2 from user");
});

Deno.test("generateSummary - extracts topics from user messages", () => {
    const messages: ChatMessage[] = [
        {
            id: "1",
            role: "user",
            content: "What is the meaning of life and everything in the universe?",
            created_at: "2024-01-01T10:00:00Z",
        },
        {
            id: "2",
            role: "assistant",
            content: "42",
            created_at: "2024-01-01T10:00:01Z",
        },
    ];

    const result = generateSummary(messages);
    assertStringIncludes(result, "Topics discussed:");
    assertStringIncludes(result, "What is the meaning of...");
});

Deno.test("generateSummary - limits topics to 3", () => {
    const messages: ChatMessage[] = [
        { id: "1", role: "user", content: "Topic one", created_at: "2024-01-01T10:00:00Z" },
        { id: "2", role: "user", content: "Topic two", created_at: "2024-01-01T10:00:01Z" },
        { id: "3", role: "user", content: "Topic three", created_at: "2024-01-01T10:00:02Z" },
        { id: "4", role: "user", content: "Topic four", created_at: "2024-01-01T10:00:03Z" },
        { id: "5", role: "user", content: "Topic five", created_at: "2024-01-01T10:00:04Z" },
    ];

    const result = generateSummary(messages);
    assertStringIncludes(result, "Topic one");
    assertStringIncludes(result, "Topic two");
    assertStringIncludes(result, "Topic three");
    // Should not include topics 4 and 5
    assertEquals(result.includes("Topic four"), false);
    assertEquals(result.includes("Topic five"), false);
});

// ============================================================================
// SSE FORMATTING TESTS
// ============================================================================

Deno.test("formatSSEChunk - formats content correctly", () => {
    const result = formatSSEChunk("Hello ");
    assertEquals(result, 'data: {"content":"Hello "}\n\n');
});

Deno.test("formatSSEChunk - escapes special characters", () => {
    const result = formatSSEChunk('Say "hello"');
    assertEquals(result, 'data: {"content":"Say \\"hello\\""}\n\n');
});

Deno.test("formatSSEDone - returns done signal", () => {
    const result = formatSSEDone();
    assertEquals(result, "data: [DONE]\n\n");
});

// ============================================================================
// INTEGRATION-STYLE TESTS
// ============================================================================

Deno.test("SSE stream simulation - multiple chunks form complete message", () => {
    const words = ["Hello", "world", "from", "streaming"];
    const chunks = words.map((w) => formatSSEChunk(w + " "));

    // Verify each chunk is properly formatted
    assertEquals(chunks.length, 4);
    assertStringIncludes(chunks[0], "Hello");
    assertStringIncludes(chunks[3], "streaming");

    // Verify done signal
    const done = formatSSEDone();
    assertStringIncludes(done, "[DONE]");
});
