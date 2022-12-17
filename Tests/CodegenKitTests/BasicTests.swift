import XCTest
@testable import CodeTemplate

final class BasicTests: XCTestCase {
    func testSplitLines() {
        XCTAssertEqual("".splitLines(), [])
        XCTAssertEqual("aa".splitLines(), ["aa"])
        XCTAssertEqual("aa\nbb".splitLines(), ["aa\n", "bb"])
        XCTAssertEqual("aa\nbb\n".splitLines(), ["aa\n", "bb\n"])
        XCTAssertEqual("aa\n\nbb".splitLines(), ["aa\n", "\n", "bb"])
        XCTAssertEqual("aa\rbb\r\ncc".splitLines(), ["aa\r", "bb\r\n", "cc"])
    }

    func testTemplate() {
        var t = Template(string: """
            class V {
                // @codegen(aaa)
                func foo0() {}
                func foo1() {}
                // @end
            }

            """
        )

        XCTAssertEqual(t.fragments.count, 3)
        XCTAssertEqual(t.fragments[safe: 0], .text("""
            class V {
                // @codegen(aaa)

            """)
        )
        XCTAssertEqual(t.fragments[safe: 1], .placeholder(
            name: "aaa", content: """
                func foo0() {}
                func foo1() {}

            """
        ))
        XCTAssertEqual(t.fragments[safe: 2], .text("""
                // @end
            }

            """)
        )

        XCTAssertEqual(t.description, """
            class V {
                // @codegen(aaa)
                func foo0() {}
                func foo1() {}
                // @end
            }

            """
        )

        XCTAssertEqual(t.names, ["aaa"])

        t["aaa"] = ("""
                func foo2() {}
                func foo3() {}
            """
        )

        XCTAssertEqual(t.description, """
            class V {
                // @codegen(aaa)
                func foo2() {}
                func foo3() {}
                // @end
            }

            """
        )
    }
}
