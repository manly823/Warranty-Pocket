import Foundation

final class Storage {
    static let shared = Storage()
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private init() {}
    
    func save<T: Codable>(_ value: T, forKey key: String) {
        if let data = try? encoder.encode(value) {
            defaults.set(data, forKey: key)
        }
    }
    
    func load<T: Codable>(forKey key: String, default defaultValue: T) -> T {
        guard let data = defaults.data(forKey: key),
              let value = try? decoder.decode(T.self, from: data) else {
            return defaultValue
        }
        return value
    }
    
    func remove(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}
