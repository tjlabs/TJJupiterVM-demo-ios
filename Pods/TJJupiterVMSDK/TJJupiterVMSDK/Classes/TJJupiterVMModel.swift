
import Foundation

public protocol TJJupiterVMDelegate: AnyObject {
    func onInitSuccess(_ isSuccess: Bool, _ code: InitErrorCode?)
    func onJupiterSuccess(_ isSuccess: Bool, _ code: JupiterErrorCode?)
    func onJupiterResult(_ result: JupiterResult)
    func onWebViewSuccess(_ isSuccess: Bool, _ code: VMErrorCode?)
    func didWebViewRemoved()
    func isEnteringWardDeteced(info: EnteringInfo)
    func isParkingLocationTapped(levelId: String, parkingLocationId: String)
}

var tjBranch: ServerBranch = .PROD
var tjRegion: JupiterVMRegion = .SAUDI

public enum ServerBranch {
    case DEV, PROD
}

public enum JupiterVMRegion: String {
    case KOREA = "KOREA"
    case SAUDI = "SAUDI"
}

public enum InitErrorCode: Int {
    case UNKNOWN = -1
    case NOT_AUTHORIZED = 0
    case INVALID_ID = 1
    case NETWORK_DISCONNECT = 2
    case LOGIN_FAIL = 3
    case LOAD_RESOURCE_FAIL = 4
}

public enum JupiterErrorCode: Int {
    case UNKNOWN = -1
    case NOT_INITIALIZED = 0
    case DUPLICATED_SERVICE = 1
    case GENERATOR_FAIL = 2
    // startService 의 sectorId 가 initialize 때 로드되지 않았거나 configureFrame 이 고정한 활성 섹터와 다름
    case INVALID_SECTOR = 3
}

public enum JupiterServiceCode: Int {
    case UNKNOWN = -1
    case SERVICE_FAIL = 0
    case SERVICE_SUCCESS = 1
    case BECOME_BACKGROUND = 2
    case BECOME_FOREGROUND = 3
    case BLUETOOTH_UNAVAILABLE = 4
    case BLUETOOTH_OFF = 5
    case BLUETOOTH_SCAN_STOP = 6
    case NETWORK_DISCONNECT = 7
    case GET_FIRST_RESULT = 8
    case PEAK_DETECTED = 300
}

public enum VMErrorCode: Int {
    case UNKNOWN = -1
    case NOT_INITIALIZED = 401
    case VM_VIEW_FAIL  = 402
    // configureFrame 의 sectorId 가 initialize 때 로드되지 않았거나 startService 가 고정한 활성 섹터와 다름
    case INVALID_SECTOR = 403
}

public struct JupiterResult: Codable {
    public var mobile_time: Int
    public var index: Int
    public var building_name: String
    public var level_name: String
    public var jupiter_pos: Position
    public var navi_pos: Position?
    // 목적지까지 남은 경로 거리(m). 차량 모드 + 길안내 경로가 있을 때만 값이 있고, 보행자 모드·경로 없음·도착/stop 이후는 nil.
    public var remaining_distance: Int?
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
    public let id: Int
    public let number: Int
    public let name: String
}

public enum ParkingLocationState: Int {
    case UNKNOWN = -1
    case VACANT = 0
    case OCCUPIED = 1
}
