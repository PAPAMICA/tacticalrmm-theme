export const UI_THEMES = ["dracula", "classic", "alucard"];

export const UI_THEME_OPTIONS = [
  { label: "Dracula", value: "dracula" },
  { label: "Classic (TacticalRMM)", value: "classic" },
  { label: "Alucard (Light)", value: "alucard" },
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
