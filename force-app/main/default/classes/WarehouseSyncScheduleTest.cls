@IsTest
public with sharing class WarehouseSyncScheduleTest {
    // implement scheduled code here
    @IsTest
    static void test() {
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock());
        Test.startTest();
        // Schedule the test job

        String jobID = System.schedule('WarehouseSyncScheduleJob', WarehouseSyncSchedule.CRON_EXP,
                new WarehouseSyncSchedule());

        // Get the information from the CronTrigger API object
        CronTrigger ct = [
                SELECT Id, CronExpression, TimesTriggered,
                        NextFireTime
                FROM CronTrigger
                WHERE Id = :jobID
        ];

        // Verify the expressions are the same
        System.assertEquals(WarehouseSyncSchedule.CRON_EXP,
                ct.CronExpression);

        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);

        // Verify the next time the job will run
        System.assertEquals('2022-12-18 01:00:00',
                String.valueOf(ct.NextFireTime));

        Test.stopTest();
    }
}