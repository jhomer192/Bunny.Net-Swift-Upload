//
//  BunnyNet.swift
//  SurfWell
//
//  Jack Homer
//  While the documentation is helpful from Bunny.net, It didn't work super well for iOS so I decided to upload this to github for anyone else sturggling
//  The credit for the basis of the createVideo and uploadVideo come from the Bunny.net https://docs.bunny.net/reference/bunnynet-api-overview

import Foundation

let authKey = "" //enter your authKey for bunny.net here
let libraryID = "" //enter your library ID here
let uploadKey = "" //enter your uploadKey here
let storageZoneName = "" //enter your storageZoneName here

//I edited this from my code to make it more general. We got video data from this code snippet where we use PhotosPicker to pick a video from users camera roll (you need to add a warning in info.plst about using users video library)
// PhotosPicker("Select Video", selection: $selectedItem, matching: .videos)
//                             .onChange(of: selectedItem) { newItem in
//                                 Task {
//                                     if let data = try? await newItem?.loadTransferable(type: Data.self) {
//                                         selectedVideoData = data //THIS IS WHERE WE SET VIDEO DATA
//                                     }
//                                     guard (newItem?.supportedContentTypes.first) != nil else {
//                                         // guard let type = newItem?.supportedContentTypes.first else {
//                                         throw MyError.runtimeError("There is no supported type")
//                                     }
//                                     isVideo = 1 //flag to mark video is working
//                                 }
//                             }

//RETURNS VIDEOGUID WHICH IS IMPORTANT FOR STREAMING
func addVideo(title: String, collectionID: String, fileNameInBunnyStorage: String, videoData: Data)  -> String
{
    let videoGUID = createVideo(title: title, collectionID: collectionID)
    uploadVideo(guid: videoGUID, file: fileNameInBunnyStorage, videoData: videoData)
    return videoGUID
}
//  Semaphores are used here to ensure that we return a videoGUID before trying to upload. If this happened out of order this code would not work
func createVideo(title: String, collectionID: String)-> String {
    let headers = [
        "accept": "application/json",
        "content-type": "application/*+json",
        "AccessKey": authKey
    ]
    let postData = NSData(data: "{\"title\":\"\(title)\",\"collectionId\":\"\(collectionID)\",\"thumbnailTime\":0}".data(using: String.Encoding.utf8)!)
    let request = NSMutableURLRequest(url: NSURL(string: "https://video.bunnycdn.com/library/\(libraryID)/videos")! as URL,
                                      cachePolicy: .useProtocolCachePolicy,
                                      timeoutInterval: 10.0) 
    request.httpMethod = "POST"
    request.allHTTPHeaderFields = headers
    request.httpBody = postData as Data
    var output = ""
    let semaphore = DispatchSemaphore(value: 0)
    let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
        if let data = data, let dataString = String(data: data, encoding: .utf8) {
            let videoDict = convertStringToDictionary(text: dataString)!
            output = videoDict["guid"] as! String
            semaphore.signal()
        }
    }
    task.resume()
    semaphore.wait()
    return output
}


func uploadVideo(guid: String, file: String, videoData: Data) {
    let headers = [
      "accept": "application/json",
      "AccessKey": authKey
    ]
    var request = URLRequest(url: URL(string: "https://video.bunnycdn.com/library/\(libraryID)/videos/\(guid)")!)
    request.httpMethod = "PUT"
    request.allHTTPHeaderFields = headers
    let fileToUpload = videoData
    let uploadTask = URLSession.shared.uploadTask(with: request,  from: fileToUpload) {data, response, error in
        if (error != nil) {
            print(error as Any)
          } else {
            let httpResponse = response as? HTTPURLResponse
              print("\(httpResponse!)")
          }
    }
    uploadTask.resume()
    
   
   
}

func deleteVideo(guid: String) {
    let headers = [
      "accept": "application/json",
      "AccessKey": authKey
    ]
    
    let request = NSMutableURLRequest(url: NSURL(string: "https://video.bunnycdn.com/library/\(libraryID)/videos/\(guid)")! as URL,
                                            cachePolicy: .useProtocolCachePolicy,
                                        timeoutInterval: 10.0)
    request.httpMethod = "DELETE"
    request.allHTTPHeaderFields = headers
}

//pretty basic utility function, don't remember if I coded this or I got it from somewhere but its super helpful with http requests
public func convertStringToDictionary(text: String) -> [String:AnyObject]? {
   if let data = text.data(using: .utf8) {
       do {
           let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:AnyObject]
           return json
       } catch {
           print("Something went wrong")
       }
   }
   return nil
}


//heres how to play
// you need to import AVKit and import AVFoundation
//  VideoPlayer(player: AVPlayer(url: URL(string: ENTER_URL_TO_YOUR_VIDEO_HERE)!)) //ASSUMING YOU KNOW THAT THE VIDEO URL IS CORRECT
//Url should be YOUR_CDN_HOSTNAME/VIDEO_GUID_RETURNED_FROM_ADD_VIDEO/play_720p.mp4