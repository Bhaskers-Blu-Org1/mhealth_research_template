// Copyright © 2018 IBM.


import Foundation
import Security
import PDFKit
import Alamofire
import SwiftyRSA


// This section should be cleaned up and streamlined in future releases.
// To communicate with a REST api, we use both Swift/iOS native API calls (for sending study data) and Alamofire (for sending the PDF consent document)

let api_url : String = "API without SSL can go here"
let s_api_url : String = "API using SSL goes here" // Generally, you need to use encrypted connections in iOS applications

func encrypt(str_to_encrypt: String) -> String {
    var base64String = ""
    do {
        let pubKey = try PublicKey(pemNamed: "StudyLeadsPublicKey")
        let clrMessage = try ClearMessage(string: str_to_encrypt, using: .utf8)
        let encrypted = try clrMessage.encrypted(with: pubKey, padding: .OAEP)
        let data = encrypted.data
        base64String = encrypted.base64String

    } catch  {
        print("this error happened when encrypting a string: \(error)")
    }
    return base64String
}

func uploadConsent(id: String, pw: String,onCompletion: @escaping (String) -> Void, onError: @escaping (NSError) -> Void) {
    var returnvalue = " "
    let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
    let turl = NSURL(fileURLWithPath: path)
    let pathC = turl.appendingPathComponent(studyID + ".pdf")
    var p  = ""
    var td = Data() //Placeholder for data file
    var url = URL(string: s_api_url + "uploadConsentFile") // endpoint to upload consent PDF
    // Let's find the path and double check the file exists...
    if let pathComponent = pathC {
        let filePath = pathComponent.path
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: filePath) {
            p = filePath
            if let consentData = fileManager.contents(atPath: filePath){
                td = consentData
            }
        } else {
            let message = "Error thrown: No file here."
            print(message)
            onCompletion(message)
        }
    } else {
        print("ERROR: FILE PATH NOT AVAILABLE")
        onCompletion("ERROR: FILE PATH NOT AVAILABLE")
    }
    
    let data2 = try? NSData(contentsOfFile: p) as Data
    guard let uploadDatap = data2 else {
        onCompletion(" ")
        return
    }
    let user = "admin"
    let password = "admin"
    let credentialData = "\(user):\(password)".data(using: String.Encoding.utf8)!
    let base64Credentials = credentialData.base64EncodedString(options: [])
    let headers = ["Authorization": "Basic \(base64Credentials)"]
    let t = SessionManager()
    t.upload(multipartFormData: { (form) in
        form.append(uploadDatap, withName: "file", fileName: studyID + ".pdf", mimeType: "application/pdf")
    }, to: url!,headers:headers, encodingCompletion: { result in
        
        switch result {
        case .success(let upload, _, _):
            upload.responseString { response in
                returnvalue = String(describing: response.value)
                onCompletion(returnvalue)
            }
        case .failure(let encodingError):
            print("https error : \(encodingError)")
            
            returnvalue = (encodingError.localizedDescription)
            onCompletion(returnvalue)
        }
        
    })
    
}

var tracker = [[String : String]]()

