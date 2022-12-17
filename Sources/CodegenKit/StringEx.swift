extension String {
    public var pascal: String {
        guard let head = self.first else { return self }
        var tail = self
        tail.removeFirst()
        return head.uppercased() + tail
    }
}
