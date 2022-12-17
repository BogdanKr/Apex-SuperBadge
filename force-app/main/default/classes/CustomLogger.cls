/**
 * Copyright © 2017 Salesforce
 * Class to be used to persist custom logs (via the Custom_Log__c object) in Salesforce
 *        Example of a info implementation :
 *        CustomLogger.info(CustomLogger.MAIN_PROJECT_NAME, 'Transaction was successful');
 *
 *        Example of logging an error :
 *        try
 *        {
 *        // do something
 *        }
 *        catch (Exception ex)
 *        {
 *            CustomLogger.error(CustomLogger.MAIN_PROJECT_NAME, ex);
 *        }
 *
 *        When all events have been logged, always call save prior to execution end, logs
 *        will only exist for the extent of the session in which they are initiated.
 *
 *        CustomLogger.save();
 */
public without sharing class CustomLogger {

    // **********************   LOGGER SETUP ************************************
    // **************************************************************************

    //Admins groups api name for emails in case DML operation failed on Custom Log.
    @TestVisible
    private static final String CUSTOM_LOG_ADMINS_GROUP_API_NAME = 'Custom_Log_Admins';


    // Project Names
    // - Please add additional project names here and then use the new constant
    // - NO STRINGS IN THE ACTUAL METHODS!
    // - this is so if you wish to change the actual Project label,
    //   you can do so in one place.
    public static final String MAIN_PROJECT_NAME = 'Salesforce Project';


    // Log types
    // - If you want to add more log types (such as Info etc...)
    //   please do so here and then reference the new constant in the methods
    // - NO STRINGS IN THE ACTUAL METHODS!
    // - Best practice is to also add the new value to the picklist on
    //   the Custom Log object Custom_Log__c.Type__c
    @TestVisible private static final String LOG_TYPE_INFO    = 'Info';
    @TestVisible private static final String LOG_TYPE_WARNING = 'Warning';
    @TestVisible private static final String LOG_TYPE_ERROR   = 'Error';

    // **************************************************************************
    // **************************************************************************


    private static List<Logger__e> CUSTOM_LOG_CACHE = new List<Logger__e>();


    public class messageToLog {

        @InvocableVariable(Label='Project Name' Description='Project Name or Label. If unsure what to put here, leave blank.')
        public String projectName;

        @InvocableVariable(Required=true Label='Message to Log')
        public String message;

        @InvocableVariable(Required=true Label='Name of apex class' Description='Name of the apex class that sent the message')
        public String className;

        @InvocableVariable(Required=true Label='Name of apex method' Description='Name of the method of the apex class that sent the message')
        public String methodName;

        @InvocableVariable(Required=true Label='This is an INFO Message')
        public Boolean infoLog = false;

        @InvocableVariable(Required=true Label='This is an WARNING Message')
        public Boolean warningLog = false;

        @InvocableVariable(Required=true Label='This is an ERROR Message')
        public Boolean errorLog = false;
    }

    /**
     * get a list and insert them to database according to their type
     *
     * @param listOfMessages The messages to log
     */
    @InvocableMethod(Label='Log Message')
    public static void logSingleMessage(List<messageToLog> listOfMessages) {
        String projectName = '';

        for (messageToLog singleMessage : listOfMessages) {

            if (String.isBlank(singleMessage.projectName)) {
                projectName = CustomLogger.MAIN_PROJECT_NAME;
            } else {
                projectName = singleMessage.projectName;
            }

            if (singleMessage.infoLog) {
                info(projectName, singleMessage.message, singleMessage.className, singleMessage.methodName);
            }

            if (singleMessage.warningLog) {
                warning(projectName, singleMessage.message, singleMessage.className, singleMessage.methodName);
            }

            if (singleMessage.errorLog) {
                error(projectName, singleMessage.message, singleMessage.className, singleMessage.methodName);
            }

            if (!singleMessage.errorLog && !singleMessage.warningLog && !singleMessage.infoLog) {
                log(projectName, '', singleMessage.message, singleMessage.className, singleMessage.methodName);
            }

        }

        CustomLogger.save();
    }

    /**
     * log an info type message
     *
     * @param projectName Name of the project to log
     * @param message Event description
     * @param className The name of the class that fired this event
     * @param methodName The name of the method that fired this event
     */
    public static void info(String projectName,
            String message,
            String className,
            String methodName) {
        log(projectName, CustomLogger.LOG_TYPE_INFO, message, className, methodName);
    }

    /**
     * log a warning type message
     *
     * @param projectName Name of the project to log
     * @param message Event description
     * @param className The name of the class that fired this event
     * @param methodName The name of the method that fired this event
     */
    public static void warning(String projectName,
            String message,
            String className,
            String methodName) {
        log(projectName, CustomLogger.LOG_TYPE_WARNING, message, className, methodName);
    }

    /**
     * log an error type message
     *
     * @param projectName Name of the project to log
     * @param message Event description
     * @param className The name of the class that fired this event
     * @param methodName The name of the method that fired this event
     */
    public static void error(String projectName,
            String message,
            String className,
            String methodName) {
        log(projectName, CustomLogger.LOG_TYPE_ERROR, message, className, methodName);
    }

    /**
     * log an error type message + exception info
     *
     * @param projectName Name of the project to log
     * @param ex Exception to log
     */
    public static void error(String projectName, Exception ex) {
        String[] errorData = CustomLogger.extractClassAndMethodName(ex);
        error(
                projectName,
                ex.getMessage() + '; ' + ex.getTypeName() + '; ' + ex.getStackTraceString(),
                errorData[0],
                errorData[1]
        );
    }

    /**
     * Save cached logs.
     * Persists logs for current transaction.
     */
    public static void save() {
        CustomLogger.save(CustomLogger.CUSTOM_LOG_CACHE);
        CustomLogger.CUSTOM_LOG_CACHE.clear();
    }

    /**
     * Persists logs for current transaction, used from platform event trigger.
     */
    public static void save(List<Logger__e> loggerEvents) {
        if (!loggerEvents.isEmpty()) {
            List<Database.SaveResult> results = EventBus.publish(loggerEvents);
            for (Database.SaveResult result : results) {
                if (!result.isSuccess()) {
                    CustomLogger.sendErrorEmail(result.getErrors());
                }
            }
        }
    }

    /**
     * Create and populate a new Custom_Log__c object and add it to the static list that will be inserted at the end of a transaction
     *
     * @param projectName Project name to log
     * @param logType Type of the log event (choosen from the LOG_TYPE constants)
     * @param message Event description
     * @param className The name of the class that fired this event
     * @param methodName The name of the method that fired this event
     */
    private static void log(String projectName,
            String logType,
            String message,
            String className,
            String methodName) {
        Logger__e log = new Logger__e();

        // Do logging that is generic enough
        // to be applicable to all projects
        log.Project_Name__c = projectName;
        log.Time_Stamp__c = CustomLogger.getTimeStamp();
        log.Type__c = logType;
        log.Message__c = message;
        log.Class_Name__c = className;
        log.Method_Name__c = methodName;

        // Do logging that is specific to a particular project
        specificLogging(projectName, log);

        // Add to static list so that we do not have numerous DML statements
        // throughout a transaction
        CustomLogger.CUSTOM_LOG_CACHE.add(log);
    }

    /**
     * Add an else statement to do logging specific to your project
     *
     * @param projectName
     * @param log
     */
    private static void specificLogging(String projectName, Logger__e log) {
        if (projectName == CustomLogger.MAIN_PROJECT_NAME) {
            log.User_Name__c = UserInfo.getName();
            log.User_Email__c = UserInfo.getUserEmail();
            //add project specific data items here...
        }
    }


    /**
     * As logs are not immediately inserted (they are added to a list to be inserted at the end of a transaction)
     * so the CreatedDate field on Custom_Log__c is not useful to us.
     * We will generate a timestamp and populate the Time_Stamp__c field so we can keep track of when individual logs were logged.
     *
     * @return date in special format
     */
    private static String getTimeStamp() {
        return 'TS ' + String.valueOfGmt(System.now());
    }

    /**
     * In case DML operation failed on Log send an email with information.
     *
     * @param errorMessage
     */
    @TestVisible
    private static void sendErrorEmail(List<Database.Error> errors) {
        //Get group users emails:
        List<User> userList = [
                SELECT Email
                FROM User
                WHERE Id IN (
                        SELECT UserOrGroupId
                        FROM GroupMember
                        WHERE Group.DeveloperName = :CustomLogger.CUSTOM_LOG_ADMINS_GROUP_API_NAME
                )
        ];
        if (!userList.isEmpty()) {
            List<String> toAddresses = new List<String>();
            for (User userForEmail : userList) {
                toAddresses.add(userForEmail.Email);
            }

            Datetime nowDateTime = Datetime.now();
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(toAddresses);
            mail.setSenderDisplayName(Schema.SObjectType.Custom_Log__c.label);
            mail.setSubject(Schema.SObjectType.Custom_Log__c.label + ' Error - ' + nowDateTime);
            String errorMessage = '';
            Integer errorNumber = 1;
            for (Database.Error error : errors) {
                errorMessage += errorNumber + ') ';
                errorMessage += error.message;
                errorMessage += '\n';
            }

            mail.setPlainTextBody(errorMessage);
        }
    }


    /**
     * Extract emthod name and class name from the error stack trace.
     *
     * @param trace Stack trace to extract from
     */
    public static String[] extractClassAndMethodName(String trace) {
        Pattern pattern = Pattern.compile('Class\\.([\\w_]+)\\.([\\w_]+)');
        Matcher matcher = pattern.matcher(trace);
        if (matcher.find() && matcher.groupCount() >= 2) {
            return new String[]{
                    matcher.group(1),
                    matcher.group(2)
            };
        }
        return new String[]{
                '',
                ''
        };
    }


    /**
     * Extract method name and class name that fired the error from the Error object
     *
     * @param ex Exception to process
     */
    public static String[] extractClassAndMethodName(Exception ex) {
        return extractClassAndMethodName(ex.getStackTraceString());
    }

}