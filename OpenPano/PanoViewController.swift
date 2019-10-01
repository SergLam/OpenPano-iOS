//
//  PanoViewController.swift
//  OpenPano
//
//  Created by GitZChen on 7/3/16.
//  Copyright © 2019 GitZChen. All rights reserved.
//

import UIKit
import Photos
import Dispatch
import libopano

class PanoViewController: UIViewController {
    
    var pano : UIImage? = nil
    @IBOutlet var imageView: UIImageView!
    
    let stitchingQueue = DispatchQueue.global(qos: .userInitiated)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
//        selectAndStitch()
        stitchTestImages()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func selectAndStitch() {
        let welcomeAlertVC = UIAlertController(title: "Welcome!", message: "Please select the images to be stitched.", preferredStyle: .alert)
        welcomeAlertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            let pickerVC = UIAlertController(style: .actionSheet)
            pickerVC.addPhotoLibraryPicker(flow: .vertical, paging: true, selection: .multiple(action: { (assets) in
                if assets.count < 2 {
                    let fewImageAlertVC = UIAlertController(title: "Too few images!", message: "Please select at least 2 images!", preferredStyle: .alert)
                    fewImageAlertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                        self.selectAndStitch()
                    }))
                    self.present(fewImageAlertVC, animated: true, completion: nil)
                    return
                }
                
                var imagePaths : [String] = []
                for asset in assets {
                    asset.requestContentEditingInput(with: PHContentEditingInputRequestOptions(), completionHandler: { (input, _) in
                        if input != nil && input?.fullSizeImageURL != nil {
                            if imagePaths.count == 0 {
                                PHImageManager.default().requestImage(for: asset, targetSize: self.view.frame.size, contentMode: .default, options: .init(), resultHandler: { (image, _) in
                                    self.imageView.image = image
                                })
                            }
                            imagePaths.append(input!.fullSizeImageURL!.absoluteString.replacingOccurrences(of: "file://", with: ""))
                        }
                    })
                }
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { (timer) in
                    if assets.count == imagePaths.count {
                        timer.invalidate()
                        if imagePaths.count < 2 {
                            return
                        }
                        self.stitchingQueue.async {
                            let image = StitchingWrapper.stitchImages(ofPaths: imagePaths)?.rotate(byDegrees: 90)
                            self.pano = image
                            if self.pano != nil {
                                DispatchQueue.main.async {
                                    self.imageView.image = self.pano
                                }
                            }
                        }
                    }
                })
                
            }))
            self.present(pickerVC, animated: true, completion: nil)
        }))
        
        self.present(welcomeAlertVC, animated: true, completion: nil)
    }
    
    private func stitchTestImages() {
        
        var imageNames: [String] = []
        imageNames.append("bottom-0")
        imageNames.append("bottom-1")
        
        imageNames.append("bottom-2")
        imageNames.append("bottom-3")
        
//        for i in (4...21).reversed() {
//            // down - 0...5 6...10 12...21
//            // Failed to stitch - 10...12
//            // error: Failed to find hfactor
//
//            // up 0...2 4...21
//            // Failed to stitch - 2...5
//            // error: Failed to find hfactor
//            imageNames.append("up-\(i)")
//        }
        let imagePaths : [String] = imageNames.compactMap{ return getFilePathByName(name: $0) }
        
        self.stitchingQueue.async {
            let image = StitchingWrapper.stitchImages(ofPaths: imagePaths)//?.rotate(byDegrees: 90)
            self.pano = image
            if self.pano != nil {
                DispatchQueue.main.async {
                    self.imageView.image = self.pano
                }
            }
        }
    }
    
    private func getFilePathByName(name: String) -> String? {
        
        guard let path = Bundle.main.path(forResource: name, ofType: "jpg") else {
            assertionFailure("Unable to found specified file")
            return nil
        }
        return path.replacingOccurrences(of: "file://", with: "")
    }
    
}

