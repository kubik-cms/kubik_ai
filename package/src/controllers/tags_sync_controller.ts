import { Controller } from '@hotwired/stimulus'

const TAG_FIELD_IDS = [
  'kubik_media_upload_media_tag_list_input',
  'media_upload_media_tag_list_input'
]

function expandTags (raw: unknown): string[] {
  if (raw == null) return []

  let values: unknown[] = []
  if (Array.isArray(raw)) {
    values = raw
  } else if (typeof raw === 'string') {
    const trimmed = raw.trim()
    if (trimmed.startsWith('[')) {
      try {
        const parsed = JSON.parse(trimmed)
        if (Array.isArray(parsed)) values = parsed
        else values = [raw]
      } catch {
        values = [raw]
      }
    } else {
      values = [raw]
    }
  } else {
    return []
  }

  return values.reduce<string[]>((acc, entry) => {
    return acc.concat(
      String(entry)
        .split(/[,;]+/)
        .map((tag) => tag.trim())
        .filter((tag) => tag !== '')
    )
  }, [])
}

export default class extends Controller {
  static values = {
    tags: { type: Array, default: [] },
    uploadId: { type: String, default: '' }
  }

  declare tagsValue: string[]
  declare uploadIdValue: string

  connect (): void {
    this.apply()
  }

  tagsValueChanged (): void {
    this.apply()
  }

  private apply (): void {
    const tags = expandTags(this.tagsValue)
    if (tags.length === 0) return

    const tokenRoot = this.findTokenInputRoot()
    if (!tokenRoot) return

    tokenRoot.dispatchEvent(
      new CustomEvent('kubik-token-input:replace', {
        bubbles: false,
        detail: { tags }
      })
    )
  }

  private findTokenInputRoot (): HTMLElement | null {
    for (const id of TAG_FIELD_IDS) {
      const field = document.getElementById(id)
      const token = field?.querySelector<HTMLElement>('[data-controller*="kubik-token-input"]')
      if (token) return token
    }
    return document.querySelector<HTMLElement>('[data-controller*="kubik-token-input"]')
  }
}
