import { Controller } from "@hotwired/stimulus";
const activePanelSyncUrls = /* @__PURE__ */ new Set();
const PANEL_PROCESSING_SELECTORS = ".kubik-panel-cta--processing, .kubik-ai-panel__status--processing";
function panelShowsProcessing(panel) {
  if (!panel)
    return false;
  return panel.querySelector(PANEL_PROCESSING_SELECTORS) != null;
}
class panel_sync_controller_default extends Controller {
  constructor() {
    super(...arguments);
    this.timer = null;
  }
  connect() {
    if (this.urlValue === "")
      return;
    if (activePanelSyncUrls.has(this.urlValue))
      return;
    activePanelSyncUrls.add(this.urlValue);
    this.timer = setInterval(() => this.poll(), this.intervalMsValue);
    void this.poll();
  }
  disconnect() {
    this.endPolling();
  }
  stopPolling() {
    if (this.timer)
      clearInterval(this.timer);
    this.timer = null;
  }
  poll() {
    const csrf = document.querySelector('meta[name="csrf-token"]');
    const token = (csrf == null ? void 0 : csrf.getAttribute("content")) || "";
    fetch(this.urlValue, {
      headers: {
        Accept: "text/vnd.turbo-stream.html",
        "X-CSRF-Token": token
      },
      credentials: "same-origin"
    }).then((response) => response.text()).then((html) => {
      const turbo = window.Turbo;
      if (html && typeof (turbo == null ? void 0 : turbo.renderStreamMessage) === "function") {
        turbo.renderStreamMessage(html);
      }
      const panel = document.getElementById(`kubik_ai_panel_${this.panelIdValue}`);
      if (!panelShowsProcessing(panel)) {
        this.endPolling();
      }
    }).catch(() => {
    });
  }
  endPolling() {
    this.stopPolling();
    activePanelSyncUrls.delete(this.urlValue);
  }
}
panel_sync_controller_default.values = {
  url: { type: String, default: "" },
  panelId: { type: String, default: "" },
  intervalMs: { type: Number, default: 2e3 }
};
const ALT_TEXT_SELECTORS = [
  "#media_upload_additional_info_alt_text",
  "#kubik_media_upload_additional_info_alt_text",
  "textarea[name='media_upload[additional_info][alt_text]']",
  "input[name='media_upload[additional_info][alt_text]']",
  "textarea[name='kubik_media_upload[additional_info][alt_text]']",
  "input[name='kubik_media_upload[additional_info][alt_text]']"
];
class alt_text_sync_controller_default extends Controller {
  connect() {
    this.apply();
  }
  altTextValueChanged() {
    this.apply();
  }
  apply() {
    const value = this.altTextValue;
    ALT_TEXT_SELECTORS.forEach((selector) => {
      const element = document.querySelector(selector);
      if (!element)
        return;
      element.value = value;
      element.dispatchEvent(new Event("input", { bubbles: true }));
      element.dispatchEvent(new Event("change", { bubbles: true }));
    });
  }
}
alt_text_sync_controller_default.values = {
  altText: { type: String, default: "" }
};
const TAG_FIELD_IDS = [
  "kubik_media_upload_media_tag_list_input",
  "media_upload_media_tag_list_input"
];
function expandTags(raw) {
  if (raw == null)
    return [];
  let values = [];
  if (Array.isArray(raw)) {
    values = raw;
  } else if (typeof raw === "string") {
    const trimmed = raw.trim();
    if (trimmed.startsWith("[")) {
      try {
        const parsed = JSON.parse(trimmed);
        if (Array.isArray(parsed))
          values = parsed;
        else
          values = [raw];
      } catch {
        values = [raw];
      }
    } else {
      values = [raw];
    }
  } else {
    return [];
  }
  return values.reduce((acc, entry) => {
    return acc.concat(
      String(entry).split(/[,;]+/).map((tag) => tag.trim()).filter((tag) => tag !== "")
    );
  }, []);
}
class tags_sync_controller_default extends Controller {
  connect() {
    this.apply();
  }
  tagsValueChanged() {
    this.apply();
  }
  apply() {
    const tags = expandTags(this.tagsValue);
    if (tags.length === 0)
      return;
    const tokenRoot = this.findTokenInputRoot();
    if (!tokenRoot)
      return;
    tokenRoot.dispatchEvent(
      new CustomEvent("kubik-token-input:replace", {
        bubbles: false,
        detail: { tags }
      })
    );
  }
  findTokenInputRoot() {
    for (const id of TAG_FIELD_IDS) {
      const field = document.getElementById(id);
      const token = field == null ? void 0 : field.querySelector('[data-controller*="kubik-token-input"]');
      if (token)
        return token;
    }
    return document.querySelector('[data-controller*="kubik-token-input"]');
  }
}
tags_sync_controller_default.values = {
  tags: { type: Array, default: [] },
  uploadId: { type: String, default: "" }
};
class metatag_sync_controller_default extends Controller {
  connect() {
    this.apply();
  }
  fieldsValueChanged() {
    this.apply();
  }
  apply() {
    const fields = this.fieldsValue || {};
    Object.entries(fields).forEach(([field, value]) => {
      const selector = `[name*="[meta_tag_attributes]"][name*="[${field}]"]`;
      const element = document.querySelector(selector);
      if (!element)
        return;
      element.value = value;
      element.dispatchEvent(new Event("input", { bubbles: true }));
      element.dispatchEvent(new Event("change", { bubbles: true }));
    });
  }
}
metatag_sync_controller_default.values = {
  fields: { type: Object, default: {} }
};
export { alt_text_sync_controller_default as AltTextSyncController, metatag_sync_controller_default as MetatagSyncController, panel_sync_controller_default as PanelSyncController, tags_sync_controller_default as TagsSyncController };
