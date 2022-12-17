/**
 * Created by Bogdan_Krasun on 15.12.2022.
 */

public with sharing class MaintenanceRequestHandler {

    public static void onBeforeInsert(Case[] newCases) {
    }
    public static void onBeforeUpdate(Case[] newCases, Map<Id, Case> oldCasesMap) {
    }
    public static void onBeforeDelete(Case[] oldCases) {
    }
    public static void onAfterUpdate(Case[] newCases, Map<Id, Case> oldCasesMap) {
        MaintenanceRequestHelper.createNewMaintenanceRequest(getClosedRepairOrRoutineMaintenanceCases(newCases));
    }

    @TestVisible
    private static List<Case> getClosedRepairOrRoutineMaintenanceCases(Case[] newCases) {
        List<Case> closedCases = new List<Case>();
        for (Case c : newCases) {
            if (c.Status == 'Closed' && (c.Type == 'Repair' || c.Type == 'Routine Maintenance')) {
                closedCases.add(c);
            }
        }
        return closedCases;
    }
}