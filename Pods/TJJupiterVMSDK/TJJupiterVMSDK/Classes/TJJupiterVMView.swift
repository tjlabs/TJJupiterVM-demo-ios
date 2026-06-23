
import Foundation
import UIKit
import TJLabsCommon
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
    
    public func isParkingLocationTapped(levelId: Int, parkingLocationId: String) {
        delegate?.isParkingLocationTapped(levelId: levelId, parkingLocationId: parkingLocationId)
    }
    
    private var vmView = JupiterVMView()
    public weak var delegate: TJJupiterVMDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func initialize(userId: String, region: String = VMRegion.SAUDI.rawValue, sectorId: Int, debugOption: Bool = true) {
        JupiterNetworkConstants.setServerBranch(prod: true)
        self.vmView.initialize(userId: userId, region: region, sectorId: sectorId, debugOption: debugOption)
        self.vmView.delegate = self
    }
    
    public func startService() {
        let appName = JupiterReplayer.shared.replayMode ? "ios_vm_replay" : "ios_vm_prod"
        self.vmView.setLSEAppName(name: appName)
        self.vmView.startService()
    }
    
    public func stopService(completion: @escaping (Bool, String) -> Void) {
        self.vmView.stopService(completion: completion)
    }
    
    public func setReplayMode(flag: Bool, rfdFileName: String, uvdFileName: String, eventFileName: String) {
        self.vmView.setReplayMode(flag: flag, rfdFileName: rfdFileName, uvdFileName: uvdFileName, eventFileName: eventFileName)
    }
    
    public func setMockMode(mode: JupiterMockMode, completion: @escaping (Bool) -> Void) {
        self.vmView.setMockMode(mode: mode, completion: { isSuccess in
            completion(isSuccess)
        })
    }
    
    public func configureFrame(to matchView: UIView) {
        self.vmView.configureFrame(to: matchView)
    }

    public func closeFrame() {
        self.vmView.closeFrame()
    }
    
    public func setSavedParkingLocations(parkingLocations: [Int: [String]]) {
        self.vmView.setSavedParkingLocations(parkingLocations)
    }
    
    public func updateSavedParkingLocations(parkingLocations: [Int: [String]]) {
        self.vmView.updateSavedParkingLocations(parkingLocations)
    }
    
    public func setParkingLocationStates(parkingLocationStates: [Int: [String: ParkingLocationState]]) {
        var statesInput = [Int : [String: TJLabsJupiterVM.ParkingLocationState]]()
        
        for (levelId, data) in parkingLocationStates {
            var wrapped = [String: TJLabsJupiterVM.ParkingLocationState]()
            for (pId, pState) in data {
                wrapped[pId] = pState.toJupiterVM()
            }
            statesInput[levelId] = wrapped
        }

        self.vmView.setParkingLocationStates(parkingLocationStates: statesInput)
    }

    public func updateParkingLocationStates(parkingLocationStates: [Int: [String: ParkingLocationState]]) {
        var statesInput = [Int : [String: TJLabsJupiterVM.ParkingLocationState]]()
        
        for (levelId, data) in parkingLocationStates {
            var wrapped = [String: TJLabsJupiterVM.ParkingLocationState]()
            for (pId, pState) in data {
                wrapped[pId] = pState.toJupiterVM()
            }
            statesInput[levelId] = wrapped
        }
        self.vmView.updateParkingLocationStates(parkingLocationStates: statesInput)
    }
}
