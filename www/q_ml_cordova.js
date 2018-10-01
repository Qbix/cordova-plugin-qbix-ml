var exec = require('cordova/exec');

exports.ocr = function(image, isCloud, success, error) {
  exec(success, error, "QMLCordova", "ocr", [image,isCloud]);
};