/**
 * Reads State_Assignment__mdt, which maps each US state to a region and an inspector.
 * Lookups accept either the two-letter code or the full state name, so they work
 * whether or not State and Country picklists are enabled in the org.
 */
public with sharing class StateAssignments {
  private static Map<String, State_Assignment__mdt> byKey;

  public static State_Assignment__mdt forState(String state) {
    if (String.isBlank(state)) {
      return null;
    }
    return index().get(state.trim().toUpperCase());
  }

  /** All assignments sorted by state name. */
  public static List<State_Assignment__mdt> all() {
    Map<String, State_Assignment__mdt> byName = new Map<String, State_Assignment__mdt>();
    for (State_Assignment__mdt row : State_Assignment__mdt.getAll().values()) {
      byName.put(row.State_Name__c, row);
    }
    List<String> names = new List<String>(byName.keySet());
    names.sort();
    List<State_Assignment__mdt> sorted = new List<State_Assignment__mdt>();
    for (String name : names) {
      sorted.add(byName.get(name));
    }
    return sorted;
  }

  private static Map<String, State_Assignment__mdt> index() {
    if (byKey == null) {
      byKey = new Map<String, State_Assignment__mdt>();
      for (
        State_Assignment__mdt row : State_Assignment__mdt.getAll().values()
      ) {
        if (String.isNotBlank(row.State_Code__c)) {
          byKey.put(row.State_Code__c.toUpperCase(), row);
        }
        if (String.isNotBlank(row.State_Name__c)) {
          byKey.put(row.State_Name__c.toUpperCase(), row);
        }
      }
    }
    return byKey;
  }
}
