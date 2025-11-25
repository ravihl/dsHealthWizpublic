public with sharing class APIUsageServiceScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        APIUsageService.logCurrentUsage();
    }
}
