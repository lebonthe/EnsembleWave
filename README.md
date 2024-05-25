<img src="https://raw.githubusercontent.com/lebonthe/EnsembleWave/main/EnsembleWave/Assets.xcassets/FullLogo_Transparent_NoBuffer.imageset/FullLogo_Transparent_NoBuffer.png" width="150">

# EnsembleWave

EnsembleWave allows you to easily create videos with dual-screen merging and publish them to a dynamic wall, allowing all users to participate in a joint performance.

## Description

EnsembleWave Has The Following Functions:

### Recording Configuration

After selecting a template and recording duration, you can start recording videos for each shot individually. You can switch between front and back cameras, use a countdown timer, or start recording with a gesture.

### Import Videos or Reference Music

In addition to live recording, you can also use videos from your album. If needed, you can select music from your files to listen to while recording. 

### Trim and Merge

After recording, you can trim the video length and merge it with the video on the other side.

### Post to What's New

Once the video is complete, you can choose to save it to your photo album or upload it to the dynamic wall.

### What's New

Showcase all users' creations. If you want to join the performance, you can click Co-Play to participate in the creation. You can like and comment on posts, and if you encounter any issues, you can report problems or block accounts.

## Getting started

Since the required API key to run the app is not included here, you won't be able to build this project directly. If needed, please refer to the contact information at the bottom.

## Technical Features
- Extensively use AVFoundation and AVKit for multi-screen synchronized recording/playback and video merging, incorporating GCD and Observer patterns.
- Develope a gesture-controlled recording start feature using Vision framework.
- Implemente real-time dynamic updates with Firebase.
- Use FileManager to access and save music & videos.
- Use Firebase Crashlytics to receive user crash reports.

## Libraries & Dependencies
- FirebaseAuth
- FirebaseFirestore
- FirebaseCrashlytics
- SwiftLint
- IQKeyboardManagerSwift
- Kingfisher
- Lottie for iOS
- SwiftEntryKit
- VideoConverter
- MJRefresh

## Requirement

Xcode 13.3 or higher version
iOS 15.4 or higher version

## Contact
Min Hu
lebonthe@gmail.com
