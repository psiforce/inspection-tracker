/**
 * Read-only data for the public Facility Inspections portal (guest users).
 *
 * Security:
 *  - with sharing + USER_MODE queries: the guest sees only facilities shared by the
 *    guest sharing rule (Publicly_Listed__c = true) and only fields the
 *    Inspection_Portal_Guest permission set grants.
 *  - Results are returned as DTOs that carry public fields only. Inspector and
 *    Internal_Notes__c are never queried here.
 */
public with sharing class FacilityPortalController {
  @TestVisible
  private static final Integer MAX_RESULTS = 500;
  private static final Integer MAX_HISTORY = 50;
  private static final Integer MAX_TERM_LENGTH = 80;

  /** Status filter options, in the order the portal shows them. */
  @TestVisible
  private static final List<String> PORTAL_STATUSES = new List<String>{
    InspectionConstants.STATUS_PASSED,
    InspectionConstants.STATUS_PASSED_WITH_CONDITIONS,
    InspectionConstants.STATUS_SCHEDULED,
    InspectionConstants.STATUS_IN_PROGRESS,
    InspectionConstants.STATUS_FAILED,
    InspectionConstants.STATUS_REINSPECTION_REQUIRED,
    InspectionConstants.PORTAL_OVERDUE,
    InspectionConstants.PORTAL_NOT_YET_INSPECTED
  };

  @AuraEnabled(cacheable=true)
  public static List<FacilitySummary> searchFacilities(
    String searchTerm,
    String state,
    String status,
    String facilityType
  ) {
    Map<String, Object> binds = new Map<String, Object>{
      'recordType' => InspectionConstants.FACILITY_RECORD_TYPE,
      'maxResults' => MAX_RESULTS
    };
    List<String> conditions = new List<String>{
      'RecordType.DeveloperName = :recordType',
      'Publicly_Listed__c = TRUE',
      'BillingLatitude != NULL'
    };

    String term = String.isBlank(searchTerm)
      ? ''
      : searchTerm.trim().left(MAX_TERM_LENGTH);
    if (term.length() > 0) {
      binds.put('term', '%' + escapeLike(term) + '%');
      conditions.add(
        '(Name LIKE :term OR BillingCity LIKE :term OR BillingPostalCode LIKE :term)'
      );
    }
    if (String.isNotBlank(state)) {
      State_Assignment__mdt assignment = StateAssignments.forState(state);
      binds.put(
        'stateValues',
        assignment == null
          ? new List<String>{ state }
          : new List<String>{
              assignment.State_Name__c,
              assignment.State_Code__c
            }
      );
      conditions.add('BillingState IN :stateValues');
    }
    if (String.isNotBlank(status)) {
      binds.put('status', status);
      conditions.add('Portal_Status__c = :status');
    }
    if (String.isNotBlank(facilityType)) {
      binds.put('facilityType', facilityType);
      conditions.add('Facility_Type__c = :facilityType');
    }

    String soql =
      'SELECT Id, Name, Facility_Type__c, BillingStreet, BillingCity, BillingState, BillingPostalCode, ' +
      'BillingLatitude, BillingLongitude, Region__c, Portal_Status__c, ' +
      'Last_Inspection_Date__c, Next_Inspection_Due__c ' +
      'FROM Account WHERE ' +
      String.join(conditions, ' AND ') +
      ' ORDER BY Name LIMIT :maxResults';

    List<FacilitySummary> results = new List<FacilitySummary>();
    try {
      List<Account> facilities = (List<Account>) Database.queryWithBinds(
        soql,
        binds,
        AccessLevel.USER_MODE
      );
      for (Account facility : facilities) {
        results.add(new FacilitySummary(facility));
      }
    } catch (Exception e) {
      throw portalError(e);
    }
    return results;
  }

  @AuraEnabled(cacheable=true)
  public static FacilityDetail getFacilityDetail(Id facilityId) {
    if (facilityId == null) {
      throw portalException('Choose a facility to see its inspection history.');
    }
    List<Account> facilities;
    try {
      facilities = [
        SELECT
          Id,
          Name,
          Facility_Type__c,
          BillingStreet,
          BillingCity,
          BillingState,
          BillingPostalCode,
          BillingLatitude,
          BillingLongitude,
          Region__c,
          Portal_Status__c,
          Last_Inspection_Date__c,
          Next_Inspection_Due__c,
          License_Number__c,
          Phone,
          (
            SELECT
              Id,
              Name,
              Inspection_Type__c,
              Status__c,
              Scheduled_Date__c,
              Completed_Date__c,
              Score__c,
              Public_Summary__c
            FROM Inspections__r
            ORDER BY Scheduled_Date__c DESC
            LIMIT :MAX_HISTORY
          )
        FROM Account
        WHERE
          Id = :facilityId
          AND RecordType.DeveloperName = :InspectionConstants.FACILITY_RECORD_TYPE
          AND Publicly_Listed__c = TRUE
        WITH USER_MODE
      ];
    } catch (Exception e) {
      throw portalError(e);
    }
    if (facilities.isEmpty()) {
      throw portalException('This facility is not listed on the portal.');
    }
    return new FacilityDetail(facilities[0]);
  }

  @AuraEnabled(cacheable=true)
  public static FilterOptions getFilterOptions() {
    FilterOptions options = new FilterOptions();
    for (State_Assignment__mdt row : StateAssignments.all()) {
      options.states.add(new Option(row.State_Name__c, row.State_Name__c));
    }
    for (
      Schema.PicklistEntry entry : Account.Facility_Type__c.getDescribe()
        .getPicklistValues()
    ) {
      if (entry.isActive()) {
        options.facilityTypes.add(
          new Option(entry.getLabel(), entry.getValue())
        );
      }
    }
    for (String status : PORTAL_STATUSES) {
      options.statuses.add(new Option(status, status));
    }
    return options;
  }

  @TestVisible
  private static String escapeLike(String value) {
    return value.replace('\\', '\\\\').replace('%', '\\%').replace('_', '\\_');
  }

  private static AuraHandledException portalError(Exception e) {
    System.debug(
      LoggingLevel.ERROR,
      'FacilityPortalController: ' + e.getMessage()
    );
    return portalException(
      'Facility data is unavailable right now. Try again in a few minutes.'
    );
  }

  /** AuraHandledException hides its message from Apex callers unless setMessage is also called. */
  private static AuraHandledException portalException(String message) {
    AuraHandledException error = new AuraHandledException(message);
    error.setMessage(message);
    return error;
  }

  // ---------- DTOs (public fields only) ----------

  public virtual class FacilitySummary {
    @AuraEnabled
    public Id id;
    @AuraEnabled
    public String name;
    @AuraEnabled
    public String facilityType;
    @AuraEnabled
    public String street;
    @AuraEnabled
    public String city;
    @AuraEnabled
    public String state;
    @AuraEnabled
    public String postalCode;
    @AuraEnabled
    public Decimal latitude;
    @AuraEnabled
    public Decimal longitude;
    @AuraEnabled
    public String region;
    @AuraEnabled
    public String portalStatus;
    @AuraEnabled
    public Date lastInspectionDate;
    @AuraEnabled
    public Date nextInspectionDue;

    public FacilitySummary(Account facility) {
      id = facility.Id;
      name = facility.Name;
      facilityType = facility.Facility_Type__c;
      street = facility.BillingStreet;
      city = facility.BillingCity;
      state = facility.BillingState;
      postalCode = facility.BillingPostalCode;
      latitude = facility.BillingLatitude;
      longitude = facility.BillingLongitude;
      region = facility.Region__c;
      portalStatus = facility.Portal_Status__c;
      lastInspectionDate = facility.Last_Inspection_Date__c;
      nextInspectionDue = facility.Next_Inspection_Due__c;
    }
  }

  public class FacilityDetail extends FacilitySummary {
    @AuraEnabled
    public String licenseNumber;
    @AuraEnabled
    public String phone;
    @AuraEnabled
    public List<InspectionHistoryItem> inspections = new List<InspectionHistoryItem>();

    public FacilityDetail(Account facility) {
      super(facility);
      licenseNumber = facility.License_Number__c;
      phone = facility.Phone;
      for (Inspection__c inspection : facility.Inspections__r) {
        inspections.add(new InspectionHistoryItem(inspection));
      }
    }
  }

  public class InspectionHistoryItem {
    @AuraEnabled
    public Id id;
    @AuraEnabled
    public String inspectionNumber;
    @AuraEnabled
    public String inspectionType;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public Date scheduledDate;
    @AuraEnabled
    public Date completedDate;
    @AuraEnabled
    public Decimal score;
    @AuraEnabled
    public String publicSummary;

    public InspectionHistoryItem(Inspection__c inspection) {
      id = inspection.Id;
      inspectionNumber = inspection.Name;
      inspectionType = inspection.Inspection_Type__c;
      status = inspection.Status__c;
      scheduledDate = inspection.Scheduled_Date__c;
      completedDate = inspection.Completed_Date__c;
      score = inspection.Score__c;
      publicSummary = inspection.Public_Summary__c;
    }
  }

  public class FilterOptions {
    @AuraEnabled
    public List<Option> states = new List<Option>();
    @AuraEnabled
    public List<Option> facilityTypes = new List<Option>();
    @AuraEnabled
    public List<Option> statuses = new List<Option>();
  }

  public class Option {
    @AuraEnabled
    public String label;
    @AuraEnabled
    public String value;

    public Option(String label, String value) {
      this.label = label;
      this.value = value;
    }
  }
}
