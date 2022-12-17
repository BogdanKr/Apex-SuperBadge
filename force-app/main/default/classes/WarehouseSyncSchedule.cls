public with sharing class WarehouseSyncSchedule implements Schedulable{
    // implement scheduled code here

    public void execute(SchedulableContext param1) {
        System.enqueueJob(new WarehouseCalloutService());
    }
}