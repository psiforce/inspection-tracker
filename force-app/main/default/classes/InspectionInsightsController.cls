/**
 * National inspection statistics for the public National Insights page (guest users).
 *
 * Same security model as FacilityPortalController: with sharing, USER_MODE queries, so the
 * guest sharing rule and the Inspection_Portal_Guest permission set decide what is counted.
 * Only aggregates are returned - no record ids, inspector or internal notes.
 *
 * Definitions (shared with the portal):
 *   compliant = Portal_Status__c Passed or Passed with Conditions
 *   failing   = Portal_Status__c Failed or Re-inspection Required
 *   overdue   = Portal_Status__c Overdue (next inspection due date has passed)
 */
public with sharing class InspectionInsightsController {
  private static final Integer TREND_QUARTERS = 12;
  private static final Integer DEFICIENCY_MONTHS = 24;
  private static final Integer MAX_FACILITIES = 10000;
  private static final Integer MAX_INSPECTIONS = 20000;

  @AuraEnabled(cacheable=true)
  public static NationalInsights getNationalInsights(String facilityType) {
    try {
      return build(
        String.isBlank(facilityType) ? null : facilityType,
        Date.today()
      );
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'InspectionInsightsController: ' + e.getMessage()
      );
      String message = 'Inspection statistics are unavailable right now. Try again in a few minutes.';
      AuraHandledException error = new AuraHandledException(message);
      error.setMessage(message);
      throw error;
    }
  }

  @TestVisible
  private static NationalInsights build(String facilityType, Date today) {
    Map<Id, Account> facilities = queryFacilities(facilityType);
    List<Inspection__c> inspections = queryInspections(
      today,
      facilities.keySet()
    );

    NationalInsights result = new NationalInsights();
    result.generatedOn = today;
    result.facilityType = facilityType;
    result.kpis = kpis(facilities.values(), inspections, today);
    result.states = states(facilities.values());
    result.trend = trend(inspections, today);
    result.deficiencies = deficiencies(inspections, today);
    result.byType = breakdown(
      facilities,
      inspections,
      today,
      picklistValues(Account.Facility_Type__c.getDescribe(), facilityType),
      true
    );
    result.byRegion = breakdown(
      facilities,
      inspections,
      today,
      picklistValues(Account.Region__c.getDescribe(), null),
      false
    );
    result.overdueAging = overdueAging(facilities.values(), today);
    return result;
  }

  // ---------- queries ----------

  private static Map<Id, Account> queryFacilities(String facilityType) {
    Map<String, Object> binds = new Map<String, Object>{
      'recordType' => InspectionConstants.FACILITY_RECORD_TYPE,
      'maxRows' => MAX_FACILITIES
    };
    String soql =
      'SELECT Id, Facility_Type__c, BillingState, Region__c, Portal_Status__c, Next_Inspection_Due__c ' +
      'FROM Account WHERE RecordType.DeveloperName = :recordType AND Publicly_Listed__c = TRUE';
    if (facilityType != null) {
      binds.put('facilityType', facilityType);
      soql += ' AND Facility_Type__c = :facilityType';
    }
    soql += ' LIMIT :maxRows';
    return new Map<Id, Account>(
      (List<Account>) Database.queryWithBinds(
        soql,
        binds,
        AccessLevel.USER_MODE
      )
    );
  }

  /** Completed inspections of the listed facilities over the trend window. */
  private static List<Inspection__c> queryInspections(
    Date today,
    Set<Id> facilityIds
  ) {
    Map<String, Object> binds = new Map<String, Object>{
      'facilityIds' => facilityIds,
      'fromDate' => quarterStart(today).addMonths(-3 * (TREND_QUARTERS - 1)),
      'today' => today,
      'maxRows' => MAX_INSPECTIONS
    };
    String soql =
      'SELECT Facility__c, Status__c, Completed_Date__c, Score__c, Deficiency_Areas__c ' +
      'FROM Inspection__c WHERE Facility__c IN :facilityIds ' +
      'AND Completed_Date__c >= :fromDate AND Completed_Date__c <= :today ' +
      'ORDER BY Completed_Date__c LIMIT :maxRows';
    List<Inspection__c> completed = new List<Inspection__c>();
    for (
      Inspection__c inspection : (List<Inspection__c>) Database.queryWithBinds(
        soql,
        binds,
        AccessLevel.USER_MODE
      )
    ) {
      if (InspectionConstants.isCompleted(inspection.Status__c)) {
        completed.add(inspection);
      }
    }
    return completed;
  }

  // ---------- sections ----------

  private static Kpis kpis(
    List<Account> facilities,
    List<Inspection__c> inspections,
    Date today
  ) {
    Kpis k = new Kpis();
    k.facilities = facilities.size();
    Integer compliant = 0;
    for (Account facility : facilities) {
      if (isCompliant(facility.Portal_Status__c)) {
        compliant++;
      } else if (
        facility.Portal_Status__c == InspectionConstants.PORTAL_OVERDUE
      ) {
        k.overdue++;
      } else if (isFailing(facility.Portal_Status__c)) {
        k.failing++;
      }
      Date due = facility.Next_Inspection_Due__c;
      if (due != null && due >= today && due <= today.addDays(90)) {
        k.dueNext90Days++;
      }
    }
    k.compliantPct = pct(compliant, k.facilities);

    Stats last12 = new Stats();
    for (Inspection__c inspection : inspections) {
      if (inspection.Completed_Date__c.year() == today.year()) {
        k.completedThisYear++;
      }
      if (inspection.Completed_Date__c > today.addYears(-1)) {
        last12.add(inspection);
      }
    }
    k.inspectionsLast12Months = last12.count;
    k.failRateLast12Months = last12.failRate();
    k.avgScoreLast12Months = last12.avgScore();
    return k;
  }

  private static List<StateStat> states(List<Account> facilities) {
    Map<String, StateStat> byKey = new Map<String, StateStat>();
    List<StateStat> ordered = new List<StateStat>();
    for (State_Assignment__mdt row : StateAssignments.all()) {
      StateStat stat = new StateStat();
      stat.code = row.State_Code__c;
      stat.name = row.State_Name__c;
      stat.region = row.Region__c;
      ordered.add(stat);
      byKey.put(row.State_Code__c.toUpperCase(), stat);
      byKey.put(row.State_Name__c.toUpperCase(), stat);
    }
    for (Account facility : facilities) {
      StateStat stat = String.isBlank(facility.BillingState)
        ? null
        : byKey.get(facility.BillingState.trim().toUpperCase());
      if (stat == null) {
        continue;
      }
      stat.facilities++;
      if (isCompliant(facility.Portal_Status__c)) {
        stat.compliant++;
      } else if (
        facility.Portal_Status__c == InspectionConstants.PORTAL_OVERDUE
      ) {
        stat.overdue++;
      } else if (isFailing(facility.Portal_Status__c)) {
        stat.failing++;
      }
    }
    for (StateStat stat : ordered) {
      stat.compliantPct = stat.facilities == 0
        ? null
        : pct(stat.compliant, stat.facilities);
    }
    return ordered;
  }

  private static List<QuarterStat> trend(
    List<Inspection__c> inspections,
    Date today
  ) {
    Date first = quarterStart(today).addMonths(-3 * (TREND_QUARTERS - 1));
    List<QuarterStat> quarters = new List<QuarterStat>();
    Map<Integer, QuarterStat> byKey = new Map<Integer, QuarterStat>();
    Map<Integer, Stats> statsByKey = new Map<Integer, Stats>();
    for (Integer i = 0; i < TREND_QUARTERS; i++) {
      Date start = first.addMonths(3 * i);
      QuarterStat q = new QuarterStat();
      q.year = start.year();
      q.quarter = (start.month() - 1) / 3 + 1;
      q.label = 'Q' + q.quarter + ' ' + q.year;
      q.isPartial = i == TREND_QUARTERS - 1;
      quarters.add(q);
      byKey.put(quarterKey(start), q);
      statsByKey.put(quarterKey(start), new Stats());
    }
    for (Inspection__c inspection : inspections) {
      Integer key = quarterKey(inspection.Completed_Date__c);
      QuarterStat q = byKey.get(key);
      if (q == null) {
        continue;
      }
      if (inspection.Status__c == InspectionConstants.STATUS_PASSED) {
        q.passed++;
      } else if (
        inspection.Status__c ==
        InspectionConstants.STATUS_PASSED_WITH_CONDITIONS
      ) {
        q.conditional++;
      } else {
        q.failed++;
      }
      statsByKey.get(key).add(inspection);
    }
    for (Integer key : byKey.keySet()) {
      QuarterStat q = byKey.get(key);
      q.total = q.passed + q.conditional + q.failed;
      q.avgScore = statsByKey.get(key).avgScore();
    }
    return quarters;
  }

  private static List<CountStat> deficiencies(
    List<Inspection__c> inspections,
    Date today
  ) {
    Map<String, Integer> counts = new Map<String, Integer>();
    for (
      Schema.PicklistEntry entry : Inspection__c.Deficiency_Areas__c.getDescribe()
        .getPicklistValues()
    ) {
      if (entry.isActive()) {
        counts.put(entry.getValue(), 0);
      }
    }
    Date fromDate = today.addMonths(-DEFICIENCY_MONTHS);
    Integer total = 0;
    for (Inspection__c inspection : inspections) {
      if (
        inspection.Completed_Date__c <= fromDate ||
        String.isBlank(inspection.Deficiency_Areas__c)
      ) {
        continue;
      }
      for (String area : inspection.Deficiency_Areas__c.split(';')) {
        if (counts.containsKey(area)) {
          counts.put(area, counts.get(area) + 1);
          total++;
        }
      }
    }
    List<CountStat> stats = new List<CountStat>();
    for (String area : counts.keySet()) {
      stats.add(
        new CountStat(area, counts.get(area), pct(counts.get(area), total))
      );
    }
    stats.sort();
    return stats;
  }

  private static List<GroupStat> breakdown(
    Map<Id, Account> facilities,
    List<Inspection__c> inspections,
    Date today,
    List<String> groups,
    Boolean byType
  ) {
    Map<String, GroupStat> byName = new Map<String, GroupStat>();
    Map<String, Stats> statsByName = new Map<String, Stats>();
    List<GroupStat> ordered = new List<GroupStat>();
    for (String name : groups) {
      GroupStat stat = new GroupStat();
      stat.name = name;
      ordered.add(stat);
      byName.put(name, stat);
      statsByName.put(name, new Stats());
    }
    for (Account facility : facilities.values()) {
      GroupStat stat = byName.get(
        byType ? facility.Facility_Type__c : facility.Region__c
      );
      if (stat == null) {
        continue;
      }
      stat.facilities++;
      if (facility.Portal_Status__c == InspectionConstants.PORTAL_OVERDUE) {
        stat.overdue++;
      }
    }
    for (Inspection__c inspection : inspections) {
      if (inspection.Completed_Date__c <= today.addYears(-1)) {
        continue;
      }
      Account facility = facilities.get(inspection.Facility__c);
      String name = facility == null
        ? null
        : (byType ? facility.Facility_Type__c : facility.Region__c);
      if (statsByName.containsKey(name)) {
        statsByName.get(name).add(inspection);
      }
    }
    for (GroupStat stat : ordered) {
      Stats s = statsByName.get(stat.name);
      stat.inspectionsLast12Months = s.count;
      stat.overdueRate = stat.facilities == 0
        ? null
        : pct(stat.overdue, stat.facilities);
      stat.failRate = s.failRate();
      stat.avgScore = s.avgScore();
    }
    return ordered;
  }

  private static List<CountStat> overdueAging(
    List<Account> facilities,
    Date today
  ) {
    Integer upTo30 = 0;
    Integer upTo90 = 0;
    Integer over90 = 0;
    for (Account facility : facilities) {
      if (
        facility.Portal_Status__c != InspectionConstants.PORTAL_OVERDUE ||
        facility.Next_Inspection_Due__c == null
      ) {
        continue;
      }
      Integer days = facility.Next_Inspection_Due__c.daysBetween(today);
      if (days <= 30) {
        upTo30++;
      } else if (days <= 90) {
        upTo90++;
      } else {
        over90++;
      }
    }
    Integer total = upTo30 + upTo90 + over90;
    return new List<CountStat>{
      new CountStat('1–30 days', upTo30, pct(upTo30, total)),
      new CountStat('31–90 days', upTo90, pct(upTo90, total)),
      new CountStat('Over 90 days', over90, pct(over90, total))
    };
  }

  // ---------- helpers ----------

  private static Boolean isCompliant(String portalStatus) {
    return InspectionConstants.PASSING_STATUSES.contains(portalStatus);
  }

  private static Boolean isFailing(String portalStatus) {
    return InspectionConstants.FAILING_STATUSES.contains(portalStatus);
  }

  private static Decimal pct(Integer part, Integer whole) {
    return whole == null || whole == 0 ? 0 : (100.0 * part / whole).setScale(1);
  }

  private static Date quarterStart(Date d) {
    return Date.newInstance(d.year(), ((d.month() - 1) / 3) * 3 + 1, 1);
  }

  private static Integer quarterKey(Date d) {
    return d.year() * 4 + (d.month() - 1) / 3;
  }

  private static List<String> picklistValues(
    Schema.DescribeFieldResult field,
    String only
  ) {
    List<String> values = new List<String>();
    for (Schema.PicklistEntry entry : field.getPicklistValues()) {
      if (entry.isActive() && (only == null || entry.getValue() == only)) {
        values.add(entry.getValue());
      }
    }
    return values;
  }

  /** Running totals for fail rate and average score. */
  private class Stats {
    public Integer count = 0;
    public Integer failed = 0;
    public Integer scored = 0;
    public Decimal scoreTotal = 0;

    public void add(Inspection__c inspection) {
      count++;
      if (InspectionConstants.FAILING_STATUSES.contains(inspection.Status__c)) {
        failed++;
      }
      if (inspection.Score__c != null) {
        scored++;
        scoreTotal += inspection.Score__c;
      }
    }

    public Decimal failRate() {
      return count == 0 ? null : pct(failed, count);
    }

    public Decimal avgScore() {
      return scored == 0 ? null : (scoreTotal / scored).setScale(1);
    }
  }

  // ---------- DTOs ----------

  public class NationalInsights {
    @AuraEnabled
    public Date generatedOn;
    @AuraEnabled
    public String facilityType;
    @AuraEnabled
    public Kpis kpis;
    @AuraEnabled
    public List<StateStat> states;
    @AuraEnabled
    public List<QuarterStat> trend;
    @AuraEnabled
    public List<CountStat> deficiencies;
    @AuraEnabled
    public List<GroupStat> byType;
    @AuraEnabled
    public List<GroupStat> byRegion;
    @AuraEnabled
    public List<CountStat> overdueAging;
  }

  public class Kpis {
    @AuraEnabled
    public Integer facilities = 0;
    @AuraEnabled
    public Decimal compliantPct = 0;
    @AuraEnabled
    public Integer overdue = 0;
    @AuraEnabled
    public Integer failing = 0;
    @AuraEnabled
    public Integer dueNext90Days = 0;
    @AuraEnabled
    public Integer completedThisYear = 0;
    @AuraEnabled
    public Integer inspectionsLast12Months = 0;
    @AuraEnabled
    public Decimal failRateLast12Months;
    @AuraEnabled
    public Decimal avgScoreLast12Months;
  }

  public class StateStat {
    @AuraEnabled
    public String code;
    @AuraEnabled
    public String name;
    @AuraEnabled
    public String region;
    @AuraEnabled
    public Integer facilities = 0;
    @AuraEnabled
    public Integer compliant = 0;
    @AuraEnabled
    public Integer overdue = 0;
    @AuraEnabled
    public Integer failing = 0;
    @AuraEnabled
    public Decimal compliantPct;
  }

  public class QuarterStat {
    @AuraEnabled
    public String label;
    @AuraEnabled
    public Integer year;
    @AuraEnabled
    public Integer quarter;
    @AuraEnabled
    public Boolean isPartial = false;
    @AuraEnabled
    public Integer passed = 0;
    @AuraEnabled
    public Integer conditional = 0;
    @AuraEnabled
    public Integer failed = 0;
    @AuraEnabled
    public Integer total = 0;
    @AuraEnabled
    public Decimal avgScore;
  }

  public class GroupStat {
    @AuraEnabled
    public String name;
    @AuraEnabled
    public Integer facilities = 0;
    @AuraEnabled
    public Integer overdue = 0;
    @AuraEnabled
    public Integer inspectionsLast12Months = 0;
    @AuraEnabled
    public Decimal overdueRate;
    @AuraEnabled
    public Decimal failRate;
    @AuraEnabled
    public Decimal avgScore;
  }

  /** A labelled count, sorted by count descending. */
  public class CountStat implements Comparable {
    @AuraEnabled
    public String label;
    @AuraEnabled
    public Integer count;
    @AuraEnabled
    public Decimal pct;

    public CountStat(String label, Integer count, Decimal pct) {
      this.label = label;
      this.count = count;
      this.pct = pct;
    }

    public Integer compareTo(Object other) {
      return ((CountStat) other).count - count;
    }
  }
}
