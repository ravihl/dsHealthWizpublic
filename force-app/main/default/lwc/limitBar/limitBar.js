import { LightningElement, api } from 'lwc';
import { getProgressBarClass } from 'c/limitUtils';

export default class LimitBar extends LightningElement {
  @api percentage = 0;
  @api status = 'ok';

get progressStyle() {
  const pct = Math.min(Math.max(this.percentage, 0), 100);
  return `width: ${pct}%;`; // ✅ Add semicolon
}

  get progressBarClass() {
    return getProgressBarClass(this.status);
  }

get safePercentage() {
  return isNaN(this.percentage) ? 0 : Math.min(Math.max(this.percentage, 0), 100);
}

}
