<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
    pageEncoding="ISO-8859-1"%>

<!DOCTYPE html>
<html>
    <head>
        <title>Screen Sharing</title>

        <script>
            if(!location.hash.replace('#', '').length) {
                location.href = location.href.split('#')[0] + '#' + (Math.random() * 100).toString().replace('.', '');
                location.reload();
            }
        </script>

       

        <link rel="stylesheet" href="/plugin/css/style.css">

        <style>
            video {
                -moz-transition: all 1s ease;
                -ms-transition: all 1s ease;

                -o-transition: all 1s ease;
                -webkit-transition: all 1s ease;
                transition: all 1s ease;
                vertical-align: top;
                width: 100%;
            }

            input {
                border: 1px solid #d9d9d9;
                border-radius: 1px;
                font-size: 2em;
                margin: .2em;
                width: 50%;
                margin-top:20px;
            }

            select {
                border: 1px solid #d9d9d9;
                border-radius: 1px;
                height: 50px;
                margin-left: 1em;
                margin-right: -12px;
                padding: 1.1em;
                vertical-align: 6px;
                width: 18%;
            }

            .setup {
                border-bottom-left-radius: 0;
                border-top-left-radius: 0;
                font-size: 102%;
                height: 47px;
                margin-left: 46px;
                margin-top: 21px;
                position: absolute;
            }

            p { padding: 1em; }

            li {
                border-bottom: 1px solid rgb(189, 189, 189);
                border-left: 1px solid rgb(189, 189, 189);
                padding: .5em;
            }
        </style>
      


        <!-- scripts used for screen-sharing -->
          <script src="/plugin/js/socket.io.js"> </script>
        <script src="/plugin/js/adapter-latest.js"></script>
        <script src="/plugin/js/iceserverhandler.js"></script>
        <script src="/plugin/js/getscreenid.js"> </script>
        <script src="/plugin/js/codeshandler.js"></script>
        <script src="/plugin/js/banwidhthandler.js"></script>
        <script src="/plugin/js/screen.js"> </script>
    </head>

    <body>
        <article>
            <header style="text-align: center;">
                <h1>
                    Screen Sharing
                </h1>
                            </header>



            <h2 id="number-of-participants" style="display: block;text-align: center;border:0;margin-bottom:0;">Its a full-HD (1080p) screen sharing application</h2>

            <!-- just copy this <section> and next script -->
            <section class="experiment">
                <section class="hide-after-join">
                 <table>
                 <tr>
                 <div>
                   
                   <td>
                 <div id="screenSharingDivision"> 
                   <input type="text" id="user-name" placeholder="Your Name">
                    <button id="share-screen" class="setup">Share Your Screen</button>
                </div>
                </td>
                   <td>
                   <span>
                        <a href="/screen-sharing/" target="_blank" ><code><strong id="unique-token"></strong></code></a>
                   </span>
                   </td>
                   </div>
                </tr>
                </table>
                </section>

                <!-- list of all available broadcasting rooms -->
                <table style="width: 100%;" id="rooms-list" class="hide-after-join"></table>

                <!-- local/remote videos container -->
                <div id="videos-container"></div>
            </section>

            <script>
              
                var videosContainer = document.getElementById("videos-container") || document.body;
                var roomsList = document.getElementById('rooms-list');

                var screensharing = new Screen();
                var usrType='${usrType}';
                console.log(usrType);
                if(usrType=='t'){
                    
                }else{
                	
                	document.getElementById('screenSharingDivision').style.display="none";
                }

                var channel = location.href.replace(/\?.*?#|[\/:#%.\[\]]/g, '');
                console.log(channel);
                var sender = Math.round(Math.random() * 999999999) + 999999999;

                var SIGNALING_SERVER = 'https://socketio-over-nodejs2.herokuapp.com:443/';
                io.connect(SIGNALING_SERVER).emit('new-channel', {
                    channel: channel,
                    sender: sender
                });

                var socket = io.connect(SIGNALING_SERVER + channel);
                socket.on('connect', function () {
                    // setup peer connection & pass socket object over the constructor!
                });

                socket.send = function (message) {
                    socket.emit('message', {
                        sender: sender,
                        data: message
                    });
                };

                screensharing.openSignalingChannel = function(callback) {
                    return socket.on('message', callback);
                };

                screensharing.onscreen = function(_screen) {
                    var alreadyExist = document.getElementById(_screen.userid);
                    if (alreadyExist) return;

                    if (typeof roomsList === 'undefined') roomsList = document.body;

                    var tr = document.createElement('tr');

                    tr.id = _screen.userid;
                    tr.innerHTML = '<td>' + _screen.userid + ' shared his screen.</td>' +
                            '<td><button class="join">View</button></td>';
                    roomsList.insertBefore(tr, roomsList.firstChild);

                    var button = tr.querySelector('.join');
                    button.setAttribute('data-userid', _screen.userid);
                    button.setAttribute('data-roomid', _screen.roomid);
                    button.onclick = function() {
                        var button = this;
                        button.disabled = true;

                        var _screen = {
                            userid: button.getAttribute('data-userid'),
                            roomid: button.getAttribute('data-roomid')
                        };
                        screensharing.view(_screen);
                    };
                };

                // on getting each new screen
                screensharing.onaddstream = function(media) {
                    media.video.id = media.userid;

                    var video = media.video;
                    videosContainer.insertBefore(video, videosContainer.firstChild);
                    rotateVideo(video);

                    var hideAfterJoin = document.querySelectorAll('.hide-after-join');
                    for(var i = 0; i < hideAfterJoin.length; i++) {
                        hideAfterJoin[i].style.display = 'none';
                    }

                    if(media.type === 'local') {
                        addStreamStopListener(media.stream, function() {
                            location.reload();
                        });
                    }
                };

                // using firebase for signaling
                // screen.firebase = 'signaling';

                // if someone leaves; just remove his screen
                screensharing.onuserleft = function(userid) {
                    var video = document.getElementById(userid);
                    if (video && video.parentNode) video.parentNode.removeChild(video);

                    // location.reload();
                };

                // check pre-shared screens
                screensharing.check();

                document.getElementById('share-screen').onclick = function() {
                    var username = document.getElementById('user-name');
                    username.disabled = this.disabled = true;

                    screensharing.isModerator = true;
                    screensharing.userid = username.value;

                    screensharing.share();
                };

                function rotateVideo(video) {
                    video.style[navigator.mozGetUserMedia ? 'transform' : '-webkit-transform'] = 'rotate(0deg)';
                    setTimeout(function() {
                        video.style[navigator.mozGetUserMedia ? 'transform' : '-webkit-transform'] = 'rotate(360deg)';
                    }, 1000);
                }

                (function() {
                    var uniqueToken = document.getElementById('unique-token');
                    if (uniqueToken)
                        if (location.hash.length > 2) uniqueToken.parentNode.parentNode.parentNode.innerHTML = '<h6 style="text-align:right;margin-top:20px;margin-right: 20px;"><button style="width:150%;"><a style="color:white" href="' + location.href + '" target="_blank">Share Screen URL</a></button></h6>';
                        else uniqueToken.innerHTML = uniqueToken.parentNode.parentNode.href = '#' + (Math.random() * new Date().getTime()).toString(36).toUpperCase().replace( /\./g , '-');
                })();

                screensharing.onNumberOfParticipantsChnaged = function(numberOfParticipants) {
                    if(!screensharing.isModerator) return;

                    document.title = numberOfParticipants + ' users are viewing your screen!';
                    var element = document.getElementById('number-of-participants');
                    if (element) {
                        element.innerHTML = numberOfParticipants + ' users are viewing your screen!';
                    }
                };
            </script>

            <script>
                // todo: need to check exact chrome browser because opera also uses chromium framework
                var isChrome = !!navigator.webkitGetUserMedia;

               
                var DetectRTC = {};

                (function () {

                    var screenCallback;

                    DetectRTC.screen = {
                        chromeMediaSource: 'screen',
                        getSourceId: function(callback) {
                            if(!callback) throw '"callback" parameter is mandatory.';
                            screenCallback = callback;
                            window.postMessage('get-sourceId', '*');
                        },
                        isChromeExtensionAvailable: function(callback) {
                            if(!callback) return;

                            if(DetectRTC.screen.chromeMediaSource == 'desktop') return callback(true);

                            // ask extension if it is available
                            window.postMessage('are-you-there', '*');

                            setTimeout(function() {
                                if(DetectRTC.screen.chromeMediaSource == 'screen') {
                                    callback(false);
                                }
                                else callback(true);
                            }, 2000);
                        },
                        onMessageCallback: function(data) {
                            if (!(typeof data == 'string' || !!data.sourceId)) return;

                            console.log('chrome message', data);

                            // "cancel" button is clicked
                            if(data == 'PermissionDeniedError') {
                                DetectRTC.screen.chromeMediaSource = 'PermissionDeniedError';
                                if(screenCallback) return screenCallback('PermissionDeniedError');
                                else throw new Error('PermissionDeniedError');
                            }

                            

                            // extension shared temp sourceId
                            if(data.sourceId) {
                                DetectRTC.screen.sourceId = data.sourceId;
                                if(screenCallback) screenCallback( DetectRTC.screen.sourceId );
                            }
                        },
                        getChromeExtensionStatus: function (callback) {
                            if (!!navigator.mozGetUserMedia) return callback('not-chrome');

                            var extensionid = 'ajhifddimkapgcifgcodmmfdlknahffk';

                            var image = document.createElement('img');
                            image.src = 'chrome-extension://' + extensionid + '/icon.png';
                            image.onload = function () {
                                DetectRTC.screen.chromeMediaSource = 'screen';
                                window.postMessage('are-you-there', '*');
                                setTimeout(function () {
                                    if (!DetectRTC.screen.notInstalled) {
                                        callback('installed-enabled');
                                    }
                                }, 2000);
                            };
                            image.onerror = function () {
                                DetectRTC.screen.notInstalled = true;
                                callback('not-installed');
                            };
                        }
                    };

                    // check if desktop-capture extension installed.
                    if(window.postMessage && isChrome) {
                        DetectRTC.screen.isChromeExtensionAvailable();
                    }
                })();

                 window.addEventListener('message', function (event) {
                    if (event.origin != window.location.origin) {
                        return;
                    }

                    DetectRTC.screen.onMessageCallback(event.data);
                });

                console.log('current chromeMediaSource', DetectRTC.screen.chromeMediaSource);
            </script>
                    </article>
    </body>
</html>