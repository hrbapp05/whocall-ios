import XCTest
@testable import Whocall

final class NotificationPreferenceTests: XCTestCase {
    func testNewAccountDefaultsToNotificationsEnabled() throws {
        let defaults = try makeDefaults()

        XCTAssertTrue(NotificationPreference.isEnabled(userID: "new-user", defaults: defaults))
        XCTAssertFalse(NotificationPreference.isEnabled(userID: nil, defaults: defaults))
    }

    func testPreferenceCanBeDisabledAndReset() throws {
        let defaults = try makeDefaults()
        let userID = "notification-user"

        NotificationPreference.setEnabled(false, userID: userID, defaults: defaults)
        XCTAssertFalse(NotificationPreference.isEnabled(userID: userID, defaults: defaults))

        NotificationPreference.clear(userID: userID, defaults: defaults)
        XCTAssertTrue(NotificationPreference.isEnabled(userID: userID, defaults: defaults))
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "NotificationPreferenceTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
