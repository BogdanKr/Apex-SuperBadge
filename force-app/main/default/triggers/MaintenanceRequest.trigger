/**
 * Created by Bogdan_Krasun on 15.12.2022.
 */

trigger MaintenanceRequest on Case (before insert, before update, after insert, after update, before delete ) {

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            MaintenanceRequestHandler.onBeforeInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            MaintenanceRequestHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
        if (Trigger.isDelete) {
            MaintenanceRequestHandler.onBeforeDelete(Trigger.old);
        }
    }
    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            MaintenanceRequestHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}