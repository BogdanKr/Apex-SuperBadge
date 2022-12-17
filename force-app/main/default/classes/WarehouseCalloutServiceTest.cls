@IsTest
private class WarehouseCalloutServiceTest {

    @TestSetup
    static void setupData() {
        List<Product2> newProducts = new List<Product2>{
                new Product2(Name = 'Name 1', Warehouse_SKU__c = '100003'), new Product2(Name = 'Name 2', Warehouse_SKU__c = '100004'),
                new Product2(Name = 'Name 3', Warehouse_SKU__c = '100005')
        };
        insert newProducts;
    }
    // implement your mock callout test here
    @IsTest
    static void testGetCallout() {
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock());
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock.
        Test.startTest();
        System.enqueueJob(new WarehouseCalloutService());
        Test.stopTest();

        System.assertEquals(2, [SELECT Id FROM Product2 WHERE Replacement_Part__c = TRUE].size());

    }
}