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
import "lodash";


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
  // Scrolling: {
  //   mounted() {
  //     window.addEventListener("scroll", e => {
  //       let page = document.documentElement
  //       let percentage = page.scrollTop / (page.scrollHeight - page.clientHeight);

  //       if (percentage < 0.1) {
  //         this.pushEvent("change_range", {amount: -1})
  //       }
  //       else if (percentage > 0.9) this.pushEvent("change_range", {amount: 1})
  //     })
  //   }
  // },
  Today: {
    mounted() {
      this.el.scrollIntoView()
    }
  },
  Days: {
    loading: false,
    scrollTop: document.documentElement.scrollTop,
    height: document.documentElement.offsetHeight,
    beforeUpdate() {
      this.scrollTop = document.documentElement.scrollTop;
      this.height = document.documentElement.offsetHeight;
    },
    mounted() {
      window.addEventListener("scroll", _.throttle(e => {
        if (this.loading) return;
        let page = document.documentElement
        let percentage = page.scrollTop / (page.scrollHeight - page.clientHeight);
        if (percentage < 0.3) {
          this.loading = true;
          this.pushEvent("change_range", {amount: -1}, () => {
            this.loading = false;
            let addedElHeight = this.el.firstElementChild.offsetHeight
            document.documentElement.scrollTop = this.scrollTop + addedElHeight;
          })
        }
        else if (percentage > 0.7) {
          this.loading = true;
          this.pushEvent("change_range", {amount: 1}, () => {
            this.loading = false;
            let addedElHeight = this.el.lastElementChild.offsetHeight
            document.documentElement.scrollTop = this.scrollTop - addedElHeight;
          });
        }
      }), 1000, {leading: true})
    },

  },
  Topics: {
    searching: false,
    searchTerm: "",
    removeSearchTerm() {
      let matches = [...this.el.value.matchAll(/(\/.+?)(?:((?:-|\+)\d)|$)/gm)]
      for (let match of matches) {
        if (this.el.selectionStart - match["index"] - match[0].length == 0) {
          let selectionStart = this.el.selectionStart;
          let matchLength = match[0].length
          this.el.value = this.el.value.slice(0,match["index"]) + this.el.value.slice(match["index"] + matchLength);
          this.el.selectionStart = selectionStart - matchLength;
          this.el.selectionEnd = selectionStart - matchLength;
        }
      }

    },
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
            this.removeSearchTerm()
            e.preventDefault()
            this.searching = false
            this.pushEvent("insert_topic", {content: this.el.value, location: this.el.selectionStart})
          } else if (e.key == "Escape") {
            this.removeSearchTerm()
            this.searching = false;
            this.pushEvent("search_term", {term: ""})
          } else if (e.key == "ArrowLeft") {
            e.preventDefault()
            this.pushEvent("select_topic", {direction: "left"})
          } else if (e.key == "ArrowRight") {
            e.preventDefault()
            this.pushEvent("select_topic", {direction: "right"})
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
  params: {_csrf_token: csrfToken},
})

liveSocket.connect()

// Expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
// The latency simulator is enabled for the duration of the browser session.
// Call disableLatencySim() to disable:
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket


