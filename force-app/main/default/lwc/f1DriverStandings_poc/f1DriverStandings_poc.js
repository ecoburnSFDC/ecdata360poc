import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getDriverStandings from '@salesforce/apex/F1DriverStandingsController_poc.getDriverStandings';

const TOP_N = 5;

export default class F1DriverStandings_poc extends NavigationMixin(LightningElement) {
    drivers = [];
    error = null;
    loading = true;

    @wire(getDriverStandings)
    wiredStandings({ data, error }) {
        this.loading = false;
        if (data) {
            this.drivers = data;
            this.error = null;
        } else if (error) {
            this.error = error;
            this.drivers = [];
        }
    }

    get isLoading() {
        return this.loading;
    }

    get hasError() {
        return !this.loading && this.error != null;
    }

    get hasDrivers() {
        return !this.loading && !this.error && this.drivers.length > 0;
    }

    get topDrivers() {
        return this.drivers.slice(0, TOP_N);
    }

    get errorMessage() {
        return this.error?.body?.message ?? 'Failed to load standings.';
    }

    handleViewAll() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: 'https://www.formula1.com/en/results/driver-standings'
            }
        });
    }
}