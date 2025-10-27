// apiUsageTracker.js
import { LightningElement, track, wire } from 'lwc';
import getAPIUsage from '@salesforce/apex/APIUsageService.getAPIUsageStats';
import chartjs from '@salesforce/resourceUrl/chartjs';
import { loadScript } from 'lightning/platformResourceLibrary';

export default class ApiUsageTracker extends LightningElement {
    @track apiUsageData = {};
    @track dailyUsagePercentage = 0;
    @track chartInitialized = false;
    chart;

    @wire(getAPIUsage)
    wiredAPIUsage({ data, error }) {
        if (data) {
            this.apiUsageData = data;
            this.dailyUsagePercentage = (data.dailyUsed / data.dailyLimit * 100).toFixed(2);
            this.renderChart();
        } else if (error) {
            console.error('Error loading API usage:', error);
        }
    }

    renderedCallback() {
        if (this.chartInitialized) {
            return;
        }
        this.chartInitialized = true;

        loadScript(this, chartjs)
            .then(() => {
                this.renderChart();
            })
            .catch(error => {
                console.error('Error loading Chart.js:', error);
            });
    }

    renderChart() {
        if (!this.chartInitialized || !this.apiUsageData.hourlyBreakdown) {
            return;
        }

        const ctx = this.template.querySelector('canvas.api-chart').getContext('2d');

        if (this.chart) {
            this.chart.destroy();
        }

        this.chart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: this.apiUsageData.hourlyBreakdown.map(h => h.hour),
                datasets: [{
                    label: 'API Calls',
                    data: this.apiUsageData.hourlyBreakdown.map(h => h.count),
                    borderColor: 'rgb(0, 112, 210)',
                    backgroundColor: 'rgba(0, 112, 210, 0.1)',
                    tension: 0.4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: true,
                        position: 'top'
                    },
                    tooltip: {
                        enabled: true
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
    }

    get usageStatusClass() {
        if (this.dailyUsagePercentage >= 90) return 'critical';
        if (this.dailyUsagePercentage >= 75) return 'warning';
        return 'healthy';
    }
}