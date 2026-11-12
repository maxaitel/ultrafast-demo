import Foundation
import Security

// Secrets enter through stdin and leave only through a pipe to the launcher.
let service = "com.openai.codex.ultrafast-demo"
let account = "openai-api-key"
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: service,
    kSecAttrAccount as String: account,
]

func fail(_ message: String, code: Int32 = 1) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(code)
}

func check(_ status: OSStatus) {
    guard status == errSecSuccess else {
        let detail = SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error"
        fail("ultrafast-demo: Keychain error: \(detail)")
    }
}

switch CommandLine.arguments.dropFirst().first {
case "get":
    // Prevent accidental display of a saved key in a terminal.
    guard isatty(STDOUT_FILENO) == 0 else {
        fail("ultrafast-demo: refusing to display the API key in a terminal.")
    }
    var request = query
    request[kSecReturnData as String] = true
    request[kSecMatchLimit as String] = kSecMatchLimitOne
    var result: CFTypeRef?
    let status = SecItemCopyMatching(request as CFDictionary, &result)
    if status == errSecItemNotFound {
        fail("ultrafast-demo: no saved key. Run ultrafast-demo --setup-key first.", code: 2)
    }
    check(status)
    guard let data = result as? Data, !data.isEmpty else {
        fail("ultrafast-demo: the saved Keychain entry is empty.")
    }
    FileHandle.standardOutput.write(data)
case "set":
    guard isatty(STDIN_FILENO) == 0 else {
        fail("ultrafast-demo: use --setup-key to enter a key privately.")
    }
    let data = FileHandle.standardInput.readDataToEndOfFile()
    guard let key = String(data: data, encoding: .utf8),
          key.hasPrefix("sk-"), !key.contains(where: { $0.isWhitespace }) else {
        fail("ultrafast-demo: expected an OpenAI API key without whitespace.")
    }
    var entry = query
    entry[kSecAttrLabel as String] = "Ultrafast Demo API Key"
    entry[kSecValueData as String] = data
    let status = SecItemAdd(entry as CFDictionary, nil)
    if status == errSecDuplicateItem {
        check(SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary))
    } else {
        check(status)
    }
    print("Saved API key in macOS Keychain for ultrafast-demo.")
case "status":
    var request = query
    request[kSecReturnAttributes as String] = true
    let status = SecItemCopyMatching(request as CFDictionary, nil)
    if status == errSecItemNotFound {
        print("No API key saved for ultrafast-demo.")
        exit(2)
    }
    check(status)
    print("API key saved in macOS Keychain for ultrafast-demo.")
default:
    fail("Usage: ultrafast-demo-keychain get|set|status")
}
