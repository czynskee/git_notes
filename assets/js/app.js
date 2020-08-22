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

function percentageSeen(element) {
  console.log(window.scrollY)
  const viewportHeight = window.innerHeight;
  const scrollTop = window.scrollY;
  const elementOffsetTop = element.offsetTop;
  const elementHeight = element.offsetHeight;

  // Calculate percentage of the element that's been seen
  const distance = scrollTop + viewportHeight - elementOffsetTop;
  const percentage = Math.round(
    distance / ((viewportHeight + elementHeight) / 100)
  );

  // Restrict the range to between 0 and 100
  return Math.min(100, Math.max(0, percentage));
}

let Hooks = {
  Today: {
    mounted() {
      this.el.scrollIntoView()
    }
  },
  DayLoader: {
    loading: false,
    scrollTop: document.documentElement.scrollTop,
    height: document.documentElement.offsetHeight,
    header: null,
    incrementDate(dateString, amount) {
      let date = new Date(dateString);
      date = date.setDate(date.getDate() + amount);
      date = new Date(date);
      return date.toISOString().split("T")[0]
    },
    beforeUpdate() {
      this.scrollTop = document.documentElement.scrollTop;
      this.height = document.documentElement.offsetHeight;
    },
    currentDate() {
      let currentDate = document.querySelector(".iso-date").innerHTML
      let children = Array.from(this.el.children)
      let mostSeenElem = null;
      let highestAmountShown = -1;

      for (let child of children) {
        let childLocation = child.getBoundingClientRect()
        let childBottom = childLocation.y + childLocation.height
        if (childBottom > 0 && childLocation.y < window.innerHeight) {
          let childCutoffTop = childLocation.y < 0 ? 0 : childLocation.y
          let childCutoffBottom = childBottom > window.innerHeight ? window.innerHeight : childBottom
          let totalAmountShown = childCutoffBottom - childCutoffTop
          if (totalAmountShown > highestAmountShown) {
            mostSeenElem = child;
            highestAmountShown = totalAmountShown;
          }
        }
      }

      let date = mostSeenElem.id.split("-").slice(1).join("-")
      if (currentDate !== date) {
        console.log(date, currentDate)
        this.pushEvent("current_date", {date})
      }
    },
    mounted() {
      this.header = document.querySelector(".day-header")
      this.currentDate()
      window.addEventListener("scroll", _.throttle(e => {
        if (this.loading) return;
        this.currentDate()
        let page = document.documentElement
        let percentage = page.scrollTop / (page.scrollHeight - page.clientHeight);
        if (percentage < 0.2) {
          this.loading = true;
          // let newDate = this.incrementDate(this.el.firstElementChild.id, -1)
          // this.pushEvent("change_range", {new_date: newDate, add_date_action: "prepend"}, () => {
            this.pushEvent("change_range", {direction: "back"}, () => {
            this.loading = false;
            let addedElHeight = this.el.firstElementChild.offsetHeight
            document.documentElement.scrollTop = this.scrollTop + addedElHeight;
            // this.el.lastElementChild.remove()
          })
        }

        else if (percentage > 0.8) {
          this.loading = true;
          // let newDate = this.incrementDate(this.el.lastElementChild.id, 1)
          // this.pushEvent("change_range", {new_date: newDate, add_date_action: "append"}, () => {
            this.pushEvent("change_range", {direction: "forward"}, () => {
            this.loading = false;
            let addedElHeight = this.el.lastElementChild.offsetHeight
            document.documentElement.scrollTop = this.scrollTop - addedElHeight;
            // this.el.firstElementChild.remove()
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
            console.log(this.el.id)
            this.pushEventTo(`#${this.el.id}`, "search_term", {term: this.searchTerm, modifier: match[2]}, (reply, ref) => {
              console.log(reply, ref)
            });
          }
        }
        if (found == false && this.searching == true) {
          this.searching = false;
          this.pushEventTo(`#${this.el.id}`, "search_term", {term: ""})
        }
        })
      
        this.el.addEventListener("keydown", e => {
        if (this.searching) {
          if (e.key == "ArrowUp") {
            e.preventDefault()
            this.pushEventTo(`#${this.el.id}`, "select_topic", {direction: "up"})
          } else if (e.key == "ArrowDown") {
            e.preventDefault()
            this.pushEventTo(`#${this.el.id}`, "select_topic", {direction: "down"})
          } else if (e.key == "Enter") {
            this.removeSearchTerm()
            e.preventDefault()
            this.searching = false
            this.pushEventTo(`#${this.el.id}`, "insert_topic", {content: this.el.value, location: this.el.selectionStart})
          } else if (e.key == "Escape") {
            this.removeSearchTerm()
            this.searching = false;
            this.pushEventTo(`#${this.el.id}`, "search_term", {term: ""})
          } else if (e.key == "ArrowLeft") {
            e.preventDefault()
            this.pushEventTo(`#${this.el.id}`, "select_topic", {direction: "left"})
          } else if (e.key == "ArrowRight") {
            e.preventDefault()
            this.pushEventTo(`#${this.el.id}`, "select_topic", {direction: "right"})
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


