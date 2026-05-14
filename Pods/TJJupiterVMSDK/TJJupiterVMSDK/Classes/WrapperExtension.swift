
import Foundation
import TJLabsCommon
import TJLabsJupiter
import TJLabsJupiterVM

// MARK: - To JupiterVM
extension ParkingLocationState {
    func toJupiterVM() -> TJLabsJupiterVM.ParkingLocationState {
        return TJLabsJupiterVM.ParkingLocationState(rawValue: self.rawValue) ?? .OCCUPIED
    }
}

// MARK: - To Wrap 필요
extension TJLabsJupiter.InitErrorCode {
    func toWrap() -> InitErrorCode {
        return InitErrorCode(rawValue: self.rawValue) ?? .UNKNOWN
    }
}

extension TJLabsJupiter.JupiterErrorCode {
    func toWrap() -> JupiterErrorCode {
        return JupiterErrorCode(rawValue: self.rawValue) ?? .UNKNOWN
    }
}

extension TJLabsJupiterVM.VMErrorCode {
    func toWrap() -> VMErrorCode {
        return VMErrorCode(rawValue: self.rawValue) ?? .UNKNOWN
    }
}

extension TJLabsJupiter.Position {
    func toWrap() -> Position {
        return Position(
            x: self.x,
            y: self.y,
            heading: self.heading
        )
    }
}

extension TJLabsJupiter.LLH {
    func toWrap() -> LLH {
        return LLH(
            lat: self.lat,
            lon: self.lon,
            azimuth: self.azimuth
        )
    }
}

extension TJLabsJupiter.JupiterResult {
    func toWrap() -> JupiterResult {
        return JupiterResult(
            mobile_time: self.mobile_time,
            index: self.index,
            building_name: self.building_name,
            level_name: self.level_name,
            jupiter_pos: self.jupiter_pos.toWrap(),
            navi_pos: self.navi_pos?.toWrap(),
            llh: self.llh?.toWrap(),
            velocity: self.velocity,
            is_vehicle: self.is_vehicle,
            is_indoor: self.is_indoor,
            validity_flag: self.validity_flag
        )
    }
}

extension TJLabsJupiterVM.EnteringInfo {
    func toWrap() -> EnteringInfo {
        return EnteringInfo(id: self.id,
                            number: self.number,
                            name: self.name)
    }
}

extension TJLabsJupiterVM.ParkingLocationState {
    func toWrap() -> ParkingLocationState {
        return ParkingLocationState(rawValue: self.rawValue) ?? .UNKNOWN
    }
}
