/**
 * Copyright © 2017 Salesforce
 * This class tests the generic custom logger class.
 */
@IsTest
class CustomLoggerTest {
    /**
     * Method that test Name of logger and they messages
     */
    @IsTest
    static void insertSingleMessageLog() {
        Test.startTest();
        List<CustomLogger.messageToLog> listOfMessages = new List<CustomLogger.messageToLog>();
        CustomLogger.messageToLog infoMessage = new CustomLogger.messageToLog();
        CustomLogger.messageToLog warningMessage = new CustomLogger.messageToLog();
        CustomLogger.messageToLog errorMessage = new CustomLogger.messageToLog();
        CustomLogger.messageToLog untypedMessage = new CustomLogger.messageToLog();

        infoMessage.infoLog = true;
        infoMessage.message = 'INFO MESSAGE';
        infoMessage.projectName = CustomLogger.MAIN_PROJECT_NAME;
        listOfMessages.add(infoMessage);

        warningMessage.warningLog = true;
        warningMessage.message = 'WARNING MESSAGE';
        warningMessage.projectName = CustomLogger.MAIN_PROJECT_NAME;
        listOfMessages.add(warningMessage);

        errorMessage.errorLog = true;
        errorMessage.message = 'ERROR MESSAGE';
        errorMessage.projectName = CustomLogger.MAIN_PROJECT_NAME;
        listOfMessages.add(errorMessage);

        untypedMessage.message = 'UNTYPED MESSAGE';
        untypedMessage.projectName = CustomLogger.MAIN_PROJECT_NAME;
        listOfMessages.add(untypedMessage);

        CustomLogger.logSingleMessage(listOfMessages);

        Test.stopTest();
        Test.getEventBus().deliver();

        List<Custom_Log__c> logs = [
                SELECT Id, Name
                FROM Custom_Log__c
        ];
        System.assert(!logs.isEmpty());

    }

    /**
     * Method that test info logger
     */
    @IsTest
    static void insertInfoLog() {
        Test.startTest();
        CustomLogger.info(CustomLogger.MAIN_PROJECT_NAME, 'INFO MESSAGE', 'TestClass', 'TestMethod');
        CustomLogger.save();
        Test.stopTest();
        Test.getEventBus().deliver();

        List<Custom_Log__c> logs = [
                SELECT Id, Name
                FROM Custom_Log__c
        ];
        System.assert(!logs.isEmpty());
    }

    /**
     * Method that test warning logger
     */
    @IsTest
    static void insertWarningLog() {
        Test.startTest();
        CustomLogger.warning(CustomLogger.MAIN_PROJECT_NAME, 'WARNING MESSAGE', 'TestClass', 'TestMethod');
        CustomLogger.save();
        Test.stopTest();
        Test.getEventBus().deliver();

        List<Custom_Log__c> logs = [
                SELECT Id, Name
                FROM Custom_Log__c
        ];
        System.assert(!logs.isEmpty());
    }

    /**
     * Method that test error logger
     */
    @IsTest
    static void insertErrorLog() {
        Test.startTest();
        CustomLogger.error(CustomLogger.MAIN_PROJECT_NAME, 'ERROR MESSAGE', 'TestClass', 'TestMethod');
        CustomLogger.save();
        Test.stopTest();
        Test.getEventBus().deliver();

        List<Custom_Log__c> logs = [
                SELECT Id, Name
                FROM Custom_Log__c
        ];
        System.assert(!logs.isEmpty());
    }

    /**
     * Method that test exception
     */
    @IsTest
    static void insertExceptionLog() {
        Test.startTest();
        try {
            insert new Lead();
        } catch (DmlException ex) {
            CustomLogger.error(CustomLogger.MAIN_PROJECT_NAME, ex);
        }
        CustomLogger.save();
        Test.stopTest();
        Test.getEventBus().deliver();

        List<Custom_Log__c> logs = [
                SELECT Id, Name
                FROM Custom_Log__c
        ];
        System.assert(!logs.isEmpty());

    }
    /**
     * Test main project insert log
     */
    @IsTest
    static void mainProjectInsertExceptionLog() {
        Test.startTest();
        CustomLogger.error(CustomLogger.MAIN_PROJECT_NAME, 'ERROR MESSAGE', 'TestClass', 'TestMethod');
        CustomLogger.save();
        Test.stopTest();
        Test.getEventBus().deliver();

        List<Custom_Log__c> logs = [
                SELECT Id, Name
                FROM Custom_Log__c
        ];
        System.assert(!logs.isEmpty());
    }
    /**
     * Test when dml operation failed for sending email
     */
    @IsTest
    static void failDMLOperationOnLogSendEmail() {
        Group emailGroup = [
                SELECT Id
                FROM Group
                WHERE DeveloperName = :CustomLogger.CUSTOM_LOG_ADMINS_GROUP_API_NAME
                LIMIT 1
        ];

        GroupMember gm = new GroupMember();
        gm.GroupId = emailGroup.Id;
        gm.UserOrGroupId = UserInfo.getUserId();
        Database.insert(gm);

        Test.startTest();
        try {
            List<Database.Error> errors = new List<Database.Error>();
            CustomLogger.sendErrorEmail(errors);
        } catch (System.EmailException e) {
            //This org is not permitted to send emails.
        }

        Test.stopTest();
        Test.getEventBus().deliver();

        List<Custom_Log__c> logs = [
                SELECT Id
                FROM Custom_Log__c
        ];
        System.assert(logs.isEmpty());
    }
}