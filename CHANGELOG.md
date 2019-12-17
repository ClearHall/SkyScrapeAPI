## [2.3.5+2] - Fixed Comment Support

Assignment info comment support.

## [2.3.5+1] - Added Comment Support

Assignment info comment support.

## [2.3.4+1] - Code Speed Up

Added a long lost if statement that reduced speed of getting gradebook.

Tests were performed on decent internet.

One action : 7s 645 ms -> 4s 984ms
Three actions : 21 s -> 14 s

## [2.3.3+1] - Final Bug Fix

Finally fixed all bugs for messages for all districts by searching through all div's.

## [2.3.2+2] - More Bug Fix

Fix bug of insertion.

## [2.3.2+1] - More Bug Fix

Split's the text and inserts link in there.

## [2.3.1+1] - Bug Fix

Fixed bug where there was duplicate links.

## [2.3.0+2] - Windows Retarded

Windows RETARDED

## [2.3.0+1] - Messages

Added messages retrieval with attachments and hyperlinks.
- Gets messages from Skyward
- Retrieves attachments and attempts to keep formatting
- Moved messages to a new method because of the sheer slowness

## [2.2.1+2] - Retrieval of Current User

Retrieve current user

## [2.2.1+1] - User Name

Added getting the logged-in user's name.
- Adds more documentation
- Makes more variables private for security purposes
- Refactor of lib/src files to fit dart naming convention

## [2.2.0+1] - Parental Account Support

Added support for parent accounts with initializing accounts.
- Better documentation will be provided later.

## [2.1.0+3] - Small addition for maintenance checking

Will return text of the error if maintenance is returned

## [2.1.0+1] - Fix Github Retardation

HUGE GLOW-UP (Refactor)
- Removed duplicate code
- Moved files around
- Removed unnecessary code

## [2.0.0+2] - Fix Github Retardation

No description needed.

## [2.0.0+1] - Server Implementation

Added quick retrieval of assignments in the grade book.
- Added new data type that allows you to store assignments from the grade book
- Made for servers
- Retrieves post-able assignment, grade, and term the grade is from

## [1.1.0+3] - Bug Fix

Fixed bug that caused second login to grade book of the same API object would fail.

- Made Grade Book accessor values non static
- Made initgradebook return list

## [1.1.0+2] - Dev Test

Testing

## [1.1.0+1] - Refresh Rate Update

To give the developer more flexibility over skyscrapeapi.

This update gives more power to the developer and allows for developers to relax more.

- Refresh rates will now affect skyward log-ins
- The developer can now choose **IF** they want to refresh skyward authentication automatically
- Testing files now have settings testSettings.skyTest

## [1.0.1+3] - Maintenance Update

Added an example for developers to use in case they do not understand the documentation.

Reformatted all files to fit flutter's requests.

## [1.0.1+2] - Organization Update

Minor update for renaming and organizing library stuff.

## [1.0.1+1] - Documentation Update

Documentation is now available for developers to view.

## [1.0.0+1] - First Official Pub Release

I am confident now in my code and the errors it produces. The API tester code has been finished.

## [0.0.1+2] - Rename to Camel Case

Like the title, rename files to Camel Case

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
