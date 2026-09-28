import { Controller } from '@hotwired/stimulus'

type FieldMap = Record<string, string>

export default class extends Controller {
  static values = {
    fields: { type: Object, default: {} }
  }

  declare fieldsValue: FieldMap

  connect (): void {
    this.apply()
  }

  fieldsValueChanged (): void {
    this.apply()
  }

  private apply (): void {
    const fields = this.fieldsValue || {}
    Object.entries(fields).forEach(([field, value]) => {
      const selector = `[name*="[meta_tag_attributes]"][name*="[${field}]"]`
      const element = document.querySelector(selector) as HTMLInputElement | HTMLTextAreaElement | null
      if (!element) return
      element.value = value
      element.dispatchEvent(new Event('input', { bubbles: true }))
      element.dispatchEvent(new Event('change', { bubbles: true }))
    })
  }
}
