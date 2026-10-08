/**
 * Assigns new inspections to an inspector based on the facility's state.
 * The state is looked up in State_Assignment__mdt; when that row has no
 * Inspector_Username__c, or the user is inactive, the facility owner is used.
 */
public without sharing class InspectorAssignmentService {
  // without sharing: the inspector is resolved from the facility and User records,
  // which the user creating the inspection may not be able to see.

  public static void assign(List<Inspection__c> inspections) {
    Set<Id> facilityIds = new Set<Id>();
    for (Inspection__c inspection : inspections) {
      if (inspection.Inspector__c == null && inspection.Facility__c != null) {
        facilityIds.add(inspection.Facility__c);
      }
    }
    if (facilityIds.isEmpty()) {
      return;
    }

    Map<Id, Account> facilities = new Map<Id, Account>(
      [SELECT Id, BillingState, OwnerId FROM Account WHERE Id IN :facilityIds]
    );

    Set<String> usernames = new Set<String>();
    for (Account facility : facilities.values()) {
      State_Assignment__mdt assignment = StateAssignments.forState(
        facility.BillingState
      );
      if (
        assignment != null &&
        String.isNotBlank(assignment.Inspector_Username__c)
      ) {
        usernames.add(assignment.Inspector_Username__c);
      }
    }
    Map<String, Id> userIdByUsername = new Map<String, Id>();
    if (!usernames.isEmpty()) {
      for (User inspector : [
        SELECT Id, Username
        FROM User
        WHERE Username IN :usernames AND IsActive = TRUE
      ]) {
        userIdByUsername.put(inspector.Username.toLowerCase(), inspector.Id);
      }
    }

    for (Inspection__c inspection : inspections) {
      Account facility = facilities.get(inspection.Facility__c);
      if (inspection.Inspector__c != null || facility == null) {
        continue;
      }
      State_Assignment__mdt assignment = StateAssignments.forState(
        facility.BillingState
      );
      Id inspectorId = null;
      if (
        assignment != null &&
        String.isNotBlank(assignment.Inspector_Username__c)
      ) {
        inspectorId = userIdByUsername.get(
          assignment.Inspector_Username__c.toLowerCase()
        );
      }
      inspection.Inspector__c = inspectorId != null
        ? inspectorId
        : facility.OwnerId;
    }
  }
}
