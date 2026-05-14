

import Foundation
import UIKit
import TJLabsJupiter
import TJLabsJupiterVM

public class TJJupiterVMView: UIView, JupiterVMDelegate {
    
    public func onInitSuccess(_ isSuccess: Bool, _ code: TJLabsJupiter.InitErrorCode?) {
        delegate?.onInitSuccess(isSuccess, code?.toWrap())
    }
    
    public func onJupiterSuccess(_ isSuccess: Bool, _ code: TJLabsJupiter.JupiterErrorCode?) {
        delegate?.onJupiterSuccess(isSuccess, code?.toWrap())
    }
    
    public func onJupiterResult(_ result: TJLabsJupiter.JupiterResult) {
        delegate?.onJupiterResult(result.toWrap())
    }
    
    public func onWebViewSuccess(_ isSuccess: Bool, _ code: TJLabsJupiterVM.VMErrorCode?) {
        delegate?.onWebViewSuccess(isSuccess, code?.toWrap())
    }
    
    public func didWebViewRemoved() {
        delegate?.didWebViewRemoved()
    }
    
    public func isEnteringWardDeteced(info: TJLabsJupiterVM.EnteringInfo) {
        delegate?.isEnteringWardDeteced(info: info.toWrap())
    }
    
    public func isParkingLocationTapped(_ parkingLocationId: String) {
        delegate?.isParkingLocationTapped(parkingLocationId)
    }
    
    private var vmView = JupiterVMView()
    public weak var delegate: TJJupiterVMDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    public func initialize(userId: String, region: String = VMRegion.SAUDI.rawValue, sectorId: Int) {
        self.vmView.initialize(userId: userId, region: region, sectorId: sectorId)
        self.vmView.delegate = self
    }
    
    public func startService() {
        self.vmView.startService()
    }
    
    public func stopService(completion: @escaping (Bool, String) -> Void) {
        self.vmView.stopService(completion: completion)
    }
    
    public func configureFrame(to matchView: UIView) {
        self.vmView.configureFrame(to: matchView)
    }

    public func closeFrame() {
        self.vmView.closeFrame()
    }
    
    public func setSavedParkingLocations(parkingLocationIds: [String]) {
        self.vmView.setSavedParkingLocations(parkingLocationIds: parkingLocationIds)
    }
    
    public func setVacantParkingLocations(levelId: Int, parkingLocationStates: [String: ParkingLocationState]) {
        var wrapped = [String: TJLabsJupiterVM.ParkingLocationState]()
        for (key, value) in parkingLocationStates {
            wrapped[key] = value.toJupiterVM()
        }
        self.vmView.setVacantParkingLocations(levelId: levelId, parkingLocationStates: wrapped)
    }
    
    public func updateVacantParkingLocations(levelId: Int, parkingLocationStates: [String: ParkingLocationState]) {
        var wrapped = [String: TJLabsJupiterVM.ParkingLocationState]()
        for (key, value) in parkingLocationStates {
            wrapped[key] = value.toJupiterVM()
        }
        self.vmView.updateVacantParkingLocations(levelId: levelId, parkingLocationStates: wrapped)
    }
}
