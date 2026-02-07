
import { assertEquals } from "https://deno.land/std@0.168.0/testing/asserts.ts";

// Simple utility to test
// In a real app, this would be imported from a shared module
function cleanContent(content: string): string {
    return content.trim();
}

function truncateSummary(summary: string, maxLength: number): string {
    if (summary.length <= maxLength) return summary;
    return summary.slice(0, maxLength) + "...";
}

Deno.test("cleanContent removes whitespace", () => {
    const input = "  Hello World  ";
    const expected = "Hello World";
    assertEquals(cleanContent(input), expected);
});

Deno.test("truncateSummary shortens long text", () => {
    const input = "This is a very long memory summary that needs to be shortened.";
    const maxLength = 10;
    const expected = "This is a ...";
    assertEquals(truncateSummary(input, maxLength), expected);
});

Deno.test("truncateSummary keeps short text", () => {
    const input = "Short.";
    const maxLength = 50;
    assertEquals(truncateSummary(input, maxLength), input);
});
