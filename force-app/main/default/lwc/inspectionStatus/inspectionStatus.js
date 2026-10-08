// Shared status presentation for the inspection portal components.

const STATUS_META = {
  Passed: { tone: "ok", color: "#2e7d4f" },
  "Passed with Conditions": { tone: "caution", color: "#b7791f" },
  Scheduled: { tone: "info", color: "#2f6fb0" },
  "In Progress": { tone: "info", color: "#2f6fb0" },
  Failed: { tone: "bad", color: "#c0392b" },
  "Re-inspection Required": { tone: "bad", color: "#c0392b" },
  Overdue: { tone: "overdue", color: "#8e1f5b" },
  "Not Yet Inspected": { tone: "neutral", color: "#6b7a83" }
};

const FALLBACK = { tone: "neutral", color: "#6b7a83" };

export function statusMeta(status) {
  return STATUS_META[status] || FALLBACK;
}

export function statusPillClass(status) {
  return `pill pill_${statusMeta(status).tone}`;
}

/** Legend rows for the map, in display order. Failed and Re-inspection Required share a color. */
export const LEGEND = [
  { label: "Passed", color: STATUS_META.Passed.color },
  {
    label: "Passed with conditions",
    color: STATUS_META["Passed with Conditions"].color
  },
  { label: "Scheduled / in progress", color: STATUS_META.Scheduled.color },
  { label: "Failed / re-inspection", color: STATUS_META.Failed.color },
  { label: "Overdue", color: STATUS_META.Overdue.color },
  { label: "Not yet inspected", color: FALLBACK.color }
];

/** Apex Date values arrive as 'YYYY-MM-DD'. Parse them as local dates so they don't shift a day. */
function parseDate(value) {
  if (!value) {
    return null;
  }
  const [y, m, d] = value.split("-").map(Number);
  return new Date(y, m - 1, d);
}

export function formatDate(value) {
  const date = parseDate(value);
  return date
    ? date.toLocaleDateString("en-US", {
        month: "short",
        day: "numeric",
        year: "numeric"
      })
    : "—";
}

/** "Due in 12 days", "Due today", "Overdue by 40 days". */
export function dueLabel(value) {
  const date = parseDate(value);
  if (!date) {
    return "No inspection scheduled";
  }
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const days = Math.round((date - today) / 86400000);
  if (days === 0) {
    return "Due today";
  }
  const unit = Math.abs(days) === 1 ? "day" : "days";
  return days > 0
    ? `Due in ${days} ${unit}`
    : `Overdue by ${Math.abs(days)} ${unit}`;
}

export function formatAddress(facility) {
  if (!facility) {
    return "";
  }
  const cityLine = [
    facility.city,
    [facility.state, facility.postalCode].filter(Boolean).join(" ")
  ]
    .filter(Boolean)
    .join(", ");
  return [facility.street, cityLine].filter(Boolean).join(", ");
}

// ---------- National Insights charts ----------

/**
 * Result colors for the trend chart. Validated as a set (CVD-safe, normal-vision distinct);
 * the amber is below 3:1 on white, so the chart always ships a legend and a data table.
 */
export const RESULT_COLORS = {
  passed: "#1c8a4a",
  conditional: "#e0a21a",
  failed: "#c62f2f"
};

/** Single-series bar color (sequential blue, step 450). */
export const BAR_COLOR = "#2a78d6";

/** Sequential blue bins for "% of facilities compliant" on the state map. */
export const COMPLIANCE_BINS = [
  { min: 85, label: "85–100%", fill: "#184f95", ink: "#ffffff" },
  { min: 70, label: "70–84%", fill: "#3987e5", ink: "#ffffff" },
  { min: 50, label: "50–69%", fill: "#86b6ef", ink: "#0d366b" },
  { min: 0, label: "Under 50%", fill: "#cde2fb", ink: "#0d366b" }
];
export const NO_DATA_BIN = {
  label: "No listed facilities",
  fill: "#eef1f3",
  ink: "#6b7a83"
};

export function complianceBin(pct) {
  if (pct === null || pct === undefined) {
    return NO_DATA_BIN;
  }
  return COMPLIANCE_BINS.find((bin) => pct >= bin.min) || COMPLIANCE_BINS[3];
}

export function formatPct(value) {
  return value === null || value === undefined
    ? "—"
    : `${Number(value).toFixed(1)}%`;
}

export function formatScore(value) {
  return value === null || value === undefined ? "—" : Number(value).toFixed(1);
}

export function formatCount(value) {
  return value === null || value === undefined
    ? "—"
    : Number(value).toLocaleString("en-US");
}

/** Smallest "nice" axis maximum (1, 2, 2.5, 5 x 10^n) at or above the data maximum. */
export function niceMax(value) {
  if (!value || value <= 0) {
    return 1;
  }
  const magnitude = 10 ** Math.floor(Math.log10(value));
  const step = [1, 2, 2.5, 5, 10].find((m) => m * magnitude >= value);
  return step * magnitude;
}
