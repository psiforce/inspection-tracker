import { LightningElement, api } from "lwc";
import { statusMeta, LEGEND, formatAddress } from "c/inspectionStatus";

// Geographic center of the contiguous United States.
const US_CENTER = { location: { Latitude: 39.8283, Longitude: -98.5795 } };
const US_ZOOM = 4;
// SVG circle centered on the coordinate.
const DOT_PATH = "M 0,0 m -7,0 a 7,7 0 1,0 14,0 a 7,7 0 1,0 -14,0";

export default class FacilityMap extends LightningElement {
  @api facilities = [];
  @api selectedId;
  /** True when a state or text filter is active: fit the map to the results instead of the whole US. */
  @api fitToResults = false;

  legend = LEGEND.map((item) => ({
    ...item,
    style: `background-color: ${item.color}`
  }));

  get markers() {
    return (this.facilities || [])
      .filter((f) => f.latitude != null && f.longitude != null)
      .map((f) => {
        const selected = f.id === this.selectedId;
        return {
          location: { Latitude: f.latitude, Longitude: f.longitude },
          value: f.id,
          title: f.name,
          description: `${f.facilityType || "Facility"} · ${f.portalStatus || "Not Yet Inspected"} · ${formatAddress(f)}`,
          mapIcon: {
            path: DOT_PATH,
            fillColor: statusMeta(f.portalStatus).color,
            fillOpacity: selected ? 1 : 0.85,
            strokeColor: "#ffffff",
            strokeWeight: selected ? 3 : 1.5,
            scale: selected ? 1.4 : 1
          }
        };
      });
  }

  get hasMarkers() {
    return this.markers.length > 0;
  }

  get center() {
    return this.fitToResults ? undefined : US_CENTER;
  }

  get zoomLevel() {
    return this.fitToResults ? undefined : US_ZOOM;
  }

  handleMarkerSelect(event) {
    const id = event.detail.selectedMarkerValue;
    if (id) {
      this.dispatchEvent(new CustomEvent("facilityselect", { detail: { id } }));
    }
  }
}
