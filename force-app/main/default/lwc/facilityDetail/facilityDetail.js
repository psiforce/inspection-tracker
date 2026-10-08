import { LightningElement, api, wire } from "lwc";
import getFacilityDetail from "@salesforce/apex/FacilityPortalController.getFacilityDetail";
import {
  statusPillClass,
  formatDate,
  dueLabel,
  formatAddress
} from "c/inspectionStatus";

export default class FacilityDetail extends LightningElement {
  @api facilityId;

  facility;
  error;

  @wire(getFacilityDetail, { facilityId: "$facilityId" })
  wiredDetail({ data, error }) {
    if (data) {
      this.facility = data;
      this.error = undefined;
    } else if (error) {
      this.facility = undefined;
      this.error = error?.body?.message || "This facility could not be loaded.";
    }
  }

  get isLoading() {
    return !this.facility && !this.error;
  }

  get statusClass() {
    return statusPillClass(this.facility?.portalStatus);
  }

  get statusLabel() {
    return this.facility?.portalStatus || "Not Yet Inspected";
  }

  get address() {
    return formatAddress(this.facility);
  }

  get lastInspection() {
    return formatDate(this.facility?.lastInspectionDate);
  }

  get nextDue() {
    return formatDate(this.facility?.nextInspectionDue);
  }

  get nextDueHint() {
    return dueLabel(this.facility?.nextInspectionDue);
  }

  get history() {
    return (this.facility?.inspections || []).map((item) => ({
      ...item,
      pillClass: statusPillClass(item.status),
      dateLabel: item.completedDate
        ? `Completed ${formatDate(item.completedDate)}`
        : `Scheduled ${formatDate(item.scheduledDate)}`,
      scoreLabel: item.score != null ? `Score ${item.score}/100` : null
    }));
  }

  get hasHistory() {
    return this.history.length > 0;
  }

  handleBack() {
    this.dispatchEvent(new CustomEvent("close"));
  }
}
