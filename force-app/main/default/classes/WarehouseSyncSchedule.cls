public with sharing class WarehouseSyncSchedule implements Schedulable {
    public static String CRON_EXP = '0 0 1 * * ?';
    // implement scheduled code here

    public void execute(SchedulableContext param1) {
        System.enqueueJob(new WarehouseCalloutService());
    }
}