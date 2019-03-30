@testable import bulbivorusCore
import Foundation

let r = "hi.*"
let trimmedRequest = "hiii"
if let range = trimmedRequest.range(of: r, options: .regularExpression), range.lowerBound == trimmedRequest.startIndex, range.upperBound == trimmedRequest.endIndex {
    dump(range)
}