func callAPIc(type: String, id: String, pw: String, params: [[String: String]], onCompletion: @escaping ([String]) -> Void, onError: @escaping (NSError) -> Void) {
    // Convert params to JSON
    var jsonParams = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
    if type == "ID" || type == "SelectedThing" || type == "Baseline" || type == "Profile" {
        jsonParams = try? JSONSerialization.data(withJSONObject: params[0], options: .prettyPrinted)
    }
    
    // Create login basic-auth string and use base64 encoding in request
    let loginString = String(format: "%@:%@", id, pw)
    let loginData = loginString.data(using: String.Encoding.utf8)!
    let base64LoginString = loginData.base64EncodedString()
    
    //Create URL
    var url = URL(string: s_api_url + "newUser") //newUSer by default, we'll change that below depending on type.
    
    //change URL endpoint depending on type.
    switch type {
    case "ID":
        url = URL(string: s_api_url + "newUser")
    case "Profile":
        url = URL(string: api_url + "createProfile")
    case "SelectedThing":
        url = URL(string: api_url + "createSelectedThing")
    case "Location":
        url = URL(string: api_url + "updateLocation")
    case "Baseline":
        url = URL(string: api_url + "updateBaseline")
    case "Notification":
        url = URL(string: api_url + "updateNotificationFeedback")
    case "HK":
        url = URL(string: api_url + "updateHkData")
    case "Calendar":
        url = URL(string: api_url + "updateCalendarInfo")
    case "CMActivity":
        url = URL(string: api_url + "updateCMActivityData")
    case "CMSteps":
        url = URL(string: api_url + "updateCMStepData")
    default:
        url = URL(string: api_url + "xx") // Needs to be in each case!
    }
    
    //Create a new request
    var request = URLRequest(url: url!)
    var resp = 0 // Response code from API
    let responseCode = 0
    request.httpMethod = "POST" // Requests are all of type POST
    request.httpBody = jsonParams // Add params to request
    request.setValue("Basic " + base64LoginString, forHTTPHeaderField: "Authorization") // Add basic-auth to header
    request.setValue("application/json", forHTTPHeaderField: "Content-Type") // Set types in header
    request.setValue("application/json", forHTTPHeaderField: "Accept") // Set types in header
    let task = URLSession.shared.dataTask(with:request, completionHandler: {(data: Data?, response: URLResponse?, error: Error?) in
        print("Debug Response in the async: \(String(describing: response))")
        
        let status = (response as! HTTPURLResponse).statusCode
        let res = response as! HTTPURLResponse
       
        guard let data = data, error == nil else { return }
        do { // Will do only if JSON response
                let status = (response as! HTTPURLResponse).statusCode
                resp = status
            
                switch type {
                case "ID": // Only ID endpoint returns JSON responses, so this is the only case
                    
                    if status == 200 {
                        let respJSON = try JSONSerialization.jsonObject(with: data, options:[ .allowFragments])
                         if let respJSON = respJSON as? [String: Any] {

                        //Store respones
                        if let sID = respJSON["studyID"] as? Int {
                            studyID = "\(sID)" // Store StudyID
                        }
                        if let g = respJSON["groupType"]  as? String {
                            group =  "Treatment1" // TEST ONLY. SHOULD BE g here
                        }
                        if let sK = respJSON["secure_key"]  as? String {
                            sKey = sK // Store study key
                        }
                        }
                        syncDate[type] = Date() 
                        onCompletion([type, studyID])

                    } else {
                        print(" response: \(status) ERROR")
 
                    }
                default:
                    ()
                }
            //}
        } catch let error as NSError {
            print("ERROR: \(error)")
            if responseCode != 200 { //Some error occured.
                resp = 0000 // error response
            }
        }
        print("***RESP \(resp)")
        let codeS = String(describing: status)
        onCompletion([type, codeS])
   
    })
    task.resume()
    
}

func callConsentAPI(id: String, pw: String, onCompletion: @escaping (String) -> Void, onError: @escaping (NSError) -> Void) {
    var returnvalue = " "
    let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
    let turl = NSURL(fileURLWithPath: path)
    let pathC = turl.appendingPathComponent(studyID + ".pdf")
    var p  = ""
    var td = Data() //Placehodler for data file
    var url = URL(string: s_api_url + "uploadConsentFile") // endpoint to upload consent PDF
    // Let's find the path and double check the file exists...
    if let pathComponent = pathC {
        let filePath = pathComponent.path
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: filePath) {
            
            print ("\(filePath)")
            p = filePath
            if let consentData = fileManager.contents(atPath: filePath){
                td = consentData
            }

        } else {
            onCompletion("FILE PATH NOT AVAILABLE")
        }
    } else {
        print("FILE PATH NOT AVAILABLE")
        onCompletion("FILE PATH NOT AVAILABLE")
    }
    
    let data2 = try? NSData(contentsOfFile: p) as Data
    guard let uploadDatap = data2 else {
        onCompletion(" ")
        return
    }
    let user = "test_user"
    let password = "test_pw"
    let credentialData = "\(user):\(password)".data(using: String.Encoding.utf8)!
    let base64Credentials = credentialData.base64EncodedString(options: [])
    let headers = ["Authorization": "Basic \(base64Credentials)"]
    
    
    Alamofire.upload(multipartFormData: { (form) in
        form.append(uploadDatap, withName: "file", fileName: studyID + ".pdf", mimeType: "application/pdf")
    }, to: url!,headers:headers, encodingCompletion: { result in
        
        switch result {
        case .success(let upload, _, _):
            upload.responseString { response in
                print(response.value)
                returnvalue = String(describing: response.value)
                onCompletion(returnvalue)
            }
        case .failure(let encodingError):
            print(encodingError)
            returnvalue = (encodingError.localizedDescription)
            onCompletion(returnvalue)
        }
    })
}
