extension Optional {
    public func unwrap(_ name: String) throws -> Wrapped {
        guard let self else {
            throw NoneError(name: name)
        }
        return self
    }
}
