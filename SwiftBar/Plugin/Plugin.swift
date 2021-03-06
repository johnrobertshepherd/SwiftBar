import Combine
import Foundation
import os

enum PluginType: String {
    case Executable
    case Streamable
}

enum PluginState {
    case Loading
    case Streaming
    case Success
    case Failed
    case Disabled
}

typealias PluginID = String

protocol Plugin: AnyObject {
    var id: PluginID { get }
    var type: PluginType { get }
    var name: String { get }
    var file: String { get }
    var enabled: Bool { get }
    var metadata: PluginMetadata? { get set }
    var contentUpdatePublisher: PassthroughSubject<Any, Never> { get set }
    var updateInterval: Double { get }
    var lastUpdated: Date? { get set }
    var lastState: PluginState { get set }
    var content: String? { get set }
    var error: ShellOutError? { get set }
    func refresh()
    func enable()
    func disable()
    func terminate()
    func invoke() -> String?
    func makeScriptExecutable(file: String)
    func refreshPluginMetadata()
}

extension Plugin {
    var description: String {
        """
        id: \(id)
        type: \(type)
        name: \(name)
        path: \(file)
        """
    }

    var prefs: Preferences {
        Preferences.shared
    }

    var enabled: Bool {
        !prefs.disabledPlugins.contains(id)
    }

    func makeScriptExecutable(file: String) {
        guard prefs.makePluginExecutable else { return }
        let script = """
        if [[ -x "\(file)" ]]
        then
            echo "File "\(file)" is executable"
        else
            chmod +x "\(file)"
        fi
        """
        _ = try? runScript(to: script)
    }

    func refreshPluginMetadata() {
        os_log("Refreshing plugin metadata \n%{public}@", log: Log.plugin, file)
        let url = URL(fileURLWithPath: file)
        if let script = try? String(contentsOf: url) {
            metadata = PluginMetadata.parser(script: script)
        }
        if let md = PluginMetadata.parser(fileURL: url) {
            metadata = md
        }
    }
}
