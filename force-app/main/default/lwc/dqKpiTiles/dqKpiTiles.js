import { LightningElement, track } from 'lwc';
import getKpis from '@salesforce/apex/DataQualityDashboardService.getKpis';

export default class DqKpiTiles extends LightningElement {
    @track invalidEmails = 0;
    @track missingRequired = 0;
    @track analysisDate;
    @track isLoading = true;

    connectedCallback() {
        this.load();
    }

    load() {
        this.isLoading = true;
        getKpis()
            .then(result => {
                this.invalidEmails = result.invalidEmails || 0;
                this.missingRequired = result.missingRequired || 0;
                this.analysisDate = result.analysisDate || '';
                this.isLoading = false;
            })
            .catch(() => {
                this.isLoading = false;
            });
    }

    refresh() {
        this.load();
        // bubble event for container to refresh children
        this.dispatchEvent(new CustomEvent('refresh'));
    }
}