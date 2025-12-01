import { LightningElement, api, track } from 'lwc';
import getKpis from '@salesforce/apex/DataQualityDashboardService.getKpis';

export default class DqHeatmap extends LightningElement {
    @api metrics = ['MissingRequired','InvalidEmails','InvalidPhones'];
    @track objects = ['Account','Contact','Lead','Opportunity'];
    @track dataMap = {};
    @track isLoading = true;

    connectedCallback() {
        this.loadData();
    }

    // internal loader
    loadData() {
        this.isLoading = true;
        getKpis()
            .then(result => {
                this.dataMap = result.perObject || {};
                this.isLoading = false;
            })
            .catch(() => {
                this.isLoading = false;
                this.dataMap = {};
            });
    }

    // exposed API method for parent to refresh
    @api refresh() {
        this.loadData();
    }

    getCellValue(obj, metric) {
        const key = obj + '#' + metric;
        return this.dataMap[key] ? this.dataMap[key] : 0;
    }

    getCellClass(obj, metric) {
        const val = Number(this.getCellValue(obj, metric));
        if (val === 0) return 'cell-green';
        if (val > 0 && val < 5) return 'cell-yellow';
        return 'cell-red';
    }

    onCellClick(evt) {
        const obj = evt.currentTarget.dataset.object;
        const metric = evt.currentTarget.dataset.metric;
        this.dispatchEvent(new CustomEvent('cellclick', {
            detail: { objectApiName: obj, metricName: metric },
            bubbles: true
        }));
    }
}