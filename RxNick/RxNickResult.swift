public enum RxNickResult<Value, Error> {
    case success(Value)
    case failure(Error)
}
