import { LightningElement, api } from "lwc";
import { RESULT_COLORS, formatScore, niceMax } from "c/inspectionStatus";

// SVG coordinate system (scaled to the container width).
const W = 1040;
const LEFT = 40;
const RIGHT = 12;
const COLUMNS_TOP = 24;
const COLUMNS_H = 180;
const AXIS_GAP = 34; // room for quarter and year labels
const SCORE_TITLE_H = 26;
const SCORE_H = 84;
const H = COLUMNS_TOP + COLUMNS_H + AXIS_GAP + SCORE_TITLE_H + SCORE_H + 8;
const SEGMENT_GAP = 2;
const RADIUS = 4;

const SERIES = [
  { key: "passed", label: "Passed", color: RESULT_COLORS.passed },
  {
    key: "conditional",
    label: "Passed with conditions",
    color: RESULT_COLORS.conditional
  },
  { key: "failed", label: "Failed", color: RESULT_COLORS.failed }
];

/** Rect with only the top corners rounded (the data end), anchored to the baseline. */
function topRoundedPath(x, y, w, h, r) {
  const rr = Math.min(r, h, w / 2);
  return `M${x},${y + h} V${y + rr} Q${x},${y} ${x + rr},${y} H${x + w - rr} Q${x + w},${y} ${x + w},${y + rr} V${y + h} Z`;
}

/**
 * Two panels on one quarterly x-axis (small multiples, not a dual axis):
 * stacked columns of completed inspections by result, then the average score line.
 */
export default class InsightsTrendChart extends LightningElement {
  /** QuarterStat[] from InspectionInsightsController. */
  @api quarters = [];

  viewBox = `0 0 ${W} ${H}`;
  legend = SERIES.map((s) => ({
    ...s,
    style: `background-color: ${s.color}`
  }));
  activeIndex = null;

  get list() {
    return this.quarters || [];
  }

  get band() {
    return (W - LEFT - RIGHT) / Math.max(1, this.list.length);
  }

  get countMax() {
    return niceMax(Math.max(0, ...this.list.map((q) => q.total || 0)));
  }

  get scoreDomain() {
    const scores = this.list
      .map((q) => q.avgScore)
      .filter((s) => s !== null && s !== undefined);
    const min = scores.length ? Math.min(...scores) : 60;
    return [Math.min(80, Math.floor((min - 5) / 10) * 10), 100];
  }

  get scoreTop() {
    return COLUMNS_TOP + COLUMNS_H + AXIS_GAP + SCORE_TITLE_H;
  }

  yCount(v) {
    return COLUMNS_TOP + COLUMNS_H - (v / this.countMax) * COLUMNS_H;
  }

  yScore(v) {
    const [lo, hi] = this.scoreDomain;
    return this.scoreTop + SCORE_H - ((v - lo) / (hi - lo)) * SCORE_H;
  }

  gridLine(key, value, y) {
    return {
      key,
      y,
      x1: LEFT,
      x2: W - RIGHT,
      labelX: LEFT - 6,
      labelY: y + 4,
      label: value
    };
  }

  get countGrid() {
    const max = this.countMax;
    return [0, 0.25, 0.5, 0.75, 1].map((f) => {
      const value = Math.round(max * f * 10) / 10;
      return this.gridLine(`c${f}`, value, this.yCount(value));
    });
  }

  get scoreGrid() {
    const [lo, hi] = this.scoreDomain;
    return [lo, (lo + hi) / 2, hi].map((value) =>
      this.gridLine(`s${value}`, value, this.yScore(value))
    );
  }

