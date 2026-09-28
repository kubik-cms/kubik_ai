import { Controller } from '@hotwired/stimulus'

const ALT_TEXT_SELECTORS = [
  '#media_upload_additional_info_alt_text',
  '#kubik_media_upload_additional_info_alt_text',
  "textarea[name='media_upload[additional_info][alt_text]']",
  "input[name='media_upload[additional_info][alt_text]']",
  "textarea[name='kubik_media_upload[additional_info][alt_text]']",
  "input[name='kubik_media_upload[additional_info][alt_text]']"
]

export default class extends Controller {
  static values = {
    altText: { type: String, default: '' }
  }

  declare altTextValue: string

  connect (): void {
    this.apply()
  }

  altTextValueChanged (): void {
    this.apply()
  }

  private apply (): void {
    const value = this.altTextValue
    ALT_TEXT_SELECTORS.forEach((selector) => {
      const element = document.querySelector(selector) as HTMLInputElement | HTMLTextAreaElement | null
      if (!element) return
      element.value = value
      element.dispatchEvent(new Event('input', { bubbles: true }))
      element.dispatchEvent(new Event('change', { bubbles: true }))
    })
  }
}
