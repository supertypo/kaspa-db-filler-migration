### Kaspa DB Filler NG - Schema migration

Migration scripts to transform a Postgresql schema populated by 
Kaspa DB Filler to the structure expected by Kaspa DB Filler NG.

#### Prerequisites

* A schema populated by Kaspa DB Filler.
* Kaspa DB Filler must be stopped.

Database migration is not needed when starting from an empty db.

#### Usage

1. Run 2_migration/0_misc.sql to completion.
2. Run 2_migration/1..6.sql to completion.
3. Run 2_migration/7_cleanup.sql to completion.

After transforming the schema the Kaspa DB Filler NG can be started.
