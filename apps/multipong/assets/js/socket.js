// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/web/endpoint.ex":
import {Socket} from "phoenix"
let authToken = document.getElementById('game-container').getAttribute('data-auth-token')
let socket = new Socket("/socket", {params: {token: authToken}})
socket.connect()

window.channel = socket.channel("game", {})
channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

channel.on("output", output => { console.log("output:", output) });

export default socket
