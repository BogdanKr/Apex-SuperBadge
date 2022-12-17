/**
 * Created by Bogdan_Krasun on 17.12.2022.
 */
@IsTest
public with sharing class MaintenanceRequestHandlerTest {

    @TestSetup
    static void testData() {
        Case[] cases = new Case[]{};
        for (Integer i = 0; i < 10; i++) {
            cases.add(new Case(Status = 'New', Origin = 'Phone', Type = 'Other'));
        }
        insert cases;
    }
    @IsTest
    static void testOnInsert() {
        System.assertEquals(false, getCases().isEmpty());
    }
    @IsTest
    static void testOnUpdate() {
        Case[] cases = new Case[]{};
        for (Case c : getCases()) {
            cases.add(new Case(Id = c.Id, Origin = 'Web'));
        }
        update cases;
        System.assertEquals(10, [SELECT Id FROM Case WHERE Origin LIKE '%Web%'].size());
    }
    @IsTest
    static void testOnDelete() {
        delete getCases();
        System.assertEquals(true, getCases().isEmpty());
    }
    static Case[] getCases() {
        return [SELECT Id, Status, Type  FROM Case];
    }

    @IsTest
    static void getClosedRepairOrRoutineMaintenanceCasesTest(){
        List<Case> cases = getCases();
        cases.get(0).Type = 'Repair';
        cases.get(1).Type = 'Routine Maintenance';
        cases.get(1).Status = 'Closed';

        cases = MaintenanceRequestHandler.getClosedRepairOrRoutineMaintenanceCases(cases);

        System.assertEquals(1, cases.size());
    }
}