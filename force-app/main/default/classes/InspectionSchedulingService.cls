/**
 * Creates the follow-up inspection when an inspection is completed:
 *   Passed / Passed with Conditions     -> Annual inspection 365 days after completion
 *   Failed / Re-inspection Required     -> Re-inspection 30 days after completion
 * A facility that already has an open (Scheduled or In Progress) inspection gets nothing new,
 * which keeps reruns and historical data loads from creating duplicates.
 */
public without sharing class InspectionSchedulingService {
  // without sharing: inspectors may not have create access to every inspection on the facility.

  private static Set<Id> alreadyProcessed = new Set<Id>();

  public static void scheduleFollowUps(
    List<Inspection__c> inspections,
    Map<Id, Inspection__c> oldMap
  ) {
    Map<Id, Inspection__c> latestByFacility = new Map<Id, Inspection__c>();
    for (Inspection__c inspection : inspections) {
      Boolean becameCompleted =
        InspectionConstants.isCompleted(inspection.Status__c) &&
        (oldMap == null ||
        oldMap.get(inspection.Id).Status__c != inspection.Status__c);
      if (
        !becameCompleted ||
        inspection.Completed_Date__c == null ||
        alreadyProcessed.contains(inspection.Id)
      ) {
        continue;
      }
      alreadyProcessed.add(inspection.Id);
      Inspection__c current = latestByFacility.get(inspection.Facility__c);
      if (
        current == null ||
        inspection.Completed_Date__c > current.Completed_Date__c
      ) {
        latestByFacility.put(inspection.Facility__c, inspection);
      }
    }
    if (latestByFacility.isEmpty()) {
      return;
    }

    Set<Id> facilityIds = latestByFacility.keySet();
    for (Inspection__c open : [
      SELECT Facility__c
      FROM Inspection__c
      WHERE
        Facility__c IN :facilityIds
        AND Status__c IN :InspectionConstants.OPEN_STATUSES
    ]) {
      latestByFacility.remove(open.Facility__c);
    }

    List<Inspection__c> followUps = new List<Inspection__c>();
    for (Inspection__c completed : latestByFacility.values()) {
      Boolean passed = InspectionConstants.PASSING_STATUSES.contains(
        completed.Status__c
      );
      followUps.add(
        new Inspection__c(
          Facility__c = completed.Facility__c,
          Status__c = InspectionConstants.STATUS_SCHEDULED,
          Inspection_Type__c = passed
            ? InspectionConstants.TYPE_ANNUAL
            : InspectionConstants.TYPE_REINSPECTION,
          Scheduled_Date__c = completed.Completed_Date__c.addDays(
            passed
              ? InspectionConstants.ANNUAL_INTERVAL_DAYS
              : InspectionConstants.REINSPECTION_INTERVAL_DAYS
          )
        )
      );
    }
    insert followUps;
  }
}
