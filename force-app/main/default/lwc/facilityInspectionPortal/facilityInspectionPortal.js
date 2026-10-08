import { LightningElement, api, wire } from "lwc";
import basePath from "@salesforce/community/basePath";
import searchFacilities from "@salesforce/apex/FacilityPortalController.searchFacilities";
import getFilterOptions from "@salesforce/apex/FacilityPortalController.getFilterOptions";
import { statusPillClass, formatDate } from "c/inspectionStatus";

const SEARCH_DELAY_MS = 300;
const COMPLIANT = new Set(["Passed", "Passed with Conditions"]);
const FAILING = new Set(["Failed", "Re-inspection Required"]);

export default class FacilityInspectionPortal extends LightningElement {
  @api heading = "Medical Facility Inspections";
  @api introText =
    "Search licensed medical facilities and check the result of their most recent yearly inspection.";

  filterOptions;
  filters = { searchTerm: "", state: "", status: "", facilityType: "" };
  facilities = [];
  selectedId;
  isLoading = true;
  error;

  searchTimeout;
  requestId = 0;

  @wire(getFilterOptions)
  wiredOptions({ data, error }) {
    if (data) {
      this.filterOptions = data;
    } else if (error) {
      this.error =
        "Search filters could not be loaded. Refresh the page to try again.";
    }
  }

  connectedCallback() {
    // The National Insights state map links here with ?state=<state name>.
    const state = this.stateFromUrl();
    if (state) {
      this.filters = { ...this.filters, state };
    }
    this.loadFacilities();
  }

  stateFromUrl() {
    try {
      return new URLSearchParams(window.location.search).get("state") || "";
    } catch {
      return "";
    }
  }

  get initialState() {
    return this.filters.state;
  }

  get insightsUrl() {
    return `${basePath || ""}/insights`;
  }

  disconnectedCallback() {
    clearTimeout(this.searchTimeout);
  }

  handleFilterChange(event) {
    this.filters = { ...event.detail };
    this.selectedId = undefined;
    clearTimeout(this.searchTimeout);
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.searchTimeout = setTimeout(
      () => this.loadFacilities(),
      SEARCH_DELAY_MS
    );
  }

  async loadFacilities() {
    const requestId = ++this.requestId;
    this.isLoading = true;
    try {
      const results = await searchFacilities({ ...this.filters });
      if (requestId !== this.requestId) {
        return; // A newer search has started; drop this response.
      }
      this.facilities = results;
      this.error = undefined;
    } catch (e) {
      if (requestId === this.requestId) {
        this.facilities = [];
        this.error =
          e?.body?.message ||
          "Facilities could not be loaded. Try again in a few minutes.";
      }
    } finally {
      if (requestId === this.requestId) {
        this.isLoading = false;
      }
    }
  }

  handleFacilitySelect(event) {
    this.selectedId = event.detail.id;
  }

  handleListSelect(event) {
    this.selectedId = event.currentTarget.dataset.id;
  }

  handleDetailClose() {
    this.selectedId = undefined;
  }

  get fitToResults() {
    return Boolean(this.filters.state || this.filters.searchTerm);
  }

  get hasSelection() {
    return Boolean(this.selectedId);
  }

  get resultItems() {
    return this.facilities.map((f) => ({
      ...f,
      location: [f.city, f.state].filter(Boolean).join(", "),
      pillClass: statusPillClass(f.portalStatus),
      statusLabel: f.portalStatus || "Not Yet Inspected",
      lastLabel: f.lastInspectionDate
        ? `Last inspected ${formatDate(f.lastInspectionDate)}`
        : "Not inspected yet"
    }));
  }

  get hasResults() {
    return this.facilities.length > 0;
  }

  get showEmpty() {
    return !this.isLoading && !this.hasResults && !this.error;
  }

  get resultCountLabel() {
    const n = this.facilities.length;
    return `${n} ${n === 1 ? "facility" : "facilities"}`;
  }

  get stats() {
    let compliant = 0;
    let failing = 0;
    let overdue = 0;
    let upcoming = 0;
    for (const f of this.facilities) {
      if (COMPLIANT.has(f.portalStatus)) {
        compliant++;
      } else if (FAILING.has(f.portalStatus)) {
        failing++;
      } else if (f.portalStatus === "Overdue") {
        overdue++;
      } else {
        upcoming++;
      }
    }
    return [
      {
        key: "total",
        label: "Facilities shown",
        value: this.facilities.length,
        cls: "stat"
      },
      {
        key: "compliant",
        label: "Passed",
        value: compliant,
        cls: "stat stat_ok"
      },
      {
        key: "failing",
        label: "Failed / re-inspection",
        value: failing,
        cls: "stat stat_bad"
      },
      {
        key: "overdue",
        label: "Overdue",
        value: overdue,
        cls: "stat stat_overdue"
      },
      {
        key: "upcoming",
        label: "Scheduled / not yet inspected",
        value: upcoming,
        cls: "stat stat_info"
      }
    ];
  }
}
