/**
 * Created by Bogdan_Krasun on 15.12.2022.
 */

public with sharing class MaintenanceRequestHelper {

    public static void createNewMaintenanceRequest(List<Case> mRequests) {
//        try {
            List<Case> currentMaintenanceRequests = [SELECT Id, Vehicle__c, (SELECT Id, Equipment__c, Quantity__c, Maintenance_Cycle_Days__c FROM Equipment_Maintenance_Items__r) FROM Case WHERE Id IN :mRequests];

            for (Case mr : currentMaintenanceRequests) {
                Decimal cycleDays = 365;
                for (Equipment_Maintenance_Item__c item : mr.Equipment_Maintenance_Items__r) {
                    cycleDays = item.Maintenance_Cycle_Days__c < cycleDays ? item.Maintenance_Cycle_Days__c : cycleDays;
                }
                mr.Date_Due__c = System.today() + Integer.valueOf(cycleDays);
            }

            Map <Id, Case> oldCaseToNewCaseMap = new Map<Id, Case>();
            List<Equipment_Maintenance_Item__c> maintenanceItems = [
                    SELECT Id, Maintenance_Request__c, Quantity__c, Equipment__c
                    FROM Equipment_Maintenance_Item__c
                    WHERE Maintenance_Request__c IN :currentMaintenanceRequests
            ];
            for (Case mRequest : currentMaintenanceRequests) {
                oldCaseToNewCaseMap.put(mRequest.Id, new Case(Type = 'Routine Maintenance', Vehicle__c = mRequest.Vehicle__c,
                        Date_Reported__c = System.today(), Date_Due__c = mRequest.Date_Due__c));
            }
            insert oldCaseToNewCaseMap.values();

            for (Equipment_Maintenance_Item__c item : maintenanceItems) {
                Id requestId = oldCaseToNewCaseMap.get(item.Maintenance_Request__c).Id;
                item.Id = null;
                item.Maintenance_Request__c = requestId;
            }
            insert maintenanceItems;

//        } catch (Exception ex) {
//            CustomLogger.error(CustomLogger.MAIN_PROJECT_NAME, ex);
//            System.debug('ERROR: ' + ex.getMessage() + '\nStack Trace:\n' + ex.getStackTraceString());
//            throw ex;
//        } finally {
//            CustomLogger.save();
//        }
    }
}