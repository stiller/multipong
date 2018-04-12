# What?

TLDR: I made a mutiplayer Pong game using Elm, Elixir GenServer and Phoenix.

[Demo player 1](https://serene-basin-29878.herokuapp.com/player1)
[Demo player 2](https://serene-basin-29878.herokuapp.com/player2)

Please allow some time for the dyno to spin up. If multiple people try to control the same player, hilarity ensues.

# Why?

I wanted to develop my Elixir and Elm skills and I figured a mutiplayer game would really exercise the whole stack. I had come across the original [Elm Pong game](http://elm-lang.org:1234/examples/pong) some years ago and decided to make it multiplayer and move all the game state to the server. After completing the excellent [Elm](https://pragmaticstudio.com/courses/elm), [Elixir](https://pragmaticstudio.com/courses/elixir) and the first part of the [Elm + Elixir](https://pragmaticstudio.com/courses/unpacked-bingo) courses by The Pragmatic Studio, I was confident enough to try.

# How?

I started with porting the game state of the original game to a simple Elixir module:
https://github.com/stiller/multipong/blob/master/apps/pong/lib/pong/game.ex
I then added a basic GenServer to hold the game state and actually run the game:
https://github.com/stiller/multipong/blob/master/apps/pong/lib/pong/game_server.ex
After testing this from an IEx shell, I added a separate Phoenix app, with the sole purpose of serving the Elm game client itself and provide websocket funcionality using the excellent Phoenix Channels. After getting the channels to work in plain old Javascript, I grabbed a `0.18` port of the Elm Pong game: https://github.com/davydog187/elm-pong
Then I set to work to replace all the client-side game state updates with calls to and from the Phoenix backend:
https://github.com/stiller/multipong/blob/master/apps/multipong/assets/elm/src/Pong.elm
To watch this process, you can checkout commits 77b06ff through a0d5cc8
Finally I converted the whole thing to an Elixir umbrella app, since that proved easier to deploy to Heroku.

# What's next?

Some obvious improvements are:
- actual user sessions
- game create
- share game link

These features are much like some topics in the Unpacked: Multi-Player Bingo course.
Then there are some gameplay improvements:
- do not allow paddle move during pause (because that's cheating)
- save key-down event in state until key-up event (this is already implemented in the `0.18` port I stole
- save and publish highscores, which allows me to play with Ecto

# Conclusion

This whole exercise was a very pleasant experience with very little frustrating moments. This was very suprising, given my experience with Elixir (little) and Elm (none).
If you have any questions, drop me a line.
