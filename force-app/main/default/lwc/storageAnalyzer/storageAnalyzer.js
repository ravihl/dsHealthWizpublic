import { LightningElement, wire, track } from "lwc";
import getLatestStorageSnapshots from '@salesforce/apex/StorageAnalyzerController.getLatestStorageSnapshots';

export default class StorageAnalyzer extends LightningElement {
  @track snapshots = [];
  @track isLoading = false;

  totalStorage = 0;
  usagePercent = 0;

  columns = [
    { label: "Snapshot Date", fieldName: "Date__c", type: "date" },
    { label: "Data Storage (MB)", fieldName: "Data_Storage_Used__c", type: "number" },
    { label: "File Storage (MB)", fieldName: "File_Storage_Used__c", type: "number" },
    { label: "Total (MB)", fieldName: "TotalMB__c", type: "number" },
    { label: "Percent Used", fieldName: "Storage_UsedP_ercentage__c", type: "percent" }
  ];

  connectedCallback() {
    this.refresh();
  }

  @wire(getLatestStorageSnapshots)
  wiredSnapshots({ data, error }) {
    if (data) {
      this.processData(data);
    } else if (error) {
      // eslint-disable-next-line no-console
      console.error("StorageAnalyzer wire error", error);
    }
  }

  processData(data) {
    const rows = (data || []).map((d) => ({
      ...d,
      TotalMB__c: (Number(d.Data_Storage_Used__c || 0) + Number(d.File_Storage_Used__c || 0)).toFixed(2),
      PercentUsed__c: Number(d.Storage_Used_Percentage__c || 0) / 100
    }));

    this.snapshots = rows;

    const totals = rows.reduce(
      (acc, r) => {
        acc.total += Number(r.TotalMB__c);
        return acc;
      },
      { total: 0 }
    );

    this.totalStorage = totals.total.toFixed(2);

    // If snapshots contain org limit info, compute usagePercent, else 0
    const latest = rows[0];
    if (latest && latest.OrgLimitMB__c) {
      const pct = (Number(latest.TotalMB__c) / Number(latest.OrgLimitMB__c)) * 100;
      this.usagePercent = Math.min(100, Math.max(0, Number(pct.toFixed(2))));
    } else {
      this.usagePercent = 0;
    }
  }

  get hasData() {
    return (this.snapshots || []).length > 0;
  }

  get isLoadingClass() {
    return this.isLoading ? "slds-hide" : "";
  }

  refresh() {
    this.isLoading = true;
    // Imperative refresh to re-invoke wire by toggling a tracked property or leveraging refreshApex if stored
    // For now, simply flip loading state; real refresh should use refreshApex with wired result
    setTimeout(() => {
      this.isLoading = false;
    }, 400);
  }
}