  get columns() {
    const band = this.band;
    const barW = Math.min(40, band * 0.6);
    return this.list.map((q, index) => {
      const x = LEFT + band * index + (band - barW) / 2;
      let base = this.yCount(0);
      const present = SERIES.filter((s) => q[s.key] > 0);
      const segments = present.map((s, i) => {
        const h = (q[s.key] / this.countMax) * COLUMNS_H;
        const gap = i === 0 ? 0 : SEGMENT_GAP;
        const segH = Math.max(1, h - gap);
        const y = base - gap - segH;
        base = y;
        return {
          key: `${index}-${s.key}`,
          fill: s.color,
          d:
            i === present.length - 1
              ? topRoundedPath(x, y, barW, segH, RADIUS)
              : `M${x},${y} h${barW} v${segH} h${-barW} Z`
        };
      });
      return {
        key: `q${index}`,
        index,
        segments,
        cx: LEFT + band * index + band / 2,
        quarterLabel: `Q${q.quarter}`,
        yearLabel: q.quarter === 1 || index === 0 ? String(q.year) : "",
        quarterY: COLUMNS_TOP + COLUMNS_H + 16,
        yearY: COLUMNS_TOP + COLUMNS_H + 30,
        hitX: LEFT + band * index,
        hitW: band,
        ariaLabel: this.describe(q)
      };
    });
  }

  get scorePoints() {
    return this.list
      .map((q, index) => ({ q, index }))
      .filter(({ q }) => q.avgScore !== null && q.avgScore !== undefined)
      .map(({ q, index }) => ({
        key: `p${index}`,
        cx: LEFT + this.band * index + this.band / 2,
        cy: this.yScore(q.avgScore),
        index
      }));
  }

  /** Line through the score points, broken where a quarter has no score. */
  get scoreLine() {
    let d = "";
    let previous = null;
    for (const p of this.scorePoints) {
      d +=
        previous !== null && p.index === previous + 1
          ? ` L${p.cx},${p.cy}`
          : ` M${p.cx},${p.cy}`;
      previous = p.index;
    }
    return d.trim();
  }

  get lastScoreLabel() {
    const points = this.scorePoints;
    if (!points.length) {
      return null;
    }
    const last = points[points.length - 1];
    return {
      x: last.cx,
      y: last.cy - 10,
      text: formatScore(this.list[last.index].avgScore)
    };
  }

  get columnsTitleY() {
    return COLUMNS_TOP - 10;
  }

  get scoreTitleY() {
    return this.scoreTop - 12;
  }

  get labelX() {
    return LEFT;
  }

  get hitTop() {
    return COLUMNS_TOP;
  }

  get hitH() {
    return H - COLUMNS_TOP;
  }

  get tableRows() {
    return this.list.map((q) => ({
      key: q.label,
      label: q.isPartial ? `${q.label} (to date)` : q.label,
      passed: q.passed,
      conditional: q.conditional,
      failed: q.failed,
      score: formatScore(q.avgScore)
    }));
  }

  get chartLabel() {
    return "Completed inspections by quarter and result, with the average inspection score.";
  }

  get tooltip() {
    if (this.activeIndex === null || !this.list[this.activeIndex]) {
      return null;
    }
    const q = this.list[this.activeIndex];
    const cx = LEFT + this.band * this.activeIndex + this.band / 2;
    const leftPct = Math.min(86, Math.max(14, (cx / W) * 100));
    return {
      title: q.isPartial ? `${q.label} (to date)` : q.label,
      style: `left: ${leftPct}%; top: ${(COLUMNS_TOP / H) * 100}%;`,
      rows: [
        ...SERIES.map((s) => ({
          key: s.key,
          label: s.label,
          value: q[s.key],
          swatch: `background-color: ${s.color}`
        })),
        {
          key: "score",
          label: "Average score",
          value: formatScore(q.avgScore),
          swatch: "background-color: #17242b"
        }
      ]
    };
  }

  describe(q) {
    return `${q.label}: ${q.passed} passed, ${q.conditional} passed with conditions, ${q.failed} failed, average score ${formatScore(q.avgScore)}`;
  }

  handleEnter(event) {
    this.activeIndex = Number(event.currentTarget.dataset.index);
  }

  handleLeave() {
    this.activeIndex = null;
  }
}
