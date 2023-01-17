=begin

use RAILS???
OR REWRITE WHOLE APP in REACT?????
- decisions decisions....

Major steps to refactoring and cleaning up code - in seq order

1. Use a different data structure to represent a 'game' - the valuable data the program offers
  - currently using 2 level nested objects / hashes


  - build  adatabase

SCHEMA
  one < many
  - users table
    - password, username

  - games table
    - username
    - ...

  - history
    - username
    - game id


2. refactor the code to work with the new data structure

3. use an SQL database for the storage mechanism instead of YML file

4. ensure XSS is protected

5. encrypt password using bcrypt

6. clean up website UI


=end