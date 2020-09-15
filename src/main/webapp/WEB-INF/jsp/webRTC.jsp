<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
    pageEncoding="ISO-8859-1"%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Video Conferencing</title>

        <script>
            if(!location.hash.replace('#', '').length) {
console.log(location.href);
                location.href = location.href.split('#')[0] + '#' + (Math.random() * 100).toString().replace('.', '');
                location.reload();

                }
        </script>

        <meta charset="utf-8">

       
        <link rel="stylesheet" href="/plugin/css/style.css">

        <style>
            audio, video {
                -moz-transition: all 1s ease;
                -ms-transition: all 1s ease;

                -o-transition: all 1s ease;
                -webkit-transition: all 1s ease;
                transition: all 1s ease;
                vertical-align: top;
            }

            input {
                border: 1px solid #d9d9d9;
                border-radius: 1px;
                font-size: 2em;
                margin: .2em;
                width: 30%;
            }

            .setup {
                border-bottom-left-radius: 0;
                border-top-left-radius: 0;
                font-size: 102%;
                height: 47px;
                margin-left: 9px;
                margin-top: 30px;
                position: absolute;
            }
			.shareConferance{
			border-bottom-left-radius:0;
			border-top-left-radius:0;
			font-size:80%;
			height:50px;
			margin-left: -9px;
                position: absolute;
			
			}
			::placeholder {
  color: blue;
  font-size: 0.8em;
}
            p { padding: 1em; }

            li {
                border-bottom: 1px solid rgb(189, 189, 189);
                border-left: 1px solid rgb(189, 189, 189);
                padding: .5em;
            }
        </style>
        
        <!-- script used to stylize video element -->
        <script src="/plugin/js/getmediaelement.min.js"> </script>

        <script src="/plugin/js/socket.io.js"> </script>
        <script src="/plugin/js/adapter-latest.js"></script>
        <script src="/plugin/js/iceserverhandler.js"></script>
        <script src="/plugin/js/codeshandler.js"></script>
        <script src="/plugin/js/rtcpeerconnection.js"> </script>
        <script src="/plugin/js/main.js"> </script>
    </head>

    <body>
        <article>
            <header style="text-align: center;">
			<div style="margin:0 auto;text-align:center">
				<input type="text" id="meetingAddress" style="width: 50%;margin-top:30px;" readonly>
			</div>
               
            </header>

            <section class="experiment">
              <table>
                    <tr >    
				<div >
                    
                     
                       <td> 
                       <div id="newConferance">
                    <input type="text" id="conference-name" placeholder="Conference Name" style="width: 50%;margin-top:30px;">
                    <button id="setup-new-room" class="setup">New Conference</button>

                </div>
              </td>
              
              <td>
               <span >
     				
                        <button target="_blank" title="private!">
                        <code>
                        <button id="unique-token"></button>
                        </code>
                        </button>
                       
                    </span>
                    </div>
                    </td>
                    </tr>
                   </table>
            
               
                </section>
			<section>
                <!-- list of all available conferencing rooms -->
                <table style="width: 100%;" id="rooms-list"></table>

                <!-- local/remote videos container -->
                <div id="videos-container"></div>
            </section>

            <script>

                var config = {
                    openSocket: function(config) {
                        var SIGNALING_SERVER = 'https://socketio-over-nodejs2.herokuapp.com:443/';
                        						
					console.log(location.href);
					var loc=location.href.split('#');
					var meetingaddress=document.getElementById("meetingAddress");
					meetingaddress.value=loc[1];
					console.log(loc[1]);
                       config.channel = config.channel || location.href.replace(/\?.*?#|[\/:#%.\[\]]/g,'');
                        var sender = Math.round(Math.random() * 999999999) + 999999999;
                        io.connect(SIGNALING_SERVER).emit('new-channel', {
                            channel: config.channel,
                            sender: sender
                        });

                        var socket = io.connect(SIGNALING_SERVER + config.channel);
                        socket.channel = config.channel;
                        socket.on('connect', function () {
                            if (config.callback) config.callback(socket);
                        });

                        socket.send = function (message) {
                           // console.log(message);
                            socket.emit('message', {
                                sender: sender,
                                data: message
                            });
                        };

                        socket.on('message', config.onmessage);
                    },
                    onRemoteStream: function(media) {
                        var mediaElement = getMediaElement(media.video, {
                            width: (videosContainer.clientWidth / 2) - 50,
                            buttons: ['mute-audio', 'mute-video', 'full-screen', 'volume-slider']
                        });
                        mediaElement.id = media.stream.streamid;
                        videosContainer.appendChild(mediaElement);
                    },
                    onRemoteStreamEnded: function(stream, video) {
                        if (video.parentNode && video.parentNode.parentNode && video.parentNode.parentNode.parentNode) {
                            video.parentNode.parentNode.parentNode.removeChild(video.parentNode.parentNode);
                        }
                    },
                    onRoomFound: function(room) {
                        var alreadyExist = document.querySelector('button[data-broadcaster="' + room.broadcaster + '"]');
                        if (alreadyExist) return;

                        if (typeof roomsList === 'undefined') roomsList = document.body;

                        var tr = document.createElement('tr');
                        tr.innerHTML = '<td><strong>' + room.roomName + '</strong> shared a conferencing room with you!</td>' +
                            '<td><button class="join">Join</button></td>';
                         
                        roomsList.appendChild(tr);

                        var joinRoomButton = tr.querySelector('.join');
                        joinRoomButton.setAttribute('data-broadcaster', room.broadcaster);
                        joinRoomButton.setAttribute('data-roomToken', room.roomToken);
                        joinRoomButton.onclick = function() {
                            this.disabled = true;

                            var broadcaster = this.getAttribute('data-broadcaster');
                            var roomToken = this.getAttribute('data-roomToken');
                            captureUserMedia(function() {
                                conferenceUI.joinRoom({
                                    roomToken: roomToken,
                                    joinUser: broadcaster
                                });
                            }, function() {
                                joinRoomButton.disabled = false;
                            });
                        };
                    },
                    onRoomClosed: function(room) {
                        var joinButton = document.querySelector('button[data-roomToken="' + room.roomToken + '"]');
                        if (joinButton) {
                            // joinButton.parentNode === <li>
                            // joinButton.parentNode.parentNode === <td>
                            // joinButton.parentNode.parentNode.parentNode === <tr>
                            // joinButton.parentNode.parentNode.parentNode.parentNode === <table>
                            joinButton.parentNode.parentNode.parentNode.parentNode.removeChild(joinButton.parentNode.parentNode.parentNode);
                        }
                    },
                    onReady: function() {
                        console.log('now you can open or join rooms');
                    }
                };

                function setupNewRoomButtonClickHandler() {
                    btnSetupNewRoom.disabled = true;
                    document.getElementById('conference-name').disabled = true;
                    captureUserMedia(function() {
                        conferenceUI.createRoom({
                            roomName: (document.getElementById('conference-name') || { }).value || 'Anonymous'
                        });
                    }, function() {
                        btnSetupNewRoom.disabled = document.getElementById('conference-name').disabled = false;
                    });
                }

                function captureUserMedia(callback, failure_callback) {
                    var video = document.createElement('video');
                    video.muted = true;
                    video.volume = 0;
                    //video.stream=false;
                   // connection.streamEvents.selectFirst({local: true}).stream.mute();

                    try {
                        video.setAttributeNode(document.createAttribute('autoplay'));
                        video.setAttributeNode(document.createAttribute('playsinline'));
                        video.setAttributeNode(document.createAttribute('controls'));
                    } catch (e) {
                        video.setAttribute('autoplay', true);
                        video.setAttribute('playsinline', true);
                        video.setAttribute('controls', true);
                        
                    }

                    getUserMedia({
                        video: video,
                        onsuccess: function(stream) {
                            config.attachStream = stream;

                            var mediaElement = getMediaElement(video, {
                                width: (videosContainer.clientWidth / 2) - 50,
                                buttons: ['mute-audio', 'mute-video', 'full-screen', 'volume-slider']
                            });
                            mediaElement.toggle('mute-audio');
                            videosContainer.appendChild(mediaElement);

                            callback && callback();
                        },
                        onerror: function() {
                            alert('unable to get access to your webcam');
                            callback && callback();
                        }
                    });
                }

                var conferenceUI = conference(config);

                /* UI specific */
                var videosContainer = document.getElementById('videos-container') || document.body;
                var btnSetupNewRoom = document.getElementById('setup-new-room');
                var roomsList = document.getElementById('rooms-list');

                if (btnSetupNewRoom) btnSetupNewRoom.onclick = setupNewRoomButtonClickHandler;

                function rotateVideo(video) {
                    video.style[navigator.mozGetUserMedia ? 'transform' : '-webkit-transform'] = 'rotate(0deg)';
                    setTimeout(function() {
                        video.style[navigator.mozGetUserMedia ? 'transform' : '-webkit-transform'] = 'rotate(360deg)';
                    }, 1000);
                }

                (function() {
                    var uniqueToken = document.getElementById('unique-token');
                    if (uniqueToken)
                        if (location.hash.length > 2) uniqueToken.parentNode.parentNode.parentNode.innerHTML = '<h6 style="text-align:right;margin-bottom:10px;"><button><a style="color:white" href="' + location.href + '" target="_blank">Share Conferance</a></button></h6>';
                        else uniqueToken.innerHTML = uniqueToken.parentNode.parentNode.href = '#' + (Math.random() * new Date().getTime()).toString(36).toUpperCase().replace( /\./g , '-');
                })();


                
                function scaleVideos() {
                    var videos = document.querySelectorAll('video'),
                        length = videos.length, video;

                    var minus = 130;
                    var windowHeight = 700;
                    var windowWidth = 600;
                    var windowAspectRatio = windowWidth / windowHeight;
                    var videoAspectRatio = 4 / 3;
                    var blockAspectRatio;
                    var tempVideoWidth = 0;
                    var maxVideoWidth = 0;

                    for (var i = length; i > 0; i--) {
                        blockAspectRatio = i * videoAspectRatio / Math.ceil(length / i);
                        if (blockAspectRatio <= windowAspectRatio) {
                            tempVideoWidth = videoAspectRatio * windowHeight / Math.ceil(length / i);
                        } else {
                            tempVideoWidth = windowWidth / i;
                        }
                        if (tempVideoWidth > maxVideoWidth)
                            maxVideoWidth = tempVideoWidth;
                    }
                    for (var i = 0; i < length; i++) {
                        video = videos[i];
                        if (video)
                            video.width = maxVideoWidth - minus;
                    }
                }

                window.onresize = scaleVideos;

//var usrType='${usrType}';
//console.log(usrType);
//if(usrType!='t'){
//	document.getElementById('newConferance').style.display="none";
//}
            </script>  
        </article>
    </body>
</html>