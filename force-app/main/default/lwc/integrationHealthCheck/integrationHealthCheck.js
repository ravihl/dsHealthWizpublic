import { LightningElement, wire, track } from "lwc";
import getIntegrationStatus from '@salesforce/apex/IntegrationHealthController.getIntegrationStatus';


export default class IntegrationHealthCheck extends LightningElement {
  @track rows = [];
  @track isLoading = false;

  columns = [
    { label: "Name", fieldName: "Name", type: "text" },
    { label: "System", fieldName: "System__c", type: "text" },
    { label: "Status", fieldName: "Status__c", type: "badge" },
    { label: "Last Checked", fieldName: "Last_Checked__c", type: "date" },
    { label: "Message", fieldName: "Message__c", type: "text" }
  ];

  connectedCallback() {
    this.refresh();
  }

  @wire(getIntegrationStatus)
  wiredStatuses({ data, error }) {
    if (data) {
      this.rows = data;
    } else if (error) {
      // eslint-disable-next-line no-console
      console.error("IntegrationHealthCheck wire error", error);
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
