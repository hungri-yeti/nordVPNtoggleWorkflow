// Ken Luke, 02 Apr 2025
// copyright 2025, all rights reserved.
// ------------------------------------
import Foundation


// Modify this to correspond to your VPN
// use the command:
// scutil --nc list
// to list out all current VPN
private let ServiceName = "NordVPN NordLynx 2"

// full path to the scutil command:
private let scutilCmd = "/usr/sbin/scutil"

// various scutil commnds:
private let scutilNetworkCmdOpt = "--nc"
private let scutilNCStatusCmd = "status"
private let scutilNCStartCmd = "start"
private let scutilNCStopCmd = "stop"

// these may change based on locale/language?:
private let scutilDisconnectedString = "Disconnected"
private let scutilConnectedString = "Connected"



// main:
setConnected(isConnected)



private func setConnected(_ state: Bool) {
	// debug:
	switch state {
		case true: print("connected -> disconnecting...")
		case false: print("disconnected -> connecting...")
	}
	
	let cmd = state ? scutilNCStopCmd : scutilNCStartCmd
	let (_, _, error) = Process.shell(
		path: scutilCmd,
		args: [scutilNetworkCmdOpt, cmd, ServiceName]
	)
	
	if let error {
		print("error: cmd: \(cmd) failed: \(error)")
		exit(3)
	}
}


private var isConnected: Bool {
	let (_, output, error) = Process.shell(
		path: scutilCmd,
		args: [scutilNetworkCmdOpt, scutilNCStatusCmd, ServiceName]
	)
	
	guard let output else {
		print("error: output unexpectedly empty")
		exit(1)
	}
	
	if let error {
		print("error: scutilNCStatusCmd: \(scutilNCStatusCmd) failed: \(error)")
		exit(5)
	}
	
	if output.hasPrefix(scutilDisconnectedString) {
		return false
	}
	else if output.hasPrefix(scutilConnectedString) {
		return true
	}
	
	print("error: unable to determine connected/disconnected state")
	exit(2)
}



// Credit: https://stackoverflow.com/a/79123107/5768505
extension Process {
	
	static func shell(path: String = "/bin/zsh", args:[String] = []) -> (Int32, String?, String?) {
		let task = Process()
		let pipeOut = Pipe()
		let pipeErr = Pipe()
		task.standardInput = nil
		task.standardOutput = pipeOut
		task.standardError = pipeErr
		task.executableURL = URL(fileURLWithPath: path)
		task.arguments = args
		do {
			try task.run()
			task.waitUntilExit()
			let dataOut = pipeOut.fileHandleForReading.readDataToEndOfFile()
			let dataErr = pipeErr.fileHandleForReading.readDataToEndOfFile()
			return (
				task.terminationStatus,
				dataOut.isEmpty ? nil : String(data: dataOut, encoding: .utf8),
				dataErr.isEmpty ? nil : String(data: dataErr, encoding: .utf8)
			)
		} catch {
			return (0, nil, nil)
		}
	}
}
