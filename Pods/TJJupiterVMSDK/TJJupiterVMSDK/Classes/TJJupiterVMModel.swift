
import Foundation

public protocol TJJupiterVMDelegate: AnyObject {
    func onInitSuccess(_ isSuccess: Bool, _ code: InitErrorCode?)
    func onJupiterSuccess(_ isSuccess: Bool, _ code: JupiterErrorCode?)
    func onJupiterResult(_ result: JupiterResult)
    func onWebViewSuccess(_ isSuccess: Bool, _ code: VMErrorCode?)
    func didWebViewRemoved()
    func isEnteringWardDeteced(info: EnteringInfo)
    func isParkingLocationTapped(_ parkingLocationId: String)
}

public enum JupiterVMRegion: String {
    case KOREA = "KOREA"
    case US_EAST = "US_EAST"
    case CANADA = "CANADA"
    case SAUDI = "SAUDI"
}

public enum InitErrorCode: Int {
    case UNKNOWN = -1
    case NOT_AUTHORIZED = 0
    case INVALID_ID = 1
    case INVALID_MODE = 2
    case NETWORK_DISCONNECT = 3
    case DUPLICATED_SERVICE = 4
    case LOGIN_FAIL = 5
    case CALC_INIT_FAIL = 6
}

public enum JupiterErrorCode: Int {
    case UNKNOWN = -1
    case INVALID_ID = 0
    case INVALID_MODE = 1
    case NETWORK_DISCONNECT = 2
    case DUPLICATED_SERVICE = 3
    case LOGIN_FAIL = 4
    case GENERATOR_FAIL = 5
    case CALC_INIT_FAIL = 6
}

public enum VMErrorCode: Int {
    case UNKNOWN = -1
    case VM_VIEW_FAIL  = 402
}

public struct JupiterResult: Codable {
    public var mobile_time: Int
    public var index: Int
    public var building_name: String
    public var level_name: String
    public var jupiter_pos: Position
    public var navi_pos: Position?
    public var llh: LLH?
    public var velocity: Float
    public var is_vehicle: Bool
    public var is_indoor: Bool
    public var validity_flag: Int
}

public struct Position: Codable {
    public var x: Float
    public var y: Float
    public var heading: Float
}

public struct LLH: Codable {
    public var lat: Double
    public var lon: Double
    public var azimuth: Double
}


public struct EnteringInfo: Codable {
    let id: Int
    let number: Int
    let name: String
}

public enum ParkingLocationState: Int {
    case UNKNOWN = -1
    case VACANT = 0
    case OCCUPIED = 1
}
