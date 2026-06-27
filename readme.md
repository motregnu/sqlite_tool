**The sqlite_tool app is written in Lazarus/Free Pascal (with some assistance from Google Gemini). 
The compiled binary is for Linux, but I have tried to make the source code platform-neutral. **

The UI is not slick, but there is a good amount of functionality. It can:

* Inspect the structure of tables and views. View/export create statements of a SQLite database file (tables, views, and triggers).

* View field info, indexes, and foreign-key info for each table.

* Export the schema to **text**, **Markdown**, and **PDF** formats.

* Import CSV data into an existing table. Either all columns or just some.

* Create new tables; either from scratch, or from the structure of a CSV file.

* Link to external SQLite database files.

* Paste table names (Ctrl+F) and field names (Ctrl+T) into the SQL Editor via shortcut hotkeys.

* A simple SQL buider dialog is available from the menu (Tools/Build SQL).

* Paste some SQLite functions into the SQL Editor via shortcut hotkeys (Ctrl+L).

* If you select a portion of the text in the SQL editor, only the selected part is executed  when the [Run query] button is pressed.

* Change shortcut hotkeys based on user preference.

* Some user preferances are saved to, and laoded from a config.ini file.

* Save, replay, or export SQL queries  to an external file.

* Use the [Direct Exec] button for SQL commands that do not return a record-set (e.g., CREATE VIEW, DROP TABLE...).
