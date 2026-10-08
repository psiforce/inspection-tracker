import { LightningElement, api } from "lwc";
import { formatPct, formatScore, formatCount } from "c/inspectionStatus";

/** Headline numbers for the National Insights page. */
export default class InsightsKpiTiles extends LightningElement {
  /** Kpis DTO from InspectionInsightsController. */
  @api kpis;

  get tiles() {
    const k = this.kpis;
    if (!k) {
      return [];
    }
    return [
      {
        key: "compliant",
        label: "Facilities compliant",
        value: formatPct(k.compliantPct),
        detail: `of ${formatCount(k.facilities)} listed facilities`,
        cls: "tile tile_ok"
      },
      {
        key: "overdue",
        label: "Overdue for inspection",
        value: formatCount(k.overdue),
        detail: `${formatPct(k.facilities ? (100 * k.overdue) / k.facilities : 0)} of facilities`,
        cls: "tile tile_overdue"
      },
      {
        key: "failing",
        label: "Currently failing",
        value: formatCount(k.failing),
        detail: "awaiting re-inspection",
        cls: "tile tile_bad"
      },
      {
        key: "failRate",
        label: "Fail rate",
        value: formatPct(k.failRateLast12Months),
        detail: `of ${formatCount(k.inspectionsLast12Months)} inspections, last 12 months`,
        cls: "tile"
      },
      {
        key: "score",
        label: "Average score",
        value: formatScore(k.avgScoreLast12Months),
        detail: "out of 100, last 12 months",
        cls: "tile"
      },
      {
        key: "due",
        label: "Due in the next 90 days",
        value: formatCount(k.dueNext90Days),
        detail: `${formatCount(k.completedThisYear)} completed so far this year`,
        cls: "tile"
      }
    ];
  }
}
