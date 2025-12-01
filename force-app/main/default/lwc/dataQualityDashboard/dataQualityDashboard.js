import { LightningElement, track } from 'lwc';

export default class DataQualityDashboard extends LightningElement {
    @track metrics = ['MissingRequired','InvalidEmails','InvalidPhones'];

    handleCellClick(e) {
        // e.detail = { objectApiName, metricName }
        const payload = e.detail;
        const drill = this.template.querySelector('c-dq-drilldown-modal');
        if (drill) {
            drill.open(payload.objectApiName, payload.metricName);
        }
    }

    handleRefresh() {
        // Bubble refresh to child components if needed
        const heat = this.template.querySelector('c-dq-heatmap');
        const trend = this.template.querySelector('c-dq-trend-chart');
        if (heat) heat.refresh();
        if (trend) trend.load();
    }
}