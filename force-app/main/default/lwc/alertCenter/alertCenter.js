import { LightningElement, wire, track } from "lwc";
import getActiveAlerts from "@salesforce/apex/AlertController.getActiveAlerts"; // TODO: Adjust if method differs

export default class AlertCenter extends LightningElement {
  @track rows = [];
  @track isLoading = false;

  columns = [
    { label: "Name", fieldName: "Name", type: "text" },
    { label: "Alert Type", fieldName: "Alert_Type__c", type: "text" },
    { label: "Severity", fieldName: "Severity__c", type: "text" },
    { label: "Threshold", fieldName: "Threshold_Value__c", type: "number" },
    { label: "Active", fieldName: "Active__c", type: "boolean" },
    { label: "Recipients", fieldName: "Notification_Recipients__c", type: "text" }
  ];

  connectedCallback() {
    this.refresh();
  }

  @wire(getActiveAlerts)
  wiredAlerts({ data, error }) {
    if (data) {
      this.rows = data;
    } else if (error) {
      // eslint-disable-next-line no-console
      console.error("AlertCenter wire error", error);
    }
  }

  get hasData() {
    return (this.rows || []).length > 0;
  }

  refresh() {
    this.isLoading = true;
    // Placeholder for refreshApex once wired result is stored
    setTimeout(() => {
      this.isLoading = false;
    }, 400);
  }
}
