import { LightningElement, api } from "lwc";

const ALL = { label: "All", value: "" };

export default class FacilitySearchFilters extends LightningElement {
  @api options;

  searchTerm = "";
  state = "";
  status = "";
  facilityType = "";

  get stateOptions() {
    return [{ ...ALL, label: "All states" }, ...(this.options?.states || [])];
  }

  get statusOptions() {
    return [
      { ...ALL, label: "All statuses" },
      ...(this.options?.statuses || [])
    ];
  }

  get typeOptions() {
    return [
      { ...ALL, label: "All facility types" },
      ...(this.options?.facilityTypes || [])
    ];
  }

  get hasActiveFilters() {
    return Boolean(
      this.searchTerm || this.state || this.status || this.facilityType
    );
  }

  get clearDisabled() {
    return !this.hasActiveFilters;
  }

  handleSearch(event) {
    this.searchTerm = event.target.value;
    this.notify();
  }

  handleState(event) {
    this.state = event.detail.value;
    this.notify();
  }

  handleStatus(event) {
    this.status = event.detail.value;
    this.notify();
  }

  handleType(event) {
    this.facilityType = event.detail.value;
    this.notify();
  }

  handleClear() {
    this.searchTerm = "";
    this.state = "";
    this.status = "";
    this.facilityType = "";
    this.notify();
  }

  notify() {
    this.dispatchEvent(
      new CustomEvent("filterchange", {
        detail: {
          searchTerm: this.searchTerm,
          state: this.state,
          status: this.status,
          facilityType: this.facilityType
        }
      })
    );
  }
}
