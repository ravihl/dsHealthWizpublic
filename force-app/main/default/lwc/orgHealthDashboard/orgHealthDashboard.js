// orgHealthDashboard.js
import { LightningElement, track } from 'lwc';

export default class OrgHealthDashboard extends LightningElement {
    @track activeTab = 'overview';
    @track isLoading = false;
    @track lastUpdated = '';
    
    ltabs = [
        { label: 'Overview', name: 'overview', icon: 'utility:page' },
        { label: 'Governor Limits', name: 'limits', icon: 'utility:resource_capacity' },
        { label: 'API Usage', name: 'api', icon: 'utility:connected_apps' },
        { label: 'Storage', name: 'storage', icon: 'utility:database' },
        { label: 'Performance', name: 'performance', icon: 'utility:chart' },
        { label: 'Integrations', name: 'integrations', icon: 'utility:integration' },
        { label: 'Data Quality', name: 'quality', icon: 'utility:check' },
        { label: 'Alerts', name: 'alerts', icon: 'utility:notification' },
        { label: 'Settings', name: 'settings', icon: 'utility:settings' }
    ];

    get activeTabLabel() {
        const vtab = this.ltabs.find(t => t.name === this.activeTab);
        return vtab ? vtab.label : '';
    }

    get isOverviewTab() { return this.activeTab === 'overview'; }
    get isLimitsTab() { return this.activeTab === 'limits'; }
    get isApiTab() { return this.activeTab === 'api'; }
    get isStorageTab() { return this.activeTab === 'storage'; }
    get isPerformanceTab() { return this.activeTab === 'performance'; }
    get isIntegrationsTab() { return this.activeTab === 'integrations'; }
    get isDataQualityTab() { return this.activeTab === 'quality'; }
    get isAlertsTab() { return this.activeTab === 'alerts'; }
    get isSettingsTab() { return this.activeTab === 'settings'; }

    handleTabChange(event) {
        this.activeTab = event.target.value;
        this.refreshData();
    }

    async refreshData() {
        console.log('Refreshing data for tab:', this.activeTab);
        this.isLoading = true;
        try {
            // Refresh all child components
            this.template.querySelectorAll('[ondatarefresh]').forEach(component => {
                if (component.refreshData) {
                    component.refreshData();
                }
            });
            this.lastUpdated = new Date().toLocaleString();
        } catch (error) {
            console.error('Error refreshing data:', error);
        } finally {
            this.isLoading = false;
        }
    }

    handleExport() {
        // Implement export functionality
        console.log('Export functionality to be implemented');
    }

    toggleDarkMode() {
        // Implement dark mode toggle
        console.log('Dark mode toggle to be implemented');
    }

    handleSettingsChange(event) {
        // Handle settings changes from settings component
        console.log('Settings changed:', event.detail);
    }

    connectedCallback() {
    }
}