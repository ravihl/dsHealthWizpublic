import { LightningElement, wire } from 'lwc';
import getDataQualityScores from '@salesforce/apex/DataQualityController.getDataQualityScores';
import chartjs from '@salesforce/resourceUrl/chartjs';
import { loadScript } from 'lightning/platformResourceLoader';

export default class DataQualitychart extends LightningElement {
    records = [];
    chart;
    chartInitialized = false;

    columns = [
        { label: 'Object', fieldName: 'Object_Name__c' },
        { label: 'Field', fieldName: 'Field__c' },
        { label: 'Record Count', fieldName: 'Record_Count__c', type: 'number' },
        { label: 'Analysis Date', fieldName: 'Analysis_Date__c', type: 'date' },
        { label: 'Notes', fieldName: 'Notes__c' }
    ];

    @wire(getDataQualityScores)
    wiredResults({ data, error }) {
        if (data) {
            this.records = data;
            this.renderChart();
        }
        if (error) {
            console.error(error);
        }
    }

    renderedCallback() {
        if (this.chartInitialized) return;
        this.chartInitialized = true;

        loadScript(this, chartjs + '/Chart.min.js')
            .then(() => this.renderChart())
            .catch(error => console.error('Error loading chartJS', error));
    }

    renderChart() {
        if (!this.records.length || typeof Chart === 'undefined') {
            return;
        }

        // Destroy existing chart for refresh
        if (this.chart) {
            this.chart.destroy();
        }

        const ctx = this.template.querySelector('canvas.dqChart');

        // LABELS → "Object – Field"
        const labels = this.records.map(
            rec => `${rec.Object_Name__c} - ${rec.Notes__c}`
        );

        // VALUES → Record_Count__c
        const values = this.records.map(rec => rec.Record_Count__c);

        this.chart = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: labels,
                datasets: [
                    {
                        label: 'Record Count',
                        data: values,
                        backgroundColor: 'rgba(54, 162, 235, 0.6)',
                        borderColor: 'rgba(54, 162, 235, 1)',
                        borderWidth: 1
                    }
                ]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: { display: false }
                },
                scales: {
                    y: { beginAtZero: true }
                }
            }
        });
    }
}