## [0.0.1] - Initial Release

SkyScrapeAPI is a dart API that allows you to login and pull data from Skyward. SkyScrapeAPI was separated from the original SkyMobile app to allow the API to develop separately from the main app.

SkyScrapeAPI will restart at 0.0.1.

**BELOW IS THE OLD CHANGELOG**

**V1.6.0**

- Allows for error checking

**V1.5.4**

- Fixed bug where JSON Saver couldn't save ClassLevel

**V1.5.3**

- Removed unnecessary 4.0 GPA Credit attribute

**V1.5.2**

- Fixed bug where duplicate SchoolYears were returned.

**V1.5.1**

- Modified History Scraper and Data Types to support json saving.

**V1.5.0**

- Added History Scraper. Allows you to scrape from sfacademichistory001.w.

**V1.4.1**

- Adressed major bug which prevented users from Highland Park ISD from logging in. This should fix logging in bugs for all districts with wsEAplus in their url link name.

**V1.4.0**

- Remade Assignment scraping algorithm to support more districts.

**V1.3.0**

- Adds DistrictSearcher to search for districts family access links.

**V1.2.1**

- Fixed bug where assignments with the same name would display the same details: *THIS BUG AFFECTS SKYMOBILE iOS AND WILL NOT BE FIXED FOR SKYMOBILE iOS*

**V1.2.0**

- Can scrape assignment details.

**V1.0.0**

- Build the basic foundation. Initial release.
- Can scrape gradebook and assignments.
