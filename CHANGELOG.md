
## 1.0.0

- **Feature**: Real-time streams for UI integration (`AutoSyncManager.pendingItemsStream` and `isSyncingStream`).
- **Feature**: AES database encryption via `flutter_secure_storage` to secure offline payloads.
- **Feature**: Queue prioritization (`priority` parameter in `addToQueue`).
- **Feature**: Support for all HTTP methods (GET, POST, PUT, DELETE, PATCH).
- **Feature**: Support for custom headers (e.g., Authorization tokens).
- **Fix**: Proper `retryCount` persistence across app restarts.
- **Fix**: Better HTTP success code handling (treats all 2xx responses as success).
- **Fix**: Added concurrent sync lock to prevent duplicate network calls.

## 0.0.5

- Fixed  files  

## 0.0.4

- Fixed LICENSE file to use a recognized OSI-approved MIT license
- Updated dependencies to latest compatible versions
- Fixed analyzer warnings and improved code quality
- Improved connectivity handling logic
- Updated documentation

## 0.0.3

- Updated dependencies to latest versions
- Fixed connectivity check for new connectivity_plus API
- Improved code quality based on Flutter analyzer suggestions
- Added const constructors where possible
- Improved documentation comments

## 0.0.2

- Added retry mechanism for failed sync requests
- Added updateItem method in LocalStorage
- Improved offline queue reliability
- Updated documentation

## 0.0.1

- Initial release of flutter_auto_sync
- Offline storage using Hive
- Automatic sync when internet connectivity returns