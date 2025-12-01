import { LightningElement, api, track } from 'lwc';
import getTrendData from '@salesforce/apex/DataQualityDashboardService.getTrendData';

export default class DqTrendChart extends LightningElement {
    @api daysBack = 30;
    @api objectApiName = '';
    @api metricName = '';
    @track isLoading = true;

    connectedCallback() {
        this.load();
    }

    // expose load so container can call refresh
    @api load() {
        this.isLoading = true;
        getTrendData({ daysBack: this.daysBack, objectApiName: this.objectApiName, metricName: this.metricName })
            .then(data => {
                this.isLoading = false;
                this.renderChart(data);
            })
            .catch(() => {
                this.isLoading = false;
                const container = this.template.querySelector('[data-chart]');
                if (container) container.innerHTML = '<div>No trend data</div>';
            });
    }

    renderChart(data) {
        const container = this.template.querySelector('[data-chart]');
        if (!container) return;
        container.innerHTML = '';

        // aggregate totals per date
        const map = new Map();
        data.forEach(d => {
            const dateKey = (new Date(d.date)).toISOString().substring(0,10);
            map.set(dateKey, (map.get(dateKey) || 0) + d.total);
        });

        const labels = Array.from(map.keys()).sort();
        const values = labels.map(l => map.get(l));

        if (values.length === 0) {
            container.innerHTML = '<div>No trend data</div>';
            return;
        }

        // tiny SVG line chart (same approach as earlier)
        const width = 480, height = 160, padding = 20;
        const max = Math.max(...values);
        const min = Math.min(...values);

        const svgNS = "http://www.w3.org/2000/svg";
        const svg = document.createElementNS(svgNS, 'svg');
        svg.setAttribute('viewBox', `0 0 ${width} ${height}`);
        svg.setAttribute('width', '100%');

        const stepX = (width - padding*2) / Math.max(1, labels.length - 1);
        const points = values.map((v,i) => {
            const x = padding + i * stepX;
            const y = height - padding - ((v - min) / ((max - min) || 1)) * (height - padding*2);
            return `${x},${y}`;
        }).join(' ');

        const poly = document.createElementNS(svgNS, 'polyline');
        poly.setAttribute('points', points);
        poly.setAttribute('fill', 'none');
        poly.setAttribute('stroke-width', '2');
        poly.setAttribute('stroke', '#1589EE');
        svg.appendChild(poly);

        labels.forEach((lbl, i) => {
            if (i % Math.ceil(labels.length / 6) !== 0 && i !== labels.length - 1) return;
            const text = document.createElementNS(svgNS, 'text');
            const x = padding + i * stepX;
            text.setAttribute('x', x);
            text.setAttribute('y', height - 6);
            text.setAttribute('font-size', '10');
            text.setAttribute('text-anchor', 'middle');
            text.textContent = lbl;
            svg.appendChild(text);
        });

        container.appendChild(svg);
    }
}