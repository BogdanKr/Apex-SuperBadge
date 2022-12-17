public with sharing class WarehouseCalloutService implements Queueable, Database.AllowsCallouts {

    private static final String WAREHOUSE_URL = 'https://th-superbadge-apex.herokuapp.com/equipment';

    public void execute(QueueableContext param1) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(WAREHOUSE_URL);
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        // If the request is successful, parse the JSON response.
        if (response.getStatusCode() == 200) {
            // Deserialize the JSON string into collections of primitive data types.
//            List<Map <String, Object>> results = (List<Map<String, Object>>) JSON.deserializeUntyped(response.getBody());
            List<ExternalEquipment> results = (List<ExternalEquipment>) JSON.deserialize(response.getBody(), List<ExternalEquipment>.class);
            System.debug('Received the following:' + results);
            List<Product2> equipments = new List<Product2>();
            for (ExternalEquipment res : results) {
                equipments.add(new Product2(Replacement_Part__c = true, Cost__c = res.cost, Current_Inventory__c = res.quantity,
                        Lifespan_Months__c = res.lifespan, Maintenance_Cycle__c = res.maintenanceperiod, Warehouse_SKU__c = res.sku,
                        Name = res.name));
            }
            upsert equipments Warehouse_SKU__c;
        }
    }

    public class ExternalEquipment {
        public Boolean replacement;
        public Integer quantity;
        public String name;
        public Integer maintenanceperiod;
        public Decimal lifespan;
        public Integer cost;
        public String sku;
    }
}