
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
    
    public func isParkingLocationTapped(levelId: String, parkingLocationId: String) {
        delegate?.isParkingLocationTapped(levelId: levelId, parkingLocationId: parkingLocationId)
    }
    
    private var vmView = JupiterVMView()
    public weak var delegate: TJJupiterVMDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        // configureFrame 이 initialize 이전에 호출되어도 하위 뷰가 방출하는
        // onWebViewSuccess(false) 콜백이 래퍼(그리고 호스트)로 전달되도록,
        // 내부 뷰의 delegate 를 생성 시점에 연결해 둔다.
        self.vmView.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func initialize(userId: String, sectorId: Int, debugOption: Bool = true) {
        let dev = tjBranch == .DEV
        JupiterLogger.setDebugOption(set: false)
        JupiterVMLogger.setDebugOption(set: false)
        self.vmView.initialize(userId: userId, region: tjRegion.rawValue, sectorId: sectorId, debugOption: debugOption, dev: dev)
    }
    
    public func startService() {
        let suffix = tjBranch == .DEV ? "dev" : "prod"
        let appName = JupiterReplayer.shared.replayMode ? "ios_vm_replay" : "ios_vm_\(suffix)"
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
    
    private func initializeWebView() {
        self.vmView.initializeWebView()
    }

    private func attachView(to matchView: UIView) {
        self.vmView.configureFrame(to: matchView)
    }

    public func configureFrame(to matchView: UIView) {
        self.initializeWebView()
        self.attachView(to: matchView)
    }

    public func closeFrame() {
        self.vmView.closeFrame()
    }
    
    public func setSavedParkingLocations(parkingLocations: [String: [String]]) {
        self.vmView.setSavedParkingLocations(parkingLocations)
    }
    
    public func updateSavedParkingLocations(parkingLocations: [String: [String]]) {
        self.vmView.updateSavedParkingLocations(parkingLocations)
    }
    
    public func setParkingLocationStates(parkingLocationStates: [String: [String: ParkingLocationState]]) {
        var statesInput = [String : [String: TJLabsJupiterVM.ParkingLocationState]]()
        
        for (levelId, data) in parkingLocationStates {
            var wrapped = [String: TJLabsJupiterVM.ParkingLocationState]()
            for (pId, pState) in data {
                wrapped[pId] = pState.toJupiterVM()
            }
            statesInput[levelId] = wrapped
        }

        self.vmView.setParkingLocationStates(parkingLocationStates: statesInput)
    }

    public func updateParkingLocationStates(parkingLocationStates: [String: [String: ParkingLocationState]]) {
        var statesInput = [String : [String: TJLabsJupiterVM.ParkingLocationState]]()
        
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
