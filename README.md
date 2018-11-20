scr-timelapse
=============

Timelapse tool using Sony's Camera Remote API

Currently *under development*.
Default fixed value of 10 fps still shooting, but you can experiment by changing the constant `INTERVAL` in `app.rb` to a positive integer of your choice. 

Photos will be saved on camera, no automatic transfers to your computer!

You have to combine all photos by yourself, i.e. with 'Time Lapse Assembler' on a Mac.

## Requirements

* Ruby 2.4.3 or higher
* Wifi connection

## Instructions

1. Manually connect your Wifi connection to your camera.
2. Open Terminal/bash
3. cd to Project directory
4. Run `ruby app.rb`

## Supported Cameras

Have a look at: https://developer.sony.com/develop/cameras/device-support/

## Thanks to

* https://github.com/dbussink/jsonrpc
* https://github.com/turboladen/playful
