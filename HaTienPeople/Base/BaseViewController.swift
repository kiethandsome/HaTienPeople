//
//  BaseViewController.swift
//  Garage-admin
//
//  Created by LOU on 4/21/20.
//  Copyright © 2020 LOU. All rights reserved.
//

import Foundation
import UIKit
import SVProgressHUD
import Alamofire
import AlamofireSwiftyJSON
import SwiftyJSON
import CoreLocation
import AppCenter
import AppCenterCrashes

struct MyLocation {
    static var long = Double() {
        didSet {
            print("Long: \(long)")
        }
    }
    
    static var lat = Double() {
        didSet {
            print("Lat: \(lat)")
        }
    }
}

class BaseViewController: UIViewController {
    
    var locationManager = CLLocationManager()
    var location: CLLocation!{
        didSet {
            MyLocation.lat = location.coordinate.latitude
            MyLocation.long = location.coordinate.longitude
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //MARK: Back Button
    func showBackButton() {
        let backButton = UIBarButtonItem(image: #imageLiteral(resourceName: "back-button2").withRenderingMode(.alwaysTemplate) , style: .plain, target: self, action: #selector(popToBack))
        navigationItem.leftBarButtonItem = backButton
    }
    @objc func popToBack() {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: Dimiss Button
    func showDismissButton(title: String) {
        let dismissButton = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(dissmissButtonTapped(_:)))
        navigationItem.leftBarButtonItem = dismissButton
    }
    @objc func dissmissButtonTapped(_ button: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: Right Bar button with Image
    func showRightBarButtonWithImage(image: String, action: Selector?, isEnable: Bool = false) {
        let barButton = UIBarButtonItem(image: UIImage(named: image)!.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: action)
        navigationItem.rightBarButtonItem = barButton
        barButton.isEnabled = isEnable
    }
    
    // MARK:  Show/Hide HUD
    func showHUD() {
        DispatchQueue.main.async {
            SVProgressHUD.show()
            self.view.isUserInteractionEnabled = false
        }
    }
    func hideHUD() {
        DispatchQueue.main.async {
            SVProgressHUD.dismiss()
            self.view.isUserInteractionEnabled = true
        }
    }
    
    // MARK: Show alert with error Message
    public func showAlert(errorMessage: String) {
        let alert = UIAlertController(title: "Lỗi", message: errorMessage, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Show Alert
    open func showAlert(title: String, message: String, style: UIAlertController.Style, hasTwoButton: Bool = false, okAction: @escaping (_ action: UIAlertAction) -> Void ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: style)
        let ok = UIAlertAction(title: "Ok", style: .default, handler: okAction)
        alert.addAction(ok)
        if hasTwoButton {
            let cancelAction = UIAlertAction(title: "Huỷ", style: .cancel, handler: nil)
            alert.addAction(cancelAction)
        }
        present(alert, animated: true)
    }
    
    // MARK: Simple alert
    public func showSimpleAlert(message: String, title: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    // response Swifty json with token
    func requestAPIwith(urlString: String, method: HTTPMethod, params: Parameters? = nil, completion: @escaping (_ response: DataResponse<JSON>) -> Void ) {
        let url = URL(string: urlString)!
        guard let token = UserDefaults.standard.value(forKey: "Token") as? String else { return }
        let tokenHeader = ["Authorization" : "Bearer \(token)"]
        self.showHUD()
        Alamofire.request(url, method: method, parameters: params, encoding: JSONEncoding.default, headers: tokenHeader).responseSwiftyJSON { [weak self] (response) in
            guard let wSelf = self else { return }
            wSelf.hideHUD()
            guard let code = response.response?.statusCode else { return }
            print(code)
            if code == 200 {
                completion(response)
            } else {
                wSelf.showAlert(errorMessage: response.error.debugDescription)
            }
        }
    }
    
    
    // Response String
    func requestApiResponseString(urlString: String, method: HTTPMethod, params: Parameters? = nil, encoding: ParameterEncoding, headers: HTTPHeaders? = nil,  completion: @escaping (_ response: DataResponse<String>) -> Void ) {
        guard let token = Account.current?.access_token else { return }
        let tokenHeader = ["Authorization" : "Bearer \(token)"]
        let url = URL(string: urlString)!
        self.showHUD()
        Alamofire.request(url, method: method, parameters: params, encoding: encoding, headers: tokenHeader).responseString { (responseString) in
            self.hideHUD()
            guard let statusCode = responseString.response?.statusCode else { return }
//            print(responseString)
            print(statusCode)
            if responseString.result.isSuccess {
                if 200..<300 ~= statusCode {
                    completion(responseString)
                }
            } else {
                self.showAlert(errorMessage: responseString.error.debugDescription)
            }
        }
    }
    
    // Response JSON
    func requestApiResponseJson(urlString: String, method: HTTPMethod, params: Parameters? = nil, encoding: ParameterEncoding, completion: @escaping (_ response: DataResponse<JSON>) -> Void ) {
        guard let token = UserDefaults.standard.value(forKey: "Token") as? String else { return }
        let tokenHeader = ["Authorization" : "Bearer \(token)"]
        let url = URL(string: urlString)!
        self.showHUD()
        Alamofire.request(url, method: method, parameters: params, encoding: encoding, headers: tokenHeader).responseSwiftyJSON { (responseSwiftyJson) in
            self.hideHUD()
            guard let statusCode = responseSwiftyJson.response?.statusCode else { return }
            print("Status code: \(statusCode)")
            if 200..<300 ~= statusCode {
                completion(responseSwiftyJson)
            } else {
                self.showAlert(errorMessage: responseSwiftyJson.error.debugDescription)
            }
        }
    }
    
    // Response model
    func requestApiResponseModel(urlString: String, method: HTTPMethod, params: Parameters? = nil, encoding: ParameterEncoding, completion: @escaping (_ response: DataResponse<JSON>) -> Void ) {
        
    }
    
    // Response T class
    func requestModel<T: Codable>(with urlString: String, method: HTTPMethod, params: Parameters?, encoding: ParameterEncoding, completion: @escaping (_ response: T) -> Void) {
        guard let token = UserDefaults.standard.value(forKey: "Token") as? String else { return }
        let tokenHeader = ["Authorization" : "Bearer \(token)"]
        let url = URL(string: urlString)!
        self.showHUD()
        Alamofire.request(url, method: method, parameters: params, encoding: encoding, headers: tokenHeader).responseString { (response) in
            guard let jsonString: String = response.value else { return }
            guard let data = jsonString.data(using: .utf8) else { return }
            do {
                let responseModel = try JSONDecoder().decode(T.self, from: data)
                completion(responseModel)
            } catch let DecodingError.dataCorrupted(context) {
                print(context)
            } catch let DecodingError.keyNotFound(key, context) {
                print("Key '\(key)' not found:", context.debugDescription)
                print("codingPath:", context.codingPath)
            } catch let DecodingError.valueNotFound(value, context) {
                print("Value '\(value)' not found:", context.debugDescription)
                print("codingPath:", context.codingPath)
            } catch let DecodingError.typeMismatch(type, context)  {
                print("Type '\(type)' mismatch:", context.debugDescription)
                print("codingPath:", context.codingPath)
            } catch {
                print("error: ", error)
            }
        }
    }
    
    
    // MARK: - request api response Data
    
}

// MARK: - Request Body
extension String: ParameterEncoding {
    
    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var request = try urlRequest.asURLRequest()
        request.httpBody = data(using: .utf8, allowLossyConversion: false)
        return request
    }
}


extension BaseViewController {
    // Response Non-token
    func requestNonTokenResponseString(urlString: String, method: HTTPMethod, params: Parameters? = nil, encoding: ParameterEncoding, headers: HTTPHeaders? = nil,  completion: @escaping (_ response: DataResponse<String>) -> Void ) {
        guard let url = URL(string: urlString) else { return }
//        self.showHUD()
        Alamofire.request(url, method: method, parameters: params, encoding: encoding).responseString { (responseString) in
//            self.hideHUD()
            guard let statusCode = responseString.response?.statusCode else { return }
            print(responseString)
            print(statusCode)
            if responseString.result.isSuccess {
                if 200..<300 ~= statusCode {
                    completion(responseString)
                }
            } else {
                self.showAlert(errorMessage: responseString.error.debugDescription)
            }
        }
    }
    
}

// MARK: - Location Manager
extension BaseViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = (locations ).last
//        locationManager.stopUpdatingLocation()
    }
    
    func checkCoreLocationPermission(){
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse{
            self.locationManager.startUpdatingLocation()
        }
        else if CLLocationManager.authorizationStatus() == .notDetermined{
            self.locationManager.requestWhenInUseAuthorization()
        }
        else if CLLocationManager.authorizationStatus() == .restricted{
            print("unauthorized")
        }
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        default:
            return
        }
    }

    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
    }
}
