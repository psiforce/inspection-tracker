/**
 * Status values, inspection types and scheduling intervals shared by the
 * inspection automation and the public portal controller.
 */
public with sharing class InspectionConstants {
  public static final String FACILITY_RECORD_TYPE = 'Medical_Facility';

  public static final String STATUS_SCHEDULED = 'Scheduled';
  public static final String STATUS_IN_PROGRESS = 'In Progress';
  public static final String STATUS_PASSED = 'Passed';
  public static final String STATUS_PASSED_WITH_CONDITIONS = 'Passed with Conditions';
  public static final String STATUS_FAILED = 'Failed';
  public static final String STATUS_REINSPECTION_REQUIRED = 'Re-inspection Required';

  /** Portal-only statuses derived by Account.Portal_Status__c. */
  public static final String PORTAL_OVERDUE = 'Overdue';
  public static final String PORTAL_NOT_YET_INSPECTED = 'Not Yet Inspected';

  public static final String TYPE_ANNUAL = 'Annual';
  public static final String TYPE_REINSPECTION = 'Re-inspection';
  public static final String TYPE_COMPLAINT = 'Complaint';

  public static final Integer ANNUAL_INTERVAL_DAYS = 365;
  public static final Integer REINSPECTION_INTERVAL_DAYS = 30;

  public static final Set<String> OPEN_STATUSES = new Set<String>{
    STATUS_SCHEDULED,
    STATUS_IN_PROGRESS
  };
  public static final Set<String> PASSING_STATUSES = new Set<String>{
    STATUS_PASSED,
    STATUS_PASSED_WITH_CONDITIONS
  };
  public static final Set<String> FAILING_STATUSES = new Set<String>{
    STATUS_FAILED,
    STATUS_REINSPECTION_REQUIRED
  };

  public static Boolean isCompleted(String status) {
    return PASSING_STATUSES.contains(status) ||
      FAILING_STATUSES.contains(status);
  }

  public static Boolean isOpen(String status) {
    return OPEN_STATUSES.contains(status);
  }

  public static Id facilityRecordTypeId() {
    return Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
      .get(FACILITY_RECORD_TYPE)
      .getRecordTypeId();
  }
}
