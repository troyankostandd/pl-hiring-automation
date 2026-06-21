import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "list", "item"]
  static values = {
    url: String,
    delay: { type: Number, default: 300 }
  }

  connect() {
    this.timeout = null
  }

  search(event) {
    const query = event.target.value

    if (this.timeout) clearTimeout(this.timeout)

    if (query.length < 1) {
      this.listTarget.innerHTML = ""
      return
    }

    this.timeout = setTimeout(() => {
      this.fetchSuggestions(query)
    }, this.delayValue)
  }

  async fetchSuggestions(query) {
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.append("q", query)

    try {
      const response = await fetch(url)
      const suggestions = await response.json()
      this.renderSuggestions(suggestions)
    } catch (error) {
      console.error("Autocomplete error:", error)
    }
  }

  renderSuggestions(suggestions) {
    if (suggestions.length === 0) {
      this.listTarget.innerHTML = "<div class='p-2 text-sm text-gray-500'>No matches</div>"
      return
    }

    const html = suggestions
      .map(
        (item) =>
          `<button
            type="button"
            class="w-full text-left px-4 py-2 hover:bg-gray-100 data-[action]="autocomplete#select"
            data-id="${item.id}"
            data-name="${item.display_name}"
          >
            ${item.display_name} <span class="text-xs text-gray-500">(${item.usage_count})</span>
          </button>`
      )
      .join("")

    this.listTarget.innerHTML = html
  }

  select(event) {
    event.preventDefault()
    const ingredient = {
      id: event.target.dataset.id,
      name: event.target.dataset.name
    }

    this.dispatch("selected", { detail: ingredient })
  }
}
