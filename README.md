# Cordova plugin for ML

## Supported Platforms

- __Android__
- __iOS__


## Installation

The plugin can be installed via [Cordova-CLI][CLI].

Or install the latest head version:

    $ cordova plugin add https://github.com/Qbix/cordova-plugin-qbix-ml.git

### Setup
Download your Firebase configuration files, GoogleService-Info.plist for iOS and google-services.json for android, and place them in the root folder of your cordova project.

```
- My Project/
    platforms/
    plugins/
    www/
    config.xml
    google-services.json       <--
    GoogleService-Info.plist   <--
    ...
```

## Usage

The plugin creates the object `Q.ML.Cordova` and is accessible after the *deviceready* event has been fired.

```javascript
Q.ML.Cordova.ocr(
    image,          String, // image in base64 or path to image on device started with 'file://'
    isCloud,        Boolean, // false -> do ocr offline, true -> do ocr in Google MLKit
    callback, 		
    errorCallback
);
```