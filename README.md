# Medical Facility Inspection Tracker

Salesforce app for tracking the yearly inspections of US medical facilities. It includes a public Experience Cloud portal where anyone can search facilities on a US map and see their inspection status.

- **Internal app:** *Inspection Tracker*, with Accounts (record type *Medical Facility*), Inspections, reports and the *Inspection Compliance* dashboard.
- **Automation:** completing an inspection schedules the next one (+365 days if it passed, +30 days for a re-inspection if it failed), assigns an inspector by state and updates the facility's status.
- **National Insights:** public dashboards at `/insights`, with KPIs, a state compliance map, quarterly result trends, most-cited deficiency areas and facility-type/region comparisons.
- **Public portal:** the `facilityInspectionPortal` Lightning Web Component provides search by name, city or ZIP; state, status and type filters; a status-colored US map; and inspection history.

Architecture, data model, security model and diagrams: [docs/Solution-Architecture.md](docs/Solution-Architecture.md)

## Project layout

| Path | Contents |
| --- | --- |
| `force-app/` | Everything except the site sharing rule: objects, Apex, LWC, permission sets, app, reports, dashboard |
| `site-config/` | The *Facility Inspections* LWR site (home page, public access, network) and the guest sharing rule. Deploy it **after** the site exists |
| `scripts/apex/seedData.apex` | Creates or refreshes 150 demo facilities with inspection history |
| `docs/` | Solution architecture |

## Setup

You need the Salesforce CLI (`sf`) and a Developer Edition org.

```bash
# 1. Connect the org
sf org login web --alias inspections --set-default

# 2. Deploy the app
sf project deploy start --source-dir force-app

# 3. Give yourself access and run the tests
sf org assign permset --name Inspection_Tracker_Admin
sf apex run test --code-coverage --result-format human --wait 10

# 4. Load demo data
sf apex run --file scripts/apex/seedData.apex
```

### Public portal (Experience Cloud)

Live demo site: https://orgfarm-24624b149c-dev-ed.develop.my.site.com/inspections (facility search) and https://orgfarm-24624b149c-dev-ed.develop.my.site.com/inspections/insights (national insights dashboards)

To set it up in a new org:

1. Turn on Digital Experiences (Setup → Digital Experiences → Settings → **Enable Digital Experiences**). This can't be undone.
2. Create the site. It takes about a minute:
   ```bash
   sf community create --name "Facility Inspections" --template-name "Build Your Own (LWR)" --url-path-prefix inspections
   ```
3. Assign the guest permission set to the site guest user (Setup → Sites → *Facility_Inspections* → Public Access Settings → View Users):
   ```bash
   sf org assign permset --name Inspection_Portal_Guest --on-behalf-of "<guest user username>"
   ```
4. Deploy the site configuration, then publish. The deploy puts the portal component on Home, turns on public access, sets the site to Live and adds the guest sharing rule:
   ```bash
   sf project deploy start --source-dir site-config
   sf community publish --name "Facility Inspections"
   ```
5. Open the site URL in an incognito window.

If the new org gives the site different API names than `Facility_Inspections1` (the site bundle) and `Facility_Inspections` (the guest sharing rule), retrieve the site with `sf project retrieve start --metadata DigitalExperienceBundle DigitalExperienceConfig Network CustomSite`. Then make the same home-page and `authenticationType` changes again.

### Inspector assignment

Each state maps to a region and an inspector in **Setup → Custom Metadata Types → State Assignment**. Put an inspector's username in *Inspector Username*. While it's blank, new inspections go to the facility owner.

## Useful commands

```bash
sf data query --file scripts/soql/facilities.soql          # facilities by next due date
sf apex run test --class-names FacilityPortalControllerTest --wait 10
npm run lint                                                # ESLint for LWC
npm run prettier                                            # format sources
```
