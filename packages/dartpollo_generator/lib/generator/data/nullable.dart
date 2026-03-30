/// Allows to reset values back to null in `copyWith` pattern
class Nullable<T> {
  /// Sets desired value
  Nullable(this._value);
  final T _value;

  /// Gets the real value
  T get value {
    return _value;
  }
}
