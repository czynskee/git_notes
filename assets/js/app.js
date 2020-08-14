// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
    // import {Socket} from "phoenix"
    // import socket from "./socket"
//
import "phoenix_html"


// autocomplete
// when they type we will do a regex to find our topic lookup pattern "/text"
// when we have the result of the regex, we will look at the selectionstart to see
// where in the text field they are typing.
// we can subtract the length of the match from selectionstart and see if it matches the index in the
// match. If so then we know that this is the match that they are currently typing and the one that
// should show autocomplete suggestions for. We will send the text in there to the server
// the server will filter the list of the users topics.
// should the topic show inline or on the side?
// if its inline then we need a div to hold the text. When we see that they type a slash we could
// insert a new div. Then we could just look at the content in that div to see what they're looking
// for.

let Hooks = {
  Topics: {
    searching: false,
    searchTerm: "",
    mounted() {
      this.el.addEventListener("input", e => {
        let matches = [...this.el.value.matchAll(/(\/.+?)(?:((?:-|\+)\d)|$)/gm)]
        let found = false;
        for (let match of matches) {
          if (this.el.selectionStart - match["index"] - match[0].length == 0) {
            this.searching = true;
            found = true;
            this.searchTerm = match[1].slice(1)
            this.pushEvent("search_term", {term: this.searchTerm, modifier: match[2]});
          }
        }
        if (found == false && this.searching == true) {
          this.searching = false;
          this.pushEvent("search_term", {term: ""})
        }
        })
      
        this.el.addEventListener("keydown", e => {
        if (this.searching) {
          if (e.key == "ArrowUp") {
            e.preventDefault()
            this.pushEvent("select_topic", {direction: "up"})
          } else if (e.key == "ArrowDown") {
            e.preventDefault()
            this.pushEvent("select_topic", {direction: "down"})
          } else if (e.key == "Enter") {
            e.preventDefault()
            this.searching = false
            this.pushEvent("insert_topic", {content: this.el.value, location: this.el.selectionStart})
          }
        }
      })
    }
  }
}






import {Socket} from "phoenix"
import LiveSocket from "phoenix_live_view"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: {_csrf_token: csrfToken}
})

liveSocket.connect()

// Expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
// The latency simulator is enabled for the duration of the browser session.
// Call disableLatencySim() to disable:
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket


