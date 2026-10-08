import { LightningElement, api } from "lwc";
import {
  COMPLIANCE_BINS,
  NO_DATA_BIN,
  complianceBin,
  formatPct
} from "c/inspectionStatus";

// Equal-area tile grid of the 50 states: [column, row].
const GRID = {
  AK: [0, 0],
  ME: [11, 0],
  VT: [10, 1],
  NH: [11, 1],
  WA: [1, 2],
  ID: [2, 2],
  MT: [3, 2],
  ND: [4, 2],
  MN: [5, 2],
  IL: [6, 2],
  WI: [7, 2],
  MI: [8, 2],
  NY: [9, 2],
  RI: [10, 2],
  MA: [11, 2],
  OR: [1, 3],
  NV: [2, 3],
  WY: [3, 3],
  SD: [4, 3],
  IA: [5, 3],
  IN: [6, 3],
  OH: [7, 3],
  PA: [8, 3],
  NJ: [9, 3],
  CT: [10, 3],
  CA: [1, 4],
  UT: [2, 4],
  CO: [3, 4],
  NE: [4, 4],
  MO: [5, 4],
  KY: [6, 4],
  WV: [7, 4],
  VA: [8, 4],
  MD: [9, 4],
  DE: [10, 4],
  AZ: [2, 5],
  NM: [3, 5],
  KS: [4, 5],
  AR: [5, 5],
  TN: [6, 5],
  NC: [7, 5],
  SC: [8, 5],
  OK: [4, 6],
  LA: [5, 6],
  MS: [6, 6],
  AL: [7, 6],
  GA: [8, 6],
  HI: [0, 7],
  TX: [4, 7],
  FL: [9, 7]
};
const CELL = 48;
const TILE = 44;

/**
 * Tile-grid map of US states shaded by % of listed facilities compliant.
 * Each tile links to the facility search filtered to that state.
 */
export default class UsStateTileMap extends LightningElement {
  /** StateStat[] from InspectionInsightsController. */
  @api states = [];
  /** Base URL of the facility search page; ?state=<name> is appended. */
  @api searchUrl = "/";

  viewBox = `0 0 ${12 * CELL} ${8 * CELL}`;
  activeCode = null;

  get legend() {
    return [...COMPLIANCE_BINS, NO_DATA_BIN].map((bin) => ({
      key: bin.label,
      label: bin.label,
      style: `background-color: ${bin.fill}`
    }));
  }

  get tiles() {
    return (this.states || [])
      .filter((s) => GRID[s.code])
      .map((s) => {
        const [col, row] = GRID[s.code];
        const bin = complianceBin(s.compliantPct);
        const x = col * CELL + (CELL - TILE) / 2;
        const y = row * CELL + (CELL - TILE) / 2;
        const active = s.code === this.activeCode;
        return {
          key: s.code,
          code: s.code,
          x,
          y,
          size: TILE,
          fill: bin.fill,
          labelX: x + TILE / 2,
          labelY: y + TILE / 2 + 5,
          labelStyle: `fill: ${bin.ink}`,
          tileClass: active ? "tile tile_active" : "tile",
          href: `${this.searchUrl}?state=${encodeURIComponent(s.name)}`,
          ariaLabel: this.describe(s)
        };
      });
  }

  get tooltip() {
    const s = (this.states || []).find((st) => st.code === this.activeCode);
    if (!s || !GRID[s.code]) {
      return null;
    }
    const [col, row] = GRID[s.code];
    const left = Math.min(
      84,
      Math.max(16, (((col + 0.5) * CELL) / (12 * CELL)) * 100)
    );
    const top = ((row * CELL) / (8 * CELL)) * 100;
    return {
      title: s.name,
      style: `left: ${left}%; top: ${top}%;`,
      rows:
        s.facilities === 0
          ? [{ key: "none", text: "No listed facilities" }]
          : [
              { key: "pct", text: `${formatPct(s.compliantPct)} compliant` },
              { key: "fac", text: `${s.facilities} facilities` },
              { key: "od", text: `${s.overdue} overdue · ${s.failing} failing` }
            ]
    };
  }

  get tableRows() {
    return (this.states || []).map((s) => ({
      key: s.code,
      name: s.name,
      facilities: s.facilities,
      pct: s.facilities === 0 ? "—" : formatPct(s.compliantPct),
      overdue: s.overdue,
      failing: s.failing
    }));
  }

  describe(s) {
    if (s.facilities === 0) {
      return `${s.name}: no listed facilities`;
    }
    return `${s.name}: ${formatPct(s.compliantPct)} of ${s.facilities} facilities compliant, ${s.overdue} overdue, ${s.failing} failing. Open facilities in ${s.name}.`;
  }

  handleEnter(event) {
    this.activeCode = event.currentTarget.dataset.code;
  }

  handleLeave() {
    this.activeCode = null;
  }
}
