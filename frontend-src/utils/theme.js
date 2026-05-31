export const UI_THEMES = [
  "dracula",
  "classic",
  "nothing",
  "material",
  "terminal",
];

export const UI_THEME_OPTIONS = [
  { label: "Dracula", value: "dracula", description: "Violet néon — dark & light (Alucard)" },
  { label: "Classic (TacticalRMM)", value: "classic", description: "Apparence originale Quasar" },
  { label: "Nothing Phone", value: "nothing", description: "Monochrome + accent rouge" },
  { label: "Material Design", value: "material", description: "Material Design 3" },
  { label: "Terminal", value: "terminal", description: "Console monospace phosphore" },
];

export function applyTheme(theme) {
  const name = UI_THEMES.includes(theme) ? theme : "dracula";
  const body = document.body;
  UI_THEMES.forEach((t) => body.classList.remove(`theme-${t}`));
  body.classList.add(`theme-${name}`);
  return name;
}

export function getThemeLabel(theme) {
  return UI_THEME_OPTIONS.find((o) => o.value === theme)?.label ?? "Dracula";
}
