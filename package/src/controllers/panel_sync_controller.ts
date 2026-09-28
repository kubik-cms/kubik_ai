import { Controller } from '@hotwired/stimulus'

declare global {
  interface Window {
    Turbo?: { renderStreamMessage: (html: string) => void }
  }
}

const activePanelSyncUrls = new Set<string>()

/** Matches kubik_panel_cta processing state (see kubik-panel-cta--processing). */
const PANEL_PROCESSING_SELECTORS =
  '.kubik-panel-cta--processing, .kubik-ai-panel__status--processing'

function panelShowsProcessing (panel: HTMLElement | null): boolean {
  if (!panel) return false
  return panel.querySelector(PANEL_PROCESSING_SELECTORS) != null
}

export default class extends Controller {
  static values = {
    url: { type: String, default: '' },
    panelId: { type: String, default: '' },
    intervalMs: { type: Number, default: 2000 }
  }

  declare urlValue: string
  declare panelIdValue: string
  declare intervalMsValue: number

  private timer: ReturnType<typeof setInterval> | null = null

  connect (): void {
    if (this.urlValue === '') return
    if (activePanelSyncUrls.has(this.urlValue)) return
    activePanelSyncUrls.add(this.urlValue)
    this.timer = setInterval(() => this.poll(), this.intervalMsValue)
    void this.poll()
  }

  disconnect (): void {
    this.endPolling()
  }

  private stopPolling (): void {
    if (this.timer) clearInterval(this.timer)
    this.timer = null
  }

  private poll (): void {
    const csrf = document.querySelector('meta[name="csrf-token"]')
    const token = csrf?.getAttribute('content') || ''

    fetch(this.urlValue, {
      headers: {
        Accept: 'text/vnd.turbo-stream.html',
        'X-CSRF-Token': token
      },
      credentials: 'same-origin'
    })
      .then((response) => response.text())
      .then((html) => {
        const turbo = window.Turbo
        if (html && typeof turbo?.renderStreamMessage === 'function') {
          turbo.renderStreamMessage(html)
        }
        const panel = document.getElementById(`kubik_ai_panel_${this.panelIdValue}`)
        if (!panelShowsProcessing(panel)) {
          this.endPolling()
        }
      })
      .catch(() => {})
  }

  private endPolling (): void {
    this.stopPolling()
    activePanelSyncUrls.delete(this.urlValue)
  }
}
