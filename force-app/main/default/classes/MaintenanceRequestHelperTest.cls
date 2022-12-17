@IsTest
public with sharing class MaintenanceRequestHelperTest {
    // implement scheduled code here
    @IsTest
    public static void createNewMaintenanceRequestTest() {
        Vehicle__c v = new Vehicle__c(Name = 'Test Vehicle');
        insert v;
        Case c = new Case(Type = 'Routine Maintenance', Vehicle__c = v.Id,
                Date_Reported__c = System.today(), Date_Due__c = System.today() + 10);
        insert c;
        Equipment_Maintenance_Item__c item = new Equipment_Maintenance_Item__c(Maintenance_Request__c = c.Id);
        insert item;

        MaintenanceRequestHelper.createNewMaintenanceRequest(new List<Case>{c});

        System.assert([SELECT Id FROM Equipment_Maintenance_Item__c].size() == 2);
    }
}