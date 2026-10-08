/**
 * Single entry point for Inspection__c trigger logic.
 */
public with sharing class InspectionTriggerHandler {
  /** Lets data loads and tests switch the automation off. */
  public static Boolean bypass = false;

  public void run() {
    if (bypass) {
      return;
    }
    switch on Trigger.operationType {
      when BEFORE_INSERT {
        stampCompletedDate((List<Inspection__c>) Trigger.new);
        InspectorAssignmentService.assign((List<Inspection__c>) Trigger.new);
      }
      when BEFORE_UPDATE {
        stampCompletedDate((List<Inspection__c>) Trigger.new);
      }
      when AFTER_INSERT {
        FacilityRollupService.recalculate(
          facilityIds((List<Inspection__c>) Trigger.new)
        );
        InspectionSchedulingService.scheduleFollowUps(
          (List<Inspection__c>) Trigger.new,
          null
        );
      }
      when AFTER_UPDATE {
        FacilityRollupService.recalculate(
          facilityIds((List<Inspection__c>) Trigger.new)
        );
        InspectionSchedulingService.scheduleFollowUps(
          (List<Inspection__c>) Trigger.new,
          (Map<Id, Inspection__c>) Trigger.oldMap
        );
      }
      when AFTER_DELETE {
        FacilityRollupService.recalculate(
          facilityIds((List<Inspection__c>) Trigger.old)
        );
      }
      when AFTER_UNDELETE {
        FacilityRollupService.recalculate(
          facilityIds((List<Inspection__c>) Trigger.new)
        );
      }
    }
  }

  /** A result status without a completed date gets today's date. */
  private static void stampCompletedDate(List<Inspection__c> inspections) {
    for (Inspection__c inspection : inspections) {
      if (
        InspectionConstants.isCompleted(inspection.Status__c) &&
        inspection.Completed_Date__c == null
      ) {
        inspection.Completed_Date__c = Date.today();
      }
    }
  }

  private static Set<Id> facilityIds(List<Inspection__c> inspections) {
    Set<Id> ids = new Set<Id>();
    for (Inspection__c inspection : inspections) {
      ids.add(inspection.Facility__c);
    }
    return ids;
  }
}
