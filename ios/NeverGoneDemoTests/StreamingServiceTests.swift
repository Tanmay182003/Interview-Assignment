//
//  StreamingServiceTests.swift
//  NeverGoneDemoTests
//
//  Tests for the streaming service functionality.
//

import XCTest
@testable import NeverGoneDemo

final class StreamingServiceTests: XCTestCase {
    
    // MARK: - SSE Parsing Tests
    
    /// Test that SSE chunks are correctly parsed
    func testParseSSEChunk() {
        // Simulate the parsing logic from StreamingService
        let sseEvent = "data: {\"content\":\"Hello \"}\n"
        
        // Parse the event
        let content = parseSSEEvent(sseEvent)
        
        XCTAssertEqual(content, "Hello ")
    }
    
    /// Test that DONE signal is recognized
    func testParseSSEDoneSignal() {
        let sseEvent = "data: [DONE]\n"
        
        let content = parseSSEEvent(sseEvent)
        
        XCTAssertEqual(content, "[DONE]")
    }
    
    /// Test that multiple SSE events can be parsed
    func testParseMultipleSSEChunks() {
        let events = [
            "data: {\"content\":\"Hello \"}\n",
            "data: {\"content\":\"world!\"}\n",
            "data: [DONE]\n"
        ]
        
        var fullContent = ""
        for event in events {
            if let content = parseSSEEvent(event), content != "[DONE]" {
                fullContent += content
            }
        }
        
        XCTAssertEqual(fullContent, "Hello world!")
    }
    
    /// Test that invalid JSON is handled gracefully
    func testParseInvalidSSEChunk() {
        let sseEvent = "data: invalid json\n"
        
        let content = parseSSEEvent(sseEvent)
        
        XCTAssertNil(content)
    }
    
    /// Test empty event handling
    func testParseEmptySSEEvent() {
        let sseEvent = ""
        
        let content = parseSSEEvent(sseEvent)
        
        XCTAssertNil(content)
    }
    
    // MARK: - StreamingTask Tests
    
    /// Test that StreamingTask can be cancelled
    func testStreamingTaskCancellation() async {
        let task = StreamingTask()
        
        // Verify task is not active initially
        XCTAssertFalse(task.isActive)
        
        // Cancel should not crash even when not started
        task.cancel()
        
        XCTAssertFalse(task.isActive)
    }
    
    // MARK: - ChatMessage Tests
    
    /// Test local message creation
    func testLocalMessageCreation() {
        let sessionId = UUID()
        
        let message = ChatMessage.local(
            sessionId: sessionId,
            role: .user,
            content: "Hello"
        )
        
        XCTAssertEqual(message.sessionId, sessionId)
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content, "Hello")
        XCTAssertNotNil(message.id)
        XCTAssertNotNil(message.createdAt)
    }
    
    /// Test message role enum
    func testMessageRoles() {
        XCTAssertEqual(MessageRole.user.rawValue, "user")
        XCTAssertEqual(MessageRole.assistant.rawValue, "assistant")
    }
    
    // MARK: - Helper
    
    /// Parse an SSE event (mirroring StreamingService logic for testing)
    private func parseSSEEvent(_ event: String) -> String? {
        let lines = event.components(separatedBy: "\n")
        
        for line in lines {
            if line.hasPrefix("data: ") {
                let data = String(line.dropFirst(6))
                
                if data == "[DONE]" {
                    return "[DONE]"
                }
                
                if let jsonData = data.data(using: .utf8),
                   let chunk = try? JSONDecoder().decode(StreamChunk.self, from: jsonData) {
                    return chunk.content
                }
            }
        }
        
        return nil
    }
}

// MARK: - Mock Streaming Tests

/// Tests for streaming with mocked data
final class MockStreamingTests: XCTestCase {
    
    /// Test that streaming chunks accumulate correctly
    func testChunkAccumulation() {
        let chunks = ["Hello ", "world", "! ", "How ", "are ", "you?"]
        var accumulated = ""
        
        for chunk in chunks {
            accumulated += chunk
        }
        
        XCTAssertEqual(accumulated, "Hello world! How are you?")
    }
    
    /// Test cancellation mid-stream behavior
    func testCancellationMidStream() {
        let allChunks = ["Hello ", "world", "! ", "How ", "are ", "you?"]
        var accumulated = ""
        var cancelled = false
        
        // Simulate receiving chunks and cancelling after 3
        for (index, chunk) in allChunks.enumerated() {
            if cancelled { break }
            
            accumulated += chunk
            
            if index == 2 {
                cancelled = true
            }
        }
        
        XCTAssertEqual(accumulated, "Hello world! ")
        XCTAssertTrue(cancelled)
    }
}
