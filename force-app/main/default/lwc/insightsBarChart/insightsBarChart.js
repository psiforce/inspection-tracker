import { LightningElement, api } from "lwc";
import {
  BAR_COLOR,
  formatPct,
  formatScore,
  formatCount,
  niceMax
} from "c/inspectionStatus";

const FORMATTERS = { pct: formatPct, score: formatScore, count: formatCount };

/**
 * Horizontal bar chart for one measure. Bars start at a zero baseline; every bar carries
 * its value as a direct label (at most ~10 bars). A screen-reader table mirrors the data.
 */
export default class InsightsBarChart extends LightningElement {
  /** [{ label, value, note? }] - value may be null ("no data"). */
  @api items = [];
  /** 'pct' | 'score' | 'count' */
  @api format = "count";
  /** Fixed axis maximum (e.g. 100 for rates); defaults to a nice max of the data. */
  @api max;
  @api chartLabel = "";
  @api valueHeading = "Value";

  get formatter() {
    return FORMATTERS[this.format] || formatCount;
  }

  get axisMax() {
    if (this.max) {
      return Number(this.max);
    }
    const values = (this.items || []).map((i) => i.value || 0);
    return niceMax(Math.max(0, ...values));
  }

  get rows() {
    const max = this.axisMax;
    return (this.items || []).map((item, index) => {
      const hasValue = item.value !== null && item.value !== undefined;
      const width = hasValue
        ? Math.max(0, Math.min(100, (item.value / max) * 100))
        : 0;
      return {
        key: `${index}-${item.label}`,
        label: item.label,
        display: hasValue ? this.formatter(item.value) : "No data",
        note: item.note,
        hasValue,
        barStyle: `width: ${width}%; background-color: ${BAR_COLOR};`,
        valueClass: hasValue ? "bars__value" : "bars__value bars__value_empty"
      };
    });
  }

  get hasRows() {
    return this.rows.length > 0;
  }
}
