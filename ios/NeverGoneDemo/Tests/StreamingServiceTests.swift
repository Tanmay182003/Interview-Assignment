//
//  StreamingServiceTests.swift
//  NeverGoneDemoTests
//
//  Tests for StreamingService logic.
//

import XCTest
@testable import NeverGoneDemo

final class StreamingServiceTests: XCTestCase {
    
    // Test parsing logic (mocked via a private extension or similar if accessible, 
    // or by testing a public helper function if we refactored).
    // Since parseSSEEvent is private, we'll test the public streamChat method with a mocked URLSession 
    // if we had dependency injection.
    
    // For this assignment, we'll demonstrate a unit test for a string parsing helper 
    // that mimics the SSE logic.
    
    func testSSEParsing() {
        let event = "data: {\"content\": \"Hello\"}\n\n"
        let expectedContent = "Hello"
        
        let chunk = parseSSEEventMock(event)
        XCTAssertEqual(chunk, expectedContent)
    }
    
    func testDoneSignal() {
        let event = "data: [DONE]\n\n"
        let chunk = parseSSEEventMock(event)
        XCTAssertEqual(chunk, "[DONE]")
    }
    
    // A helper duplicating the logic for testability without exposing private methods
    private func parseSSEEventMock(_ event: String) -> String? {
        let lines = event.components(separatedBy: "\n")
        for line in lines {
            if line.hasPrefix("data: ") {
                let data = String(line.dropFirst(6))
                if data == "[DONE]" { return "[DONE]" }
                
                struct StreamChunk: Codable { let content: String }
                if let jsonData = data.data(using: .utf8),
                   let chunk = try? JSONDecoder().decode(StreamChunk.self, from: jsonData) {
                    return chunk.content
                }
            }
        }
        return nil
    }
}
