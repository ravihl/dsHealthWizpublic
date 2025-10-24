/**
 * @description Centralized Logging Service
 * @author dsHealthWiz Platform Team
 */
public class LoggingService {

    public enum LogLevel { DEBUG, INFO, WARN, ERROR, FATAL }

    private static List<Application_Log__c> logBuffer = new List<Application_Log__c>();
    private static final Integer BUFFER_SIZE = 100;

    /**
     * Log an error with exception
     */
    public static void error(String message, Exception ex) {
        log(LogLevel.ERROR, message, ex.getTypeName(), ex.getStackTraceString());
    }

    /**
     * Log a warning
     */
    public static void warn(String message) {
        log(LogLevel.WARN, message, null, null);
    }

    /**
     * Log info message
     */
    public static void info(String message) {
        log(LogLevel.INFO, message, null, null);
    }

    /**
     * Log debug message
     */
    public static void debug(String message) {
        log(LogLevel.DEBUG, message, null, null);
    }

    /**
     * Core logging method
     */
    private static void log(LogLevel level, String message, String exceptionType, String stackTrace) {
        Application_Log__c logRecord = new Application_Log__c(
            Log_Level__c = level.name(),
            Message__c = message,
            Exception_Type__c = exceptionType,
            Stack_Trace__c = stackTrace,
            User_Id__c = UserInfo.getUserId(),
            Timestamp__c = System.now(),
            Context__c = getContext()
        );

        logBuffer.add(logRecord);

        if (logBuffer.size() >= BUFFER_SIZE) {
            flush();
        }
    }

    /**
     * Flush logs to database
     */
    public static void flush() {
        if (!logBuffer.isEmpty()) {
            Database.insert(logBuffer, false);
            logBuffer.clear();
        }
    }

    /**
     * Get execution context
     */
    private static String getContext() {
        String context = '';
        if (Trigger.isExecuting) {
            context = 'Trigger: ' + Trigger.operationType;
        } else if (System.isBatch()) {
            context = 'Batch';
        } else if (System.isQueueable()) {
            context = 'Queueable';
        } else if (System.isFuture()) {
            context = 'Future';
        } else if (System.isScheduled()) {
            context = 'Scheduled';
        } else {
            context = 'Interactive';
        }
        return context;
    }
}