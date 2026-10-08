import { LightningElement, api, wire } from "lwc";
import basePath from "@salesforce/community/basePath";
import getNationalInsights from "@salesforce/apex/InspectionInsightsController.getNationalInsights";
import getFilterOptions from "@salesforce/apex/FacilityPortalController.getFilterOptions";
import { formatDate, formatPct } from "c/inspectionStatus";

const METRICS = {
  failRate: {
    label: "Fail rate",
    heading: "Fail rate, last 12 months",
    format: "pct",
    max: 100
  },
  overdueRate: {
    label: "Overdue",
    heading: "Share of facilities overdue",
    format: "pct",
    max: 100
  },
  avgScore: {
    label: "Average score",
    heading: "Average score, last 12 months",
    format: "score",
    max: 100
  }
};

/**
 * National Insights page: public dashboards built from InspectionInsightsController.
 * Every panel follows the facility-type filter.
 */
export default class InspectionInsights extends LightningElement {
  @api heading = "National Inspection Insights";
  @api introText =
    "How licensed medical facilities across the United States are doing on their yearly inspections.";

  facilityType = "";
  metric = "failRate";
  insights;
  error;
  typeOptions = [{ label: "All facility types", value: "" }];

  @wire(getFilterOptions)
  wiredOptions({ data }) {
    if (data) {
      this.typeOptions = [
        { label: "All facility types", value: "" },
        ...data.facilityTypes
      ];
    }
  }

  @wire(getNationalInsights, { facilityType: "$facilityType" })
  wiredInsights({ data, error }) {
    if (data) {
      this.insights = data;
      this.error = undefined;
    } else if (error) {
      this.error =
        error?.body?.message || "Inspection statistics could not be loaded.";
    }
  }

  // ---------- navigation ----------

  get searchUrl() {
    return `${basePath || ""}/`;
  }

  // ---------- state ----------

  get isLoading() {
    return !this.insights && !this.error;
  }

  get asOf() {
    return formatDate(this.insights?.generatedOn);
  }

  get scopeLabel() {
    return this.facilityType
      ? `${this.facilityType} facilities`
      : "All facility types";
  }

  handleTypeChange(event) {
    this.facilityType = event.detail.value;
  }

  get metricOptions() {
    return Object.entries(METRICS).map(([value, m]) => ({
      label: m.label,
      value
    }));
  }

  get metricConfig() {
    return METRICS[this.metric];
  }

  handleMetricChange(event) {
    this.metric = event.detail.value;
  }

  // ---------- key findings ----------

  get findings() {
    const i = this.insights;
    if (!i) {
      return [];
    }
    return [
      this.trendFinding(i),
      this.deficiencyFinding(i),
      this.overdueFinding(i)
    ].filter(Boolean);
  }

  trendFinding(i) {
    const byYear = new Map();
    for (const q of i.trend || []) {
      const y = byYear.get(q.year) || { failed: 0, total: 0 };
      y.failed += q.failed;
      y.total += q.total;
      byYear.set(q.year, y);
    }
    const thisYear = new Date().getFullYear();
    const now = byYear.get(thisYear);
    const before = byYear.get(thisYear - 1);
    if (!now || !before || !now.total || !before.total) {
      return null;
    }
    const nowRate = (100 * now.failed) / now.total;
    const beforeRate = (100 * before.failed) / before.total;
    const change = nowRate - beforeRate;
    const direction =
      Math.abs(change) < 0.5
        ? "about the same as"
        : change > 0
          ? "up from"
          : "down from";
    return {
      key: "trend",
      title:
        change > 0.5
          ? "Fail rate is rising"
          : change < -0.5
            ? "Fail rate is falling"
            : "Fail rate is steady",
      text: `${formatPct(nowRate)} of inspections have failed so far in ${thisYear}, ${direction} ${formatPct(beforeRate)} in ${thisYear - 1}.`
    };
  }

  deficiencyFinding(i) {
    const top = (i.deficiencies || [])[0];
    if (!top || !top.count) {
      return null;
    }
    const next = (i.deficiencies || [])
      .slice(1, 3)
      .filter((d) => d.count)
      .map((d) => d.label.toLowerCase());
    const runnersUp = next.length
      ? ` It is followed by ${next.join(" and ")}.`
      : "";
    return {
      key: "deficiency",
      title: `${top.label} is the most-cited problem`,
      text: `${top.count} citations in the last 24 months, ${formatPct(top.pct)} of all deficiencies cited.${runnersUp}`
    };
  }

  overdueFinding(i) {
    const k = i.kpis;
    if (!k || !k.facilities) {
      return null;
    }
    const worst = (i.byType || [])
      .filter((t) => t.facilities > 0 && t.overdueRate !== null)
      .sort((a, b) => b.overdueRate - a.overdueRate)[0];
    const share = formatPct((100 * k.overdue) / k.facilities);
    const worstText =
      worst && worst.overdueRate > 0 && !this.facilityType
        ? ` ${worst.name} facilities have the highest overdue rate, at ${formatPct(worst.overdueRate)}.`
        : "";
    return {
      key: "overdue",
      title:
        k.overdue === 1
          ? "1 facility is overdue"
          : `${k.overdue} facilities are overdue`,
      text: `That is ${share} of listed facilities.${worstText} ${k.dueNext90Days} more inspections fall due in the next 90 days.`
    };
  }

  // ---------- panels ----------

  get attentionStates() {
    return (this.insights?.states || [])
      .filter((s) => s.overdue + s.failing > 0)
      .sort(
        (a, b) =>
          b.overdue + b.failing - (a.overdue + a.failing) ||
          a.name.localeCompare(b.name)
      )
      .slice(0, 8)
      .map((s) => ({
        key: s.code,
        name: s.name,
        href: `${this.searchUrl}?state=${encodeURIComponent(s.name)}`,
        detail: `${s.overdue} overdue · ${s.failing} failing of ${s.facilities}`
      }));
  }

  get hasAttentionStates() {
    return this.attentionStates.length > 0;
  }

  get deficiencyItems() {
    return (this.insights?.deficiencies || []).map((d) => ({
      label: d.label,
      value: d.count,
      note: d.count ? `(${formatPct(d.pct)})` : null
    }));
  }

  get agingItems() {
    return (this.insights?.overdueAging || []).map((d) => ({
      label: d.label,
      value: d.count
    }));
  }

  get typeItems() {
    return (this.insights?.byType || []).map((g) => ({
      label: g.name,
      value: g[this.metric]
    }));
  }

  get regionItems() {
    return (this.insights?.byRegion || []).map((g) => ({
      label: g.name,
      value: g[this.metric]
    }));
  }

  get typeChartLabel() {
    return `${this.metricConfig.heading}, by facility type`;
  }

  get regionChartLabel() {
    return `${this.metricConfig.heading}, by region`;
  }
}
