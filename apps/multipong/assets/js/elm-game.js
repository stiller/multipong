const gameContainer = document.getElementById("game-container");

if(gameContainer) {
  Elm.Pong.embed(gameContainer, {
    authToken: gameContainer.getAttribute("data-auth-token"),
    wsUrl: gameContainer.getAttribute("data-ws-url")
  })
}
