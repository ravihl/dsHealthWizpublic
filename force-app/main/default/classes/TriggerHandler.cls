/**
 * @description Base Trigger Handler Framework
 * @author dsHealthWiz Platform Team
 * @date October 2025
 */
public virtual class TriggerHandler {

    // Static variables to prevent recursive triggers
    private static Set<String> bypassedHandlers = new Set<String>();

    // Context variables
    protected List<SObject> newRecords;
    protected List<SObject> oldRecords;
    protected Map<Id, SObject> newRecordsMap;
    protected Map<Id, SObject> oldRecordsMap;
    protected Schema.SObjectType sObjectType;

    /**
     * Main entry point for trigger execution
     */
    public void execute() {
        if (isBypassed()) {
            return;
        }

        // Load context
        loadContext();

        // Execute appropriate handler based on trigger context
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                beforeInsert();
            } else if (Trigger.isUpdate) {
                beforeUpdate();
            } else if (Trigger.isDelete) {
                beforeDelete();
            }
        } else if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                afterInsert();
            } else if (Trigger.isUpdate) {
                afterUpdate();
            } else if (Trigger.isDelete) {
                afterDelete();
            } else if (Trigger.isUndelete) {
                afterUndelete();
            }
        }
    }

    // Virtual methods to be overridden by child classes
    protected virtual void beforeInsert() {}
    protected virtual void beforeUpdate() {}
    protected virtual void beforeDelete() {}
    protected virtual void afterInsert() {}
    protected virtual void afterUpdate() {}
    protected virtual void afterDelete() {}
    protected virtual void afterUndelete() {}

    /**
     * Load trigger context variables
     */
    private void loadContext() {
        this.newRecords = Trigger.new;
        this.oldRecords = Trigger.old;
        this.newRecordsMap = Trigger.newMap;
        this.oldRecordsMap = Trigger.oldMap;
        this.sObjectType = newRecords != null ? 
            newRecords.getSObjectType() : oldRecords.getSObjectType();
    }

    /**
     * Check if this handler is bypassed
     */
    private Boolean isBypassed() {
        return bypassedHandlers.contains(getHandlerName());
    }

    /**
     * Bypass this trigger handler
     */
    public static void bypass(String handlerName) {
        bypassedHandlers.add(handlerName);
    }

    /**
     * Clear bypass for this trigger handler
     */
    public static void clearBypass(String handlerName) {
        bypassedHandlers.remove(handlerName);
    }

    /**
     * Get handler name
     */
    private String getHandlerName() {
        return String.valueOf(this).split(':')[0];
    }
}