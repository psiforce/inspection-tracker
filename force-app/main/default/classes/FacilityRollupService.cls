/**
 * Copies inspection results up to the facility Account:
 *   Inspection_Status__c    latest completed result (or the open status if never completed)
 *   Last_Inspection_Date__c completed date of that result
 *   Next_Inspection_Due__c  earliest open inspection, else last inspection + 365 days
 *   Region__c               from State_Assignment__mdt, when blank
 * Account.Portal_Status__c turns these into Overdue / Not Yet Inspected for the public portal.
 */
public without sharing class FacilityRollupService {
  // without sharing: inspectors can complete inspections without edit access to the facility,
  // but the rollup must still update it.

  public static void recalculate(Set<Id> facilityIds) {
    facilityIds.remove(null);
    if (facilityIds.isEmpty()) {
      return;
    }

    List<Account> changed = new List<Account>();
    for (Account facility : [
      SELECT
        Id,
        BillingState,
        Region__c,
        Inspection_Status__c,
        Last_Inspection_Date__c,
        Next_Inspection_Due__c,
        (
          SELECT Status__c, Scheduled_Date__c, Completed_Date__c
          FROM Inspections__r
          ORDER BY Completed_Date__c DESC NULLS LAST, Scheduled_Date__c ASC
        )
      FROM Account
      WHERE Id IN :facilityIds
    ]) {
      Inspection__c latestCompleted = null;
      Inspection__c nextOpen = null;
      for (Inspection__c inspection : facility.Inspections__r) {
        if (
          InspectionConstants.isCompleted(inspection.Status__c) &&
          inspection.Completed_Date__c != null
        ) {
          if (
            latestCompleted == null ||
            inspection.Completed_Date__c > latestCompleted.Completed_Date__c
          ) {
            latestCompleted = inspection;
          }
        } else if (
          InspectionConstants.isOpen(inspection.Status__c) &&
          inspection.Scheduled_Date__c != null
        ) {
          if (
            nextOpen == null ||
            inspection.Scheduled_Date__c < nextOpen.Scheduled_Date__c
          ) {
            nextOpen = inspection;
          }
        }
      }

      String status = latestCompleted != null
        ? latestCompleted.Status__c
        : (nextOpen != null ? nextOpen.Status__c : null);
      Date lastDate = latestCompleted?.Completed_Date__c;
      Date nextDue = nextOpen != null
        ? nextOpen.Scheduled_Date__c
        : (lastDate != null
            ? lastDate.addDays(InspectionConstants.ANNUAL_INTERVAL_DAYS)
            : null);
      String region = facility.Region__c;
      if (String.isBlank(region)) {
        region = StateAssignments.forState(facility.BillingState)?.Region__c;
      }

      if (
        status != facility.Inspection_Status__c ||
        lastDate != facility.Last_Inspection_Date__c ||
        nextDue != facility.Next_Inspection_Due__c ||
        region != facility.Region__c
      ) {
        changed.add(
          new Account(
            Id = facility.Id,
            Inspection_Status__c = status,
            Last_Inspection_Date__c = lastDate,
            Next_Inspection_Due__c = nextDue,
            Region__c = region
          )
        );
      }
    }
    update changed;
  }
}
